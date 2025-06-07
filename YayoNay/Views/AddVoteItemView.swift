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
    @StateObject private var viewModel: VotingViewModel
    @State private var selectedVoteType: VoteType = .yay
    
    let topicId: String
    let topicTitle: String
    let categoryId: String
    let categoryName: String
    let subCategoryId: String
    
    init(topicId: String, topicTitle: String, categoryId: String, categoryName: String, subCategoryId: String) {
        self.topicId = topicId
        self.topicTitle = topicTitle
        self.categoryId = categoryId
        self.categoryName = categoryName
        self.subCategoryId = subCategoryId
        _viewModel = StateObject(wrappedValue: VotingViewModel())
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Vote Type")) {
                    Picker("Vote Type", selection: $selectedVoteType) {
                        Text("Yay").tag(VoteType.yay)
                        Text("Nay").tag(VoteType.nay)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
                
                Section {
                    Button(action: submitVote) {
                        Text("Submit Vote")
                            .frame(maxWidth: .infinity)
                            .foregroundColor(.white)
                    }
                    .listRowBackground(Color.blue)
                }
            }
            .navigationTitle("Add Vote")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func submitVote() {
        Task {
            await viewModel.createVote(
                topicId: topicId,
                voteType: selectedVoteType,
                categoryId: categoryId,
                subCategoryId: subCategoryId,
                itemName: topicTitle,
                categoryName: categoryName
            )
            dismiss()
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
    AddVoteItemView(
        topicId: "123",
        topicTitle: "Sample Topic",
        categoryId: "456",
        categoryName: "Sample Category",
        subCategoryId: "789"
    )
} 