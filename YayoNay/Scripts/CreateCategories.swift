import Foundation
import FirebaseFirestore
import FirebaseCore

// Function to create categories in Firestore
func createCategories() {
    // Initialize Firebase
    let options = FirebaseOptions(
        googleAppID: "1:1234567890:ios:abcdef1234567890", // Replace with your actual App ID
        gcmSenderID: "1234567890" // Replace with your actual Sender ID
    )
    options.apiKey = "YOUR_API_KEY" // Replace with your actual API Key
    options.projectID = "yayonay-e7f58" // Replace with your actual Project ID
    options.storageBucket = "yayonay-e7f58.appspot.com" // Replace with your actual Storage Bucket
    FirebaseApp.configure(options: options)

    // Get Firestore instance
    let db = Firestore.firestore()

    // Define categories
    let categories = [
        [
            "name": "Food",
            "description": "Discover delicious dishes",
            "isTopCategory": true,
            "order": 1,
            "featured": true,
            "votesCount": 0
        ],
        [
            "name": "Drinks",
            "description": "Refreshing beverages",
            "isTopCategory": true,
            "order": 2,
            "featured": true,
            "votesCount": 0
        ],
        [
            "name": "Dessert",
            "description": "Sweet treats and delights",
            "isTopCategory": true,
            "order": 3,
            "featured": true,
            "votesCount": 0
        ],
        [
            "name": "Sports",
            "description": "Game on!",
            "isTopCategory": true,
            "order": 4,
            "featured": true,
            "votesCount": 0
        ],
        [
            "name": "Travel",
            "description": "Explore destinations",
            "isTopCategory": true,
            "order": 5,
            "featured": true,
            "votesCount": 0
        ],
        [
            "name": "Art",
            "description": "Creative expressions",
            "isTopCategory": true,
            "order": 6,
            "featured": true,
            "votesCount": 0
        ],
        [
            "name": "Music",
            "description": "Rhythm and melodies",
            "isTopCategory": true,
            "order": 7,
            "featured": true,
            "votesCount": 0
        ],
        [
            "name": "Movies",
            "description": "Cinematic experiences",
            "isTopCategory": true,
            "order": 8,
            "featured": true,
            "votesCount": 0
        ],
        [
            "name": "Books",
            "description": "Literary adventures",
            "isTopCategory": true,
            "order": 9,
            "featured": true,
            "votesCount": 0
        ],
        [
            "name": "Technology",
            "description": "Innovation and gadgets",
            "isTopCategory": true,
            "order": 10,
            "featured": true,
            "votesCount": 0
        ]
    ]

    // Add categories to Firestore
    print("Adding categories to Firestore...")

    for category in categories {
        db.collection("categories").addDocument(data: category) { error in
            if let error = error {
                print("Error adding category \(category["name"] ?? "unknown"): \(error.localizedDescription)")
            } else {
                print("Successfully added category: \(category["name"] ?? "unknown")")
            }
        }
    }

    // Keep the script running until all operations complete
    RunLoop.main.run(until: Date(timeIntervalSinceNow: 5))
}

// Call the function
createCategories() 