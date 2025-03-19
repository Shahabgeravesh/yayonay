import Foundation
import FirebaseFirestore
import SwiftUI

class SubCategoryViewModel: ObservableObject {
    @Published var subCategories: [SubCategory] = []
    @Published var currentIndex = 0
    private let db = Firestore.firestore()
    private var listener: ListenerRegistration?
    private var isProcessingUpdate = false
    
    init(categoryId: String) {
        fetchSubCategories(for: categoryId)
    }
    
    deinit {
        listener?.remove()
    }
    
    func fetchSubCategories(for categoryId: String) {
        print("🔍 Fetching subcategories for categoryId:", categoryId)
        
        // Remove existing listener if any
        listener?.remove()
        
        let query = db.collection("subCategories")
            .whereField("categoryId", isEqualTo: categoryId)
            .order(by: "order", descending: false)
        
        listener = query.addSnapshotListener { [weak self] querySnapshot, error in
            guard let self = self else { return }
            
            if let error = error {
                print("❌ Error fetching subcategories:", error.localizedDescription)
                return
            }
            
            guard let documents = querySnapshot?.documents,
                  !documents.isEmpty else {
                print("❌ No documents found")
                return
            }
            
            // Only process if not already processing
            guard !self.isProcessingUpdate else { return }
            
            self.isProcessingUpdate = true
            
            let newSubCategories = documents.compactMap { document in
                SubCategory(document: document)
            }
            
            // Only update if the data is actually different
            if self.subCategories != newSubCategories {
                DispatchQueue.main.async {
                    self.subCategories = newSubCategories
                    // Reset index if needed
                    if self.currentIndex >= self.subCategories.count {
                        self.currentIndex = 0
                    }
                }
            }
            
            self.isProcessingUpdate = false
        }
    }
    
    func vote(for subCategory: SubCategory, isYay: Bool) {
        // Add haptic feedback
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
        
        let field = isYay ? "yayCount" : "nayCount"
        db.collection("subCategories")
            .document(subCategory.id)
            .updateData([
                field: FieldValue.increment(Int64(1))
            ]) { error in
                if let error = error {
                    print("Error voting: \(error.localizedDescription)")
                }
            }
    }
    
    func nextItem() {
        guard currentIndex < subCategories.count - 1,
              !isProcessingUpdate else { return }
        
        withAnimation(nil) {
            currentIndex += 1
        }
    }
    
    func previousItem() {
        if currentIndex > 0 {
            currentIndex -= 1
        }
    }
} 