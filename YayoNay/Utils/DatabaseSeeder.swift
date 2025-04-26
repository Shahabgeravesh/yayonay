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
        "Drinks": [
            "How is the taste?",
            "How is the presentation?",
            "How is the price?",
            "How is the quality?",
            "How is the service?",
            "How is the atmosphere?"
        ],
        "Dessert": [
            "How is the taste?",
            "How is the presentation?",
            "How is the portion size?",
            "How is the price?",
            "How is the quality?",
            "How is the variety?"
        ],
        "Sports": [
            "How is the gameplay?",
            "How is the atmosphere?",
            "How is the venue?",
            "How is the value?",
            "How is the organization?",
            "How is the experience?"
        ],
        "Travel": [
            "How is the location?",
            "How is the accessibility?",
            "How is the cleanliness?",
            "How is the atmosphere?",
            "How are the facilities?",
            "How is the value for money?"
        ],
        "Art": [
            "How is the creativity?",
            "How is the technique?",
            "How is the presentation?",
            "How is the originality?",
            "How is the impact?",
            "How is the value?"
        ],
        "Music": [
            "How is the melody?",
            "How are the lyrics?",
            "How is the production?",
            "How is the vocal performance?",
            "How is the instrumentation?",
            "How is the overall vibe?"
        ],
        "Movies": [
            "How is the plot?",
            "How are the performances?",
            "How is the cinematography?",
            "How is the soundtrack?",
            "How is the pacing?",
            "How is the ending?"
        ],
        "Books": [
            "How is the writing style?",
            "How is the character development?",
            "How is the plot?",
            "How is the pacing?",
            "How is the world-building?",
            "How is the ending?"
        ],
        "Technology": [
            "How is the performance?",
            "How is the design?",
            "How is the usability?",
            "How is the price?",
            "How is the quality?",
            "How is the innovation?"
        ],
        "Politics": [
            "How is the policy?",
            "How is the leadership?",
            "How is the transparency?",
            "How is the effectiveness?",
            "How is the communication?",
            "How is the impact?"
        ],
        "Fashion": [
            "How is the style?",
            "How is the quality?",
            "How is the fit?",
            "How is the price?",
            "How is the trendiness?",
            "How is the versatility?"
        ],
        "Pets": [
            "How is the temperament?",
            "How is the health?",
            "How is the training?",
            "How is the care?",
            "How is the compatibility?",
            "How is the cost?"
        ],
        "Home Decor": [
            "How is the style?",
            "How is the quality?",
            "How is the functionality?",
            "How is the price?",
            "How is the durability?",
            "How is the aesthetics?"
        ],
        "Fitness": [
            "How is the effectiveness?",
            "How is the difficulty?",
            "How is the safety?",
            "How is the equipment?",
            "How is the instruction?",
            "How is the results?"
        ],
        "Gaming": [
            "How is the gameplay?",
            "How are the graphics?",
            "How is the story?",
            "How are the controls?",
            "How is the replay value?",
            "How is the multiplayer?"
        ],
        "Beauty": [
            "How is the quality?",
            "How is the application?",
            "How is the longevity?",
            "How is the price?",
            "How is the packaging?",
            "How is the results?"
        ],
        "Cars": [
            "How is the performance?",
            "How is the design?",
            "How is the comfort?",
            "How is the price?",
            "How is the reliability?",
            "How is the features?"
        ],
        "Photography": [
            "How is the quality?",
            "How is the composition?",
            "How is the lighting?",
            "How is the subject?",
            "How is the editing?",
            "How is the impact?"
        ],
        "Nature": [
            "How is the beauty?",
            "How is the accessibility?",
            "How is the preservation?",
            "How is the wildlife?",
            "How is the facilities?",
            "How is the experience?"
        ],
        "DIY": [
            "How is the difficulty?",
            "How is the cost?",
            "How is the time?",
            "How is the materials?",
            "How is the instructions?",
            "How is the results?"
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
        print("DEBUG: Starting fetchCategoriesAndSeedSubQuestions...")
        
        // Print all category names from our dictionary
        print("DEBUG: Category names in our dictionary:")
        for categoryName in self.categoryQuestions.keys {
            print("  - \(categoryName)")
        }
        
        db.collection("categories").getDocuments { [weak self] snapshot, error in
            guard let self = self else { return }
            
            if let error = error {
                print("DEBUG: Error fetching categories: \(error.localizedDescription)")
                return
            }
            
            guard let documents = snapshot?.documents else {
                print("DEBUG: No categories found in the database")
                return
            }
            
            print("DEBUG: Found \(documents.count) categories in the database")
            print("DEBUG: Category names in database:")
            for document in documents {
                let data = document.data()
                if let name = data["name"] as? String {
                    print("  - \(name)")
                }
            }
            
            // Create a mapping of category names to their IDs
            let categoryIdMap = documents.reduce(into: [String: String]()) { result, doc in
                if let name = doc.data()["name"] as? String {
                    result[name] = doc.documentID
                    print("DEBUG: Mapped category '\(name)' to ID: \(doc.documentID)")
                }
            }
            
            if categoryIdMap.isEmpty {
                print("DEBUG: ERROR: No valid category mappings found!")
                return
            }
            
            print("DEBUG: Successfully created category ID map with \(categoryIdMap.count) entries")
            
            // Print categories that don't have matching IDs
            let unmatchedCategories = Set(self.categoryQuestions.keys).subtracting(Set(categoryIdMap.keys))
            if !unmatchedCategories.isEmpty {
                print("DEBUG: WARNING: The following categories don't have matching IDs in the database:")
                for category in unmatchedCategories {
                    print("  - \(category)")
                }
            }
            
            self.seedSubQuestions(withCategoryIds: categoryIdMap)
        }
    }
    
    private func seedSubQuestions(withCategoryIds categoryIdMap: [String: String]) {
        print("DEBUG: Starting to seed sub-questions...")
        print("DEBUG: Category ID map: \(categoryIdMap)")
        
        // First, fetch all subcategories
        db.collection("subCategories").getDocuments { [weak self] snapshot, error in
            guard let self = self else { return }
            
            if let error = error {
                print("DEBUG: Error fetching subcategories: \(error.localizedDescription)")
                return
            }
            
            guard let subCategoryDocuments = snapshot?.documents else {
                print("DEBUG: No subcategories found")
                return
            }
            
            print("DEBUG: Found \(subCategoryDocuments.count) subcategories")
            
            // Group subcategories by their categoryId
            var subCategoriesByCategory: [String: [QueryDocumentSnapshot]] = [:]
            for doc in subCategoryDocuments {
                if let categoryId = doc.data()["categoryId"] as? String {
                    if subCategoriesByCategory[categoryId] == nil {
                        subCategoriesByCategory[categoryId] = []
                    }
                    subCategoriesByCategory[categoryId]?.append(doc)
                }
            }
            
            let batch = self.db.batch()
            var questionCount = 0
            var failedCategories: [String] = []
            
            for (categoryName, questions) in self.categoryQuestions {
                guard let categoryId = categoryIdMap[categoryName] else {
                    print("DEBUG: WARNING: No ID found for category: \(categoryName)")
                    failedCategories.append(categoryName)
                    continue
                }
                
                guard let subCategories = subCategoriesByCategory[categoryId] else {
                    print("DEBUG: WARNING: No subcategories found for category: \(categoryName)")
                    continue
                }
                
                print("DEBUG: Seeding questions for category: \(categoryName) (ID: \(categoryId))")
                print("DEBUG: Found \(subCategories.count) subcategories for this category")
                
                for subCategoryDoc in subCategories {
                    let subCategoryId = subCategoryDoc.documentID
                    print("DEBUG: Processing subcategory: \(subCategoryId)")
                    
                    for question in questions {
                        let subQuestion = SubQuestion(
                            categoryId: categoryId,
                            subCategoryId: subCategoryId,
                            question: question
                        )
                        
                        print("DEBUG: Creating sub-question:")
                        print("  - ID: \(subQuestion.id)")
                        print("  - Category ID: \(subQuestion.categoryId)")
                        print("  - SubCategory ID: \(subQuestion.subCategoryId)")
                        print("  - Question: \(subQuestion.question)")
                        
                        let docRef = self.db.collection("subQuestions").document(subQuestion.id)
                        batch.setData(subQuestion.dictionary, forDocument: docRef)
                        questionCount += 1
                    }
                }
            }
            
            if !failedCategories.isEmpty {
                print("DEBUG: WARNING: Failed to find IDs for categories: \(failedCategories.joined(separator: ", "))")
            }
            
            print("DEBUG: Committing batch of \(questionCount) questions...")
            
            batch.commit { error in
                if let error = error {
                    print("DEBUG: ERROR: Failed to seed sub-questions: \(error.localizedDescription)")
                    print("DEBUG: Error details: \(error)")
                } else {
                    print("DEBUG: Successfully seeded \(questionCount) sub-questions")
                    
                    // Verify the seeding was successful
                    self.db.collection("subQuestions").getDocuments { snapshot, error in
                        if let error = error {
                            print("DEBUG: ERROR: Failed to verify seeding: \(error.localizedDescription)")
                            return
                        }
                        
                        if let documents = snapshot?.documents {
                            print("DEBUG: Verification: Found \(documents.count) sub-questions in database")
                            for document in documents {
                                let data = document.data()
                                print("DEBUG: Verified sub-question:")
                                print("  - ID: \(document.documentID)")
                                print("  - Category ID: \(data["categoryId"] as? String ?? "unknown")")
                                print("  - SubCategory ID: \(data["subCategoryId"] as? String ?? "unknown")")
                                print("  - Question: \(data["question"] as? String ?? "unknown")")
                            }
                        } else {
                            print("DEBUG: ERROR: Verification failed - no documents found")
                        }
                    }
                }
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