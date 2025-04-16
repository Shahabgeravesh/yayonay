import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct VotingView: View {
    @StateObject private var viewModel: VotingViewModel
    @EnvironmentObject var userManager: UserManager
    
    init(category: String) {
        _viewModel = StateObject(wrappedValue: VotingViewModel(category: category))
    }
    
    init(topic: Topic) {
        _viewModel = StateObject(wrappedValue: VotingViewModel(topic: topic))
    }
    
    var body: some View {
        VStack(spacing: 20) {
            // Topic Display
            Text(viewModel.topic.title)
                .font(AppFont.bold(24))
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            // Options
            VStack(spacing: 16) {
                // Option A
                voteButton(choice: viewModel.topic.optionA)
                
                // Option B
                voteButton(choice: viewModel.topic.optionB)
            }
            .padding()
            
            if viewModel.isLoading {
                ProgressView()
                    .scaleEffect(1.5)
            }
        }
        .alert("Error", isPresented: .constant(viewModel.error != nil)) {
            Button("OK") { viewModel.error = nil }
        } message: {
            if let error = viewModel.error {
                Text(error.localizedDescription)
            }
        }
    }
    
    private func voteButton(choice: String) -> some View {
        Button(action: { handleVote(choice: choice) }) {
            Text(choice)
                .font(AppFont.medium(16))
                .frame(maxWidth: .infinity)
                .padding()
                .background(AppColor.secondaryBackground)
                .foregroundStyle(AppColor.text)
                .cornerRadius(12)
        }
        .disabled(viewModel.isLoading)
    }
    
    private func handleVote(choice: String) {
        print("🎯 Starting vote submission for choice: \(choice)")
        viewModel.submitVote(choice: choice) { success in
            if success {
                print("✅ Vote submission completed successfully")
                // Remove redundant calls since we're handling these in the batch write
                // userManager.incrementVoteCount()
                // userManager.addRecentActivity(
                //     type: "vote",
                //     itemId: viewModel.topic.id
                // )
            } else {
                print("❌ Vote submission failed")
            }
        }
    }
}

class VotingViewModel: ObservableObject {
    @Published var topic: Topic
    @Published var isLoading = false
    @Published var error: Error?
    private let db = Firestore.firestore()
    private var currentIndex = 0
    private var topics: [Topic] = []
    
    init(topic: Topic) {
        self.topic = topic
    }
    
    init(category: String) {
        self.topic = Topic(
            id: "",
            title: "Loading...",
            userImage: "",
            userId: ""
        )
        fetchTopicsForCategory(category)
    }
    
    private func fetchTopicsForCategory(_ category: String) {
        isLoading = true
        
        // Simplified query that doesn't require a composite index
        db.collection("topics")
            .whereField("category", isEqualTo: category)
            .getDocuments { [weak self] snapshot, error in
                guard let self = self else { return }
                
                DispatchQueue.main.async {
                    self.isLoading = false
                    
                    if let error = error {
                        self.error = error
                        return
                    }
                    
                    // Sort the topics in memory instead of in the query
                    self.topics = snapshot?.documents.compactMap { Topic(document: $0) } ?? []
                    self.topics.sort { $0.date > $1.date }  // Sort by date descending
                    
                    if let firstTopic = self.topics.first {
                        self.topic = firstTopic
                    }
                }
            }
    }
    
    func nextTopic() {
        guard currentIndex < topics.count - 1 else { return }
        currentIndex += 1
        topic = topics[currentIndex]
    }
    
    func previousTopic() {
        guard currentIndex > 0 else { return }
        currentIndex -= 1
        topic = topics[currentIndex]
    }
    
