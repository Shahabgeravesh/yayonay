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
    let voteId: String
    
    init(id: String = UUID().uuidString,
         userId: String,
         username: String,
         userImage: String,
         text: String,
         date: Date = Date(),
         likes: Int = 0,
         isLiked: Bool = false,
         parentId: String? = nil,
         replies: [Comment] = [],
         voteId: String) {
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
        self.voteId = voteId
    }
    
    init?(document: QueryDocumentSnapshot) {
        let data = document.data()
        
        guard let userId = data["userId"] as? String,
              let username = data["username"] as? String,
              let text = data["text"] as? String,
              let timestamp = (data["date"] as? Timestamp)?.dateValue(),
              let likes = data["likes"] as? Int,
              let voteId = data["voteId"] as? String else {
            return nil
        }
        
        self.id = document.documentID
        self.userId = userId
        self.username = username
        self.userImage = data["userImage"] as? String ?? "https://firebasestorage.googleapis.com/v0/b/yayonay-e7f58.appspot.com/o/default_profile.png?alt=media"
        self.text = text
        self.date = timestamp
        self.likes = likes
        self.isLiked = false
        self.parentId = data["parentId"] as? String
        self.replies = []
        self.voteId = voteId
    }
    
    var dictionary: [String: Any] {
        var dict: [String: Any] = [
            "userId": userId,
            "username": username,
            "userImage": userImage,
            "text": text,
            "date": Timestamp(date: date),
            "likes": likes,
            "voteId": voteId
        ]
        if let parentId = parentId {
            dict["parentId"] = parentId
        }
        return dict
    }
} 