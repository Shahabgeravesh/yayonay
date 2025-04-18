import SwiftUI
import FirebaseAuth
import GoogleSignIn
import FirebaseFirestore
import FirebaseCore

class AuthViewModel: ObservableObject {
    @Published var user: User?
    @Published var isAuthenticated = false
    @Published var errorMessage: String?
    
    private let db = Firestore.firestore()
    
    init() {
        setupAuthStateListener()
    }
    
    private func setupAuthStateListener() {
        Auth.auth().addStateDidChangeListener { [weak self] _, user in
            self?.user = user
            self?.isAuthenticated = user != nil
        }
    }
    
    func signInWithGoogle() {
        guard let clientID = FirebaseApp.app()?.options.clientID else { return }
        
        let config = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.configuration = config
        
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first,
              let rootViewController = window.rootViewController else {
            return
        }
        
        GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController) { [weak self] result, error in
            if let error = error {
                self?.errorMessage = error.localizedDescription
                return
            }
            
            guard let user = result?.user,
                  let idToken = user.idToken?.tokenString else {
                return
            }
            
            let credential = GoogleAuthProvider.credential(withIDToken: idToken,
                                                         accessToken: user.accessToken.tokenString)
            
            Auth.auth().signIn(with: credential) { [weak self] result, error in
                if let error = error {
                    self?.errorMessage = error.localizedDescription
                    return
                }
                
                // Save user data to Firestore
                if let firebaseUser = result?.user {
                    self?.saveUserToFirestore(firebaseUser)
                }
            }
        }
    }
    
    private func saveUserToFirestore(_ user: FirebaseAuth.User) {
        let userData: [String: Any] = [
            "id": user.uid,
            "email": user.email ?? "",
            "displayName": user.displayName ?? "",
            "photoURL": user.photoURL?.absoluteString ?? "",
            "lastLogin": Date()
        ]
        
        db.collection("users").document(user.uid).setData(userData, merge: true) { error in
            if let error = error {
                print("Error saving user data: \(error.localizedDescription)")
            }
        }
    }
    
    func signOut() {
        do {
            try Auth.auth().signOut()
            GIDSignIn.sharedInstance.signOut()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
} 