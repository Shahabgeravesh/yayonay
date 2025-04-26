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
import FirebaseMessaging

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
        
        // Request notification permissions
        NotificationManager.shared.requestNotificationPermission()
        
        // Initialize subQuestions collection
        print("DEBUG: Initializing DatabaseSeeder...")
        
        // First verify the categories collection
        print("DEBUG: Verifying categories collection...")
        Firestore.firestore().collection("categories").getDocuments { snapshot, error in
            if let error = error {
                print("DEBUG: Error verifying categories: \(error.localizedDescription)")
                return
            }
            
            if let documents = snapshot?.documents {
                print("DEBUG: Found \(documents.count) categories in the database")
                for document in documents {
                    let data = document.data()
                    print("DEBUG: Category document:")
                    print("  - ID: \(document.documentID)")
                    print("  - Name: \(data["name"] as? String ?? "unknown")")
                }
            } else {
                print("DEBUG: No categories found in the database")
            }
        }
        
        let seeder = DatabaseSeeder()
        seeder.initializeSubQuestionsCollection()
        
        // Add a delay to ensure Firebase is initialized
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            print("DEBUG: Verifying subQuestions collection...")
            Firestore.firestore().collection("subQuestions").getDocuments { snapshot, error in
                if let error = error {
                    print("DEBUG: Error verifying subQuestions: \(error.localizedDescription)")
                    return
                }
                
                if let documents = snapshot?.documents {
                    print("DEBUG: Found \(documents.count) subQuestions in the database")
                    for document in documents {
                        let data = document.data()
                        print("DEBUG: SubQuestion document:")
                        print("  - ID: \(document.documentID)")
                        print("  - Category ID: \(data["categoryId"] as? String ?? "unknown")")
                        print("  - Question: \(data["question"] as? String ?? "unknown")")
                    }
                } else {
                    print("DEBUG: No subQuestions found in the database")
                }
            }
        }
        
        return true
    }
    
    func application(_ application: UIApplication,
                    didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        Messaging.messaging().apnsToken = deviceToken
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
    @StateObject private var authViewModel = AuthViewModel()
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(userManager)
                .environmentObject(authViewModel)
                .onOpenURL { url in
                    handleDeepLink(url)
                }
                .preferredColorScheme(colorScheme)
                .background(AppColor.adaptiveBackground(for: colorScheme))
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
