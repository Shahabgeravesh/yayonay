import SwiftUI
import FirebaseFirestore

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
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Filter and Sort Options
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        // Filter Options
                        ForEach(VotesViewModel.FilterOption.allCases, id: \.self) { option in
                            FilterButton(
                                title: option.rawValue,
                                isSelected: viewModel.filterOption == option,
                                action: { viewModel.filterOption = option }
                            )
                        }
                        
                        Divider()
                            .frame(height: 24)
                        
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
                            VoteCard(vote: vote)
                                .listRowInsets(EdgeInsets())
                                .listRowSeparator(.hidden)
                                .padding(.vertical, 4)
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Your Votes")
            .searchable(text: $searchText, prompt: "Search votes")
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
    
    var body: some View {
        NavigationLink {
            SubCategoryStatsView(subCategory: SubCategory(
                id: vote.subCategoryId,
                name: vote.itemName,
                imageURL: vote.imageURL,
                categoryId: vote.categoryId,
                order: 0,
                yayCount: 0,
                nayCount: 0
            ))
        } label: {
            HStack(spacing: 12) {
                // Image
                AsyncImage(url: URL(string: vote.imageURL)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Color.gray.opacity(0.2)
                }
                .frame(width: 50, height: 50)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                
                // Content
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(vote.itemName)
                            .font(.headline)
                        
                        Text(vote.isYay ? "Yay!" : "Nay!")
                            .font(.subheadline)
                            .foregroundColor(vote.isYay ? .green : .red)
                    }
                    
                    Text(formatDate(vote.date))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Only one chevron
                Image(systemName: "chevron.forward")
                    .foregroundStyle(.secondary)
                    .font(.system(size: 14))
            }
            .padding()
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: Color.black.opacity(0.1), radius: 5, y: 2)
        }
        .buttonStyle(.plain)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "M/d/yy"
        return formatter.string(from: date)
    }
}

#Preview {
    VotesView()
} 