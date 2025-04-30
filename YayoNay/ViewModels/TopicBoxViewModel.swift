import SwiftUI
import FirebaseFirestore
import FirebaseAuth
import Foundation

class TopicBoxViewModel: ObservableObject {
    @Published var topics: [Topic] = []
    @Published var sortOption: SortOption = .date
    @Published var showSubmitSheet = false
    @Published var newTopicTitle = ""
    @Published var error: Error?
    @Published var isLoading = false
    @Published var dailySubmissionCount = 0
    @Published var lastSubmissionDate: Date?
    
    static let availableCategories = [
        "General",
        "Technology",
        "Entertainment",
        "Sports",
        "Politics",
        "Science",
        "Health",
        "Education",
        "Business",
        "Art",
        "Food",
        "Travel",
        "Fashion",
        "Gaming",
        "Music"
    ]
    
    private let db = Firestore.firestore()
    private var listener: ListenerRegistration?
    let DAILY_SUBMISSION_LIMIT = 5
    
    enum SortOption: String, CaseIterable {
        case date = "Date"
        case mostPopular = "Most Popular"
    }
    
    var sortedTopics: [Topic] {
        switch sortOption {
        case .date:
            return topics.sorted { $0.date > $1.date }
        case .mostPopular:
            return topics.sorted {
                if $0.upvotes != $1.upvotes {
                    return $0.upvotes > $1.upvotes
                } else {
                    return $0.date > $1.date
                }
            }
        }
    }
    
    func fetchTopics() {
        listener?.remove()
        
        let baseQuery = db.collection("topics")
        
        listener = baseQuery.addSnapshotListener { [weak self] snapshot, error in
            guard let self = self,
                  let documents = snapshot?.documents else {
                print("Error fetching topics: \(error?.localizedDescription ?? "Unknown error")")
                return
            }
            
            self.topics = documents.compactMap { document in
                Topic(document: document)
            }
        }
        
        // Load user's submission count
        loadUserSubmissionCount()
    }
    
