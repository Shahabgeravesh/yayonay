import SwiftUI
import FirebaseFirestore
import FirebaseAuth

class SubCategoryStatsViewModel: ObservableObject {
    @Published var attributeVotes: [String: AttributeVotes] = [:]
    @Published var comments: [Comment] = []
    @Published var currentSubCategory: SubCategory
    @Published var subQuestions: [SubQuestion] = []
    private let db = Firestore.firestore()
    private var attributeListener: ListenerRegistration?
    private var subCategoryListener: ListenerRegistration?
    private var commentsListener: ListenerRegistration?
    private var subQuestionsListener: ListenerRegistration?
    
    init(subCategory: SubCategory) {
        self.currentSubCategory = subCategory
        setupListeners()
        setupCommentsListener()
        setupSubQuestionsListener()
    }
    
    deinit {
        attributeListener?.remove()
        subCategoryListener?.remove()
        commentsListener?.remove()
        subQuestionsListener?.remove()
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
            
            let allComments = documents.compactMap { [weak self] document -> Comment? in
                guard let self = self else { return nil }
                let data = document.data()
                print("DEBUG: Comment data: \(data)")
                
                guard let userId = data["userId"] as? String,
                      let username = data["username"] as? String,
                      let text = data["text"] as? String,
                      let timestamp = data["date"] as? Timestamp else {
                    print("DEBUG: Failed to parse comment data: \(data)")
                    return nil
                }
                
                return Comment(
                    id: document.documentID,
                    userId: userId,
                    username: username,
                    userImage: data["userImage"] as? String ?? "https://firebasestorage.googleapis.com/v0/b/yayonay-e7f58.appspot.com/o/default_profile.png?alt=media",
                    text: text,
                    date: timestamp.dateValue(),
                    likes: data["likes"] as? Int ?? 0,
                    isLiked: (data["likedBy"] as? [String: Bool])?[Auth.auth().currentUser?.uid ?? ""] ?? false,
                    parentId: data["parentId"] as? String,
                    voteId: data["subCategoryId"] as? String ?? self.currentSubCategory.id
                )
            }
            
            print("DEBUG: Successfully parsed \(allComments.count) comments")
            
            DispatchQueue.main.async {
                // First, get all top-level comments (no parentId)
                var topLevelComments = allComments.filter { $0.parentId == nil }
                
                // Create a dictionary to organize replies by parent comment ID
                let repliesByParentId = Dictionary(grouping: allComments.filter { $0.parentId != nil },
                                                 by: { $0.parentId ?? "" })
                
                // Attach replies to their parent comments
                topLevelComments = topLevelComments.map { comment in
                    var updatedComment = comment
                    updatedComment.replies = repliesByParentId[comment.id] ?? []
                    return updatedComment
                }
                
                // Sort comments by date (newest first)
                self?.comments = topLevelComments.sorted(by: { $0.date > $1.date })
                
                print("DEBUG: Organized comments structure:")
                print("- Top-level comments: \(self?.comments.count ?? 0)")
                for comment in self?.comments ?? [] {
                    print("  - Comment \(comment.id) has \(comment.replies.count) replies")
                }
            }
        }
    }
    
    private func setupSubQuestionsListener() {
        print("DEBUG: Setting up sub-questions listener for categoryId: \(currentSubCategory.categoryId)")
        
        let questionsRef = db.collection("subQuestions")
            .whereField("categoryId", isEqualTo: currentSubCategory.categoryId)
        
        subQuestionsListener = questionsRef.addSnapshotListener { [weak self] snapshot, error in
            if let error = error {
                print("DEBUG: Error fetching sub-questions: \(error.localizedDescription)")
                return
            }
            
            guard let documents = snapshot?.documents else {
                print("DEBUG: No sub-questions found")
                return
            }
            
            print("DEBUG: Fetched \(documents.count) sub-questions")
            
            let questions = documents.compactMap { document -> SubQuestion? in
                return SubQuestion(document: document)
            }
            
            DispatchQueue.main.async {
                self?.subQuestions = questions
                print("DEBUG: Updated sub-questions: \(questions.count)")
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
    
    func voteForSubQuestion(_ question: SubQuestion, isYay: Bool) {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        let docRef = db.collection("subQuestions").document(question.id)
        
        // Update the vote count
        docRef.updateData([
            isYay ? "yayCount" : "nayCount": FieldValue.increment(Int64(1))
        ]) { error in
            if let error = error {
                print("DEBUG: Error updating sub-question vote: \(error.localizedDescription)")
            } else {
                print("DEBUG: Successfully updated sub-question vote")
            }
        }
        
        // Record the user's vote
        let vote = Vote(
            id: UUID().uuidString,
            itemName: currentSubCategory.name,
            imageURL: currentSubCategory.imageURL,
            isYay: isYay,
            date: Date(),
            categoryName: question.question,
            categoryId: currentSubCategory.categoryId,
            subCategoryId: currentSubCategory.id
        )
        
        db.collection("votes").document(vote.id).setData(vote.dictionary) { error in
            if let error = error {
                print("DEBUG: Error recording vote: \(error.localizedDescription)")
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
                parentId: parentId,
                voteId: self.currentSubCategory.id
            )
            
            var commentData = comment.dictionary
            commentData["subCategoryId"] = self.currentSubCategory.id
            
            if let parentId = parentId {
                commentData["parentId"] = parentId
            }
            
            print("DEBUG: Comment data to save: \(commentData)")
            
            self.db.collection("comments").document(commentId).setData(commentData) { error in
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
        print("DEBUG: Attempting to delete comment: \(comment.id)")
        
        guard let userId = Auth.auth().currentUser?.uid,
              comment.userId == userId else {
            print("DEBUG: Delete failed - User not authorized")
            return
        }
        
        let batch = db.batch()
        let commentRef = db.collection("comments").document(comment.id)
        
        // Delete the comment
        batch.deleteDocument(commentRef)
        
        // If this is a parent comment, also delete all replies
        if comment.parentId == nil {
            // Query for replies to this comment
            db.collection("comments")
                .whereField("parentId", isEqualTo: comment.id)
                .getDocuments { [weak self] snapshot, error in
                    if let error = error {
                        print("DEBUG: Error fetching replies to delete: \(error.localizedDescription)")
                        return
                    }
                    
                    guard let documents = snapshot?.documents else { return }
                    
                    let batch = self?.db.batch()
                    
                    // Add each reply to the batch delete
                    for document in documents {
                        batch?.deleteDocument(document.reference)
                    }
                    
                    // Commit the batch delete
                    batch?.commit { error in
                        if let error = error {
                            print("DEBUG: Error deleting replies: \(error.localizedDescription)")
                        } else {
                            print("DEBUG: Successfully deleted comment and its replies")
                        }
                    }
                }
        } else {
            // Just delete the single reply
            batch.commit { error in
                if let error = error {
                    print("DEBUG: Error deleting reply: \(error.localizedDescription)")
                } else {
                    print("DEBUG: Successfully deleted reply")
                }
            }
        }
    }
} 