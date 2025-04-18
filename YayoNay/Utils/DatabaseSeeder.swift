import Foundation
import FirebaseFirestore

class DatabaseSeeder {
    private let db = Firestore.firestore()
    
    // Category-specific sub-questions
    private let categoryQuestions: [String: [String]] = [
        "Food": [
            "How is the taste?",
            "How is the presentation?",
            "How is the portion size?",
            "How is the value for money?",
            "How is the service?",
            "How is the ambiance?"
        ],
        "Movies": [
            "How is the plot?",
            "How are the performances?",
            "How is the cinematography?",
            "How is the soundtrack?",
            "How is the pacing?",
            "How is the ending?"
        ],
        "Music": [
            "How is the melody?",
            "How are the lyrics?",
            "How is the production?",
            "How is the vocal performance?",
            "How is the instrumentation?",
            "How is the overall vibe?"
        ],
        "Books": [
            "How is the writing style?",
            "How is the character development?",
            "How is the plot?",
            "How is the pacing?",
            "How is the world-building?",
            "How is the ending?"
        ],
        "Games": [
            "How is the gameplay?",
            "How are the graphics?",
            "How is the story?",
            "How are the controls?",
            "How is the replay value?",
            "How is the multiplayer?"
        ],
        "Travel": [
            "How is the location?",
            "How is the accessibility?",
            "How is the cleanliness?",
            "How is the atmosphere?",
            "How are the facilities?",
            "How is the value for money?"
        ]
    ]
    
    func initializeSubQuestionsCollection() {
        print("DEBUG: Initializing subQuestions collection...")
        
        // First, check if the collection exists and has documents
        db.collection("subQuestions").getDocuments { [weak self] snapshot, error in
            if let error = error {
                print("DEBUG: Error checking subQuestions collection: \(error.localizedDescription)")
                return
            }
            
            // If collection is empty or doesn't exist, seed it
            if snapshot?.documents.isEmpty ?? true {
                print("DEBUG: subQuestions collection is empty, seeding data...")
                self?.fetchCategoriesAndSeedSubQuestions()
            } else {
                print("DEBUG: subQuestions collection already exists with \(snapshot?.documents.count ?? 0) documents")
            }
        }
    }
    
    private func fetchCategoriesAndSeedSubQuestions() {
        print("DEBUG: Fetching categories to get their IDs...")
        
        db.collection("categories").getDocuments { [weak self] snapshot, error in
            if let error = error {
                print("DEBUG: Error fetching categories: \(error.localizedDescription)")
                return
            }
            
            guard let documents = snapshot?.documents else {
                print("DEBUG: No categories found")
                return
            }
            
            // Create a mapping of category names to their IDs
            let categoryIdMap = documents.reduce(into: [String: String]()) { result, doc in
                if let name = doc.data()["name"] as? String {
                    result[name] = doc.documentID
                }
            }
            
            print("DEBUG: Found \(categoryIdMap.count) categories")
            self?.seedSubQuestions(withCategoryIds: categoryIdMap)
        }
    }
    
    private func seedSubQuestions(withCategoryIds categoryIdMap: [String: String]) {
        print("DEBUG: Starting to seed sub-questions...")
        
        let batch = db.batch()
        
        for (categoryName, questions) in categoryQuestions {
            guard let categoryId = categoryIdMap[categoryName] else {
                print("DEBUG: No ID found for category: \(categoryName)")
                continue
            }
            
            for question in questions {
                let subQuestion = SubQuestion(
                    categoryId: categoryId,
                    question: question
                )
                
                let docRef = db.collection("subQuestions").document(subQuestion.id)
                batch.setData(subQuestion.dictionary, forDocument: docRef)
            }
        }
        
        batch.commit { error in
            if let error = error {
                print("DEBUG: Error seeding sub-questions: \(error.localizedDescription)")
            } else {
                print("DEBUG: Successfully seeded all sub-questions")
            }
        }
    }
    
    func clearSubQuestions() {
        print("DEBUG: Starting to clear sub-questions...")
        
        db.collection("subQuestions").getDocuments { [weak self] snapshot, error in
            if let error = error {
                print("DEBUG: Error fetching sub-questions: \(error.localizedDescription)")
                return
            }
            
            guard let documents = snapshot?.documents else { return }
            
            let batch = self?.db.batch()
            
            for document in documents {
                batch?.deleteDocument(document.reference)
            }
            
            batch?.commit { error in
                if let error = error {
                    print("DEBUG: Error clearing sub-questions: \(error.localizedDescription)")
                } else {
                    print("DEBUG: Successfully cleared all sub-questions")
                }
            }
        }
    }
} 