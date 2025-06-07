import Foundation

struct Vote: Codable, Identifiable {
    let id: String
    let userId: String
    let categoryId: String
    let subCategoryId: String
    let topicId: String
    let voteType: Bool
    let timestamp: Date
    let itemName: String
    let imageURL: String?
    let categoryName: String
    let createdAt: Date
    let updatedAt: Date
    var topic: Topic?
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case categoryId = "category_id"
        case subCategoryId = "sub_category_id"
        case topicId = "topic_id"
        case voteType = "vote_type"
        case timestamp
        case itemName = "item_name"
        case imageURL = "image_url"
        case categoryName = "category_name"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case topic
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        userId = try container.decode(String.self, forKey: .userId)
        categoryId = try container.decode(String.self, forKey: .categoryId)
        subCategoryId = try container.decode(String.self, forKey: .subCategoryId)
        topicId = try container.decode(String.self, forKey: .topicId)
        voteType = try container.decode(Bool.self, forKey: .voteType)
        timestamp = try container.decode(Date.self, forKey: .timestamp)
        itemName = try container.decode(String.self, forKey: .itemName)
        imageURL = try container.decodeIfPresent(String.self, forKey: .imageURL)
        categoryName = try container.decode(String.self, forKey: .categoryName)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        updatedAt = try container.decode(Date.self, forKey: .updatedAt)
        topic = try container.decodeIfPresent(Topic.self, forKey: .topic)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(userId, forKey: .userId)
        try container.encode(categoryId, forKey: .categoryId)
        try container.encode(subCategoryId, forKey: .subCategoryId)
        try container.encode(topicId, forKey: .topicId)
        try container.encode(voteType, forKey: .voteType)
        try container.encode(timestamp, forKey: .timestamp)
        try container.encode(itemName, forKey: .itemName)
        try container.encodeIfPresent(imageURL, forKey: .imageURL)
        try container.encode(categoryName, forKey: .categoryName)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(updatedAt, forKey: .updatedAt)
        try container.encodeIfPresent(topic, forKey: .topic)
    }
} 