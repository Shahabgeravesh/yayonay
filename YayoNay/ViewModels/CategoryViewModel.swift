import Foundation
import FirebaseFirestore

class CategoryViewModel: ObservableObject {
    @Published var categories: [Category] = []
    @Published var isLoading = false
    @Published var error: Error?
    
    private let db = Firestore.firestore()
    private var listener: ListenerRegistration?
    
    init() {
        fetchCategories()
    }
    
    deinit {
        listener?.remove()
    }
    
    func fetchCategories() {
        print("DEBUG: Fetching categories")
        isLoading = true
        
        // Remove any existing listener
        listener?.remove()
        
        // Add new listener for categories
        listener = db.collection("categories")
            .order(by: "order")
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }
                
                if let error = error {
                    print("❌ Error fetching categories: \(error.localizedDescription)")
                    self.error = error
                    self.isLoading = false
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    print("DEBUG: No categories found")
                    self.categories = []
                    self.isLoading = false
                    return
                }
                
                self.categories = documents.compactMap { Category(document: $0) }
                print("DEBUG: Fetched \(self.categories.count) categories")
                self.isLoading = false
            }
    }
    
    func fetchSubcategories(for categoryId: String) async throws -> [SubCategory] {
        let snapshot = try await db.collection("categories")
            .document(categoryId)
            .collection("subcategories")
            .order(by: "order")
            .getDocuments()
        
        return snapshot.documents.compactMap { SubCategory(document: $0) }
    }
    
    func createFoodCategory() {
        let foodCategory = Category(
            id: UUID().uuidString,
            name: "Food",
            imageURL: "https://images.unsplash.com/photo-1504674900247-0877df9cc836?w=800",
            isTopCategory: true,
            order: 2,
            description: "Vote on your favorite foods"
        )
        
        do {
            let data = try Firestore.Encoder().encode(foodCategory)
            db.collection("categories").document(foodCategory.id).setData(data) { error in
                if let error = error {
                    print("❌ Error creating food category: \(error.localizedDescription)")
                } else {
                    print("✅ Successfully created food category")
                }
            }
        } catch {
            print("❌ Error encoding food category: \(error.localizedDescription)")
        }
    }
} 