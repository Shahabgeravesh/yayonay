import FirebaseFirestore

class SubCategoryImporter {
    static let shared = SubCategoryImporter()
    private let db = Firestore.firestore()
    
    // Fruit subcategories
    func importFruitSubcategories(categoryId: String, completion: @escaping (Bool) -> Void = { _ in }) {
        print("📱 Starting fruit import for categoryId:", categoryId)
        let batch = db.batch()
        
        let fruits = [
            SubCategory(
                name: "Orange",
                imageURL: "https://images.unsplash.com/photo-1557800636-894a64c1696f?w=800",
                categoryId: categoryId,
                order: 0
            ),
            SubCategory(
                name: "Apple",
                imageURL: "https://images.unsplash.com/photo-1560806887-1e4cd0b6cbd6?w=800",
                categoryId: categoryId,
                order: 1
            ),
            SubCategory(
                name: "Banana",
                imageURL: "https://images.unsplash.com/photo-1571771894821-ce9b6c11b08e?w=800",
                categoryId: categoryId,
                order: 2
            ),
            SubCategory(
                name: "Strawberry",
                imageURL: "https://images.unsplash.com/photo-1464965911861-746a04b4bca6?w=800",
                categoryId: categoryId,
                order: 3
            ),
            SubCategory(
                name: "Mango",
                imageURL: "https://images.unsplash.com/photo-1553279768-865429fa0078?w=800",
                categoryId: categoryId,
                order: 4
            ),
            SubCategory(
                name: "Grapes",
                imageURL: "https://images.unsplash.com/photo-1537640538966-79f369143f8f?w=800",
                categoryId: categoryId,
                order: 5
            ),
            SubCategory(
                name: "Watermelon",
                imageURL: "https://images.unsplash.com/photo-1587049633312-d628ae50a8ae?w=800",
                categoryId: categoryId,
                order: 6
            ),
            SubCategory(
                name: "Pineapple",
                imageURL: "https://images.unsplash.com/photo-1550258987-190a2d41a8ba?w=800",
                categoryId: categoryId,
                order: 7
            ),
            SubCategory(
                name: "Kiwi",
                imageURL: "https://images.unsplash.com/photo-1585059895524-72359e06133a?w=800",
                categoryId: categoryId,
                order: 8
            ),
            SubCategory(
                name: "Peach",
                imageURL: "https://images.unsplash.com/photo-1595145610670-f32fd5d0473f?w=800",
                categoryId: categoryId,
                order: 9
            ),
            SubCategory(
                name: "Dragon Fruit",
                imageURL: "https://images.unsplash.com/photo-1527325678964-54921661f888?w=800",
                categoryId: categoryId,
                order: 10
            ),
            SubCategory(
                name: "Blueberries",
                imageURL: "https://images.unsplash.com/photo-1498557850523-fd3d118b962e?w=800",
                categoryId: categoryId,
                order: 11
            )
        ]
        
        print("📱 Attempting to import \(fruits.count) fruits")
        importSubcategories(subcategories: fruits, batch: batch, completion: completion)
    }
    
    // Food subcategories
    func importFoodSubcategories(categoryId: String, completion: @escaping (Bool) -> Void = { _ in }) {
        print("📱 Starting food import for categoryId:", categoryId)
        let batch = db.batch()
        
        let foods = [
            SubCategory(
                name: "Pizza",
                imageURL: "https://images.unsplash.com/photo-1513104890138-7c749659a591?w=800",
                categoryId: categoryId,
                order: 0
            ),
            SubCategory(
                name: "Burger",
                imageURL: "https://images.unsplash.com/photo-1568901346375-23c9450c58cd?w=800",
                categoryId: categoryId,
                order: 1
            ),
            SubCategory(
                name: "Sushi",
                imageURL: "https://images.unsplash.com/photo-1579871494447-9811cf80d66c?w=800",
                categoryId: categoryId,
                order: 2
            ),
            SubCategory(
                name: "Pasta",
                imageURL: "https://images.unsplash.com/photo-1551183053-bf91a1d81141?w=800",
                categoryId: categoryId,
                order: 3
            ),
            SubCategory(
                name: "Tacos",
                imageURL: "https://images.unsplash.com/photo-1551504734-5ee1c4a1479b?w=800",
                categoryId: categoryId,
                order: 4
            ),
            SubCategory(
                name: "Salad",
                imageURL: "https://images.unsplash.com/photo-1512621776951-a57141f2eefd?w=800",
                categoryId: categoryId,
                order: 5
            ),
            SubCategory(
                name: "Steak",
                imageURL: "https://images.unsplash.com/photo-1600891964092-4316c288032e?w=800",
                categoryId: categoryId,
                order: 6
            ),
            SubCategory(
                name: "Ramen",
                imageURL: "https://images.unsplash.com/photo-1569718212165-3a8278d5f624?w=800",
                categoryId: categoryId,
                order: 7
            ),
            SubCategory(
                name: "Ice Cream",
                imageURL: "https://images.unsplash.com/photo-1497034825429-c343d7c6a68f?w=800",
                categoryId: categoryId,
                order: 8
            ),
            SubCategory(
                name: "Pancakes",
                imageURL: "https://images.unsplash.com/photo-1528207776546-365bb710ee93?w=800",
                categoryId: categoryId,
                order: 9
            )
        ]
        
        print("📱 Attempting to import \(foods.count) food items")
        importSubcategories(subcategories: foods, batch: batch, completion: completion)
    }
    
