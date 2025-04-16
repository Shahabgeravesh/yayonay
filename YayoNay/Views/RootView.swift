import SwiftUI

struct RootView: View {
    @EnvironmentObject var userManager: UserManager
    
    var body: some View {
        Group {
            if userManager.isAuthenticated {
                if userManager.needsOnboarding {
                    OnboardingView()
                } else {
                    MainTabView()
                }
            } else {
                AuthView()
            }
        }
    }
} 