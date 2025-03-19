import SwiftUI
import PhotosUI
import FirebaseStorage

struct AddVoteItemView: View {
    let categoryId: String
    let viewModel: VoteItemViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var title = ""
    @State private var description = ""
    @State private var selectedItem: PhotosPickerItem?
    @State private var selectedImageData: Data?
    @State private var isUploading = false
    @State private var showError = false
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section("Details") {
                    TextField("Title", text: $title)
                    TextField("Description", text: $description, axis: .vertical)
                        .lineLimit(3...6)
                }
                
                Section("Image") {
                    PhotosPicker(selection: $selectedItem,
                               matching: .images) {
                        if let selectedImageData,
                           let uiImage = UIImage(data: selectedImageData) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFit()
                                .frame(maxHeight: 200)
                        } else {
                            HStack {
                                Image(systemName: "photo")
                                Text("Select Image")
                            }
                        }
                    }
                }
            }
            .navigationTitle("New Vote Item")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        addItem()
                    }
                    .disabled(title.isEmpty || description.isEmpty || isUploading)
                }
            }
            .overlay {
                if isUploading {
                    ProgressView("Uploading...")
                        .padding()
                        .background(.regularMaterial)
                        .cornerRadius(8)
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
            .onChange(of: selectedItem) { newValue in
                Task {
                    if let data = try? await newValue?.loadTransferable(type: Data.self) {
                        selectedImageData = data
                    }
                }
            }
        }
    }
    
    private func addItem() {
        guard !title.isEmpty && !description.isEmpty else { return }
        
        isUploading = true
        
        // For now, we'll use a placeholder user ID
        let userId = "placeholder_user_id"
        
        if let imageData = selectedImageData {
            // Upload image first
            let storageRef = Storage.storage().reference()
            let imageRef = storageRef.child("vote_items/\(UUID().uuidString).jpg")
            
            // Create metadata
            let metadata = StorageMetadata()
            metadata.contentType = "image/jpeg"
            
            imageRef.putData(imageData, metadata: metadata) { metadata, error in
                if let error = error {
                    showError(message: "Failed to upload image: \(error.localizedDescription)")
                    return
                }
                
                // Get download URL and create vote item
                imageRef.downloadURL { url, error in
                    if let error = error {
                        showError(message: "Failed to get image URL: \(error.localizedDescription)")
                        return
                    }
                    
                    if let url = url {
                        createVoteItem(imageURL: url.absoluteString, userId: userId)
                    }
                }
            }
        } else {
            // Create vote item without image
            createVoteItem(imageURL: nil, userId: userId)
        }
    }
    
    private func createVoteItem(imageURL: String?, userId: String) {
        let item = VoteItem(
            title: title,
            description: description,
            imageURL: imageURL,
            categoryId: categoryId,
            createdBy: userId
        )
        
        viewModel.addVoteItem(item)
        isUploading = false
        dismiss()
    }
    
    private func showError(message: String) {
        errorMessage = message
        showError = true
        isUploading = false
    }
}

#Preview {
    AddVoteItemView(categoryId: "preview", viewModel: VoteItemViewModel(categoryId: "preview"))
} 