// MARK: - Votes View
// This view displays the user's voting activity, including:
// 1. Recent votes cast by the user
// 2. Vote statistics and history
// 3. Ability to view and manage past votes
// This is one of the main tabs in the app's bottom navigation.

import SwiftUI
import FirebaseFirestore
import FirebaseAuth

class VotesViewModel: ObservableObject {
    @Published var votes: [Vote] = []
    @Published var sortOption: SortOption = .date
    @Published var filterOption: FilterOption = .all
    private let db = Firestore.firestore()
    
    enum SortOption: String, CaseIterable {
        case date = "Date"
        case category = "Category"
        case name = "Name"
    }
    
    enum FilterOption: String, CaseIterable {
        case all = "All"
        case yay = "Yay!"
        case nay = "Nay!"
    }
    
    func fetchVotes() {
        guard let userId = Auth.auth().currentUser?.uid else {
            print("Error: No authenticated user")
            return
        }
        
        db.collection("users").document(userId).collection("votes")
            .order(by: "date", descending: true)
            .addSnapshotListener { [weak self] snapshot, error in
                if let error = error {
                    print("Error fetching votes: \(error)")
                    return
                }
                
                self?.votes = snapshot?.documents.compactMap { document in
                    Vote(document: document)
                } ?? []
            }
    }
    
    func deleteVote(_ vote: Vote) {
        guard let userId = Auth.auth().currentUser?.uid else {
            print("Error: No authenticated user")
            return
        }
        
        db.collection("users").document(userId).collection("votes").document(vote.id).delete() { error in
            if let error = error {
                print("Error deleting vote: \(error)")
            }
        }
    }
    
    func sortedAndFilteredVotes(searchText: String) -> [Vote] {
        var filteredVotes = votes
        
        // Apply filter
        switch filterOption {
        case .yay:
            filteredVotes = filteredVotes.filter { $0.isYay }
        case .nay:
            filteredVotes = filteredVotes.filter { !$0.isYay }
        case .all:
            break
        }
        
        // Apply search
        if !searchText.isEmpty {
            filteredVotes = filteredVotes.filter {
                $0.itemName.localizedCaseInsensitiveContains(searchText) ||
                $0.categoryName.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        // Apply sort
        return filteredVotes.sorted { first, second in
            switch sortOption {
            case .date:
                return first.date > second.date
            case .category:
                return first.categoryName < second.categoryName
            case .name:
                return first.itemName < second.itemName
            }
        }
    }
}

struct VotesView: View {
    @StateObject private var viewModel = VotesViewModel()
    @State private var searchText = ""
    @State private var selectedSubCategory: SubCategory?
    @State private var showSubCategoryStats = false
    
    // Helper function to fetch SubCategory from Firestore
    private func fetchSubCategory(from vote: Vote) {
        let db = Firestore.firestore()
        db.collection("categories")
            .document(vote.categoryId)
            .collection("subcategories")
            .document(vote.subCategoryId)
            .getDocument { snapshot, error in
                if let error = error {
                    print("Error fetching subcategory: \(error)")
                    return
                }
                
                if let data = snapshot?.data(),
                   let name = data["name"] as? String,
                   let imageURL = data["imageURL"] as? String,
                   let categoryId = data["categoryId"] as? String,
                   let order = data["order"] as? Int,
                   let yayCount = data["yayCount"] as? Int,
                   let nayCount = data["nayCount"] as? Int {
                    selectedSubCategory = SubCategory(
                        id: vote.subCategoryId,
                        name: name,
                        imageURL: imageURL,
                        categoryId: categoryId,
                        order: order,
                        yayCount: yayCount,
                        nayCount: nayCount
                    )
                    showSubCategoryStats = true
                }
            }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Filter Options
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        // Filter Options
                        ForEach(VotesViewModel.FilterOption.allCases, id: \.self) { option in
                            FilterButton(
                                title: option.rawValue,
                                isSelected: viewModel.filterOption == option,
                                action: { viewModel.filterOption = option }
                            )
                        }
                        
                        // Sort Options
                        ForEach(VotesViewModel.SortOption.allCases, id: \.self) { option in
                            SortButton(
                                title: option.rawValue,
                                isSelected: viewModel.sortOption == option,
                                action: { viewModel.sortOption = option }
                            )
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                }
                .background(Color(.systemBackground))
                
                if viewModel.sortedAndFilteredVotes(searchText: searchText).isEmpty {
                    EmptyStateView(searchText: searchText)
                } else {
                    // Votes List
                    List {
                        ForEach(viewModel.sortedAndFilteredVotes(searchText: searchText)) { vote in
                            VoteCard(vote: vote, isClickable: false)
                                .onTapGesture {
                                    fetchSubCategory(from: vote)
                                }
                                .listRowInsets(EdgeInsets())
                                .listRowSeparator(.hidden)
                                .padding(.vertical, 4)
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("My Votes")
            .searchable(text: $searchText, prompt: "Search votes...")
            .background(
                NavigationLink(
                    destination: Group {
                        if let subCategory = selectedSubCategory {
                            SubCategoryStatsView(subCategory: subCategory)
                        }
                    },
                    isActive: $showSubCategoryStats
                ) {
                    EmptyView()
                }
            )
        }
        .onAppear {
            viewModel.fetchVotes()
        }
    }
}

struct FilterButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: {
            HapticManager.shared.selection()
            action()
        }) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    isSelected
                        ? ModernDesign.primaryGradient
                        : LinearGradient(
                            colors: [Color.gray.opacity(0.1), Color.gray.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                )
                .foregroundColor(isSelected ? .white : .primary)
                .clipShape(Capsule())
                .shadow(color: isSelected ? Color.black.opacity(0.1) : .clear, radius: 2, y: 1)
        }
    }
}

struct SortButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: {
            HapticManager.shared.selection()
            action()
        }) {
            HStack(spacing: 4) {
                Text(title)
                Image(systemName: "arrow.up.arrow.down")
                    .font(.caption)
            }
            .font(.subheadline)
            .fontWeight(.medium)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                isSelected
                    ? ModernDesign.primaryGradient
                    : LinearGradient(
                        colors: [Color.gray.opacity(0.1), Color.gray.opacity(0.1)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
            )
            .foregroundColor(isSelected ? .white : .primary)
            .clipShape(Capsule())
            .shadow(color: isSelected ? Color.black.opacity(0.1) : .clear, radius: 2, y: 1)
        }
    }
}

