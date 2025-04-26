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
                        ForEach(viewModel.categories) { category in
                            NavigationLink(destination: CategoryDetailView(category: category)) {
                                CategoryCard(title: category.name, icon: category.iconName)
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Explore")
        }
        .onAppear {
            viewModel.fetchCategories()
        }
    }
}

struct CategoryCard: View {
    let title: String
    let icon: String
    
    // Premium color palette
    private var cardColor: Color {
        let colors: [Color] = [
            Color(red: 0.20, green: 0.60, blue: 0.86), // Ocean Blue
            Color(red: 0.61, green: 0.35, blue: 0.71), // Royal Purple
            Color(red: 0.95, green: 0.40, blue: 0.50), // Coral Pink
            Color(red: 0.98, green: 0.55, blue: 0.38), // Sunset Orange
            Color(red: 0.30, green: 0.69, blue: 0.31), // Forest Green
            Color(red: 0.40, green: 0.40, blue: 0.80), // Indigo
            Color(red: 0.20, green: 0.80, blue: 0.80), // Teal
            Color(red: 0.85, green: 0.45, blue: 0.65)  // Rose
        ]
        let index = abs(icon.hashValue) % colors.count
        return colors[index]
    }
    
    var body: some View {
        VStack {
            ZStack {
                // Premium background with subtle gradient
                RoundedRectangle(cornerRadius: 24)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                cardColor.opacity(0.12),
                                cardColor.opacity(0.05)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 24)
                            .stroke(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        cardColor.opacity(0.3),
                                        cardColor.opacity(0.1)
                                    ]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 0.5
                            )
                    )
                
                // Subtle background pattern
                GeometryReader { geometry in
                    Path { path in
                        let size = geometry.size
                        let spacing: CGFloat = 20
                        let rows = Int(size.height / spacing)
                        let columns = Int(size.width / spacing)
                        
                        for row in 0...rows {
                            for column in 0...columns {
                                let x = CGFloat(column) * spacing
                                let y = CGFloat(row) * spacing
                                path.addEllipse(in: CGRect(x: x, y: y, width: 2, height: 2))
                            }
                        }
                    }
                    .fill(cardColor.opacity(0.1))
                    .blur(radius: 1)
                }
                
                // Main content
                VStack(spacing: 20) {
                    // Premium icon container
                    ZStack {
                        Circle()
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
                            .frame(width: 60, height: 60)
                            .overlay(
                                Circle()
                                    .stroke(
                                        LinearGradient(
                                            gradient: Gradient(colors: [
                                                cardColor.opacity(0.4),
                                                cardColor.opacity(0.1)
                                            ]),
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ),
                                        lineWidth: 1
                                    )
                            )
                        
                        Image(systemName: icon)
                            .font(.system(size: 24, weight: .medium))
                            .foregroundColor(cardColor)
                    }
                    .accessibilityHidden(true)
                    
                    Text(title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .padding(.horizontal, 4)
                }
                .padding()
            }
            .frame(height: 160)
        }
        .shadow(color: cardColor.opacity(0.15), radius: 15, x: 0, y: 5)
        .shadow(color: Color.black.opacity(0.05), radius: 1, x: 0, y: 1)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title) category")
        .accessibilityHint("Double tap to view \(title) items")
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