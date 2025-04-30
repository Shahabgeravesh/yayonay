import UIKit

class VoteDetailView: UIViewController {

    private var vote: Vote!

    override func viewDidLoad() {
        super.viewDidLoad()
        // Initialize vote with required parameters
        vote = Vote(
            id: "1",
            itemName: "Sample Vote",
            imageURL: "https://example.com/image.jpg",
            isYay: true,
            date: Date(),
            categoryName: "Sample Category",
            categoryId: "category1",
            subCategoryId: "subcategory1"
        )
    }

    private func shareVote() {
        Task {
            do {
                let shareURL = try await DynamicLinksService.shared.createVoteLink(voteId: vote.id)
                
                let items: [Any] = [
                    "Check out this vote on YayoNay!",
                    shareURL
                ]
                
                let activityVC = UIActivityViewController(activityItems: items, applicationActivities: nil)
                
                // For iPad
                if let popoverController = activityVC.popoverPresentationController {
                    popoverController.sourceView = UIApplication.shared.windows.first?.rootViewController?.view
                    popoverController.sourceRect = CGRect(x: UIScreen.main.bounds.width / 2, y: UIScreen.main.bounds.height / 2, width: 0, height: 0)
                    popoverController.permittedArrowDirections = []
                }
                
                UIApplication.shared.windows.first?.rootViewController?.present(activityVC, animated: true)
            } catch {
                print("Error creating share link: \(error)")
                // Fallback to regular URL if dynamic link fails
                let fallbackURL = "https://yayonay.app/vote/\(vote.id)"
                let items: [Any] = [
                    "Check out this vote on YayoNay!",
                    URL(string: fallbackURL)!
                ]
                
                let activityVC = UIActivityViewController(activityItems: items, applicationActivities: nil)
                UIApplication.shared.windows.first?.rootViewController?.present(activityVC, animated: true)
            }
        }
    }
} 