import SwiftUI
import FirebaseFirestore
import FirebaseAuth

typealias FIRFieldValue = FirebaseFirestore.FieldValue

class SubCategoryStatsViewModel: ObservableObject {
    @Published var attributeVotes: [String: AttributeVotes] = [:]
    @Published var comments: [Comment] = []
    @Published var currentSubCategory: SubCategory
    @Published var subQuestions: [SubQuestion] = []
    @Published var showCooldownAlert = false
    @Published private(set) var lastVoteDate: Date?
    @Published private var subQuestionVoteDates: [String: Date] = [:] // Track vote dates for each sub-question
    @Published var errorMessage: String?
    @Published var showErrorAlert = false
    @Published var isProcessingCommentAction = false
    @Published var recentlyDeletedCommentId: String?
    @Published var subQuestionVoteHistory: [String: [UserVote]] = [:] // Track vote history for each subquestion
    private let db = Firestore.firestore()
    private var attributeListener: ListenerRegistration?
    private var subCategoryListener: ListenerRegistration?
    private var commentsListener: ListenerRegistration?
    private var subQuestionsListener: ListenerRegistration?
    private var userVotesListener: ListenerRegistration?
    private var voteHistoryListeners: [String: ListenerRegistration] = [:] // Track listeners for vote history
    private var userSubQuestionVotes: [String: Bool] = [:] // Track votes for each sub-question
    
    init(subCategory: SubCategory) {
        print("DEBUG: Initializing SubCategoryStatsViewModel for subCategory: \(subCategory.id)")
        self.currentSubCategory = subCategory
        self.lastVoteDate = UserDefaults.standard.object(forKey: "lastVoteDate_\(subCategory.id)") as? Date
        print("DEBUG: Initial lastVoteDate from UserDefaults: \(String(describing: self.lastVoteDate))")
        setupListeners()
        setupCommentsListener()
        setupSubQuestionsListener()
        setupUserVotesListener()
        print("DEBUG: SubCategoryStatsViewModel initialization complete")
    }
    
    deinit {
        print("DEBUG: Deinitializing SubCategoryStatsViewModel")
        attributeListener?.remove()
        subCategoryListener?.remove()
        commentsListener?.remove()
        subQuestionsListener?.remove()
        userVotesListener?.remove()
    }
    
