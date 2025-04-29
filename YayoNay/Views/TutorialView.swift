import SwiftUI

struct TutorialView: View {
    @State private var currentPage = 0
    @State private var showGetStarted = false
    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject private var userManager: UserManager
    @EnvironmentObject private var authViewModel: AuthViewModel
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(.systemBackground),
                    Color(.systemBackground).opacity(0.8)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack {
                // Skip button
                HStack {
                    Spacer()
                    Button(action: {
                        HapticManager.shared.buttonPress()
                        userManager.completeTutorial()
                    }) {
                        Text("Skip")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.secondary)
                            .padding()
                    }
                }
                
                Spacer()
                
                // Tutorial content
                TabView(selection: $currentPage) {
                    ForEach(Array(TutorialPage.pages.enumerated()), id: \.offset) { index, page in
                        TutorialPageView(page: page)
                            .tag(index)
                    }
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                .animation(.easeInOut, value: currentPage)
                
                // Page indicators
                HStack(spacing: 8) {
                    ForEach(0..<TutorialPage.pages.count, id: \.self) { index in
                        Circle()
                            .fill(currentPage == index ? pageColor : Color.gray.opacity(0.3))
                            .frame(width: 8, height: 8)
                            .scaleEffect(currentPage == index ? 1.2 : 1.0)
                            .animation(.spring(), value: currentPage)
                    }
                }
                .padding(.bottom, 20)
                
                // Navigation buttons
                HStack {
                    if currentPage > 0 {
                        Button(action: {
                            HapticManager.shared.buttonPress()
                            withAnimation(.easeInOut) {
                                currentPage -= 1
                            }
                        }) {
                            HStack {
                                Image(systemName: "chevron.left")
                                Text("Previous")
                            }
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.primary)
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(10)
                        }
                    }
                    
                    Spacer()
                    
                    if currentPage < TutorialPage.pages.count - 1 {
                        Button(action: {
                            HapticManager.shared.buttonPress()
                            withAnimation(.easeInOut) {
                                currentPage += 1
                            }
                        }) {
                            HStack {
                                Text("Next")
                                Image(systemName: "chevron.right")
                            }
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white)
                            .padding()
                            .background(pageColor)
                            .cornerRadius(10)
                        }
                    } else {
                        Button(action: {
                            HapticManager.shared.success()
                            withAnimation {
                                showGetStarted = true
                            }
                            userManager.completeTutorial()
                        }) {
                            Text("Get Started")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.white)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(pageColor)
                                .cornerRadius(10)
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 30)
            }
        }
    }
    
    private var pageColor: Color {
        TutorialPage.pages[currentPage].color
    }
}

struct TutorialPageView: View {
    let page: TutorialPage
    @State private var isAnimating = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 30) {
                // Icon
                Image(systemName: page.imageName)
                    .font(.system(size: 80))
                    .foregroundColor(page.color)
                    .scaleEffect(isAnimating ? 1.0 : 0.5)
                    .opacity(isAnimating ? 1.0 : 0.0)
                    .animation(.spring(response: 0.6, dampingFraction: 0.6), value: isAnimating)
                
                // Title
                Text(page.title)
                    .font(.system(size: 28, weight: .bold))
                    .multilineTextAlignment(.center)
                    .foregroundColor(.primary)
                    .padding(.horizontal)
                
                // Description
                Text(page.description)
                    .font(.system(size: 18))
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 40)
                
                // Tips Section
                VStack(alignment: .leading, spacing: 12) {
                    Text("Quick Tips")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.primary)
                        .padding(.top, 20)
                    
                    ForEach(page.tips, id: \.self) { tip in
                        HStack(alignment: .top, spacing: 12) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(page.color)
                                .font(.system(size: 16))
                            
                            Text(tip)
                                .font(.system(size: 16))
                                .foregroundColor(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
                .padding(.horizontal, 40)
                .padding(.top, 20)
            }
            .padding(.vertical, 20)
        }
        .onAppear {
            isAnimating = true
        }
    }
}

// Preview
struct TutorialView_Previews: PreviewProvider {
    static var previews: some View {
        TutorialView()
    }
} 