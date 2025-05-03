import Foundation
import FirebaseAuth

class AuthFeedbackManager {
    // MARK: - Sign In Messages
    static let signInSuccess = "Welcome back! You've successfully signed in."
    static let signInError = "Unable to sign in. Please check your credentials and try again."
    static let signInInvalidCredentials = "The email or password you entered is incorrect."
    static let signInAccountDisabled = "Your account has been disabled. Please contact support."
    static let signInTooManyAttempts = "Too many failed attempts. Please try again later or reset your password."
    
    // MARK: - Sign Up Messages
    static let signUpSuccess = "Account created successfully! Welcome to YayoNay."
    static let signUpError = "Unable to create your account. Please try again."
    static let signUpEmailInUse = "This email is already registered. Please sign in or use a different email."
    static let signUpWeakPassword = "Please choose a stronger password. It should be at least 8 characters long and include uppercase letters, numbers, and special characters."
    static let signUpInvalidEmail = "Please enter a valid email address."
    
    // MARK: - Password Reset Messages
    static let resetPasswordSuccess = "Password reset email sent! Please check your inbox."
    static let resetPasswordError = "Unable to send reset email. Please try again."
    static let resetPasswordInvalidEmail = "No account found with this email address."
    static let resetPasswordTooManyAttempts = "Too many reset attempts. Please try again later."
    
    // MARK: - Social Sign In Messages
    static let googleSignInSuccess = "Successfully signed in with Google!"
    static let googleSignInError = "Unable to sign in with Google. Please try again."
    static let appleSignInSuccess = "Successfully signed in with Apple!"
    static let appleSignInError = "Unable to sign in with Apple. Please try again."
    
    // MARK: - General Messages
    static let networkError = "Please check your internet connection and try again."
    static let unexpectedError = "An unexpected error occurred. Please try again."
    static let sessionExpired = "Your session has expired. Please sign in again."
    static let emailVerificationSent = "Verification email sent! Please check your inbox."
    static let emailVerified = "Email verified successfully!"
    
    // MARK: - Helper Methods
    static func getErrorMessage(for error: Error) -> String {
        if let authError = error as? AuthErrorCode {
            switch authError.code {
            case .invalidEmail:
                return signUpInvalidEmail
            case .emailAlreadyInUse:
                return signUpEmailInUse
            case .weakPassword:
                return signUpWeakPassword
            case .wrongPassword:
                return signInInvalidCredentials
            case .userNotFound:
                return signInInvalidCredentials
            case .userDisabled:
                return signInAccountDisabled
            case .tooManyRequests:
                return signInTooManyAttempts
            case .networkError:
                return networkError
            default:
                return unexpectedError
            }
        }
        return error.localizedDescription
    }
    
    static func getSuccessMessage(for action: AuthAction) -> String {
        switch action {
        case .signIn:
            return signInSuccess
        case .signUp:
            return signUpSuccess
        case .resetPassword:
            return resetPasswordSuccess
        case .googleSignIn:
            return googleSignInSuccess
        case .appleSignIn:
            return appleSignInSuccess
        case .emailVerification:
            return emailVerified
        }
    }
}

enum AuthAction {
    case signIn
    case signUp
    case resetPassword
    case googleSignIn
    case appleSignIn
    case emailVerification
} 