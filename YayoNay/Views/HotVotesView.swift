// MARK: - Hot Votes View
// This view displays the trending content in the app, including:
// 1. Top Categories - Shows the most voted categories
// 2. Today's Trending - Displays items with the most votes in the last 24 hours
// 3. All-Time Best - Shows the highest rated items ever
// This is one of the main tabs in the app's bottom navigation.

import SwiftUI
import FirebaseFirestore

struct HotVoteItem: Identifiable {
    let id: String
    let name: String
    let imageURL: String
    let yayCount: Int
    let nayCount: Int
    let totalVotes: Int
    let yayPercentage: Double
    let nayPercentage: Double
    let categoryId: String
    let categoryName: String
    
    init(id: String, name: String, imageURL: String, yayCount: Int, nayCount: Int, categoryId: String, categoryName: String) {
        self.id = id
        self.name = name
        self.imageURL = imageURL
        self.yayCount = yayCount
        self.nayCount = nayCount
        self.totalVotes = yayCount + nayCount
        self.yayPercentage = Double(yayCount) / Double(max(totalVotes, 1)) * 100
        self.nayPercentage = Double(nayCount) / Double(max(totalVotes, 1)) * 100
        self.categoryId = categoryId
        self.categoryName = categoryName
    }
}

struct TopCategory: Identifiable {
    let id: String
    let name: String
    let totalVotes: Int
    let imageURL: String
    
    init(id: String, name: String, totalVotes: Int, imageURL: String) {
        self.id = id
        self.name = name
        self.totalVotes = totalVotes
        self.imageURL = imageURL
    }
    
    var iconName: String {
        // Default icon if no specific match
        return "star.fill"
    }
    
    var accentColor: Color {
        // Default color if no specific match
        return .yellow
    }
}

class HotVotesViewModel: ObservableObject {
    @Published var hotVotes: [HotVoteItem] = []
    @Published var topCategories: [TopCategory] = []
    @Published var todaysTopVotes: [HotVoteItem] = []
    @Published var hasLoaded = false
    private let db = Firestore.firestore()
    
    // Store all listener registrations
    private var hotVotesListener: ListenerRegistration?
    private var todaysVotesListener: ListenerRegistration?
    private var topCategoriesListener: ListenerRegistration?
    private var subCategoriesListener: ListenerRegistration?
    
    func fetchData() {
        fetchHotVotes()
        setupTopCategoriesListener()
        fetchTodaysTopVotes()
    }
    
    private func fetchHotVotes() {
        // Remove any existing listener
        hotVotesListener?.remove()
        
        // Add new listener and store the registration
        hotVotesListener = db.collection("subCategories")
            .whereField("yayCount", isGreaterThan: 0)  // Only get items with votes
            .order(by: "yayCount", descending: true)
            .limit(to: 50)
            .addSnapshotListener { [weak self] snapshot, error in
                if let error = error {
                    print("Error fetching hot votes: \(error)")
                    return
                }
                
                // First get all categories to map IDs to names
                self?.db.collection("categories").getDocuments { categorySnapshot, error in
                    guard let categoryDocuments = categorySnapshot?.documents else { return }
                    let categoryMap = Dictionary(uniqueKeysWithValues: categoryDocuments.map { ($0.documentID, $0["name"] as? String ?? "") })
                    
                    self?.hotVotes = snapshot?.documents.compactMap { document in
                        let data = document.data()
                        guard let name = data["name"] as? String,
                              let imageURL = data["imageURL"] as? String,
                              let yayCount = data["yayCount"] as? Int,
                              let nayCount = data["nayCount"] as? Int,
                              let categoryId = data["categoryId"] as? String,
                              yayCount + nayCount > 0  // Double check total votes
                        else { return nil }
                        
                        return HotVoteItem(
                            id: document.documentID,
                            name: name,
                            imageURL: imageURL,
                            yayCount: yayCount,
                            nayCount: nayCount,
                            categoryId: categoryId,
                            categoryName: categoryMap[categoryId] ?? ""
                        )
                    }
                    ?? []  // Remove redundant sorting since Firestore query is already sorted
                }
            }
    }
    
