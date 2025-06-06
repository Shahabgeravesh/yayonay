// MARK: - Subcategory Statistics View
// This view displays detailed statistics for a specific subcategory, including:
// 1. Voting trends and patterns
// 2. User engagement metrics
// 3. Historical voting data
// 4. Comparative analysis with other subcategories

import SwiftUI
import FirebaseFirestore
import FirebaseAuth
import Charts
import Photos

// Helper class for image saving
fileprivate class ImageSaver: NSObject {
    var completion: ((Error?) -> Void)?
    
    @objc func image(_ image: UIImage, didFinishSavingWithError error: Error?, contextInfo: UnsafeRawPointer) {
        completion?(error)
    }
}

struct AttributeVotes: Codable, Equatable {
    var yayCount: Int = 0
    var nayCount: Int = 0
    
    var totalVotes: Int { yayCount + nayCount }
    var yayPercentage: Double {
        totalVotes > 0 ? Double(yayCount) / Double(totalVotes) * 100 : 0
    }
    
    static func == (lhs: AttributeVotes, rhs: AttributeVotes) -> Bool {
        return lhs.yayCount == rhs.yayCount && lhs.nayCount == rhs.nayCount
    }
}

struct SubCategoryStatsView: View {
    @StateObject private var statsViewModel: SubCategoryStatsViewModel
    @StateObject private var categoryViewModel = CategoryViewModel()
    @State private var newComment = ""
    @State private var showShareSheet = false
    @State private var showResetConfirmation = false
    @State private var timeRemaining: TimeInterval = 0
    @State private var timer: Timer?
    @State private var showPhotoPermissionAlert = false
    @State private var showSaveErrorAlert = false
    @State private var errorMessage = ""
    @Environment(\.colorScheme) private var colorScheme
    
    // Timer state
    private class TimerState: ObservableObject {
        @Published var timeRemaining: TimeInterval = 0
        private var timer: Timer?
        
