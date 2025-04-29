import SwiftUI

class HapticManager {
    static let shared = HapticManager()
    private init() {}
    
    // MARK: - Notification Feedback
    
    func notification(type: UINotificationFeedbackGenerator.FeedbackType) {
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(type)
    }
    
    // MARK: - Impact Feedback
    
    func impact(style: UIImpactFeedbackGenerator.FeedbackStyle) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.prepare()
        generator.impactOccurred()
    }
    
    // MARK: - Selection Feedback
    
    func selection() {
        let generator = UISelectionFeedbackGenerator()
        generator.prepare()
        generator.selectionChanged()
    }
    
    // MARK: - Custom Feedback Methods
    
    func voteSuccess() {
        impact(style: .medium)
    }
    
    func voteReset() {
        impact(style: .heavy)
    }
    
    func error() {
        notification(type: .error)
    }
    
    func success() {
        notification(type: .success)
    }
    
    func warning() {
        notification(type: .warning)
    }
    
    func buttonPress() {
        impact(style: .light)
    }
    
    func longPress() {
        impact(style: .rigid)
    }
} 