    private func setupListeners() {
        // Listen for subcategory updates
        let docRef = db.collection("categories").document(currentSubCategory.categoryId).collection("subcategories").document(currentSubCategory.id)
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
        let votesRef = db.collection("users").document(Auth.auth().currentUser?.uid ?? "").collection("votes")
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
        
        // Remove existing listener if any
        commentsListener?.remove()
        
        let commentsRef = db.collection("comments")
            .whereField("subCategoryId", isEqualTo: currentSubCategory.id)
            .order(by: "date", descending: true)
        
        commentsListener = commentsRef.addSnapshotListener { [weak self] snapshot, error in
            guard let self = self else { return }
            
            if let error = error {
                print("DEBUG: Error fetching comments: \(error.localizedDescription)")
                self.errorMessage = "Failed to load comments: \(error.localizedDescription)"
                self.showErrorAlert = true
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
                      let text = data["text"] as? String,
                      let timestamp = data["date"] as? Timestamp else {
                    print("DEBUG: Failed to parse comment data: \(data)")
                    return nil
                }
                
                return Comment(
                    id: document.documentID,
                    userId: userId,
                    username: username,
                    userImage: data["userImage"] as? String ?? "",
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
                self.comments = topLevelComments.sorted(by: { $0.date > $1.date })
                
                print("DEBUG: Organized comments structure:")
                print("- Top-level comments: \(self.comments.count)")
                for comment in self.comments {
                    print("  - Comment \(comment.id) has \(comment.replies.count) replies")
                }
            }
        }
    }
    
    private func setupSubQuestionsListener() {
        print("DEBUG: Setting up sub-questions listener")
        let subQuestionsRef = db.collection("categories")
            .document(currentSubCategory.categoryId)
            .collection("subcategories")
            .document(currentSubCategory.id)
            .collection("subquestions")
            .whereField("active", isEqualTo: true)
            .order(by: "order", descending: false)
        
        subQuestionsListener = subQuestionsRef.addSnapshotListener { [weak self] (snapshot: QuerySnapshot?, error: Error?) in
            guard let self = self,
                  let documents = snapshot?.documents else {
                if let error = error {
                    print("DEBUG: Error fetching sub-questions: \(error.localizedDescription)")
                }
                return
            }
            
            let questions = documents.compactMap { document -> SubQuestion? in
                return SubQuestion(document: document)
            }
            
            DispatchQueue.main.async {
                self.subQuestions = questions
                print("DEBUG: Updated sub-questions with aggregated data: \(questions.count)")
                
                // Set up vote history listeners for each subquestion
                self.setupVoteHistoryListeners(for: questions)
            }
        }
    }
    
    private func setupVoteHistoryListeners(for questions: [SubQuestion]) {
        // Remove existing listeners
        for (_, listener) in voteHistoryListeners {
            listener.remove()
        }
        voteHistoryListeners.removeAll()
        
        for question in questions {
            let votesRef = db.collection("categories")
                .document(question.categoryId)
                .collection("subcategories")
                .document(question.subCategoryId)
                .collection("subquestions")
                .document(question.id)
                .collection("votes")
            
            let listener = votesRef.addSnapshotListener { [weak self] (snapshot, error) in
                if let error = error {
                    print("DEBUG: Error listening to votes: \(error.localizedDescription)")
                    return
                }
                
                guard let documents = snapshot?.documents else { return }
                
                // Update vote counts
                var yayCount = 0
                var nayCount = 0
                var uniqueVoters = Set<String>()
                
                for doc in documents {
                    if doc.documentID == "_metadata" { continue } // Skip metadata document
                    
                    if let vote = doc.data()["vote"] as? Bool {
                        if vote {
                            yayCount += 1
                        } else {
                            nayCount += 1
                        }
                        uniqueVoters.insert(doc.documentID) // documentID is userId
                    }
                }
                
                // Update metadata
                let metadataRef = votesRef.document("_metadata")
                let metadata: [String: Any] = [
                    "totalVotes": yayCount + nayCount,
                    "uniqueVoters": uniqueVoters.count,
                    "lastVoteAt": Timestamp(date: Date())
                ]
                
                metadataRef.setData(metadata, merge: true)
                
                // Update subquestion document
                let subquestionRef = self?.db.collection("categories")
                    .document(question.categoryId)
                    .collection("subcategories")
                    .document(question.subCategoryId)
                    .collection("subquestions")
                    .document(question.id)
                
                subquestionRef?.updateData([
                    "yayCount": yayCount,
                    "nayCount": nayCount,
                    "votesMetadata": metadata
                ])
            }
            
            voteHistoryListeners[question.id] = listener
        }
    }
    
    private func setupUserVotesListener() {
        print("DEBUG: Setting up user votes listener")
        guard let userId = Auth.auth().currentUser?.uid else {
            print("DEBUG: No user ID found in setupUserVotesListener")
            return
        }
        
        print("DEBUG: User ID found: \(userId)")
        print("DEBUG: Checking votes for subCategory: \(currentSubCategory.id)")
        
        // First, check for existing votes using getDocuments
        let votesRef = db.collection("users").document(userId).collection("votes")
            .whereField("subCategoryId", isEqualTo: currentSubCategory.id)
        
        print("DEBUG: Querying Firestore for existing votes")
        
        votesRef.getDocuments { [weak self] (snapshot, error) in
            guard let self = self else { return }
            
            if let error = error {
                print("DEBUG: Error fetching user votes: \(error.localizedDescription)")
                return
            }
            
            if let documents = snapshot?.documents {
                print("DEBUG: Found \(documents.count) vote documents")
                
                // Reset the vote dates dictionary
                self.subQuestionVoteDates = [:]
                
                // Process each vote document
                for document in documents {
                    let data = document.data()
                    if let subQuestionId = data["subQuestionId"] as? String,
                       let timestamp = data["timestamp"] as? Timestamp {
                        self.subQuestionVoteDates[subQuestionId] = timestamp.dateValue()
                    }
                }
                
                print("DEBUG: Updated sub-question vote dates: \(self.subQuestionVoteDates)")
            } else {
                print("DEBUG: No vote documents found")
                self.subQuestionVoteDates = [:]
            }
        }
        
        // Set up the listener for future votes
        print("DEBUG: Setting up real-time listener for future votes")
        userVotesListener = votesRef.addSnapshotListener { [weak self] (snapshot, error) in
            guard let self = self else { return }
            
            if let error = error {
                print("DEBUG: Error in vote listener: \(error.localizedDescription)")
                return
            }
            
            if let documents = snapshot?.documents {
                print("DEBUG: Vote listener found \(documents.count) documents")
                
                // Reset the votes dictionary
                self.userSubQuestionVotes = [:]
                self.subQuestionVoteDates = [:]
                
                // Process each vote document
                for document in documents {
                    let data = document.data()
                    if let subQuestionId = data["subQuestionId"] as? String,
                       let isYay = data["isYay"] as? Bool,
                       let timestamp = data["timestamp"] as? Timestamp {
                        self.userSubQuestionVotes[subQuestionId] = isYay
                        self.subQuestionVoteDates[subQuestionId] = timestamp.dateValue()
                    }
                }
                
                print("DEBUG: Updated user sub-question votes: \(self.userSubQuestionVotes)")
                print("DEBUG: Updated sub-question vote dates: \(self.subQuestionVoteDates)")
            }
        }
    }
    
    func canVote() -> Bool {
        print("DEBUG: Checking if user can vote")
        print("DEBUG: Current lastVoteDate: \(String(describing: lastVoteDate))")
        
        guard let lastVote = lastVoteDate else {
            print("DEBUG: No previous vote found, allowing vote")
            return true
        }
        
        let calendar = Calendar.current
        let now = Date()
        let components = calendar.dateComponents([.day], from: lastVote, to: now)
        
        let daysSinceLastVote = components.day ?? 0
        print("DEBUG: Days since last vote: \(daysSinceLastVote)")
        
        let canVote = daysSinceLastVote >= 7
        print("DEBUG: Can vote: \(canVote)")
        return canVote
    }
    
    func getCooldownRemaining() -> String {
        guard let lastVote = lastVoteDate else { return "" }
        
        let calendar = Calendar.current
        let now = Date()
        let components = calendar.dateComponents([.day, .hour], from: lastVote, to: now)
        
        let daysRemaining = 7 - (components.day ?? 0)
        let hoursRemaining = 24 - (components.hour ?? 0)
        
        return "\(daysRemaining) days, \(hoursRemaining) hours"
    }
    
    func voteForAttribute(name: String, isYay: Bool) {
        print("DEBUG: Attempting to vote for attribute: \(name)")
        print("DEBUG: Current lastVoteDate before voting: \(String(describing: lastVoteDate))")
        guard let userId = Auth.auth().currentUser?.uid else {
            print("DEBUG: No authenticated user found")
            return
        }
        
        // Record user vote
        let userVote = UserVote(
            userId: userId,
            subCategoryId: self.currentSubCategory.id,
            subQuestionId: nil,
            isYay: isYay,
            itemName: self.currentSubCategory.name,
            categoryName: name,
            categoryId: self.currentSubCategory.categoryId,
            imageURL: self.currentSubCategory.imageURL
        )
        
        print("DEBUG: Recording user vote in Firestore")
        self.db.collection("users").document(userId).collection("votes").document(userVote.id).setData(userVote.dictionary) { error in
            if let error = error {
                print("DEBUG: Error recording user vote: \(error.localizedDescription)")
            } else {
                print("DEBUG: Successfully recorded user vote")
                self.lastVoteDate = Date()
                // Save to UserDefaults
                UserDefaults.standard.set(Date(), forKey: "lastVoteDate_\(self.currentSubCategory.id)")
                print("DEBUG: Updated lastVoteDate to: \(String(describing: self.lastVoteDate))")
            }
        }
        
        // Update the subcategory's vote count
        let docRef = self.db.collection("categories").document(self.currentSubCategory.categoryId).collection("subcategories").document(self.currentSubCategory.id)
        docRef.updateData([
            isYay ? "yayCount" : "nayCount": FieldValue.increment(Int64(1))
        ]) { error in
            if let error = error {
                print("DEBUG: Error updating subcategory vote count: \(error.localizedDescription)")
            } else {
                print("DEBUG: Successfully updated subcategory vote count")
            }
        }
    }
    
    func voteForSubQuestion(_ question: SubQuestion, isYay: Bool) {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        // Only allow voting if the main vote has been reset
        if !canVote() {
            return
        }
        
        let batch = db.batch()
        
        // Reference to the subquestion document
        let subQuestionRef = db.collection("categories")
            .document(currentSubCategory.categoryId)
            .collection("subcategories")
            .document(currentSubCategory.id)
            .collection("subquestions")
            .document(question.id)
        
        // Reference to the user's vote document in the votes subcollection
        let voteRef = subQuestionRef.collection("votes").document(userId)
        
        // Get the current vote (if any)
        voteRef.getDocument { [weak self] (snapshot, error) in
            guard let self = self else { return }
            
                    let batch = self.db.batch()
            let now = Timestamp(date: Date())
            
            if let existingVote = snapshot?.data()?["vote"] as? Bool {
                // Update existing vote
                if existingVote != isYay {
                    // Vote changed, update counts
                    batch.updateData([
                        "yayCount": FieldValue.increment(Int64(isYay ? 1 : -1)),
                        "nayCount": FieldValue.increment(Int64(isYay ? -1 : 1)),
                        "updatedAt": now,
                        "votesMetadata.lastVoteAt": now
                    ], forDocument: subQuestionRef)
                    
                    // Update vote document
                    batch.setData([
                        "userId": userId,
                        "vote": isYay,
                        "timestamp": now,
                        "previousVote": existingVote,
                        "lastChangeAt": now
                    ], forDocument: voteRef, merge: true)
                }
            } else {
                // New vote
                batch.updateData([
                    "yayCount": FIRFieldValue.increment(Int64(isYay ? 1 : 0)),
                    "nayCount": FIRFieldValue.increment(Int64(isYay ? 0 : 1)),
                    "updatedAt": now,
                    "votesMetadata.lastVoteAt": now,
                    "votesMetadata.totalVotes": FIRFieldValue.increment(Int64(1)),
                    "votesMetadata.uniqueVoters": FIRFieldValue.increment(Int64(1))
                ], forDocument: subQuestionRef)
            
            // Create new vote document
                batch.setData([
                    "userId": userId,
                    "vote": isYay,
                    "timestamp": now,
                    "previousVote": nil,
                    "lastChangeAt": nil
                ], forDocument: voteRef)
            }
            
            // Create user vote record for tracking cooldown
            let userVote = UserVote(
                userId: userId,
                subCategoryId: self.currentSubCategory.id,
                subQuestionId: question.id,
                isYay: isYay,
                itemName: self.currentSubCategory.name,
                categoryName: question.question,
                categoryId: self.currentSubCategory.categoryId,
                imageURL: self.currentSubCategory.imageURL
            )
            
            let userVoteRef = self.db.collection("users")
                .document(userId)
                .collection("votes")
                .document(userVote.id)
            batch.setData(userVote.dictionary, forDocument: userVoteRef)
            
            // Commit all changes
            batch.commit { error in
                if let error = error {
                    print("DEBUG: Error updating vote: \(error.localizedDescription)")
                } else {
                    print("DEBUG: Successfully updated vote")
                    self.subQuestionVoteDates[question.id] = Date()
                }
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
        
        isProcessingCommentAction = true
        
        let docRef = db.collection("comments").document(comment.id)
        
        if comment.isLiked {
            // Unlike
            docRef.updateData([
                "likes": FIRFieldValue.increment(Int64(-1)),
                "likedBy.\(userId)": FIRFieldValue.delete()
            ]) { [weak self] error in
                DispatchQueue.main.async {
                    self?.isProcessingCommentAction = false
                    if let error = error {
                        self?.errorMessage = "Failed to unlike comment: \(error.localizedDescription)"
                        self?.showErrorAlert = true
                    }
                }
            }
        } else {
            // Like
            docRef.updateData([
                "likes": FIRFieldValue.increment(Int64(1)),
                "likedBy.\(userId)": true
            ]) { [weak self] error in
                DispatchQueue.main.async {
                    self?.isProcessingCommentAction = false
                    if let error = error {
                        self?.errorMessage = "Failed to like comment: \(error.localizedDescription)"
                        self?.showErrorAlert = true
                    }
                }
            }
        }
    }
    
    func deleteComment(_ comment: Comment) {
        print("DEBUG: Attempting to delete comment: \(comment.id)")
        
        guard let userId = Auth.auth().currentUser?.uid,
              comment.userId == userId else {
            print("DEBUG: Delete failed - User not authorized")
            errorMessage = "You are not authorized to delete this comment"
            showErrorAlert = true
            return
        }
        
        isProcessingCommentAction = true
        recentlyDeletedCommentId = comment.id
        
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
                        DispatchQueue.main.async {
                            self?.isProcessingCommentAction = false
                            self?.recentlyDeletedCommentId = nil
                            self?.errorMessage = "Failed to delete comment: \(error.localizedDescription)"
                            self?.showErrorAlert = true
                        }
                        return
                    }
                    
                    guard let documents = snapshot?.documents else { return }
                    
                    // Add each reply to the batch delete
                    for document in documents {
                        batch.deleteDocument(document.reference)
                    }
                    
                    // Commit the batch delete (includes both parent and replies)
                    batch.commit { error in
                        DispatchQueue.main.async {
                            self?.isProcessingCommentAction = false
                            if let error = error {
                                self?.recentlyDeletedCommentId = nil
                                self?.errorMessage = "Failed to delete comment: \(error.localizedDescription)"
                                self?.showErrorAlert = true
                            } else {
                                print("DEBUG: Successfully deleted comment and its replies")
                                // Keep the recentlyDeletedCommentId for undo functionality
                            }
                        }
                    }
                }
        } else {
            // Just delete the single reply
            batch.commit { [weak self] error in
                DispatchQueue.main.async {
                    self?.isProcessingCommentAction = false
                    if let error = error {
                        self?.recentlyDeletedCommentId = nil
                        self?.errorMessage = "Failed to delete reply: \(error.localizedDescription)"
                        self?.showErrorAlert = true
                    } else {
                        print("DEBUG: Successfully deleted reply")
                        // Keep the recentlyDeletedCommentId for undo functionality
                    }
                }
            }
        }
    }
    
