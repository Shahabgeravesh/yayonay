import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var userManager: UserManager
    
    var body: some View {
        TabView {
            ExploreView()
                .tabItem {
                    Image(systemName: "square.grid.2x2")
                }
            
            VotesView()
                .tabItem {
                    Image(systemName: "checkmark.circle.fill")
                }
            
            HotVotesView()
                .tabItem {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                }
            
            TopicBoxView()
                .tabItem {
                    TopicTabIcon()
                }
            
            ProfileView()
                .tabItem {
                    Image(systemName: "person.fill")
                }
        }
        .tint(.blue) // This sets the active tab color
    }
} 