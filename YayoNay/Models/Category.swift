import Foundation
import FirebaseFirestore

struct Category: Identifiable, Codable {
    var id: String
    var name: String
    var imageURL: String?
    var isTopCategory: Bool // For the top grid items that are white cards
    var order: Int // To maintain custom ordering
    var description: String  // Add this property
    var featured: Bool
    var votesCount: Int
    
    init(id: String = UUID().uuidString,
         name: String,
         imageURL: String? = nil,
         isTopCategory: Bool = false,
         order: Int = 0,
         description: String = "",
         featured: Bool = false,
         votesCount: Int = 0) {
        self.id = id
        self.name = name
        self.imageURL = imageURL
        self.isTopCategory = isTopCategory
        self.order = order
        self.description = description
        self.featured = featured
        self.votesCount = votesCount
    }
    
    init?(document: QueryDocumentSnapshot) {
        let data = document.data()
        
        guard let name = data["name"] as? String else { return nil }
        
        self.id = document.documentID
        self.name = name
        self.imageURL = data["imageURL"] as? String
        self.isTopCategory = data["isTopCategory"] as? Bool ?? false
        self.order = data["order"] as? Int ?? 0
        self.featured = data["featured"] as? Bool ?? false
        self.votesCount = data["votesCount"] as? Int ?? 0
        
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
            "description": description,
            "featured": featured,
            "votesCount": votesCount
        ]
    }
    
    // Computed property to get the appropriate icon name for the category
    var iconName: String {
        switch name.lowercased() {
        case "food":
            return "fork.knife"
        case "drinks", "drink":
            return "cup.and.saucer.fill"
        case "dessert":
            return "birthday.cake.fill"
        case "sports", "sport":
            return "figure.run"
        case "travel":
            return "airplane"
        case "art", "arts":
            return "paintbrush.fill"
        case "music":
            return "music.note"
        case "movies", "movie":
            return "film"
        case "books", "book":
            return "book.fill"
        case "technology", "tech":
            return "laptopcomputer"
        case "fashion":
            return "tshirt.fill"
        case "pets":
            return "pawprint.fill"
        case "home decor":
            return "house.fill"
        case "fitness":
            return "figure.walk"
        case "gaming":
            return "gamecontroller.fill"
        case "beauty":
            return "sparkles"
        case "cars":
            return "car.fill"
        case "photography":
            return "camera.fill"
        case "nature":
            return "leaf.fill"
        case "diy":
            return "hammer.fill"
        default:
            return "star.fill"
        }
    }
    
    // Make this static so it can be called without instance
    static func getDefaultDescription(for category: String) -> String {
        switch category.lowercased() {
        case "food":
            return "Discover delicious dishes"
        case "drinks", "drink":
            return "Refreshing beverages"
        case "dessert":
            return "Sweet treats and delights"
        case "sports", "sport":
            return "Game on!"
        case "travel":
            return "Explore destinations"
        case "art", "arts":
            return "Creative expressions"
        case "music":
            return "Rhythm and melodies"
        case "movies", "movie":
            return "Cinematic experiences"
        case "books", "book":
            return "Literary adventures"
        case "technology", "tech":
            return "Innovation and gadgets"
        case "fashion":
            return "Style and trends"
        case "pets":
            return "Furry friends and companions"
        case "home decor":
            return "Interior design and decoration"
        case "fitness":
            return "Health and exercise"
        case "gaming":
            return "Video games and entertainment"
        case "beauty":
            return "Cosmetics and skincare"
        case "cars":
            return "Automobiles and vehicles"
        case "photography":
            return "Capturing moments"
        case "nature":
            return "Outdoor and wildlife"
        case "diy":
            return "Do it yourself projects"
        default:
            return "Explore and vote"
        }
    }
} 