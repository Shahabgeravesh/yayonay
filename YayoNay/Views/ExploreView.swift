// MARK: - Explore View
// This view allows users to browse and discover content by:
// 1. Viewing all available categories
// 2. Searching for specific topics
// 3. Filtering content by interests
// This is one of the main tabs in the app's bottom navigation.

import SwiftUI
import FirebaseFirestore

struct ExploreView: View {
    @StateObject private var viewModel = ExploreViewModel()
    @State private var selectedCategory: Category?
    @State private var selectedSubCategory: SubCategory?
    @State private var showCategoryDetail = false
    @State private var searchText = ""
    @State private var isSearching = false
    @State private var searchResults: [SubCategory] = []
    @State private var subCategories: [SubCategory] = []
    @State private var hasLoaded = false
    
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
                            .foregroundColor(ModernColor.secondaryText)
                            .font(.system(size: 18, weight: .medium))
                        
                        TextField("Search for items", text: $searchText)
                            .font(AppFont.medium(16))
                            .onChange(of: searchText) { newValue in
                                updateSearchResults(for: newValue)
                            }
                        
                        if !searchText.isEmpty {
                            Button(action: {
                                searchText = ""
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(ModernColor.secondaryText)
                                    .font(.system(size: 18))
                            }
                        }
                    }
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(ModernColor.cardBackground)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(ModernColor.border.opacity(0.3), lineWidth: 1)
                            )
                    )
                    .shadow(color: ModernDesign.CardShadow.color, radius: ModernDesign.CardShadow.radius, x: ModernDesign.CardShadow.x, y: ModernDesign.CardShadow.y)
                    .padding(.horizontal)
                    
                    if !searchResults.isEmpty {
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Text("Search Results")
                                    .font(AppFont.bold(24))
                                    .foregroundColor(ModernColor.text)
                                
                                Spacer()
                                
                                Text("\(searchResults.count) found")
                                    .font(AppFont.medium(14))
                                    .foregroundColor(ModernColor.secondaryText)
                            }
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
                            HStack {
                                Text("Featured Categories")
                                    .font(AppFont.bold(24))
                                    .foregroundColor(ModernColor.text)
                                
                                Spacer()
                                
                                Text("\(viewModel.categories.filter { $0.id != "random" }.prefix(5).count) categories")
                                    .font(AppFont.medium(14))
                                    .foregroundColor(ModernColor.secondaryText)
                            }
                            .padding(.horizontal)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 20) {
                                    ForEach(viewModel.categories.filter { $0.id != "random" }.prefix(5)) { category in
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
                        
                        // Discover Hub Section
                        if let randomCategory = viewModel.categories.first(where: { $0.id == "random" }) {
                            VStack(alignment: .leading, spacing: 16) {
                                Text("Discover Hub")
                                    .font(.system(size: 24, weight: .bold))
                                    .padding(.horizontal)
                                
                                DiscoverHubCard(category: randomCategory)
                                    .onTapGesture {
                                        withAnimation(.spring()) {
                                            selectedCategory = randomCategory
                                            showCategoryDetail = true
                                        }
                                    }
                                    .padding(.horizontal)
                            }
                            .padding(.bottom, 8)
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
                                ForEach(viewModel.categories.filter { $0.id != "random" }) { category in
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
            if !hasLoaded {
                viewModel.fetchCategories()
                fetchAllSubCategories()
                hasLoaded = true
            }
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
    @State private var isHovered = false
    
    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                // Gradient border effect
                RoundedRectangle(cornerRadius: 18)
                    .strokeBorder(ModernDesign.primaryGradient, lineWidth: 2)
                    .frame(height: 124)
                
                AsyncImage(url: URL(string: subCategory.imageURL)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    ModernDesign.cardGradient
                }
                .frame(height: 120)
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            
            Text(subCategory.name)
                .font(AppFont.medium(15))
                .foregroundColor(.primary)
                .lineLimit(2)
                .multilineTextAlignment(.center)
        }
        .padding()
        .background(ModernDesign.primaryGradient)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: Color.black.opacity(0.10), radius: 8, y: 4)
        .scaleEffect(isHovered ? 1.03 : 1.0)
        .animation(ModernDesign.hoverAnimation, value: isHovered)
        .onHover { hovering in
            isHovered = hovering
        }
    }
}

