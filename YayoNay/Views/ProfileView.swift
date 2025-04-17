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
    
    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    // Cover Image & Profile Section
                    ZStack(alignment: .top) {
                        // Cover Image
                        Rectangle()
                            .fill(AppColor.gradient)
                            .frame(height: 140)
                            .overlay {
                                Image(systemName: "camera.fill")
                                    .foregroundStyle(.white.opacity(0.7))
                                    .font(.system(size: 24))
                            }
                        
                        // Profile Content
                        VStack(spacing: 0) {
                            // Profile Image
                            PhotosPicker(selection: $imageSelection,
                                       matching: .images,
                                       photoLibrary: .shared()) {
                                profileImage
                            }
                            .offset(y: 80)
                            .overlay(
                                Circle()
                                    .fill(AppColor.gradient)
                                    .frame(width: 32, height: 32)
                                    .overlay(
                                        Image(systemName: "camera.fill")
                                            .font(.system(size: 14, weight: .bold))
                                            .foregroundStyle(.white)
                                    )
                                    .offset(x: 4, y: 84),
                                alignment: .bottomTrailing
                            )
                        }
                    }
                    
                    // Profile Info Section
                    VStack(spacing: 20) {
                        // Username and Bio
                        VStack(spacing: 8) {
                            Text(userManager.currentUser?.username ?? "")
                                .font(AppFont.bold(28))
                                .foregroundStyle(AppColor.text)
                            
                            if let bio = userManager.currentUser?.bio, !bio.isEmpty {
                                Text(bio)
                                    .font(AppFont.regular(16))
                                    .foregroundStyle(AppColor.secondaryText)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal)
                            }
                        }
                        .padding(.top, 64) // Account for profile image overlap
                        
                        // Action Buttons
                        VStack(spacing: 12) {
                            HStack(spacing: 16) {
                                Button(action: { showEditProfile = true }) {
                                    HStack {
                                        Image(systemName: "pencil")
                                        Text("Edit Profile")
                                    }
                                    .font(AppFont.medium(15))
                                    .foregroundStyle(AppColor.accent)
                                    .frame(height: 36)
                                    .frame(maxWidth: .infinity)
                                    .background(AppColor.accent.opacity(0.1))
                                    .clipShape(RoundedRectangle(cornerRadius: 18))
                                }
                                
                                Button(action: { showingShareSheet = true }) {
                                    HStack {
                                        Image(systemName: "person.badge.plus")
                                        Text("Invite")
                                    }
                                    .font(AppFont.medium(15))
                                    .foregroundStyle(.white)
                                    .frame(height: 36)
                                    .frame(maxWidth: .infinity)
                                    .background(AppColor.gradient)
                                    .clipShape(RoundedRectangle(cornerRadius: 18))
                                }
                            }
                            
                            Button(action: { showSignOutAlert = true }) {
                                HStack {
                                    Image(systemName: "rectangle.portrait.and.arrow.right")
                                    Text("Sign Out")
                                }
                                .font(AppFont.medium(15))
                                .foregroundStyle(.red)
                                .frame(height: 36)
                                .frame(maxWidth: .infinity)
                                .background(Color.red.opacity(0.1))
                                .clipShape(RoundedRectangle(cornerRadius: 18))
                            }
                        }
                        .padding(.horizontal, 32)
                        
                        // Stats Card
                        statsSection
                            .padding(.horizontal, 20)
                        
                        // Interests Section
                        if let interests = userManager.currentUser?.topInterests,
                           !interests.isEmpty {
                            interestsSection(interests: interests)
                                .padding(.horizontal, 20)
                        }
                    }
                    .padding(.vertical, 20)
                }
            }
            .background(AppColor.background)
            .navigationBarTitleDisplayMode(.inline)
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
            .onChange(of: imageSelection) { newItem in
                Task {
                    if let data = try? await newItem?.loadTransferable(type: Data.self),
                       let image = UIImage(data: data) {
                        await MainActor.run {
                            selectedImage = image
                            userManager.updateProfile(
                                username: userManager.currentUser?.username ?? "",
                                image: image,
                                bio: userManager.currentUser?.bio,
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
        .frame(width: 120, height: 120)
        .clipShape(Circle())
        .overlay(
            Circle()
                .stroke(.white, lineWidth: 4)
        )
        .shadow(radius: 8)
    }
    
    private var defaultProfileImage: some View {
        Image(systemName: "person.circle.fill")
            .resizable()
            .aspectRatio(contentMode: .fit)
            .foregroundStyle(AppColor.accent)
    }
    
    private var statsSection: some View {
        VStack(spacing: 24) {
            // Stats Row - Only Total Votes
            HStack {
                StatItem(
                    icon: "checkmark.circle.fill",
                    value: userManager.currentUser?.votesCount ?? 0,
                    label: "Total Votes"
                )
            }
            
            // Last Vote Date
            if let lastVoteDate = userManager.currentUser?.lastVoteDate {
                HStack(spacing: 12) {
                    Image(systemName: "calendar")
                        .font(.system(size: 18))
                        .foregroundStyle(AppColor.gradient)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Last Vote")
                            .font(AppFont.regular(14))
                            .foregroundStyle(AppColor.secondaryText)
                        
                        Text(formatDate(lastVoteDate))
                            .font(AppFont.medium(16))
                            .foregroundStyle(AppColor.text)
                    }
                    
                    Spacer()
                }
                .padding(.horizontal, 8)
            }
        }
        .padding(.vertical, 24)
        .padding(.horizontal, 32)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: Color.black.opacity(0.05), radius: 10, y: 5)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
    
    private func interestsSection(interests: [String]) -> some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Interests")
                .font(AppFont.bold(20))
                .foregroundStyle(AppColor.text)
            
            FlowLayout(spacing: 10) {
                ForEach(interests, id: \.self) { interest in
                    Text(interest)
                        .font(AppFont.medium(15))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(
                            Capsule()
                                .fill(AppColor.gradient.opacity(0.1))
                        )
                        .overlay(
                            Capsule()
                                .strokeBorder(AppColor.gradient.opacity(0.3), lineWidth: 1)
                        )
                        .foregroundStyle(AppColor.accent)
                }
            }
        }
        .padding(24)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: Color.black.opacity(0.05), radius: 10, y: 5)
    }
    
    private func createInviteLink() -> URL? {
        guard let userId = userManager.currentUser?.id,
              let username = userManager.currentUser?.username else { return nil }
        
        let baseURL = "https://yayonay.app/invite"
        let inviteMessage = "\(username) is inviting you to vote on YayoNay!"
        let encodedMessage = inviteMessage.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let inviteURL = "\(baseURL)?ref=\(userId)&message=\(encodedMessage)"
        
        return URL(string: inviteURL)
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
                .padding(.bottom, 4)
            
            Text("\(value)")
                .font(AppFont.bold(28))
                .foregroundStyle(AppColor.text)
            
            Text(label)
                .font(AppFont.regular(14))
                .foregroundStyle(AppColor.secondaryText)
        }
        .frame(maxWidth: .infinity)
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