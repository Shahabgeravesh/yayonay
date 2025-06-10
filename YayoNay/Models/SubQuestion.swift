import Foundation
import FirebaseFirestore

struct SubQuestion: Identifiable, Codable {
    let id: String
    let categoryId: String
    let subCategoryId: String
    let question: String
    var yayCount: Int
    var nayCount: Int
    var order: Int
    var active: Bool
    var createdAt: Date?
    var updatedAt: Date?
    var votesMetadata: VotesMetadata
    
    struct VotesMetadata: Codable {
        var lastVoteAt: Date?
        var totalVotes: Int
        var uniqueVoters: Int
    }
    
    init(id: String = UUID().uuidString,
         categoryId: String,
         subCategoryId: String,
         question: String,
         yayCount: Int = 0,
         nayCount: Int = 0,
         order: Int = 0,
         active: Bool = true,
         createdAt: Date? = nil,
         updatedAt: Date? = nil,
         votesMetadata: VotesMetadata = VotesMetadata(lastVoteAt: nil, totalVotes: 0, uniqueVoters: 0)) {
        self.id = id
        self.categoryId = categoryId
        self.subCategoryId = subCategoryId
        self.question = question
        self.yayCount = yayCount
        self.nayCount = nayCount
        self.order = order
        self.active = active
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.votesMetadata = votesMetadata
    }
    
    init?(document: QueryDocumentSnapshot) {
        let data = document.data()
        
        guard let categoryId = data["categoryId"] as? String,
              let subCategoryId = data["subCategoryId"] as? String,
              let question = data["question"] as? String else {
            return nil
        }
        
        self.id = document.documentID
        self.categoryId = categoryId
        self.subCategoryId = subCategoryId
        self.question = question
        self.yayCount = data["yayCount"] as? Int ?? 0
        self.nayCount = data["nayCount"] as? Int ?? 0
        self.order = data["order"] as? Int ?? 0
        self.active = data["active"] as? Bool ?? true
        
        if let createdAtTimestamp = data["createdAt"] as? Timestamp {
            self.createdAt = createdAtTimestamp.dateValue()
        } else {
            self.createdAt = nil
        }
        
        if let updatedAtTimestamp = data["updatedAt"] as? Timestamp {
            self.updatedAt = updatedAtTimestamp.dateValue()
        } else {
            self.updatedAt = nil
        }
        
        if let metadata = data["votesMetadata"] as? [String: Any] {
            let lastVoteAt = (metadata["lastVoteAt"] as? Timestamp)?.dateValue()
            let totalVotes = metadata["totalVotes"] as? Int ?? 0
            let uniqueVoters = metadata["uniqueVoters"] as? Int ?? 0
            self.votesMetadata = VotesMetadata(lastVoteAt: lastVoteAt,
                                             totalVotes: totalVotes,
                                             uniqueVoters: uniqueVoters)
        } else {
            self.votesMetadata = VotesMetadata(lastVoteAt: nil, totalVotes: 0, uniqueVoters: 0)
        }
    }
    
    var dictionary: [String: Any] {
        var dict: [String: Any] = [
            "categoryId": categoryId,
            "subCategoryId": subCategoryId,
            "question": question,
            "yayCount": yayCount,
            "nayCount": nayCount,
            "order": order,
            "active": active
        ]
        
        // Create votesMetadata dictionary
        var votesMetadataDict: [String: Any] = [
            "totalVotes": votesMetadata.totalVotes,
            "uniqueVoters": votesMetadata.uniqueVoters
        ]
        
        // Add lastVoteAt if it exists
        if let lastVoteAt = votesMetadata.lastVoteAt {
            votesMetadataDict["lastVoteAt"] = Timestamp(date: lastVoteAt)
        }
        
        // Add the votesMetadata dictionary to the main dictionary
        dict["votesMetadata"] = votesMetadataDict
        
        // Add timestamps if they exist
        if let createdAt = createdAt {
            dict["createdAt"] = Timestamp(date: createdAt)
        }
        if let updatedAt = updatedAt {
            dict["updatedAt"] = Timestamp(date: updatedAt)
        }
        
        return dict
    }
} 