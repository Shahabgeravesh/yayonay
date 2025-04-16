import Foundation
import FirebaseMessaging
import UserNotifications
import FirebaseFirestore
import FirebaseAuth
import UIKit

class NotificationManager: NSObject, ObservableObject {
    static let shared = NotificationManager()
    private let db = Firestore.firestore()
    
    @Published var isNotificationsEnabled = false
    
    override init() {
        super.init()
        UNUserNotificationCenter.current().delegate = self
        Messaging.messaging().delegate = self
    }
    
    func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { [weak self] granted, error in
            DispatchQueue.main.async {
                self?.isNotificationsEnabled = granted
                if granted {
                    UIApplication.shared.registerForRemoteNotifications()
                }
            }
        }
    }
    
    func updateFCMToken() {
        Messaging.messaging().token { [weak self] token, error in
            guard let self = self,
                  let token = token,
                  let userId = Auth.auth().currentUser?.uid else { return }
            
            // Store the FCM token in Firestore
            self.db.collection("users").document(userId).updateData([
                "fcmToken": token
            ]) { error in
                if let error = error {
                    print("Error updating FCM token: \(error.localizedDescription)")
                }
            }
        }
    }
    
    func subscribeToCommentNotifications(for topicId: String) {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        // Subscribe to comment notifications for this topic
        let topicName = "topic_\(topicId)_comments"
        Messaging.messaging().subscribe(toTopic: topicName) { error in
            if let error = error {
                print("Error subscribing to topic: \(error.localizedDescription)")
            }
        }
        
        // Store the subscription in Firestore
        db.collection("users").document(userId).updateData([
            "commentSubscriptions": FieldValue.arrayUnion([topicId])
        ])
    }
    
    func subscribeToVoteNotifications(for topicId: String) {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        // Subscribe to vote notifications for this topic
        let topicName = "topic_\(topicId)_votes"
        Messaging.messaging().subscribe(toTopic: topicName) { error in
            if let error = error {
                print("Error subscribing to topic: \(error.localizedDescription)")
            }
        }
        
        // Store the subscription in Firestore
        db.collection("users").document(userId).updateData([
            "voteSubscriptions": FieldValue.arrayUnion([topicId])
        ])
    }
}

// MARK: - UNUserNotificationCenterDelegate
extension NotificationManager: UNUserNotificationCenterDelegate {
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                              willPresent notification: UNNotification,
                              withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound])
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                              didReceive response: UNNotificationResponse,
                              withCompletionHandler completionHandler: @escaping () -> Void) {
        let userInfo = response.notification.request.content.userInfo
        
        // Handle notification tap
        if let topicId = userInfo["topicId"] as? String {
            NotificationCenter.default.post(
                name: Notification.Name("OpenVote"),
                object: nil,
                userInfo: ["topicId": topicId]
            )
        }
        
        completionHandler()
    }
}

// MARK: - MessagingDelegate
extension NotificationManager: MessagingDelegate {
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        updateFCMToken()
    }
} 