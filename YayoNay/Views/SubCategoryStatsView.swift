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
                            // Yay Stats
                            VStack(spacing: 4) {
                                Text("\(Int(yayPercentage))%")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.green)
                               
                            }
                            .frame(maxWidth: .infinity)
                            
                          
                            
                            // Nay Stats
                            VStack(spacing: 4) {
                                Text("\(Int(nayPercentage))%")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.red)
                               
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .padding(.top, 8)
                        
                        // Vote Bar
                        GeometryReader { geometry in
                            HStack(spacing: 2) {
                                // Yay portion
                                Rectangle()
                                    .fill(Color.green.opacity(0.7))
                                    .frame(width: geometry.size.width * CGFloat(yayPercentage / 100))
                                
                                // Nay portion
                                Rectangle()
                                    .fill(Color.red.opacity(0.7))
                                    .frame(width: geometry.size.width * CGFloat(nayPercentage / 100))
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
                }
                .padding(.horizontal)
            
            // Total Votes Card
            VStack(spacing: 4) {
                Text("Total Votes")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Text("\(totalVotes)")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.primary)
                    .onAppear {
                        print("📊 DEBUG: Displaying total votes in UI: \(totalVotes)")
                    }
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 16)
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.1), radius: 5, y: 2)
            
            // Add Social Sharing
            SocialSharingView(subCategory: statsViewModel.currentSubCategory)
            
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
                        Text("Yay: \(votes.yayCount)")
                            .foregroundColor(.green)
                        Spacer()
                        Text("Nay: \(votes.nayCount)")
                            .foregroundColor(.red)
                    }
                    .font(.subheadline)
                    
                    GeometryReader { geometry in
                        HStack(spacing: 0) {
                            Rectangle()
                                .fill(Color.green.opacity(0.3))
                                .frame(width: geometry.size.width * CGFloat(votes.yayPercentage / 100))
                            
                            Rectangle()
                                .fill(Color.red.opacity(0.3))
                                .frame(width: geometry.size.width * CGFloat((100 - votes.yayPercentage) / 100))
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
                        if !hasVoted && question.totalVotes == 0 {
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
                }
                .frame(width: 100, height: 16)
                
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
        .alert("Voting Cooldown", isPresented: $viewModel.showCooldownAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("You can vote again in \(viewModel.getCooldownRemaining())")
        }
    }
} 
