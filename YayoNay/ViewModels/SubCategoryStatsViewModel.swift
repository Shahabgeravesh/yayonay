import SwiftUI
import FirebaseFirestore
import FirebaseAuth

class SubCategoryStatsViewModel: ObservableObject {
    @Published var attributeVotes: [String: AttributeVotes] = [:]
    @Published var comments: [Comment] = []
    @Published var currentSubCategory: SubCategory
    private let db = Firestore.firestore()
    private var attributeListener: ListenerRegistration?
    private var subCategoryListener: ListenerRegistration?
    private var commentsListener: ListenerRegistration?
    
    init(subCategory: SubCategory) {
        self.currentSubCategory = subCategory
        setupListeners()
        setupCommentsListener()
    }
    
    deinit {
        attributeListener?.remove()
        subCategoryListener?.remove()
        commentsListener?.remove()
    }
    
    private func setupListeners() {
        // Listen for subcategory updates
        let docRef = db.collection("subCategories").document(currentSubCategory.id)
        subCategoryListener = docRef.addSnapshotListener { [weak self] (snapshot: DocumentSnapshot?, error: Error?) in
            guard let self = self,
                  let snapshot = snapshot else { return }
            
            if let error = error {
                print("Error fetching subcategory: \(error.localizedDescription)")
                return
            }
            
            if let updatedSubCategory = SubCategory(document: snapshot) {
                self.currentSubCategory = updatedSubCategory
            }
        }
        
        // Listen for attribute votes
        let votesRef = db.collection("votes")
            .whereField("subCategoryId", isEqualTo: currentSubCategory.id)
        
        attributeListener = votesRef.addSnapshotListener { [weak self] (snapshot: QuerySnapshot?, error: Error?) in
            guard let self = self,
                  let documents = snapshot?.documents else {
                if let error = error {
                    print("Error fetching votes: \(error.localizedDescription)")
                }
                return
            }
            
            var newAttributeVotes: [String: AttributeVotes] = [:]
            
            for document in documents {
                let data = document.data()
                if let attributeName = data["categoryName"] as? String,
                   let isYay = data["isYay"] as? Bool {
                    var votes = newAttributeVotes[attributeName] ?? AttributeVotes()
                    if isYay {
                        votes.yayCount += 1
                    } else {
                        votes.nayCount += 1
                    }
                    newAttributeVotes[attributeName] = votes
                }
            }
            
            self.attributeVotes = newAttributeVotes
        }
    }
    
    private func setupCommentsListener() {
        print("DEBUG: Setting up comments listener for subCategoryId: \(currentSubCategory.id)")
        
        let commentsRef = db.collection("comments")
            .whereField("subCategoryId", isEqualTo: currentSubCategory.id)
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
            
            // Organize comments into threads
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
    
    func voteForAttribute(name: String, isYay: Bool) {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        let vote = Vote(
            id: UUID().uuidString,
            itemName: currentSubCategory.name,
            imageURL: currentSubCategory.imageURL,
            isYay: isYay,
            date: Date(),
            categoryName: name,
            categoryId: currentSubCategory.categoryId,
            subCategoryId: currentSubCategory.id
        )
        
        // Add the vote to Firestore
        db.collection("votes").document(vote.id).setData(vote.dictionary) { error in
            if let error = error {
                print("Error adding vote: \(error.localizedDescription)")
            }
        }
        
        // Update the subcategory's vote count
        let docRef = db.collection("subCategories").document(currentSubCategory.id)
        docRef.updateData([
            isYay ? "yayCount" : "nayCount": FieldValue.increment(Int64(1))
        ]) { error in
            if let error = error {
                print("Error updating subcategory vote count: \(error.localizedDescription)")
            }
        }
    }
    
    func addComment(_ text: String, parentId: String? = nil) {
        print("DEBUG: Attempting to add comment: '\(text)' with parentId: \(parentId ?? "nil")")
        
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
            commentData["subCategoryId"] = self.currentSubCategory.id
            
            print("DEBUG: Comment data to save: \(commentData)")
            print("DEBUG: SubCategory ID: \(self.currentSubCategory.id)")
            
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
} 