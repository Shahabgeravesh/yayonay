import SwiftUI
import FirebaseFirestore

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
        _statsViewModel = StateObject(wrappedValue: SubCategoryStatsViewModel(subCategory: subCategory))
    }
    
    private var totalVotes: Int {
        statsViewModel.currentSubCategory.yayCount + statsViewModel.currentSubCategory.nayCount
    }
    
    private var yayPercentage: Double {
        totalVotes > 0 ? Double(statsViewModel.currentSubCategory.yayCount) / Double(totalVotes) * 100 : 0
    }
    
    private var nayPercentage: Double {
        totalVotes > 0 ? Double(statsViewModel.currentSubCategory.nayCount) / Double(totalVotes) * 100 : 0
    }
    
    private func submitComment() {
        statsViewModel.addComment(newComment)
        newComment = "" // Clear the input field after submitting
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                headerSection
                
                // Voting section
                if let category = categoryViewModel.categories.first(where: { $0.id == statsViewModel.currentSubCategory.categoryId }) {
                    VStack(spacing: 16) {
                        ForEach(category.attributes, id: \.name) { attribute in
                            AttributeRow(
                                name: attribute.name,
                                yayText: attribute.yayText,
                                nayText: attribute.nayText,
                                votes: statsViewModel.attributeVotes[attribute.name] ?? AttributeVotes(),
                                onVote: { isYay in
                                    statsViewModel.voteForAttribute(name: attribute.name, isYay: isYay)
                                }
                            )
                        }
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                    .shadow(color: .black.opacity(0.1), radius: 5, y: 2)
                }
                
                // Comments Section
                VStack(alignment: .leading, spacing: 16) {
                    Text("Comment")
                        .font(.headline)
                    
                    // Comment Input
                    HStack {
                        TextField("Add your comments here", text: $newComment)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                        
                        Button(action: submitComment) {
                            Text("Post")
                                .foregroundColor(newComment.isEmpty ? .gray : .blue)
                        }
                        .disabled(newComment.isEmpty)
                    }
                    
                    // Comments List
                    ForEach(statsViewModel.comments) { comment in
                        CommentRow(comment: comment) { action in
                            switch action {
                            case .like:
                                statsViewModel.likeComment(comment)
                            case .delete:
                                statsViewModel.deleteComment(comment)
                            case .reply(let text):
                                statsViewModel.addComment(text, parentId: comment.id)
                            }
                        }
                    }
                }
                .padding()
                
                // Share Section
                SocialShareSection(onShare: share)
            }
            .padding()
        }
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            categoryViewModel.fetchCategories()
            statsViewModel.setupCommentsListener() // Make sure comments listener is set up
        }
    }
    
    private var headerSection: some View {
        VStack(spacing: 16) {
            AsyncImage(url: URL(string: statsViewModel.currentSubCategory.imageURL)) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Color.gray.opacity(0.2)
            }
            .frame(height: 200)
            .clipShape(RoundedRectangle(cornerRadius: 20))
            
            Text(statsViewModel.currentSubCategory.name)
                .font(.title)
                .fontWeight(.bold)
        }
    }
    
    private func share(on platform: SocialPlatform) {
        // Handle sharing based on platform
        showShareSheet = true
    }
}

struct AttributeRow: View {
    let name: String
    let yayText: String
    let nayText: String
    let votes: AttributeVotes
    let onVote: (Bool) -> Void
    @State private var hasVoted = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(name)
                .font(.headline)
                .padding(.bottom, 4)
            
            if hasVoted || votes.totalVotes > 0 {
                // Results View
                VStack(spacing: 8) {
                    // Yay Result Bar
                    HStack {
                        Text("\(yayText)!")
                            .foregroundColor(.green)
                            .font(.system(size: 16, weight: .semibold))
                        Text("\(Int(votes.yayPercentage))%")
                            .foregroundColor(.green)
                            .font(.system(size: 16, weight: .bold))
                        Spacer()
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Color.green.opacity(0.15))
                    .cornerRadius(12)
                    
                    // Nay Result Bar
                    HStack {
                        Text("\(nayText)!")
                            .foregroundColor(.red)
                            .font(.system(size: 16, weight: .semibold))
                        Text("\(100 - Int(votes.yayPercentage))%")
                            .foregroundColor(.red)
                            .font(.system(size: 16, weight: .bold))
                        Spacer()
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Color.red.opacity(0.15))
                    .cornerRadius(12)
                    
                    // Progress bar
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            Rectangle()
                                .fill(Color.red.opacity(0.3))
                                .frame(height: 3)
                            
                            Rectangle()
                                .fill(Color.green)
                                .frame(width: geometry.size.width * CGFloat(votes.yayPercentage / 100), height: 3)
                        }
                    }
                    .frame(height: 3)
                    
                    // Total votes
                    Text("\(votes.totalVotes) votes")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.top, 4)
                }
            } else {
                // Voting Buttons
                HStack(spacing: 12) {
                    Button(action: {
                        hasVoted = true
                        onVote(false)
                    }) {
                        Text(nayText)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color.red.opacity(0.15))
                            .foregroundColor(.red)
                            .cornerRadius(12)
                    }
                    
                    Button(action: {
                        hasVoted = true
                        onVote(true)
                    }) {
                        Text(yayText)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color.green.opacity(0.15))
                            .foregroundColor(.green)
                            .cornerRadius(12)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
    }
}

struct CommentRow: View {
    let comment: Comment
    let onAction: (CommentAction) -> Void
    @State private var isReplying = false
    @State private var replyText = ""
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Main comment content
            HStack(alignment: .top) {
                AsyncImage(url: URL(string: comment.userImage)) { image in
                    image.resizable()
                } placeholder: {
                    Image(systemName: "person.circle.fill")
                        .resizable()
                }
                .frame(width: 40, height: 40)
                .clipShape(Circle())
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(comment.username)
                        .font(.headline)
                    Text(comment.text)
                        .font(.body)
                    
                    // Action buttons
                    HStack(spacing: 16) {
                        Button(action: { onAction(.like) }) {
                            HStack {
                                Image(systemName: comment.isLiked ? "heart.fill" : "heart")
                                Text("\(comment.likes)")
                            }
                            .foregroundColor(comment.isLiked ? .red : .gray)
                        }
                        
                        Button(action: { isReplying.toggle() }) {
                            Label("Reply", systemImage: "arrowshape.turn.up.left")
                                .foregroundColor(.gray)
                        }
                        
                        Text(comment.date.timeAgo())
                            .foregroundStyle(.secondary)
                    }
                    .font(.caption)
                    
                    // Reply input field
                    if isReplying {
                        HStack {
                            TextField("Write a reply...", text: $replyText)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                            
                            Button("Post") {
                                onAction(.reply(replyText))
                                replyText = ""
                                isReplying = false
                            }
                            .disabled(replyText.isEmpty)
                        }
                        .padding(.top, 8)
                    }
                    
                    // Nested replies
                    if !comment.replies.isEmpty {
                        ForEach(comment.replies) { reply in
                            CommentRow(comment: reply, onAction: onAction)
                                .padding(.leading, 20)
                        }
                    }
                }
            }
        }
        .padding(.vertical, 8)
    }
}

enum CommentAction {
    case like
    case delete
    case reply(String)
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