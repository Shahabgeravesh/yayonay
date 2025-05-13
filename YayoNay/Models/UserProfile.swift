import Foundation
import FirebaseFirestore

struct UserProfile: Identifiable, Codable {
    let id: String
    var username: String
    var imageURL: String // URL to the profile image in Firebase Storage
    var email: String?
    var votesCount: Int
    var lastVoteDate: Date
    var topInterests: [String]
    var joinDate: Date
    var socialLinks: [String: String]
    var recentActivity: [Activity]
    var sharesCount: Int // New property
    
    struct Activity: Codable {
        let type: String
        let itemId: String
        let timestamp: Date
    }
    
    init(id: String = UUID().uuidString,
         username: String,
         imageURL: String = "https://firebasestorage.googleapis.com/v0/b/yayonay-e7f58.appspot.com/o/default_profile.png?alt=media",
         email: String? = nil,
         votesCount: Int = 0,
         lastVoteDate: Date = Date(),
         topInterests: [String] = [],
         joinDate: Date = Date(),
         socialLinks: [String: String] = [:],
         recentActivity: [Activity] = [],
         sharesCount: Int = 0) {
        self.id = id
        self.username = username
        self.imageURL = imageURL
        self.email = email
        self.votesCount = votesCount
        self.lastVoteDate = lastVoteDate
        self.topInterests = topInterests
        self.joinDate = joinDate
        self.socialLinks = socialLinks
        self.recentActivity = recentActivity
        self.sharesCount = sharesCount
    }
    
    var dictionary: [String: Any] {
        return [
            "id": id,
            "username": username,
            "imageURL": imageURL,
            "email": email as Any,
            "votesCount": votesCount,
            "lastVoteDate": Timestamp(date: lastVoteDate),
            "topInterests": topInterests,
            "joinDate": Timestamp(date: joinDate),
            "socialLinks": socialLinks,
            "recentActivity": recentActivity.map { activity in
                [
                    "type": activity.type,
                    "itemId": activity.itemId,
                    "timestamp": Timestamp(date: activity.timestamp)
                ]
            },
            "sharesCount": sharesCount
        ]
    }
    
    init?(document: DocumentSnapshot) {
        let data = document.data() ?? [:]
        
        guard let username = data["username"] as? String else { return nil }
        
        self.id = document.documentID
        self.username = username
        self.imageURL = data["imageURL"] as? String ?? "https://firebasestorage.googleapis.com/v0/b/yayonay-e7f58.appspot.com/o/default_profile.png?alt=media"
        self.email = data["email"] as? String
        self.votesCount = data["votesCount"] as? Int ?? 0
        self.lastVoteDate = (data["lastVoteDate"] as? Timestamp)?.dateValue() ?? Date()
        self.topInterests = data["topInterests"] as? [String] ?? []
        self.joinDate = (data["joinDate"] as? Timestamp)?.dateValue() ?? Date()
        self.socialLinks = data["socialLinks"] as? [String: String] ?? [:]
        self.sharesCount = data["sharesCount"] as? Int ?? 0
        
        // Parse recent activity
        if let activityData = data["recentActivity"] as? [[String: Any]] {
            self.recentActivity = activityData.compactMap { dict in
                guard let type = dict["type"] as? String,
                      let itemId = dict["itemId"] as? String,
                      let timestamp = (dict["timestamp"] as? Timestamp)?.dateValue()
                else { return nil }
                
                return Activity(type: type, itemId: itemId, timestamp: timestamp)
            }
        } else {
            self.recentActivity = []
        }
    }
} 