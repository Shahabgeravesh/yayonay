import Foundation
import FirebaseFirestore

struct UserProfile: Codable, Identifiable {
    let id: String
    var username: String
    var imageData: String? // Base64 encoded image data
    var email: String?
    var bio: String
    var votesCount: Int
    var lastVoteDate: Date
    var topInterests: [String]
    var joinDate: Date
    var socialLinks: [String: String]
    var recentActivity: [Activity]
    
    struct Activity: Codable {
        let type: String
        let itemId: String
        let timestamp: Date
    }
    
    init(id: String = UUID().uuidString,
         username: String,
         imageData: String? = nil,
         email: String? = nil,
         bio: String = "",
         votesCount: Int = 0,
         lastVoteDate: Date = Date(),
         topInterests: [String] = [],
         joinDate: Date = Date(),
         socialLinks: [String: String] = [:],
         recentActivity: [Activity] = []) {
        self.id = id
        self.username = username
        self.imageData = imageData
        self.email = email
        self.bio = bio
        self.votesCount = votesCount
        self.lastVoteDate = lastVoteDate
        self.topInterests = topInterests
        self.joinDate = joinDate
        self.socialLinks = socialLinks
        self.recentActivity = recentActivity
    }
    
    var dictionary: [String: Any] {
        return [
            "id": id,
            "username": username,
            "imageData": imageData as Any,
            "email": email as Any,
            "bio": bio,
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
            }
        ]
    }
    
    init?(document: DocumentSnapshot) {
        let data = document.data() ?? [:]
        
        guard let username = data["username"] as? String else { return nil }
        
        self.id = document.documentID
        self.username = username
        self.imageData = data["imageData"] as? String
        self.email = data["email"] as? String
        self.bio = data["bio"] as? String ?? ""
        self.votesCount = data["votesCount"] as? Int ?? 0
        self.lastVoteDate = (data["lastVoteDate"] as? Timestamp)?.dateValue() ?? Date()
        self.topInterests = data["topInterests"] as? [String] ?? []
        self.joinDate = (data["joinDate"] as? Timestamp)?.dateValue() ?? Date()
        self.socialLinks = data["socialLinks"] as? [String: String] ?? [:]
        
        // Parse recent activity
        if let activityData = data["recentActivity"] as? [[String: Any]] {
            self.recentActivity = activityData.compactMap { dict in
                guard let type = dict["type"] as? String,
                      let itemId = dict["itemId"] as? String,
                      let timestamp = (dict["timestamp"] as? Timestamp)?.dateValue() else {
                    return nil
                }
                return Activity(type: type, itemId: itemId, timestamp: timestamp)
            }
        } else {
            self.recentActivity = []
        }
    }
} 