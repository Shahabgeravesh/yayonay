import Foundation
import FirebaseFirestore

struct Category: Identifiable, Codable {
    var id: String
    var name: String
    var imageURL: String?
    var isTopCategory: Bool // For the top grid items that are white cards
    var order: Int // To maintain custom ordering
    var description: String  // Add this property
    
    init(id: String = UUID().uuidString,
         name: String,
         imageURL: String? = nil,
         isTopCategory: Bool = false,
         order: Int = 0,
         description: String = "") {
        self.id = id
        self.name = name
        self.imageURL = imageURL
        self.isTopCategory = isTopCategory
        self.order = order
        self.description = description
    }
    
    init?(document: QueryDocumentSnapshot) {
        let data = document.data()
        
        guard let name = data["name"] as? String else { return nil }
        
        self.id = document.documentID
        self.name = name
        self.imageURL = data["imageURL"] as? String
        self.isTopCategory = data["isTopCategory"] as? Bool ?? false
        self.order = data["order"] as? Int ?? 0
        
        // Set description after initializing name
        let defaultDescription = Category.getDefaultDescription(for: name)
        self.description = data["description"] as? String ?? defaultDescription
    }
    
    var toDict: [String: Any] {
        return [
            "name": name,
            "imageURL": imageURL ?? "",
            "isTopCategory": isTopCategory,
            "order": order,
            "description": description
        ]
    }
    
    // Make this static so it can be called without instance
    static func getDefaultDescription(for category: String) -> String {
        switch category.lowercased() {
        case "food":
            return "Discover delicious dishes"
        case "fruit":
            return "Fresh and healthy options"
        case "drink":
            return "Refreshing beverages"
        case "dessert":
            return "Sweet treats and delights"
        case "sports":
            return "Game on!"
        case "hike":
            return "Trail adventures"
        case "travel":
            return "Explore destinations"
        case "art":
            return "Creative expressions"
        default:
            return "Explore and vote"
        }
    }
} 