    func undoDeleteComment() {
        guard let commentId = recentlyDeletedCommentId else { return }
        
        isProcessingCommentAction = true
        
        // Restore the comment
        db.collection("comments").document(commentId).getDocument { [weak self] snapshot, error in
            if let error = error {
                DispatchQueue.main.async {
                    self?.isProcessingCommentAction = false
                    self?.errorMessage = "Failed to restore comment: \(error.localizedDescription)"
                    self?.showErrorAlert = true
                }
                return
            }
            
            guard let data = snapshot?.data() else {
                DispatchQueue.main.async {
                    self?.isProcessingCommentAction = false
                    self?.recentlyDeletedCommentId = nil
                }
                return
            }
            
            // Restore the comment
            self?.db.collection("comments").document(commentId).setData(data) { error in
                DispatchQueue.main.async {
                    self?.isProcessingCommentAction = false
                    self?.recentlyDeletedCommentId = nil
                    if let error = error {
                        self?.errorMessage = "Failed to restore comment: \(error.localizedDescription)"
                        self?.showErrorAlert = true
                    }
                }
            }
        }
    }
    
    var hasVoted: Bool {
        print("DEBUG: Checking hasVoted - lastVoteDate is \(String(describing: lastVoteDate))")
        return lastVoteDate != nil
    }
    
