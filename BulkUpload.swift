import FirebaseFirestore
import FirebaseCore

// Only run this once to set up your subcategories!
func uploadSubCategories() {
    let db = Firestore.firestore()
    let batch = db.batch()
    
    // Replace this with your actual category ID from Firestore
    let fruitCategoryId = "your_fruit_category_id"
    
    // Array of subcategories to add
    let subcategories: [[String: Any]] = [
        [
            "name": "Orange",
            "imageURL": "https://images.unsplash.com/photo-1557800636-894a64c1696f?w=800",
            "categoryId": fruitCategoryId,
            "order": 0,
            "yayCount": 0,
            "nayCount": 0
        ],
        [
            "name": "Apple",
            "imageURL": "https://images.unsplash.com/photo-1560806887-1e4cd0b6cbd6?w=800",
            "categoryId": fruitCategoryId,
            "order": 1,
            "yayCount": 0,
            "nayCount": 0
        ],
        [
            "name": "Banana",
            "imageURL": "https://images.unsplash.com/photo-1571771894821-ce9b6c11b08e?w=800",
            "categoryId": fruitCategoryId,
            "order": 2,
            "yayCount": 0,
            "nayCount": 0
        ],
        [
            "name": "Strawberry",
            "imageURL": "https://images.unsplash.com/photo-1464965911861-746a04b4bca6?w=800",
            "categoryId": fruitCategoryId,
            "order": 3,
            "yayCount": 0,
            "nayCount": 0
        ],
        [
            "name": "Mango",
            "imageURL": "https://images.unsplash.com/photo-1553279768-865429fa0078?w=800",
            "categoryId": fruitCategoryId,
            "order": 4,
            "yayCount": 0,
            "nayCount": 0
        ]
    ]
    
    // Add each subcategory to the batch
    for subcategory in subcategories {
        let docRef = db.collection("subCategories").document()
        batch.setData(subcategory, forDocument: docRef)
    }
    
    // Commit the batch
    batch.commit { error in
        if let error = error {
            print("❌ Error adding subcategories: \(error.localizedDescription)")
        } else {
            print("✅ Successfully added \(subcategories.count) subcategories!")
        }
    }
} 