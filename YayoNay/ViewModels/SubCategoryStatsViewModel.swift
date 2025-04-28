import SwiftUI
import FirebaseFirestore
import FirebaseAuth

class SubCategoryStatsViewModel: ObservableObject {
    @Published var attributeVotes: [String: AttributeVotes] = [:]
    @Published var comments: [Comment] = []
    @Published var currentSubCategory: SubCategory
    @Published var subQuestions: [SubQuestion] = []
    @Published var showCooldownAlert = false
    @Published private(set) var lastVoteDate: Date?
    private let db = Firestore.firestore()
    private var attributeListener: ListenerRegistration?
    private var subCategoryListener: ListenerRegistration?
    private var commentsListener: ListenerRegistration?
    private var subQuestionsListener: ListenerRegistration?
    private var userVotesListener: ListenerRegistration?
    
    init(subCategory: SubCategory) {
        print("DEBUG: Initializing SubCategoryStatsViewModel for subCategory: \(subCategory.id)")
        self.currentSubCategory = subCategory
        self.lastVoteDate = UserDefaults.standard.object(forKey: "lastVoteDate_\(subCategory.id)") as? Date
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
        print("DEBUG: Setting up sub-questions listener")
        let subQuestionsRef = db.collection("subQuestions")
            .whereField("categoryId", isEqualTo: currentSubCategory.categoryId)
            .whereField("subCategoryId", isEqualTo: currentSubCategory.id)
        
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
                for question in questions {
                    print("DEBUG: Question: \(question.question), Yay: \(question.yayCount), Nay: \(question.nayCount)")
            }
        }
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
        let votesRef = db.collection("votes")
            .whereField("userId", isEqualTo: userId)
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
                
                // Find the most recent vote
                let latestVote = documents.compactMap { UserVote(document: $0) }
                    .sorted(by: { $0.timestamp > $1.timestamp })
                    .first
                
