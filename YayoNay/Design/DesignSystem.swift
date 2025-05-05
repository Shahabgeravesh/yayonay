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

// Modern, sharp color palette
enum ModernColor {
    static let primary = Color(red: 0.2, green: 0.2, blue: 0.2)
    static let secondary = Color(red: 0.4, green: 0.4, blue: 0.4)
    static let accent = Color(red: 0.0, green: 0.6, blue: 0.8)
    static let background = Color(red: 0.95, green: 0.95, blue: 0.95)
    static let cardBackground = Color.white
    static let text = Color(red: 0.1, green: 0.1, blue: 0.1)
    static let secondaryText = Color(red: 0.5, green: 0.5, blue: 0.5)
    static let border = Color(red: 0.8, green: 0.8, blue: 0.8)
}

// Modern design elements
enum ModernDesign {
    // Modern gradients
    static let primaryGradient = LinearGradient(
        colors: [
            Color(red: 0.0, green: 0.2, blue: 0.3),  // Dark blue
            Color(red: 0.0, green: 0.3, blue: 0.4)   // Deeper dark blue
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    // Featured categories gradient
    static let featuredGradient = LinearGradient(
        colors: [
            Color(red: 0.0, green: 0.8, blue: 0.9),  // Bright cyan
            Color(red: 0.0, green: 0.6, blue: 0.8)   // Medium cyan
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    // Regular categories gradient
    static let regularGradient = LinearGradient(
        colors: [
            Color(red: 0.0, green: 0.4, blue: 0.6),  // Deep cyan
            Color(red: 0.0, green: 0.2, blue: 0.4)   // Dark cyan
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let cardGradient = LinearGradient(
        colors: [
            Color.white,
            Color(red: 0.95, green: 0.95, blue: 0.95)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    // Modern shadows
    struct CardShadow {
        static let color = Color.black.opacity(0.15)
        static let radius: CGFloat = 12
        static let x: CGFloat = 0
        static let y: CGFloat = 6
    }
    
    struct ElevatedShadow {
        static let color = Color.black.opacity(0.2)
        static let radius: CGFloat = 20
        static let x: CGFloat = 0
        static let y: CGFloat = 10
    }
    
    struct FeaturedShadow {
        static let color = Color(red: 0.0, green: 0.8, blue: 0.9).opacity(0.3)
        static let radius: CGFloat = 15
        static let x: CGFloat = 0
        static let y: CGFloat = 8
    }
    
    struct RegularShadow {
        static let color = Color(red: 0.0, green: 0.4, blue: 0.6).opacity(0.3)
        static let radius: CGFloat = 15
        static let x: CGFloat = 0
        static let y: CGFloat = 8
    }
    
    // Modern animations
    static let cardAnimation = Animation.spring(response: 0.3, dampingFraction: 0.7)
    static let hoverAnimation = Animation.easeInOut(duration: 0.2)
}

extension View {
    func appShadow() -> some View {
        modifier(AppShadow())
    }
    
    func glassmorphic() -> some View {
        modifier(GlassmorphicBackground())
    }
} 