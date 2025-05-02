import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var userManager: UserManager
    @State private var selectedTab = 0
    @State private var tabBarOffset: CGFloat = 0
    @State private var isTabBarVisible = true
    
    var body: some View {
        ZStack {
            TabView(selection: $selectedTab) {
            ExploreView()
                    .tag(0)
            
            VotesView()
                    .tag(1)
            
            HotVotesView()
                    .tag(2)
                
                TopicBoxView()
                    .tag(3)
                
                ProfileView()
                    .tag(4)
            }
            .onChange(of: selectedTab) { _, _ in
                withAnimation(.spring()) {
                    isTabBarVisible = true
                }
            }
            
            // Custom Tab Bar
            VStack {
                Spacer()
                HStack(spacing: 0) {
                    ForEach(0..<5) { index in
                        Button(action: {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                selectedTab = index
                            }
                        }) {
                            VStack(spacing: 4) {
                                ZStack {
                                    Circle()
                                        .fill(selectedTab == index ? Color.blue.opacity(0.05) : Color.clear)
                                        .frame(width: 40, height: 40)
                                    
                                    Image(systemName: tabIcon(for: index))
                                        .font(.system(size: 18, weight: selectedTab == index ? .semibold : .regular))
                                        .foregroundColor(selectedTab == index ? .blue : .gray)
                                        .scaleEffect(selectedTab == index ? 1.1 : 1.0)
                                }
                            }
                            .frame(maxWidth: .infinity)
                        }
                    }
                }
                .padding(.horizontal, 4)
                .padding(.vertical, 8)
                .background(
                    .ultraThinMaterial
                        .opacity(0.8)
                )
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: -2)
                .padding(.horizontal)
                .padding(.bottom, 4)
                .offset(y: isTabBarVisible ? 0 : 100)
            }
        }
        .ignoresSafeArea(.keyboard)
    }
    
    private func tabIcon(for index: Int) -> String {
        switch index {
        case 0: return "square.grid.2x2.fill"
        case 1: return "checkmark.circle.fill"
        case 2: return "chart.line.uptrend.xyaxis"
        case 3: return "square.text.square.fill"
        case 4: return "person.fill"
        default: return ""
        }
    }
} 