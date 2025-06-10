import Foundation
import FirebaseFirestore

struct Topic: Identifiable, Codable {
    let id: String
    let title: String
    let mediaURL: String?
    let description: String
    let tags: [String]
    let category: String
    let optionA: String
    let optionB: String
    let date: Date
    let userImage: String
    let userId: String
    var upvotes: Int
    var downvotes: Int
    var userVoteStatus: VoteStatus
    
    enum VoteStatus: String, Codable {
        case none
        case upvoted
        case downvoted
    }
    
    init(id: String = UUID().uuidString,
         title: String,
         mediaURL: String? = nil,
         description: String = "",
         tags: [String] = [],
         category: String = "General",
         optionA: String = "Yay",
         optionB: String = "Nay",
         date: Date = Date(),
         userImage: String,
         userId: String,
         upvotes: Int = 0,
         downvotes: Int = 0,
         userVoteStatus: VoteStatus = .none) {
        self.id = id
        self.title = title
        self.mediaURL = mediaURL
        self.description = description
        self.tags = tags
        self.category = category
        self.optionA = optionA
        self.optionB = optionB
        self.date = date
        self.userImage = userImage
        self.userId = userId
        self.upvotes = upvotes
        self.downvotes = downvotes
        self.userVoteStatus = userVoteStatus
    }
    
    init?(document: QueryDocumentSnapshot) {
        let data = document.data()
        
        guard let title = data["title"] as? String,
              let optionA = data["optionA"] as? String,
              let optionB = data["optionB"] as? String,
              let date = (data["date"] as? Timestamp)?.dateValue(),
              let userImage = data["userImage"] as? String,
              let userId = data["userId"] as? String else {
            return nil
        }
        
        self.id = document.documentID
        self.title = title
        self.mediaURL = data["mediaURL"] as? String
        self.description = data["description"] as? String ?? ""
        self.tags = data["tags"] as? [String] ?? []
        self.category = data["category"] as? String ?? "General"
        self.optionA = optionA
        self.optionB = optionB
        self.date = date
        self.userImage = userImage
        self.userId = userId
        self.upvotes = data["upvotes"] as? Int ?? 0
        self.downvotes = data["downvotes"] as? Int ?? 0
        self.userVoteStatus = VoteStatus(rawValue: data["userVoteStatus"] as? String ?? "") ?? .none
    }
    
    var dictionary: [String: Any] {
        return [
            "title": title,
            "mediaURL": mediaURL ?? "",
            "description": description,
            "tags": tags,
            "category": category,
            "optionA": optionA,
            "optionB": optionB,
            "date": Timestamp(date: date),
            "userImage": userImage,
            "userId": userId,
            "upvotes": upvotes,
            "downvotes": downvotes,
            "userVoteStatus": userVoteStatus.rawValue
        ]
    }
}