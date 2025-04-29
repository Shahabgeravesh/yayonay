import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct CategoryDetailView: View {
    let category: Category
    @StateObject private var viewModel: SubCategoryViewModel
    @State private var offset: CGFloat = 0
    @State private var backgroundColor: Color = .white
    @State private var isLoading = true
    @State private var isRefreshing = false
    @State private var isAnimatingCard = false
    @State private var showingCooldownAlert = false
    @State private var votedSubCategoryIds: Set<String> = []
    
    // Constants for thresholds and calculations
    private let swipeThreshold: CGFloat = 100.0
    private let maxOpacity: CGFloat = 0.3
    
    init(category: Category) {
        self.category = category
        print("📝 Category ID:", category.id)
        _viewModel = StateObject(wrappedValue: SubCategoryViewModel(categoryId: category.id))
    }
    
    var filteredSubCategories: [SubCategory] {
        return viewModel.subCategories.filter { !votedSubCategoryIds.contains($0.id) }
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
            .alert("Vote Cooldown", isPresented: $showingCooldownAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("You can vote again in 7 days")
            }
            .onAppear {
                loadVotedSubCategories()
            }
        }
    }
    
    private func loadVotedSubCategories() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        let votesRef = Firestore.firestore().collection("votes")
            .whereField("userId", isEqualTo: userId)
        
        votesRef.getDocuments { snapshot, error in
            if let error = error {
                print("Error loading voted subcategories: \(error.localizedDescription)")
                return
            }
            
            if let documents = snapshot?.documents {
                let votedIds = documents.compactMap { $0.data()["subCategoryId"] as? String }
                votedSubCategoryIds = Set(votedIds)
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
            
            // First check for cooldown
            let db = Firestore.firestore()
            let votesRef = db.collection("votes")
                .whereField("userId", isEqualTo: Auth.auth().currentUser?.uid ?? "")
                .whereField("subCategoryId", isEqualTo: subCategory.id)
            
            votesRef.getDocuments { (snapshot, error) in
                if let error = error {
                    print("Error checking for existing votes: \(error.localizedDescription)")
                    return
                }
                
                if let documents = snapshot?.documents {
                    let latestVote = documents.compactMap { document -> (id: String, date: Date, isYay: Bool)? in
                        if let timestamp = document.data()["date"] as? Timestamp,
                           let isYay = document.data()["isYay"] as? Bool {
                            return (id: document.documentID, date: timestamp.dateValue(), isYay: isYay)
                        }
                        return nil
                    }.sorted(by: { $0.date > $1.date }).first
                    
                    if let latestVote = latestVote {
                        print("⏰ Found previous vote from \(latestVote.date)")
                        
                        let calendar = Calendar.current
                        let now = Date()
                        let components = calendar.dateComponents([.day], from: latestVote.date, to: now)
                        let daysSinceLastVote = components.day ?? 0
                        
                        print("📅 Days since last vote: \(daysSinceLastVote)")
                        
                        if daysSinceLastVote < 7 {
                            print("⏳ Cannot vote - cooldown period active")
                            // Show cooldown alert and return without recording vote
                            DispatchQueue.main.async {
                                self.showingCooldownAlert = true
                            }
                            return
                        }
                    }
                }
                
                DispatchQueue.main.async {
                    // Save vote and update count
                    self.saveVote(for: subCategory, isYay: isYay)
            
                    // Add to voted subcategories
                    self.votedSubCategoryIds.insert(subCategory.id)
                    
            // Animate card off screen
            withAnimation(.interpolatingSpring(stiffness: 180, damping: 100)) {
                self.offset = offset > 0 ? 1000 : -1000
                        self.backgroundColor = .white
            }
            
            // Move to next item immediately but delay resetting the card position
                    self.viewModel.nextItem()
            
            // Reset card position and animation state
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                withAnimation(nil) {
                    self.offset = 0
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            self.isAnimatingCard = false
                        }
                    }
                }
            }
        } else {
            // Spring back to center
            withAnimation(.interpolatingSpring(stiffness: 180, damping: 100)) {
                self.offset = 0
                self.backgroundColor = .white
            }
        }
    }
    
    private func saveVote(for subCategory: SubCategory, isYay: Bool) {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        let db = Firestore.firestore()
                    let batch = db.batch()
        
        // Create vote document
        let voteData: [String: Any] = [
            "itemName": subCategory.name,
            "imageURL": subCategory.imageURL,
            "isYay": isYay,
            "date": Timestamp(date: Date()),
                "categoryName": self.category.name,
                "categoryId": self.category.id,
            "subCategoryId": subCategory.id,
            "userId": userId
        ]
        
        // Add vote document
        let voteRef = db.collection("votes").document()
        batch.setData(voteData, forDocument: voteRef)
        
        // Update subcategory's vote counts
        let subCategoryRef = db.collection("subCategories").document(subCategory.id)
        let updateData: [String: Any] = isYay ? 
            ["yayCount": FieldValue.increment(Int64(1))] : 
            ["nayCount": FieldValue.increment(Int64(1))]
        batch.updateData(updateData, forDocument: subCategoryRef)
        
        // Update user profile
        let userRef = db.collection("users").document(userId)
        batch.updateData([
            "votesCount": FieldValue.increment(Int64(1)),
            "lastVoteDate": Timestamp(date: Date())
        ], forDocument: userRef)
        
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
        
        // Commit the batch
        batch.commit { error in
            if let error = error {
                print("Error saving vote: \(error.localizedDescription)")
            } else {
                print("Successfully saved vote")
                // Add to voted subcategories
                DispatchQueue.main.async {
                    self.votedSubCategoryIds.insert(subCategory.id)
                }
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
    
    private var emptyState: some View {
        VStack(spacing: 24) {
            Image(systemName: "photo.stack")
                .font(.system(size: 70))
                .foregroundStyle(.secondary)
                .symbolEffect(.bounce)
            
            Text("No items yet")
                .font(.title2.weight(.semibold))
                .foregroundStyle(.secondary)
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