    private func setupTopCategoriesListener() {
        // Remove any existing listeners
        topCategoriesListener?.remove()
        subCategoriesListener?.remove()
        
        // First, listen to all subcategories for vote count changes
        subCategoriesListener = db.collection("subCategories")
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }
                
                if let error = error {
                    print("Error listening to subcategories: \(error)")
                    return
                }
                
                // Count votes per category
                var categoryVotes: [String: Int] = [:]
                
                snapshot?.documents.forEach { doc in
                    let data = doc.data()
                    if let categoryId = data["categoryId"] as? String,
                       let yayCount = data["yayCount"] as? Int,
                       let nayCount = data["nayCount"] as? Int {
                        let totalVotes = yayCount + nayCount
                        categoryVotes[categoryId] = (categoryVotes[categoryId] ?? 0) + totalVotes
                    }
                }
                
                // Then, listen to categories to get their details
                self.topCategoriesListener = self.db.collection("categories")
                    .addSnapshotListener { [weak self] snapshot, error in
                        guard let self = self else { return }
                        
                        if let error = error {
                            print("Error listening to categories: \(error)")
                            return
                        }
                        
                    guard let documents = snapshot?.documents else { return }
                    
                        self.topCategories = documents.compactMap { doc -> TopCategory? in
                        let id = doc.documentID
                            guard let name = doc.data()["name"] as? String,
                                  let imageURL = doc.data()["imageURL"] as? String else { return nil }
                        
                        return TopCategory(
                            id: id,
                            name: name,
                                totalVotes: categoryVotes[id] ?? 0,
                                imageURL: imageURL
                        )
                    }
                    .sorted { $0.totalVotes > $1.totalVotes }
                    .prefix(5)
                    .map { $0 }
                }
            }
    }
    
    private func fetchTodaysTopVotes() {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else {
            print("Error: Could not calculate end of day")
            return
        }
        
        // Remove any existing listener
        todaysVotesListener?.remove()
        
        // First get all categories to map IDs to names
        db.collection("categories").getDocuments { [weak self] categorySnapshot, error in
            guard let categoryDocuments = categorySnapshot?.documents else { return }
            let categoryMap = Dictionary(uniqueKeysWithValues: categoryDocuments.map { ($0.documentID, $0["name"] as? String ?? "") })
            
            // Add new listener and store the registration
            self?.todaysVotesListener = self?.db.collection("votes")
                .whereField("date", isGreaterThan: Timestamp(date: startOfDay))
                .whereField("date", isLessThan: Timestamp(date: endOfDay))
                .addSnapshotListener { snapshot, error in
                    if let error = error {
                        print("Error fetching today's votes: \(error)")
                        return
                    }
                    
                    // Count votes by item
                    var itemVotes: [String: (name: String, imageURL: String, yay: Int, nay: Int, categoryId: String, categoryName: String)] = [:]
                    
                    snapshot?.documents.forEach { doc in
                        let data = doc.data()
                        if let itemId = data["subCategoryId"] as? String,
                           let name = data["itemName"] as? String,
                           let imageURL = data["imageURL"] as? String,
                           let isYay = data["isYay"] as? Bool,
                           let categoryId = data["categoryId"] as? String {
                            if let existing = itemVotes[itemId] {
                                itemVotes[itemId] = (
                                    name: name,
                                    imageURL: imageURL,
                                    yay: existing.yay + (isYay ? 1 : 0),
                                    nay: existing.nay + (isYay ? 0 : 1),
                                    categoryId: categoryId,
                                    categoryName: categoryMap[categoryId] ?? ""
                                )
                            } else {
                                itemVotes[itemId] = (
                                    name: name,
                                    imageURL: imageURL,
                                    yay: isYay ? 1 : 0,
                                    nay: isYay ? 0 : 1,
                                    categoryId: categoryId,
                                    categoryName: categoryMap[categoryId] ?? ""
                                )
                            }
                        }
                    }
                    
                    // Convert to HotVoteItem array and sort by yay count instead of total votes
                    self?.todaysTopVotes = itemVotes
                        .map { id, info in
                            HotVoteItem(
                                id: id,
                                name: info.name,
                                imageURL: info.imageURL,
                                yayCount: info.yay,
                                nayCount: info.nay,
                                categoryId: info.categoryId,
                                categoryName: info.categoryName
                            )
                        }
                        .sorted { $0.yayCount > $1.yayCount }  // Sort by yay count instead of total votes
                        .prefix(10)
                        .map { $0 }
                }
        }
    }
    
    deinit {
        // Clean up all listeners when the view model is deallocated
        hotVotesListener?.remove()
        todaysVotesListener?.remove()
        topCategoriesListener?.remove()
        subCategoriesListener?.remove()
    }
}

