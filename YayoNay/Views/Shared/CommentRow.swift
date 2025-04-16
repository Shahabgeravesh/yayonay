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
        VStack(alignment: .leading, spacing: 8) {
            // Comment Header
            HStack {
                AsyncImage(url: URL(string: comment.userImage)) { image in
                    image
                        .resizable()
                        .scaledToFill()
                } placeholder: {
                    Color.gray.opacity(0.3)
                }
                .frame(width: 32, height: 32)
                .clipShape(Circle())
                
                VStack(alignment: .leading) {
                    Text(comment.username)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    
                    Text(comment.date, style: .relative)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if comment.userId == Auth.auth().currentUser?.uid {
                    Button {
                        onDelete()
                    } label: {
                        Image(systemName: "trash")
                            .foregroundColor(.red)
                    }
                }
            }
            
            // Comment Text
            Text(comment.text)
                .font(.body)
            
            // Like Button
            Button {
                onLike()
            } label: {
                HStack {
                    Image(systemName: comment.isLiked ? "heart.fill" : "heart")
                        .foregroundColor(comment.isLiked ? .red : .gray)
                    
                    Text("\(comment.likes)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            // Reply Button (only show if onReply is provided)
            if let onReply = onReply {
                Button {
                    isReplying.toggle()
                } label: {
                    Label("Reply", systemImage: "arrowshape.turn.up.left")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
                
                // Reply Input Field
                if isReplying {
                    HStack {
                        TextField("Write a reply...", text: $replyText)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                        
                        Button("Post") {
                            onReply(replyText)
                            replyText = ""
                            isReplying = false
                        }
                        .disabled(replyText.isEmpty)
                    }
                    .padding(.top, 8)
                }
            }
            
            // Replies
            if !comment.replies.isEmpty {
                Button {
                    showingReplies.toggle()
                } label: {
                    Text("\(comment.replies.count) replies")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
                
                if showingReplies {
                    ForEach(comment.replies) { reply in
                        CommentRow(
                            comment: reply,
                            onLike: onLike,
                            onDelete: onDelete,
                            onReply: onReply
                        )
                        .padding(.leading)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
} 