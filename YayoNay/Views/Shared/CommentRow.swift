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
    
    @State private var showingReplies = false
    @State private var isReplying = false
    @State private var replyText = ""
    @State private var showingDeleteAlert = false
    @State private var isLiked = false
    
    private let db = Firestore.firestore()
    
    init(comment: Comment, onLike: @escaping () -> Void, onDelete: @escaping () -> Void, onReply: @escaping (String) -> Void) {
        self.comment = comment
        self.onLike = onLike
        self.onDelete = onDelete
        self.onReply = onReply
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top, spacing: 12) {
                // User avatar
                Circle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 40, height: 40)
                    .overlay(
                        Text(comment.username.prefix(1).uppercased())
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.gray)
                    )
                
                VStack(alignment: .leading, spacing: 4) {
                    // Username and timestamp
                    HStack {
                        Text(comment.username)
                            .font(.system(size: 16, weight: .semibold))
                        Text(comment.date.timeAgoDisplay())
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                    }
                    
                    // Comment text
                    Text(comment.text)
                        .font(.system(size: 16))
                        .fixedSize(horizontal: false, vertical: true)
                    
                    // Action buttons
                    HStack(spacing: 16) {
                        Button(action: {
                            isLiked.toggle()
                            onLike()
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: isLiked ? "heart.fill" : "heart")
                                    .foregroundColor(isLiked ? .red : .gray)
                                Text("\(comment.likes)")
                                    .font(.system(size: 14))
                                    .foregroundColor(.gray)
                            }
                        }
                        
                        Button(action: {
                            isReplying.toggle()
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: "arrowshape.turn.up.left")
                                Text("Reply")
                                    .font(.system(size: 14))
                                    .foregroundColor(.gray)
                            }
                        }
                        
                        if comment.userId == Auth.auth().currentUser?.uid {
                            Button(action: {
                                showingDeleteAlert = true
                            }) {
                                HStack(spacing: 4) {
                                    Image(systemName: "trash")
                                        .foregroundColor(.red)
                                    Text("Delete")
                                        .font(.system(size: 14))
                                        .foregroundColor(.red)
                                }
                            }
                        }
                    }
                    
                    // Reply input field
                    if isReplying {
                        HStack {
                            TextField("Write a reply...", text: $replyText)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                            
                            Button(action: {
                                if !replyText.isEmpty {
                                    onReply(replyText)
                                    replyText = ""
                                    isReplying = false
                                }
                            }) {
                                Text("Post")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.blue)
                            }
                            .disabled(replyText.isEmpty)
                        }
                        .padding(.top, 8)
                    }
                    
                    // Show replies button
                    if !comment.replies.isEmpty {
                        Button(action: {
                            showingReplies.toggle()
                        }) {
                            HStack {
                                Text(showingReplies ? "Hide replies" : "Show \(comment.replies.count) replies")
                                    .font(.system(size: 14))
                                    .foregroundColor(.blue)
                                Image(systemName: showingReplies ? "chevron.up" : "chevron.down")
                                    .font(.system(size: 12))
                                    .foregroundColor(.blue)
                            }
                        }
                        .padding(.top, 4)
                    }
                }
            }
            
            // Replies
            if showingReplies {
                ForEach(comment.replies) { reply in
                    CommentRow(
                        comment: reply,
                        onLike: {
                            // Handle reply like
                        },
                        onDelete: {
                            // Handle reply delete
                        },
                        onReply: onReply
                    )
                    .padding(.leading, 52)
                }
            }
        }
        .padding(.vertical, 8)
        .alert("Delete Comment", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                onDelete()
            }
        } message: {
            Text("Are you sure you want to delete this comment? This action cannot be undone.")
        }
    }
} 