import SwiftUI
import FirebaseFirestore
import FirebaseAuth
import PhotosUI

struct ProfileView: View {
    @EnvironmentObject var userManager: UserManager
    @State private var showImagePicker = false
    @State private var showEditProfile = false
    @State private var selectedImage: UIImage?
    @State private var showSignOutAlert = false
    @State private var imageSelection: PhotosPickerItem? = nil
    @State private var showingEditProfile = false
    @State private var showingShareSheet = false
    @State private var showChangePassword = false
    @State private var showNotificationPreferences = false
    @State private var showSettingsSheet = false
    
    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 32) {
                    // Profile Image
                    PhotosPicker(selection: $imageSelection,
                                 matching: .images,
                                 photoLibrary: .shared()) {
                        profileImage
                    }
                    .frame(width: 140, height: 140)
                    .padding(.top, 40)
                    .overlay(
                        Circle()
                            .fill(AppColor.gradient)
                            .frame(width: 36, height: 36)
                            .overlay(
                                Image(systemName: "camera.fill")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundStyle(.white)
                            )
                            .offset(x: 4, y: 4),
                        alignment: .bottomTrailing
                    )

                    // Stats Row (Votes and Last Vote)
                    HStack(spacing: 32) {
                        VStack(spacing: 8) {
                            Text("\(userManager.currentUser?.votesCount ?? 0)")
                                .font(AppFont.bold(24))
                                .foregroundStyle(AppColor.text)
                            Text("Votes")
                                .font(AppFont.regular(14))
                                .foregroundStyle(AppColor.secondaryText)
                        }
                        .frame(maxWidth: .infinity)
                        
                        VStack(spacing: 8) {
                            if let user = userManager.currentUser {
                                Text(formatDate(user.lastVoteDate))
                                    .font(AppFont.bold(20))
                                    .foregroundStyle(AppColor.text)
                            } else {
                                Text("-")
                                    .font(AppFont.bold(20))
                                    .foregroundStyle(AppColor.text)
                            }
                            Text("Last vote")
                                .font(AppFont.regular(14))
                                .foregroundStyle(AppColor.secondaryText)
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .padding(.horizontal, 32)

                    // Username
                    Text(userManager.currentUser?.username ?? "")
                        .font(AppFont.bold(24))
                        .foregroundStyle(AppColor.text)
                        .padding(.top, 8)

                    // Top Interests
                    if let interests = userManager.currentUser?.topInterests, !interests.isEmpty {
                        let topInterests = interests.prefix(3).joined(separator: ", ")
                        Text("Top interests: \(topInterests)")
                            .font(AppFont.regular(16))
                            .foregroundStyle(Color.blue)
                            .padding(.top, 4)
                    }

                    // Invite Button
                    Button(action: { showingShareSheet = true }) {
                        Text("Invite others to vote")
                            .font(AppFont.bold(18))
                            .foregroundStyle(.white)
                            .frame(height: 56)
                            .frame(maxWidth: .infinity)
                            .background(AppColor.gradient)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                    .padding(.horizontal, 32)
                    .padding(.top, 24)

                    // Settings List
                    VStack(spacing: 16) {
                        Button(action: { showSettingsSheet = true }) {
                            HStack {
                                Text("Settings and security")
                                    .font(AppFont.regular(16))
                                    .foregroundStyle(AppColor.text)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 14))
                                    .foregroundStyle(AppColor.secondaryText)
                            }
                            .padding(.vertical, 16)
                            .padding(.horizontal, 20)
                            .background(AppColor.secondaryBackground)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                        }
                        Button(action: { showNotificationPreferences = true }) {
                            HStack {
                                Text("Notification preferences")
                                    .font(AppFont.regular(16))
                                    .foregroundStyle(AppColor.text)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 14))
                                    .foregroundStyle(AppColor.secondaryText)
                            }
                            .padding(.vertical, 16)
                            .padding(.horizontal, 20)
                            .background(AppColor.secondaryBackground)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                        }
                        Button(action: { /* Privacy and support action */ }) {
                            HStack {
                                Text("Privacy and support")
                                    .font(AppFont.regular(16))
                                    .foregroundStyle(AppColor.text)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 14))
                                    .foregroundStyle(AppColor.secondaryText)
                            }
                            .padding(.vertical, 16)
                            .padding(.horizontal, 20)
                            .background(AppColor.secondaryBackground)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                        }
                    }
                    .padding(.horizontal, 32)
                    .padding(.top, 24)

                    Spacer(minLength: 16)

                    // Sign Out Button
                    Button(action: { showSignOutAlert = true }) {
                        HStack {
                            Image(systemName: "rectangle.portrait.and.arrow.right")
                                .font(.system(size: 16))
                            Text("Sign Out")
                                .font(AppFont.regular(16))
                        }
                        .foregroundStyle(Color.red)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.red.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .padding(.horizontal, 32)
                    .padding(.top, 8)
                    .padding(.bottom, 16)
                }
            }
            .background(AppColor.background)
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showSettingsSheet) {
                NavigationStack {
                    List {
                        Section {
                            Button(action: { 
                                showSettingsSheet = false
                                showEditProfile = true
                            }) {
                                HStack {
                                    Text("Edit Profile")
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 14))
                                        .foregroundStyle(AppColor.secondaryText)
                                }
                            }
                            Button(action: { 
                                showSettingsSheet = false
                                showChangePassword = true
                            }) {
                                HStack {
                                    Text("Change Password")
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 14))
                                        .foregroundStyle(AppColor.secondaryText)
                                }
                            }
                        }
                    }
                    .navigationTitle("Settings and Security")
                    .navigationBarTitleDisplayMode(.inline)
                }
            }
            .sheet(isPresented: $showEditProfile) {
                EditProfileView(userManager: userManager)
            }
            .sheet(isPresented: $showingShareSheet) {
                if let inviteLink = createInviteLink() {
                    ShareSheet(activityItems: [
                        "\(userManager.currentUser?.username ?? "Someone") is inviting you to vote on YayoNay!",
                        inviteLink
                    ])
                }
            }
            .sheet(isPresented: $showChangePassword) {
                ChangePasswordView(userManager: userManager)
            }
            .sheet(isPresented: $showNotificationPreferences) {
                NotificationPreferencesView()
            }
            .onChange(of: imageSelection) { oldValue, newValue in
                Task {
                    if let data = try? await newValue?.loadTransferable(type: Data.self),
                       let image = UIImage(data: data) {
                        await MainActor.run {
                            selectedImage = image
                            userManager.updateProfile(
                                username: userManager.currentUser?.username ?? "",
                                image: image,
                                interests: userManager.currentUser?.topInterests
                            )
                        }
                    }
                }
            }
            .alert("Sign Out", isPresented: $showSignOutAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Sign Out", role: .destructive) {
                    userManager.signOut()
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
    
    private var profileImage: some View {
        Group {
            if let imageURL = userManager.currentUser?.imageURL {
                AsyncImage(url: URL(string: imageURL)) { phase in
                    switch phase {
                    case .empty:
                        defaultProfileImage
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    case .failure:
                        defaultProfileImage
                    @unknown default:
                        defaultProfileImage
                    }
                }
            } else {
                defaultProfileImage
            }
        }
        .frame(width: 140, height: 140)
        .clipShape(Circle())
        .overlay(
            Circle()
                .stroke(.white, lineWidth: 4)
        )
        .shadow(radius: 10)
    }
    
    private var defaultProfileImage: some View {
        Image(systemName: "person.circle.fill")
            .resizable()
            .aspectRatio(contentMode: .fit)
            .foregroundStyle(AppColor.accent)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        return formatter.string(from: date)
    }
    
    private func createInviteLink() -> String? {
        // Implement your invite link generation logic here
        return "https://yayonay.app/invite/\(userManager.currentUser?.id ?? "")"
    }
}

