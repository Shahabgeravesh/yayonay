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
    @FocusState private var isReplyFieldFocused: Bool
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Main comment
            HStack(alignment: .top, spacing: 12) {
                // User avatar
                AsyncImage(url: URL(string: comment.userImage)) { phase in
                    switch phase {
                    case .empty:
                        Circle()
                            .fill(colorScheme == .dark ? Color.gray.opacity(0.3) : Color.gray.opacity(0.2))
                            .overlay(
                                Text(comment.username.prefix(1).uppercased())
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(colorScheme == .dark ? .white.opacity(0.7) : .gray)
                            )
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    case .failure:
                        Circle()
                            .fill(colorScheme == .dark ? Color.gray.opacity(0.3) : Color.gray.opacity(0.2))
                            .overlay(
                                Text(comment.username.prefix(1).uppercased())
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(colorScheme == .dark ? .white.opacity(0.7) : .gray)
                            )
                    @unknown default:
                        Circle()
                            .fill(colorScheme == .dark ? Color.gray.opacity(0.3) : Color.gray.opacity(0.2))
                            .overlay(
                                Text(comment.username.prefix(1).uppercased())
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(colorScheme == .dark ? .white.opacity(0.7) : .gray)
                            )
                    }
                }
                .frame(width: 40, height: 40)
                .clipShape(Circle())
                
                VStack(alignment: .leading, spacing: 4) {
                    // Username and timestamp
                    HStack {
                        Text(comment.username)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(AppColor.text)
                        Text(comment.date.timeAgoDisplay())
                            .font(.system(size: 14))
                            .foregroundColor(AppColor.secondaryText)
                    }
                    
                    // Comment text
                    Text(comment.text)
                        .font(.system(size: 16))
                        .foregroundColor(AppColor.text)
                        .fixedSize(horizontal: false, vertical: true)
                    
                    // Action buttons
                    HStack(spacing: 16) {
                        Button(action: {
                            print("DEBUG: Like button tapped for comment ID: \(comment.id)")
                            onLike()
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: comment.isLiked ? "heart.fill" : "heart")
                                    .foregroundColor(comment.isLiked ? .red : AppColor.secondaryText)
                                Text("\(comment.likes)")
                                    .font(.system(size: 14))
                                    .foregroundColor(AppColor.secondaryText)
                            }
                        }
                        
                        Button(action: { 
                            print("DEBUG: Reply button tapped for comment ID: \(comment.id)")
                            isReplying = true
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: "arrowshape.turn.up.left")
                                    .foregroundColor(AppColor.secondaryText)
                                Text("Reply")
                                    .font(.system(size: 14))
                                    .foregroundColor(AppColor.secondaryText)
                            }
                        }
                        
                        if comment.userId == Auth.auth().currentUser?.uid {
                            Button(action: {
                                print("DEBUG: Delete button tapped for comment: \(comment.id)")
                                onDelete()
                            }) {
                                Image(systemName: "trash")
                                    .foregroundColor(.red)
                            }
                        }
                    }
                }
            }
            
            // Reply input field
            if isReplying {
                VStack(spacing: 8) {
                    HStack(spacing: 12) {
                        TextField("Write a reply...", text: $replyText)
                            .textFieldStyle(.roundedBorder)
                            .frame(maxWidth: .infinity)
                            .focused($isReplyFieldFocused)
                            .submitLabel(.send)
                            .onSubmit {
                                submitReply()
                            }
                        
                        Button(action: {
                            submitReply()
                        }) {
                            Text("Post")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(replyText.isEmpty ? AppColor.secondaryText : AppColor.accent)
                        }
                        .disabled(replyText.isEmpty)
                    }
                    
                    HStack {
                        Button(action: {
                            isReplying = false
                            replyText = ""
                            isReplyFieldFocused = false
                        }) {
                            Text("Cancel")
                                .font(.system(size: 14))
                                .foregroundColor(AppColor.secondaryText)
                        }
                        
                        Spacer()
                        
                        Button(action: {
                            isReplyFieldFocused = false
                        }) {
                            Text("Done")
                                .font(.system(size: 14))
                                .foregroundColor(AppColor.accent)
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
                .padding(.leading, 52)
                .padding(.trailing, 16)
                .padding(.vertical, 8)
                .background(AppColor.adaptiveSecondaryBackground(for: colorScheme))
                .onAppear {
                    // Set focus after a short delay to ensure view is ready
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        isReplyFieldFocused = true
                    }
                }
            }
        }
        .padding()
        .background(AppColor.adaptiveBackground(for: colorScheme))
        .cornerRadius(12)
        .shadow(
            color: colorScheme == .dark ? .black.opacity(0.2) : .black.opacity(0.05),
            radius: colorScheme == .dark ? 3 : 3,
            y: colorScheme == .dark ? 1 : 1
        )
    }
    
    private func submitReply() {
        guard !replyText.isEmpty else { return }
        print("DEBUG: Submitting reply to comment ID: \(comment.id)")
        onReply(replyText)
        replyText = ""
        isReplying = false
        isReplyFieldFocused = false
    }
} 