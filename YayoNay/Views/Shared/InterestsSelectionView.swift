// MARK: - Interests Selection View
// This view allows users to select their interests, including:
// 1. Category preferences
// 2. Topic interests
// 3. Voting preferences
// 4. Content customization

import SwiftUI

struct InterestsSelectionView: View {
    @ObservedObject var viewModel: ProfileViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(viewModel.availableInterests, id: \.self) { interest in
                    Button(action: {
                        if viewModel.selectedInterests.contains(interest) {
                            viewModel.selectedInterests.remove(interest)
                        } else {
                            viewModel.selectedInterests.insert(interest)
                        }
                    }) {
                        HStack {
                            Text(interest)
                            Spacer()
                            if viewModel.selectedInterests.contains(interest) {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                    .foregroundColor(.primary)
                }
            }
            .navigationTitle("Choose Interests")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        viewModel.updateInterests()
                        dismiss()
                    }
                }
            }
        }
    }
} 