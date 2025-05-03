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
                if let subCategory = viewModel.currentSubCategory {
                    CategoryDetailView(
                        category: Category(
                            id: subCategory.categoryId,
                            name: "", // Optionally fetch the name if needed
                            isTopCategory: false,
                            order: 0
                        ),
                        initialSubCategoryId: subCategory.id
                    )
                } else {
                    ContentUnavailableView(
                        "No Topics Available",
                        systemImage: "dice",
                        description: Text("Check back later for more topics to vote on")
                    )
                }
                
                Button(action: viewModel.fetchRandomSubCategory) {
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
            viewModel.fetchRandomSubCategory()
        }
    }
}

class DiscoverHubViewModel: ObservableObject {
    @Published var currentTopic: Topic?
    @Published var currentSubCategory: SubCategory?
    private let db = Firestore.firestore()
    
    func fetchRandomTopic() {
        db.collection("subCategories")
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
    
    func fetchRandomSubCategory() {
        db.collection("subCategories")
            .getDocuments { [weak self] snapshot, error in
                guard let documents = snapshot?.documents,
                      !documents.isEmpty else { return }
                
                // Get a random document
                let randomIndex = Int.random(in: 0..<documents.count)
                let doc = documents[randomIndex]
                let data = doc.data()
                guard let name = data["name"] as? String,
                      let imageURL = data["imageURL"] as? String,
                      let categoryId = data["categoryId"] as? String,
                      let yayCount = data["yayCount"] as? Int,
                      let nayCount = data["nayCount"] as? Int else { return }
                let subCategory = SubCategory(
                    id: doc.documentID,
                    name: name,
                    imageURL: imageURL,
                    categoryId: categoryId,
                    order: 0,
                    yayCount: yayCount,
                    nayCount: nayCount,
                    attributes: [:]
                )
                DispatchQueue.main.async {
                    self?.currentSubCategory = subCategory
                }
            }
    }
}

#Preview {
    DiscoverHubView()
} 