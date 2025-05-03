// MARK: - Tutorial View
// This view provides an interactive tutorial for new users, including:
// 1. App features walkthrough
// 2. Voting mechanics explanation
// 3. Navigation guidance
// 4. Best practices and tips

import SwiftUI

struct TutorialCard: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let imageName: String
    let icon: String
}

struct TutorialView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var userManager: UserManager
    @State private var currentIndex = 0
    @State private var offset: CGFloat = 0
    @State private var isDragging = false
    @State private var showGetStarted = false
    @State private var isCompleting = false
    @Namespace private var animation
    
    var onComplete: (() -> Void)?
    
    private let cards = [
        TutorialCard(
            title: "Welcome to YayoNay",
            description: "Swipe left and right to navigate through this tutorial. In the app, you'll swipe up for YAY and down for NAY to vote on topics!",
            imageName: "tutorial_welcome",
            icon: "hand.wave.fill"
        ),
        TutorialCard(
            title: "Home Tab - Discover & Vote",
            description: "The Home tab shows trending topics and categories. In the app, swipe up on topics you like (YAY) or down on topics you dislike (NAY). Your votes help shape the community's opinion!",
            imageName: "tutorial_home",
            icon: "house.fill"
        ),
        TutorialCard(
            title: "Categories Tab - Explore Topics",
            description: "Browse through different categories like Politics, Sports, Entertainment, and more. Each category contains specific topics for you to vote on and discuss.",
            imageName: "tutorial_categories",
            icon: "square.grid.2x2.fill"
        ),
        TutorialCard(
            title: "Statistics Tab - Track Trends",
            description: "View detailed statistics about voting trends, popular topics, and your voting history. See how your opinions compare with others in the community.",
            imageName: "tutorial_stats",
            icon: "chart.bar.fill"
        ),
        TutorialCard(
            title: "Profile Tab - Your Activity",
            description: "Manage your profile, view your voting history, and see your contribution to the community. Customize your experience and track your engagement.",
            imageName: "tutorial_profile",
            icon: "person.fill"
        ),
        TutorialCard(
            title: "Sharing & Social Features",
            description: "Share your votes on social media, invite friends to join the conversation, and see what others are voting on. Connect with like-minded people!",
            imageName: "tutorial_sharing",
            icon: "square.and.arrow.up.fill"
        ),
        TutorialCard(
            title: "Ready to Start?",
            description: "You're all set! Remember: in the app, swipe up for YAY and down for NAY. Let's get started!",
            imageName: "tutorial_ready",
            icon: "checkmark.circle.fill"
        )
    ]
    
    private func completeTutorial() {
        guard !isCompleting else { return }
        isCompleting = true
        
        print("DEBUG: Starting tutorial completion")
        
        // Save tutorial completion state
        userManager.completeTutorial()
        print("DEBUG: Tutorial completion state saved")
        
        // Call completion handler first
        if let onComplete = onComplete {
            print("DEBUG: Calling completion handler")
            onComplete()
        } else {
            print("DEBUG: No completion handler provided")
        }
        
        // Then dismiss the view
        print("DEBUG: Attempting to dismiss view")
        DispatchQueue.main.async {
            print("DEBUG: Inside main thread async block")
            presentationMode.wrappedValue.dismiss()
            print("DEBUG: Dismiss called")
        }
    }
    
    var body: some View {
        GeometryReader { geometry in
        ZStack {
            // Background gradient
            LinearGradient(
                    gradient: Gradient(colors: [Color.blue.opacity(0.3), Color.purple.opacity(0.3)]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
                VStack(spacing: 20) {
                    // Progress dots
                    HStack(spacing: 8) {
                        ForEach(0..<cards.count, id: \.self) { index in
                            Circle()
                                .fill(currentIndex == index ? Color.blue : Color.gray.opacity(0.3))
                                .frame(width: 8, height: 8)
                                .scaleEffect(currentIndex == index ? 1.2 : 1.0)
                                .animation(.spring(), value: currentIndex)
                        }
                    }
                    .padding(.top, 50)
                    
                    // Cards
                    ZStack {
                        ForEach(Array(cards.enumerated()), id: \.element.id) { index, card in
                            TutorialCardView(card: card)
                                .frame(width: geometry.size.width - 40, height: geometry.size.height * 0.7)
                                .offset(x: CGFloat(index - currentIndex) * (geometry.size.width - 40) + offset)
                                .scaleEffect(currentIndex == index ? 1.0 : 0.8)
                                .rotationEffect(.degrees(Double(offset) * 0.05))
                                .gesture(
                                    DragGesture()
                                        .onChanged { value in
                                            isDragging = true
                                            offset = value.translation.width
                }
                                        .onEnded { value in
                                            isDragging = false
                                            let threshold = geometry.size.width * 0.3
                                            if abs(value.translation.width) > threshold {
                                                if value.translation.width > 0 {
                                                    withAnimation {
                                                        currentIndex = max(0, currentIndex - 1)
                                                    }
                                                } else {
                                                    withAnimation {
                                                        currentIndex = min(cards.count - 1, currentIndex + 1)
                            }
                                                }
                                            }
                                            withAnimation {
                                                offset = 0
                                            }
                                            
                                            // Check if we're on the last card and swiped left
                                            if currentIndex == cards.count - 1 && value.translation.width < -threshold {
                                                completeTutorial()
                        }
                    }
                                )
                        }
                    }
                    
                    // Action buttons
                    HStack(spacing: 20) {
                        Button(action: {
                            withAnimation {
                                currentIndex = max(0, currentIndex - 1)
                            }
                        }) {
                            Image(systemName: "arrow.left.circle.fill")
                                .font(.system(size: 40))
                                .foregroundColor(.blue)
                        }
                        .disabled(currentIndex == 0)
                        .opacity(currentIndex == 0 ? 0.5 : 1.0)
                        
                        if currentIndex < cards.count - 1 {
                        Button(action: {
                            withAnimation {
                                    currentIndex = min(cards.count - 1, currentIndex + 1)
                                }
                            }) {
                                Image(systemName: "arrow.right.circle.fill")
                                    .font(.system(size: 40))
                                    .foregroundColor(.blue)
                            }
                        } else {
                            Button(action: {
                                print("DEBUG: Get Started button pressed")
                                completeTutorial()
                        }) {
                            Text("Get Started")
                                    .font(.headline)
                                .foregroundColor(.white)
                                    .padding(.horizontal, 30)
                                    .padding(.vertical, 15)
                                    .background(Color.blue)
                                    .cornerRadius(25)
                        }
                    }
                }
                .padding(.bottom, 30)
            }
        }
    }
    }
}

struct TutorialCardView: View {
    let card: TutorialCard
    @State private var imageLoaded = false
    
    var body: some View {
        VStack(spacing: 20) {
                // Icon
            Image(systemName: card.icon)
                .font(.system(size: 50))
                .foregroundColor(.blue)
                .padding()
                .background(Color.blue.opacity(0.1))
                .clipShape(Circle())
                
                // Title
            Text(card.title)
                .font(.title)
                .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                
                // Description
            Text(card.description)
                .font(.body)
                    .multilineTextAlignment(.center)
                .padding(.horizontal)
                
            // App Screenshot with fallback
            if let image = UIImage(named: card.imageName) {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(height: 200)
                    .cornerRadius(15)
                    .shadow(radius: 5)
                    .padding()
            } else {
                // Fallback placeholder
                VStack {
                    Image(systemName: "photo")
                        .font(.system(size: 50))
                        .foregroundColor(.gray)
                    Text("Screenshot coming soon")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                .frame(height: 200)
                .frame(maxWidth: .infinity)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(15)
                .padding()
            }
            }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(20)
        .shadow(radius: 10)
    }
}

// Preview
struct TutorialView_Previews: PreviewProvider {
    static var previews: some View {
        TutorialView()
    }
} 