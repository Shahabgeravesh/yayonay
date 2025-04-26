//This is My Votes tab in the app.

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
        db.collection("votes")
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
        db.collection("votes").document(vote.id).delete() { error in
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
    
    // Helper function to convert Vote to SubCategory
    private func createSubCategory(from vote: Vote) -> SubCategory {
        return SubCategory(
            id: vote.subCategoryId,
            name: vote.itemName,
            imageURL: vote.imageURL,
            categoryId: vote.categoryId,
            order: 0, // Default order value
            yayCount: vote.isYay ? 1 : 0,
            nayCount: vote.isYay ? 0 : 1
        )
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
                            NavigationLink {
                                SubCategoryStatsView(subCategory: createSubCategory(from: vote))
                            } label: {
                                VoteCard(vote: vote, isClickable: false)
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
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? Color.blue : Color.gray.opacity(0.1))
                .foregroundColor(isSelected ? .white : .primary)
                .clipShape(Capsule())
        }
    }
}

struct SortButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Text(title)
                Image(systemName: "arrow.up.arrow.down")
                    .font(.caption)
            }
            .font(.subheadline)
            .fontWeight(.medium)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(isSelected ? Color.blue : Color.gray.opacity(0.1))
            .foregroundColor(isSelected ? .white : .primary)
            .clipShape(Capsule())
        }
    }
}

struct EmptyStateView: View {
    let searchText: String
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "square.stack.3d.up.slash")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            if searchText.isEmpty {
                Text("No votes yet")
                    .font(.title2)
                    .foregroundColor(.gray)
                Text("Start voting on items to see them here")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            } else {
                Text("No matches found")
                    .font(.title2)
                    .foregroundColor(.gray)
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
            } else {
                voteContent
            }
        }
        .onAppear {
            if isClickable {
                print("DEBUG: VoteCard appeared")
                print("DEBUG: CategoryId: \(vote.categoryId)")
                print("DEBUG: SubCategoryId: \(vote.subCategoryId)")
                subCategoryViewModel.fetchSubCategories(for: vote.categoryId)
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
            .clipShape(RoundedRectangle(cornerRadius: 8))
            
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
                        .foregroundColor(vote.isYay ? .green : .red)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(vote.isYay ? Color.green.opacity(0.1) : Color.red.opacity(0.1))
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
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: Color.black.opacity(0.05), radius: 3, y: 1)
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
                        .fill(Color.green.opacity(0.7))
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
