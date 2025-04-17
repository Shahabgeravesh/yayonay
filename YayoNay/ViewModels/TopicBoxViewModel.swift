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
    
    private let db = Firestore.firestore()
    private var listener: ListenerRegistration?
    
    enum SortOption: String, CaseIterable {
        case date = "Date"
        case mostPopular = "Most Popular"
        case saved = "Saved"
    }
    
    func fetchTopics() {
        listener?.remove()
        
        let baseQuery = db.collection("topics")
        
        let sortedQuery: Query
        switch sortOption {
        case .date:
            sortedQuery = baseQuery.order(by: "date", descending: true)
        case .mostPopular:
            sortedQuery = baseQuery.order(by: "upvotes", descending: true)
        case .saved:
            sortedQuery = baseQuery.order(by: "date", descending: true)
        }
        
        listener = sortedQuery.addSnapshotListener { [weak self] snapshot, error in
            guard let self = self,
                  let documents = snapshot?.documents else {
                print("Error fetching topics: \(error?.localizedDescription ?? "Unknown error")")
                return
            }
            
            self.topics = documents.compactMap { document in
                Topic(document: document)
            }
        }
    }
    
    func submitTopic(title: String, mediaURL: String, tags: [String], category: String, description: String) {
        guard !title.isEmpty,
              let userId = Auth.auth().currentUser?.uid else { return }
        
        isLoading = true
        
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
                userImage: userProfile.imageURL ?? "",
                userId: userId
            )
            
            // Add to Firestore
            self.db.collection("topics").document(topic.id).setData(topic.dictionary) { [weak self] error in
                guard let self = self else { return }
                
                DispatchQueue.main.async {
                    self.isLoading = false
                    if let error = error {
                        self.error = error
                    } else {
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