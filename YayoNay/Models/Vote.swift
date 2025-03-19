import Foundation
import FirebaseFirestore

struct Vote: Identifiable, Codable, Hashable {
    let id: String
    let itemName: String
    let imageURL: String
    let isYay: Bool
    let date: Date
    let categoryName: String
    let categoryId: String
    let subCategoryId: String
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: Vote, rhs: Vote) -> Bool {
        lhs.id == rhs.id
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case itemName
        case imageURL
        case isYay
        case date
        case categoryName
        case categoryId
        case subCategoryId
    }
    
    init(id: String,
         itemName: String,
         imageURL: String,
         isYay: Bool,
         date: Date,
         categoryName: String,
         categoryId: String,
         subCategoryId: String) {
        self.id = id
        self.itemName = itemName
        self.imageURL = imageURL
        self.isYay = isYay
        self.date = date
        self.categoryName = categoryName
        self.categoryId = categoryId
        self.subCategoryId = subCategoryId
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        itemName = try container.decode(String.self, forKey: .itemName)
        imageURL = try container.decode(String.self, forKey: .imageURL)
        isYay = try container.decode(Bool.self, forKey: .isYay)
        date = try container.decode(Date.self, forKey: .date)
        categoryName = try container.decode(String.self, forKey: .categoryName)
        categoryId = try container.decode(String.self, forKey: .categoryId)
        subCategoryId = try container.decode(String.self, forKey: .subCategoryId)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(itemName, forKey: .itemName)
        try container.encode(imageURL, forKey: .imageURL)
        try container.encode(isYay, forKey: .isYay)
        try container.encode(date, forKey: .date)
        try container.encode(categoryName, forKey: .categoryName)
        try container.encode(categoryId, forKey: .categoryId)
        try container.encode(subCategoryId, forKey: .subCategoryId)
    }
    
    var dictionary: [String: Any] {
        return [
            "itemName": itemName,
            "imageURL": imageURL,
            "isYay": isYay,
            "date": Timestamp(date: date),
            "categoryName": categoryName,
            "categoryId": categoryId,
            "subCategoryId": subCategoryId
        ]
    }
    
    init?(document: QueryDocumentSnapshot) {
        let data = document.data()
        
        guard let itemName = data["itemName"] as? String,
              let imageURL = data["imageURL"] as? String,
              let isYay = data["isYay"] as? Bool,
              let timestamp = data["date"] as? Timestamp,
              let categoryName = data["categoryName"] as? String,
              let categoryId = data["categoryId"] as? String,
              let subCategoryId = data["subCategoryId"] as? String
        else { return nil }
        
        self.id = document.documentID
        self.itemName = itemName
        self.imageURL = imageURL
        self.isYay = isYay
        self.date = timestamp.dateValue()
        self.categoryName = categoryName
        self.categoryId = categoryId
        self.subCategoryId = subCategoryId
    }
} 