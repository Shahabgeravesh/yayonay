import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct VotingView: View {
    @StateObject private var viewModel: VotingViewModel
    @EnvironmentObject var userManager: UserManager
    @State private var offset: CGSize = .zero
    @State private var scale: CGFloat = 1.0
    @State private var rotation: Double = 0
    @State private var showVoteFeedback = false
    @State private var voteChoice: String = ""
    @State private var isAnimating = false
    
    init(category: String) {
        _viewModel = StateObject(wrappedValue: VotingViewModel(category: category))
    }
    
    init(topic: Topic) {
        _viewModel = StateObject(wrappedValue: VotingViewModel(topic: topic))
    }
    
    var body: some View {
        ZStack {
            // Background
            Color(.systemGroupedBackground)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Topic Card
                ZStack {
                    // Card
                    VStack(spacing: 24) {
                        // Topic Title
            Text(viewModel.topic.title)
                            .font(.system(size: 32, weight: .bold))
                .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                            .padding(.top, 40)
                        
                        Spacer()
            
                        // Vote Buttons
                        HStack(spacing: 24) {
                            // Nay Button
                            voteButton(choice: viewModel.topic.optionB, isYay: false)
                            
                            // Yay Button
                            voteButton(choice: viewModel.topic.optionA, isYay: true)
                        }
                        .padding(.bottom, 40)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 30)
                            .fill(Color(.systemBackground))
                            .shadow(color: Color.black.opacity(0.1), radius: 20, x: 0, y: 10)
                    )
                    .offset(offset)
                    .scaleEffect(scale)
                    .rotationEffect(.degrees(rotation))
                    .gesture(
                        DragGesture()
                            .onChanged { gesture in
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    offset = gesture.translation
                                    rotation = Double(gesture.translation.width / 20)
                                    scale = 1.0 - abs(gesture.translation.width / 1000)
                                }
                            }
                            .onEnded { gesture in
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    if abs(gesture.translation.width) > 100 {
                                        let isYay = gesture.translation.width > 0
                                        handleSwipe(isYay: isYay)
                                    } else {
                                        offset = .zero
                                        rotation = 0
                                        scale = 1.0
                                    }
                                }
                            }
                    )
                    
                    // Vote Feedback
                    if showVoteFeedback {
                        VStack {
                            Image(systemName: voteChoice == viewModel.topic.optionA ? "hand.thumbsup.fill" : "hand.thumbsdown.fill")
                                .font(.system(size: 60))
                                .foregroundColor(voteChoice == viewModel.topic.optionA ? .green : .red)
                                .padding()
                                .background(
                                    Circle()
                                        .fill(.ultraThinMaterial)
                                        .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 5)
                                )
                        }
                        .transition(.scale.combined(with: .opacity))
                    }
            }
            .padding()
            
                // Navigation Buttons
                HStack(spacing: 24) {
                    Button(action: viewModel.previousTopic) {
                        Image(systemName: "arrow.left.circle.fill")
                            .font(.system(size: 44))
                            .foregroundColor(.gray)
                            .background(
                                Circle()
                                    .fill(.ultraThinMaterial)
                                    .frame(width: 50, height: 50)
                            )
                    }
                    
                    Button(action: viewModel.nextTopic) {
                        Image(systemName: "arrow.right.circle.fill")
                            .font(.system(size: 44))
                            .foregroundColor(.gray)
                            .background(
                                Circle()
                                    .fill(.ultraThinMaterial)
                                    .frame(width: 50, height: 50)
                            )
                    }
                }
                .padding(.top, 20)
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
    
    private func voteButton(choice: String, isYay: Bool) -> some View {
        Button(action: { handleVote(choice: choice) }) {
            VStack(spacing: 12) {
                Image(systemName: isYay ? "hand.thumbsup.fill" : "hand.thumbsdown.fill")
                    .font(.system(size: 28))
            Text(choice)
                    .font(.system(size: 18, weight: .medium))
            }
                .frame(maxWidth: .infinity)
                .padding()
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(isYay ? Color.green.opacity(0.1) : Color.red.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        isYay ? Color.green.opacity(0.3) : Color.red.opacity(0.3),
                                        isYay ? Color.green.opacity(0.1) : Color.red.opacity(0.1)
                                    ]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
            )
            .foregroundColor(isYay ? .green : .red)
        }
        .disabled(viewModel.isLoading)
    }
    
    private func handleSwipe(isYay: Bool) {
        let choice = isYay ? viewModel.topic.optionA : viewModel.topic.optionB
        voteChoice = choice
        showVoteFeedback = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            handleVote(choice: choice)
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                offset = CGSize(width: isYay ? 500 : -500, height: 0)
                rotation = isYay ? 15 : -15
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                viewModel.nextTopic()
                offset = .zero
                rotation = 0
                scale = 1.0
                showVoteFeedback = false
            }
        }
    }
    
    private func handleVote(choice: String) {
        viewModel.submitVote(choice: choice) { success in
            if success {
                print("✅ Vote submitted successfully")
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
    @Environment(\.colorScheme) private var colorScheme
    
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
                        .fill(Color.red.opacity(colorScheme == .dark ? 0.4 : 0.3))
                        .frame(height: 8)
                        .cornerRadius(4)
                    
                    // Foreground bar (Yay)
                    Rectangle()
                        .fill(Color.green.opacity(colorScheme == .dark ? 0.6 : 0.7))
                        .frame(width: geometry.size.width * CGFloat(yayPercentage / 100), height: 8)
                        .cornerRadius(4)
                }
            }
            .frame(height: 8)
            
            // Total votes
            Text("\(totalVotes) votes")
                .font(.caption2)
                .foregroundStyle(AppColor.secondaryText)
        }
        .padding()
        .background(AppColor.adaptiveSecondaryBackground(for: colorScheme))
        .cornerRadius(12)
        .shadow(
            color: colorScheme == .dark ? .black.opacity(0.2) : .black.opacity(0.1),
            radius: colorScheme == .dark ? 5 : 5,
            y: colorScheme == .dark ? 1 : 2
        )
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