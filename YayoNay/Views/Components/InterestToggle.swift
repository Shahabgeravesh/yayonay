// MARK: - Interest Toggle Component
// This component provides a toggle switch for interest selection, including:
// 1. Visual toggle state
// 2. Interest label
// 3. Selection feedback
// 4. Accessibility support

import SwiftUI

struct InterestToggle: View {
    let interest: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(interest)
                .font(AppFont.medium(14))
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .frame(maxWidth: .infinity)
                .background(
                    Group {
                        if isSelected {
                            AppColor.gradient
                        } else {
                            AppColor.secondaryBackground
                        }
                    }
                )
                .foregroundStyle(isSelected ? .white : AppColor.text)
                .cornerRadius(12)
        }
    }
}

#Preview {
    VStack {
        InterestToggle(interest: "Food", isSelected: true) {}
        InterestToggle(interest: "Sports", isSelected: false) {}
    }
    .padding()
} 