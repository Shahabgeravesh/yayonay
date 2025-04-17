import Foundation
import FirebaseFirestore
import SwiftUI

class SubCategoryViewModel: ObservableObject {
    @Published var subCategories: [SubCategory] = []
    @Published var currentIndex = 0
    private let db = Firestore.firestore()
    private var listener: ListenerRegistration?
    private var isProcessingUpdate = false
    private let categoryId: String
    
    init(categoryId: String) {
        print("DEBUG: Initializing SubCategoryViewModel with categoryId: \(categoryId)")
        self.categoryId = categoryId
        fetchSubCategories(for: categoryId)
    }
    
    deinit {
        print("DEBUG: SubCategoryViewModel deinit - removing listener")
        listener?.remove()
    }
    
    func fetchSubCategories(for categoryId: String) {
        guard !categoryId.isEmpty else {
            print("DEBUG: ❌ Attempted to fetch with empty categoryId")
            return
        }
        
        print("DEBUG: 🔍 Fetching subcategories for categoryId: \(categoryId)")
        
        // Remove existing listener if any
        listener?.remove()
        
        let query = db.collection("subCategories")
            .whereField("categoryId", isEqualTo: categoryId)
            .order(by: "order", descending: false)
        
        print("DEBUG: Setting up Firestore listener for subcategories")
        
        listener = query.addSnapshotListener { [weak self] querySnapshot, error in
            guard let self = self else {
                print("DEBUG: ❌ Self is nil in snapshot listener")
                return
            }
            
            if let error = error {
                print("DEBUG: ❌ Error fetching subcategories: \(error.localizedDescription)")
                return
            }
            
            guard let documents = querySnapshot?.documents else {
                print("DEBUG: ❌ No documents in snapshot")
                return
            }
            
            if documents.isEmpty {
                print("DEBUG: ❌ No subcategories found for categoryId: \(categoryId)")
                return
            }
            
            print("DEBUG: 📄 Found \(documents.count) subcategories")
            
            // Only process if not already processing
            guard !self.isProcessingUpdate else {
                print("DEBUG: ⚠️ Update already in progress, skipping")
                return
            }
            
            self.isProcessingUpdate = true
            
            let newSubCategories = documents.compactMap { document -> SubCategory? in
                let subCategory = SubCategory(document: document)
                print("DEBUG: Processing subcategory - ID: \(document.documentID), Name: \(subCategory?.name ?? "nil")")
                return subCategory
            }
            
            print("DEBUG: 📦 Processed \(newSubCategories.count) valid subcategories")
            
            // Only update if the data is actually different
            if self.subCategories != newSubCategories {
                DispatchQueue.main.async {
                    print("DEBUG: ✅ Updating subcategories in ViewModel")
                    self.subCategories = newSubCategories
                    // Reset index if needed
                    if self.currentIndex >= self.subCategories.count {
                        self.currentIndex = 0
                    }
                }
            } else {
                print("DEBUG: ℹ️ No changes in subcategories data")
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
                    print("DEBUG: ❌ Error voting: \(error.localizedDescription)")
                } else {
                    print("DEBUG: ✅ Vote recorded successfully")
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