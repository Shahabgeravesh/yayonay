import SwiftUI
import Firebase
import FirebaseAuth

struct RootView: View {
    @EnvironmentObject var userManager: UserManager
    
    var body: some View {
        Group {
            if userManager.isAuthenticated {
                if !userManager.hasCompletedTutorial {
                    TutorialView()
                } else if userManager.needsOnboarding {
                    OnboardingView()
                } else {
                    MainTabView()
                }
            } else {
                AuthView()
            }
        }
        .onAppear {
            // Check if this is a new user
            if let userId = Auth.auth().currentUser?.uid {
                userManager.checkIfUserIsNew(userId: userId) { isNew in
                    if isNew {
                        print("New user detected, showing tutorial")
                    }
                }
            }
        }
    }
} 