struct FeaturedCategoryCard: View {
    let category: Category
    @State private var isHovered = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 20)
                    .fill(ModernDesign.featuredGradient)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(ModernColor.border.opacity(0.3), lineWidth: 1)
                    )
                
                Image(systemName: category.iconName)
                    .font(.system(size: 36, weight: .medium))
                    .foregroundColor(.white)
            }
            .frame(width: 140, height: 140)
            
            Text(category.name)
                .font(AppFont.semibold(16))
                .foregroundColor(ModernColor.text)
                .lineLimit(2)
        }
        .frame(width: 140)
        .shadow(color: ModernDesign.FeaturedShadow.color, radius: ModernDesign.FeaturedShadow.radius, x: ModernDesign.FeaturedShadow.x, y: ModernDesign.FeaturedShadow.y)
        .scaleEffect(isHovered ? 1.05 : 1.0)
        .animation(ModernDesign.hoverAnimation, value: isHovered)
        .onHover { hovering in
            isHovered = hovering
        }
    }
}

struct CategoryCard: View {
    let category: Category
    @State private var isHovered = false
    
    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 20)
                    .fill(ModernDesign.regularGradient)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(ModernColor.border.opacity(0.3), lineWidth: 1)
                    )
                
                Image(systemName: category.iconName)
                    .font(.system(size: 28, weight: .medium))
                    .foregroundColor(.white)
            }
            .frame(height: 120)
            
            Text(category.name)
                .font(AppFont.medium(15))
                .foregroundColor(ModernColor.text)
                .lineLimit(2)
                .multilineTextAlignment(.center)
        }
        .padding()
        .background(ModernColor.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: ModernDesign.RegularShadow.color, radius: ModernDesign.RegularShadow.radius, x: ModernDesign.RegularShadow.x, y: ModernDesign.RegularShadow.y)
        .scaleEffect(isHovered ? 1.02 : 1.0)
        .animation(ModernDesign.hoverAnimation, value: isHovered)
        .onHover { hovering in
            isHovered = hovering
        }
    }
}

struct DiscoverHubCard: View {
    let category: Category
    @State private var isHovered = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ZStack {
                AsyncImage(url: URL(string: category.imageURL ?? "")) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    ModernDesign.cardGradient
                }
                .frame(height: 160)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                
                LinearGradient(
                    gradient: Gradient(colors: [
                        ModernColor.primary.opacity(0.8),
                        ModernColor.primary.opacity(0.4)
                    ]),
                    startPoint: .bottom,
                    endPoint: .top
                )
                .clipShape(RoundedRectangle(cornerRadius: 16))
                
                VStack(alignment: .leading, spacing: 8) {
                    Spacer()
                    
                    HStack {
                        Image(systemName: "dice.fill")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundStyle(ModernDesign.primaryGradient)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(category.name)
                                .font(AppFont.bold(32))
                                .foregroundColor(.white)
                            
                            Text(category.description)
                                .font(AppFont.regular(14))
                                .foregroundColor(.white.opacity(0.9))
                        }
                    }
                }
                .padding(16)
            }
        }
        .shadow(color: ModernDesign.ElevatedShadow.color, radius: ModernDesign.ElevatedShadow.radius, x: ModernDesign.ElevatedShadow.x, y: ModernDesign.ElevatedShadow.y)
        .scaleEffect(isHovered ? 1.02 : 1.0)
        .animation(ModernDesign.hoverAnimation, value: isHovered)
        .onHover { hovering in
            isHovered = hovering
        }
    }
}

class ExploreViewModel: ObservableObject {
    @Published var categories: [Category] = []
    private let db = Firestore.firestore()
    private var listenerRegistration: ListenerRegistration?
    
    func fetchCategories() {
        // Remove any existing listener
        listenerRegistration?.remove()
        
        // Add new listener and store the registration
        listenerRegistration = db.collection("categories")
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
    
    deinit {
        // Clean up the listener when the view model is deallocated
        listenerRegistration?.remove()
    }
}

#Preview {
    ExploreView()
} 