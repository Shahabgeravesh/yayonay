import SwiftUI

struct TopicTabIcon: View {
    var body: some View {
        ZStack {
            // Cube base
            Image(systemName: "cube.fill")
                .font(.system(size: 24))
            
            // Question mark overlay
            Image(systemName: "questionmark")
                .font(.system(size: 14, weight: .bold))
                .offset(y: -2)
        }
    }
}

#Preview {
    TopicTabIcon()
} 