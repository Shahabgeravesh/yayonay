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
    // Base colors that adapt to light/dark mode
    static let background = Color(.systemBackground)
    static let secondaryBackground = Color(.secondarySystemBackground)
    static let tertiaryBackground = Color(.tertiarySystemBackground)
    static let accent = Color.blue
    static let text = Color(.label)
    static let secondaryText = Color(.secondaryLabel)
    static let divider = Color(.separator)
    
    // Dark mode specific colors
    static let darkBackground = Color(red: 0.12, green: 0.12, blue: 0.15)
    static let darkSecondaryBackground = Color(red: 0.18, green: 0.18, blue: 0.22)
    static let darkAccent = Color.blue.opacity(0.8)
    
    // Light mode specific colors
    static let lightBackground = Color(.systemBackground)
    static let lightSecondaryBackground = Color(.secondarySystemBackground)
    static let lightAccent = Color.blue
    
    // Custom gradient for buttons and highlights
    static let gradient = LinearGradient(
        colors: [.blue, .purple],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    // Dark mode gradient
    static let darkGradient = LinearGradient(
        colors: [Color.blue.opacity(0.7), Color.purple.opacity(0.7)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    // Get the appropriate background color based on color scheme
    static func adaptiveBackground(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? darkBackground : lightBackground
    }
    
    // Get the appropriate secondary background color based on color scheme
    static func adaptiveSecondaryBackground(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? darkSecondaryBackground : lightSecondaryBackground
    }
    
    // Get the appropriate accent color based on color scheme
    static func adaptiveAccent(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? darkAccent : lightAccent
    }
    
    // Get the appropriate gradient based on color scheme
    static func adaptiveGradient(for colorScheme: ColorScheme) -> LinearGradient {
        colorScheme == .dark ? darkGradient : gradient
    }
}

struct AppShadow: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme
    
    func body(content: Content) -> some View {
        content
            .shadow(
                color: colorScheme == .dark ? .black.opacity(0.3) : .black.opacity(0.1),
                radius: colorScheme == .dark ? 8 : 10,
                y: colorScheme == .dark ? 1 : 2
            )
    }
}

struct GlassmorphicBackground: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme
    
    func body(content: Content) -> some View {
        content
            .background(.ultraThinMaterial)
            .background(
                colorScheme == .dark 
                    ? AppColor.darkBackground.opacity(0.7) 
                    : AppColor.background.opacity(0.8)
            )
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