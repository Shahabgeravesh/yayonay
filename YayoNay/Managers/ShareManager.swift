import Foundation
import UIKit
import MessageUI
import Firebase
import FirebaseAuth
import FirebaseFirestore

class ShareManager: NSObject, MFMessageComposeViewControllerDelegate {
    static let shared = ShareManager()
    private let baseURL = "yayonay://vote"
    private let db = Firestore.firestore()
    
    func createShareURL(for topic: Topic) -> URL? {
        let urlString = "\(baseURL)?id=\(topic.id)"
        return URL(string: urlString)
    }
    
    func shareContent(for topic: Topic) {
        guard let url = createShareURL(for: topic),
              let userId = Auth.auth().currentUser?.uid else { return }
        
        // Get the user's profile from Firestore
        db.collection("users").document(userId).getDocument { [weak self] snapshot, error in
            guard let self = self,
                  let data = snapshot?.data(),
                  let username = data["username"] as? String else {
                // Fallback to display name if profile not found
                self?.presentShareSheet(for: topic, with: Auth.auth().currentUser?.displayName ?? "Someone", url: url)
                return
            }
            
            self.presentShareSheet(for: topic, with: username, url: url)
        }
    }
    
    private func presentShareSheet(for topic: Topic, with username: String, url: URL) {
        let text = """
        \(username) wants you to vote on YayoNay on:
        
        \(topic.title)
        
        Vote now: \(url.absoluteString)
        """
        
        // Create an NSAttributedString for richer text sharing
        let attributedString = NSAttributedString(
            string: text,
            attributes: [
                .font: UIFont.systemFont(ofSize: 16),
                .foregroundColor: UIColor.label
            ]
        )
        
        // Create image for sharing
        let image = createShareImage(for: topic, username: username)
        
        // Prepare all items for sharing
        let itemsToShare: [Any] = [
            text,                // Plain text
            attributedString,    // Rich text
            url,                // Deep link URL
            image               // Share image
        ]
        
        let activityVC = UIActivityViewController(
            activityItems: itemsToShare,
            applicationActivities: nil
        )
        
        // Only exclude non-relevant activities
        activityVC.excludedActivityTypes = [
            .assignToContact,
            .addToReadingList,
            .openInIBooks
        ]
        
        // Present the share sheet
        DispatchQueue.main.async {
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let window = windowScene.windows.first,
               let rootVC = window.rootViewController?.topMostViewController() {
                if UIDevice.current.userInterfaceIdiom == .pad {
                    activityVC.popoverPresentationController?.sourceView = rootVC.view
                    activityVC.popoverPresentationController?.sourceRect = CGRect(x: UIScreen.main.bounds.width / 2, y: UIScreen.main.bounds.height / 2, width: 0, height: 0)
                    activityVC.popoverPresentationController?.permittedArrowDirections = []
                }
                rootVC.present(activityVC, animated: true)
            }
        }
    }
    
    func shareViaMessage(for topic: Topic) {
        guard MFMessageComposeViewController.canSendText() else {
            // Show alert that messaging is not available
            DispatchQueue.main.async {
                if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                   let window = windowScene.windows.first,
                   let rootVC = window.rootViewController?.topMostViewController() {
                    let alert = UIAlertController(
                        title: "Cannot Send Message",
                        message: "Your device is not configured to send text messages.",
                        preferredStyle: .alert
                    )
                    alert.addAction(UIAlertAction(title: "OK", style: .default))
                    rootVC.present(alert, animated: true)
                }
            }
            return
        }
        
        guard let url = createShareURL(for: topic),
              let userId = Auth.auth().currentUser?.uid else { return }
        
        // Get the user's profile from Firestore
        db.collection("users").document(userId).getDocument { [weak self] snapshot, error in
            guard let self = self,
                  let data = snapshot?.data(),
                  let username = data["username"] as? String else {
                // Fallback to display name if profile not found
                self?.presentMessageComposer(for: topic, with: Auth.auth().currentUser?.displayName ?? "Someone", url: url)
                return
            }
            
            self.presentMessageComposer(for: topic, with: username, url: url)
        }
    }
    
    private func presentMessageComposer(for topic: Topic, with username: String, url: URL) {
        let messageVC = MFMessageComposeViewController()
        messageVC.messageComposeDelegate = self
        
        let messageText = """
        \(username) wants you to vote on YayoNay on:
        
        \(topic.title)
        
        Vote now: \(url.absoluteString)
        """
        
        messageVC.body = messageText
        
        // Present the message composer
        DispatchQueue.main.async {
            if let topVC = UIApplication.shared.windows.first?.rootViewController?.topMostViewController() {
                topVC.present(messageVC, animated: true)
            }
        }
    }
    
    // MARK: - MFMessageComposeViewControllerDelegate
    func messageComposeViewController(_ controller: MFMessageComposeViewController, didFinishWith result: MessageComposeResult) {
        controller.dismiss(animated: true)
    }
    
    private func createShareImage(for topic: Topic, username: String) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 600, height: 300))
        
        let image = renderer.image { context in
            // Background
            UIColor.systemBackground.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 600, height: 300))
            
            // Draw content
            let titleAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 24, weight: .bold),
                .foregroundColor: UIColor.label
            ]
            
            let messageAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 20),
                .foregroundColor: UIColor.label
            ]
            
            // Draw message
            "\(username) wants you to vote on YayoNay on:".draw(at: CGPoint(x: 30, y: 40), withAttributes: titleAttributes)
            
            // Draw topic
            topic.title.draw(at: CGPoint(x: 30, y: 100), withAttributes: messageAttributes)
            
            // Draw call to action
            "Vote now on YayoNay".draw(at: CGPoint(x: 30, y: 220), withAttributes: [
                .font: UIFont.systemFont(ofSize: 18, weight: .semibold),
                .foregroundColor: UIColor.secondaryLabel
            ])
        }
        
        return image
    }
}

// Helper extension to get the topmost view controller
extension UIViewController {
    func topMostViewController() -> UIViewController {
        if let presented = presentedViewController {
            return presented.topMostViewController()
        }
        if let navigation = self as? UINavigationController {
            return navigation.visibleViewController?.topMostViewController() ?? navigation
        }
        if let tab = self as? UITabBarController {
            return tab.selectedViewController?.topMostViewController() ?? tab
        }
        return self
    }
} 