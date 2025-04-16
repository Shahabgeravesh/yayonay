import SwiftUI
import FirebaseFirestore
import FirebaseAuth

class VotesViewModel: ObservableObject {
    @Published var votes: [Vote] = []
    @Published var sortOption: SortOption = .date
    @Published var filterOption: FilterOption = .all
    @Published var comments: [Comment] = []
    private let db = Firestore.firestore()
    private var commentsListener: ListenerRegistration?
    
    enum SortOption: String, CaseIterable {
        case date = "Date"
        case category = "Category"
        case name = "Name"
    }
    
    enum FilterOption: String, CaseIterable {
        case all = "All"
        case yay = "Yay!"
        case nay = "Nay!"
    }
    
    func fetchVotes() {
        db.collection("votes")
            .order(by: "date", descending: true)
            .addSnapshotListener { [weak self] snapshot, error in
                if let error = error {
                    print("Error fetching votes: \(error)")
                    return
                }
                
                self?.votes = snapshot?.documents.compactMap { document in
                    Vote(document: document)
                } ?? []
            }
    }
    
    func deleteVote(_ vote: Vote) {
        db.collection("votes").document(vote.id).delete() { error in
            if let error = error {
                print("Error deleting vote: \(error)")
            }
        }
    }
    
    func sortedAndFilteredVotes(searchText: String) -> [Vote] {
        var filteredVotes = votes
        
        // Apply filter
        switch filterOption {
        case .yay:
            filteredVotes = filteredVotes.filter { $0.isYay }
        case .nay:
            filteredVotes = filteredVotes.filter { !$0.isYay }
        case .all:
            break
        }
        
        // Apply search
        if !searchText.isEmpty {
            filteredVotes = filteredVotes.filter {
                $0.itemName.localizedCaseInsensitiveContains(searchText) ||
                $0.categoryName.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        // Apply sort
        return filteredVotes.sorted { first, second in
            switch sortOption {
            case .date:
                return first.date > second.date
            case .category:
                return first.categoryName < second.categoryName
            case .name:
                return first.itemName < second.itemName
            }
        }
    }
    
    func setupCommentsListener(forVoteId voteId: String) {
        print("DEBUG: Setting up comments listener for voteId: \(voteId)")
        
        // Remove existing listener if any
        commentsListener?.remove()
        
        let commentsRef = db.collection("comments")
            .whereField("voteId", isEqualTo: voteId)
            .order(by: "date", descending: true)
        
        commentsListener = commentsRef.addSnapshotListener { [weak self] snapshot, error in
            if let error = error {
                print("DEBUG: Error fetching comments: \(error.localizedDescription)")
                return
            }
            
            guard let documents = snapshot?.documents else {
                print("DEBUG: No documents in snapshot")
                return
            }
            
            print("DEBUG: Fetched \(documents.count) comments from Firestore")
            
            let allComments = documents.compactMap { document -> Comment? in
                let data = document.data()
                print("DEBUG: Comment data: \(data)")
                
                guard let userId = data["userId"] as? String,
                      let username = data["username"] as? String,
                      let userImage = data["userImage"] as? String,
                      let text = data["text"] as? String,
                      let timestamp = data["date"] as? Timestamp else {
                    print("DEBUG: Failed to parse comment data: \(data)")
                    return nil
                }
                
                return Comment(
                    id: document.documentID,
                    userId: userId,
                    username: username,
                    userImage: userImage,
                    text: text,
                    date: timestamp.dateValue(),
                    likes: data["likes"] as? Int ?? 0,
                    isLiked: (data["likedBy"] as? [String: Bool])?[Auth.auth().currentUser?.uid ?? ""] ?? false,
                    parentId: data["parentId"] as? String
                )
            }
            
            print("DEBUG: Successfully parsed \(allComments.count) comments")
            
            DispatchQueue.main.async {
                // First, get all top-level comments (no parentId)
                self?.comments = allComments.filter { $0.parentId == nil }
                print("DEBUG: Top-level comments: \(self?.comments.count ?? 0)")
                
                // Then, for each top-level comment, attach its replies
                self?.comments = self?.comments.map { comment in
                    var updatedComment = comment
                    updatedComment.replies = allComments.filter { $0.parentId == comment.id }
                    return updatedComment
                } ?? []
                
                print("DEBUG: Final comments with replies: \(self?.comments.count ?? 0)")
            }
        }
    }
    
    func addComment(_ text: String, voteId: String, parentId: String? = nil) {
        print("DEBUG: Attempting to add comment: '\(text)' for voteId: \(voteId) with parentId: \(parentId ?? "nil")")
        
        guard let userId = Auth.auth().currentUser?.uid else {
            print("DEBUG: Failed to add comment - No authenticated user")
            return
        }
        
        print("DEBUG: User ID: \(userId)")
        
        db.collection("users").document(userId).getDocument { [weak self] snapshot, error in
            if let error = error {
                print("DEBUG: Error fetching user data: \(error.localizedDescription)")
                return
            }
            
            guard let self = self,
                  let data = snapshot?.data() else {
                print("DEBUG: Failed to get user data")
                return
            }
            
            print("DEBUG: User data: \(data)")
            
            // Extract username and userImage with fallbacks
            let username = data["username"] as? String ?? "Anonymous User"
            let userImage = data["imageURL"] as? String ?? "https://firebasestorage.googleapis.com/v0/b/yayonay-e7f58.appspot.com/o/default_profile.png?alt=media"
            
            print("DEBUG: Username: \(username), UserImage: \(userImage)")
            
            let commentId = UUID().uuidString
            print("DEBUG: Generated comment ID: \(commentId)")
            
            let comment = Comment(
                id: commentId,
                userId: userId,
                username: username,
                userImage: userImage,
                text: text,
                parentId: parentId
            )
            
            var commentData = comment.dictionary
            commentData["voteId"] = voteId
            
            print("DEBUG: Comment data to save: \(commentData)")
            print("DEBUG: Vote ID: \(voteId)")
            
            self.db.collection("comments")
                .document(commentId)
                .setData(commentData) { error in
                    if let error = error {
                        print("DEBUG: Error adding comment: \(error.localizedDescription)")
                    } else {
                        print("DEBUG: Comment successfully added to Firestore")
                    }
                }
        }
    }
    
    func likeComment(_ comment: Comment) {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        let docRef = db.collection("comments").document(comment.id)
        
        if comment.isLiked {
            // Unlike
            docRef.updateData([
                "likes": FieldValue.increment(Int64(-1)),
                "likedBy.\(userId)": FieldValue.delete()
            ])
        } else {
            // Like
            docRef.updateData([
                "likes": FieldValue.increment(Int64(1)),
                "likedBy.\(userId)": true
            ])
        }
    }
    
    func deleteComment(_ comment: Comment) {
        guard let userId = Auth.auth().currentUser?.uid,
              comment.userId == userId else { return }
        
        db.collection("comments").document(comment.id).delete { [weak self] error in
            if error == nil {
                DispatchQueue.main.async {
                    self?.comments.removeAll { $0.id == comment.id }
                }
            }
        }
    }
    
    deinit {
        commentsListener?.remove()
    }
}

struct VotesView: View {
    @StateObject private var viewModel = VotesViewModel()
    @State private var searchText = ""
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Filter and Sort Options
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        // Filter Options
                        ForEach(VotesViewModel.FilterOption.allCases, id: \.self) { option in
                            FilterButton(
                                title: option.rawValue,
                                isSelected: viewModel.filterOption == option,
                                action: { viewModel.filterOption = option }
                            )
                        }
                        
                        Divider()
                            .frame(height: 24)
                        
                        // Sort Options
                        ForEach(VotesViewModel.SortOption.allCases, id: \.self) { option in
                            SortButton(
                                title: option.rawValue,
                                isSelected: viewModel.sortOption == option,
                                action: { viewModel.sortOption = option }
                            )
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                }
                .background(Color(.systemBackground))
                
                if viewModel.sortedAndFilteredVotes(searchText: searchText).isEmpty {
                    EmptyStateView(searchText: searchText)
                } else {
                    // Votes List
                    List {
                        ForEach(viewModel.sortedAndFilteredVotes(searchText: searchText)) { vote in
                            NavigationLink {
                                CommentsView(
                                    vote: vote,
                                    comments: viewModel.comments,
                                    onAddComment: { text, parentId in
                                        viewModel.addComment(text, voteId: vote.id, parentId: parentId)
                                    },
                                    onLikeComment: { comment in
                                        viewModel.likeComment(comment)
                                    },
                                    onDeleteComment: { comment in
                                        viewModel.deleteComment(comment)
                                    }
                                )
                                .onAppear {
                                    viewModel.setupCommentsListener(forVoteId: vote.id)
                                }
                            } label: {
                                VoteCard(vote: vote, isClickable: false)
                            }
                            .listRowInsets(EdgeInsets())
                            .listRowSeparator(.hidden)
                            .padding(.vertical, 4)
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("My Votes")
            .searchable(text: $searchText, prompt: "Search votes...")
        }
        .onAppear {
            viewModel.fetchVotes()
        }
    }
}

struct CommentsView: View {
    let vote: Vote
    let comments: [Comment]
    let onAddComment: (String, String?) -> Void
    let onLikeComment: (Comment) -> Void
    let onDeleteComment: (Comment) -> Void
    
    @State private var newCommentText = ""
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack {
            // Vote Summary
            VoteCard(vote: vote, isClickable: false)
                .padding()
            
            // Comments List
            ScrollView {
                LazyVStack(spacing: 16) {
                    ForEach(comments) { comment in
                        CommentRow(
                            comment: comment,
                            onLike: { onLikeComment(comment) },
                            onDelete: { onDeleteComment(comment) },
                            onReply: { text in
                                onAddComment(text, comment.id)
                            }
                        )
                    }
                }
                .padding()
            }
            
            // Comment Input
            HStack {
                TextField("Add a comment...", text: $newCommentText)
                    .textFieldStyle(.roundedBorder)
                
                Button {
                    guard !newCommentText.isEmpty else { return }
                    onAddComment(newCommentText, nil)
                    newCommentText = ""
                } label: {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.title2)
                        .foregroundColor(.blue)
                }
                .disabled(newCommentText.isEmpty)
            }
            .padding()
        }
        .navigationTitle("Comments")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct FilterButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? Color.blue : Color.gray.opacity(0.1))
                .foregroundColor(isSelected ? .white : .primary)
                .clipShape(Capsule())
        }
    }
}

