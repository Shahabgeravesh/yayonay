import SwiftUI
import FirebaseFirestore

struct ExploreView: View {
    @StateObject private var viewModel = ExploreViewModel()
    
    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var body: some View {
        NavigationStack {
            ScrollView {
                // Top Grid Categories
                LazyVGrid(columns: columns, spacing: 16) {
                    NavigationLink(destination: CategoryDetailView(category: Category(id: "fruits", name: "Fruit", imageURL: nil))) {
                        CategoryCard(title: "Fruit")
                    }
                    
                    NavigationLink(destination: CategoryDetailView(category: Category(id: "food", name: "Food", imageURL: nil))) {
                        CategoryCard(title: "Food")
                    }
                    
                    NavigationLink(destination: CategoryDetailView(category: Category(id: "drink", name: "Drink", imageURL: nil))) {
                        CategoryCard(title: "Drink")
                    }
                    
                    NavigationLink(destination: CategoryDetailView(category: Category(id: "dessert", name: "Dessert", imageURL: nil))) {
                        CategoryCard(title: "Dessert")
                    }
                }
                .padding()
                
                // Bottom Image Categories
                LazyVGrid(columns: columns, spacing: 16) {
                    NavigationLink(destination: CategoryDetailView(category: Category(id: "sports", name: "Sports", imageURL: "sports_image"))) {
                        CategoryImageCard(title: "Sports", imageURL: "sports_image")
                    }
                    
                    NavigationLink(destination: CategoryDetailView(category: Category(id: "hike", name: "Hike", imageURL: "hike_image"))) {
                        CategoryImageCard(title: "Hike", imageURL: "hike_image")
                    }
                    
                    NavigationLink(destination: CategoryDetailView(category: Category(id: "travel", name: "Travel", imageURL: "travel_image"))) {
                        CategoryImageCard(title: "Travel", imageURL: "travel_image")
                    }
                }
                .padding()
            }
            .navigationTitle("Explore")
        }
    }
}

struct CategoryCard: View {
    let title: String
    
    var body: some View {
        VStack {
            Text(title)
                .font(.title2)
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity, minHeight: 120)
                .background(Color.white)
                .cornerRadius(16)
                .shadow(color: Color.black.opacity(0.05), radius: 8, y: 4)
        }
    }
}

struct CategoryImageCard: View {
    let title: String
    let imageURL: String
    
    var body: some View {
        VStack {
            AsyncImage(url: URL(string: imageURL)) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Color.gray.opacity(0.2)
            }
            .overlay(
                Text(title)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
            )
            .frame(height: 200)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: Color.black.opacity(0.1), radius: 8, y: 4)
        }
    }
}

class ExploreViewModel: ObservableObject {
    @Published var featuredCategories: [Category] = []
    @Published var popularTopics: [Topic] = []
    @Published var trendingCategories: [Category] = []
    private let db = Firestore.firestore()
    
    init() {
        fetchFeaturedCategories()
        fetchPopularTopics()
        fetchTrendingCategories()
    }
    
    func fetchFeaturedCategories() {
        db.collection("categories")
            .order(by: "featured", descending: true)
            .limit(to: 5)
            .getDocuments { [weak self] snapshot, error in
                if let documents = snapshot?.documents {
                    self?.featuredCategories = documents.compactMap { Category(document: $0) }
                }
            }
    }
    
    func fetchPopularTopics() {
        db.collection("topics")
            .order(by: "upvotes", descending: true)
            .limit(to: 5)
            .getDocuments { [weak self] snapshot, error in
                if let documents = snapshot?.documents {
                    self?.popularTopics = documents.compactMap { Topic(document: $0) }
                }
            }
    }
    
    func fetchTrendingCategories() {
        db.collection("categories")
            .order(by: "votesCount", descending: true)
            .limit(to: 6)
            .getDocuments { [weak self] snapshot, error in
                if let documents = snapshot?.documents {
                    self?.trendingCategories = documents.compactMap { Category(document: $0) }
                }
            }
    }
    
    func vote(for topic: Topic, isUpvote: Bool) {
        // Implement voting logic
    }
    
    func shareTopic(_ topic: Topic) {
        // Implement sharing logic
    }
    
    @MainActor
    func refresh() async {
        fetchFeaturedCategories()
        fetchPopularTopics()
        fetchTrendingCategories()
    }
}

#Preview {
    ExploreView()
} 