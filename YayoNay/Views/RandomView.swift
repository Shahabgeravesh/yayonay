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
    @Published var currentSubCategory: SubCategory?
    private let db = Firestore.firestore()
    
    func fetchRandomSubCategory() {
        // First get all categories
        db.collection("categories").getDocuments { [weak self] snapshot, error in
            guard let self = self,
                  let documents = snapshot?.documents,
                  !documents.isEmpty else { return }
            
            // Get a random category
            let randomCategory = documents.randomElement()
            guard let categoryId = randomCategory?.documentID else { return }
            
            // Then get subcategories from the nested structure
            db.collection("categories")
                .document(categoryId)
                .collection("subcategories")
                .getDocuments { subSnapshot, subError in
                    guard let subDocuments = subSnapshot?.documents,
                          !subDocuments.isEmpty else { return }
                    
                    // Get a random subcategory
                    if let randomSubCategory = subDocuments.randomElement() {
                        let data = randomSubCategory.data()
                        guard let name = data["name"] as? String,
                              let imageURL = data["imageURL"] as? String,
                              let categoryId = data["categoryId"] as? String,
                              let order = data["order"] as? Int,
                              let yayCount = data["yayCount"] as? Int,
                              let nayCount = data["nayCount"] as? Int else { return }
                        
                        let subCategory = SubCategory(
                            id: randomSubCategory.documentID,
                            name: name,
                            imageURL: imageURL,
                            categoryId: categoryId,
                            order: order,
                            yayCount: yayCount,
                            nayCount: nayCount
                        )
                        
                        DispatchQueue.main.async {
                            self.currentSubCategory = subCategory
                        }
                    }
                }
        }
    }
}

#Preview {
    DiscoverHubView()
} 