        func startTimer(nextVoteDate: Date) {
            stopTimer()
            timeRemaining = max(0, nextVoteDate.timeIntervalSince(Date()))
            
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
                    guard let self = self else { return }
                    self.timeRemaining = max(0, nextVoteDate.timeIntervalSince(Date()))
                }
            }
        }
        
        func stopTimer() {
            timer?.invalidate()
            timer = nil
        }
        
        deinit {
            stopTimer()
        }
    }
    
    @StateObject private var timerState = TimerState()
    
    init(subCategory: SubCategory) {
        print("🔍 DEBUG: Initializing SubCategoryStatsView")
        print("📊 DEBUG: Initial subcategory data:")
        print("   - Name: \(subCategory.name)")
        print("   - ID: \(subCategory.id)")
        print("   - Yay Count: \(subCategory.yayCount)")
        print("   - Nay Count: \(subCategory.nayCount)")
        print("   - Category ID: \(subCategory.categoryId)")
        _statsViewModel = StateObject(wrappedValue: SubCategoryStatsViewModel(subCategory: subCategory))
    }
    
    private var totalVotes: Int {
        let total = statsViewModel.currentSubCategory.yayCount + statsViewModel.currentSubCategory.nayCount
        print("📈 DEBUG: Calculating total votes")
        print("   - Current Yay: \(statsViewModel.currentSubCategory.yayCount)")
        print("   - Current Nay: \(statsViewModel.currentSubCategory.nayCount)")
        print("   - Total: \(total)")
        return total
    }
    
    private var yayPercentage: Double {
        let percentage = totalVotes > 0 ? Double(statsViewModel.currentSubCategory.yayCount) / Double(totalVotes) * 100 : 0
        print("🟢 DEBUG: Calculating Yay percentage: \(percentage)%")
        return percentage
    }
    
    private var nayPercentage: Double {
        let percentage = totalVotes > 0 ? Double(statsViewModel.currentSubCategory.nayCount) / Double(totalVotes) * 100 : 0
        print("🔴 DEBUG: Calculating Nay percentage: \(percentage)%")
        return percentage
    }
    
    private var formattedTimeRemaining: String {
        let hours = Int(timeRemaining) / 3600
        let minutes = Int(timeRemaining) / 60 % 60
        let seconds = Int(timeRemaining) % 60
        
        if hours > 0 {
            return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%02d:%02d", minutes, seconds)
        }
    }
    
    private func startCooldownTimer() {
        guard let lastVoteDate = statsViewModel.lastVoteDate else {
            print("DEBUG: No last vote date found, timer not started")
            return
        }
        
        let nextVoteDate = Calendar.current.date(byAdding: .day, value: 7, to: lastVoteDate) ?? Date()
        print("DEBUG: Starting timer with next vote date: \(nextVoteDate)")
        timerState.startTimer(nextVoteDate: nextVoteDate)
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Image and Name
                AsyncImage(url: URL(string: statsViewModel.currentSubCategory.imageURL)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                } placeholder: {
                    Color.gray.opacity(0.2)
                }
                .frame(height: 200)
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .onAppear {
                    print("🖼️ DEBUG: Loading image from URL: \(statsViewModel.currentSubCategory.imageURL)")
                }
                
                Text(statsViewModel.currentSubCategory.name)
                    .font(.title2)
                    .fontWeight(.semibold)
                
                // Overall Vote Stats
                VStack(spacing: 16) {
                    // Vote Distribution
                    HStack(spacing: 32) {
                        // Nay Stats
                        VStack(spacing: 4) {
                            Text("\(Int(nayPercentage))%")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.red)
                        }
                        .frame(maxWidth: .infinity)
                        
                        // Yay Stats
                        VStack(spacing: 4) {
                            Text("\(Int(yayPercentage))%")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.green)
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .padding(.top, 8)
                    
                    // Vote Bar
                    GeometryReader { geometry in
                        HStack(spacing: 2) {
                            // Nay portion
                            Rectangle()
                                .fill(Color.red.opacity(0.7))
                                .frame(width: geometry.size.width * CGFloat(nayPercentage / 100))
                            
                            // Yay portion
                            Rectangle()
                                .fill(Color.green.opacity(0.7))
                                .frame(width: geometry.size.width * CGFloat(yayPercentage / 100))
                        }
                    }
                    .frame(height: 12)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                    .padding(.top, 8)
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(16)
                .shadow(color: .black.opacity(0.1), radius: 5, y: 2)
                .padding(.horizontal)
                
                // Total Votes Card
                HStack(spacing: 8) {
                    Text("Total Votes")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.secondary)
                    
                    Text("\(totalVotes)")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.primary)
                        .onAppear {
                            print("📊 DEBUG: Displaying total votes in UI: \(totalVotes)")
                        }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color(.systemBackground))
                .clipShape(Capsule())
                .shadow(color: .black.opacity(0.05), radius: 2, y: 1)
                
                // Social Sharing Section
                VStack(spacing: 16) {
                    Text("Share")
                        .font(.headline)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            // Facebook
                            Button(action: {
                                shareToFacebook()
                            }) {
                                Image("iconfinder_facebook")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 24, height: 24)
                                    .padding(8)
                                    .background(Color(red: 0.23, green: 0.35, blue: 0.60).opacity(0.1))
                                    .foregroundColor(Color(red: 0.23, green: 0.35, blue: 0.60))
                                    .clipShape(Circle())
                            }
                            
                            // X (Twitter)
                            Button(action: {
                                shareToTwitter()
                            }) {
                                Image(systemName: "x.circle.fill")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 24, height: 24)
                                    .padding(8)
                                    .background(Color.black.opacity(0.1))
                                    .foregroundColor(.black)
                                    .clipShape(Circle())
                            }
                            
                            // Instagram
                            Button(action: {
                                shareToInstagram()
                            }) {
                                Image("iconfinder_instagram")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 24, height: 24)
                                    .padding(8)
                                    .background(Color(red: 0.83, green: 0.18, blue: 0.42).opacity(0.1))
                                    .foregroundColor(Color(red: 0.83, green: 0.18, blue: 0.42))
                                    .clipShape(Circle())
                            }
                            
                            // WhatsApp
                            Button(action: {
                                shareToWhatsApp()
                            }) {
                                Image(systemName: "message.circle.fill")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 24, height: 24)
                                    .padding(8)
                                    .background(Color(red: 0.18, green: 0.77, blue: 0.45).opacity(0.1))
                                    .foregroundColor(Color(red: 0.18, green: 0.77, blue: 0.45))
                                    .clipShape(Circle())
                            }
                            
                            // Telegram
                            Button(action: {
                                shareToTelegram()
                            }) {
                                Image(systemName: "paperplane.circle.fill")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 24, height: 24)
                                    .padding(8)
                                    .background(Color(red: 0.0, green: 0.7, blue: 1.0).opacity(0.1))
                                    .foregroundColor(Color(red: 0.0, green: 0.7, blue: 1.0))
                                    .clipShape(Circle())
                            }
                            
                            // LinkedIn
                            Button(action: {
                                shareToLinkedIn()
                            }) {
                                Image("iconfinder_linkedin")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 24, height: 24)
                                    .padding(8)
                                    .background(Color(red: 0.0, green: 0.47, blue: 0.71).opacity(0.1))
                                    .foregroundColor(Color(red: 0.0, green: 0.47, blue: 0.71))
                                    .clipShape(Circle())
                            }
                            
                            // TikTok
                            Button(action: {
                                shareToTikTok()
                            }) {
                                Image("iconfinder_tiktok")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 24, height: 24)
                                    .padding(8)
                                    .background(Color.black.opacity(0.1))
                                    .foregroundColor(.black)
                                    .clipShape(Circle())
                            }
                            
                            // More Options
                            Button(action: {
                                showShareSheet = true
                            }) {
                                Image(systemName: "ellipsis.circle.fill")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 24, height: 24)
                                    .padding(8)
                                    .background(Color.gray.opacity(0.1))
                                    .foregroundColor(.gray)
                                    .clipShape(Circle())
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.vertical)
                .background(Color(.systemBackground))
                .cornerRadius(12)
                .shadow(color: colorScheme == .dark ? .black.opacity(0.2) : .black.opacity(0.05),
                        radius: colorScheme == .dark ? 3 : 3,
                        y: colorScheme == .dark ? 1 : 1)
                
                // Sub-Questions Section
                if !statsViewModel.subQuestions.isEmpty {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Additional Questions")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        ForEach(statsViewModel.subQuestions) { question in
                            SubQuestionRow(question: question, onVote: { isYay in
                                statsViewModel.voteForSubQuestion(question, isYay: isYay)
                            }, viewModel: statsViewModel)
                        }
                    }
                    .padding(.horizontal)
                }
                
                // Comments Section
                VStack(alignment: .leading, spacing: 16) {
                    Text("Comments")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    TextField("Add a comment...", text: $newComment)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding(.horizontal)
                    
                    HStack {
                        Spacer()
                        Button(action: {
                            if !newComment.isEmpty {
                                print("💬 DEBUG: User added a new comment")
                                statsViewModel.addComment(newComment)
                                newComment = ""
                            }
                        }) {
                            Text("Post")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(newComment.isEmpty ? .gray : .blue)
                        }
                        .disabled(newComment.isEmpty)
                        .padding(.trailing)
                    }
                    
                    if !statsViewModel.comments.isEmpty {
                        ForEach(statsViewModel.comments) { comment in
                            VStack(alignment: .leading, spacing: 8) {
                                CommentRow(
                                    comment: comment,
                                    onLike: {
                                        statsViewModel.likeComment(comment)
                                    },
                                    onDelete: {
                                        statsViewModel.deleteComment(comment)
                                    },
                                    onReply: { replyText in
                                        print("DEBUG: Adding reply to comment: \(comment.id)")
                                        statsViewModel.addComment(replyText, parentId: comment.id)
                                    },
                                    viewModel: statsViewModel
                                )
                                .padding(.horizontal)
                                
                                // Display replies
                                if !comment.replies.isEmpty {
                                    VStack(alignment: .leading, spacing: 8) {
                                        ForEach(comment.replies) { reply in
                                            CommentRow(
                                                comment: reply,
                                                onLike: {
                                                    statsViewModel.likeComment(reply)
                                                },
                                                onDelete: {
                                                    statsViewModel.deleteComment(reply)
                                                },
                                                onReply: { replyText in
                                                    statsViewModel.addComment(replyText, parentId: comment.id)
                                                },
                                                viewModel: statsViewModel
                                            )
                                        }
                                    }
                                    .padding(.leading, 40)
                                }
                            }
                            .padding(.vertical, 8)
                            Divider()
                        }
                    } else {
                        Text("No comments yet")
                            .foregroundColor(.secondary)
                            .padding()
                    }
                }
                .padding(.top)
                
                // Update Vote Reset Button section
                VStack(spacing: 12) {
                    if let lastVoteDate = statsViewModel.lastVoteDate {
                        let nextVoteDate = Calendar.current.date(byAdding: .day, value: 7, to: lastVoteDate) ?? Date()
                        let canReset = timerState.timeRemaining <= 0
                        
                        Button(action: {
                            if canReset {
                                HapticManager.shared.buttonPress()
                                showResetConfirmation = true
                            }
                        }) {
                            HStack(spacing: 8) {
                                Image(systemName: canReset ? "arrow.clockwise.circle.fill" : "clock.fill")
                                    .font(.system(size: 18))
                                Text(canReset ? "Change My Vote" : "Time Remaining: \(formatTimeRemaining(timerState.timeRemaining))")
                                    .font(.system(size: 15, weight: .semibold))
                            }
                            .foregroundColor(canReset ? .white : .secondary)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(canReset ? Color.blue : Color.gray.opacity(0.2))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(canReset ? Color.blue : Color.gray.opacity(0.3), lineWidth: 1)
                            )
                            .shadow(color: canReset ? Color.blue.opacity(0.3) : Color.clear, radius: 4, x: 0, y: 2)
                        }
                        .disabled(!canReset)
                        .scaleEffect(canReset ? 1.0 : 0.95)
                        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: canReset)
                        
                        if !canReset {
                            Text("You voted on \(formatDate(lastVoteDate))")
                                .font(.system(size: 13))
                                .foregroundColor(.secondary)
                            
                            Text("You can change your vote on \(formatDate(nextVoteDate))")
                                .font(.system(size: 13))
                                .foregroundColor(.secondary)
                        }
                    } else {
                        // Show disabled button when no vote exists
                        Button(action: {}) {
                            HStack(spacing: 8) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 18))
                                Text("Change My Vote")
                                    .font(.system(size: 15, weight: .semibold))
                            }
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.gray.opacity(0.2))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                            )
                        }
                        .disabled(true)
                        
                        Text("You can change your vote once every 7 days")
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                            .padding(.top, 4)
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 32) // Add bottom padding to prevent overlap with TabView
            }
        }
        .alert("Reset Vote", isPresented: $showResetConfirmation) {
            Button("Cancel", role: .cancel) {
                HapticManager.shared.buttonPress()
                showResetConfirmation = false
            }
            Button("Reset", role: .destructive) {
                HapticManager.shared.voteReset()
                statsViewModel.resetVote { success in
                    if success {
                        HapticManager.shared.success()
                        self.showResetConfirmation = false
                        self.startCooldownTimer()
                    } else {
                        HapticManager.shared.error()
                    }
                }
            }
        } message: {
            Text("This will replace your previous vote. Are you sure?")
        }
        .alert("Photo Library Access Required", isPresented: $showPhotoPermissionAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Open Settings") {
                if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(settingsURL)
                }
            }
        } message: {
            Text(errorMessage)
        }
        .alert("Error", isPresented: $showSaveErrorAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            print("🔄 DEBUG: SubCategoryStatsView onAppear called")
            print("🕒 DEBUG: hasVoted: \(statsViewModel.hasVoted)")
            print("🕒 DEBUG: lastVoteDate: \(String(describing: statsViewModel.lastVoteDate))")
            startCooldownTimer()
            print("\n📱 DEBUG: SubCategoryStatsView appeared")
            print("📊 DEBUG: Current subcategory state:")
            print("   - Name: \(statsViewModel.currentSubCategory.name)")
            print("   - ID: \(statsViewModel.currentSubCategory.id)")
            print("   - Yay Count: \(statsViewModel.currentSubCategory.yayCount)")
            print("   - Nay Count: \(statsViewModel.currentSubCategory.nayCount)")
            print("   - Total Votes: \(totalVotes)")
            print("   - Yay Percentage: \(yayPercentage)%")
            print("   - Nay Percentage: \(nayPercentage)%")
            categoryViewModel.fetchCategories()
        }
        .onDisappear {
            print("🔚 DEBUG: SubCategoryStatsView onDisappear called")
            timerState.stopTimer()
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        return formatter.string(from: date)
    }
    
    private func formatTimeRemaining(_ timeInterval: TimeInterval) -> String {
        let hours = Int(timeInterval) / 3600
        let minutes = Int(timeInterval) / 60 % 60
        let seconds = Int(timeInterval) % 60
        
        if hours > 0 {
            return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%02d:%02d", minutes, seconds)
        }
    }
    
    private func shareToFacebook() {
        HapticManager.shared.buttonPress()
        let deepLink = "yayonay://subcategory/\(statsViewModel.currentSubCategory.id)"
        let appStoreLink = "https://apps.apple.com/app/idYOUR_APP_ID"
        let vote = yayPercentage > 50 ? "YAY" : "NAY"
        let shareText = "I just voted \(vote) on \(statsViewModel.currentSubCategory.name) in YayoNay! What do you think? Vote now: \(deepLink) or download YayoNay: \(appStoreLink)"
        
        if let url = URL(string: "fb://share?text=\(shareText.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")") {
            if UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url)
            } else {
                // Fallback to Facebook web sharing
                if let webURL = URL(string: "https://www.facebook.com/sharer/sharer.php?u=\(deepLink)&quote=\(shareText.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")") {
                    UIApplication.shared.open(webURL)
                }
            }
        }
    }
    
    private func shareToTwitter() {
        HapticManager.shared.buttonPress()
        let deepLink = "yayonay://subcategory/\(statsViewModel.currentSubCategory.id)"
        let appStoreLink = "https://apps.apple.com/app/idYOUR_APP_ID"
        let vote = yayPercentage > 50 ? "YAY" : "NAY"
        let shareText = "I voted \(vote) on \(statsViewModel.currentSubCategory.name) in YayoNay! What's your vote? Vote now: \(deepLink) #YayoNay #VoteNow"
        
        if let url = URL(string: "twitter://post?message=\(shareText.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")") {
            if UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url)
            } else {
                // Fallback to Twitter web sharing
                if let webURL = URL(string: "https://twitter.com/intent/tweet?text=\(shareText.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")&url=\(deepLink)") {
                    UIApplication.shared.open(webURL)
                }
            }
        }
    }
    
    private func shareToInstagram() {
        HapticManager.shared.buttonPress()
        let deepLink = "yayonay://subcategory/\(statsViewModel.currentSubCategory.id)"
        let appStoreLink = "https://apps.apple.com/app/idYOUR_APP_ID"
        let vote = yayPercentage > 50 ? "YAY" : "NAY"
        let shareText = "I voted \(vote) on \(statsViewModel.currentSubCategory.name) in YayoNay! What's your vote? Vote now: \(deepLink)"
        
        // Try to open Instagram Stories with the image
        if let imageURL = URL(string: statsViewModel.currentSubCategory.imageURL),
           let url = URL(string: "instagram-stories://share?source_application=YayoNay&background_image=\(imageURL.absoluteString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")") {
            if UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url)
            } else {
                // Fallback to Instagram app with the deep link
                if let appURL = URL(string: "instagram://app?url=\(deepLink.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")") {
                    if UIApplication.shared.canOpenURL(appURL) {
                    UIApplication.shared.open(appURL)
                    } else {
                        // Final fallback to Instagram web
                        if let webURL = URL(string: "https://www.instagram.com/") {
                            UIApplication.shared.open(webURL)
                        }
                    }
                }
            }
        }
    }
    
    private func shareToWhatsApp() {
        HapticManager.shared.buttonPress()
        let deepLink = "yayonay://subcategory/\(statsViewModel.currentSubCategory.id)"
        let appStoreLink = "https://apps.apple.com/app/idYOUR_APP_ID"
        let vote = yayPercentage > 50 ? "YAY" : "NAY"
        let shareText = "I just voted \(vote) on \(statsViewModel.currentSubCategory.name) in YayoNay! What do you think? Vote now: \(deepLink) or download YayoNay: \(appStoreLink)"
        
        if let url = URL(string: "whatsapp://send?text=\(shareText.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")") {
            if UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url)
            } else {
                // Fallback to WhatsApp web
                if let webURL = URL(string: "https://api.whatsapp.com/send?text=\(shareText.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")") {
                    UIApplication.shared.open(webURL)
                }
            }
        }
    }
    
    private func shareToTelegram() {
        HapticManager.shared.buttonPress()
        let deepLink = "yayonay://subcategory/\(statsViewModel.currentSubCategory.id)"
        let appStoreLink = "https://apps.apple.com/app/idYOUR_APP_ID"
        let vote = yayPercentage > 50 ? "YAY" : "NAY"
        let shareText = "I just voted \(vote) on \(statsViewModel.currentSubCategory.name) in YayoNay! What do you think? Vote now: \(deepLink) or download YayoNay: \(appStoreLink)"
        
        if let url = URL(string: "tg://msg?text=\(shareText.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")") {
            if UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url)
            } else {
                // Fallback to Telegram web
                if let webURL = URL(string: "https://t.me/share/url?url=\(deepLink)&text=\(shareText.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")") {
                    UIApplication.shared.open(webURL)
                }
            }
        }
    }
    
    private func shareToLinkedIn() {
        HapticManager.shared.buttonPress()
        let deepLink = "yayonay://subcategory/\(statsViewModel.currentSubCategory.id)"
        let appStoreLink = "https://apps.apple.com/app/idYOUR_APP_ID"
        let vote = yayPercentage > 50 ? "YAY" : "NAY"
        let shareText = "I just voted \(vote) on \(statsViewModel.currentSubCategory.name) in YayoNay! What's your opinion? Vote now: \(deepLink) or download YayoNay: \(appStoreLink)"
        
        // Try LinkedIn app first
        if let url = URL(string: "linkedin://share?text=\(shareText.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")") {
            if UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url)
            } else {
                // Fallback to LinkedIn web sharing with message
                if let webURL = URL(string: "https://www.linkedin.com/sharing/share-offsite/?mini=true&url=\(deepLink)&title=YayoNay%20Vote&summary=\(shareText.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")") {
                    UIApplication.shared.open(webURL)
                }
            }
        }
    }
    
    private func shareToTikTok() {
        HapticManager.shared.buttonPress()
        let deepLink = "yayonay://subcategory/\(statsViewModel.currentSubCategory.id)"
        let appStoreLink = "https://apps.apple.com/app/idYOUR_APP_ID"
        let vote = yayPercentage > 50 ? "YAY" : "NAY"
        let shareText = "I just voted \(vote) on \(statsViewModel.currentSubCategory.name) in YayoNay! What's your vote? Vote now: \(deepLink) or download YayoNay: \(appStoreLink)"
        
        // Try to open TikTok app
        if let url = URL(string: "tiktok://") {
            if UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url)
            } else {
                // Fallback to TikTok web
                if let webURL = URL(string: "https://www.tiktok.com/") {
                    UIApplication.shared.open(webURL)
                }
            }
        }
    }
}

