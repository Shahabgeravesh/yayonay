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
            ScrollView {
                VStack(spacing: 0) {
                    // Profile Header
                    headerSection
                        .padding(.top)
                    
                    // Stats Section
                    statsSection
                        .padding(.top, 24)
                    
                    // Interests Section
                    if let interests = userManager.currentUser?.topInterests, !interests.isEmpty {
                        interestsSection(interests: interests)
                            .padding(.top, 24)
                    }
                    
                    // Recent Activity
                    recentActivitySection
                        .padding(.top, 24)
                }
                .padding(.horizontal)
            }
            .background(AppColor.background)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button(action: { showEditProfile = true }) {
                            Label("Edit Profile", systemImage: "pencil")
                        }
                        
                        Button(role: .destructive, action: { showSignOutAlert = true }) {
                            Label("Sign Out", systemImage: "arrow.right.square")
                        }
                    } label: {
                        if let imageData = userManager.currentUser?.imageData,
                           let data = Data(base64Encoded: imageData),
                           let uiImage = UIImage(data: data) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 32, height: 32)
                                .clipShape(Circle())
                        } else {
                            defaultProfileImage
                                .frame(width: 32, height: 32)
                                .clipShape(Circle())
                        }
                    }
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
            .onChange(of: imageSelection) { newItem in
                Task {
                    if let data = try? await newItem?.loadTransferable(type: Data.self),
                       let image = UIImage(data: data) {
                        await MainActor.run {
                            selectedImage = image
                            // Update profile immediately with current username and bio
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
    
    private var headerSection: some View {
        VStack(spacing: 16) {
            // Profile Image
            PhotosPicker(selection: $imageSelection,
                        matching: .images,
                        photoLibrary: .shared()) {
                profileImage
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
            .appShadow()
            
            // Username and Bio
            VStack(spacing: 4) {
                Text(userManager.currentUser?.username ?? "")
                    .font(AppFont.bold(24))
                    .foregroundStyle(AppColor.text)
                
                if let bio = userManager.currentUser?.bio, !bio.isEmpty {
                    Text(bio)
                        .font(AppFont.regular(16))
                        .foregroundStyle(AppColor.secondaryText)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
            }
            
            // Action Buttons
            HStack(spacing: 20) {
                Button(action: { showEditProfile = true }) {
                    Label("Edit Profile", systemImage: "pencil")
                        .font(.subheadline)
                        .foregroundColor(.blue)
                }
                
                Button(action: { showingShareSheet = true }) {
                    Label("Invite Others", systemImage: "person.badge.plus")
                        .font(.subheadline)
                        .foregroundColor(.blue)
                }
            }
            .padding(.top, 8)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(15)
        .shadow(radius: 2)
    }
    
    private var profileImage: some View {
        Group {
            if let imageData = userManager.currentUser?.imageData,
               let data = Data(base64Encoded: imageData),
               let uiImage = UIImage(data: data) {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                defaultProfileImage
            }
        }
        .frame(width: 120, height: 120)
        .clipShape(Circle())
        .overlay(
            Circle()
                .stroke(AppColor.gradient, lineWidth: 2)
        )
    }
    
    private var defaultProfileImage: some View {
        Image(systemName: "person.circle.fill")
            .resizable()
            .aspectRatio(contentMode: .fit)
            .foregroundStyle(AppColor.accent)
    }
    
    private var statsSection: some View {
        HStack(spacing: 30) {
            VStack {
                Text("\(userManager.currentUser?.votesCount ?? 0)")
                    .font(.title2)
                    .bold()
                Text("Votes")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            VStack {
                Text("\(userManager.currentUser?.recentActivity.count ?? 0)")
                    .font(.title2)
                    .bold()
                Text("Activity")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(15)
        .shadow(radius: 2)
    }
    
    private func interestsSection(interests: [String]) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Interests")
                .font(AppFont.semibold(18))
                .foregroundStyle(AppColor.text)
            
            FlowLayout(spacing: 8) {
                ForEach(interests, id: \.self) { interest in
                    Text(interest)
                        .font(AppFont.medium(14))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(
                            Capsule()
                                .fill(AppColor.gradient.opacity(0.1))
                        )
                        .foregroundStyle(AppColor.accent)
                }
            }
        }
        .padding(20)
        .glassmorphic()
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .appShadow()
    }
    
    private var recentActivitySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Recent Activity")
                .font(AppFont.bold(18))
                .foregroundStyle(AppColor.text)
            
            if let activities = userManager.currentUser?.recentActivity,
               !activities.isEmpty {
                ForEach(activities.prefix(5), id: \.timestamp) { activity in
                    HStack {
                        Circle()
                            .fill(AppColor.accent)
                            .frame(width: 8, height: 8)
                        
                        Text(activity.type.capitalized)
                            .font(AppFont.medium(16))
                        
                        Spacer()
                        
                        Text(activity.timestamp, style: .relative)
                            .font(AppFont.regular(14))
                            .foregroundStyle(AppColor.secondaryText)
                    }
                }
            } else {
                Text("No recent activity")
                    .font(AppFont.regular(16))
                    .foregroundStyle(AppColor.secondaryText)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 32)
            }
        }
        .padding(20)
        .glassmorphic()
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .appShadow()
    }
    
    private func createInviteLink() -> URL? {
        guard let userId = userManager.currentUser?.id,
              let username = userManager.currentUser?.username else { return nil }
        
        // Create a simple invite link with the user's ID and message
        let baseURL = "https://yayonay.app/invite"
        let inviteMessage = "\(username) is inviting you to vote on YayoNay!"
        let encodedMessage = inviteMessage.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let inviteURL = "\(baseURL)?ref=\(userId)&message=\(encodedMessage)"
        
        return URL(string: inviteURL)
    }
}

struct StatItem: View {
    let value: Int
    let label: String
    
    var body: some View {
        VStack(spacing: 4) {
            Text("\(value)")
                .font(AppFont.bold(24))
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