import SwiftUI
import FirebaseFirestore

struct TopicBoxView: View {
    @StateObject private var viewModel = TopicBoxViewModel()
    @State private var showNewTopicSheet = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                // Submit Button
                Button(action: {
                    viewModel.showSubmitSheet = true
                }) {
                    Text("Submit Your Topics Here")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.blue)
                        .cornerRadius(25)
                }
                .padding(.horizontal)
                
                // Subtitle
                Text("everyday you can suggest 5 topics for voting")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                // Sort Options
                HStack(spacing: 16) {
                    ForEach(TopicBoxViewModel.SortOption.allCases, id: \.self) { option in
                        Button(action: { viewModel.sortOption = option }) {
                            Text(option.rawValue)
                                .font(.subheadline)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(viewModel.sortOption == option ? Color.blue : Color.clear)
                                .foregroundColor(viewModel.sortOption == option ? .white : .primary)
                                .clipShape(Capsule())
                        }
                    }
                }
                .padding(.horizontal)
                
                // Topics List
                List {
                    ForEach(viewModel.topics) { topic in
                        TopicRow(
                            topic: topic,
                            onVote: { isUpvote in
                                viewModel.vote(for: topic, isUpvote: isUpvote)
                            },
                            onShare: {
                                viewModel.shareTopic(topic)
                            },
                            onShareViaMessage: {
                                viewModel.shareViaMessage(topic)
                            }
                        )
                    }
                }
                .listStyle(.plain)
            }
            .navigationTitle("Topic Box")
            .sheet(isPresented: $viewModel.showSubmitSheet) {
                SubmitTopicSheet(viewModel: viewModel)
            }
        }
        .onAppear {
            viewModel.fetchTopics()
        }
    }
}

struct TopicRow: View {
    let topic: Topic
    let onVote: (Bool) -> Void
    let onShare: () -> Void
    let onShareViaMessage: () -> Void
    
    @State private var showingShareSheet = false
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // User and Date Info
            HStack {
                // User Image
                AsyncImage(url: URL(string: topic.userImage)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Image(systemName: "person.circle.fill")
                        .resizable()
                }
                .frame(width: 40, height: 40)
                .clipShape(Circle())
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(topic.title)
                        .font(.headline)
                    
                    HStack {
                        Text(topic.category)
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.blue.opacity(0.1))
                            .foregroundColor(.blue)
                            .cornerRadius(8)
                        
                        Text("•")
                            .foregroundStyle(.secondary)
                        
                        Text("Submitted: \(dateFormatter.string(from: topic.date))")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                
                Spacer()
            }
            
            // Voting Options and Actions
            HStack {
                // Vote counts
                HStack(spacing: 16) {
                    // Downvote button
                    Button(action: { onVote(false) }) {
                        VStack(spacing: 4) {
                            Image(systemName: "hand.thumbsdown")
                                .foregroundColor(topic.userVoteStatus == .downvoted ? .red : .gray)
                            Text("\(topic.downvotes)")
                                .font(.caption)
                                .foregroundColor(topic.userVoteStatus == .downvoted ? .red : .gray)
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    // Upvote button
                    Button(action: { onVote(true) }) {
                        VStack(spacing: 4) {
                            Image(systemName: "hand.thumbsup")
                                .foregroundColor(topic.userVoteStatus == .upvoted ? .green : .gray)
                            Text("\(topic.upvotes)")
                                .font(.caption)
                                .foregroundColor(topic.userVoteStatus == .upvoted ? .green : .gray)
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                
                Spacer()
                
                // Share buttons
                HStack(spacing: 12) {
                    // Text message share button
                    Button(action: onShareViaMessage) {
                        Image(systemName: "message")
                            .font(.system(size: 16))
                            .foregroundStyle(AppColor.secondaryText)
                    }
                    
                    // General share button
                    shareButton
                }
            }
        }
        .padding()
        .background(AppColor.secondaryBackground.opacity(0.5))
        .cornerRadius(12)
    }
    
    private var shareButton: some View {
        Button(action: {
            showingShareSheet = true
        }) {
            Image(systemName: "square.and.arrow.up")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.gray)
                .frame(width: 32, height: 32)
                .background(AppColor.secondaryBackground.opacity(0.5))
                .cornerRadius(12)
        }
        .sheet(isPresented: $showingShareSheet) {
            if let url = URL(string: "https://yayonay.app/topic/\(topic.id)") {
                ShareSheet(activityItems: [url])
            }
        }
    }
}

#Preview {
    TopicBoxView()
}