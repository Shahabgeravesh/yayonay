import SwiftUI

struct SignInView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var userManager: UserManager
    @State private var email = ""
    @State private var password = ""
    @State private var showForgotPassword = false
    @State private var isAnimating = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 32) {
                    // Welcome Section
                    VStack(spacing: 8) {
                        Text("Welcome Back!")
                            .font(AppFont.bold(28))
                            .foregroundStyle(AppColor.text)
                        
                        Text("Sign in to continue")
                            .font(AppFont.regular(16))
                            .foregroundStyle(AppColor.secondaryText)
                    }
                    .padding(.top, 40)
                    
                    // Input Fields
                    VStack(spacing: 20) {
                        AuthTextField(
                            title: "Email",
                            icon: "envelope",
                            text: $email,
                            keyboardType: .emailAddress,
                            textContentType: .emailAddress
                        )
                        
                        AuthTextField(
                            title: "Password",
                            icon: "lock",
                            text: $password,
                            isSecure: true,
                            textContentType: .password
                        )
                        
                        Button("Forgot Password?") {
                            showForgotPassword = true
                        }
                        .font(AppFont.medium(14))
                        .foregroundStyle(AppColor.accent)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                    }
                    
                    // Sign In Button
                    Button(action: signIn) {
                        if userManager.isLoading {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Text("Sign In")
                                .font(AppFont.semibold(16))
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        isValid ?
                        AppColor.gradient :
                        LinearGradient(colors: [.gray.opacity(0.3)], startPoint: .leading, endPoint: .trailing)
                    )
                    .foregroundStyle(.white)
                    .cornerRadius(12)
                    .disabled(!isValid || userManager.isLoading)
                    .padding(.top, 16)
                }
                .padding(.horizontal, 24)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(AppColor.text)
                    }
                }
            }
            .alert("Reset Password", isPresented: $showForgotPassword) {
                TextField("Email", text: $email)
                    .textContentType(.emailAddress)
                    .keyboardType(.emailAddress)
                Button("Cancel", role: .cancel) { }
                Button("Reset") {
                    userManager.resetPassword(email: email)
                }
            } message: {
                Text("Enter your email to receive a password reset link.")
            }
            .alert("Error", isPresented: .constant(userManager.error != nil)) {
                Button("OK") { userManager.error = nil }
            } message: {
                if let error = userManager.error {
                    Text(error.localizedDescription)
                }
            }
        }
    }
    
    private var isValid: Bool {
        !email.isEmpty && 
        !password.isEmpty && 
        email.contains("@") &&
        password.count >= 6
    }
    
    private func signIn() {
        withAnimation {
            userManager.signIn(email: email, password: password)
        }
    }
} 