import SwiftUI
import FirebaseFirestore
import FirebaseAuth
import Charts

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
    @Environment(\.colorScheme) private var colorScheme
    
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
                                if let url = URL(string: "https://www.facebook.com/sharer/sharer.php?u=\(statsViewModel.currentSubCategory.imageURL)") {
                                    UIApplication.shared.open(url)
                                }
                            }) {
                                HStack(spacing: 6) {
                                    Image(systemName: "square.and.arrow.up")
                                        .font(.system(size: 16, weight: .medium))
                                    Text("Facebook")
                                        .font(.system(size: 14, weight: .medium))
                                }
                                .frame(minWidth: 44, minHeight: 44)
                                .padding(.horizontal, 12)
                                .background(Color(red: 0.23, green: 0.35, blue: 0.60).opacity(0.1))
                                .foregroundColor(Color(red: 0.23, green: 0.35, blue: 0.60))
                                .clipShape(Capsule())
                            }
                            
                            // Twitter/X
                            Button(action: {
                                let shareText = "Check out \(statsViewModel.currentSubCategory.name) on YayoNay! \(statsViewModel.currentSubCategory.yayCount) people voted Yay and \(statsViewModel.currentSubCategory.nayCount) voted Nay. What do you think? #YayoNay"
                                if let url = URL(string: "https://twitter.com/intent/tweet?text=\(shareText.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")") {
                                    UIApplication.shared.open(url)
                                }
                            }) {
                                HStack(spacing: 6) {
                                    Image(systemName: "square.and.arrow.up")
                                        .font(.system(size: 16, weight: .medium))
                                    Text("Twitter")
                                        .font(.system(size: 14, weight: .medium))
                                }
                                .frame(minWidth: 44, minHeight: 44)
                                .padding(.horizontal, 12)
                                .background(Color.black.opacity(0.1))
                                .foregroundColor(.black)
                                .clipShape(Capsule())
                            }
                            
                            // Instagram
                            Button(action: {
                                if let url = URL(string: "instagram://app") {
                                    if UIApplication.shared.canOpenURL(url) {
                                        UIApplication.shared.open(url)
                                    } else {
                                        if let webURL = URL(string: "https://www.instagram.com/") {
                                            UIApplication.shared.open(webURL)
                                        }
                                    }
                                }
                            }) {
                                HStack(spacing: 6) {
                                    Image(systemName: "square.and.arrow.up")
                                        .font(.system(size: 16, weight: .medium))
                                    Text("Instagram")
                                        .font(.system(size: 14, weight: .medium))
                                }
                                .frame(minWidth: 44, minHeight: 44)
                                .padding(.horizontal, 12)
                                .background(Color(red: 0.83, green: 0.18, blue: 0.42).opacity(0.1))
                                .foregroundColor(Color(red: 0.83, green: 0.18, blue: 0.42))
                                .clipShape(Capsule())
                            }
                            
                            // Message
                            Button(action: {
                                let shareText = "Check out \(statsViewModel.currentSubCategory.name) on YayoNay! \(statsViewModel.currentSubCategory.yayCount) people voted Yay and \(statsViewModel.currentSubCategory.nayCount) voted Nay. What do you think? #YayoNay"
                                let activityVC = UIActivityViewController(
                                    activityItems: [shareText, URL(string: statsViewModel.currentSubCategory.imageURL) as Any],
                                    applicationActivities: nil
                                )
                                
                                if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                                   let window = windowScene.windows.first,
                                   let rootVC = window.rootViewController {
                                    rootVC.present(activityVC, animated: true)
                                }
                            }) {
                                HStack(spacing: 6) {
                                    Image(systemName: "message.fill")
                                        .font(.system(size: 16, weight: .medium))
                                    Text("Message")
                                        .font(.system(size: 14, weight: .medium))
                                }
                                .frame(minWidth: 44, minHeight: 44)
                                .padding(.horizontal, 12)
                                .background(Color.blue.opacity(0.1))
                                .foregroundColor(.blue)
                                .clipShape(Capsule())
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
                                    }
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
                                                }
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
                
                // Vote Reset Button
                if statsViewModel.hasVoted {
                    VStack(spacing: 8) {
                        if let lastVoteDate = statsViewModel.lastVoteDate {
                            let nextVoteDate = Calendar.current.date(byAdding: .day, value: 7, to: lastVoteDate) ?? Date()
                            let canReset = Calendar.current.dateComponents([.day], from: Date(), to: nextVoteDate).day ?? 0 <= 0
                            
                            Button(action: {
                                if canReset {
                                    showResetConfirmation = true
                                }
                            }) {
                                HStack(spacing: 8) {
                                    Image(systemName: "arrow.clockwise.circle.fill")
                                        .font(.system(size: 18))
                                    Text(canReset ? "Change My Vote" : "Change My Vote")
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
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
        .alert("Reset Vote", isPresented: $showResetConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Reset", role: .destructive) {
                statsViewModel.resetVote()
            }
        } message: {
            Text("This will replace your previous vote. Are you sure?")
        }
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
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
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        return formatter.string(from: date)
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
                        print("DEBUG: Voting Nay for attribute: \(name)")
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
                        print("DEBUG: Voting Yay for attribute: \(name)")
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
    @State private var hasVoted = false
    @State private var showVoteAnimation = false
    @Environment(\.colorScheme) private var colorScheme
    @ObservedObject var viewModel: SubCategoryStatsViewModel
    
    var body: some View {
        HStack(spacing: 8) {
            // Question text
            Text(question.question)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(AppColor.text)
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            // Vote Bar with Percentage and Total Votes
            VStack(spacing: 2) {
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        // Background
                        RoundedRectangle(cornerRadius: 4)
                            .fill(colorScheme == .dark ? Color.gray.opacity(0.3) : Color.gray.opacity(0.2))
                            .frame(height: 16)
                        
                        // Yay portion
                        if question.yayPercentage > 0 {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.green.opacity(colorScheme == .dark ? 0.6 : 0.7))
                                .frame(width: geometry.size.width * CGFloat(question.yayPercentage / 100), height: 16)
                        }
                        
                        // Nay portion
                        if question.nayPercentage > 0 {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.red.opacity(colorScheme == .dark ? 0.6 : 0.7))
                                .frame(width: geometry.size.width * CGFloat(question.nayPercentage / 100), height: 16)
                                .offset(x: geometry.size.width * CGFloat(question.yayPercentage / 100))
                        }
                        
                        // Vote buttons
                        if !hasVoted && question.totalVotes == 0 && viewModel.hasVoted && viewModel.canVote() {
                            HStack(spacing: 0) {
                                Button(action: {
                                    withAnimation {
                                        hasVoted = true
                                        onVote(true)
                                    }
                                }) {
                                    Text("Yay")
                                        .font(.system(size: 10, weight: .medium))
                                        .foregroundColor(.white)
                                        .frame(width: geometry.size.width / 2, height: 16)
                                }
                                
                                Button(action: {
                                    withAnimation {
                                        hasVoted = true
                                        onVote(false)
                                    }
                                }) {
                                    Text("Nay")
                                        .font(.system(size: 10, weight: .medium))
                                        .foregroundColor(.white)
                                        .frame(width: geometry.size.width / 2, height: 16)
                                }
                            }
                        } else {
                            // Show percentages
                            HStack {
                                if question.yayPercentage > 0 {
                                    Text("\(Int(question.yayPercentage))%")
                                        .font(.system(size: 10, weight: .bold))
                                        .foregroundColor(.white)
                                        .padding(.leading, 4)
                                }
                                
                                Spacer()
                                
                                if question.nayPercentage > 0 {
                                    Text("\(Int(question.nayPercentage))%")
                                        .font(.system(size: 10, weight: .bold))
                                        .foregroundColor(.white)
                                        .padding(.trailing, 4)
                                }
                            }
                        }
                    }
                    .frame(width: 100, height: 16)
                }
                
                // Total votes
                if question.totalVotes > 0 {
                    Text("\(question.totalVotes)")
                        .font(.system(size: 8))
                        .foregroundStyle(.secondary)
                        .frame(width: 100, alignment: .center)
                }
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(AppColor.adaptiveSecondaryBackground(for: colorScheme))
        .cornerRadius(6)
        .shadow(
            color: colorScheme == .dark ? .black.opacity(0.2) : .black.opacity(0.05),
            radius: colorScheme == .dark ? 3 : 3,
            y: colorScheme == .dark ? 1 : 1
        )
    }
} 
