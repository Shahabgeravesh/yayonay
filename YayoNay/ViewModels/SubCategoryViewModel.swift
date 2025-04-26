import Foundation
import FirebaseFirestore
import SwiftUI
import FirebaseAuth

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
        print("DEBUG: 🔍 Fetching subcategories for categoryId: \(categoryId)")
        print("DEBUG: Setting up Firestore listener for subcategories")
        
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
                
                for document in documents {
                    let data = document.data()
                    
                    // Skip if this item was recently voted on
                    if recentlyVotedIds.contains(document.documentID) {
                        print("⏳ Skipping recently voted item: \(data["name"] as? String ?? "Unknown")")
                        continue
                    }
                    
                    // Rest of the existing validation code...
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
                        print("DEBUG: Processing subcategory - ID: \(document.documentID), Name: \(name)")
                    }
                }
                
                print("DEBUG: 📦 Processed \(validSubCategories.count) valid subcategories")
                
                DispatchQueue.main.async {
                    self.subCategories = validSubCategories
                    print("DEBUG: ✅ Updating subcategories in ViewModel")
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