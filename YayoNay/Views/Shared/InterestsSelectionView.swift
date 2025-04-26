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