import SwiftUI
import FirebaseFirestore

struct ExploreView: View {
    @StateObject private var viewModel = ExploreViewModel()
    @StateObject private var subCategoryViewModel = SubCategoryViewModel(categoryId: "")
    @State private var selectedCategory: Category?
    @State private var selectedSubCategory: SubCategory?
    @State private var showCategoryDetail = false
    @State private var searchText = ""
    @State private var isSearching = false
    @State private var searchResults: [SubCategory] = []
    @State private var subCategories: [SubCategory] = []
    
    private func updateSearchResults(for searchText: String) {
        if searchText.isEmpty {
            searchResults = []
            return
        }
        
        // Search through subcategories
        let matches = subCategories.filter { subCategory in
            subCategory.name.localizedCaseInsensitiveContains(searchText)
        }
        
        searchResults = matches
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Search Bar
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundStyle(.secondary)
                        
                        TextField("Search for items", text: $searchText)
                            .onChange(of: searchText) { newValue in
                                updateSearchResults(for: newValue)
                            }
                        
                        if !searchText.isEmpty {
                            Button(action: {
                                searchText = ""
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .padding(12)
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .padding(.horizontal)
                    
                    if !searchResults.isEmpty {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Search Results")
                                .font(.system(size: 24, weight: .bold))
                                .padding(.horizontal)
                            
                            LazyVGrid(columns: [
                                GridItem(.flexible(), spacing: 16),
                                GridItem(.flexible(), spacing: 16)
                            ], spacing: 16) {
                                ForEach(searchResults) { subCategory in
                                    SubCategoryCard(subCategory: subCategory)
                                        .onTapGesture {
                                            if let category = viewModel.categories.first(where: { $0.id == subCategory.categoryId }) {
                                                selectedCategory = category
                                                selectedSubCategory = subCategory
                                                showCategoryDetail = true
                                            }
                                        }
                                }
                            }
                            .padding(.horizontal)
                        }
                    } else {
                        // Featured Section
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Featured Categories")
                                .font(.system(size: 24, weight: .bold))
                                .padding(.horizontal)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 20) {
                                    ForEach(viewModel.categories.prefix(5)) { category in
                                        FeaturedCategoryCard(category: category)
                                            .onTapGesture {
                                                withAnimation(.spring()) {
                                                    selectedCategory = category
                                                    showCategoryDetail = true
                                                }
                                            }
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                        
                        // All Categories Section
                        VStack(alignment: .leading, spacing: 16) {
                            Text("All Categories")
                                .font(.system(size: 24, weight: .bold))
                                .padding(.horizontal)
                            
                            LazyVGrid(columns: [
                                GridItem(.flexible(), spacing: 16),
                                GridItem(.flexible(), spacing: 16)
                            ], spacing: 16) {
                                ForEach(viewModel.categories) { category in
                                    CategoryCard(category: category)
                                        .onTapGesture {
                                            withAnimation(.spring()) {
                                                selectedCategory = category
                                                showCategoryDetail = true
                                            }
                                        }
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                }
                .padding(.vertical)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Explore")
            .navigationDestination(isPresented: $showCategoryDetail) {
                if let category = selectedCategory {
                    CategoryDetailView(
                        category: category,
                        initialSubCategoryId: selectedSubCategory?.id
                    )
                }
            }
        }
        .onAppear {
            viewModel.fetchCategories()
            fetchAllSubCategories()
        }
    }
    
    private func fetchAllSubCategories() {
        let db = Firestore.firestore()
        db.collection("subCategories").getDocuments { snapshot, error in
            if let error = error {
                print("Error fetching subcategories: \(error)")
                return
            }
            
            if let documents = snapshot?.documents {
                subCategories = documents.compactMap { document in
                    let data = document.data()
                    guard let name = data["name"] as? String,
                          let imageURL = data["imageURL"] as? String,
                          let categoryId = data["categoryId"] as? String,
                          let yayCount = data["yayCount"] as? Int,
                          let nayCount = data["nayCount"] as? Int else {
                        return nil
                    }
                    
                    return SubCategory(
                        id: document.documentID,
                        name: name,
                        imageURL: imageURL,
                        categoryId: categoryId,
                        order: 0,
                        yayCount: yayCount,
                        nayCount: nayCount,
                        attributes: [:]
                    )
                }
            }
        }
    }
}

struct SubCategoryCard: View {
    let subCategory: SubCategory
    
    var body: some View {
        VStack(spacing: 12) {
            AsyncImage(url: URL(string: subCategory.imageURL)) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Color.gray.opacity(0.2)
            }
            .frame(height: 120)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            
            Text(subCategory.name)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(.primary)
                .lineLimit(2)
                .multilineTextAlignment(.center)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
    }
}

struct FeaturedCategoryCard: View {
    let category: Category
    
    private var cardColor: Color {
        let colors: [Color] = [
            Color(red: 0.20, green: 0.60, blue: 0.86),
            Color(red: 0.61, green: 0.35, blue: 0.71),
            Color(red: 0.95, green: 0.40, blue: 0.50),
            Color(red: 0.98, green: 0.55, blue: 0.38),
            Color(red: 0.30, green: 0.69, blue: 0.31)
        ]
        let index = abs(category.iconName.hashValue) % colors.count
        return colors[index]
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 20)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                cardColor.opacity(0.2),
                                cardColor.opacity(0.1)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        cardColor.opacity(0.3),
                                        cardColor.opacity(0.1)
                                    ]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
                
                Image(systemName: category.iconName)
                    .font(.system(size: 36, weight: .medium))
                    .foregroundColor(cardColor)
            }
            .frame(width: 140, height: 140)
            
            Text(category.name)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.primary)
                .lineLimit(2)
        }
        .frame(width: 140)
    }
}

