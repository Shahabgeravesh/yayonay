// MARK: - Onboarding View
// This view provides the initial user experience when first launching the app, including:
// 1. Welcome screens and app introduction
// 2. User registration and login options
// 3. Initial preferences and interests selection
// 4. Tutorial and app usage guidance

import SwiftUI
import PhotosUI
import FirebaseAuth

struct OnboardingView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var userManager: UserManager
    @State private var username = ""
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
                    
                    Text("Choose a profile picture")
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
                    
                    // Username display (read-only)
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Username")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        
                        Text(username.isEmpty ? "Loading..." : username)
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                    }
                    
                    Spacer()
                    
                    Button("Next") {
                        withAnimation {
                            currentStep = 1
                        }
                    }
                    .buttonStyle(.primary)
                }
                .padding()
                .tag(0)
                .onAppear {
                    // Set username from auth provider
                    if let displayName = userManager.currentUser?.username, !displayName.isEmpty {
                        username = displayName
                    } else if let email = userManager.currentUser?.email {
                        // Use email username part if no display name
                        let emailParts = email.split(separator: "@")
                        if !emailParts.isEmpty {
                            username = String(emailParts[0])
                        }
                    }
                    
                    // If still empty, try to get from auth user directly
                    if username.isEmpty, let authUser = Auth.auth().currentUser {
                        if let displayName = authUser.displayName, !displayName.isEmpty {
                            username = displayName
                        } else if let email = authUser.email {
                            let emailParts = email.split(separator: "@")
                            if !emailParts.isEmpty {
                                username = String(emailParts[0])
                            }
                        }
                    }
                }
                
                // Step 2: Interests
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
                .tag(1)
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