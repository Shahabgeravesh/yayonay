import SwiftUI

struct ContentView: View {
    @EnvironmentObject var userManager: UserManager
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            ExploreView()
                .tabItem {
                    Label("Explore", systemImage: "square.grid.2x2")
                }
                .tag(0)
            
            HotVotesView()
                .tabItem {
                    Label("Hot", systemImage: "flame")
                }
                .tag(1)
            
            TopicBoxView()
                .tabItem {
                    Image("topicBoxIcon")
                        .renderingMode(.original)
                    Text("Topics")
                }
                .tag(2)
            
            VotesView()
                .tabItem {
                    Label("Votes", systemImage: "checkmark.circle")
                }
                .tag(3)
            
            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person")
                }
                .tag(4)
        }
    }
}

#Preview {
    ContentView()
} 