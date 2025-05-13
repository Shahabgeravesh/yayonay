import Foundation
import FirebaseFirestore

struct Category: Identifiable, Codable, Hashable {
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
        self.description = data["description"] as? String ?? ""
    }
    
    var dictionary: [String: Any] {
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
    
    // Hashable conformance
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: Category, rhs: Category) -> Bool {
        lhs.id == rhs.id
    }
} 