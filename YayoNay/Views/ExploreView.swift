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
                .padding(.vertical, 24)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Explore")
            .overlay {
                if viewModel.isLoading {
                    ProgressView()
                        .scaleEffect(1.5)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.black.opacity(0.1))
                }
            }
        }
        .onAppear {
            viewModel.fetchCategories()
        }
    }
}

class ExploreViewModel: ObservableObject {
    @Published var categories: [Category] = []
    @Published var isLoading = true
    private let db = Firestore.firestore()
    private var listener: ListenerRegistration?
    
    deinit {
        listener?.remove()
    }
    
    func fetchCategories() {
        print("DEBUG: Fetching categories for ExploreView")
        isLoading = true
        
        listener?.remove()
        
        listener = db.collection("categories")
            .whereField("isTopCategory", isEqualTo: true)
            .order(by: "order")
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }
                
                if let error = error {
                    print("DEBUG: Error fetching categories: \(error.localizedDescription)")
                    self.isLoading = false
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    print("DEBUG: No category documents found")
                    self.isLoading = false
                    return
                }
                
                print("DEBUG: Found \(documents.count) category documents")
                
                self.categories = documents.compactMap { doc -> Category? in
                    let data = doc.data()
                    print("DEBUG: Processing category document: \(data)")
                    
                    guard let name = data["name"] as? String else {
                        print("DEBUG: Category \(doc.documentID) missing name")
                        return nil
                    }
                    
                    return Category(
                        id: doc.documentID,
                        name: name,
                        isTopCategory: data["isTopCategory"] as? Bool ?? false,
                        order: data["order"] as? Int ?? 0,
                        description: data["description"] as? String ?? "",
                        featured: data["featured"] as? Bool ?? false,
                        votesCount: data["votesCount"] as? Int ?? 0
                    )
                }
                
                print("DEBUG: Loaded \(self.categories.count) categories")
                self.isLoading = false
            }
    }
}

struct CategoryCard: View {
    let title: String
    let icon: String
    
    var body: some View {
        VStack {
            Image(systemName: icon)
                .font(.system(size: 30))
                .foregroundColor(.blue)
                .frame(width: 60, height: 60)
                .background(Color(.systemBackground))
                .clipShape(Circle())
                .shadow(color: Color.black.opacity(0.1), radius: 5, y: 2)
            
            Text(title)
                .font(.headline)
                .foregroundColor(.primary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: Color.black.opacity(0.1), radius: 5, y: 2)
    }
}

#Preview {
    ExploreView()
} 