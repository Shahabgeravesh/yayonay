// MARK: - Add Vote Item View
// This view allows users to add new items for voting, including:
// 1. Item information input
// 2. Category and subcategory selection
// 3. Image upload
// 4. Item details and description

import SwiftUI
import PhotosUI
import FirebaseStorage

struct AddVoteItemView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = VotingViewModel()
    @State private var selectedVoteType: Bool?
    @State private var showingError = false
    
    let topicId: String
    let categoryId: String
    let subCategoryId: String
    let topicTitle: String
    let categoryName: String
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Vote on this topic")
                    .font(.title2)
                    .fontWeight(.bold)
                
                HStack(spacing: 30) {
                    VoteButton(
                        type: .yay,
                        isSelected: selectedVoteType == true,
                        action: { selectedVoteType = true }
                    )
                    
                    VoteButton(
                        type: .nay,
                        isSelected: selectedVoteType == false,
                        action: { selectedVoteType = false }
                    )
                }
                
                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.caption)
                }
                
                Spacer()
            }
            .padding()
            .navigationBarItems(
                leading: Button("Cancel") { dismiss() },
                trailing: Button("Submit") {
                    submitVote()
                }
                .disabled(selectedVoteType == nil || viewModel.isLoading)
            )
        }
    }
    
    private func submitVote() {
        guard let voteType = selectedVoteType else { return }
        
        Task {
            await viewModel.createVote(
                topicId: topicId,
                voteType: voteType,
                categoryId: categoryId,
                subCategoryId: subCategoryId,
                itemName: topicTitle,
                categoryName: categoryName
            )
            if viewModel.errorMessage == nil {
                dismiss()
            }
        }
    }
}

struct VoteButton: View {
    enum VoteType {
        case yay, nay
        
        var title: String {
            switch self {
            case .yay: return "Yay"
            case .nay: return "Nay"
            }
        }
        
        var color: Color {
            switch self {
            case .yay: return .green
            case .nay: return .red
            }
        }
    }
    
    let type: VoteType
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(type.title)
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .frame(width: 120, height: 120)
                .background(isSelected ? type.color : Color.gray)
                .cornerRadius(60)
        }
    }
}

#Preview {
    AddVoteItemView(topicId: "preview", categoryId: "preview", subCategoryId: "preview", topicTitle: "Preview Topic", categoryName: "Preview Category")
} 