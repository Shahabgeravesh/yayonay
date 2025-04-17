import SwiftUI
import PhotosUI

struct EditProfileView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var userManager: UserManager
    
    @State private var username: String
    @State private var bio: String
    @State private var selectedImage: UIImage?
    @State private var imageSelection: PhotosPickerItem? = nil
    @State private var selectedInterests: Set<String>
    
    init(userManager: UserManager) {
        self.userManager = userManager
        // Initialize state variables
        _username = State(initialValue: userManager.currentUser?.username ?? "")
        _bio = State(initialValue: userManager.currentUser?.bio ?? "")
        _selectedInterests = State(initialValue: Set(userManager.currentUser?.topInterests ?? []))
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Profile Image Section
                    profileImageSection
                    
                    // Input Fields Section
                    inputFieldsSection
                    
                    // Interests Section
                    interestsSection
                }
                .padding()
            }
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                toolbarItems
            }
            .onChange(of: imageSelection) { newItem in
                handleImageSelection(newItem)
            }
        }
    }
    
    private var profileImageSection: some View {
        PhotosPicker(selection: $imageSelection,
                    matching: .images,
                    photoLibrary: .shared()) {
            profileImageContent
        }
    }
    
    private var profileImageContent: some View {
        Group {
            if let selectedImage = selectedImage {
                Image(uiImage: selectedImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else if let imageURL = userManager.currentUser?.imageURL {
                AsyncImage(url: URL(string: imageURL)) { phase in
                    switch phase {
                    case .empty:
                        Image(systemName: "person.circle.fill")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .foregroundStyle(AppColor.accent)
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    case .failure:
                        Image(systemName: "person.circle.fill")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .foregroundStyle(AppColor.accent)
                    @unknown default:
                        Image(systemName: "person.circle.fill")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .foregroundStyle(AppColor.accent)
                    }
                }
            } else {
                Image(systemName: "person.circle.fill")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .foregroundStyle(AppColor.accent)
            }
        }
        .frame(width: 120, height: 120)
        .clipShape(Circle())
        .overlay(
            Circle()
                .stroke(AppColor.gradient, lineWidth: 2)
        )
    }
    
    private var inputFieldsSection: some View {
        VStack(spacing: 16) {
            // Username Field
            AuthTextField(
                title: "Username",
                icon: "person",
                text: $username
            )
            
            // Bio Field
            VStack(alignment: .leading, spacing: 8) {
                Text("Bio")
                    .font(AppFont.medium(14))
                    .foregroundStyle(AppColor.secondaryText)
                
                TextEditor(text: $bio)
                    .frame(height: 100)
                    .padding(8)
                    .background(AppColor.secondaryBackground)
                    .cornerRadius(12)
            }
        }
    }
    
    private var interestsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Interests")
                .font(AppFont.medium(14))
                .foregroundStyle(AppColor.secondaryText)
            
            FlowLayout(spacing: 8) {
                ForEach(availableInterests, id: \.self) { interest in
                    interestButton(interest)
                }
            }
        }
    }
    
    private func interestButton(_ interest: String) -> some View {
        Button(action: { toggleInterest(interest) }) {
            Text(interest)
                .font(AppFont.medium(14))
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    Group {
                        if selectedInterests.contains(interest) {
                            AppColor.gradient
                        } else {
                            Color.gray.opacity(0.1)
                        }
                    }
                )
                .foregroundStyle(selectedInterests.contains(interest) ?
                                Color.white :
                                AppColor.accent)
        }
    }
    
    private var toolbarItems: some ToolbarContent {
        Group {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    dismiss()
                }
                .foregroundStyle(AppColor.text)
            }
            
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    saveProfile()
                }
                .fontWeight(.semibold)
                .foregroundStyle(AppColor.accent)
                .disabled(username.isEmpty)
            }
        }
    }
    
    private func toggleInterest(_ interest: String) {
        if selectedInterests.contains(interest) {
            selectedInterests.remove(interest)
        } else {
            selectedInterests.insert(interest)
        }
    }
    
    private func saveProfile() {
        userManager.updateProfile(
            username: username,
            image: selectedImage,
            bio: bio,
            interests: Array(selectedInterests)
        )
        dismiss()
    }
    
    private func handleImageSelection(_ newItem: PhotosPickerItem?) {
        Task {
            if let data = try? await newItem?.loadTransferable(type: Data.self),
               let image = UIImage(data: data) {
                await MainActor.run {
                    selectedImage = image
                }
            }
        }
    }
    
    private let availableInterests = [
        "Food", "Drinks", "Sports", "Travel", "Art",
        "Music", "Movies", "Books", "Technology", "Fashion"
    ]
} 