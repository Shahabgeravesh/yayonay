import SwiftUI
import AuthenticationServices

struct AuthView: View {
    @EnvironmentObject var userManager: UserManager
    @Environment(\.colorScheme) private var colorScheme
    @State private var showSignUp = false
    @State private var showSignIn = false
    @State private var showDatabaseCleanup = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background gradient
                LinearGradient(
                    colors: [
                        AppColor.accent.opacity(0.1),
                        AppColor.background
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 32) {
                        // Logo and Welcome Text
                        VStack(spacing: 24) {
                            // App Logo
                            ZStack {
                                Circle()
                                    .fill(AppColor.accent.opacity(0.1))
                                    .frame(width: 120, height: 120)
                                
                                Circle()
                                    .fill(AppColor.accent.opacity(0.2))
                                    .frame(width: 100, height: 100)
                                
                                // Yay and Nay icons
                                VStack(spacing: 8) {
                                    // Thumbs Up
                                    Image(systemName: "hand.thumbsup.fill")
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(width: 30, height: 30)
                                        .foregroundStyle(AppColor.accent)
                                        .symbolEffect(.bounce, options: .repeating)
                                    
                                    // Thumbs Down
                                    Image(systemName: "hand.thumbsdown.fill")
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(width: 30, height: 30)
                                        .foregroundStyle(.red)
                                        .symbolEffect(.bounce, options: .repeating)
                                }
                            }
                            
                            VStack(spacing: 8) {
                                Text("Welcome to YayoNay")
                                    .font(.system(size: 28, weight: .bold))
                                    .foregroundStyle(AppColor.text)
                                
                                Text("Vote and share your opinions on anything and everything!")
                                    .font(.system(size: 16))
                                    .foregroundStyle(AppColor.secondaryText)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal)
                            }
                        }
                        .padding(.top, 40)
                        
                        // Auth Buttons
                        VStack(spacing: 20) {
                            // Social Sign In
                            VStack(spacing: 12) {
                                GoogleSignInButton(action: { userManager.signInWithGoogle() })
                                
                                SignInWithAppleButton { request in
                                    request.requestedScopes = [.fullName, .email]
                                } onCompletion: { result in
                                    switch result {
                                    case .success(let authorization):
                                        if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential,
                                           let identityToken = appleIDCredential.identityToken,
                                           let tokenString = String(data: identityToken, encoding: .utf8) {
                                            userManager.signInWithApple(credential: appleIDCredential, identityToken: tokenString)
                                        }
                                    case .failure(let error):
                                        userManager.error = error
                                    }
                                }
                                .frame(height: 45)
                            }
                            
                            // Divider
                            HStack {
                                Color(.separator).frame(height: 1)
                                Text("or")
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                                Color(.separator).frame(height: 1)
                            }
                            .padding(.vertical, 8)
                            
                            // Email Sign Up/In Buttons
                            VStack(spacing: 12) {
                                Button(action: { showSignUp = true }) {
                                    Text("Create Account")
                                        .font(.system(size: 16, weight: .semibold))
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 12)
                                        .background(AppColor.accent)
                                        .foregroundColor(.white)
                                        .cornerRadius(12)
                                }
                                
                                Button(action: { showSignIn = true }) {
                                    Text("Sign In")
                                        .font(.system(size: 16, weight: .semibold))
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 12)
                                        .background(Color(.systemBackground))
                                        .foregroundColor(.primary)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(Color(.separator), lineWidth: 1)
                                        )
                                }
                            }
                        }
                        .padding(.horizontal)
                        
                        // Terms and Privacy
                        VStack(spacing: 8) {
                            Text("By continuing, you agree to our")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            
                            HStack(spacing: 4) {
                                Link("Terms of Service", destination: URL(string: "https://your-terms-url.com")!)
                                    .font(.caption)
                                    .tint(AppColor.accent)
                                
                                Text("and")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                
                                Link("Privacy Policy", destination: URL(string: "https://your-privacy-url.com")!)
                                    .font(.caption)
                                    .tint(AppColor.accent)
                            }
                        }
                        
                        // Developer Tools (only visible in DEBUG)
                        #if DEBUG
                        Button(action: { showDatabaseCleanup = true }) {
                            Text("Database Cleanup")
                                .font(.caption)
                                .foregroundColor(.red)
                                .padding(.top, 8)
                        }
                        #endif
                    }
                    .padding(.vertical, 40)
                }
            }
            .sheet(isPresented: $showSignUp) {
                SignUpView(userManager: userManager)
            }
            .sheet(isPresented: $showSignIn) {
                SignInView(userManager: userManager)
            }
            .sheet(isPresented: $showDatabaseCleanup) {
                DatabaseCleanupView()
            }
            .overlay {
                if userManager.isLoading {
                    ProgressView()
                        .scaleEffect(1.5)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.black.opacity(0.2))
                }
            }
        }
    }
} 
