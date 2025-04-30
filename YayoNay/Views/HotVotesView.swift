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
    
    var iconName: String {
        switch name.lowercased() {
        case "food": return "fork.knife"
        case "fruit": return "leaf.fill"
        case "drinks", "drink": return "cup.and.saucer.fill"
        case "dessert": return "birthday.cake.fill"
        case "sports", "sport": return "figure.run"
        case "hike": return "mountain.2.fill"
        case "travel": return "airplane"
        case "art", "arts": return "paintbrush.fill"
        case "music": return "music.note"
        case "movies", "movie": return "film"
        case "books", "book": return "book.fill"
        case "technology", "tech": return "laptopcomputer"
        case "fashion": return "tshirt.fill"
        default: return "star.fill"
        }
    }
    
    var accentColor: Color {
        switch name.lowercased() {
        case "food": return .orange
        case "fruit": return .green
        case "drinks", "drink": return .blue
        case "dessert": return .pink
        case "sports", "sport": return .red
        case "hike": return .mint
        case "travel": return .purple
        case "art", "arts": return .indigo
        case "music": return .pink
        case "movies", "movie": return .brown
        case "books", "book": return .green
        case "technology", "tech": return .gray
        case "fashion": return .mint
        default: return .yellow
        }
    }
}

class HotVotesViewModel: ObservableObject {
    @Published var hotVotes: [HotVoteItem] = []
    @Published var topCategories: [TopCategory] = []
    @Published var todaysTopVotes: [HotVoteItem] = []
    private let db = Firestore.firestore()
    
    func fetchData() {
        fetchHotVotes()
        fetchTopCategories()
        fetchTodaysTopVotes()
    }
    
    private func fetchHotVotes() {
        db.collection("subCategories")
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
                    .sorted { $0.yayCount > $1.yayCount }
                    ?? []
                }
            }
    }
    
    func fetchTopCategories() {
        // First get all votes to count by category
        db.collection("votes")
            .getDocuments { [weak self] snapshot, error in
                if let error = error {
                    print("Error fetching top categories: \(error)")
                    return
                }
                
                // Count votes per category
                var categoryVotes: [String: (name: String, votes: Int)] = [:]
                
                snapshot?.documents.forEach { doc in
                    let data = doc.data()
                    if let categoryId = data["categoryId"] as? String,
                       let categoryName = data["categoryName"] as? String {
                        let current = categoryVotes[categoryId]?.votes ?? 0
                        categoryVotes[categoryId] = (categoryName, current + 1)
                    }
                }
                
                // Get categories and combine with vote counts
                self?.db.collection("categories").getDocuments { snapshot, error in
                    guard let documents = snapshot?.documents else { return }
                    
                    self?.topCategories = documents.compactMap { doc -> TopCategory? in
                        let id = doc.documentID
                        guard let name = doc["name"] as? String else { return nil }
                        let votes = categoryVotes[id]?.votes ?? 0
                        
                        return TopCategory(
                            id: id,
                            name: name,
                            totalVotes: votes
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
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        // First get all categories to map IDs to names
        db.collection("categories").getDocuments { [weak self] categorySnapshot, error in
            guard let categoryDocuments = categorySnapshot?.documents else { return }
            let categoryMap = Dictionary(uniqueKeysWithValues: categoryDocuments.map { ($0.documentID, $0["name"] as? String ?? "") })
            
            self?.db.collection("votes")
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
}

struct HotVotesView: View {
    @StateObject private var viewModel = HotVotesViewModel()
    
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
                            HotVoteCard(index: index + 1, item: item)
                        }
                    }
                    
                    // All-Time Top Votes Section
                    VStack(alignment: .leading, spacing: 16) {
                        SectionHeader(title: "All-Time Best", subtitle: "Highest rated items ever")
                        
                        ForEach(Array(viewModel.hotVotes.enumerated()), id: \.element.id) { index, item in
                            HotVoteCard(index: index + 1, item: item)
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
            viewModel.fetchData()
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
                    
                    Text("\(index)")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.white)
                }
                .accessibilityHidden(true) // Hide from VoiceOver since we include it in the label
                
                // Category Icon and Name
                HStack {
                    Image(systemName: category.iconName)
                        .font(.system(size: 20))
                        .foregroundStyle(category.accentColor)
                        .accessibilityHidden(true) // Hide from VoiceOver since we describe it in the label
                    
                    Text(category.name)
                        .font(.system(size: 17, weight: .semibold))
                }
                
                Spacer()
                
                // Vote Count
                Text("\(category.totalVotes) votes")
                    .font(.system(size: 15))
                    .foregroundStyle(.secondary)
            }
            .padding()
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: Color.black.opacity(0.1), radius: 5, y: 2)
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
    let index: Int
    let item: HotVoteItem
    
    private var category: Category {
        Category(
            id: item.categoryId,
            name: item.categoryName,
            isTopCategory: true,
            order: index
        )
    }
    
    var body: some View {
        NavigationLink(destination: CategoryDetailView(category: Category(id: item.categoryId, name: item.categoryName, isTopCategory: true, order: index), initialSubCategoryId: item.id)) {
            VStack(spacing: 12) {
                HStack(spacing: 16) {
                    // Rank and Image
                    ZStack(alignment: .topLeading) {
                        AsyncImage(url: URL(string: item.imageURL)) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        } placeholder: {
                            Color.gray.opacity(0.2)
                        }
                        .frame(width: 80, height: 80)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .accessibilityHidden(true) // Hide from VoiceOver since we describe it in the label
                        
                        // Rank Badge
                        Text("\(index)")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 24, height: 24)
                            .background(
                                Circle()
                                    .fill(Color.blue)
                                    .shadow(radius: 2)
                            )
                            .offset(x: -8, y: -8)
                            .accessibilityHidden(true) // Hide from VoiceOver since we include it in the label
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text(item.name)
                            .font(.system(size: 17, weight: .semibold))
                        
                        HStack {
                            Text("\(item.yayCount) yays")
                                .font(.system(size: 15, weight: .medium))
                                .foregroundStyle(.green)
                            Text("(\(item.totalVotes) total)")
                                .font(.system(size: 13))
                                .foregroundStyle(.secondary)
                        }
                    }
                    
                    Spacer()
                }
                
                // Vote Progress Bar
                VStack(spacing: 6) {
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            // Background
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.red.opacity(0.3))
                                .frame(height: 16)
                            
                            // Yay Progress
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.green.opacity(0.7))
                                .frame(width: geometry.size.width * CGFloat(item.yayPercentage) / 100, height: 16)
                        }
                    }
                    .frame(height: 16)
                    .accessibilityHidden(true) // Hide from VoiceOver since we describe it in the label
                    
                    // Vote Stats
                    HStack {
                        HStack(spacing: 4) {
                            Image(systemName: "hand.thumbsdown.fill")
                            Text("\(Int(item.nayPercentage))%")
                        }
                        .foregroundStyle(.red)
                        
                        Spacer()
                        
                        HStack(spacing: 4) {
                            Text("\(Int(item.yayPercentage))%")
                            Image(systemName: "hand.thumbsup.fill")
                        }
                        .foregroundStyle(.green)
                    }
                    .font(.system(size: 13, weight: .medium))
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: Color.black.opacity(0.05), radius: 8, y: 4)
        }
        .buttonStyle(PlainButtonStyle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(index). \(item.name)")
        .accessibilityValue("\(item.yayCount) yays, \(item.nayCount) nays. \(Int(item.yayPercentage))% positive")
        .accessibilityHint("Double tap to view and vote on this item")
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