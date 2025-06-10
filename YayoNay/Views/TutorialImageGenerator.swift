import SwiftUI

struct TutorialImageGenerator {
    func generateWelcomeImage() -> some View {
        VStack(spacing: 20) {
            Image(systemName: "hand.wave.fill")
                .font(.system(size: 60))
                .foregroundColor(.blue)
                .padding()
            
            Text("Welcome to YayoNay")
                .font(.title)
                .fontWeight(.bold)
            
            Text("Swipe to vote and share your opinions!")
                .font(.body)
                .multilineTextAlignment(.center)
                .padding()
            
            Image(systemName: "arrow.up.arrow.down")
                .font(.system(size: 40))
                .foregroundColor(.blue)
                .padding()
        }
        .padding()
    }
    
    func generateHomeImage() -> some View {
        VStack(spacing: 20) {
            Image(systemName: "house.fill")
                .font(.system(size: 60))
                .foregroundColor(.blue)
                .padding()
            
            Text("Home")
                .font(.title)
                .fontWeight(.bold)
            
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Image(systemName: "arrow.up.circle.fill")
                        .foregroundColor(.green)
                    Text("Swipe up for YAY")
                }
                HStack {
                    Image(systemName: "arrow.down.circle.fill")
                        .foregroundColor(.red)
                    Text("Swipe down for NAY")
                }
            }
            .padding()
        }
        .padding()
    }
    
    func generateCategoriesImage() -> some View {
        VStack(spacing: 20) {
            Image(systemName: "list.bullet")
                .font(.system(size: 60))
                .foregroundColor(.blue)
                .padding()
            
            Text("Categories")
                .font(.title)
                .fontWeight(.bold)
            
            Text("Browse and vote in different categories")
                .font(.body)
                .multilineTextAlignment(.center)
                .padding()
            
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Image(systemName: "sportscourt")
                        .foregroundColor(.blue)
                    Text("Sports")
                }
                HStack {
                    Image(systemName: "music.note")
                        .foregroundColor(.blue)
                    Text("Music")
                }
                HStack {
                    Image(systemName: "film")
                        .foregroundColor(.blue)
                    Text("Movies")
                }
            }
            .padding()
        }
        .padding()
    }
    
    func generateStatsImage() -> some View {
        VStack(spacing: 20) {
            Image(systemName: "chart.bar.fill")
                .font(.system(size: 60))
                .foregroundColor(.blue)
                .padding()
            
            Text("Statistics")
                .font(.title)
                .fontWeight(.bold)
            
            Text("Track your voting history and trends")
                .font(.body)
                .multilineTextAlignment(.center)
                .padding()
            
            VStack(spacing: 10) {
                HStack {
                    Text("YAY: 75%")
                        .foregroundColor(.green)
                    Spacer()
                    Text("NAY: 25%")
                        .foregroundColor(.red)
                }
                .padding()
                
                ProgressView(value: 0.75)
                    .tint(.green)
            }
            .padding()
        }
        .padding()
    }
    
    func generateProfileImage() -> some View {
        VStack(spacing: 20) {
            Image(systemName: "person.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(.blue)
                .padding()
            
            Text("Profile")
                .font(.title)
                .fontWeight(.bold)
            
            Text("Customize your profile and settings")
                .font(.body)
                .multilineTextAlignment(.center)
                .padding()
            
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Image(systemName: "person.fill")
                    Text("Username")
                }
                HStack {
                    Image(systemName: "envelope.fill")
                    Text("Email")
                }
                HStack {
                    Image(systemName: "gear")
                    Text("Settings")
                }
            }
            .padding()
        }
        .padding()
    }
    
    func generateSharingImage() -> some View {
        VStack(spacing: 20) {
            Image(systemName: "square.and.arrow.up.fill")
                .font(.system(size: 60))
                .foregroundColor(.blue)
                .padding()
            
            Text("Share")
                .font(.title)
                .fontWeight(.bold)
            
            Text("Share your votes with friends")
                .font(.body)
                .multilineTextAlignment(.center)
                .padding()
            
            HStack(spacing: 20) {
                Image(systemName: "message.fill")
                    .font(.system(size: 30))
                Image(systemName: "square.and.arrow.up")
                    .font(.system(size: 30))
                Image(systemName: "link")
                    .font(.system(size: 30))
            }
            .padding()
        }
        .padding()
    }
    
    func generateReadyImage() -> some View {
        VStack(spacing: 20) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(.green)
                .padding()
            
            Text("Ready to Go!")
                .font(.title)
                .fontWeight(.bold)
            
            Text("Start voting and sharing your opinions")
                .font(.body)
                .multilineTextAlignment(.center)
                .padding()
            
            Button("Get Started") {
                // Action will be handled by the parent view
            }
            .buttonStyle(.borderedProminent)
            .padding()
        }
        .padding()
    }
}

struct TutorialImageGeneratorView: View {
    var body: some View {
        VStack {
            // Welcome Image
            TutorialImageGenerator().generateWelcomeImage()
                .frame(width: 300, height: 600)
                .background(Color.white)
                .cornerRadius(20)
                .shadow(radius: 10)
            
            // Home Image
            TutorialImageGenerator().generateHomeImage()
                .frame(width: 300, height: 600)
                .background(Color.white)
                .cornerRadius(20)
                .shadow(radius: 10)
            
            // Categories Image
            TutorialImageGenerator().generateCategoriesImage()
                .frame(width: 300, height: 600)
                .background(Color.white)
                .cornerRadius(20)
                .shadow(radius: 10)
            
            // Stats Image
            TutorialImageGenerator().generateStatsImage()
                .frame(width: 300, height: 600)
                .background(Color.white)
                .cornerRadius(20)
                .shadow(radius: 10)
            
            // Profile Image
            TutorialImageGenerator().generateProfileImage()
                .frame(width: 300, height: 600)
                .background(Color.white)
                .cornerRadius(20)
                .shadow(radius: 10)
            
            // Sharing Image
            TutorialImageGenerator().generateSharingImage()
                .frame(width: 300, height: 600)
                .background(Color.white)
                .cornerRadius(20)
                .shadow(radius: 10)
            
            // Ready Image
            TutorialImageGenerator().generateReadyImage()
                .frame(width: 300, height: 600)
                .background(Color.white)
                .cornerRadius(20)
                .shadow(radius: 10)
        }
    }
}

struct CategoryRow: View {
    let name: String
    let icon: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.blue)
            Text(name)
            Spacer()
            Image(systemName: "chevron.right")
                .foregroundColor(.gray)
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(10)
    }
}

struct StatRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
            Spacer()
            Text(value)
                .fontWeight(.bold)
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(10)
    }
}

struct ProfileRow: View {
    let icon: String
    let title: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.blue)
            Text(title)
            Spacer()
            Image(systemName: "chevron.right")
                .foregroundColor(.gray)
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(10)
    }
}

struct SocialIcon: View {
    let name: String
    
    var body: some View {
        Image(systemName: "circle.fill")
            .font(.system(size: 40))
            .foregroundColor(.blue.opacity(0.3))
    }
}

struct TutorialImageGenerator_Previews: PreviewProvider {
    static var previews: some View {
        TutorialImageGeneratorView()
    }
} 