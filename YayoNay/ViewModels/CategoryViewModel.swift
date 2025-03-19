import Foundation
import FirebaseFirestore

class CategoryViewModel: ObservableObject {
    @Published var categories: [Category] = []
    private let db = Firestore.firestore()
    private var listener: ListenerRegistration?
    
    init() {
        fetchCategories()
    }
    
    deinit {
        listener?.remove()
    }
    
    func fetchCategories() {
        print("Starting to fetch categories...")
        listener = db.collection("categories")
            .order(by: "order")
            .addSnapshotListener { [weak self] querySnapshot, error in
                if let error = error {
                    print("Error fetching categories:", error.localizedDescription)
                    return
                }
                
                print("Got categories snapshot with \(querySnapshot?.documents.count ?? 0) documents")
                
                guard let self = self,
                      let documents = querySnapshot?.documents else {
                    print("Error fetching categories: \(error?.localizedDescription ?? "Unknown error")")
                    return
                }
                
                self.categories = documents.compactMap { document in
                    let category = Category(document: document)
                    print("Category:", category?.name ?? "nil", "ID:", document.documentID)
                    return category
                }
            }
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