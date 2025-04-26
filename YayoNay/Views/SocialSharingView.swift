import SwiftUI

struct SocialSharingView: View {
    let subCategory: SubCategory
    @Environment(\.colorScheme) private var colorScheme
    
    private var shareText: String {
        "Check out \(subCategory.name) on YayoNay! \(subCategory.yayCount) people voted Yay and \(subCategory.nayCount) voted Nay. What do you think? #YayoNay"
    }
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Share")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 20) {
                    // Facebook
                    ShareButton(
                        icon: "facebook",
                        color: Color(red: 0.23, green: 0.35, blue: 0.60),
                        action: { shareToFacebook() }
                    )
                    
                    // Twitter/X
                    ShareButton(
                        icon: "twitter",
                        color: .black,
                        action: { shareToTwitter() }
                    )
                    
                    // Instagram
                    ShareButton(
                        icon: "instagram",
                        color: Color(red: 0.83, green: 0.18, blue: 0.42),
                        action: { shareToInstagram() }
                    )
                    
                    // Reddit
                    ShareButton(
                        icon: "reddit",
                        color: Color(red: 1.00, green: 0.40, blue: 0.00),
                        action: { shareToReddit() }
                    )
                    
                    // TikTok
                    ShareButton(
                        icon: "tiktok",
                        color: .black,
                        action: { shareToTikTok() }
                    )
                    
                    // Message
                    ShareButton(
                        icon: "message",
                        color: .blue,
                        action: { shareViaMessage() }
                    )
                }
                .padding(.horizontal)
            }
        }
        .padding(.vertical)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: colorScheme == .dark ? .black.opacity(0.2) : .black.opacity(0.05),
                radius: colorScheme == .dark ? 3 : 3,
                y: colorScheme == .dark ? 1 : 1)
    }
    
    private func shareToFacebook() {
        if let url = URL(string: "https://www.facebook.com/sharer/sharer.php?u=\(subCategory.imageURL)") {
            UIApplication.shared.open(url)
        }
    }
    
    private func shareToTwitter() {
        if let url = URL(string: "https://twitter.com/intent/tweet?text=\(shareText.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")") {
            UIApplication.shared.open(url)
        }
    }
    
    private func shareToInstagram() {
        if let url = URL(string: "instagram://app") {
            if UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url)
            } else {
                if let webURL = URL(string: "https://www.instagram.com/") {
                    UIApplication.shared.open(webURL)
                }
            }
        }
    }
    
    private func shareToReddit() {
        if let url = URL(string: "https://www.reddit.com/submit?url=\(subCategory.imageURL)&title=\(shareText.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")") {
            UIApplication.shared.open(url)
        }
    }
    
    private func shareToTikTok() {
        if let url = URL(string: "https://www.tiktok.com/") {
            UIApplication.shared.open(url)
        }
    }
    
    private func shareViaMessage() {
        let activityVC = UIActivityViewController(
            activityItems: [shareText, URL(string: subCategory.imageURL) as Any],
            applicationActivities: nil
        )
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first,
           let rootVC = window.rootViewController {
            rootVC.present(activityVC, animated: true)
        }
    }
}

struct ShareButton: View {
    let icon: String
    let color: Color
    let action: () -> Void
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        Button(action: action) {
            Image(icon)
                .resizable()
                .scaledToFit()
                .frame(width: 30, height: 30)
                .padding(10)
                .background(color.opacity(0.1))
                .clipShape(Circle())
                .shadow(color: colorScheme == .dark ? .black.opacity(0.2) : .black.opacity(0.05),
                        radius: colorScheme == .dark ? 3 : 3,
                        y: colorScheme == .dark ? 1 : 1)
        }
    }
} 