struct SortButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Text(title)
                Image(systemName: "arrow.up.arrow.down")
                    .font(.caption)
            }
            .font(.subheadline)
            .fontWeight(.medium)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(isSelected ? Color.blue : Color.gray.opacity(0.1))
            .foregroundColor(isSelected ? .white : .primary)
            .clipShape(Capsule())
        }
    }
}

struct EmptyStateView: View {
    let searchText: String
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "square.stack.3d.up.slash")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            if searchText.isEmpty {
                Text("No votes yet")
                    .font(.title2)
                    .foregroundColor(.gray)
                Text("Start voting on items to see them here")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            } else {
                Text("No matches found")
                    .font(.title2)
                    .foregroundColor(.gray)
                Text("Try adjusting your search or filters")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
    }
}

struct VoteCard: View {
    let vote: Vote
    let isClickable: Bool
    
    init(vote: Vote, isClickable: Bool = true) {
        self.vote = vote
        self.isClickable = isClickable
    }
    
    var body: some View {
        Group {
            if isClickable {
                NavigationLink {
                    SubCategoryStatsView(subCategory: SubCategory(
                        id: vote.subCategoryId,
                        name: vote.itemName,
                        imageURL: vote.imageURL,
                        categoryId: vote.categoryId,
                        order: 0,
                        yayCount: 0,
                        nayCount: 0
                    ))
                } label: {
                    voteContent
                }
                .buttonStyle(.plain)
            } else {
                voteContent
            }
        }
    }
    
    private var voteContent: some View {
        HStack(spacing: 12) {
            // Image
            AsyncImage(url: URL(string: vote.imageURL)) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Color.gray.opacity(0.2)
            }
            .frame(width: 50, height: 50)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            
            // Content
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(vote.itemName)
                        .font(.headline)
                    
                    Text(vote.isYay ? "Yay!" : "Nay!")
                        .font(.subheadline)
                        .foregroundColor(vote.isYay ? .green : .red)
                }
                
                Text(formatDate(vote.date))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Only show chevron if clickable
            if isClickable {
                Image(systemName: "chevron.forward")
                    .foregroundStyle(.secondary)
                    .font(.system(size: 14))
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: Color.black.opacity(0.1), radius: 5, y: 2)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "M/d/yy"
        return formatter.string(from: date)
    }
}

#Preview {
    VotesView()
} 