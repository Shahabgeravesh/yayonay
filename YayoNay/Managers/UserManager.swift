import SwiftUI
import FirebaseCore
import FirebaseAuth
import FirebaseStorage
import FirebaseFirestore
import GoogleSignIn
import AuthenticationServices
import CryptoKit

class UserManager: NSObject, ObservableObject {
    @Published var currentUser: UserProfile?
    @Published var isAuthenticated = false
    @Published var isLoading = false
    @Published var error: Error?
    @Published var needsOnboarding = false
    @Published var hasCompletedTutorial = false
    
    private let auth = Auth.auth()
    private let storage = Storage.storage()
    private let db = Firestore.firestore()
    private var listener: ListenerRegistration?
    
    // For Apple Sign In
    private var currentNonce: String?
    
    override init() {
        super.init()
        setupAuthStateListener()
        // Load tutorial state from UserDefaults
        hasCompletedTutorial = UserDefaults.standard.bool(forKey: "hasCompletedTutorial")
    }
    
    deinit {
        listener?.remove()
    }
    
    private func setupAuthStateListener() {
        auth.addStateDidChangeListener { [weak self] _, user in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                if let user = user {
                    // User is signed in
                    self.isAuthenticated = true
                    self.setupUserProfileListener(userId: user.uid)
                } else {
                    // User is signed out
                    self.isAuthenticated = false
                    self.currentUser = nil
                    self.needsOnboarding = false
                    // Don't reset tutorial state on sign out
                    self.listener?.remove()
                    self.listener = nil
                }
            }
        }
    }
    
    private func setupUserProfileListener(userId: String) {
        print("🎯 Setting up profile listener for user: \(userId)")
        
        // Remove any existing listener
        listener?.remove()
        
        // Set up a new real-time listener
        listener = db.collection("users").document(userId).addSnapshotListener { [weak self] snapshot, error in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                if let error = error {
                    print("❌ Profile listener error: \(error.localizedDescription)")
                    self.error = error
                    return
                }
                
                if let snapshot = snapshot, snapshot.exists {
                    print("📥 Received profile update from Firestore")
                    // User has a profile
                    self.currentUser = UserProfile(document: snapshot)
                    self.needsOnboarding = false
                    // Check if this is a new user
                    if let isNewUser = snapshot.data()?["isNewUser"] as? Bool, isNewUser {
                        self.hasCompletedTutorial = false
                        UserDefaults.standard.set(false, forKey: "hasCompletedTutorial")
                    }
                    
                    // Print debug information
                    print("Profile updated via listener:")
                    print("Votes count: \(self.currentUser?.votesCount ?? 0)")
                    print("Recent activity count: \(self.currentUser?.recentActivity.count ?? 0)")
                } else {
                    print("⚠️ No profile document found for user: \(userId)")
                    // User needs to create a profile
                    self.needsOnboarding = true
                    // New users need to see the tutorial
                    self.hasCompletedTutorial = false
                    UserDefaults.standard.set(false, forKey: "hasCompletedTutorial")
                }
            }
        }
    }
    
    // This method is now only used for initial profile creation
    private func fetchUserProfile(userId: String) {
        db.collection("users").document(userId).getDocument { [weak self] snapshot, error in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                if let error = error {
                    self.error = error
                    return
                }
                
                if let snapshot = snapshot, snapshot.exists {
                    // User has a profile
                    self.currentUser = UserProfile(document: snapshot)
                    self.needsOnboarding = false
                } else {
                    // User needs to create a profile
                    self.needsOnboarding = true
                }
            }
        }
    }
    
    // Remove or comment out signInAnonymously method since we don't want automatic sign-in
    /* 
    func signInAnonymously() {
        isLoading = true
        auth.signInAnonymously { [weak self] result, error in
            guard let self = self else { return }
            self.isLoading = false
            
            if let error = error {
                self.error = error
                return
            }
            
            if let userId = result?.user.uid {
                self.createUserProfile(userId: userId)
            }
        }
    }
    */
    
    private func uploadProfileImage(_ image: UIImage) async throws -> String {
        guard let userId = auth.currentUser?.uid else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "No user ID available"])
        }
        
        print("🔍 DEBUG: Starting profile image processing")
        print("🔍 DEBUG: User ID: \(userId)")
        
        // Resize image to reduce size
        let size = CGSize(width: 200, height: 200)
        let renderer = UIGraphicsImageRenderer(size: size)
        let resizedImage = renderer.image { context in
            image.draw(in: CGRect(origin: .zero, size: size))
        }
        
        // Convert to JPEG data with lower quality to reduce size
        guard let imageData = resizedImage.jpegData(compressionQuality: 0.3) else {
            print("❌ DEBUG: Failed to convert image to JPEG data")
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to convert image to JPEG"])
        }
        
        print("✅ DEBUG: Successfully converted image to JPEG data (\(imageData.count) bytes)")
        
        // Convert to base64 string
        let base64String = imageData.base64EncodedString()
        print("✅ DEBUG: Successfully converted image to base64 string (\(base64String.count) characters)")
        
        // Return the base64 string with a data URI prefix
        return "data:image/jpeg;base64,\(base64String)"
    }
    
    func updateProfile(username: String, image: UIImage?, interests: [String]? = nil) {
        guard let userId = auth.currentUser?.uid else {
            self.error = NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "No user ID available"])
            return
        }
        isLoading = true
        print("Starting profile update for user: \(userId)")
        Task {
            do {
                var userData: [String: Any] = [
                    "username": username,
                    "lastUpdated": Timestamp(date: Date())
                ]
                if let image = image {
                    let imageURL = try await uploadProfileImage(image)
                    userData["imageURL"] = imageURL
                }
                if let interests = interests {
                    userData["topInterests"] = interests
                }
                let docRef = db.collection("users").document(userId)
                let snapshot = try await docRef.getDocument()
                if snapshot.exists {
                    try await docRef.updateData(userData)
                } else {
                    var newUserData = userData
                    newUserData["joinDate"] = Timestamp(date: Date())
                    newUserData["votesCount"] = 0
                    newUserData["lastVoteDate"] = Timestamp(date: Date())
                    newUserData["socialLinks"] = [:] as [String: String]
                    newUserData["imageURL"] = userData["imageURL"] ?? "https://firebasestorage.googleapis.com/v0/b/yayonay-e7f58.appspot.com/o/default_profile.png?alt=media"
                    try await docRef.setData(newUserData)
                }
                await MainActor.run {
                    self.isLoading = false
                    self.needsOnboarding = false
                }
            } catch {
                await MainActor.run {
                    self.error = error
                    self.isLoading = false
                }
            }
        }
    }
    
    private func createUserProfile(userId: String) {
        let defaultProfile = UserProfile(
            id: userId,
            username: "User\(Int.random(in: 1000...9999))",
            imageURL: "https://firebasestorage.googleapis.com/v0/b/yayonay-e7f58.appspot.com/o/default_profile.png?alt=media",
            votesCount: 0,
            lastVoteDate: Date(),
            topInterests: []
        )
        
        db.collection("users").document(userId).setData(defaultProfile.dictionary) { [weak self] error in
            if let error = error {
                self?.error = error
            }
        }
    }
    
    func signOut() {
        do {
            try auth.signOut()
            // Don't reset tutorial state on sign out
        } catch {
            self.error = error
        }
    }
    
    // Additional auth methods
    func signInWithGoogle() {
        isLoading = true
        
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first,
              let rootViewController = window.rootViewController else {
            isLoading = false
            self.error = NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: AuthFeedbackManager.networkError])
            return
        }
        
        GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController) { [weak self] result, error in
            guard let self = self else { return }
            
            if let error = error {
                DispatchQueue.main.async {
                    self.error = NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: AuthFeedbackManager.googleSignInError])
                    self.isLoading = false
                }
                return
            }
            
            guard let user = result?.user,
                  let idToken = user.idToken?.tokenString else {
                DispatchQueue.main.async {
                    self.error = NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: AuthFeedbackManager.googleSignInError])
                    self.isLoading = false
                }
                return
            }
            
            let credential = GoogleAuthProvider.credential(withIDToken: idToken,
                                                         accessToken: user.accessToken.tokenString)
            
            self.signInWithCredential(credential)
        }
    }
    
    func signInWithApple(credential: ASAuthorizationAppleIDCredential, identityToken: String) {
        isLoading = true
        
        let nonce = randomNonceString()
        let oauthCredential = OAuthProvider.credential(
            withProviderID: "apple.com",
            idToken: identityToken,
            rawNonce: nonce
        )
        
        auth.signIn(with: oauthCredential) { [weak self] result, error in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                self.isLoading = false
                
                if let error = error {
                    self.error = NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: AuthFeedbackManager.appleSignInError])
                    return
                }
                
                if let userId = result?.user.uid {
                    self.createUserProfileIfNeeded(userId: userId)
                }
            }
        }
    }
    
    private func signInWithCredential(_ credential: AuthCredential) {
        Auth.auth().signIn(with: credential) { [weak self] result, error in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                self.isLoading = false
                
                if let error = error {
                    self.error = NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: AuthFeedbackManager.getErrorMessage(for: error)])
                    return
                }
                
                guard let user = result?.user else {
                    self.error = NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: AuthFeedbackManager.unexpectedError])
                    return
                }
                
                // Get username from display name or email
                var username = user.displayName ?? ""
                if username.isEmpty, let email = user.email {
                    // Use email username part if no display name
                    let emailParts = email.split(separator: "@")
                    if !emailParts.isEmpty {
                        username = String(emailParts[0])
                    }
                }
                
                // Create/Update user profile
                let userProfile = UserProfile(
                    id: user.uid,
                    username: username,
                    imageURL: "https://firebasestorage.googleapis.com/v0/b/yayonay-e7f58.appspot.com/o/default_profile.png?alt=media",
                    email: user.email,
                    votesCount: 0,
                    lastVoteDate: Date(),
                    topInterests: []
                )
                
                self.createOrUpdateUserProfile(userProfile)
                
                // If this is a new user, set needsOnboarding to true
                if result?.additionalUserInfo?.isNewUser == true {
                    self.needsOnboarding = true
                }
            }
        }
    }
    
    private func createUserProfileIfNeeded(userId: String) {
        db.collection("users").document(userId).getDocument { [weak self] snapshot, error in
            guard let self = self else { return }
            
            if let error = error {
                self.error = error
                return
            }
            
            if !snapshot!.exists {
                DispatchQueue.main.async {
                    self.needsOnboarding = true
                }
            }
        }
    }
    
    // Helper methods for Apple Sign In
    private func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        let charset: [Character] = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        var result = ""
        var remainingLength = length
        
        while remainingLength > 0 {
            let randoms: [UInt8] = (0 ..< 16).map { _ in
                var random: UInt8 = 0
                let errorCode = SecRandomCopyBytes(kSecRandomDefault, 1, &random)
                if errorCode != errSecSuccess {
                    fatalError("Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)")
                }
                return random
            }
            
            randoms.forEach { random in
                if remainingLength == 0 {
                    return
                }
                
                if random < charset.count {
                    result.append(charset[Int(random)])
                    remainingLength -= 1
                }
            }
        }
        
        return result
    }
    
    private func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashedData = SHA256.hash(data: inputData)
        let hashString = hashedData.compactMap {
            String(format: "%02x", $0)
        }.joined()
        
        return hashString
    }
    
    func signUp(email: String, password: String) {
        isLoading = true
        auth.createUser(withEmail: email, password: password) { [weak self] result, error in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                self.isLoading = false
                
                if let error = error {
                    self.error = NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: AuthFeedbackManager.getErrorMessage(for: error)])
                    return
                }
                
                // New user created - they'll need onboarding
                self.needsOnboarding = true
            }
        }
    }
    
    func signIn(email: String, password: String) {
        isLoading = true
        auth.signIn(withEmail: email, password: password) { [weak self] result, error in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                self.isLoading = false
                
                if let error = error {
                    self.error = NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: AuthFeedbackManager.getErrorMessage(for: error)])
                }
                // Auth successful - profile check handled by listener
            }
        }
    }
    
    func resetPassword(email: String) {
        isLoading = true
        auth.sendPasswordReset(withEmail: email) { [weak self] error in
            guard let self = self else { return }
            self.isLoading = false
            
            if let error = error {
                self.error = NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: AuthFeedbackManager.getErrorMessage(for: error)])
            }
        }
    }
    
    func reauthenticate(with credential: AuthCredential, completion: @escaping (Error?) -> Void) {
        guard let user = auth.currentUser else {
            completion(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "No user is currently signed in"]))
            return
        }
        
        user.reauthenticate(with: credential) { result, error in
            completion(error)
        }
    }
    
    func incrementVoteCount() {
        guard let userId = auth.currentUser?.uid else { 
            print("❌ Failed to increment vote count: No user ID available")
            return 
        }
        
        print("📝 Starting vote count increment for user: \(userId)")
        print("Current vote count: \(currentUser?.votesCount ?? 0)")
        
        // Update local state immediately
        if var user = currentUser {
            user.votesCount += 1
            user.lastVoteDate = Date()
            currentUser = user
            print("✅ Updated local vote count to: \(user.votesCount)")
        } else {
            print("⚠️ No current user found for local update")
        }
        
        let docRef = db.collection("users").document(userId)
        print("🔄 Updating Firestore document: users/\(userId)")
        
        docRef.updateData([
            "votesCount": FieldValue.increment(Int64(1)),
            "lastVoteDate": Timestamp(date: Date())
        ]) { [weak self] error in
            if let error = error {
                print("❌ Error updating vote count in Firestore: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    self?.error = error
                    // Revert local state if Firestore update fails
                    if var user = self?.currentUser {
                        user.votesCount -= 1
                        self?.currentUser = user
                        print("↩️ Reverted local vote count to: \(user.votesCount)")
                    }
                }
            } else {
                print("✅ Successfully updated vote count in Firestore")
            }
        }
    }
    
    func addRecentActivity(type: String, itemId: String) {
        guard let userId = auth.currentUser?.uid else { return }
        
        // Get the topic details to include in the activity
        db.collection("topics").document(itemId).getDocument { [weak self] snapshot, error in
            guard let self = self else { return }
            
            if let error = error {
                print("Error fetching topic for activity: \(error.localizedDescription)")
                return
            }
            
            guard let data = snapshot?.data(),
                  let title = data["title"] as? String else {
                return
            }
            
            // Create a more detailed activity object
            let activity = [
                "type": type,
                "itemId": itemId,
                "title": title,
                "timestamp": Timestamp(date: Date())
            ] as [String: Any]
            
            let docRef = db.collection("users").document(userId)
            
            // First check if the document exists
            docRef.getDocument { [weak self] snapshot, error in
                guard let self = self else { return }
                
                if let error = error {
                    print("Error checking user document: \(error.localizedDescription)")
                    return
                }
                
                if snapshot?.exists == true {
                    // Update existing document
                    docRef.updateData([
                        "recentActivity": FieldValue.arrayUnion([activity])
                    ]) { error in
                        if let error = error {
                            print("Error updating recent activity: \(error.localizedDescription)")
                            DispatchQueue.main.async {
                                self.error = error
                            }
                        }
                    }
                } else {
                    // Create new document with initial activity
                    let userData: [String: Any] = [
                        "recentActivity": [activity],
                        "votesCount": 1,
                        "lastVoteDate": Timestamp(date: Date())
                    ]
                    
                    docRef.setData(userData) { error in
                        if let error = error {
                            print("Error creating user document: \(error.localizedDescription)")
                            DispatchQueue.main.async {
                                self.error = error
                            }
                        }
                    }
                }
            }
        }
    }
    
    private func createOrUpdateUserProfile(_ profile: UserProfile) {
        let docRef = db.collection("users").document(profile.id)
        
        docRef.setData(profile.dictionary, merge: true) { [weak self] error in
            if let error = error {
                DispatchQueue.main.async {
                    self?.error = error
                }
                return
            }
            
            // After successful profile creation/update
            DispatchQueue.main.async {
                // The real-time listener will update the currentUser
                self?.isAuthenticated = true
            }
        }
    }
    
    func completeTutorial() {
        hasCompletedTutorial = true
        UserDefaults.standard.set(true, forKey: "hasCompletedTutorial")
        
        // Update Firestore to mark user as not new
        if let userId = auth.currentUser?.uid {
            db.collection("users").document(userId).updateData([
                "isNewUser": false
            ])
        }
    }
    
    // Add new public method to check if user is new
    func checkIfUserIsNew(userId: String, completion: @escaping (Bool) -> Void) {
        db.collection("users").document(userId).getDocument { snapshot, error in
            if let error = error {
                print("Error checking if user is new: \(error.localizedDescription)")
                completion(false)
                return
            }
            
            if let snapshot = snapshot, !snapshot.exists {
                // This is a new user
                self.hasCompletedTutorial = false
                UserDefaults.standard.set(false, forKey: "hasCompletedTutorial")
                completion(true)
            } else {
                completion(false)
            }
        }
    }
    
    // MARK: - Notification Preferences
    func fetchNotificationPreferences() async -> (general: Bool, votes: Bool, reminders: Bool)? {
        guard let userId = auth.currentUser?.uid else { return nil }
        do {
            let doc = try await db.collection("users").document(userId).getDocument()
            let data = doc.data() ?? [:]
            let general = data["notificationsGeneral"] as? Bool ?? true
            let votes = data["notificationsVotes"] as? Bool ?? true
            let reminders = data["notificationsReminders"] as? Bool ?? true
            return (general, votes, reminders)
        } catch {
            print("Error fetching notification preferences: \(error)")
            return nil
        }
    }

    func updateNotificationPreferences(general: Bool, votes: Bool, reminders: Bool) async {
        guard let userId = auth.currentUser?.uid else { return }
        do {
            try await db.collection("users").document(userId).updateData([
                "notificationsGeneral": general,
                "notificationsVotes": votes,
                "notificationsReminders": reminders
            ])
        } catch {
            print("Error updating notification preferences: \(error)")
        }
    }
}

// MARK: - ASAuthorizationControllerDelegate
extension UserManager: ASAuthorizationControllerDelegate {
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential,
              let nonce = currentNonce,
              let appleIDToken = appleIDCredential.identityToken,
              let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
            return
        }
        
        let credential = OAuthProvider.credential(withProviderID: "apple.com",
                                                idToken: idTokenString,
                                                rawNonce: nonce)
        
        signInWithCredential(credential)
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        self.error = error
    }
}

// MARK: - ASAuthorizationControllerPresentationContextProviding
extension UserManager: ASAuthorizationControllerPresentationContextProviding {
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else {
            fatalError("No window found")
        }
        return window
    }
} 