struct StatItem: View {
    let icon: String
    let value: Int
    let label: String
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundStyle(AppColor.gradient)
            
            Text("\(value)")
                .font(AppFont.bold(24))
                .foregroundStyle(AppColor.text)
            
            Text(label)
                .font(AppFont.regular(14))
                .foregroundStyle(AppColor.secondaryText)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(AppColor.secondaryBackground)
        .cornerRadius(16)
    }
}

struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let sizes = subviews.map { $0.sizeThatFits(.unspecified) }
        return arrangeSubviews(sizes: sizes, proposal: proposal).size
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let sizes = subviews.map { $0.sizeThatFits(.unspecified) }
        let offsets = arrangeSubviews(sizes: sizes, proposal: proposal).offsets
        
        for (offset, subview) in zip(offsets, subviews) {
            subview.place(at: bounds.origin.applying(.init(translationX: offset.x, y: offset.y)), proposal: .unspecified)
        }
    }
    
    private func arrangeSubviews(sizes: [CGSize], proposal: ProposedViewSize) -> (offsets: [CGPoint], size: CGSize) {
        guard let containerWidth = proposal.width else { return ([], .zero) }
        
        var offsets: [CGPoint] = []
        var currentPosition = CGPoint.zero
        var maxHeight: CGFloat = 0
        var currentRowHeight: CGFloat = 0
        
        for size in sizes {
            if currentPosition.x + size.width > containerWidth {
                currentPosition.x = 0
                currentPosition.y += currentRowHeight + spacing
                currentRowHeight = 0
            }
            
            offsets.append(currentPosition)
            currentPosition.x += size.width + spacing
            currentRowHeight = max(currentRowHeight, size.height)
            maxHeight = max(maxHeight, currentPosition.y + size.height)
        }
        
        return (offsets, CGSize(width: containerWidth, height: maxHeight))
    }
}

#Preview {
    ProfileView()
}
