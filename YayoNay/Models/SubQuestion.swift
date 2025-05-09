import Foundation
import FirebaseFirestore

struct SubQuestion: Identifiable, Codable {
    let id: String
    let categoryId: String
    let subCategoryId: String
    let question: String
    var yayCount: Int
    var nayCount: Int
    
    var totalVotes: Int { yayCount + nayCount }
    var yayPercentage: Double {
        totalVotes > 0 ? Double(yayCount) / Double(totalVotes) * 100 : 0
    }
    var nayPercentage: Double {
        totalVotes > 0 ? Double(nayCount) / Double(totalVotes) * 100 : 0
    }
    
    init(id: String = UUID().uuidString,
         categoryId: String,
         subCategoryId: String,
         question: String,
         yayCount: Int = 0,
         nayCount: Int = 0) {
        self.id = id
        self.categoryId = categoryId
        self.subCategoryId = subCategoryId
        self.question = question
        self.yayCount = yayCount
        self.nayCount = nayCount
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
    }
    
    var dictionary: [String: Any] {
        return [
            "categoryId": categoryId,
            "subCategoryId": subCategoryId,
            "question": question,
            "yayCount": yayCount,
            "nayCount": nayCount
        ]
    }
} 