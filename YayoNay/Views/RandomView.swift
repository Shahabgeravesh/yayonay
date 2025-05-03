// MARK: - Discover Hub View
// This view provides a random voting experience, including:
// 1. Random selection of items to vote on
// 2. Surprise voting options
// 3. Discovery of new content
// 4. Quick voting interface

import SwiftUI
import FirebaseFirestore

struct DiscoverHubView: View {
    @StateObject private var viewModel = DiscoverHubViewModel()
    
    var body: some View {
        NavigationStack {
            VStack {
                if let topic = viewModel.currentTopic {
                    VotingView(topic: topic)
                } else {
                    ContentUnavailableView(
                        "No Topics Available",
                        systemImage: "dice",
                        description: Text("Check back later for more topics to vote on")
                    )
                }
                
                Button(action: viewModel.fetchRandomTopic) {
                    Label("Next Topic", systemImage: "dice.fill")
                        .font(.headline)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(AppColor.accent)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
                .padding()
            }
            .navigationTitle("Discover Hub")
        }
        .onAppear {
            viewModel.fetchRandomTopic()
        }
    }
}

class DiscoverHubViewModel: ObservableObject {
    @Published var currentTopic: Topic?
    private let db = Firestore.firestore()
    
    func fetchRandomTopic() {
        db.collection("topics")
            .getDocuments { [weak self] snapshot, error in
                guard let documents = snapshot?.documents,
                      !documents.isEmpty else { return }
                
                // Get a random document
                let randomIndex = Int.random(in: 0..<documents.count)
                if let topic = Topic(document: documents[randomIndex]) {
                    DispatchQueue.main.async {
                        self?.currentTopic = topic
                    }
                }
            }
    }
}

#Preview {
    DiscoverHubView()
} 