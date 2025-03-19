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