    func resetVote(completion: @escaping (Bool) -> Void) {
        print("DEBUG: Resetting sub-question votes for user")
        
        guard let userId = Auth.auth().currentUser?.uid else {
            print("DEBUG: No authenticated user found")
            completion(false)
            return
        }
        
        // Get all votes for this user and subcategory
        let votesRef = db.collection("users").document(userId).collection("votes")
            .whereField("subCategoryId", isEqualTo: currentSubCategory.id)
            .whereField("subQuestionId", isNotEqualTo: NSNull())
        
        votesRef.getDocuments { [weak self] (snapshot, error) in
            guard let self = self else {
                completion(false)
                return
            }
            
            if let error = error {
                print("DEBUG: Error fetching votes: \(error.localizedDescription)")
                completion(false)
                return
            }
            
            guard let documents = snapshot?.documents, !documents.isEmpty else {
                print("DEBUG: No votes found to reset")
                completion(true)
                return
            }
            
            let batch = self.db.batch()
            
            // Update each vote to have a new timestamp
            for document in documents {
                let voteRef = self.db.collection("users").document(userId).collection("votes").document(document.documentID)
                batch.updateData([
                    "timestamp": Timestamp(date: Date())
                ], forDocument: voteRef)
            }
            
            // Commit the batch update
            batch.commit { error in
                if let error = error {
                    print("DEBUG: Error updating votes: \(error.localizedDescription)")
                    completion(false)
                } else {
                    print("DEBUG: Successfully reset votes")
        // Update the UI
                    self.objectWillChange.send()
                    completion(true)
                }
            }
        }
    }
    
