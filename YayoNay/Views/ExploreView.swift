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
                VStack(spacing: 24) {
                    // Main Categories Grid
                    LazyVGrid(columns: columns, spacing: 16) {
                        NavigationLink(destination: CategoryDetailView(category: Category(id: "fruits", name: "Fruit", imageURL: nil))) {
                            CategoryCard(title: "Fruit", icon: "apple.logo")
                        }
                        
                        NavigationLink(destination: CategoryDetailView(category: Category(id: "food", name: "Food", imageURL: nil))) {
                            CategoryCard(title: "Food", icon: "fork.knife")
                        }
                        
                        NavigationLink(destination: CategoryDetailView(category: Category(id: "drink", name: "Drink", imageURL: nil))) {
                            CategoryCard(title: "Drink", icon: "wineglass")
                        }
                        
                        NavigationLink(destination: CategoryDetailView(category: Category(id: "dessert", name: "Dessert", imageURL: nil))) {
                            CategoryCard(title: "Dessert", icon: "birthday.cake")
                        }
                        
                        NavigationLink(destination: CategoryDetailView(category: Category(id: "sports", name: "Sports", imageURL: nil))) {
                            CategoryCard(title: "Sports", icon: "sportscourt")
                        }
                        
                        NavigationLink(destination: CategoryDetailView(category: Category(id: "hike", name: "Hike", imageURL: nil))) {
                            CategoryCard(title: "Hike", icon: "figure.hiking")
                        }
                        
                        NavigationLink(destination: CategoryDetailView(category: Category(id: "travel", name: "Travel", imageURL: nil))) {
                            CategoryCard(title: "Travel", icon: "airplane")
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Explore")
        }
    }
}

struct CategoryCard: View {
    let title: String
    let icon: String
    
    var body: some View {
        VStack {
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.blue.opacity(0.1))
                
                VStack(spacing: 12) {
                    Image(systemName: icon)
                        .font(.system(size: 30))
                        .foregroundColor(.blue)
                    
                    Text(title)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                }
                .padding()
            }
            .frame(height: 120)
        }
        .shadow(color: Color.black.opacity(0.05), radius: 8, y: 4)
    }
}

class ExploreViewModel: ObservableObject {
    private let db = Firestore.firestore()
    
    init() {
        // Initialize any necessary data
    }
}

#Preview {
    ExploreView()
} 