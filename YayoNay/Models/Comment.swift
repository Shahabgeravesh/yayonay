import Foundation
import FirebaseFirestore

struct Comment: Identifiable, Codable {
    let id: String
    let userId: String
    let username: String
    let userImage: String
    let text: String
    let date: Date
    var likes: Int
    var isLiked: Bool
    let parentId: String? // For nested comments/replies
    var replies: [Comment] // To store replies
    
    init(id: String = UUID().uuidString,
         userId: String,
         username: String,
         userImage: String,
         text: String,
         date: Date = Date(),
         likes: Int = 0,
         isLiked: Bool = false,
         parentId: String? = nil,
         replies: [Comment] = []) {
        self.id = id
        self.userId = userId
        self.username = username
        self.userImage = userImage
        self.text = text
        self.date = date
        self.likes = likes
        self.isLiked = isLiked
        self.parentId = parentId
        self.replies = replies
    }
    
    var dictionary: [String: Any] {
        var dict: [String: Any] = [
            "userId": userId,
            "username": username,
            "userImage": userImage,
            "text": text,
            "date": Timestamp(date: date),
            "likes": likes
        ]
        if let parentId = parentId {
            dict["parentId"] = parentId
        }
        return dict
    }
} 