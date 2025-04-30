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
                            VStack(spacing: 6) {
                                ZStack {
                                    Circle()
                                        .fill(selectedTab == index ? Color.blue.opacity(0.1) : Color.clear)
                                        .frame(width: 50, height: 50)
                                    
                                    Image(systemName: tabIcon(for: index))
                                        .font(.system(size: 22, weight: selectedTab == index ? .semibold : .regular))
                                        .foregroundColor(selectedTab == index ? .blue : .gray)
                                        .scaleEffect(selectedTab == index ? 1.1 : 1.0)
                }
            
                                if selectedTab == index {
                                    Circle()
                                        .fill(Color.blue)
                                        .frame(width: 4, height: 4)
                                        .transition(.scale.combined(with: .opacity))
                                }
                            }
                            .frame(maxWidth: .infinity)
                        }
                    }
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 12)
                .background(
                    .ultraThinMaterial
                )
                .clipShape(RoundedRectangle(cornerRadius: 25))
                .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: -5)
                .padding(.horizontal)
                .padding(.bottom, 8)
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