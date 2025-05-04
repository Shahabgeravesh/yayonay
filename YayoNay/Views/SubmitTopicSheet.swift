import SwiftUI

struct SubmitTopicSheet: View {
    @ObservedObject var viewModel: TopicBoxViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var title = ""
    @State private var mediaURL = ""
    @State private var tags = ""
    @State private var selectedCategory = TopicBoxViewModel.availableCategories[0]
    @State private var description = ""
    @State private var showError = false
    @State private var errorMessage = ""
    
    private var isValid: Bool {
        !title.isEmpty &&
        !mediaURL.isEmpty &&
        !tags.isEmpty
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 8) {
                        Text("Submit a New Topic")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text("Share your thoughts with the community")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 8)
                    
                    // Input Fields
                    VStack(spacing: 20) {
                        // Title
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Title")
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            TextField("Enter your topic title", text: $title)
                                .textFieldStyle(RoundedTextFieldStyle(isRequired: true, isEmpty: title.isEmpty))
                        }
                        
                        // Media URL
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Media URL")
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            TextField("Enter media link", text: $mediaURL)
                                .textFieldStyle(RoundedTextFieldStyle(isRequired: true, isEmpty: mediaURL.isEmpty))
                                .keyboardType(.URL)
                                .textInputAutocapitalization(.never)
                        }
                        
                        // Tags
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Tags")
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            TextField("Enter tags (separate with commas)", text: $tags)
                                .textFieldStyle(RoundedTextFieldStyle(isRequired: true, isEmpty: tags.isEmpty))
                                .textInputAutocapitalization(.never)
                            
                            // Preview of tags
                            if !tags.isEmpty {
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 8) {
                                        ForEach(processedTags, id: \.self) { tag in
                                            HStack(spacing: 4) {
                                                Text(tag)
                                                    .font(.system(size: 12))
                                                Button(action: {
                                                    // Remove this tag
                                                    let updatedTags = processedTags.filter { $0 != tag }
                                                    tags = updatedTags.joined(separator: ", ")
                                                }) {
                                                    Image(systemName: "xmark.circle.fill")
                                                        .font(.system(size: 12))
                                                        .foregroundColor(.gray)
                                                }
                                            }
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 4)
                                            .background(Color.blue.opacity(0.1))
                                            .foregroundColor(.blue)
                                            .clipShape(Capsule())
                                        }
                                    }
                                    .padding(.top, 4)
                                }
                            }
                            
                            Text("Add multiple tags by separating them with commas")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .padding(.top, 2)
                        }
                        
                        // Category
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Category")
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            Picker("Category", selection: $selectedCategory) {
                                ForEach(TopicBoxViewModel.availableCategories, id: \.self) { category in
                                    Text(category).tag(category)
                                }
                            }
                            .pickerStyle(.menu)
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(10)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color(.systemGray4), lineWidth: 1)
                            )
                        }
                        
                        // Description
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Description")
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            TextEditor(text: $description)
                                .frame(height: 100)
                                .padding(8)
                                .background(Color(.systemGray6))
                                .cornerRadius(10)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(Color(.systemGray4), lineWidth: 1)
                                )
                        }
                    }
                    .padding(.horizontal)
                    
                    if showError {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .font(.subheadline)
                            .padding(.horizontal)
                    }
                    
                    // Submit Button
                    Button(action: validateAndSubmit) {
                        HStack {
                            Text("Submit Topic")
                                .font(.headline)
                            Image(systemName: "arrow.up.circle.fill")
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(isValid ? Color.blue : Color.gray)
                        .cornerRadius(12)
                    }
                    .disabled(!isValid)
                    .padding(.horizontal)
                    .padding(.bottom, 24)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.gray)
                    }
                }
            }
        }
    }
    
    private var processedTags: [String] {
        tags.components(separatedBy: ",")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
            .map { tag in
                if tag.hasPrefix("#") {
                    return tag
                } else {
                    return "#" + tag
                }
            }
    }
    
    private func validateAndSubmit() {
        // Clear previous error
        showError = false
        errorMessage = ""
        
        // Validate URL format
        guard !mediaURL.isEmpty else {
            showError = true
            errorMessage = "Please enter a media URL"
            return
        }
        
        // Clean up the URL
        var cleanedURL = mediaURL.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Add https:// if no scheme is present
        if !cleanedURL.hasPrefix("http://") && !cleanedURL.hasPrefix("https://") {
            cleanedURL = "https://" + cleanedURL
        }
        
        // Validate URL format
        guard let url = URL(string: cleanedURL),
              url.scheme != nil,
              url.host != nil,
              url.host!.contains(".") else {
            showError = true
            errorMessage = "Please enter a valid URL (e.g., https://example.com)"
            return
        }
        
        // Update the mediaURL with the cleaned version
        mediaURL = cleanedURL
        
        // Validate tags format
        let tagList = processedTags
        
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
            category: selectedCategory,
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
        configuration
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(borderColor, lineWidth: 1)
            )
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