    // Drink subcategories
    func importDrinkSubcategories(categoryId: String, completion: @escaping (Bool) -> Void = { _ in }) {
        let batch = db.batch()
        
        let drinks = [
            SubCategory(
                name: "Coffee",
                imageURL: "https://images.unsplash.com/photo-1509042239860-f550ce710b93?w=800",
                categoryId: categoryId,
                order: 0
            ),
            SubCategory(
                name: "Smoothie",
                imageURL: "https://images.unsplash.com/photo-1505252585461-04db1eb84625?w=800",
                categoryId: categoryId,
                order: 1
            ),
            SubCategory(
                name: "Bubble Tea",
                imageURL: "https://images.unsplash.com/photo-1558857563-c0c3a62ff0fb?w=800",
                categoryId: categoryId,
                order: 2
            ),
            SubCategory(
                name: "Lemonade",
                imageURL: "https://images.unsplash.com/photo-1621263764928-df1444c5e859?w=800",
                categoryId: categoryId,
                order: 3
            ),
            SubCategory(
                name: "Mojito",
                imageURL: "https://images.unsplash.com/photo-1551538827-9c037cb4f32a?w=800",
                categoryId: categoryId,
                order: 4
            )
        ]
        
        importSubcategories(subcategories: drinks, batch: batch, completion: completion)
    }
    
    // Dessert subcategories
    func importDessertSubcategories(categoryId: String, completion: @escaping (Bool) -> Void = { _ in }) {
        let batch = db.batch()
        
        let desserts = [
            SubCategory(
                name: "Ice Cream",
                imageURL: "https://images.unsplash.com/photo-1497034825429-c343d7c6a68f?w=800",
                categoryId: categoryId,
                order: 0
            ),
            SubCategory(
                name: "Chocolate Cake",
                imageURL: "https://images.unsplash.com/photo-1578985545062-69928b1d9587?w=800",
                categoryId: categoryId,
                order: 1
            ),
            SubCategory(
                name: "Macarons",
                imageURL: "https://images.unsplash.com/photo-1569864358642-9d1684040f43?w=800",
                categoryId: categoryId,
                order: 2
            ),
            SubCategory(
                name: "Cheesecake",
                imageURL: "https://images.unsplash.com/photo-1524351199678-941a58a3df50?w=800",
                categoryId: categoryId,
                order: 3
            ),
            SubCategory(
                name: "Donuts",
                imageURL: "https://images.unsplash.com/photo-1551024601-bec78aea704b?w=800",
                categoryId: categoryId,
                order: 4
            )
        ]
        
        importSubcategories(subcategories: desserts, batch: batch, completion: completion)
    }
    
    // Sports subcategories
    func importSportsSubcategories(categoryId: String, completion: @escaping (Bool) -> Void = { _ in }) {
        let batch = db.batch()
        
        let sports = [
            SubCategory(
                name: "Basketball",
                imageURL: "https://images.unsplash.com/photo-1546519638-68e109498ffc?w=800",
                categoryId: categoryId,
                order: 0
            ),
            SubCategory(
                name: "Soccer",
                imageURL: "https://images.unsplash.com/photo-1579952363873-27f3bade9f55?w=800",
                categoryId: categoryId,
                order: 1
            ),
            SubCategory(
                name: "Tennis",
                imageURL: "https://images.unsplash.com/photo-1595435934249-5df7ed86e1c0?w=800",
                categoryId: categoryId,
                order: 2
            ),
            SubCategory(
                name: "Swimming",
                imageURL: "https://images.unsplash.com/photo-1530549387789-4c1017266635?w=800",
                categoryId: categoryId,
                order: 3
            ),
            SubCategory(
                name: "Volleyball",
                imageURL: "https://images.unsplash.com/photo-1592656094267-764a45160876?w=800",
                categoryId: categoryId,
                order: 4
            ),
            SubCategory(
                name: "Baseball",
                imageURL: "https://images.unsplash.com/photo-1508344928928-7165b67de128?w=800",
                categoryId: categoryId,
                order: 5
            )
        ]
        
        importSubcategories(subcategories: sports, batch: batch, completion: completion)
    }
    
