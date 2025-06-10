import SwiftUI

struct GoogleSignInButton: View {
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                // Google Logo
                Image(systemName: "g.circle.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 18, height: 18)
                    .foregroundColor(.blue)
                
                Text("Sign in with Google")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.black)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(Color.white)
            .cornerRadius(4)
            .overlay(
                RoundedRectangle(cornerRadius: 4)
                    .stroke(Color(.systemGray4), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.05), radius: 1, y: 1)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    GoogleSignInButton(action: {})
        .padding()
} 