struct HotVotesView: View {
    @StateObject private var viewModel = HotVotesViewModel()
    @State private var selectedSubCategory: SubCategory?
    @State private var showSubCategoryDetail = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 32) {
                    // Top Categories Section
                    VStack(alignment: .leading, spacing: 16) {
                        SectionHeader(title: "Top Categories", subtitle: "Most voted categories")
                        
                        ForEach(Array(viewModel.topCategories.enumerated()), id: \.element.id) { index, category in
                            TopCategoryRow(index: index + 1, category: category)
                        }
                    }
                    
                    // Today's Top Votes Section
                    VStack(alignment: .leading, spacing: 16) {
                        SectionHeader(title: "Today's Trending", subtitle: "Most popular in the last 24 hours")
                        
                        ForEach(Array(viewModel.todaysTopVotes.enumerated()), id: \.element.id) { index, item in
                            HotVoteCard(item: item, index: index + 1)
                        }
                    }
                    
                    // All-Time Top Votes Section
                    VStack(alignment: .leading, spacing: 16) {
                        SectionHeader(title: "All-Time Best", subtitle: "Highest rated items ever")
                        
                        ForEach(Array(viewModel.hotVotes.enumerated()), id: \.element.id) { index, item in
                            HotVoteCard(item: item, index: index + 1)
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 24)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Hot Votes")
        }
        .onAppear {
            if !viewModel.hasLoaded {
                viewModel.fetchData()
                viewModel.hasLoaded = true
            }
        }
    }
}

struct TopCategoryRow: View {
    let index: Int
    let category: TopCategory
    
    var body: some View {
        NavigationLink(destination: CategoryDetailView(category: Category(
            id: category.id,
            name: category.name,
            isTopCategory: true,
            order: index
        ))) {
            HStack(spacing: 16) {
                // Rank Circle
                ZStack {
                    Circle()
                        .fill(getRankColor(index))
                        .frame(width: 32, height: 32)
                        .shadow(color: Color.black.opacity(0.10), radius: 4, y: 2)
                    Text("\(index)")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.white)
                }
                .accessibilityHidden(true)
                
                // Category Image and Name
                HStack {
                    AsyncImage(url: URL(string: category.imageURL)) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Image(systemName: category.iconName)
                            .font(.system(size: 20))
                            .foregroundStyle(category.accentColor)
                    }
                    .frame(width: 44, height: 44)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.cyan.opacity(0.18), lineWidth: 2)
                    )
                    .accessibilityHidden(true)
                    