    func submitVote(choice: String, completion: @escaping (Bool) -> Void) {
        guard let userId = Auth.auth().currentUser?.uid else {
            print("❌ No user ID available for vote submission")
            completion(false)
            return
        }
        
        print("📝 Starting vote submission process")
        print("User ID: \(userId)")
        print("Topic ID: \(topic.id)")
        print("Choice: \(choice)")
        
        isLoading = true
        
        // Create vote document
        let voteData: [String: Any] = [
            "userId": userId,
            "topicId": topic.id,
            "choice": choice,
            "timestamp": Timestamp(date: Date())
        ]
        
        print("📄 Created vote data: \(voteData)")
        
        // Create a batch write
        let batch = db.batch()
        print("🔄 Created batch write operation")
        
        // Add vote document
        let voteRef = db.collection("votes").document()
        batch.setData(voteData, forDocument: voteRef)
        print("📝 Added vote document to batch")
        
        // Update topic's vote counts
        let topicRef = db.collection("topics").document(topic.id)
        let isYay = choice == topic.optionA
        let updateData: [String: Any] = isYay ? 
            ["upvotes": FieldValue.increment(Int64(1))] : 
            ["downvotes": FieldValue.increment(Int64(1))]
        batch.updateData(updateData, forDocument: topicRef)
        print("📊 Added topic vote count update to batch: \(updateData)")
        
        // Update user profile
        let userRef = db.collection("users").document(userId)
        batch.updateData([
            "votesCount": FieldValue.increment(Int64(1)),
            "lastVoteDate": Timestamp(date: Date())
        ], forDocument: userRef)
        print("👤 Added user profile update to batch")
        
        // Add recent activity
        let activity = [
            "type": "vote",
            "itemId": topic.id,
            "title": topic.title,
            "timestamp": Timestamp(date: Date())
        ] as [String: Any]
        batch.updateData([
            "recentActivity": FieldValue.arrayUnion([activity])
        ], forDocument: userRef)
        print("📝 Added recent activity to batch: \(activity)")
        
        // Commit the batch
        print("🚀 Committing batch write...")
        batch.commit { [weak self] error in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                self.isLoading = false
                
                if let error = error {
                    print("❌ Batch write failed: \(error.localizedDescription)")
                    self.error = error
                    completion(false)
                } else {
                    print("✅ Batch write completed successfully")
                    // Update the local topic object
                    if isYay {
                        self.topic.upvotes += 1
                    } else {
                        self.topic.downvotes += 1
                    }
                    print("📊 Updated local topic counts - Upvotes: \(self.topic.upvotes), Downvotes: \(self.topic.downvotes)")
                    completion(true)
                }
            }
        }
    }
}

struct VoteBarView: View {
    let yayCount: Int
    let nayCount: Int
    let userVote: Bool?
    
    private var totalVotes: Int {
        yayCount + nayCount
    }
    
    private var yayPercentage: Double {
        guard totalVotes > 0 else { return 0 }
        return Double(yayCount) / Double(totalVotes) * 100
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Vote counts text
            HStack {
                Text("Yay: \(Int(yayPercentage))%")
                    .foregroundColor(.green)
                Spacer()
                Text("Nay: \(100 - Int(yayPercentage))%")
                    .foregroundColor(.red)
            }
            .font(.caption)
            
            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background bar (Nay)
                    Rectangle()
                        .fill(Color.red.opacity(0.3))
                        .frame(height: 8)
                        .cornerRadius(4)
                    
                    // Foreground bar (Yay)
                    Rectangle()
                        .fill(Color.green.opacity(0.7))
                        .frame(width: geometry.size.width * CGFloat(yayPercentage / 100), height: 8)
                        .cornerRadius(4)
                }
            }
            .frame(height: 8)
            
            // Total votes
            Text("\(totalVotes) votes")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 5, y: 2)
    }
}

struct VoteResultRow: View {
    let name: String
    let votes: AttributeVotes
    let onVote: (Bool) -> Void
    @State private var userVote: Bool?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(name)
                .font(.headline)
            
            if let _ = userVote {
                // Show results bar after voting
                VoteBarView(
                    yayCount: votes.yayCount,
                    nayCount: votes.nayCount,
                    userVote: userVote
                )
            } else {
                // Show voting buttons if user hasn't voted
                HStack(spacing: 16) {
                    Button(action: {
                        userVote = true
                        onVote(true)
                    }) {
                        Text("Yay")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.green.opacity(0.2))
                            .foregroundColor(.green)
                            .cornerRadius(8)
                    }
                    
                    Button(action: {
                        userVote = false
                        onVote(false)
                    }) {
                        Text("Nay")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.red.opacity(0.2))
                            .foregroundColor(.red)
                            .cornerRadius(8)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 5, y: 2)
    }
}

#Preview {
    VotingView(topic: Topic(
        id: "preview",
        title: "Sample Topic",
        optionA: "Option A",
        optionB: "Option B",
        userImage: "https://picsum.photos/200",
        userId: "user123"
    ))
    .environmentObject(UserManager())
} 