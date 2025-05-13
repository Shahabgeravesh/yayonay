import Foundation
import FirebaseFirestore

struct Share: Identifiable, Codable {
    let id: String
    let userId: String
    let sharedItemId: String
    let sharedItemType: ShareType
    let platform: SharePlatform
    let timestamp: Date
    let successful: Bool
    
    enum ShareType: String, Codable {
        case vote
        case category
        case topic
        case profile
        case subcategory
    }
    
    enum SharePlatform: String, Codable {
        case facebook
        case twitter
        case instagram
        case whatsapp
        case telegram
        case linkedin
        case tiktok
        case message
        case other
    }
    
    var dictionary: [String: Any] {
        return [
            "userId": userId,
            "sharedItemId": sharedItemId,
            "sharedItemType": sharedItemType.rawValue,
            "platform": platform.rawValue,
            "timestamp": Timestamp(date: timestamp),
            "successful": successful
        ]
    }
    
    init(id: String = UUID().uuidString,
         userId: String,
         sharedItemId: String,
         sharedItemType: ShareType,
         platform: SharePlatform,
         timestamp: Date = Date(),
         successful: Bool = true) {
        self.id = id
        self.userId = userId
        self.sharedItemId = sharedItemId
        self.sharedItemType = sharedItemType
        self.platform = platform
        self.timestamp = timestamp
        self.successful = successful
    }
    
    init?(document: DocumentSnapshot) {
        guard let data = document.data(),
              let userId = data["userId"] as? String,
              let sharedItemId = data["sharedItemId"] as? String,
              let sharedItemTypeRaw = data["sharedItemType"] as? String,
              let platformRaw = data["platform"] as? String,
              let timestamp = (data["timestamp"] as? Timestamp)?.dateValue(),
              let successful = data["successful"] as? Bool,
              let sharedItemType = ShareType(rawValue: sharedItemTypeRaw),
              let platform = SharePlatform(rawValue: platformRaw)
        else { return nil }
        
        self.id = document.documentID
        self.userId = userId
        self.sharedItemId = sharedItemId
        self.sharedItemType = sharedItemType
        self.platform = platform
        self.timestamp = timestamp
        self.successful = successful
    }
} 