    func refreshData(completion: @escaping (Bool) -> Void) {
        print("DEBUG: Starting data refresh")
        
        // Refresh all listeners
        setupListeners()
        setupCommentsListener()
        setupSubQuestionsListener()
        setupUserVotesListener()
        
        // Force a refresh of the current subcategory
        let docRef = db.collection("categories").document(currentSubCategory.categoryId).collection("subcategories").document(currentSubCategory.id)
        docRef.getDocument { [weak self] (snapshot, error) in
            guard let self = self else {
                completion(false)
                return
            }
            
            if let error = error {
                print("DEBUG: Error refreshing subcategory: \(error.localizedDescription)")
                completion(false)
                return
            }
            
            if let updatedSubCategory = SubCategory(document: snapshot!) {
                self.currentSubCategory = updatedSubCategory
                print("DEBUG: Subcategory refreshed successfully")
                completion(true)
            } else {
                print("DEBUG: Failed to parse refreshed subcategory")
                completion(false)
            }
        }
    }
    
    func vote(_ isYay: Bool) {
        // Check if user has already voted
        if let lastVoteDate = lastVoteDate {
            let calendar = Calendar.current
            let components = calendar.dateComponents([.day], from: lastVoteDate, to: Date())
            if let days = components.day, days < 7 {
                // Show cooldown alert
                showCooldownAlert = true
                return
            }
        }
        
        // Save the vote
        UserDefaults.standard.set(isYay, forKey: "vote_\(currentSubCategory.id)")
        UserDefaults.standard.set(Date(), forKey: "lastVoteDate_\(currentSubCategory.id)")
        
        // Update the stored property
        lastVoteDate = Date()
        
        // Update the UI
        objectWillChange.send()
    }
    
