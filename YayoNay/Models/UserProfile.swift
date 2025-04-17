import Foundation
import FirebaseFirestore

struct UserProfile: Codable, Identifiable {
    let id: String
    var username: String
    var imageURL: String // URL to the profile image in Firebase Storage
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
         imageURL: String = "https://firebasestorage.googleapis.com/v0/b/yayonay-e7f58.appspot.com/o/default_profile.png?alt=media",
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
        self.imageURL = imageURL
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
            "imageURL": imageURL,
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
        self.imageURL = data["imageURL"] as? String ?? "https://firebasestorage.googleapis.com/v0/b/yayonay-e7f58.appspot.com/o/default_profile.png?alt=media"
        self.email = data["email"] as? String
        self.bio = data["bio"] as? String ?? ""
        self.votesCount = data["votesCount"] as? Int ?? 0
        self.lastVoteDate = (data["lastVoteDate"] as? Timestamp)?.dateValue() ?? Date()
        self.topInterests = data["topInterests"] as? [String] ?? []
        self.joinDate = (data["joinDate"] as? Timestamp)?.dateValue() ?? Date()
        self.socialLinks = data["socialLinks"] as? [String: String] ?? [:]
        
        // Parse recent activity
        if let activities = data["recentActivity"] as? [[String: Any]] {
            self.recentActivity = activities.compactMap { activityData in
                guard let type = activityData["type"] as? String,
                      let itemId = activityData["itemId"] as? String,
                      let timestamp = (activityData["timestamp"] as? Timestamp)?.dateValue() else {
                    return nil
                }
                return Activity(type: type, itemId: itemId, timestamp: timestamp)
            }
        } else {
            self.recentActivity = []
        }
    }
} 