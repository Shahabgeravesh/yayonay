import SwiftUI
import FirebaseFirestore
import FirebaseCore
import FirebaseAuth

struct DatabaseCleanupView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var isCleaning = false
    @State private var showConfirmation = false
    @State private var statusMessages: [String] = []
    @State private var showError = false
    @State private var errorMessage = ""
    
    // List of all possible collection names to clean up
    private let collectionsToClean = [
        "users", "votes", "comments", "allTimeBest", "alltimebest", "AllTimeBest", "topics", 
        "topicsBox", "topicBox", "topicComments", "bestTopics",
        "popularTopics", "trendingTopics", "recentTopics",
        "attributeVotes", "attributes", "attributeTopics",
        "subCategories", "categories"
    ]
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                // Warning header
                VStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.red)
                    
                    Text("Database Cleanup")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text("This will delete ALL data including topics, votes, comments, attributes, categories, and user profiles.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 20)
                
                // Status messages
                ScrollView {
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(statusMessages, id: \.self) { message in
                            Text(message)
                                .font(.system(.body, design: .monospaced))
                                .foregroundColor(message.contains("❌") ? .red : 
                                                message.contains("✅") ? .green : .primary)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                }
                .frame(height: 200)
                
                Spacer()
                
                // Action buttons
                VStack(spacing: 16) {
                    Button(action: {
                        showConfirmation = true
                    }) {
                        Text("Clean Database")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.red)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }
                    .disabled(isCleaning)
                    
                    Button(action: {
                        dismiss()
                    }) {
                        Text("Cancel")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color(.systemGray5))
                            .foregroundColor(.primary)
                            .cornerRadius(12)
                    }
                    .disabled(isCleaning)
                }
                .padding(.horizontal)
                .padding(.bottom, 20)
            }
            .padding()
            .navigationTitle("Database Cleanup")
            .navigationBarTitleDisplayMode(.inline)
            .alert("Confirm Cleanup", isPresented: $showConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Proceed", role: .destructive) {
                    startCleanup()
                }
            } message: {
                Text("This will DELETE ALL DATA including topics, votes, comments, attributes, categories, and user profiles. This action cannot be undone.")
            }
            .alert("Error", isPresented: $showError) {
                Button("OK") { }
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    private func startCleanup() {
        isCleaning = true
        statusMessages = []
        addStatusMessage("Starting database cleanup...")
        
        // Start with the first collection
        cleanupNextCollection(index: 0)
    }
    
    private func cleanupNextCollection(index: Int) {
        // If we've processed all collections, we're done
        if index >= collectionsToClean.count {
            finishCleanup()
            return
        }
        
        let collectionName = collectionsToClean[index]
        cleanupCollection(collectionName) {
            // Move to the next collection
            cleanupNextCollection(index: index + 1)
        }
    }
    
    private func cleanupCollection(_ collectionName: String, completion: @escaping () -> Void) {
        let db = Firestore.firestore()
        
        addStatusMessage("Checking collection: \(collectionName)")
        
        db.collection(collectionName).getDocuments { snapshot, error in
            if let error = error {
                // If the collection doesn't exist, just move on
                if (error as NSError).domain == "FIRFirestoreErrorDomain" && 
                   (error as NSError).code == 5 {
                    addStatusMessage("Collection '\(collectionName)' doesn't exist, skipping")
                    completion()
                    return
                }
                
                addStatusMessage("❌ Error fetching \(collectionName): \(error.localizedDescription)")
                showError(message: error.localizedDescription)
                isCleaning = false
                return
            }
            
            guard let documents = snapshot?.documents else {
                addStatusMessage("❌ No documents found in \(collectionName)")
                completion()
                return
            }
            
            addStatusMessage("Found \(documents.count) documents in \(collectionName)")
            
            if documents.isEmpty {
                addStatusMessage("No documents to delete in \(collectionName)")
                completion()
                return
            }
            
            // Create a batch for deleting documents
            let batch = db.batch()
            
            // Add each document to the batch for deletion
            for document in documents {
                batch.deleteDocument(document.reference)
            }
            
            // Commit the batch
            batch.commit { error in
                if let error = error {
                    addStatusMessage("❌ Error deleting documents from \(collectionName): \(error.localizedDescription)")
                    showError(message: error.localizedDescription)
                    isCleaning = false
                } else {
                    addStatusMessage("✅ Successfully deleted \(documents.count) documents from \(collectionName)!")
                    completion()
                }
            }
        }
    }
    
    private func finishCleanup() {
        addStatusMessage("✅ Database cleanup completed!")
        isCleaning = false
        
        // Dismiss after a short delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            dismiss()
        }
    }
    
    private func addStatusMessage(_ message: String) {
        DispatchQueue.main.async {
            statusMessages.append(message)
        }
    }
    
    private func showError(message: String) {
        DispatchQueue.main.async {
            errorMessage = message
            showError = true
        }
    }
}

#Preview {
    DatabaseCleanupView()
} 