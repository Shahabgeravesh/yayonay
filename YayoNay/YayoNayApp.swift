//
//  YayoNayApp.swift
//  YayoNay
//
//  Created by Shahab Geravesh on 3/15/25.
//

import SwiftUI
import FirebaseCore
import GoogleSignIn
import FirebaseFirestore
import FirebaseAuth
import FirebaseStorage

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        // Configure Firebase
        FirebaseConfiguration.shared.setLoggerLevel(.min)
        FirebaseApp.configure()
        
        // Configure Firestore settings
        let settings = FirestoreSettings()
        settings.isPersistenceEnabled = true
        settings.cacheSizeBytes = FirestoreCacheSizeUnlimited
        Firestore.firestore().settings = settings
        
        // Configure Google Sign In
        guard let clientID = FirebaseApp.app()?.options.clientID else { return false }
        let config = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.configuration = config
        
        return true
    }
    
    func application(_ application: UIApplication,
                    open url: URL,
                    options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
        if url.scheme == "yayonay" {
            handleDeepLink(url)
            return true
        }
        return GIDSignIn.sharedInstance.handle(url)
    }
    
    private func handleDeepLink(_ url: URL) {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: true),
              let topicId = components.queryItems?.first(where: { $0.name == "id" })?.value else {
            return
        }
        
        NotificationCenter.default.post(
            name: Notification.Name("OpenVote"),
            object: nil,
            userInfo: ["topicId": topicId]
        )
    }
}

@main
struct YayoNayApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @StateObject private var userManager = UserManager()
    
    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(userManager)
                .onOpenURL { url in
                    handleDeepLink(url)
                }
        }
    }
    
    private func handleDeepLink(_ url: URL) {
        guard url.scheme == "yayonay",
              url.host == "vote",
              let components = URLComponents(url: url, resolvingAgainstBaseURL: true),
              let topicId = components.queryItems?.first(where: { $0.name == "id" })?.value
        else { return }
        
        // Navigate to the specific vote
        NotificationCenter.default.post(
            name: Notification.Name("OpenVote"),
            object: nil,
            userInfo: ["topicId": topicId]
        )
    }
}
