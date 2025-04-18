import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct CategoryDetailView: View {
    let category: Category
    @StateObject private var viewModel: SubCategoryViewModel
    @State private var offset: CGFloat = 0
    @State private var backgroundColor: Color = .white
    @State private var isLoading = true
    @State private var showingImportAlert = false
    @State private var isRefreshing = false
    @State private var isAnimatingCard = false
    
    // Constants for thresholds and calculations
    private let swipeThreshold: CGFloat = 100.0
    private let maxOpacity: CGFloat = 0.3
    
    init(category: Category) {
        self.category = category
        print("📝 Category ID:", category.id)
        _viewModel = StateObject(wrappedValue: SubCategoryViewModel(categoryId: category.id))
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                backgroundColor
                    .ignoresSafeArea()
                    .animation(.easeInOut(duration: 0.3), value: offset)
                
                VStack {
                    if let currentSubCategory = viewModel.subCategories.indices.contains(viewModel.currentIndex) 
                        ? viewModel.subCategories[viewModel.currentIndex] 
                        : nil {
                        
                        CardView(
                            subCategory: currentSubCategory,
                            offset: offset,
                            swipeThreshold: swipeThreshold
                        )
                        .gesture(
                            DragGesture()
                                .onChanged { gesture in
                                    if !isAnimatingCard {
                                        offset = gesture.translation.height
                                        updateBackgroundColor(for: offset)
                                    }
                                }
                                .onEnded { gesture in
                                    if !isAnimatingCard {
                                        handleSwipe(gesture.translation.height, for: currentSubCategory)
                                    }
                                }
                        )
                    } else {
                        emptyState
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingImportAlert = true }) {
                        Image(systemName: "square.and.arrow.down")
                            .imageScale(.large)
                    }
                }
            }
            .alert("Import Items", isPresented: $showingImportAlert) {
                Button("Import", role: .none) { importSubcategories() }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("Would you like to import sample items for this category?")
            }
        }
    }
    
    private func updateBackgroundColor(for offset: CGFloat) {
        let progress = min(abs(offset) / swipeThreshold, 1.0)
        if offset > 0 {
            // Swiping down (Nay)
            backgroundColor = .red.opacity(progress * maxOpacity)
        } else if offset < 0 {
            // Swiping up (Yay)
            backgroundColor = .green.opacity(progress * maxOpacity)
        } else {
            backgroundColor = .white
        }
    }
    
    private func handleSwipe(_ offset: CGFloat, for subCategory: SubCategory) {
        if abs(offset) > swipeThreshold && !isAnimatingCard {
            isAnimatingCard = true
            let isYay = offset < 0
            
            // Save vote and update count first
            saveVote(for: subCategory, isYay: isYay)
            viewModel.vote(for: subCategory, isYay: isYay)
            
            // Animate card off screen
            withAnimation(.interpolatingSpring(stiffness: 180, damping: 100)) {
                self.offset = offset > 0 ? 1000 : -1000
                backgroundColor = .white
            }
            
            // Move to next item immediately but delay resetting the card position
            viewModel.nextItem()
            
            // Reset card position and animation state
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                withAnimation(nil) {
                    self.offset = 0
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    isAnimatingCard = false
                }
            }
        } else {
            // Spring back to center
            withAnimation(.interpolatingSpring(stiffness: 180, damping: 100)) {
                self.offset = 0
                backgroundColor = .white
            }
        }
    }
    
    private func saveVote(for subCategory: SubCategory, isYay: Bool) {
        guard let userId = Auth.auth().currentUser?.uid else {
            print("❌ No user ID available for vote submission")
            return
        }
        
        print("📝 Starting vote submission process")
        print("User ID: \(userId)")
        print("SubCategory ID: \(subCategory.id)")
        print("Is Yay: \(isYay)")
        
        let db = Firestore.firestore()
        
        // Create vote document
        let voteData: [String: Any] = [
            "itemName": subCategory.name,
            "imageURL": subCategory.imageURL,
            "isYay": isYay,
            "date": Timestamp(date: Date()),
            "categoryName": category.name,
            "categoryId": category.id,
            "subCategoryId": subCategory.id,
            "userId": userId
        ]
        
        print("📄 Created vote data: \(voteData)")
        
        // Create a batch write
        let batch = db.batch()
        print("🔄 Created batch write operation")
        
        // Add vote document
        let voteRef = db.collection("votes").document()
        batch.setData(voteData, forDocument: voteRef)
        print("📝 Added vote document to batch")
        
        // Update subcategory's vote counts
        let subCategoryRef = db.collection("subCategories").document(subCategory.id)
        let updateData: [String: Any] = isYay ? 
            ["yayCount": FieldValue.increment(Int64(1))] : 
            ["nayCount": FieldValue.increment(Int64(1))]
        batch.updateData(updateData, forDocument: subCategoryRef)
        print("📊 Added subcategory vote count update to batch: \(updateData)")
        
        // Update user profile
        let userRef = db.collection("users").document(userId)
        batch.updateData([
            "votesCount": FieldValue.increment(Int64(1)),
            "lastVoteDate": Timestamp(date: Date())
        ], forDocument: userRef)
        print("👤 Added user profile update to batch")
        
        // Add recent activity
        let activity = [
            "type": "vote",
            "itemId": subCategory.id,
            "title": subCategory.name,
            "timestamp": Timestamp(date: Date())
        ] as [String: Any]
        batch.updateData([
            "recentActivity": FieldValue.arrayUnion([activity])
        ], forDocument: userRef)
        print("📝 Added recent activity to batch: \(activity)")
        
        // Commit the batch
        print("🚀 Committing batch write...")
        batch.commit { error in
            if let error = error {
                print("❌ Batch write failed: \(error.localizedDescription)")
            } else {
                print("✅ Batch write completed successfully")
            }
        }
    }
    
    private func refreshData() {
        isRefreshing = true
        viewModel.fetchSubCategories(for: category.id)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            isRefreshing = false
        }
    }
    
    private func importSubcategories() {
        print("⭐️ Starting import for category:", category.name)
        print("⭐️ Category ID:", category.id)
        isLoading = true
        
        switch category.name.lowercased() {
        case "fruit":
            SubCategoryImporter.shared.importFruitSubcategories(categoryId: category.id) { success in
                if success { refreshAfterImport() }
            }
        case "food":
            SubCategoryImporter.shared.importFoodSubcategories(categoryId: category.id) { success in
                if success { refreshAfterImport() }
            }
        case "drink":
            SubCategoryImporter.shared.importDrinkSubcategories(categoryId: category.id) { success in
                if success { refreshAfterImport() }
            }
        case "dessert":
            SubCategoryImporter.shared.importDessertSubcategories(categoryId: category.id) { success in
                if success { refreshAfterImport() }
            }
        case "sports":
            SubCategoryImporter.shared.importSportsSubcategories(categoryId: category.id) { success in
                if success { refreshAfterImport() }
            }
        case "hike":
            SubCategoryImporter.shared.importHikeSubcategories(categoryId: category.id) { success in
                if success { refreshAfterImport() }
            }
        case "travel":
            SubCategoryImporter.shared.importTravelSubcategories(categoryId: category.id) { success in
                if success { refreshAfterImport() }
            }
        case "art":
            SubCategoryImporter.shared.importArtSubcategories(categoryId: category.id) { success in
                if success { refreshAfterImport() }
            }
        default:
            print("❌ No subcategories defined for category: \(category.name)")
            isLoading = false
        }
    }
    
    private func refreshAfterImport() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            print("🔄 Refreshing data after import")
            viewModel.fetchSubCategories(for: category.id)
            isLoading = false
        }
    }
    
    private var emptyState: some View {
        VStack(spacing: 24) {
            Image(systemName: "photo.stack")
                .font(.system(size: 70))
                .foregroundStyle(.secondary)
                .symbolEffect(.bounce)
            
            Text("No items yet")
                .font(.title2.weight(.semibold))
                .foregroundStyle(.secondary)
            
            Button(action: { showingImportAlert = true }) {
                Label("Import Items", systemImage: "square.and.arrow.down")
                    .font(.headline)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
            }
            .buttonStyle(.borderedProminent)
            .tint(.blue)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
    }
}

