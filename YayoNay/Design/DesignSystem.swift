import SwiftUI

enum AppFont {
    static func regular(_ size: CGFloat) -> Font {
        .system(size: size, weight: .regular)
    }
    
    static func medium(_ size: CGFloat) -> Font {
        .system(size: size, weight: .medium)
    }
    
    static func semibold(_ size: CGFloat) -> Font {
        .system(size: size, weight: .semibold)
    }
    
    static func bold(_ size: CGFloat) -> Font {
        .system(size: size, weight: .bold)
    }
}

enum AppColor {
    static let background = Color(.systemBackground)
    static let secondaryBackground = Color(.secondarySystemBackground)
    static let accent = Color.blue
    static let text = Color(.label)
    static let secondaryText = Color(.secondaryLabel)
    static let divider = Color(.separator)
    
    // Custom gradient for buttons and highlights
    static let gradient = LinearGradient(
        colors: [.blue, .purple],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

struct AppShadow: ViewModifier {
    func body(content: Content) -> some View {
        content
            .shadow(color: .black.opacity(0.1), radius: 10, y: 2)
    }
}

struct GlassmorphicBackground: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(.ultraThinMaterial)
            .background(AppColor.background.opacity(0.8))
    }
}

extension View {
    func appShadow() -> some View {
        modifier(AppShadow())
    }
    
    func glassmorphic() -> some View {
        modifier(GlassmorphicBackground())
    }
} 