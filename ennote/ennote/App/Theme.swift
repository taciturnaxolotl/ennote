import SwiftUI

// MARK: - Color Palette
extension Color {
    // Dark Mode
    static let background = Color(hex: "171717")
    static let surface = Color(hex: "212121")
    static let surfaceElevated = Color(hex: "2A2A2A")
    static let textPrimary = Color(hex: "FAFAFA")
    static let textSecondary = Color(hex: "A3A3A3")
    static let themeAccent = Color(hex: "FBBF23")
    static let accentMuted = Color(hex: "78590A")
    static let success = Color(hex: "4ADE80")
    static let border = Color(hex: "2E2E2E")

    // Light Mode variants
    static let backgroundLight = Color(hex: "FAFAFA")
    static let surfaceLight = Color(hex: "FFFFFF")
    static let textPrimaryLight = Color(hex: "171717")
    static let textSecondaryLight = Color(hex: "6B6B6B")
    static let themeAccentLight = Color(hex: "CA8A04")
    static let accentMutedLight = Color(hex: "FEF3C7")
    static let successLight = Color(hex: "22C55E")
    static let borderLight = Color(hex: "E5E5E5")
}

// MARK: - Hex Color Initializer
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Adaptive Colors
struct AdaptiveColors {
    @Environment(\.colorScheme) var colorScheme

    var background: Color {
        colorScheme == .dark ? .background : .backgroundLight
    }

    var surface: Color {
        colorScheme == .dark ? .surface : .surfaceLight
    }

    var textPrimary: Color {
        colorScheme == .dark ? .textPrimary : .textPrimaryLight
    }

    var textSecondary: Color {
        colorScheme == .dark ? .textSecondary : .textSecondaryLight
    }

    var accent: Color {
        colorScheme == .dark ? .themeAccent : .themeAccentLight
    }

    var border: Color {
        colorScheme == .dark ? .border : .borderLight
    }
}
