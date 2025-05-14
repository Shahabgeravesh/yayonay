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
    private var voteCountListener: ListenerRegistration?
    private var isProcessingUpdate = false
    private let categoryId: String
    private let initialSubCategoryId: String?
    
    init(categoryId: String, initialSubCategoryId: String? = nil) {
        print("DEBUG: Initializing SubCategoryViewModel with categoryId: \(categoryId)")
        self.categoryId = categoryId
        self.initialSubCategoryId = initialSubCategoryId
        fetchSubCategories(for: categoryId)
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
    
    func fetchSubCategories(for categoryId: String) {
        print("DEBUG: 🔍 Fetching subcategories for categoryId: \(categoryId)")
        print("DEBUG: Firestore path: categories/\(categoryId)/subcategories")
        print("DEBUG: Current hasReachedEnd state: \(hasReachedEnd)")
        
        guard let userId = Auth.auth().currentUser?.uid else {
            print("❌ No user ID available")
            return
        }
        
        // First, get all votes from the last 7 days
        let votesRef = Firestore.firestore().collection("users").document(userId).collection("votes")
            .whereField("date", isGreaterThan: Timestamp(date: Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()))
        
        votesRef.getDocuments { [weak self] (votesSnapshot, votesError) in
            guard let self = self else { return }
            
            if let votesError = votesError {
                print("❌ Error fetching recent votes: \(votesError.localizedDescription)")
                return
            }
            
            // Get the IDs of recently voted items
            let recentlyVotedIds = votesSnapshot?.documents.compactMap { document -> String? in
                    return document.data()["subCategoryId"] as? String
            } ?? []
            
            print("📊 Found \(recentlyVotedIds.count) recently voted items")
            print("📊 Recently voted IDs: \(recentlyVotedIds)")
            
            // Try fetching from nested collection first
            let nestedRef = Firestore.firestore()
                .collection("categories").document(self.categoryId).collection("subcategories")
            print("DEBUG: Querying nested path: categories/\(self.categoryId)/subcategories")
            
            nestedRef.getDocuments { [weak self] (snapshot, error) in
                guard let self = self else { return }
                
                if let error = error {
                    print("❌ Error fetching nested subcategories: \(error.localizedDescription)")
                    // If nested fetch fails, try root collection
                    self.fetchFromRootCollection(categoryId: categoryId, recentlyVotedIds: recentlyVotedIds)
                    return
                }
                
                if let documents = snapshot?.documents, !documents.isEmpty {
                    self.processSubcategories(documents: documents, recentlyVotedIds: recentlyVotedIds)
                } else {
                    print("DEBUG: No subcategories found in nested collection, trying root collection")
                    self.fetchFromRootCollection(categoryId: categoryId, recentlyVotedIds: recentlyVotedIds)
                }
            }
        }
    }
    
    private func fetchFromRootCollection(categoryId: String, recentlyVotedIds: [String]) {
        print("DEBUG: Querying root collection: subcategories")
        let rootRef = Firestore.firestore().collection("subcategories")
            .whereField("categoryId", isEqualTo: categoryId)
        
        rootRef.getDocuments { [weak self] (snapshot, error) in
            guard let self = self else { return }
            
            if let error = error {
                print("❌ Error fetching root subcategories: \(error.localizedDescription)")
                return
            }
            
            if let documents = snapshot?.documents {
                self.processSubcategories(documents: documents, recentlyVotedIds: recentlyVotedIds)
            }
        }
    }
    
    private func processSubcategories(documents: [QueryDocumentSnapshot], recentlyVotedIds: [String]) {
        print("DEBUG: 📄 Found \(documents.count) subcategories in Firestore")
        for doc in documents {
            print("DEBUG: Subcategory doc id: \(doc.documentID), data: \(doc.data())")
        }
        
        var validSubCategories: [SubCategory] = []
        var allItemsVoted = true
        
        for document in documents {
            let data = document.data()
            let subCategoryId = document.documentID
            
            // Skip if this item was recently voted on, unless it's the initial subcategory
            if recentlyVotedIds.contains(subCategoryId) && subCategoryId != self.initialSubCategoryId {
                print("⏳ Skipping recently voted item: \(data["name"] as? String ?? "Unknown") (ID: \(subCategoryId))")
                continue
            }
            
            if let name = data["name"] as? String,
               let imageURL = data["imageURL"] as? String,
               let categoryId = data["categoryId"] as? String,
               let order = data["order"] as? Int {
                
                let subCategory = SubCategory(
                    id: subCategoryId,
                    name: name,
                    imageURL: imageURL,
                    categoryId: categoryId,
                    order: order,
                    yayCount: data["yayCount"] as? Int ?? 0,
                    nayCount: data["nayCount"] as? Int ?? 0
                )
                
                validSubCategories.append(subCategory)
                allItemsVoted = false
                print("DEBUG: ✅ Added subcategory - ID: \(subCategoryId), Name: \(name)")
            } else {
                print("❌ Invalid subcategory data for ID: \(subCategoryId)")
            }
        }
        
        print("DEBUG: 📦 Processed \(validSubCategories.count) valid subcategories")
        
        DispatchQueue.main.async {
            self.subCategories = validSubCategories
            self.hasReachedEnd = allItemsVoted
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