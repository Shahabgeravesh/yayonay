import SwiftUI

struct ExploreView: View {
    @StateObject private var viewModel = CategoryViewModel()
    @State private var showError = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Featured Categories Section
                    if !viewModel.categories.filter({ $0.isTopCategory }).isEmpty {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Featured")
                                .font(.title2)
                                .fontWeight(.bold)
                                .padding(.horizontal)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 16) {
                                    ForEach(viewModel.categories.filter { $0.isTopCategory }) { category in
                                        FeaturedCategoryCard(category: category)
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                    }
                    
                    // All Categories Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Browse All")
                            .font(.title2)
                            .fontWeight(.bold)
                            .padding(.horizontal)
                        
                        LazyVGrid(columns: [
                            GridItem(.flexible(), spacing: 16),
                            GridItem(.flexible(), spacing: 16)
                        ], spacing: 16) {
                            ForEach(viewModel.categories.filter { !$0.isTopCategory }) { category in
                                CategoryCard(category: category)
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.vertical)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Explore")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        viewModel.createFoodCategory()
                    }) {
                        Image(systemName: "plus")
                    }
                }
            }
        }
    }
}

struct CategoryCard: View {
    let category: Category
    
    var body: some View {
        NavigationLink(destination: CategoryDetailView(category: category)) {
            VStack(spacing: 12) {
                // Icon
                ZStack {
                    Circle()
                        .fill(.ultraThinMaterial)
                        .frame(width: 60, height: 60)
                    
                    Image(systemName: category.iconName)
                        .font(.system(size: 24))
                        .foregroundStyle(category.accentColor)
                }
                
                // Text
                VStack(spacing: 4) {
                    Text(category.name)
                        .font(.headline)
                        .foregroundStyle(.primary)
                    
                    Text(category.description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .padding(.horizontal, 12)
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
        }
    }
}

struct FeaturedCategoryCard: View {
    let category: Category
    
    var body: some View {
        NavigationLink(destination: CategoryDetailView(category: category)) {
            VStack(alignment: .leading, spacing: 12) {
                // Header with Icon
                HStack {
                    ZStack {
                        Circle()
                            .fill(.ultraThinMaterial)
                            .frame(width: 50, height: 50)
                        
                        Image(systemName: category.iconName)
                            .font(.system(size: 20))
                            .foregroundStyle(category.accentColor)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .foregroundStyle(.secondary)
                        .fontWeight(.semibold)
                }
                
                Spacer()
                
                // Text Content
                VStack(alignment: .leading, spacing: 4) {
                    Text(category.name)
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundStyle(.primary)
                    
                    Text(category.description)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
            }
            .frame(width: 200, height: 160)
            .padding()
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 24))
            .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
        }
    }
}

// Helper extension for Category
extension Category {
    var iconName: String {
        switch name.lowercased() {
        case "food": return "fork.knife"
        case "fruit": return "leaf.fill"
        case "drink": return "cup.and.saucer.fill"
        case "dessert": return "birthday.cake.fill"
        case "sports": return "figure.run"
        case "hike": return "mountain.2.fill"
        case "travel": return "airplane"
        case "art": return "paintbrush.fill"
        default: return "star.fill"
        }
    }
    
    var accentColor: Color {
        switch name.lowercased() {
        case "food": return .orange
        case "fruit": return .green
        case "drink": return .blue
        case "dessert": return .pink
        case "sports": return .red
        case "hike": return .mint
        case "travel": return .purple
        case "art": return .indigo
        default: return .gray
        }
    }
}

#Preview {
    ExploreView()
} 