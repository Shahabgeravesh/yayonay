import SwiftUI

struct ContentView: View {
    @StateObject private var userManager = UserManager()
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Hot Votes Tab (moved to first position)
            HotVotesView()
                .tabItem {
                    Label("Hot", systemImage: "flame")
                }
                .tag(0)
            
            // Topics Tab (moved to second position)
            TopicBoxView()
                .tabItem {
                    Label("Topics", systemImage: "list.bullet")
                }
                .tag(1)
            
            // Other tabs remain in the same order
            VotesView()
                .tabItem {
                    Label("Votes", systemImage: "checkmark.circle")
                }
                .tag(2)
            
            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person")
                }
                .tag(3)
        }
        .environmentObject(userManager)
    }
}

#Preview {
    ContentView()
} 