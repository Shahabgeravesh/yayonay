import SwiftUI
import UIKit

struct TopicBox: View {
    let topic: Topic
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Topic title
            Text(topic.title)
                .font(.headline)
                .foregroundColor(.primary)
            
            // Topic description
            if !topic.description.isEmpty {
                Text(topic.description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            
            // Share button
            Button(action: shareTopic) {
                HStack {
                    Image(systemName: "square.and.arrow.up")
                    Text("Share")
                }
                .foregroundColor(.blue)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
    
    private func shareTopic() {
        Task {
            do {
                let dynamicLink = try await DynamicLinksService.shared.createTopicLink(topicId: topic.id)
                let activityItems: [Any] = [
                    "Check out this topic on YayoNay: \(dynamicLink.absoluteString)"
                ]
                
                let activityVC = UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
                if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                   let window = windowScene.windows.first,
                   let rootVC = window.rootViewController {
                    rootVC.present(activityVC, animated: true)
                }
            } catch {
                print("Error creating dynamic link: \(error)")
                // Fallback to regular URL
                let fallbackURL = "https://yayonay.app/topic/\(topic.id)"
                let activityItems: [Any] = [
                    "Check out this topic on YayoNay: \(fallbackURL)"
                ]
                
                let activityVC = UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
                if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                   let window = windowScene.windows.first,
                   let rootVC = window.rootViewController {
                    rootVC.present(activityVC, animated: true)
                }
            }
        }
    }
} 