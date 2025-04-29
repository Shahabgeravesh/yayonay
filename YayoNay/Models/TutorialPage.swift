import SwiftUI

struct TutorialPage: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let imageName: String
    let color: Color
    let exampleImage: String?
    let tips: [String]
    
    static let pages: [TutorialPage] = [
        TutorialPage(
            title: "Welcome to YayoNay",
            description: "Your opinion matters! YayoNay is a platform where you can vote on various topics and see what others think. Each vote helps build a community consensus.",
            imageName: "hand.thumbsup.fill",
            color: .blue,
            exampleImage: nil,
            tips: [
                "Swipe left to see more features",
                "Tap 'Skip' if you're familiar with the app"
            ]
        ),
        TutorialPage(
            title: "How to Vote",
            description: "Browse through categories and topics. For each item, swipe UP for 'Yay' or DOWN for 'Nay'. The background color will change to green for Yay and red for Nay as you swipe.",
            imageName: "arrow.up.and.down",
            color: .green,
            exampleImage: nil,
            tips: [
                "Swipe up to vote 'Yay'",
                "Swipe down to vote 'Nay'",
                "You can only vote once per topic",
                "There's a 7-day cooldown between votes"
            ]
        ),
        TutorialPage(
            title: "Understanding Results",
            description: "After voting, you'll see the percentage of people who agree with you. The bar shows the distribution of votes, with green for Yay and red for Nay. You can also see the total number of votes cast.",
            imageName: "chart.bar.fill",
            color: .purple,
            exampleImage: nil,
            tips: [
                "Green represents 'Yay' votes",
                "Red represents 'Nay' votes",
                "The longer the bar, the more votes",
                "See how your vote compares to others"
            ]
        ),
        TutorialPage(
            title: "Vote History",
            description: "View all your past votes in the 'My Votes' section. You can filter by Yay or Nay votes, search for specific topics, and sort by date, category, or name.",
            imageName: "clock.fill",
            color: .orange,
            exampleImage: nil,
            tips: [
                "Filter your votes by Yay or Nay",
                "Search for specific topics",
                "Sort by date, category, or name",
                "View detailed statistics for each vote"
            ]
        ),
        TutorialPage(
            title: "Hot Topics",
            description: "Discover trending topics in the 'Hot Votes' section. See what's popular today and explore top categories based on voting activity.",
            imageName: "flame.fill",
            color: .red,
            exampleImage: nil,
            tips: [
                "See today's most voted topics",
                "Explore top categories",
                "View vote percentages",
                "Discover popular discussions"
            ]
        ),
        TutorialPage(
            title: "Vote Cooldown",
            description: "You can only vote on a topic once every 7 days. This encourages thoughtful voting and prevents spam. The app will show you when you can vote again.",
            imageName: "timer",
            color: .indigo,
            exampleImage: nil,
            tips: [
                "7-day cooldown between votes",
                "See when you can vote again",
                "Votes are permanent",
                "Choose your votes carefully"
            ]
        )
    ]
} 