import SwiftUI
import FirebaseFirestore

struct ExploreView: View {
    @StateObject private var viewModel = ExploreViewModel()
    
    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Main Categories Grid
                    LazyVGrid(columns: columns, spacing: 16) {
                        ForEach(viewModel.categories) { category in
                            NavigationLink(destination: CategoryDetailView(category: category)) {
                                CategoryCard(title: category.name, icon: category.iconName)
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Explore")
        }
        .onAppear {
            viewModel.fetchCategories()
        }
    }
}

struct CategoryCard: View {
    let title: String
    let icon: String
    
    var body: some View {
        VStack {
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.blue.opacity(0.1))
                
                VStack(spacing: 12) {
                    Image(systemName: icon)
                        .font(.system(size: 30))
                        .foregroundColor(.blue)
                        .accessibilityHidden(true)
                    
                    Text(title)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.primary)
                }
                .padding()
            }
            .frame(height: 120)
        }
        .shadow(color: Color.black.opacity(0.05), radius: 8, y: 4)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title) category")
        .accessibilityHint("Double tap to view \(title) items")
    }
}

class ExploreViewModel: ObservableObject {
    @Published var categories: [Category] = []
    private let db = Firestore.firestore()
    
    func fetchCategories() {
        db.collection("categories")
            .order(by: "order")
            .addSnapshotListener { [weak self] snapshot, error in
                if let error = error {
                    print("Error fetching categories: \(error)")
                    return
                }
                
                self?.categories = snapshot?.documents.compactMap { document in
                    Category(document: document)
                } ?? []
            }
    }
}

#Preview {
    ExploreView()
} 