    // Hike subcategories
    func importHikeSubcategories(categoryId: String, completion: @escaping (Bool) -> Void = { _ in }) {
        let batch = db.batch()
        
        let hikes = [
            SubCategory(
                name: "Mountain Trail",
                imageURL: "https://images.unsplash.com/photo-1551632811-561732d1e306?w=800",
                categoryId: categoryId,
                order: 0
            ),
            SubCategory(
                name: "Forest Path",
                imageURL: "https://images.unsplash.com/photo-1441974231531-c6227db76b6e?w=800",
                categoryId: categoryId,
                order: 1
            ),
            SubCategory(
                name: "Coastal Walk",
                imageURL: "https://images.unsplash.com/photo-1500530855697-b586d89ba3ee?w=800",
                categoryId: categoryId,
                order: 2
            ),
            SubCategory(
                name: "Desert Trek",
                imageURL: "https://images.unsplash.com/photo-1509316785289-025f5b846b35?w=800",
                categoryId: categoryId,
                order: 3
            ),
            SubCategory(
                name: "Waterfall Trail",
                imageURL: "https://images.unsplash.com/photo-1432405972618-c60b0225b8f9?w=800",
                categoryId: categoryId,
                order: 4
            )
        ]
        
        importSubcategories(subcategories: hikes, batch: batch, completion: completion)
    }
    
    // Travel subcategories
    func importTravelSubcategories(categoryId: String, completion: @escaping (Bool) -> Void = { _ in }) {
        let batch = db.batch()
        
        let travels = [
            SubCategory(
                name: "Paris",
                imageURL: "https://images.unsplash.com/photo-1502602898657-3e91760cbb34?w=800",
                categoryId: categoryId,
                order: 0
            ),
            SubCategory(
                name: "Tokyo",
                imageURL: "https://images.unsplash.com/photo-1503899036084-c55cdd92da26?w=800",
                categoryId: categoryId,
                order: 1
            ),
            SubCategory(
                name: "New York",
                imageURL: "https://images.unsplash.com/photo-1496442226666-8d4d0e62e6e9?w=800",
                categoryId: categoryId,
                order: 2
            ),
            SubCategory(
                name: "Venice",
                imageURL: "https://images.unsplash.com/photo-1514890547357-a9ee288728e0?w=800",
                categoryId: categoryId,
                order: 3
            ),
            SubCategory(
                name: "Dubai",
                imageURL: "https://images.unsplash.com/photo-1512453979798-5ea266f8880c?w=800",
                categoryId: categoryId,
                order: 4
            ),
            SubCategory(
                name: "Sydney",
                imageURL: "https://images.unsplash.com/photo-1506973035872-a4ec16b8e8d9?w=800",
                categoryId: categoryId,
                order: 5
            )
        ]
        
        importSubcategories(subcategories: travels, batch: batch, completion: completion)
    }
    
    // Art subcategories
    func importArtSubcategories(categoryId: String, completion: @escaping (Bool) -> Void = { _ in }) {
        let batch = db.batch()
        
        let arts = [
            SubCategory(
                name: "Painting",
                imageURL: "https://images.unsplash.com/photo-1579783902614-a3fb3927b6a5?w=800",
                categoryId: categoryId,
                order: 0
            ),
            SubCategory(
                name: "Sculpture",
                imageURL: "https://images.unsplash.com/photo-1561839561-b13bcfe95249?w=800",
                categoryId: categoryId,
                order: 1
            ),
            SubCategory(
                name: "Photography",
                imageURL: "https://images.unsplash.com/photo-1516035069371-29a1b244cc32?w=800",
                categoryId: categoryId,
                order: 2
            ),
            SubCategory(
                name: "Digital Art",
                imageURL: "https://images.unsplash.com/photo-1563089145-599997674d42?w=800",
                categoryId: categoryId,
                order: 3
            ),
            SubCategory(
                name: "Street Art",
                imageURL: "https://images.unsplash.com/photo-1499781350541-7783f6c6a0c8?w=800",
                categoryId: categoryId,
                order: 4
            )
        ]
        
        importSubcategories(subcategories: arts, batch: batch, completion: completion)
    }
    
    // Generic import function
    private func importSubcategories(subcategories: [SubCategory], batch: WriteBatch, completion: @escaping (Bool) -> Void = { _ in }) {
        print("📱 Starting batch import of \(subcategories.count) items")
        print("📱 First item categoryId:", subcategories.first?.categoryId ?? "none")
        
        for subcategory in subcategories {
            let docRef = db.collection("subCategories").document()
            let data: [String: Any] = [
                "name": subcategory.name,
                "imageURL": subcategory.imageURL,
                "categoryId": subcategory.categoryId,
                "order": subcategory.order,
                "yayCount": 0,
                "nayCount": 0
            ]
            print("📝 Adding document with ID:", docRef.documentID)
            print("📝 Data:", data)
            batch.setData(data, forDocument: docRef)
        }
        
        batch.commit { error in
            if let error = error {
                print("❌ Error importing subcategories:", error.localizedDescription)
                print("❌ Error details:", error)
                completion(false)
            } else {
                print("✅ Successfully imported \(subcategories.count) subcategories!")
                completion(true)
            }
        }
    }
} 