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
    
    private let auth = Auth.auth()
    private let storage = Storage.storage()
    private let db = Firestore.firestore()
    private var listener: ListenerRegistration?
    
    // For Apple Sign In
    private var currentNonce: String?
    
    override init() {
        super.init()
        setupAuthStateListener()
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
                    self.fetchUserProfile(userId: user.uid)
                } else {
                    // User is signed out
                    self.isAuthenticated = false
                    self.currentUser = nil
                    self.needsOnboarding = false
                }
            }
        }
    }
    
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
    
    func updateProfile(username: String, image: UIImage?, bio: String? = nil, interests: [String]? = nil) {
        guard let userId = auth.currentUser?.uid else {
            self.error = NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "No user ID available"])
            return
        }
        
        isLoading = true
        print("Starting profile update for user: \(userId)")
        
        var imageData: String? = nil
        if let image = image {
            // Resize image to reduce size
            let size = CGSize(width: 200, height: 200)
            let renderer = UIGraphicsImageRenderer(size: size)
            let resizedImage = renderer.image { context in
                image.draw(in: CGRect(origin: .zero, size: size))
            }
            
            // Convert to base64
            if let jpegData = resizedImage.jpegData(compressionQuality: 0.5) {
                imageData = jpegData.base64EncodedString()
            }
        }
        
        updateUserData(
            userId: userId,
            username: username,
            imageData: imageData,
            bio: bio,
            interests: interests
        )
    }
    
    private func updateUserData(userId: String, username: String, imageData: String?, bio: String?, interests: [String]?) {
        var userData: [String: Any] = [
            "username": username,
            "lastUpdated": Timestamp(date: Date()),
            "joinDate": Timestamp(date: Date()),
            "votesCount": 0,
            "lastVoteDate": Timestamp(date: Date()),
            "socialLinks": [:] as [String: String]
        ]
        
        if let imageData = imageData {
            userData["imageData"] = imageData
        }
        if let bio = bio {
            userData["bio"] = bio
        }
        if let interests = interests {
            userData["topInterests"] = interests
        }
        
        let docRef = db.collection("users").document(userId)
        
        // First check if document exists
        docRef.getDocument { [weak self] snapshot, error in
            guard let self = self else { return }
            
            if let error = error {
                DispatchQueue.main.async {
                    self.error = error
                    self.isLoading = false
                }
                return
            }
            
            if snapshot?.exists == true {
                // Update existing document
                docRef.updateData(userData) { [weak self] error in
                    DispatchQueue.main.async {
                        self?.isLoading = false
                        if let error = error {
                            self?.error = error
                        } else {
                            self?.fetchUserProfile(userId: userId)
                        }
                    }
                }
            } else {
                // Create new document
                docRef.setData(userData) { [weak self] error in
                    DispatchQueue.main.async {
                        self?.isLoading = false
                        if let error = error {
                            self?.error = error
                        } else {
                            self?.fetchUserProfile(userId: userId)
                            self?.needsOnboarding = false
                        }
                    }
                }
            }
        }
    }
    
    private func createUserProfile(userId: String) {
        let defaultProfile = UserProfile(
            id: userId,
            username: "User\(Int.random(in: 1000...9999))",
            imageData: nil,
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
            return
        }
        
        GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController) { [weak self] result, error in
            guard let self = self else { return }
            
            if let error = error {
                DispatchQueue.main.async {
                    self.error = error
                    self.isLoading = false
                }
                return
            }
            
            guard let user = result?.user,
                  let idToken = user.idToken?.tokenString else {
                DispatchQueue.main.async {
                    self.error = NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to get ID token"])
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
                    self.error = error
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
                    self.error = error
                    return
                }
                
                guard let user = result?.user else {
                    self.error = NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to get user"])
                    return
                }
                
                // Create/Update user profile
                let userProfile = UserProfile(
                    id: user.uid,
                    username: user.displayName ?? "",
                    imageData: nil,  // This needs to come before email
                    email: user.email,
                    bio: "",
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
                    self.error = error
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
                    self.error = error
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
                self.error = error
            }
        }
    }
    
    func incrementVoteCount() {
        guard let userId = auth.currentUser?.uid else { return }
        
        let docRef = db.collection("users").document(userId)
        docRef.updateData([
            "votesCount": FieldValue.increment(Int64(1)),
            "lastVoteDate": Timestamp(date: Date())
        ]) { [weak self] error in
            if let error = error {
                print("Error updating vote count: \(error.localizedDescription)")
            } else {
                self?.fetchUserProfile(userId: userId)
            }
        }
    }
    
    func addRecentActivity(type: String, itemId: String) {
        guard let userId = auth.currentUser?.uid else { return }
        
        let activity = [
            "type": type,
            "itemId": itemId,
            "timestamp": Timestamp(date: Date())
        ] as [String: Any]
        
        let docRef = db.collection("users").document(userId)
        docRef.updateData([
            "recentActivity": FieldValue.arrayUnion([activity])
        ]) { [weak self] error in
            if let error = error {
                print("Error updating recent activity: \(error.localizedDescription)")
            } else {
                self?.fetchUserProfile(userId: userId)
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
                self?.currentUser = profile
                self?.isAuthenticated = true
            }
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