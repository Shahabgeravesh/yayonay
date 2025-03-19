import SwiftUI

struct RootView: View {
    @StateObject private var userManager = UserManager()
    
    var body: some View {
        Group {
            if userManager.isAuthenticated {
                if userManager.needsOnboarding {
                    OnboardingView(userManager: userManager)
                } else {
                    MainTabView()
                        .environmentObject(userManager)
                }
            } else {
                AuthView()
                    .environmentObject(userManager)
            }
        }
    }
} 