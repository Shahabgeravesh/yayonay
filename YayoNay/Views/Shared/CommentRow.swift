import SwiftUI
import FirebaseAuth
import FirebaseFirestore

extension Date {
    func timeAgoDisplay() -> String {
        let calendar = Calendar.current
        let now = Date()
        let components = calendar.dateComponents([.minute, .hour, .day, .weekOfMonth, .month, .year], from: self, to: now)
        
        if let year = components.year, year >= 1 {
            return year == 1 ? "1 year ago" : "\(year) years ago"
        }
        
        if let month = components.month, month >= 1 {
            return month == 1 ? "1 month ago" : "\(month) months ago"
        }
        
        if let week = components.weekOfMonth, week >= 1 {
            return week == 1 ? "1 week ago" : "\(week) weeks ago"
        }
        
        if let day = components.day, day >= 1 {
            return day == 1 ? "1 day ago" : "\(day) days ago"
        }
        
        if let hour = components.hour, hour >= 1 {
            return hour == 1 ? "1 hour ago" : "\(hour) hours ago"
        }
        
        if let minute = components.minute, minute >= 1 {
            return minute == 1 ? "1 minute ago" : "\(minute) minutes ago"
        }
        
        return "Just now"
    }
}

struct CommentRow: View {
    let comment: Comment
    let onLike: () -> Void
    let onDelete: () -> Void
    let onReply: (String) -> Void
    @State private var isReplying = false
    @State private var replyText = ""
    @State private var showDeleteConfirmation = false
    @State private var showUndoDelete = false
    @ObservedObject var viewModel: SubCategoryStatsViewModel
    @Environment(\.colorScheme) private var colorScheme
    
    private var backgroundColor: Color {
        colorScheme == .dark ? Color(.systemGray6) : .white
    }
    
    private var shadowColor: Color {
        colorScheme == .dark ? .clear : Color.black.opacity(0.1)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Comment card
            VStack(alignment: .leading, spacing: 12) {
                // Comment content
                HStack(alignment: .top, spacing: 12) {
                    // User avatar with fallback
                    ZStack {
                        if !comment.userImage.isEmpty {
                            AsyncImage(url: URL(string: comment.userImage)) { image in
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                            } placeholder: {
                                Color.gray.opacity(0.2)
                            }
                        } else {
                            // Fallback to initials avatar
                            Text(comment.username.prefix(1).uppercased())
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                .background(
                                    LinearGradient(
                                        gradient: Gradient(colors: [.blue, .purple]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                        }
                    }
                    .frame(width: 40, height: 40)
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .stroke(Color(.systemGray5), lineWidth: 1)
                    )
                    
                    // Comment text and metadata
                    VStack(alignment: .leading, spacing: 6) {
                        // Username and timestamp
                        HStack(spacing: 8) {
                            Text(comment.username)
                                .font(.system(size: 15, weight: .semibold))
                            
                            Text(comment.date, style: .relative)
                                .font(.system(size: 13))
                                .foregroundColor(.secondary)
                        }
                        
                        // Comment text
                        Text(comment.text)
                            .font(.system(size: 15))
                            .foregroundColor(AppColor.text)
                            .lineSpacing(2)
                    }
                }
                
                // Action buttons
                if !viewModel.isProcessingCommentAction || viewModel.recentlyDeletedCommentId != comment.id {
                    HStack(spacing: 20) {
                        Button(action: {
                            if !viewModel.isProcessingCommentAction {
                                onLike()
                            }
                        }) {
                            HStack(spacing: 6) {
                                if viewModel.isProcessingCommentAction {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: AppColor.secondaryText))
                                        .scaleEffect(0.8)
                                } else {
                                    Image(systemName: comment.isLiked ? "heart.fill" : "heart")
                                        .foregroundColor(comment.isLiked ? .red : AppColor.secondaryText)
                                }
                                Text("\(comment.likes)")
                                    .font(.system(size: 14))
                                    .foregroundColor(AppColor.secondaryText)
                            }
                        }
                        .disabled(viewModel.isProcessingCommentAction)
                        
                        Button(action: { 
                            if !viewModel.isProcessingCommentAction {
                                withAnimation(.spring()) {
                                    isReplying.toggle()
                                }
                            }
                        }) {
                            HStack(spacing: 6) {
                                Image(systemName: "arrowshape.turn.up.left")
                                    .foregroundColor(AppColor.secondaryText)
                                Text("Reply")
                                    .font(.system(size: 14))
                                    .foregroundColor(AppColor.secondaryText)
                            }
                        }
                        .disabled(viewModel.isProcessingCommentAction)
                        
                        if comment.userId == Auth.auth().currentUser?.uid {
                            Button(action: {
                                if !viewModel.isProcessingCommentAction {
                                    showDeleteConfirmation = true
                                }
                            }) {
                                Image(systemName: "trash")
                                    .foregroundColor(.red)
                            }
                            .disabled(viewModel.isProcessingCommentAction)
                        }
                    }
                    .padding(.top, 4)
                } else if viewModel.recentlyDeletedCommentId == comment.id {
                    // Undo delete button
                    Button(action: {
                        viewModel.undoDeleteComment()
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "arrow.uturn.backward")
                            Text("Undo")
                        }
                        .font(.system(size: 14))
                        .foregroundColor(.blue)
                    }
                }
            }
            .padding(16)
            .background(backgroundColor)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: shadowColor, radius: 8, x: 0, y: 2)
            
            // Reply input field
            if isReplying {
                VStack(spacing: 12) {
                    TextField("Write a reply...", text: $replyText, axis: .vertical)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .lineLimit(3...6)
                    
                    HStack {
                        Button("Cancel") {
                            withAnimation(.spring()) {
                                isReplying = false
                                replyText = ""
                            }
                        }
                        .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Button("Reply") {
                            if !replyText.isEmpty {
                                onReply(replyText)
                                withAnimation(.spring()) {
                                    isReplying = false
                                    replyText = ""
                                }
                            }
                        }
                        .foregroundColor(.blue)
                        .disabled(replyText.isEmpty)
                    }
                }
                .padding(.leading, 56)
                .padding(.top, 8)
            }
        }
        .padding(.horizontal)
        .alert("Delete Comment", isPresented: $showDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                onDelete()
            }
        } message: {
            Text("Are you sure you want to delete this comment?")
        }
        .alert("Error", isPresented: $viewModel.showErrorAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(viewModel.errorMessage ?? "An error occurred")
        }
    }
} 