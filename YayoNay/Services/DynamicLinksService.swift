import Foundation
import FirebaseDynamicLinks
import FirebaseFirestore

class DynamicLinksService {
    static let shared = DynamicLinksService()
    private let domain = "yayonay.page.link" // Replace with your actual domain
    
    private init() {}
    
    func createVoteLink(voteId: String) async throws -> URL {
        let baseURL = "https://yayonay.app/vote/\(voteId)"
        
        guard let components = DynamicLinkComponents(link: URL(string: baseURL)!, domainURIPrefix: "https://\(domain)") else {
            throw NSError(domain: "DynamicLinksService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to create dynamic link components"])
        }
        
        // iOS parameters
        let iOSParams = DynamicLinkIOSParameters(bundleID: "com.yayonay.app")
        iOSParams.appStoreID = "YOUR_APP_STORE_ID" // Replace with your App Store ID
        components.iOSParameters = iOSParams
        
        // Android parameters
        let androidParams = DynamicLinkAndroidParameters(packageName: "com.yayonay.app")
        components.androidParameters = androidParams
        
        // Social meta tag parameters
        let socialParams = DynamicLinkSocialMetaTagParameters()
        socialParams.title = "Vote on YayoNay"
        socialParams.descriptionText = "Help decide what's better!"
        socialParams.imageURL = URL(string: "https://yayonay.app/logo.png")
        components.socialMetaTagParameters = socialParams
        
        // Analytics parameters
        let analyticsParams = DynamicLinkGoogleAnalyticsParameters()
        analyticsParams.source = "share"
        analyticsParams.medium = "social"
        analyticsParams.campaign = "vote"
        components.analyticsParameters = analyticsParams
        
        // Get the short URL
        let (shortURL, _) = try await components.shorten()
        return shortURL
    }
    
    func createCategoryLink(categoryId: String) async throws -> URL {
        let baseURL = "https://yayonay.app/category/\(categoryId)"
        
        guard let components = DynamicLinkComponents(link: URL(string: baseURL)!, domainURIPrefix: "https://\(domain)") else {
            throw NSError(domain: "DynamicLinksService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to create dynamic link components"])
        }
        
        // iOS parameters
        let iOSParams = DynamicLinkIOSParameters(bundleID: "com.yayonay.app")
        iOSParams.appStoreID = "YOUR_APP_STORE_ID" // Replace with your App Store ID
        components.iOSParameters = iOSParams
        
        // Android parameters
        let androidParams = DynamicLinkAndroidParameters(packageName: "com.yayonay.app")
        components.androidParameters = androidParams
        
        // Social meta tag parameters
        let socialParams = DynamicLinkSocialMetaTagParameters()
        socialParams.title = "Check out this category on YayoNay"
        socialParams.descriptionText = "Join the discussion and vote!"
        socialParams.imageURL = URL(string: "https://yayonay.app/logo.png")
        components.socialMetaTagParameters = socialParams
        
        // Analytics parameters
        let analyticsParams = DynamicLinkGoogleAnalyticsParameters()
        analyticsParams.source = "share"
        analyticsParams.medium = "social"
        analyticsParams.campaign = "category"
        components.analyticsParameters = analyticsParams
        
        // Get the short URL
        let (shortURL, _) = try await components.shorten()
        return shortURL
    }
    
    func createTopicLink(topicId: String) async throws -> URL {
        let baseURL = "https://yayonay.app/topic/\(topicId)"
        
        guard let components = DynamicLinkComponents(link: URL(string: baseURL)!, domainURIPrefix: "https://\(domain)") else {
            throw NSError(domain: "DynamicLinksService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to create dynamic link components"])
        }
        
        // iOS parameters
        let iOSParams = DynamicLinkIOSParameters(bundleID: "com.yayonay.app")
        iOSParams.appStoreID = "YOUR_APP_STORE_ID" // Replace with your App Store ID
        components.iOSParameters = iOSParams
        
        // Android parameters
        let androidParams = DynamicLinkAndroidParameters(packageName: "com.yayonay.app")
        components.androidParameters = androidParams
        
        // Social meta tag parameters
        let socialParams = DynamicLinkSocialMetaTagParameters()
        socialParams.title = "Vote on this topic on YayoNay"
        socialParams.descriptionText = "Join the discussion and share your opinion!"
        socialParams.imageURL = URL(string: "https://yayonay.app/logo.png")
        components.socialMetaTagParameters = socialParams
        
        // Analytics parameters
        let analyticsParams = DynamicLinkGoogleAnalyticsParameters()
        analyticsParams.source = "share"
        analyticsParams.medium = "social"
        analyticsParams.campaign = "topic"
        components.analyticsParameters = analyticsParams
        
        // Get the short URL
        let (shortURL, _) = try await components.shorten()
        return shortURL
    }
    
    func handleIncomingDynamicLink(_ url: URL) {
        DynamicLinks.dynamicLinks().handleUniversalLink(url) { dynamicLink, error in
            guard let dynamicLink = dynamicLink, let url = dynamicLink.url else { return }
            
            // Parse the URL path to determine the type of link
            if url.pathComponents.contains("vote") {
                if let voteId = url.pathComponents.last {
                    // Navigate to the vote
                    NotificationCenter.default.post(
                        name: NSNotification.Name("NavigateToVote"),
                        object: nil,
                        userInfo: ["voteId": voteId]
                    )
                }
            } else if url.pathComponents.contains("category") {
                if let categoryId = url.pathComponents.last {
                    // Navigate to the category
                    NotificationCenter.default.post(
                        name: NSNotification.Name("NavigateToCategory"),
                        object: nil,
                        userInfo: ["categoryId": categoryId]
                    )
                }
            } else if url.pathComponents.contains("topic") {
                if let topicId = url.pathComponents.last {
                    // Navigate to the topic
                    NotificationCenter.default.post(
                        name: NSNotification.Name("OpenVote"),
                        object: nil,
                        userInfo: ["topicId": topicId]
                    )
                }
            }
        }
    }
} 