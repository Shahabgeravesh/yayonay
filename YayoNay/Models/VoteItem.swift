import Foundation
import FirebaseFirestore

struct VoteItem: Identifiable, Codable {
    var id: String
    var title: String
    var description: String
    var imageURL: String?
    var categoryId: String
    var createdAt: Date
    var yayCount: Int
    var nayCount: Int
    var createdBy: String // user ID
    
    init(id: String = UUID().uuidString,
         title: String,
         description: String,
         imageURL: String? = nil,
         categoryId: String,
         createdBy: String,
         createdAt: Date = Date(),
         yayCount: Int = 0,
         nayCount: Int = 0) {
        self.id = id
        self.title = title
        self.description = description
        self.imageURL = imageURL
        self.categoryId = categoryId
        self.createdBy = createdBy
        self.createdAt = createdAt
        self.yayCount = yayCount
        self.nayCount = nayCount
    }
    
    init?(document: QueryDocumentSnapshot) {
        let data = document.data()
        
        guard 
            let title = data["title"] as? String,
            let description = data["description"] as? String,
            let categoryId = data["categoryId"] as? String,
            let createdBy = data["createdBy"] as? String,
            let createdAt = (data["createdAt"] as? Timestamp)?.dateValue()
        else { return nil }
        
        self.id = document.documentID
        self.title = title
        self.description = description
        self.imageURL = data["imageURL"] as? String
        self.categoryId = categoryId
        self.createdBy = createdBy
        self.createdAt = createdAt
        self.yayCount = data["yayCount"] as? Int ?? 0
        self.nayCount = data["nayCount"] as? Int ?? 0
    }
    
    var toDict: [String: Any] {
        return [
            "title": title,
            "description": description,
            "imageURL": imageURL ?? "",
            "categoryId": categoryId,
            "createdBy": createdBy,
            "createdAt": Timestamp(date: createdAt),
            "yayCount": yayCount,
            "nayCount": nayCount
        ]
    }
} 