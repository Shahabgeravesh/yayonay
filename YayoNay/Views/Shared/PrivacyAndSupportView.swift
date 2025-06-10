import SwiftUI

struct PrivacyAndSupportView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 32) {
                // Privacy Policy Section
                Section(header: Text("Privacy Policy")
                    .font(.title2)
                    .fontWeight(.bold)
                    .padding(.bottom, 4)) {
                    Text("Your privacy is important to us. We do not share your personal information with third parties. All data is securely stored and only used to improve your experience on YayoNay. For more details, please review our full privacy policy on our website.")
                        .font(.body)
                        .foregroundColor(.secondary)
                }
                Divider()
                // Support Section
                Section(header: Text("Support & Contact")
                    .font(.title2)
                    .fontWeight(.bold)
                    .padding(.bottom, 4)) {
                    Text("If you have any questions, feedback, or need help, please contact our support team:")
                        .font(.body)
                        .foregroundColor(.secondary)
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "envelope")
                                .foregroundColor(.blue)
                            Text("support@yayonay.app")
                                .font(.body)
                        }
                        HStack {
                            Image(systemName: "globe")
                                .foregroundColor(.green)
                            Text("www.yayonay.app/support")
                                .font(.body)
                        }
                    }
                }
                Spacer()
            }
            .padding(24)
        }
        .navigationTitle("Privacy & Support")
        .navigationBarTitleDisplayMode(.inline)
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
    }
}

#Preview {
    PrivacyAndSupportView()
} 