// Card View Component
struct CardView: View {
    let subCategory: SubCategory
    let offset: CGFloat
    let swipeThreshold: CGFloat
    
    var body: some View {
        // Main Card
        VStack(spacing: 0) {
            // Title at the top
            Text(subCategory.name)
                .font(.system(size: 24, weight: .bold))
                .padding(.top, 24)
                .padding(.bottom, 16)
            
            // Image
            AsyncImage(url: URL(string: subCategory.imageURL)) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            } placeholder: {
                Color.gray.opacity(0.1)
            }
            .frame(height: UIScreen.main.bounds.height * 0.5) // Slightly smaller height
            
            Spacer(minLength: 24)
        }
        .frame(width: UIScreen.main.bounds.width - 60, height: UIScreen.main.bounds.height * 0.65) // Smaller card
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .shadow(color: .black.opacity(0.15), radius: 12, x: 0, y: 4)
        .offset(y: offset)
        .animation(.interpolatingSpring(stiffness: 180, damping: 100), value: offset)
    }
}

// Custom Vote Button
struct VoteButton: View {
    let isYay: Bool
    let isSelected: Bool
    let action: () -> Void
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: isYay ? "hand.thumbsup.fill" : "hand.thumbsdown.fill")
                Text(isYay ? "Yay" : "Nay")
            }
            .font(.headline)
            .foregroundColor(isSelected ? .white : (isYay ? .green : .red))
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? (isYay ? Color.green : Color.red) : Color.clear)
                    .opacity(isSelected ? (colorScheme == .dark ? 0.8 : 1.0) : 0)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isYay ? Color.green : Color.red, lineWidth: 2)
                    .opacity(colorScheme == .dark ? 0.8 : 1.0)
            )
        }
    }
} 