struct AttributeVoteRow: View {
    let name: String
    let votes: AttributeVotes
    let onVote: (Bool) -> Void
    @State private var hasVoted = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(name)
                .font(.headline)
            
            if hasVoted || votes.totalVotes > 0 {
                // Show results
                VStack(spacing: 8) {
                    HStack {
                        Text("Nay: \(votes.nayCount)")
                            .foregroundColor(.red)
                        Spacer()
                        Text("Yay: \(votes.yayCount)")
                            .foregroundColor(.green)
                    }
                    .font(.subheadline)
                    
                    GeometryReader { geometry in
                        HStack(spacing: 0) {
                            Rectangle()
                                .fill(Color.red.opacity(0.3))
                                .frame(width: geometry.size.width * CGFloat((100 - votes.yayPercentage) / 100))
                            
                            Rectangle()
                                .fill(Color.green.opacity(0.3))
                                .frame(width: geometry.size.width * CGFloat(votes.yayPercentage / 100))
                        }
                    }
                    .frame(height: 8)
                    .clipShape(RoundedRectangle(cornerRadius: 4))
                }
            } else {
                // Show voting buttons
                HStack(spacing: 12) {
                    Button(action: {
                        HapticManager.shared.voteSuccess()
                        hasVoted = true
                        onVote(false)
                    }) {
                        Text("Nay!")
                            .frame(maxWidth: .infinity)
                            .frame(height: 36)
                            .background(Color.red.opacity(0.1))
                            .foregroundColor(.red)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    
                    Button(action: {
                        HapticManager.shared.voteSuccess()
                        hasVoted = true
                        onVote(true)
                    }) {
                        Text("Yay!")
                            .frame(maxWidth: .infinity)
                            .frame(height: 36)
                            .background(Color.green.opacity(0.1))
                            .foregroundColor(.green)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 5, y: 2)
    }
}

struct SocialShareSection: View {
    let onShare: (SocialPlatform) -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Share your vote")
                .font(.headline)
            
            HStack(spacing: 24) {
                ForEach(SocialPlatform.allCases, id: \.self) { platform in
                    Button(action: { onShare(platform) }) {
                        Image(platform.rawValue)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 40, height: 40)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
}

enum SocialPlatform: String, CaseIterable {
    case facebook = "facebook"
    case instagram = "instagram"
    case linkedin = "linkedin"
    case twitter = "twitter"
    
    var shareURL: String {
        switch self {
        case .facebook: return "https://www.facebook.com/sharer/sharer.php?u="
        case .twitter: return "https://twitter.com/intent/tweet?url="
        case .linkedin: return "https://www.linkedin.com/sharing/share-offsite/?url="
        case .instagram: return "" // Instagram sharing handled differently
        }
    }
}

struct SubQuestionRow: View {
    let question: SubQuestion
    let onVote: (Bool) -> Void
    @State private var showVoteAnimation = false
    @Environment(\.colorScheme) private var colorScheme
    @ObservedObject var viewModel: SubCategoryStatsViewModel
    
    private var hasVoted: Bool {
        viewModel.hasVotedForSubQuestion(question.id)
    }
    
    private var canVote: Bool {
        viewModel.canVoteForSubQuestion(question.id)
    }
    
    private var nextVoteDate: Date? {
        viewModel.getNextVoteDateForSubQuestion(question.id)
    }
    
    private var totalVotes: Int {
        question.yayCount + question.nayCount
    }
    private var yayPercentage: Double {
        totalVotes > 0 ? Double(question.yayCount) / Double(totalVotes) * 100 : 0
    }
    private var nayPercentage: Double {
        totalVotes > 0 ? Double(question.nayCount) / Double(totalVotes) * 100 : 0
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
        HStack(spacing: 8) {
            // Question text
            Text(question.question)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(AppColor.text)
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            // Vote Bar with Percentage and Total Votes
                VStack(alignment: .trailing, spacing: 4) {
                    Text("\(totalVotes) votes")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                    HStack(spacing: 0) {
                        // Yay bar
                        Rectangle()
                            .fill(Color.green)
                            .frame(width: CGFloat(yayPercentage) * 0.5, height: 4)
                            .cornerRadius(2)
                        // Nay bar
                        Rectangle()
                            .fill(Color.red)
                            .frame(width: CGFloat(nayPercentage) * 0.5, height: 4)
                            .cornerRadius(2)
                    }
                    .frame(width: 50)
                }
                        }
                        
            // Voting buttons or status
            if !hasVoted && canVote {
                HStack(spacing: 12) {
                                Button(action: {
                        HapticManager.shared.voteSuccess()
                                        onVote(true)
                                }) {
                        HStack {
                            Image(systemName: "hand.thumbsup.fill")
                                    Text("Yay")
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(Color.green.opacity(0.1))
                        .foregroundColor(.green)
                        .cornerRadius(8)
                                }
                                
                                Button(action: {
                        HapticManager.shared.voteSuccess()
                                        onVote(false)
                                }) {
                        HStack {
                            Image(systemName: "hand.thumbsdown.fill")
                                    Text("Nay")
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(Color.red.opacity(0.1))
                        .foregroundColor(.red)
                        .cornerRadius(8)
                                }
                            }
                        } else {
                            HStack {
                    Text(hasVoted ? "You voted" : "Can't vote yet")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                                
                                Spacer()
                                
                    if let nextDate = nextVoteDate {
                        Text("Next vote: \(formatDate(nextDate))")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding(12)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: colorScheme == .dark ? .black.opacity(0.2) : .black.opacity(0.05),
            radius: colorScheme == .dark ? 3 : 3,
                y: colorScheme == .dark ? 1 : 1)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
}
