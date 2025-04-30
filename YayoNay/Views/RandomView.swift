// MARK: - Random View
// This view provides a random voting experience, including:
// 1. Random selection of items to vote on
// 2. Surprise voting options
// 3. Discovery of new content
// 4. Quick voting interface

import SwiftUI
import FirebaseFirestore

struct RandomView: View {
    @StateObject private var viewModel = RandomViewModel()
    
    var body: some View {
        NavigationStack {
            VStack {
                if let topic = viewModel.currentTopic {
                    VotingView(topic: topic)
                        .padding()
                } else {
                    ContentUnavailableView(
                        "No Topics Available",
                        systemImage: "dice",
                        description: Text("Check back later for more topics to vote on")
                    )
                }
                
                Button(action: viewModel.fetchRandomTopic) {
                    Label("Next Random Topic", systemImage: "dice.fill")
                        .font(.headline)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(AppColor.accent)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
                .padding()
            }
            .navigationTitle("Random")
        }
        .onAppear {
            viewModel.fetchRandomTopic()
        }
    }
}

class RandomViewModel: ObservableObject {
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
    RandomView()
} 