    private func loadUserSubmissionCount() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        // Get today's date at midnight
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        // Get user's document
        db.collection("users").document(userId).getDocument { [weak self] snapshot, error in
            guard let self = self else { return }
            
            if let error = error {
                print("Error loading user document: \(error.localizedDescription)")
                return
            }
            
            guard let data = snapshot?.data() else { return }
            
            // Get last submission date and count
            if let lastSubmissionTimestamp = data["lastSubmissionDate"] as? Timestamp {
                let lastSubmissionDate = lastSubmissionTimestamp.dateValue()
                
                // If last submission was today, use stored count
                if calendar.isDateInToday(lastSubmissionDate) {
                    self.dailySubmissionCount = data["dailySubmissionCount"] as? Int ?? 0
                    self.lastSubmissionDate = lastSubmissionDate
                    } else {
                    // Reset count if last submission was not today
                    self.dailySubmissionCount = 0
                    self.lastSubmissionDate = nil
                    
                    // Update Firestore with reset values
                    self.db.collection("users").document(userId).updateData([
                        "dailySubmissionCount": 0,
                        "lastSubmissionDate": Timestamp(date: today)
                    ])
                }
            }
        }
    }
    
    func submitTopic(title: String, mediaURL: String, tags: [String], category: String, description: String) {
        guard !title.isEmpty,
              let userId = Auth.auth().currentUser?.uid else { return }
        
        isLoading = true
        
        // First check if user has reached daily limit
        let calendar = Calendar.current
        if let lastDate = lastSubmissionDate,
           calendar.isDateInToday(lastDate),
           dailySubmissionCount >= DAILY_SUBMISSION_LIMIT {
            DispatchQueue.main.async {
                self.error = NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "You have reached your daily limit of 5 topic submissions. Please try again tomorrow."])
                self.isLoading = false
            }
            return
        }
        
        // First get the user profile to get the username and image
        db.collection("users").document(userId).getDocument { [weak self] snapshot, error in
            guard let self = self else { return }
            
            if let error = error {
                DispatchQueue.main.async {
                    self.error = error
                    self.isLoading = false
                }
                return
            }
            
            guard let userProfile = UserProfile(document: snapshot!) else {
                DispatchQueue.main.async {
                    self.error = NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Could not get user profile"])
                    self.isLoading = false
                }
                return
            }
            
            // Create the topic with all fields
            let topic = Topic(
                title: title,
                mediaURL: mediaURL.isEmpty ? nil : mediaURL,
                description: description,
                tags: tags,
                category: category,
                userImage: userProfile.imageURL ?? "https://firebasestorage.googleapis.com/v0/b/yayonay-e7f58.appspot.com/o/default_profile.png?alt=media",
                userId: userId
            )
            
            // Create a batch write to update both the topic and user's submission count
            let batch = self.db.batch()
            
            // Add topic document
            let topicRef = self.db.collection("topics").document(topic.id)
            batch.setData(topic.dictionary, forDocument: topicRef)
            
            // Update user's submission count
            let userRef = self.db.collection("users").document(userId)
            let newCount = self.dailySubmissionCount + 1
            batch.updateData([
                "dailySubmissionCount": newCount,
                "lastSubmissionDate": Timestamp(date: Date())
            ], forDocument: userRef)
            
            // Commit the batch
            batch.commit { [weak self] error in
                guard let self = self else { return }
                
                DispatchQueue.main.async {
                    self.isLoading = false
                    if let error = error {
                        self.error = error
                    } else {
                        // Update local state
                        self.dailySubmissionCount = newCount
                        self.lastSubmissionDate = Date()
                        self.showSubmitSheet = false
                    }
                }
            }
        }
    }
    
    func vote(for topic: Topic, isUpvote: Bool) {
        let docRef = db.collection("topics").document(topic.id)
        
        guard let index = topics.firstIndex(where: { $0.id == topic.id }) else { return }
        var updatedTopic = topics[index]
        
        // Handle vote toggling
        switch (isUpvote, updatedTopic.userVoteStatus) {
        case (true, .upvoted):
            updatedTopic.upvotes -= 1
            updatedTopic.userVoteStatus = .none
        case (true, .downvoted):
            updatedTopic.downvotes -= 1
            updatedTopic.upvotes += 1
            updatedTopic.userVoteStatus = .upvoted
        case (true, .none):
            updatedTopic.upvotes += 1
            updatedTopic.userVoteStatus = .upvoted
        case (false, .downvoted):
            updatedTopic.downvotes -= 1
            updatedTopic.userVoteStatus = .none
        case (false, .upvoted):
            updatedTopic.upvotes -= 1
            updatedTopic.downvotes += 1
            updatedTopic.userVoteStatus = .downvoted
        case (false, .none):
            updatedTopic.downvotes += 1
            updatedTopic.userVoteStatus = .downvoted
        }
        
        topics[index] = updatedTopic
        
        docRef.setData(updatedTopic.dictionary) { error in
            if let error = error {
                print("Error voting: \(error.localizedDescription)")
                self.topics[index] = topic
            }
        }
    }
    
    func shareTopic(_ topic: Topic) {
        ShareManager.shared.shareContent(for: topic)
    }
    
    func shareViaMessage(_ topic: Topic) {
        ShareManager.shared.shareViaMessage(for: topic)
    }
    
    deinit {
        listener?.remove()
    }
    
    private func createUserProfile() -> UserProfile {
        guard let userId = Auth.auth().currentUser?.uid else {
            return UserProfile(
                id: UUID().uuidString,
                username: "User\(Int.random(in: 1000...9999))",
                imageURL: "https://firebasestorage.googleapis.com/v0/b/yayonay-e7f58.appspot.com/o/default_profile.png?alt=media",
                email: nil,
                bio: "",
                votesCount: 0,
                lastVoteDate: Date(),
                topInterests: []
            )
        }
        
        return UserProfile(
            id: userId,
            username: "User\(Int.random(in: 1000...9999))",
            imageURL: "https://firebasestorage.googleapis.com/v0/b/yayonay-e7f58.appspot.com/o/default_profile.png?alt=media",
            email: nil,
            bio: "",
            votesCount: 0,
            lastVoteDate: Date(),
            topInterests: []
        )
    }
} 