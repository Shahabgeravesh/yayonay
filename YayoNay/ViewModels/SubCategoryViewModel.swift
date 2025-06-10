import Foundation
import FirebaseFirestore
import SwiftUI
import FirebaseAuth

class SubCategoryViewModel: ObservableObject {
    @Published var subCategories: [SubCategory] = []
    @Published var currentIndex: Int = 0
    @Published var hasReachedEnd = false
    @Published var isLoading = false
    @Published var error: Error?
    
    private let db = Firestore.firestore()
    private var listener: ListenerRegistration?
    private var voteCountListener: ListenerRegistration?
    private var isProcessingUpdate = false
    private let categoryId: String
    private let initialSubCategoryId: String?
    
    init(categoryId: String, initialSubCategoryId: String? = nil) {
        print("DEBUG: Initializing SubCategoryViewModel with categoryId: \(categoryId)")
        self.categoryId = categoryId
        self.initialSubCategoryId = initialSubCategoryId
        fetchSubCategories()
        setupVoteCountListener()
    }
    
    deinit {
        print("DEBUG: SubCategoryViewModel deinit - removing listeners")
        listener?.remove()
        voteCountListener?.remove()
    }
    
    private func setupVoteCountListener() {
        // Listen to all subcategories in this category for vote count changes
        let subCategoriesRef = db.collection("categories").document(categoryId).collection("subcategories")
        voteCountListener = subCategoriesRef
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }
                if let error = error {
                    print("DEBUG: ❌ Error listening to vote counts: \(error.localizedDescription)")
                    return
                }
                guard let documents = snapshot?.documents else {
                    print("DEBUG: ❌ No documents in vote count listener")
                    return
                }
                DispatchQueue.main.async {
                    for document in documents {
                        if let index = self.subCategories.firstIndex(where: { $0.id == document.documentID }),
                           let yayCount = document.data()["yayCount"] as? Int,
                           let nayCount = document.data()["nayCount"] as? Int {
                            var updatedSubCategory = self.subCategories[index]
                            updatedSubCategory.yayCount = yayCount
                            updatedSubCategory.nayCount = nayCount
                            self.subCategories[index] = updatedSubCategory
                        }
                    }
                }
            }
    }
    
    func fetchSubCategories() {
        print("DEBUG: Fetching subcategories for category: \(categoryId)")
        isLoading = true
        
        // Remove any existing listener
        listener?.remove()
        
        // Add new listener for nested subcategories
        listener = db.collection("categories")
            .document(categoryId)
            .collection("subcategories")
            .order(by: "order")
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }
                
                if let error = error {
                    print("❌ Error fetching subcategories: \(error.localizedDescription)")
                    self.error = error
                    self.isLoading = false
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    print("DEBUG: No subcategories found")
                    self.subCategories = []
                    self.isLoading = false
                    return
                }
                
                self.subCategories = documents.compactMap { SubCategory(document: $0) }
                print("DEBUG: Fetched \(self.subCategories.count) subcategories")
                
                // Set initial index if needed
                if let initialId = self.initialSubCategoryId,
                   let index = self.subCategories.firstIndex(where: { $0.id == initialId }) {
                    self.currentIndex = index
                }
                
                self.isLoading = false
            }
    }
    
    func vote(for subCategory: SubCategory, isYay: Bool) {
        // Add haptic feedback
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
        
        let field = isYay ? "yayCount" : "nayCount"
        let subCategoryRef = db.collection("categories").document(categoryId).collection("subcategories").document(subCategory.id)
        subCategoryRef.updateData([
            field: FieldValue.increment(Int64(1)),
            "lastVoteDate": Timestamp(date: Date())
        ]) { error in
            if let error = error {
                print("DEBUG: ❌ Error voting: \(error.localizedDescription)")
            } else {
                print("DEBUG: ✅ Vote recorded successfully")
            }
        }
    }
    
    func nextItem() {
        if currentIndex < subCategories.count - 1 {
            currentIndex += 1
        } else {
            hasReachedEnd = true
        }
    }
    
    func previousItem() {
        if currentIndex > 0 {
            currentIndex -= 1
        }
    }
} 