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
                            .frame(height: 180)
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
                            .offset(y: 100)
                            .overlay(
                                Circle()
                                    .fill(AppColor.gradient)
                                    .frame(width: 36, height: 36)
                                    .overlay(
                                        Image(systemName: "camera.fill")
                                            .font(.system(size: 16, weight: .bold))
                                            .foregroundStyle(.white)
                                    )
                                    .offset(x: 4, y: 104),
                                alignment: .bottomTrailing
                            )
                        }
                    }
                    
                    // Profile Info Section
                    VStack(spacing: 24) {
                        // Username and Bio
                        VStack(spacing: 12) {
                            Text(userManager.currentUser?.username ?? "")
                                .font(AppFont.bold(32))
                                .foregroundStyle(AppColor.text)
                            
                            if let bio = userManager.currentUser?.bio, !bio.isEmpty {
                                Text(bio)
                                    .font(AppFont.regular(16))
                                    .foregroundStyle(AppColor.secondaryText)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 32)
                            }
                        }
                        .padding(.top, 64)
                        
                        // Action Buttons
                        HStack(spacing: 16) {
                            Button(action: { showEditProfile = true }) {
                                HStack {
                                    Image(systemName: "pencil")
                                    Text("Edit Profile")
                                }
                                .font(AppFont.medium(15))
                                .foregroundStyle(AppColor.accent)
                                .frame(height: 44)
                                .frame(maxWidth: .infinity)
                                .background(AppColor.accent.opacity(0.1))
                                .clipShape(RoundedRectangle(cornerRadius: 22))
                            }
                            
                            Button(action: { showingShareSheet = true }) {
                                HStack {
                                    Image(systemName: "person.badge.plus")
                                    Text("Invite")
                                }
                                .font(AppFont.medium(15))
                                .foregroundStyle(.white)
                                .frame(height: 44)
                                .frame(maxWidth: .infinity)
                                .background(AppColor.gradient)
                                .clipShape(RoundedRectangle(cornerRadius: 22))
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
                        
                        Spacer()
                        
                        // Sign Out Button
                        Button(action: { showSignOutAlert = true }) {
                            HStack {
                                Image(systemName: "rectangle.portrait.and.arrow.right")
                                Text("Sign Out")
                            }
                            .font(AppFont.medium(15))
                            .foregroundStyle(.red)
                            .frame(height: 44)
                            .frame(maxWidth: .infinity)
                            .background(Color.red.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 22))
                        }
                        .padding(.horizontal, 32)
                        .padding(.bottom, 32)
                    }
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
            .onChange(of: imageSelection) { oldValue, newValue in
                Task {
                    if let data = try? await newValue?.loadTransferable(type: Data.self),
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
    
    private var statsSection: some View {
        VStack(spacing: 24) {
            // Stats Row
            HStack(spacing: 20) {
                StatItem(
                    icon: "checkmark.circle.fill",
                    value: userManager.currentUser?.votesCount ?? 0,
                    label: "Total Votes"
                )
                
                // Interests Display
                VStack(spacing: 8) {
                    Image(systemName: "star.fill")
                        .font(.system(size: 24))
                        .foregroundStyle(AppColor.gradient)
                    
                    if let interests = userManager.currentUser?.topInterests, !interests.isEmpty {
                        VStack(spacing: 4) {
                            ForEach(interests.prefix(3), id: \.self) { interest in
                                Text(interest)
                                    .font(AppFont.medium(14))
                                    .foregroundStyle(AppColor.text)
                            }
                            if interests.count > 3 {
                                Text("+\(interests.count - 3) more")
                                    .font(AppFont.regular(12))
                                    .foregroundStyle(AppColor.secondaryText)
                            }
                        }
                    } else {
                        Text("No interests")
                            .font(AppFont.regular(14))
                            .foregroundStyle(AppColor.secondaryText)
                    }
                    
                    Text("Interests")
                        .font(AppFont.regular(14))
                        .foregroundStyle(AppColor.secondaryText)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(AppColor.secondaryBackground)
                .cornerRadius(16)
            }
            
            // Last Vote Date
            if let lastVoteDate = userManager.currentUser?.lastVoteDate {
                HStack(spacing: 12) {
                    Image(systemName: "calendar")
                        .font(.system(size: 20))
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
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(AppColor.secondaryBackground)
                .cornerRadius(16)
            }
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 20)
        .background(AppColor.secondaryBackground)
        .cornerRadius(20)
    }
    
    private func interestsSection(interests: [String]) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Interests")
                .font(AppFont.bold(18))
                .foregroundStyle(AppColor.text)
            
            FlowLayout(spacing: 12) {
                ForEach(interests, id: \.self) { interest in
                    Text(interest)
                        .font(AppFont.medium(14))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(AppColor.gradient)
                        .foregroundStyle(.white)
                        .clipShape(Capsule())
                }
            }
        }
        .padding(20)
        .background(AppColor.secondaryBackground)
        .cornerRadius(20)
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
