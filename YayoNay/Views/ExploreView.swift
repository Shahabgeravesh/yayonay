import SwiftUI
import FirebaseFirestore

struct ExploreView: View {
    @StateObject private var viewModel = ExploreViewModel()
    @State private var selectedCategory: Category?
    @State private var showCategoryDetail = false
    @State private var searchText = ""
    @State private var isSearching = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 32) {
                    // Search Bar
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.gray)
                        TextField("Search categories...", text: $searchText)
                            .font(.system(size: 16))
                    }
                    .padding(12)
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    .padding(.horizontal)
                    
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
                .padding(.vertical)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Explore")
            .navigationDestination(isPresented: $showCategoryDetail) {
                if let category = selectedCategory {
                    CategoryDetailView(category: category)
                }
            }
        }
        .onAppear {
            viewModel.fetchCategories()
        }
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