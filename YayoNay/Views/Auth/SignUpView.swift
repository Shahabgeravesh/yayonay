// MARK: - Sign Up View
// This view handles new user registration, including:
// 1. User information collection
// 2. Account creation
// 3. Profile setup
// 4. Initial preferences selection

import SwiftUI

struct SignUpView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var userManager: UserManager
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var agreedToTerms = false
    @State private var showSuccessAlert = false
    @State private var successMessage = ""
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 32) {
                    // Welcome Section
                    VStack(spacing: 8) {
                        Text("Create Account")
                            .font(AppFont.bold(28))
                            .foregroundStyle(AppColor.text)
                        
                        Text("Sign up to get started")
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
                            textContentType: .newPassword
                        )
                        
                        AuthTextField(
                            title: "Confirm Password",
                            icon: "lock",
                            text: $confirmPassword,
                            isSecure: true,
                            textContentType: .newPassword
                        )
                        
                        // Password Requirements
                        if !password.isEmpty {
                            PasswordRequirements(password: password)
                                .padding(.top, 8)
                        }
                    }
                    
                    // Terms and Conditions
                    Toggle(isOn: $agreedToTerms) {
                        Text("I agree to the ")
                            .font(AppFont.regular(14)) +
                        Text("Terms of Service")
                            .font(AppFont.medium(14))
                            .foregroundStyle(AppColor.accent) +
                        Text(" and ")
                            .font(AppFont.regular(14)) +
                        Text("Privacy Policy")
                            .font(AppFont.medium(14))
                            .foregroundStyle(AppColor.accent)
                    }
                    .tint(AppColor.accent)
                    
                    // Sign Up Button
                    Button(action: signUp) {
                        if userManager.isLoading {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Text("Create Account")
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
            .alert("Success", isPresented: $showSuccessAlert) {
                Button("OK") { dismiss() }
            } message: {
                Text(successMessage)
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
        password == confirmPassword &&
        password.count >= 8 &&
        email.contains("@") &&
        agreedToTerms &&
        hasValidPassword
    }
    
    private var hasValidPassword: Bool {
        let hasUppercase = password.contains { $0.isUppercase }
        let hasNumber = password.contains { $0.isNumber }
        let hasSpecialChar = password.contains { "!@#$%^&*(),.?\":{}|<>".contains($0) }
        return hasUppercase && hasNumber && hasSpecialChar
    }
    
    private func signUp() {
        withAnimation {
            userManager.signUp(email: email, password: password)
            // The success will be handled by the auth state listener in UserManager
            // which will automatically update the UI
        }
    }
}

struct PasswordRequirements: View {
    let password: String
    
    private var hasUppercase: Bool {
        password.contains { $0.isUppercase }
    }
    
    private var hasNumber: Bool {
        password.contains { $0.isNumber }
    }
    
    private var hasSpecialChar: Bool {
        password.contains { "!@#$%^&*(),.?\":{}|<>".contains($0) }
    }
    
    private var hasMinLength: Bool {
        password.count >= 8
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Password Requirements:")
                .font(AppFont.medium(14))
                .foregroundStyle(AppColor.secondaryText)
            
            RequirementRow(text: "At least 8 characters", isMet: hasMinLength)
            RequirementRow(text: "Contains uppercase letter", isMet: hasUppercase)
            RequirementRow(text: "Contains number", isMet: hasNumber)
            RequirementRow(text: "Contains special character", isMet: hasSpecialChar)
        }
    }
}

struct RequirementRow: View {
    let text: String
    let isMet: Bool
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: isMet ? "checkmark.circle.fill" : "circle")
                .foregroundStyle(isMet ? .green : AppColor.secondaryText)
            
            Text(text)
                .font(AppFont.regular(14))
                .foregroundStyle(isMet ? AppColor.text : AppColor.secondaryText)
        }
    }
} 