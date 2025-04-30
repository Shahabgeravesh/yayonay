import Foundation
import FirebaseFirestore
import SwiftUI
import FirebaseAuth

class SubCategoryViewModel: ObservableObject {
    @Published var subCategories: [SubCategory] = []
    @Published var currentIndex = 0
    @Published var hasReachedEnd = false
    private let db = Firestore.firestore()
    private var listener: ListenerRegistration?
    private var isProcessingUpdate = false
    private let categoryId: String
    private let initialSubCategoryId: String?
    
    init(categoryId: String, initialSubCategoryId: String? = nil) {
        print("DEBUG: Initializing SubCategoryViewModel with categoryId: \(categoryId)")
        self.categoryId = categoryId
        self.initialSubCategoryId = initialSubCategoryId
        fetchSubCategories(for: categoryId)
    }
    
    deinit {
        print("DEBUG: SubCategoryViewModel deinit - removing listener")
        listener?.remove()
    }
    
    func fetchSubCategories(for categoryId: String) {
        print("DEBUG: 🔍 Fetching subcategories for categoryId: \(categoryId)")
        print("DEBUG: Current hasReachedEnd state: \(hasReachedEnd)")
        
        guard let userId = Auth.auth().currentUser?.uid else {
            print("❌ No user ID available")
            return
        }
        
        // First, get all votes from the last 7 days
        let votesRef = Firestore.firestore().collection("votes")
            .whereField("userId", isEqualTo: userId)
        
        votesRef.getDocuments { [weak self] (votesSnapshot, votesError) in
            guard let self = self else { return }
            
            if let votesError = votesError {
                print("❌ Error fetching recent votes: \(votesError.localizedDescription)")
                return
            }
            
            // Get the IDs of recently voted items
            let sevenDaysAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
            let recentlyVotedIds = votesSnapshot?.documents.compactMap { document -> String? in
                if let timestamp = document.data()["date"] as? Timestamp,
                   timestamp.dateValue() > sevenDaysAgo {
                    return document.data()["subCategoryId"] as? String
                }
                return nil
            } ?? []
            
            print("📊 Found \(recentlyVotedIds.count) recently voted items")
            
            // Now fetch subcategories, excluding recently voted ones
            let subCategoriesRef = Firestore.firestore().collection("subCategories")
                .whereField("categoryId", isEqualTo: categoryId)
            
            subCategoriesRef.getDocuments { [weak self] (snapshot, error) in
                guard let self = self else { return }
                
                if let error = error {
                    print("❌ Error fetching subcategories: \(error.localizedDescription)")
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    print("❌ No subcategories found")
                    return
                }
                
                print("DEBUG: 📄 Found \(documents.count) subcategories")
                
                var validSubCategories: [SubCategory] = []
                var allItemsVoted = true
                
                for document in documents {
                    let data = document.data()
                    
                    // Skip if this item was recently voted on, unless it's the initial subcategory
                    if recentlyVotedIds.contains(document.documentID) && document.documentID != self.initialSubCategoryId {
                        print("⏳ Skipping recently voted item: \(data["name"] as? String ?? "Unknown")")
                        continue
                    }
                    
                    if let name = data["name"] as? String,
                       let imageURL = data["imageURL"] as? String,
                       let categoryId = data["categoryId"] as? String,
                       let order = data["order"] as? Int,
                       let yayCount = data["yayCount"] as? Int,
                       let nayCount = data["nayCount"] as? Int {
                        
                        let subCategory = SubCategory(
                            id: document.documentID,
                            name: name,
                            imageURL: imageURL,
                            categoryId: categoryId,
                            order: order,
                            yayCount: yayCount,
                            nayCount: nayCount
                        )
                        
                        validSubCategories.append(subCategory)
                        allItemsVoted = false
                        print("DEBUG: Processing subcategory - ID: \(document.documentID), Name: \(name)")
                    }
                }
                
                print("DEBUG: 📦 Processed \(validSubCategories.count) valid subcategories")
                
                DispatchQueue.main.async {
                    // If we have an initial subcategory, make sure it's included
                    if let initialId = self.initialSubCategoryId,
                       let initialSubCategory = validSubCategories.first(where: { $0.id == initialId }) {
                        // Remove it from its current position
                        validSubCategories.removeAll(where: { $0.id == initialId })
                        // Add it at the beginning
                        validSubCategories.insert(initialSubCategory, at: 0)
                        print("DEBUG: 📍 Added initial subcategory to the beginning: \(initialSubCategory.name)")
                        allItemsVoted = false
                    }
                    
                    self.subCategories = validSubCategories
                    
                    // If all items have been voted on, set hasReachedEnd to true
                    if allItemsVoted {
                        print("DEBUG: 🎉 All items have been voted on")
                        self.hasReachedEnd = true
                    } else {
                        // If we previously reached the end and there are no new items, keep the end state
                        if self.hasReachedEnd && validSubCategories.isEmpty {
                            print("DEBUG: 🔄 Preserving end state - no new items")
                            return
                        }
                        // Otherwise reset the end state
                        self.hasReachedEnd = false
                    }
                    
                    print("DEBUG: ✅ Updating subcategories in ViewModel")
                    print("DEBUG: New hasReachedEnd state: \(self.hasReachedEnd)")
                }
            }
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
        print("DEBUG: 🔄 Attempting to move to next item")
        print("DEBUG: Current index: \(currentIndex), Total items: \(subCategories.count)")
        
        guard !isProcessingUpdate else {
            print("DEBUG: ⏳ Skipping - processing update in progress")
            return
        }
        
        isProcessingUpdate = true
        
        // If we're at the end of the list, set the flag and return
        if currentIndex >= subCategories.count - 1 {
            print("DEBUG: 🏁 Reached end of list")
            hasReachedEnd = true
            isProcessingUpdate = false
            return
        }
        
        // Update index without animation to reduce lag
        currentIndex += 1
        print("DEBUG: 📍 Moved to index: \(currentIndex)")
        
        // Reset the processing flag immediately
        isProcessingUpdate = false
    }
    
    func previousItem() {
        print("DEBUG: 🔄 Attempting to move to previous item")
        print("DEBUG: Current index: \(currentIndex)")
        
        guard !isProcessingUpdate else {
            print("DEBUG: ⏳ Skipping - processing update in progress")
            return
        }
        
        isProcessingUpdate = true
        
        if currentIndex > 0 {
            // Update index without animation to reduce lag
            currentIndex -= 1
            hasReachedEnd = false
            print("DEBUG: 📍 Moved to index: \(currentIndex)")
        } else {
            print("DEBUG: ⛔️ Already at first item")
        }
        
        // Reset the processing flag immediately
        isProcessingUpdate = false
    }
} 