import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var userManager: UserManager
    
    var body: some View {
        TabView {
            ExploreView()
                .tabItem {
                    Label("Explore", systemImage: "square.grid.2x2")
                }
            
            HotVotesView()
                .tabItem {
                    VStack {
                        Image(systemName: "flame.fill")
                            .foregroundColor(.blue)
                        Text("Hot")
                            .foregroundColor(.blue)
                    }
                }
            
            TopicBoxView()
                .tabItem {
                    VStack {
                        Image(systemName: "list.bullet")
                            .foregroundColor(.gray)
                        Text("Topics")
                            .foregroundColor(.gray)
                    }
                }
            
            VotesView()
                .tabItem {
                    VStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.gray)
                        Text("Votes")
                            .foregroundColor(.gray)
                    }
                }
            
            ProfileView()
                .tabItem {
                    VStack {
                        Image(systemName: "person.fill")
                            .foregroundColor(.gray)
                        Text("Profile")
                            .foregroundColor(.gray)
                    }
                }
        }
        .tint(.blue) // This sets the active tab color
    }
} 