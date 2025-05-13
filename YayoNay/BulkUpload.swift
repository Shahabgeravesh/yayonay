import Foundation
import FirebaseFirestore

struct BulkUploader {
    let db = Firestore.firestore()
    
    func uploadSubcategory(to categoryId: String, subcategoryData: [String: Any], completion: ((Error?) -> Void)? = nil) {
        let docRef = db.collection("categories").document(categoryId).collection("subcategories").document()
        docRef.setData(subcategoryData) { error in
            if let error = error {
                print("Error uploading subcategory: \(error)")
            } else {
                print("Successfully uploaded subcategory to category \(categoryId)")
            }
            completion?(error)
        }
    }
}

// Example usage:
// let uploader = BulkUploader()
// let subcategory: [String: Any] = [
//     "name": "Example Subcategory",
//     "imageURL": "https://example.com/image.png",
//     "order": 1,
//     "yayCount": 0,
//     "nayCount": 0,
//     "attributes": [:]
// ]
// uploader.uploadSubcategory(to: "YOUR_CATEGORY_ID", subcategoryData: subcategory) 