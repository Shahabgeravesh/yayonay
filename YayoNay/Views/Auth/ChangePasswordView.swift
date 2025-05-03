import SwiftUI
import FirebaseAuth

struct ChangePasswordView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var userManager: UserManager
    @State private var currentPassword = ""
    @State private var newPassword = ""
    @State private var confirmPassword = ""
    @State private var showSuccessAlert = false
    @State private var showErrorAlert = false
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Current Password
                    AuthTextField(
                        title: "Current Password",
                        icon: "lock",
                        text: $currentPassword,
                        isSecure: true,
                        textContentType: .password
                    )
                    
                    // New Password
                    AuthTextField(
                        title: "New Password",
                        icon: "lock",
                        text: $newPassword,
                        isSecure: true,
                        textContentType: .newPassword
                    )
                    
                    // Confirm Password
                    AuthTextField(
                        title: "Confirm New Password",
                        icon: "lock",
                        text: $confirmPassword,
                        isSecure: true,
                        textContentType: .newPassword
                    )
                    
                    // Password Requirements
                    if !newPassword.isEmpty {
                        PasswordRequirements(password: newPassword)
                            .padding(.top, 8)
                    }
                    
                    // Change Password Button
                    Button(action: changePassword) {
                        if userManager.isLoading {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Text("Change Password")
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
                .padding()
            }
            .navigationTitle("Change Password")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .alert("Success", isPresented: $showSuccessAlert) {
                Button("OK") { dismiss() }
            } message: {
                Text("Your password has been changed successfully.")
            }
            .alert("Error", isPresented: $showErrorAlert) {
                Button("OK") { }
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    private var isValid: Bool {
        !currentPassword.isEmpty &&
        !newPassword.isEmpty &&
        newPassword == confirmPassword &&
        newPassword.count >= 8 &&
        hasValidPassword
    }
    
    private var hasValidPassword: Bool {
        let hasUppercase = newPassword.contains { $0.isUppercase }
        let hasNumber = newPassword.contains { $0.isNumber }
        let hasSpecialChar = newPassword.contains { "!@#$%^&*(),.?\":{}|<>".contains($0) }
        return hasUppercase && hasNumber && hasSpecialChar
    }
    
    private func changePassword() {
        // First verify current password
        let credential = EmailAuthProvider.credential(
            withEmail: userManager.currentUser?.email ?? "",
            password: currentPassword
        )
        
        userManager.reauthenticate(with: credential) { error in
            if let error = error {
                errorMessage = AuthFeedbackManager.getErrorMessage(for: error)
                showErrorAlert = true
                return
            }
            
            // If reauthentication successful, update password
            Auth.auth().currentUser?.updatePassword(to: newPassword) { error in
                if let error = error {
                    errorMessage = AuthFeedbackManager.getErrorMessage(for: error)
                    showErrorAlert = true
                } else {
                    showSuccessAlert = true
                }
            }
        }
    }
} 