import SwiftUI
import FirebaseAuth

struct CommentRow: View {
    let comment: Comment
    let onLike: () -> Void
    let onDelete: () -> Void
    let onReply: ((String) -> Void)?
    
    @State private var showingReplies = false
    @State private var isReplying = false
    @State private var replyText = ""
    
    init(comment: Comment, onLike: @escaping () -> Void, onDelete: @escaping () -> Void, onReply: ((String) -> Void)? = nil) {
        self.comment = comment
        self.onLike = onLike
        self.onDelete = onDelete
        self.onReply = onReply
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Comment Header
            HStack(spacing: 12) {
                // User Avatar
                AsyncImage(url: URL(string: comment.userImage)) { image in
                    image
                        .resizable()
                        .scaledToFill()
                } placeholder: {
                    Color.gray.opacity(0.3)
                }
                .frame(width: 40, height: 40)
                .clipShape(Circle())
                .overlay(
                    Circle()
                        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                )
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(comment.username)
                        .font(.system(size: 16, weight: .semibold))
                    
                    Text(comment.date, style: .relative)
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if comment.userId == Auth.auth().currentUser?.uid {
                    Button {
                        onDelete()
                    } label: {
                        Image(systemName: "trash")
                            .font(.system(size: 14))
                            .foregroundColor(.red)
                            .padding(8)
                            .background(Color.red.opacity(0.1))
                            .clipShape(Circle())
                    }
                }
            }
            
            // Comment Text
            Text(comment.text)
                .font(.system(size: 16))
                .lineSpacing(4)
                .padding(.leading, 4)
            
            // Action Buttons
            HStack(spacing: 16) {
                // Like Button
                Button {
                    onLike()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: comment.isLiked ? "heart.fill" : "heart")
                            .font(.system(size: 14))
                            .foregroundColor(comment.isLiked ? .red : .gray)
                        
                        Text("\(comment.likes)")
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.gray.opacity(0.1))
                    .clipShape(Capsule())
                }
                
                // Reply Button
                if let onReply = onReply {
                    Button {
                        isReplying.toggle()
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "arrowshape.turn.up.left")
                                .font(.system(size: 14))
                            Text("Reply")
                                .font(.system(size: 13))
                        }
                        .foregroundColor(.blue)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.blue.opacity(0.1))
                        .clipShape(Capsule())
                    }
                }
                
                // Show Replies Button
                if !comment.replies.isEmpty {
                    Button {
                        showingReplies.toggle()
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: showingReplies ? "chevron.up" : "chevron.down")
                                .font(.system(size: 14))
                            Text("\(comment.replies.count) replies")
                                .font(.system(size: 13))
                        }
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.gray.opacity(0.1))
                        .clipShape(Capsule())
                    }
                }
            }
            
            // Reply Input Field
            if isReplying, let onReply = onReply {
                HStack(spacing: 12) {
                    TextField("Write a reply...", text: $replyText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .font(.system(size: 15))
                    
                    Button {
                        onReply(replyText)
                        replyText = ""
                        isReplying = false
                    } label: {
                        Text("Post")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(replyText.isEmpty ? Color.blue.opacity(0.5) : Color.blue)
                            .clipShape(Capsule())
                    }
                    .disabled(replyText.isEmpty)
                }
                .padding(.top, 4)
            }
            
            // Replies
            if showingReplies {
                VStack(spacing: 16) {
                    ForEach(comment.replies) { reply in
                        CommentRow(
                            comment: reply,
                            onLike: onLike,
                            onDelete: onDelete,
                            onReply: onReply
                        )
                        .padding(.leading, 20)
                    }
                }
                .padding(.top, 8)
            }
        }
        .padding(16)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: Color.black.opacity(0.05), radius: 8, y: 4)
    }
} 