import SwiftUI
import FirebaseFirestore
import FirebaseAuth
import Foundation

// MARK: - Main Class
class ProfileViewModel: ObservableObject {
    @Published var profile: UserProfile
    @Published var showInterestsSheet = false
    @Published var selectedInterests: Set<String> = []
    @Published var isLoading = false
    @Published var error: Error?
    
    private let db = Firestore.firestore()
    private var listener: ListenerRegistration?
    private let userManager: UserManager
    
    let availableInterests = [
        "Food", "Drinks", "Sports", "Travel", "Art", 
        "Music", "Movies", "Books", "Technology", "Fashion"
    ]
    
    init(userManager: UserManager) {
        self.userManager = userManager
        self.profile = UserProfile(
            id: UUID().uuidString,
            username: "",
            imageURL: "",
            email: nil,
            votesCount: 0,
            lastVoteDate: Date(),
            topInterests: []
        )
        setupProfileListener()
    }
    
    deinit {
        listener?.remove()
    }
    
    private func setupProfileListener() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        listener = db.collection("users").document(userId)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }
                
                if let error = error {
                    self.error = error
                    return
                }
                
                if let snapshot = snapshot,
                   let profile = UserProfile(document: snapshot) {
                    DispatchQueue.main.async {
                        self.profile = profile
                        self.selectedInterests = Set(profile.topInterests)
                    }
                }
            }
    }
    
    func updateProfile(username: String, image: UIImage?, interests: [String]) {
        isLoading = true
        
        userManager.updateProfile(
            username: username,
            image: image,
            interests: Array(selectedInterests)
        )
    }
    
    func toggleInterest(_ interest: String) {
        if selectedInterests.contains(interest) {
            selectedInterests.remove(interest)
        } else {
            selectedInterests.insert(interest)
        }
    }
    
    // MARK: - Interest Management
    func updateInterests() {
        // Update interests directly since profile is non-optional
        profile.topInterests = Array(selectedInterests)
        
        db.collection("users").document(profile.id).updateData([
            "topInterests": profile.topInterests
        ]) { error in
            if let error = error {
                print("Error updating interests: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - Sign Out
    func signOut() {
        do {
            try Auth.auth().signOut()
            // Reset local state
            profile = UserProfile(
                id: UUID().uuidString,
                username: "",
                imageURL: "",
                email: nil,
                votesCount: 0,
                lastVoteDate: Date(),
                topInterests: []
            )
            selectedInterests = []
            // Restart authentication flow
            setupProfileListener()
        } catch {
            print("Error signing out: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Share Profile
    func shareProfile() -> String {
        return "Check out my profile on YayoNay! @\(profile.username)"
    }
    
    func updateImage(_ image: UIImage) {
        guard let imageData = image.jpegData(compressionQuality: 0.7)?.base64EncodedString() else {
            error = NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to encode image"])
            return
        }
        
        profile.imageURL = imageData
    }
    
    private func createDefaultProfile() -> UserProfile {
        return UserProfile(
            id: UUID().uuidString,
            username: "User\(Int.random(in: 1000...9999))",
            imageURL: "https://firebasestorage.googleapis.com/v0/b/yayonay-e7f58.appspot.com/o/default_profile.png?alt=media",
            email: nil,
            votesCount: 0,
            lastVoteDate: Date(),
            topInterests: []
        )
    }

    private func createProfileFromUser(_ user: User) -> UserProfile {
        // Get username from display name or email
        var username = user.displayName ?? ""
        if username.isEmpty, let email = user.email {
            // Use email username part if no display name
            let emailParts = email.split(separator: "@")
            if !emailParts.isEmpty {
                username = String(emailParts[0])
            }
        }
        
        return UserProfile(
            id: user.uid,
            username: username,
            imageURL: "https://firebasestorage.googleapis.com/v0/b/yayonay-e7f58.appspot.com/o/default_profile.png?alt=media",
            email: user.email,
            votesCount: 0,
            lastVoteDate: Date(),
            topInterests: []
        )
    }

    private func updateLocalProfile(_ profile: UserProfile) {
        self.profile = profile
        self.selectedInterests = Set(profile.topInterests)
    }
}

// Rest of the implementation...