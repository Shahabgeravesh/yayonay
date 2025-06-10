import Foundation
import FirebaseFirestore

struct SubCategory: Identifiable, Codable, Equatable {
    let id: String
    let name: String
    let imageURL: String
    let categoryId: String
    let order: Int
    var yayCount: Int
    var nayCount: Int
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case imageURL
        case categoryId
        case order
        case yayCount
        case nayCount
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        imageURL = try container.decode(String.self, forKey: .imageURL)
        categoryId = try container.decode(String.self, forKey: .categoryId)
        order = try container.decode(Int.self, forKey: .order)
        yayCount = try container.decode(Int.self, forKey: .yayCount)
        nayCount = try container.decode(Int.self, forKey: .nayCount)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(imageURL, forKey: .imageURL)
        try container.encode(categoryId, forKey: .categoryId)
        try container.encode(order, forKey: .order)
        try container.encode(yayCount, forKey: .yayCount)
        try container.encode(nayCount, forKey: .nayCount)
    }
    
    init(id: String = UUID().uuidString,
         name: String,
         imageURL: String,
         categoryId: String,
         order: Int,
         yayCount: Int = 0,
         nayCount: Int = 0) {
        self.id = id
        self.name = name
        self.imageURL = imageURL
        self.categoryId = categoryId
        self.order = order
        self.yayCount = yayCount
        self.nayCount = nayCount
    }
    
    var dictionary: [String: Any] {
        return [
            "name": name,
            "imageURL": imageURL,
            "categoryId": categoryId,
            "order": order,
            "yayCount": yayCount,
            "nayCount": nayCount
        ]
    }
    
    static func == (lhs: SubCategory, rhs: SubCategory) -> Bool {
        return lhs.id == rhs.id &&
               lhs.name == rhs.name &&
               lhs.imageURL == rhs.imageURL &&
               lhs.categoryId == rhs.categoryId &&
               lhs.order == rhs.order &&
               lhs.yayCount == rhs.yayCount &&
               lhs.nayCount == rhs.nayCount
    }
}

extension SubCategory {
    init?(document: DocumentSnapshot) {
        let data = document.data() ?? [:]
        print("DEBUG SubCategory data for doc id \(document.documentID):", data)
        guard let name = data["name"] as? String,
              let imageURL = data["imageURL"] as? String,
              let categoryId = data["categoryId"] as? String,
              let order = data["order"] as? Int else {
            print("Missing required field in subcategory doc id: \(document.documentID)")
            return nil
        }
        self.id = document.documentID
        self.name = name
        self.imageURL = imageURL
        self.categoryId = categoryId
        self.order = order
        self.yayCount = data["yayCount"] as? Int ?? 0
        self.nayCount = data["nayCount"] as? Int ?? 0
    }
} 