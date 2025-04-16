import SwiftUI
import PhotosUI

struct OnboardingView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var userManager: UserManager
    @State private var username = ""
    @State private var bio = ""
    @State private var selectedImage: UIImage?
    @State private var selectedInterests: Set<String> = []
    @State private var showImagePicker = false
    @State private var currentStep = 0
    @State private var imageSelection: PhotosPickerItem? = nil
    
    let availableInterests = [
        "Food", "Drinks", "Sports", "Travel", "Art", 
        "Music", "Movies", "Books", "Technology", "Fashion"
    ]
    
    var body: some View {
        NavigationStack {
            TabView(selection: $currentStep) {
                // Step 1: Profile Picture & Username
                VStack(spacing: 24) {
                    Text("Set up your profile")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Choose a profile picture and username")
                        .foregroundStyle(.secondary)
                    
                    // Profile Image Button
                    PhotosPicker(selection: $imageSelection,
                               matching: .images,
                               photoLibrary: .shared()) {
                        if let image = selectedImage {
                            Image(uiImage: image)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 120, height: 120)
                                .clipShape(Circle())
                                .overlay(
                                    Circle()
                                        .stroke(AppColor.gradient, lineWidth: 2)
                                )
                        } else {
                            Image(systemName: "person.circle.fill")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 120, height: 120)
                                .foregroundColor(.accentColor)
                        }
                    }
                    .overlay(
                        Circle()
                            .fill(AppColor.gradient)
                            .frame(width: 32, height: 32)
                            .overlay(
                                Image(systemName: "camera.fill")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundStyle(.white)
                            )
                            .offset(x: 4, y: 4),
                        alignment: .bottomTrailing
                    )
                    
                    TextField("Username", text: $username)
                        .textContentType(.username)
                        .autocapitalization(.none)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                    
                    Spacer()
                    
                    Button("Next") {
                        withAnimation {
                            currentStep = 1
                        }
                    }
                    .buttonStyle(.primary)
                    .disabled(username.isEmpty)
                }
                .padding()
                .tag(0)
                
                // Step 2: Bio
                VStack(spacing: 24) {
                    Text("Add your bio")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Tell others about yourself")
                        .foregroundStyle(.secondary)
                    
                    TextEditor(text: $bio)
                        .frame(height: 120)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                    
                    Spacer()
                    
                    Button("Next") {
                        withAnimation {
                            currentStep = 2
                        }
                    }
                    .buttonStyle(.primary)
                }
                .padding()
                .tag(1)
                
                // Step 3: Interests
                VStack(spacing: 24) {
                    Text("Select your interests")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Choose topics you're interested in")
                        .foregroundStyle(.secondary)
                    
                    ScrollView {
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: 12) {
                            ForEach(availableInterests, id: \.self) { interest in
                                InterestToggle(
                                    interest: interest,
                                    isSelected: selectedInterests.contains(interest),
                                    action: {
                                        if selectedInterests.contains(interest) {
                                            selectedInterests.remove(interest)
                                        } else {
                                            selectedInterests.insert(interest)
                                        }
                                    }
                                )
                            }
                        }
                    }
                    
                    Spacer()
                    
                    Button("Complete Setup") {
                        createProfile()
                    }
                    .buttonStyle(.primary)
                }
                .padding()
                .tag(2)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .onChange(of: imageSelection) { newItem in
                Task {
                    if let data = try? await newItem?.loadTransferable(type: Data.self),
                       let image = UIImage(data: data) {
                        await MainActor.run {
                            selectedImage = image
                        }
                    }
                }
            }
            .overlay {
                if userManager.isLoading {
                    ProgressView()
                        .scaleEffect(1.5)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.black.opacity(0.2))
                }
            }
            .alert("Error", isPresented: .constant(userManager.error != nil)) {
                Button("OK") { userManager.error = nil }
            } message: {
                if let error = userManager.error {
                    Text(error.localizedDescription)
                }
            }
        }
    }
    
    private func createProfile() {
        userManager.updateProfile(
            username: username,
            image: selectedImage,
            bio: bio,
            interests: Array(selectedInterests)
        )
    }
}

struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .fontWeight(.semibold)
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.accentColor)
            .foregroundColor(.white)
            .cornerRadius(12)
            .opacity(configuration.isPressed ? 0.8 : 1)
    }
}

extension ButtonStyle where Self == PrimaryButtonStyle {
    static var primary: PrimaryButtonStyle { PrimaryButtonStyle() }
} 