struct CategoryCard: View {
    let category: Category
    
    private var cardColor: Color {
        let colors: [Color] = [
            Color(red: 0.20, green: 0.60, blue: 0.86),
            Color(red: 0.61, green: 0.35, blue: 0.71),
            Color(red: 0.95, green: 0.40, blue: 0.50),
            Color(red: 0.98, green: 0.55, blue: 0.38),
            Color(red: 0.30, green: 0.69, blue: 0.31)
        ]
        let index = abs(category.iconName.hashValue) % colors.count
        return colors[index]
    }
    
    var body: some View {
        VStack(spacing: 12) {
                    ZStack {
                RoundedRectangle(cornerRadius: 20)
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        cardColor.opacity(0.2),
                                        cardColor.opacity(0.1)
                                    ]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .overlay(
                        RoundedRectangle(cornerRadius: 20)
                                    .stroke(
                                        LinearGradient(
                                            gradient: Gradient(colors: [
                                        cardColor.opacity(0.3),
                                                cardColor.opacity(0.1)
                                            ]),
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ),
                                        lineWidth: 1
                                    )
                            )
                        
                Image(systemName: category.iconName)
                    .font(.system(size: 28, weight: .medium))
                            .foregroundColor(cardColor)
                    }
            .frame(height: 120)
                    
            Text(category.name)
                .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.primary)
                .lineLimit(2)
                        .multilineTextAlignment(.center)
                }
                .padding()
        .background(Color(.systemBackground))
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
    }
}

class ExploreViewModel: ObservableObject {
    @Published var categories: [Category] = []
    private let db = Firestore.firestore()
    
    func fetchCategories() {
        db.collection("categories")
            .order(by: "order")
            .addSnapshotListener { [weak self] snapshot, error in
                if let error = error {
                    print("Error fetching categories: \(error)")
                    return
                }
                
                self?.categories = snapshot?.documents.compactMap { document in
                    Category(document: document)
                } ?? []
            }
    }
}

#Preview {
    ExploreView()
} 