struct EmptyStateView: View {
    let searchText: String
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "square.stack.3d.up.slash")
                .font(.system(size: 60))
                .foregroundStyle(ModernDesign.primaryGradient)
            
            if searchText.isEmpty {
                Text("No votes yet")
                    .font(.title2)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                Text("Start voting on items to see them here")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            } else {
                Text("No matches found")
                    .font(.title2)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                Text("Try adjusting your search or filters")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
    }
}

struct VoteCard: View {
    let vote: Vote
    let isClickable: Bool
    @StateObject private var subCategoryViewModel: SubCategoryViewModel
    @State private var isLoading = true
    
    init(vote: Vote, isClickable: Bool = true) {
        self.vote = vote
        self.isClickable = isClickable
        _subCategoryViewModel = StateObject(wrappedValue: SubCategoryViewModel(categoryId: vote.categoryId))
    }
    
    var body: some View {
        Group {
            if isClickable {
                NavigationLink {
                    Group {
                        if let subCategory = subCategoryViewModel.subCategories.first(where: { $0.id == vote.subCategoryId }) {
                            SubCategoryStatsView(subCategory: subCategory)
                        } else {
                            VStack {
                                ProgressView()
                                Text("Loading...")
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .onAppear {
                        print("DEBUG: Navigation destination appeared")
                        print("DEBUG: CategoryId: \(vote.categoryId)")
                        print("DEBUG: SubCategoryId: \(vote.subCategoryId)")
                        print("DEBUG: Current subcategories count: \(subCategoryViewModel.subCategories.count)")
                    }
                } label: {
                    voteContent
                }
                .buttonStyle(.plain)
                .simultaneousGesture(
                    LongPressGesture(minimumDuration: 0.5)
                        .onEnded { _ in
                            HapticManager.shared.longPress()
                        }
                )
            } else {
                voteContent
            }
        }
        .onAppear {
            if isClickable {
                print("DEBUG: VoteCard appeared")
                print("DEBUG: CategoryId: \(vote.categoryId)")
                print("DEBUG: SubCategoryId: \(vote.subCategoryId)")
                subCategoryViewModel.fetchSubCategories()
            }
        }
    }
    
    private var voteContent: some View {
        HStack(spacing: 12) {
            // Item image
            AsyncImage(url: URL(string: vote.imageURL)) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
            }
            .frame(width: 80, height: 80)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.gray.opacity(0.1), lineWidth: 1)
            )
            
            VStack(alignment: .leading, spacing: 8) {
                // Single line for name, vote status, and date
                HStack(alignment: .center, spacing: 8) {
                    // Item name with fixed width
                    Text(vote.itemName)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.primary)
                        .lineLimit(1)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    // Vote status with background
                    Text(vote.isYay ? "Yay!" : "Nay!")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            vote.isYay ? 
                            Color.green :
                            Color.red
                        )
                        .clipShape(Capsule())
                    
                    // Date
                    Text(formatDate(vote.date))
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                        .frame(width: 50, alignment: .trailing)
                }
            }
        }
        .padding(12)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: Color.black.opacity(0.05), radius: 4, y: 2)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "M/d/yy"
        return formatter.string(from: date)
    }
}

struct VoteStatsView: View {
    let yayCount: Int
    let nayCount: Int
    
    private var totalVotes: Int {
        yayCount + nayCount
    }
    
    private var yayPercentage: Double {
        guard totalVotes > 0 else { return 0 }
        return Double(yayCount) / Double(totalVotes) * 100
    }
    
    private var nayPercentage: Double {
        guard totalVotes > 0 else { return 0 }
        return Double(nayCount) / Double(totalVotes) * 100
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Vote counts text
            HStack {
                Text("Yay: \(Int(yayPercentage))%")
                    .foregroundColor(.green)
                Spacer()
                Text("Nay: \(Int(nayPercentage))%")
                    .foregroundColor(.red)
            }
            .font(.caption)
            
            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background bar (Nay)
                    Rectangle()
                        .fill(Color.red.opacity(0.3))
                        .frame(height: 8)
                        .cornerRadius(4)
                    
                    // Foreground bar (Yay)
                    Rectangle()
                        .fill(Color.green)
                        .frame(width: geometry.size.width * CGFloat(yayPercentage / 100), height: 8)
                        .cornerRadius(4)
                }
            }
            .frame(height: 8)
            
            // Total votes
            Text("\(totalVotes) total votes")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .padding(.top, 4)
    }
}

#Preview {
    VotesView()
} 
