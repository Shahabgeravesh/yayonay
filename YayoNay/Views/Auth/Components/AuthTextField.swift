import SwiftUI

struct AuthTextField: View {
    let title: String
    let icon: String
    @Binding var text: String
    var isSecure: Bool = false
    var keyboardType: UIKeyboardType = .default
    var textContentType: UITextContentType?
    
    @State private var isShowingPassword = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(AppFont.medium(14))
                .foregroundStyle(AppColor.secondaryText)
            
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(AppColor.secondaryText)
                    .frame(width: 24)
                
                if isSecure && !isShowingPassword {
                    SecureField("", text: $text)
                        .textContentType(textContentType)
                } else {
                    TextField("", text: $text)
                        .textContentType(textContentType)
                        .keyboardType(keyboardType)
                }
                
                if isSecure {
                    Button(action: { isShowingPassword.toggle() }) {
                        Image(systemName: isShowingPassword ? "eye.slash.fill" : "eye.fill")
                            .foregroundStyle(AppColor.secondaryText)
                    }
                }
            }
            .padding()
            .background(AppColor.secondaryBackground)
            .cornerRadius(12)
        }
    }
} 