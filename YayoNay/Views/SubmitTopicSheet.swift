import SwiftUI

struct SubmitTopicSheet: View {
    @ObservedObject var viewModel: TopicBoxViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var title = ""
    @State private var mediaURL = ""
    @State private var tags = ""
    @State private var category = ""
    @State private var description = ""
    @State private var showError = false
    @State private var errorMessage = ""
    
    private var isValid: Bool {
        !title.isEmpty &&
        !mediaURL.isEmpty &&
        !tags.isEmpty &&
        !category.isEmpty
    }
    
    var body: some View {
        VStack(spacing: 20) {
            // Close Button
            HStack {
                Spacer()
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(.white)
                        .padding(12)
                        .background(Color.blue.opacity(0.8))
                        .clipShape(Circle())
                }
                .padding()
            }
            
            // Input Fields
            VStack(spacing: 16) {
                TextField("Title *", text: $title)
                    .textFieldStyle(RoundedTextFieldStyle(isRequired: true, isEmpty: title.isEmpty))
                
                TextField("URL (media link) *", text: $mediaURL)
                    .textFieldStyle(RoundedTextFieldStyle(isRequired: true, isEmpty: mediaURL.isEmpty))
                    .keyboardType(.URL)
                    .textInputAutocapitalization(.never)
                
                TextField("Tags * (comma separated)", text: $tags)
                    .textFieldStyle(RoundedTextFieldStyle(isRequired: true, isEmpty: tags.isEmpty))
                    .textInputAutocapitalization(.never)
                
                TextField("Category *", text: $category)
                    .textFieldStyle(RoundedTextFieldStyle(isRequired: true, isEmpty: category.isEmpty))
                
                TextField("Description (optional)", text: $description)
                    .textFieldStyle(RoundedTextFieldStyle(isRequired: false, isEmpty: false))
                    .frame(height: 100)
            }
            .padding(.horizontal)
            
            if showError {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .font(.caption)
            }
            
            Spacer()
            
            // Submit Button
            Button(action: validateAndSubmit) {
                Text("Submit")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(width: 200)
                    .padding()
                    .background(isValid ? Color.blue : Color.gray)
                    .cornerRadius(25)
            }
            .disabled(!isValid)
            .padding(.bottom)
        }
        .background(Color(.systemBackground))
    }
    
    private func validateAndSubmit() {
        // Clear previous error
        showError = false
        errorMessage = ""
        
        // Validate URL format
        guard let url = URL(string: mediaURL) else {
            showError = true
            errorMessage = "Please enter a valid URL"
            return
        }
        
        // Validate tags format
        let tagList = tags.components(separatedBy: ",")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
        
        if tagList.isEmpty {
            showError = true
            errorMessage = "Please enter at least one tag"
            return
        }
        
        // Submit if all validation passes
        viewModel.submitTopic(
            title: title,
            mediaURL: mediaURL,
            tags: tagList,
            category: category,
            description: description
        )
        dismiss()
    }
}

// Custom text field style to match the design
struct RoundedTextFieldStyle: TextFieldStyle {
    let isRequired: Bool
    let isEmpty: Bool
    
    func _body(configuration: TextField<Self._Label>) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            configuration
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(borderColor, lineWidth: 1)
                )
        }
    }
    
    private var borderColor: Color {
        if isRequired && isEmpty {
            return .red.opacity(0.5)
        }
        return Color(.systemGray4)
    }
}

#Preview {
    SubmitTopicSheet(viewModel: TopicBoxViewModel())
} 