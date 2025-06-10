import Foundation
import FirebaseFirestore
import FirebaseAuth

class VoteItemViewModel: ObservableObject {
    @Published var voteItems: [VoteItem] = []
    private let db = Firestore.firestore()
    private var listener: ListenerRegistration?
    
    init(categoryId: String) {
        fetchVoteItems(for: categoryId)
    }
    
    deinit {
        listener?.remove()
    }
    
    func fetchVoteItems(for categoryId: String) {
        listener = db.collection("voteItems")
            .whereField("categoryId", isEqualTo: categoryId)
            .order(by: "createdAt", descending: true)
            .addSnapshotListener { [weak self] querySnapshot, error in
                guard let self = self,
                      let documents = querySnapshot?.documents else {
                    print("Error fetching vote items: \(error?.localizedDescription ?? "Unknown error")")
                    return
                }
                
                self.voteItems = documents.compactMap { document in
                    VoteItem(document: document)
                }
            }
    }
    
    func vote(for subCategory: SubCategory, attribute: CategoryAttribute, isYay: Bool) {
        let docRef = db.collection("categories").document(subCategory.categoryId).collection("subcategories").document(subCategory.id)
        
        // Create vote record
        let voteRef = db.collection("votes").document()
        let vote = Vote(
            id: voteRef.documentID,
            itemName: subCategory.name,
            imageURL: subCategory.imageURL,
            isYay: isYay,
            date: Date(),
            categoryName: attribute.name,
            categoryId: subCategory.categoryId,
            subCategoryId: subCategory.id
        )
        
        // Batch write
        let batch = db.batch()
        
        // Update subcategory counts and lastVoteDate
        let field = isYay ? "yayCount" : "nayCount"
        batch.updateData([
            "attributes.\(attribute.name).\(field)": FieldValue.increment(Int64(1)),
            field: FieldValue.increment(Int64(1)),
            "lastVoteDate": Timestamp(date: Date())
        ], forDocument: docRef)
        
        // Save vote
        batch.setData(vote.dictionary, forDocument: voteRef)
        
        // Update user profile
        if let userId = Auth.auth().currentUser?.uid {
            let userRef = db.collection("users").document(userId)
            batch.updateData([
                "votesCount": FieldValue.increment(Int64(1)),
                "lastVoteDate": Timestamp(date: Date())
            ], forDocument: userRef)
        }
        
        // Commit batch
        batch.commit { error in
            if let error = error {
                print("Error recording vote: \(error.localizedDescription)")
            }
        }
    }
    
    func addVoteItem(_ item: VoteItem) {
        db.collection("voteItems").document(item.id).setData(item.toDict) { error in
            if let error = error {
                print("Error adding vote item: \(error.localizedDescription)")
            }
        }
    }
} 