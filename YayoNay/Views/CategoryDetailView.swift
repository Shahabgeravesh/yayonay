// MARK: - Category Detail View
// This view displays detailed information about a specific category, including:
// 1. List of subcategories within the category
// 2. Voting statistics for each subcategory
// 3. Ability to vote on subcategories
// 4. Category-specific information and details

import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct CategoryDetailView: View {
    let category: Category
    let initialSubCategoryId: String?
    @StateObject private var viewModel: SubCategoryViewModel
    @State private var offset: CGFloat = 0
    @State private var horizontalOffset: CGFloat = 0
    @State private var backgroundColor: Color = .white
    @State private var isLoading = true
    @State private var isRefreshing = false
    @State private var isAnimatingCard = false
    @State private var showingCooldownAlert = false
    @State private var votedSubCategoryIds: Set<String> = []
    @State private var hasSetInitialIndex = false
    
    // Constants for thresholds and calculations
    private let swipeThreshold: CGFloat = 100.0
    private let horizontalSwipeThreshold: CGFloat = 100.0
    private let maxOpacity: CGFloat = 0.3
    
    init(category: Category, initialSubCategoryId: String? = nil) {
        self.category = category
        self.initialSubCategoryId = initialSubCategoryId
        _viewModel = StateObject(wrappedValue: SubCategoryViewModel(categoryId: category.id, initialSubCategoryId: initialSubCategoryId))
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
                    .animation(.easeInOut(duration: 0.3), value: horizontalOffset)
                
                Group {
                    if isLoading && !viewModel.hasReachedEnd {
                        ProgressView()
                    } else if viewModel.hasReachedEnd {
                        emptyState
                    } else {
                        VStack {
                            if let currentSubCategory = viewModel.subCategories.indices.contains(viewModel.currentIndex) 
                                ? viewModel.subCategories[viewModel.currentIndex] 
                                : nil {
                                
                                CardView(
                                    subCategory: currentSubCategory,
                                    offset: offset,
                                    horizontalOffset: 0,
                                    swipeThreshold: swipeThreshold,
                                    horizontalSwipeThreshold: horizontalSwipeThreshold,
                                    onSkip: { viewModel.nextItem() }
                                )
                                .gesture(
                                    DragGesture()
                                        .onChanged { gesture in
                                            if !isAnimatingCard {
                                                // Only handle vertical swipe
                                                    offset = gesture.translation.height
                                                    updateBackgroundColor(for: offset, isHorizontal: false)
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
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .alert("Vote Cooldown", isPresented: $showingCooldownAlert) {
                Button("Skip") {
                    // Move to next item
                    viewModel.nextItem()
                }
            } message: {
                Text("You can vote again in 7 days")
            }
            .onAppear {
                print("DEBUG: 👋 CategoryDetailView appeared")
                print("DEBUG: Initial hasReachedEnd: \(viewModel.hasReachedEnd)")
                print("DEBUG: Initial isLoading: \(isLoading)")
                loadVotedSubCategories()
            }
            .onChange(of: viewModel.subCategories) { newSubCategories in
                print("DEBUG: 📦 SubCategories changed")
                print("DEBUG: New count: \(newSubCategories.count)")
                print("DEBUG: Current hasReachedEnd: \(viewModel.hasReachedEnd)")
                
                if !newSubCategories.isEmpty && !hasSetInitialIndex {
                    if let initialId = initialSubCategoryId,
                       let index = newSubCategories.firstIndex(where: { $0.id == initialId }) {
                        viewModel.currentIndex = index
                        print("DEBUG: 📍 Set initial index to: \(index)")
                    }
                    hasSetInitialIndex = true
                    isLoading = false
                    print("DEBUG: ✅ Initial setup complete")
                } else if newSubCategories.isEmpty {
                    isLoading = false
                    print("DEBUG: ⚠️ No subcategories available")
                }
            }
        }
    }
    
    private func loadVotedSubCategories() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        let votesRef = Firestore.firestore().collection("users").document(userId).collection("votes")
        
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
    
    private func updateBackgroundColor(for offset: CGFloat, isHorizontal: Bool) {
        let progress = min(abs(offset) / (isHorizontal ? horizontalSwipeThreshold : swipeThreshold), 1.0)
        if isHorizontal {
            // Yellow for skip (both left and right)
            backgroundColor = .yellow.opacity(progress * maxOpacity)
        } else {
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
    }
    
    private func handleSwipe(_ offset: CGFloat, for subCategory: SubCategory) {
        print("DEBUG: 👆 Handling swipe for: \(subCategory.name)")
        print("DEBUG: Current offset: \(offset)")
        
        if abs(offset) > swipeThreshold && !isAnimatingCard {
            print("DEBUG: ✅ Swipe threshold reached")
            isAnimatingCard = true
            
            // Check cooldown first
            let db = Firestore.firestore()
            let votesRef = db.collection("users").document(Auth.auth().currentUser?.uid ?? "").collection("votes")
                .whereField("subCategoryId", isEqualTo: subCategory.id)
            
            votesRef.getDocuments { (snapshot, error) in
                if let error = error {
                    print("DEBUG: ❌ Error checking cooldown: \(error.localizedDescription)")
                    self.resetCard()
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
                        let calendar = Calendar.current
                        let now = Date()
                        let components = calendar.dateComponents([.day], from: latestVote.date, to: now)
                        let daysSinceLastVote = components.day ?? 0
                        
                        if daysSinceLastVote < 7 {
                            print("DEBUG: ⏳ Showing cooldown alert")
                            DispatchQueue.main.async {
                                self.showingCooldownAlert = true
                                self.resetCard()
                            }
                            return
                        }
                    }
                }
                
                // If we get here, no cooldown is active
                let isYay = offset < 0
                print("DEBUG: Vote type: \(isYay ? "Yay" : "Nay")")
                
                // Save vote
                    self.saveVote(for: subCategory, isYay: isYay)
                print("DEBUG: ✅ Vote saved")
                
                // Add to voted subcategories
                self.votedSubCategoryIds.insert(subCategory.id)
                print("DEBUG: ✅ Added to voted subcategories")
            
            // Animate card off screen
            withAnimation(.interpolatingSpring(stiffness: 180, damping: 100)) {
                self.offset = offset > 0 ? 1000 : -1000
                        self.backgroundColor = .white
            }
                print("DEBUG: ✅ Card animation started")
            
                // Move to next item immediately
                    self.viewModel.nextItem()
                print("DEBUG: ✅ Moved to next item")
            
            // Reset card position and animation state
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                withAnimation(nil) {
                    self.offset = 0
                }
                            self.isAnimatingCard = false
                    print("DEBUG: ✅ Card animation completed")
                }
            }
        } else {
            print("DEBUG: 🔄 Springing back to center")
            // Spring back to center
            withAnimation(.interpolatingSpring(stiffness: 180, damping: 100)) {
                self.offset = 0
                self.backgroundColor = .white
            }
        }
    }
    
    private func handleHorizontalSwipe(_ offset: CGFloat) {
        if abs(offset) > horizontalSwipeThreshold && !isAnimatingCard {
            isAnimatingCard = true
            
            // Animate card off screen
            withAnimation(.interpolatingSpring(stiffness: 180, damping: 100)) {
                self.horizontalOffset = offset > 0 ? 1000 : -1000
                self.backgroundColor = .white
            }
            
            // Move to next item immediately
            self.viewModel.nextItem()
            
            // Reset card position and animation state
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                withAnimation(nil) {
                    self.horizontalOffset = 0
                }
                self.isAnimatingCard = false
            }
        } else {
            // Spring back to center
            withAnimation(.interpolatingSpring(stiffness: 180, damping: 100)) {
                self.horizontalOffset = 0
                self.backgroundColor = .white
            }
        }
    }
    
    private func resetCard() {
        withAnimation(.interpolatingSpring(stiffness: 180, damping: 100)) {
            self.offset = 0
            self.backgroundColor = .white
        }
        self.isAnimatingCard = false
    }
    
    private func saveVote(for subCategory: SubCategory, isYay: Bool) {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        let db = Firestore.firestore()
        let batch = db.batch()
        
        func actuallySaveVote(categoryName: String) {
            let voteData: [String: Any] = [
                "itemName": subCategory.name,
                "imageURL": subCategory.imageURL,
                "isYay": isYay,
                "date": Timestamp(date: Date()),
                "categoryName": categoryName,
                "categoryId": self.category.id,
                "subCategoryId": subCategory.id,
                "userId": userId
            ]
            print("DEBUG: 📝 Saving vote with data: \(voteData)")
            // Create vote document
            let voteRef = db.collection("users").document(userId).collection("votes").document()
            batch.setData(voteData, forDocument: voteRef)
            // Create or update subcategory document
            let subCategoryRef = db.collection("categories").document(self.category.id).collection("subcategories").document(subCategory.id)
            let subCategoryData: [String: Any] = [
                "name": subCategory.name,
                "imageURL": subCategory.imageURL,
                "categoryId": self.category.id,
                "yayCount": isYay ? 1 : 0,
                "nayCount": isYay ? 0 : 1,
                "lastVoteDate": Timestamp(date: Date())
            ]
            batch.setData(subCategoryData, forDocument: subCategoryRef, merge: true)
            // Update user document
            let userRef = db.collection("users").document(userId)
            batch.updateData([
                "votesCount": FieldValue.increment(Int64(1)),
                "lastVoteDate": Timestamp(date: Date())
            ], forDocument: userRef)
            
            let activity = [
                "type": "vote",
                "itemId": subCategory.id,
                "title": subCategory.name,
                "timestamp": Timestamp(date: Date())
            ] as [String: Any]
            batch.updateData([
                "recentActivity": FieldValue.arrayUnion([activity])
            ], forDocument: userRef)
            
            batch.commit { error in
                if let error = error {
                    print("Error saving vote: \(error.localizedDescription)")
                } else {
                    print("Successfully saved vote")
                    DispatchQueue.main.async {
                        self.votedSubCategoryIds.insert(subCategory.id)
                    }
                }
            }
        }
        
        if self.category.name.isEmpty {
            print("DEBUG: 🔍 Fetching category name for ID: \(self.category.id)")
            db.collection("categories").document(self.category.id).getDocument { snapshot, error in
                if let error = error {
                    print("Error fetching category name: \(error.localizedDescription)")
                    return
                }
                let categoryName = snapshot?.data()?["name"] as? String ?? ""
                print("DEBUG: ✅ Fetched category name: \(categoryName)")
                actuallySaveVote(categoryName: categoryName)
            }
        } else {
            print("DEBUG: ✅ Using existing category name: \(self.category.name)")
            actuallySaveVote(categoryName: self.category.name)
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
            if viewModel.subCategories.isEmpty {
                Image(systemName: "tray")
                .font(.system(size: 70))
                .foregroundStyle(.secondary)
                
                Text("No items available")
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(.primary)
                
                VStack(spacing: 8) {
                    Text("There are no items to vote on in this category yet")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    
                    Text("Check back later for new items")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .multilineTextAlignment(.center)
            } else {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 70))
                    .foregroundStyle(.green)
                .symbolEffect(.bounce)
            
                Text("Great job!")
                .font(.title2.weight(.semibold))
                    .foregroundStyle(.primary)
                
                VStack(spacing: 8) {
                    Text("You've voted on all available items")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    
                    Text("Check back later for new items")
                        .font(.subheadline)
                .foregroundStyle(.secondary)
                }
                .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
    }
}

// Card View Component
struct CardView: View {
    let subCategory: SubCategory
    let offset: CGFloat
    let horizontalOffset: CGFloat
    let swipeThreshold: CGFloat
    let horizontalSwipeThreshold: CGFloat
    let onSkip: () -> Void
    @State private var skipAnimationOffset: CGFloat = 0
    
    var body: some View {
        ZStack {
            // Main Card
            VStack(spacing: 0) {
                Spacer(minLength: 64)
                // Title at the top (moved further down)
                Text(subCategory.name)
                    .font(.system(size: 24, weight: .bold))
                    .padding(.top, 0)
                    .padding(.bottom, 16)
                
                // Image
                AsyncImage(url: URL(string: subCategory.imageURL)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                } placeholder: {
                    Color.gray.opacity(0.1)
                }
                .frame(height: UIScreen.main.bounds.height * 0.5)
                
                Spacer(minLength: 24)
                
                // Enhanced Skip Button (centered, smaller, higher, not touching edge)
                HStack {
                    Spacer()
                    Button(action: {
                        withAnimation(.interpolatingSpring(stiffness: 180, damping: 80)) {
                            skipAnimationOffset = 1000
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                            skipAnimationOffset = 0
                            onSkip()
                        }
                    }) {
                        Text("Skip")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.orange)
                            .frame(width: 64, height: 44)
                            .background(
                                Capsule()
                                    .fill(Color.white)
                                    .shadow(color: Color.orange.opacity(0.18), radius: 8, x: 0, y: 4)
                            )
                            .overlay(
                                Capsule()
                                    .stroke(LinearGradient(gradient: Gradient(colors: [Color.yellow, Color.orange]), startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 2)
                            )
                            .accessibilityLabel("Skip")
                            .accessibilityHint("Skip this card")
                    }
                    Spacer()
                }
                .padding(.top, -24)
                .padding(.bottom, 40)
            }
            .frame(width: UIScreen.main.bounds.width - 60, height: UIScreen.main.bounds.height * 0.65)
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 24))
            .shadow(color: .black.opacity(0.15), radius: 12, x: 0, y: 4)
            .offset(x: skipAnimationOffset, y: offset)
            .animation(.interpolatingSpring(stiffness: 180, damping: 80), value: skipAnimationOffset)
            .animation(.interpolatingSpring(stiffness: 180, damping: 100), value: offset)
            
            // Vote Text Overlay
            if abs(offset) > 50 {
                HStack(spacing: 8) {
                    if offset < 0 {
                        Text("YAY 😊")
                            .font(.system(size: 40, weight: .bold))
                            .foregroundColor(.green)
                            .opacity(min(abs(offset) / swipeThreshold, 1.0))
                    } else {
                        Text("NAY 😢")
                            .font(.system(size: 40, weight: .bold))
                            .foregroundColor(.red)
                            .opacity(min(abs(offset) / swipeThreshold, 1.0))
                    }
                }
                .frame(maxWidth: .infinity)
                .offset(y: offset < 0 ? -220 : 220)
                .animation(.interpolatingSpring(stiffness: 180, damping: 100), value: offset)
            }
        }
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