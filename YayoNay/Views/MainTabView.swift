import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var userManager: UserManager
    
    var body: some View {
        TabView {
            ExploreView()
                .tabItem {
                    Label("Explore", systemImage: "square.grid.2x2")
                }
            
            VotesView()
                .tabItem {
                    Label("Votes", systemImage: "list.bullet")
                }
            
            HotVotesView()
                .tabItem {
                    Label("Hot", systemImage: "flame")
                }
            
            TopicBoxView()
                .tabItem {
                    Label("Topics", systemImage: "square.text.square")
                }
            
            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person.fill")
                }
        }
    }
} 