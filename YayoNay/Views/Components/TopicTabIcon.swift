import SwiftUI

struct TopicTabIcon: View {
    var body: some View {
        ZStack {
            // Cube base
            Image(systemName: "cube.fill")
                .font(.system(size: 24))
            
            // Question marks on each side
            HStack(spacing: 0) {
                Text("?")
                    .font(.system(size: 12, weight: .bold))
                    .offset(x: -8)
                Text("?")
                    .font(.system(size: 12, weight: .bold))
                    .offset(x: 8)
            }
        }
    }
}

#Preview {
    TopicTabIcon()
} 