                    Text(category.name)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.primary)
                }
                
                Spacer()
                
                // Vote Count
                Text("\(category.totalVotes) votes")
                    .font(.system(size: 15))
                    .foregroundStyle(.secondary)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 18)
                    .fill(LinearGradient(
                        colors: [Color.white, Color.cyan.opacity(0.04)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .overlay(
                        RoundedRectangle(cornerRadius: 18)
                            .stroke(Color.cyan.opacity(0.10), lineWidth: 1)
                    )
            )
            .clipShape(RoundedRectangle(cornerRadius: 18))
            .shadow(color: Color.black.opacity(0.06), radius: 6, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(index). \(category.name), \(category.totalVotes) votes")
        .accessibilityHint("Double tap to view \(category.name) items")
    }
    
    private func getRankColor(_ rank: Int) -> Color {
        switch rank {
        case 1: return .yellow // Gold
        case 2: return .gray // Silver
        case 3: return .brown // Bronze
        default: return .secondary
        }
    }
}

struct HotVoteCard: View {
    let item: HotVoteItem
    let index: Int
    @State private var selectedSubCategory: SubCategory?
    
    var body: some View {
        NavigationLink(destination: Group {
            if let subCategory = selectedSubCategory {
                CategoryDetailView(
                    category: Category(
                        id: item.categoryId,
                        name: item.categoryName,
                        isTopCategory: true,
                        order: index
                    ),
                    initialSubCategoryId: subCategory.id
                )
            } else {
                ProgressView()
            }
        }) {
            HStack(spacing: 16) {
                // Rank Circle
                ZStack {
                    Circle()
                        .fill(getRankColor(index))
                        .frame(width: 32, height: 32)
                        .shadow(color: Color.black.opacity(0.10), radius: 4, y: 2)
                    Text("\(index)")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.white)
                }
                .accessibilityHidden(true)
                
                // Item Image and Name
                HStack(spacing: 12) {
                    AsyncImage(url: URL(string: item.imageURL)) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Color.gray.opacity(0.1)
                    }
                    .frame(width: 44, height: 44)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.cyan.opacity(0.18), lineWidth: 2)
                    )
                    
                    Text(item.name)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.primary)
                        .lineLimit(1)
                }
                
                Spacer()
                
                // Vote Count
                Text("\(item.totalVotes) votes")
                    .font(.system(size: 15))
                    .foregroundStyle(.secondary)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 18)
                    .fill(LinearGradient(
                        colors: [Color.white, Color.cyan.opacity(0.04)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .overlay(
                        RoundedRectangle(cornerRadius: 18)
                            .stroke(Color.cyan.opacity(0.10), lineWidth: 1)
                    )
            )
            .clipShape(RoundedRectangle(cornerRadius: 18))
            .shadow(color: Color.black.opacity(0.06), radius: 6, y: 2)
            .onAppear {
                // Fetch subcategory details
                let db = Firestore.firestore()
                db.collection("subCategories").document(item.id).getDocument { snapshot, error in
                    if let data = snapshot?.data(),
                       let name = data["name"] as? String,
                       let imageURL = data["imageURL"] as? String,
                       let categoryId = data["categoryId"] as? String,
                       let order = data["order"] as? Int,
                       let yayCount = data["yayCount"] as? Int,
                       let nayCount = data["nayCount"] as? Int {
                        
                        selectedSubCategory = SubCategory(
                            id: item.id,
                            name: name,
                            imageURL: imageURL,
                            categoryId: categoryId,
                            order: order,
                            yayCount: yayCount,
                            nayCount: nayCount,
                            attributes: [:]
                        )
                    }
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(index). \(item.name), \(item.totalVotes) votes")
        .accessibilityHint("Double tap to view and vote on this item")
    }
    
    private func getRankColor(_ rank: Int) -> Color {
        switch rank {
        case 1: return .yellow // Gold
        case 2: return .gray // Silver
        case 3: return .brown // Bronze
        default: return .secondary
        }
    }
}

struct SectionHeader: View {
    let title: String
    let subtitle: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.title2)
                .fontWeight(.bold)
            
            Text(subtitle)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }
}

#Preview {
    HotVotesView()
} 