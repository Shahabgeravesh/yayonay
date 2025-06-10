// MARK: - Topic Tab Icon Component
// This component provides a visual icon for topic tabs, including:
// 1. Category-specific icons
// 2. Selection state
// 3. Visual feedback
// 4. Navigation support

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