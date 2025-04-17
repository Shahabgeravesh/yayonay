import SwiftUI
import FirebaseFirestore
import FirebaseAuth

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
        print("DEBUG: Initializing SubCategoryStatsView with subCategory: \(subCategory.name)")
        print("DEBUG: Initial yayCount: \(subCategory.yayCount), nayCount: \(subCategory.nayCount)")
        _statsViewModel = StateObject(wrappedValue: SubCategoryStatsViewModel(subCategory: subCategory))
    }
    
    private var totalVotes: Int {
        let total = statsViewModel.currentSubCategory.yayCount + statsViewModel.currentSubCategory.nayCount
        print("DEBUG: Calculating total votes: \(total)")
        return total
    }
    
    private var yayPercentage: Double {
        let percentage = totalVotes > 0 ? Double(statsViewModel.currentSubCategory.yayCount) / Double(totalVotes) * 100 : 0
        print("DEBUG: Calculating yay percentage: \(percentage)%")
        return percentage
    }
    
    private var nayPercentage: Double {
        let percentage = totalVotes > 0 ? Double(statsViewModel.currentSubCategory.nayCount) / Double(totalVotes) * 100 : 0
        print("DEBUG: Calculating nay percentage: \(percentage)%")
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
                
                Text(statsViewModel.currentSubCategory.name)
                    .font(.title2)
                    .fontWeight(.semibold)
                
                // Overall Vote Stats
                VStack(spacing: 16) {
                    // Total Votes
                    Text("Total Votes: \(totalVotes)")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    // Vote Percentages
                    HStack(spacing: 20) {
                        // Yay Stats
                        VStack(spacing: 4) {
                            Text("\(Int(yayPercentage))%")
                                .font(.title)
                                .foregroundColor(.green)
                            Text("Yay")
                                .font(.subheadline)
                                .foregroundColor(.green)
                        }
                        .frame(maxWidth: .infinity)
                        
                        // Divider
                        Rectangle()
                            .frame(width: 1, height: 40)
                            .foregroundColor(.gray.opacity(0.3))
                        
                        // Nay Stats
                        VStack(spacing: 4) {
                            Text("\(Int(nayPercentage))%")
                                .font(.title)
                                .foregroundColor(.red)
                            Text("Nay")
                                .font(.subheadline)
                                .foregroundColor(.red)
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                    .shadow(color: .black.opacity(0.1), radius: 5, y: 2)
                    
                    // Vote Bar
                    GeometryReader { geometry in
                        HStack(spacing: 0) {
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
                    .frame(height: 8)
                    .clipShape(RoundedRectangle(cornerRadius: 4))
                }
                .padding(.horizontal)
                
                // Voting Buttons
                HStack(spacing: 20) {
                    Button(action: {
                        print("DEBUG: Voting Yay")
                        statsViewModel.voteForAttribute(name: statsViewModel.currentSubCategory.name, isYay: true)
                    }) {
                        Text("Yay!")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.green)
                            .cornerRadius(12)
                    }
                    
                    Button(action: {
                        print("DEBUG: Voting Nay")
                        statsViewModel.voteForAttribute(name: statsViewModel.currentSubCategory.name, isYay: false)
                    }) {
                        Text("Nay!")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.red)
                            .cornerRadius(12)
                    }
                }
                .padding(.horizontal)
                
                // Comments Section
                VStack(alignment: .leading, spacing: 16) {
                    Text("Comments")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    TextField("Add a comment...", text: $newComment)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding(.horizontal)
                    
                    if !statsViewModel.comments.isEmpty {
                        ForEach(statsViewModel.comments) { comment in
                            CommentRow(
                                comment: comment,
                                onLike: { statsViewModel.likeComment(comment) },
                                onDelete: { statsViewModel.deleteComment(comment) },
                                onReply: { text in
                                    statsViewModel.addComment(text, parentId: comment.id)
                                }
                            )
                        }
                    } else {
                        Text("No comments yet")
                            .foregroundColor(.secondary)
                            .padding()
                    }
                }
            }
            .padding()
        }
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            print("DEBUG: SubCategoryStatsView appeared")
            print("DEBUG: Current subcategory - Name: \(statsViewModel.currentSubCategory.name)")
            print("DEBUG: Current votes - Yay: \(statsViewModel.currentSubCategory.yayCount), Nay: \(statsViewModel.currentSubCategory.nayCount)")
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