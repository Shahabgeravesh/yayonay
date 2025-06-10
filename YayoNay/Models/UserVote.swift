import Foundation
import FirebaseFirestore

struct UserVote: Identifiable, Codable {
    let id: String
    let userId: String
    let subCategoryId: String
    let subQuestionId: String?
    let timestamp: Date
    let isYay: Bool
    let itemName: String
    let categoryName: String
    let categoryId: String
    let imageURL: String
    
    init(userId: String, subCategoryId: String, subQuestionId: String? = nil, isYay: Bool, itemName: String, categoryName: String, categoryId: String, imageURL: String) {
        self.id = UUID().uuidString
        self.userId = userId
        self.subCategoryId = subCategoryId
        self.subQuestionId = subQuestionId
        self.timestamp = Date()
        self.isYay = isYay
        self.itemName = itemName
        self.categoryName = categoryName
        self.categoryId = categoryId
        self.imageURL = imageURL
    }
    
    init?(document: QueryDocumentSnapshot) {
        let data = document.data()
        
        guard let userId = data["userId"] as? String,
              let subCategoryId = data["subCategoryId"] as? String,
              let timestamp = data["timestamp"] as? Timestamp,
              let isYay = data["isYay"] as? Bool,
              let itemName = data["itemName"] as? String,
              let categoryName = data["categoryName"] as? String,
              let categoryId = data["categoryId"] as? String,
              let imageURL = data["imageURL"] as? String else {
            return nil
        }
        
        self.id = document.documentID
        self.userId = userId
        self.subCategoryId = subCategoryId
        self.subQuestionId = data["subQuestionId"] as? String
        self.timestamp = timestamp.dateValue()
        self.isYay = isYay
        self.itemName = itemName
        self.categoryName = categoryName
        self.categoryId = categoryId
        self.imageURL = imageURL
    }
    
    var dictionary: [String: Any] {
        return [
            "id": id,
            "userId": userId,
            "subCategoryId": subCategoryId,
            "subQuestionId": subQuestionId as Any,
            "timestamp": timestamp,
            "isYay": isYay,
            "itemName": itemName,
            "categoryName": categoryName,
            "categoryId": categoryId,
            "imageURL": imageURL
        ]
    }
} 