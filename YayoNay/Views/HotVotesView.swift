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
    
    init(id: String, name: String, imageURL: String, yayCount: Int, nayCount: Int) {
        self.id = id
        self.name = name
        self.imageURL = imageURL
        self.yayCount = yayCount
        self.nayCount = nayCount
        self.totalVotes = yayCount + nayCount
        self.yayPercentage = Double(yayCount) / Double(max(totalVotes, 1)) * 100
        self.nayPercentage = Double(nayCount) / Double(max(totalVotes, 1)) * 100
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
        createCategoriesIfNeeded()
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
                
                self?.hotVotes = snapshot?.documents.compactMap { document in
                    let data = document.data()
                    guard let name = data["name"] as? String,
                          let imageURL = data["imageURL"] as? String,
                          let yayCount = data["yayCount"] as? Int,
                          let nayCount = data["nayCount"] as? Int,
                          yayCount + nayCount > 0  // Double check total votes
                    else { return nil }
                    
                    return HotVoteItem(
                        id: document.documentID,
                        name: name,
                        imageURL: imageURL,
                        yayCount: yayCount,
                        nayCount: nayCount
                    )
                }
                .sorted { $0.yayCount > $1.yayCount }
                ?? []
            }
    }
    
    func fetchTopCategories() {
        print("DEBUG: Fetching top categories")
        
        // Get categories with isTopCategory=true
        db.collection("categories")
            .whereField("isTopCategory", isEqualTo: true)
            .order(by: "order")
            .addSnapshotListener { [weak self] snapshot, error in
                if let error = error {
                    print("DEBUG: Error fetching categories: \(error.localizedDescription)")
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    print("DEBUG: No category documents found")
                    return
                }
                
                print("DEBUG: Found \(documents.count) category documents")
                
                let topCategories = documents.compactMap { doc -> TopCategory? in
                    let id = doc.documentID
                    let data = doc.data()
                    
                    print("DEBUG: Processing category document: \(data)")
                    
                    guard let name = data["name"] as? String else {
                        print("DEBUG: Category \(id) missing name")
                        return nil
                    }
                    
                    let votes = data["votesCount"] as? Int ?? 0
                    print("DEBUG: Category \(name) has \(votes) votes")
                    
                    return TopCategory(
                        id: id,
                        name: name,
                        totalVotes: votes
                    )
                }
                .sorted { $0.totalVotes > $1.totalVotes }
                .prefix(5)
                .map { $0 }
                
                print("DEBUG: Top categories: \(topCategories.map { "\($0.name): \($0.totalVotes) votes" })")
                
                DispatchQueue.main.async {
                    self?.topCategories = topCategories
                }
            }
    }
    
    private func fetchTodaysTopVotes() {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        db.collection("votes")
            .whereField("date", isGreaterThan: Timestamp(date: startOfDay))
            .whereField("date", isLessThan: Timestamp(date: endOfDay))
            .addSnapshotListener { [weak self] snapshot, error in
                if let error = error {
                    print("Error fetching today's votes: \(error)")
                    return
                }
                
                // Count votes by item
                var itemVotes: [String: (name: String, imageURL: String, yay: Int, nay: Int)] = [:]
                
                snapshot?.documents.forEach { doc in
                    let data = doc.data()
                    if let itemId = data["subCategoryId"] as? String,
                       let name = data["itemName"] as? String,
                       let imageURL = data["imageURL"] as? String,
                       let isYay = data["isYay"] as? Bool {
                        if let existing = itemVotes[itemId] {
                            itemVotes[itemId] = (
                                name: name,
                                imageURL: imageURL,
                                yay: existing.yay + (isYay ? 1 : 0),
                                nay: existing.nay + (isYay ? 0 : 1)
                            )
                        } else {
                            itemVotes[itemId] = (
                                name: name,
                                imageURL: imageURL,
                                yay: isYay ? 1 : 0,
                                nay: isYay ? 0 : 1
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
                            nayCount: info.nay
                        )
                    }
                    .sorted { $0.yayCount > $1.yayCount }  // Sort by yay count instead of total votes
                    .prefix(10)
                    .map { $0 }
            }
    }
    
    func createCategoriesIfNeeded() {
        print("DEBUG: Checking if categories exist and creating if needed")
        
        // Define categories
        let categories = [
            [
                "name": "Food",
                "description": "Discover delicious dishes",
                "isTopCategory": true,
                "order": 1,
                "featured": true,
                "votesCount": 0
            ],
            [
                "name": "Drinks",
                "description": "Refreshing beverages",
                "isTopCategory": true,
                "order": 2,
                "featured": true,
                "votesCount": 0
            ],
            [
                "name": "Dessert",
                "description": "Sweet treats and delights",
                "isTopCategory": true,
                "order": 3,
                "featured": true,
                "votesCount": 0
            ],
            [
                "name": "Sports",
                "description": "Game on!",
                "isTopCategory": true,
                "order": 4,
                "featured": true,
                "votesCount": 0
            ],
            [
                "name": "Travel",
                "description": "Explore destinations",
                "isTopCategory": true,
                "order": 5,
                "featured": true,
                "votesCount": 0
            ],
            [
                "name": "Art",
                "description": "Creative expressions",
                "isTopCategory": true,
                "order": 6,
                "featured": true,
                "votesCount": 0
            ],
            [
                "name": "Music",
                "description": "Rhythm and melodies",
                "isTopCategory": true,
                "order": 7,
                "featured": true,
                "votesCount": 0
            ],
            [
                "name": "Movies",
                "description": "Cinematic experiences",
                "isTopCategory": true,
                "order": 8,
                "featured": true,
                "votesCount": 0
            ],
            [
                "name": "Books",
                "description": "Literary adventures",
                "isTopCategory": true,
                "order": 9,
                "featured": true,
                "votesCount": 0
            ],
            [
                "name": "Technology",
                "description": "Innovation and gadgets",
                "isTopCategory": true,
                "order": 10,
                "featured": true,
                "votesCount": 0
            ]
        ]
        
        // Check if categories collection exists and has documents
        db.collection("categories").getDocuments { [weak self] snapshot, error in
            if let error = error {
                print("DEBUG: Error checking categories: \(error.localizedDescription)")
                return
            }
            
            // If there are no categories, create them
            if snapshot?.documents.isEmpty ?? true {
                print("DEBUG: No categories found, creating default categories")
                
                for category in categories {
                    self?.db.collection("categories").addDocument(data: category) { error in
                        if let error = error {
                            print("DEBUG: Error adding category \(category["name"] ?? "unknown"): \(error.localizedDescription)")
                        } else {
                            print("DEBUG: Successfully added category: \(category["name"] ?? "unknown")")
                        }
                    }
                }
            } else {
                print("DEBUG: Categories already exist, count: \(snapshot?.documents.count ?? 0)")
            }
        }
    }
}

struct HotVotesView: View {
    @StateObject private var viewModel = HotVotesViewModel()
    @State private var isLoading = true
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 32) {
                    // Top Categories Section
                    VStack(alignment: .leading, spacing: 16) {
                        SectionHeader(title: "Top Categories", subtitle: "Most voted categories")
                        
                        if viewModel.topCategories.isEmpty {
                            Text("No categories with votes yet")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .padding()
                                .frame(maxWidth: .infinity, alignment: .center)
                                .background(Color(.systemBackground))
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                                .shadow(color: Color.black.opacity(0.1), radius: 5, y: 2)
                        } else {
                            ForEach(Array(viewModel.topCategories.enumerated()), id: \.element.id) { index, category in
                                TopCategoryRow(index: index + 1, category: category)
                            }
                        }
                    }
                    
                    // Today's Top Votes Section
                    VStack(alignment: .leading, spacing: 16) {
                        SectionHeader(title: "Today's Trending", subtitle: "Most popular in the last 24 hours")
                        
                        if viewModel.todaysTopVotes.isEmpty {
                            Text("No votes today yet")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .padding()
                                .frame(maxWidth: .infinity, alignment: .center)
                                .background(Color(.systemBackground))
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                                .shadow(color: Color.black.opacity(0.1), radius: 5, y: 2)
                        } else {
                            ForEach(Array(viewModel.todaysTopVotes.enumerated()), id: \.element.id) { index, item in
                                HotVoteCard(index: index + 1, item: item)
                            }
                        }
                    }
                    
                    // All-Time Top Votes Section
                    VStack(alignment: .leading, spacing: 16) {
                        SectionHeader(title: "All-Time Best", subtitle: "Highest rated items ever")
                        
                        if viewModel.hotVotes.isEmpty {
                            Text("No votes yet")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .padding()
                                .frame(maxWidth: .infinity, alignment: .center)
                                .background(Color(.systemBackground))
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                                .shadow(color: Color.black.opacity(0.1), radius: 5, y: 2)
                        } else {
                            ForEach(Array(viewModel.hotVotes.enumerated()), id: \.element.id) { index, item in
                                HotVoteCard(index: index + 1, item: item)
                            }
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 24)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Hot Votes")
            .overlay {
                if isLoading {
                    ProgressView()
                        .scaleEffect(1.5)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.black.opacity(0.1))
                }
            }
        }
        .onAppear {
            print("DEBUG: HotVotesView appeared")
            isLoading = true
            viewModel.fetchData()
            
            // Set a timer to hide the loading indicator after a reasonable time
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                isLoading = false
            }
        }
    }
}