    func hasVotedForSubQuestion(_ subQuestionId: String) -> Bool {
        return userSubQuestionVotes[subQuestionId] != nil
    }
    
    func canVoteForSubQuestions() -> Bool {
        guard let lastVote = subQuestionVoteDates.values.first else {
            return true
        }
        
        let calendar = Calendar.current
        let now = Date()
        let components = calendar.dateComponents([.day], from: lastVote, to: now)
        
        let daysSinceLastVote = components.day ?? 0
        return daysSinceLastVote >= 7
    }
    
    func getNextVoteDateForSubQuestions() -> Date? {
        guard let lastVote = subQuestionVoteDates.values.first else {
            return nil
        }
        
        return Calendar.current.date(byAdding: .day, value: 7, to: lastVote)
    }
    
    func canVoteForSubQuestion(_ subQuestionId: String) -> Bool {
        guard let lastVoteDate = subQuestionVoteDates[subQuestionId] else {
            return true
        }
        
        let calendar = Calendar.current
        let now = Date()
        let components = calendar.dateComponents([.day], from: lastVoteDate, to: now)
        
        let daysSinceLastVote = components.day ?? 0
        return daysSinceLastVote >= 7
    }
    
    func getNextVoteDateForSubQuestion(_ subQuestionId: String) -> Date? {
        guard let lastVote = subQuestionVoteDates[subQuestionId] else {
            return nil
        }
        
        return Calendar.current.date(byAdding: .day, value: 7, to: lastVote)
    }
    
    // Helper method to get vote history for a subquestion
    func getVoteHistory(for subQuestionId: String) -> [UserVote] {
        return subQuestionVoteHistory[subQuestionId] ?? []
    }
    
    // Helper method to get unique voters count for a subquestion
    func getUniqueVotersCount(for subQuestionId: String) -> Int {
        let votes = subQuestionVoteHistory[subQuestionId] ?? []
        return Set(votes.map { $0.userId }).count
    }
    
    // Helper method to get vote distribution over time
    func getVoteDistribution(for subQuestionId: String, timeframe: TimeInterval = 86400) -> [(Date, Int, Int)] {
        let votes = subQuestionVoteHistory[subQuestionId] ?? []
        let now = Date()
        let startDate = now.addingTimeInterval(-timeframe)
        
        // Group votes by day
        let calendar = Calendar.current
        var distribution: [(Date, Int, Int)] = []
        
        let groupedVotes = Dictionary(grouping: votes) { vote in
            calendar.startOfDay(for: vote.timestamp)
        }
        
        var currentDate = calendar.startOfDay(for: startDate)
        let endDate = calendar.startOfDay(for: now)
        
        while currentDate <= endDate {
            let dayVotes = groupedVotes[currentDate] ?? []
            let yayVotes = dayVotes.filter { $0.isYay }.count
            let nayVotes = dayVotes.filter { !$0.isYay }.count
            distribution.append((currentDate, yayVotes, nayVotes))
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate
        }
        
        return distribution
    }
} 