import SwiftUI
import FirebaseFirestore

struct TopicBoxView: View {
    @StateObject private var viewModel = TopicBoxViewModel()
    @State private var showNewTopicSheet = false
    @State private var showErrorAlert = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 12) {
                // Submit Button
                Button(action: {
                    if viewModel.dailySubmissionCount >= viewModel.DAILY_SUBMISSION_LIMIT {
                        showErrorAlert = true
                    } else {
                    viewModel.showSubmitSheet = true
                    }
                }) {
                    Text("Submit Your Topics Here")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background(Color.blue)
                        .clipShape(Capsule())
                }
                .padding(.horizontal)
                
                // Subtitle with remaining submissions
                HStack {
                    Text("Daily submissions: \(viewModel.dailySubmissionCount)/\(viewModel.DAILY_SUBMISSION_LIMIT)")
                        .font(.system(size: 12))
                        .foregroundColor(viewModel.dailySubmissionCount >= viewModel.DAILY_SUBMISSION_LIMIT ? .red : .secondary)
                    
                    if viewModel.dailySubmissionCount >= viewModel.DAILY_SUBMISSION_LIMIT {
                        Text("(Limit reached)")
                    .font(.system(size: 12))
                            .foregroundColor(.red)
                    }
                }
                
                // Sort Options
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(TopicBoxViewModel.SortOption.allCases, id: \.self) { option in
                            Button(action: { viewModel.sortOption = option }) {
                                Text(option.rawValue)
                                    .font(.system(size: 13, weight: .medium))
                                    .padding(.horizontal, 12)
                                    .frame(height: 32)
                                    .background(viewModel.sortOption == option ? Color.blue : Color.gray.opacity(0.1))
                                    .foregroundColor(viewModel.sortOption == option ? .white : .primary)
                                    .clipShape(Capsule())
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                
                // Topics List
                List {
                    ForEach(viewModel.sortedTopics) { topic in
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
                        .listRowSeparator(.hidden)
                        .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                    }
                }
                .listStyle(.plain)
            }
            .navigationTitle("Topic Box")
            .sheet(isPresented: $viewModel.showSubmitSheet) {
                SubmitTopicSheet(viewModel: viewModel)
            }
            .alert("Submission Limit Reached", isPresented: $showErrorAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("You have reached your daily limit of 5 topic submissions. Please try again tomorrow.")
            }
            .alert("Error", isPresented: Binding(
                get: { viewModel.error != nil },
                set: { if !$0 { viewModel.error = nil } }
            )) {
                Button("OK", role: .cancel) { }
            } message: {
                if let error = viewModel.error {
                    Text(error.localizedDescription)
                }
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
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // User and Date Info
            HStack(alignment: .center, spacing: 6) {
                // User Image
                AsyncImage(url: URL(string: topic.userImage)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Image(systemName: "person.circle.fill")
                        .resizable()
                }
                .frame(width: 28, height: 28)
                .clipShape(Circle())
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(topic.title)
                        .font(.system(size: 14, weight: .medium))
                        .lineLimit(1)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    // Voting and Share Buttons
                    HStack(spacing: 8) {
                // Downvote button
                Button(action: { onVote(false) }) {
                    HStack(spacing: 2) {
                        Image(systemName: "hand.thumbsdown")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(topic.userVoteStatus == .downvoted ? .red : .gray)
                        Text("\(topic.downvotes)")
                            .font(.system(size: 11))
                            .foregroundColor(topic.userVoteStatus == .downvoted ? .red : .gray)
                    }
                    .frame(height: 28)
                    .padding(.horizontal, 6)
                    .background(topic.userVoteStatus == .downvoted ? Color.red.opacity(0.1) : Color.clear)
                    .clipShape(Capsule())
                }
                .buttonStyle(PlainButtonStyle())
                
                // Upvote button
                Button(action: { onVote(true) }) {
                    HStack(spacing: 2) {
                        Image(systemName: "hand.thumbsup")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(topic.userVoteStatus == .upvoted ? .green : .gray)
                        Text("\(topic.upvotes)")
                            .font(.system(size: 11))
                            .foregroundColor(topic.userVoteStatus == .upvoted ? .green : .gray)
                    }
                    .frame(height: 28)
                    .padding(.horizontal, 6)
                    .background(topic.userVoteStatus == .upvoted ? Color.green.opacity(0.1) : Color.clear)
                    .clipShape(Capsule())
                }
                .buttonStyle(PlainButtonStyle())
                        
                        // Share button
                        Button(action: onShare) {
                            Image(systemName: "square.and.arrow.up")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.gray)
                                .frame(width: 28, height: 28)
                                .background(Color.gray.opacity(0.1))
                                .clipShape(Circle())
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    
                    // Date
                    Text(dateFormatter.string(from: topic.date))
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                }
            }
            
            // Description Section
            if isExpanded {
                VStack(alignment: .leading, spacing: 8) {
                    Text(topic.description)
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                        .padding(.top, 4)
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
            
            // Expand/Collapse Button
            Button(action: {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    isExpanded.toggle()
                }
            }) {
                HStack {
                    Text(isExpanded ? "Show less" : "Show more")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.blue)
                    
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.blue)
                }
                .padding(.top, 4)
            }
        }
        .padding(10)
        .background(Color(.systemBackground))
        .cornerRadius(10)
        .shadow(color: .black.opacity(0.05), radius: 2, y: 1)
    }
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()
}

#Preview {
    TopicBoxView()
}
