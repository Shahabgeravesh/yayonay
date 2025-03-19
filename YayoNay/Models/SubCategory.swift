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
    var attributes: [String: AttributeVotes]
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case imageURL
        case categoryId
        case order
        case yayCount
        case nayCount
        case attributes
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
        attributes = try container.decode([String: AttributeVotes].self, forKey: .attributes)
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
        try container.encode(attributes, forKey: .attributes)
    }
    
    init(id: String = UUID().uuidString,
         name: String,
         imageURL: String,
         categoryId: String,
         order: Int,
         yayCount: Int = 0,
         nayCount: Int = 0,
         attributes: [String: AttributeVotes] = [:]) {
        self.id = id
        self.name = name
        self.imageURL = imageURL
        self.categoryId = categoryId
        self.order = order
        self.yayCount = yayCount
        self.nayCount = nayCount
        self.attributes = attributes
    }
    
    var dictionary: [String: Any] {
        return [
            "name": name,
            "imageURL": imageURL,
            "categoryId": categoryId,
            "order": order,
            "yayCount": yayCount,
            "nayCount": nayCount,
            "attributes": attributes.mapValues { votes in
                [
                    "yayCount": votes.yayCount,
                    "nayCount": votes.nayCount
                ]
            }
        ]
    }
    
    static func == (lhs: SubCategory, rhs: SubCategory) -> Bool {
        return lhs.id == rhs.id &&
               lhs.name == rhs.name &&
               lhs.imageURL == rhs.imageURL &&
               lhs.categoryId == rhs.categoryId &&
               lhs.order == rhs.order &&
               lhs.yayCount == rhs.yayCount &&
               lhs.nayCount == rhs.nayCount &&
               lhs.attributes == rhs.attributes
    }
}

extension SubCategory {
    init?(document: DocumentSnapshot) {
        let data = document.data() ?? [:]
        
        guard let name = data["name"] as? String,
              let imageURL = data["imageURL"] as? String,
              let categoryId = data["categoryId"] as? String,
              let order = data["order"] as? Int else {
            return nil
        }
        
        self.id = document.documentID
        self.name = name
        self.imageURL = imageURL
        self.categoryId = categoryId
        self.order = order
        self.yayCount = data["yayCount"] as? Int ?? 0
        self.nayCount = data["nayCount"] as? Int ?? 0
        
        if let attributesData = data["attributes"] as? [String: [String: Int]] {
            self.attributes = attributesData.mapValues { votes in
                AttributeVotes(
                    yayCount: votes["yayCount"] ?? 0,
                    nayCount: votes["nayCount"] ?? 0
                )
            }
        } else {
            self.attributes = [:]
        }
    }
} 