                if let latestVote = latestVote {
                    print("DEBUG: Found previous vote from \(latestVote.timestamp)")
                    print("DEBUG: Vote details - User: \(latestVote.userId), SubCategory: \(latestVote.subCategoryId)")
                    self.lastVoteDate = latestVote.timestamp
                } else {
                    print("DEBUG: No previous votes found for this user and subcategory")
                    self.lastVoteDate = nil
                }
            } else {
                print("DEBUG: No vote documents found")
                self.lastVoteDate = nil
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
                
                // Find the most recent vote
                let latestVote = documents.compactMap { UserVote(document: $0) }
                    .sorted(by: { $0.timestamp > $1.timestamp })
                    .first
                
                if let latestVote = latestVote {
                    print("DEBUG: Updated last vote date to: \(latestVote.timestamp)")
                    self.lastVoteDate = latestVote.timestamp
                }
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
        guard let userId = Auth.auth().currentUser?.uid else {
            print("DEBUG: No authenticated user found")
            return
        }
        
        print("DEBUG: User ID: \(userId)")
        print("DEBUG: Current lastVoteDate: \(String(describing: lastVoteDate))")
        
        // First, check for existing votes
        let votesRef = db.collection("votes")
            .whereField("userId", isEqualTo: userId)
            .whereField("subCategoryId", isEqualTo: currentSubCategory.id)
        
        print("DEBUG: Checking for existing votes")
        
        votesRef.getDocuments { [weak self] (snapshot, error) in
            guard let self = self else { return }
            
            if let error = error {
                print("DEBUG: Error checking for existing votes: \(error.localizedDescription)")
                return
            }
            
            if let documents = snapshot?.documents {
                print("DEBUG: Found \(documents.count) vote documents")
                
                // Find the most recent vote
                let latestVote = documents.compactMap { UserVote(document: $0) }
                    .sorted(by: { $0.timestamp > $1.timestamp })
                    .first
                
                if let latestVote = latestVote {
                    print("DEBUG: Found previous vote from \(latestVote.timestamp)")
                    self.lastVoteDate = latestVote.timestamp
                    
                    let calendar = Calendar.current
                    let now = Date()
                    let components = calendar.dateComponents([.day], from: latestVote.timestamp, to: now)
                    let daysSinceLastVote = components.day ?? 0
                    
                    print("DEBUG: Days since last vote: \(daysSinceLastVote)")
                    
                    if daysSinceLastVote < 7 {
                        print("DEBUG: Cannot vote - cooldown period active")
                        self.showCooldownAlert = true
                        return
                    }
                }
            }
            
            print("DEBUG: Proceeding with vote")
            
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
            
            print("DEBUG: Recording user vote - User: \(userId), SubCategory: \(self.currentSubCategory.id)")
            
            self.db.collection("votes").document(userVote.id).setData(userVote.dictionary) { error in
                if let error = error {
                    print("DEBUG: Error recording user vote: \(error.localizedDescription)")
                } else {
                    print("DEBUG: Successfully recorded user vote")
                    self.lastVoteDate = Date()
                    print("DEBUG: Updated lastVoteDate to: \(Date())")
            }
        }
        
        // Update the subcategory's vote count
            let docRef = self.db.collection("subCategories").document(self.currentSubCategory.id)
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
    }
    
    func voteForSubQuestion(_ question: SubQuestion, isYay: Bool) {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        // Only allow voting if the main vote has been reset
        if !canVote() {
            return
        }
        
        // First, check for existing votes
        let votesRef = db.collection("votes")
            .whereField("userId", isEqualTo: userId)
            .whereField("subQuestionId", isEqualTo: question.id)
        
        votesRef.getDocuments { [weak self] (snapshot, error) in
            guard let self = self else { return }
            
            if let error = error {
                print("DEBUG: Error checking for existing votes: \(error.localizedDescription)")
                return
            }
            
            if let documents = snapshot?.documents {
                let latestVote = documents.compactMap { document -> (id: String, date: Date, isYay: Bool)? in
                    if let timestamp = document.data()["timestamp"] as? Timestamp,
                       let isYay = document.data()["isYay"] as? Bool {
                        return (id: document.documentID, date: timestamp.dateValue(), isYay: isYay)
                    }
                    return nil
                }.sorted(by: { $0.date > $1.date }).first
                
                if let latestVote = latestVote {
                    // Update existing vote
                    let batch = self.db.batch()
                    
                    // Update the vote document
                    let voteRef = self.db.collection("votes").document(latestVote.id)
                    let voteData: [String: Any] = [
                        "isYay": isYay,
                        "timestamp": Timestamp(date: Date())
                    ]
                    batch.updateData(voteData, forDocument: voteRef)
                    
                    // Update sub-question counts
                    let subQuestionRef = self.db.collection("subQuestions").document(question.id)
                    let updateData: [String: Any] = [
                        // Decrement the old vote count
                        latestVote.isYay ? "yayCount" : "nayCount": FieldValue.increment(Int64(-1)),
                        // Increment the new vote count
                        isYay ? "yayCount" : "nayCount": FieldValue.increment(Int64(1))
                    ]
                    batch.updateData(updateData, forDocument: subQuestionRef)
                    
                    batch.commit { error in
                        if let error = error {
                            print("DEBUG: Error updating vote: \(error.localizedDescription)")
                        } else {
                            print("DEBUG: Successfully updated vote")
                        }
                    }
                    return
                }
            }
            
            // If no existing vote, create new vote
            let batch = self.db.batch()
            
            // Create new vote document
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
            
            let voteRef = self.db.collection("votes").document(userVote.id)
            batch.setData(userVote.dictionary, forDocument: voteRef)
            
            // Update sub-question counts
            let subQuestionRef = self.db.collection("subQuestions").document(question.id)
            let updateData: [String: Any] = isYay ? 
                ["yayCount": FieldValue.increment(Int64(1))] : 
                ["nayCount": FieldValue.increment(Int64(1))]
            batch.updateData(updateData, forDocument: subQuestionRef)
            
            batch.commit { error in
                if let error = error {
                    print("DEBUG: Error recording vote: \(error.localizedDescription)")
                } else {
                    print("DEBUG: Successfully recorded new vote")
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
                    
                    // Add each reply to the batch delete
                    for document in documents {
                        batch.deleteDocument(document.reference)
                    }
                    
                    // Commit the batch delete (includes both parent and replies)
                    batch.commit { error in
                        if let error = error {
                            print("DEBUG: Error deleting comment and replies: \(error.localizedDescription)")
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
    
    var hasVoted: Bool {
        return lastVoteDate != nil
    }
    
    func resetVote() {
        // Remove the vote from UserDefaults
        UserDefaults.standard.removeObject(forKey: "lastVoteDate_\(currentSubCategory.id)")
        UserDefaults.standard.removeObject(forKey: "vote_\(currentSubCategory.id)")
        
        // Update the stored property
        lastVoteDate = nil
        
        // Update the UI
        objectWillChange.send()
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
} 