struct TopCategoryRow: View {
    let index: Int
    let category: TopCategory
    
    var body: some View {
        NavigationLink {
            CategoryDetailView(category: Category(
                id: category.id,
                name: category.name,
                isTopCategory: true,
                order: index
            ))
            .onAppear {
                print("DEBUG: Navigating to CategoryDetailView for category: \(category.name) (ID: \(category.id))")
            }
        } label: {
            HStack(spacing: 16) {
                // Rank Circle
                ZStack {
                    Circle()
                        .fill(getRankColor(index))
                        .frame(width: 32, height: 32)
                    
                    Text("\(index)")
                        .font(.headline)
                        .foregroundColor(.white)
                }
                
                // Category Icon and Name
                HStack {
                    Image(systemName: category.iconName)
                        .font(.title3)
                        .foregroundStyle(category.accentColor)
                    
                    Text(category.name)
                        .font(.headline)
                }
                
                Spacer()
                
                // Vote Count
                Text("\(category.totalVotes) votes")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding()
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: Color.black.opacity(0.1), radius: 5, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
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
    
    var body: some View {
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
                    
                    // Rank Badge
                    Text("\(index)")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .frame(width: 24, height: 24)
                        .background(
                            Circle()
                                .fill(Color.blue)
                                .shadow(radius: 2)
                        )
                        .offset(x: -8, y: -8)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text(item.name)
                        .font(.headline)
                    
                    HStack {
                        Text("\(item.yayCount) yays")
                            .foregroundStyle(.green)
                            .fontWeight(.medium)
                        Text("(\(item.totalVotes) total)")
                            .font(.caption)
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
                .font(.caption)
                .fontWeight(.medium)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: Color.black.opacity(0.05), radius: 8, y: 4)
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