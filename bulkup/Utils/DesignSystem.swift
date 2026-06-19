//
//  DesignSystem.swift
//  bulkup
//
//  Premium fitness design system — Freeletics-inspired dark immersive aesthetic.
//

import SwiftUI

// MARK: - Color Hex Initializer
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
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

// MARK: - Color Tokens
enum BulkUpColors {
    // Brand — Teal/Mint
    static let accent = Color(hex: "#00E6C3")
    static let accentGlow = Color(hex: "#00FFD5")
    static let accentMuted = Color(hex: "#00997F")
    static let accentGradient = LinearGradient(
        colors: [accent, accentGlow],
        startPoint: .leading, endPoint: .trailing
    )
    static let secondary = Color(hex: "#7B61FF") // electric violet (sparingly)

    // Surfaces — true black feel with subtle elevation
    static let background = Color(hex: "#0A0A0A")
    static let surface = Color(hex: "#161616")
    static let surfaceElevated = Color(hex: "#1E1E1E")
    static let border = Color.white.opacity(0.06)

    // Text
    static let textPrimary = Color.white
    static let textSecondary = Color(hex: "#8E8E93")
    static let textTertiary = Color(hex: "#48484A")
    static let onAccent = Color(hex: "#000000") // text on bright accent buttons

    // Semantic
    static let success = Color(hex: "#30D158")
    static let warning = Color(hex: "#FFD60A")
    static let error = Color(hex: "#FF453A")

    // Context — muted versions for backgrounds
    static let training = Color(hex: "#00D1FF") // cyan for training context
    static let diet = Color(hex: "#30D158")      // green for diet context

    // Muscle map states
    static let muscleDefault = Color(hex: "#2A2A2A")
    static let muscleActive = accent.opacity(0.9)
}

// MARK: - Typography
enum BulkUpFont {
    /// 48pt bold rounded monospacedDigit — hero numbers (timer, big stat)
    static func heroStat() -> Font {
        .system(size: 48, weight: .bold, design: .rounded).monospacedDigit()
    }
    /// 40pt bold rounded monospacedDigit — secondary hero numbers
    static func heroStatMedium() -> Font {
        .system(size: 40, weight: .bold, design: .rounded).monospacedDigit()
    }
    /// 28pt bold — screen titles
    static func screenTitle() -> Font {
        .system(size: 28, weight: .bold)
    }
    /// 24pt bold — large titles (workout name, plan name)
    static func largeTitle() -> Font {
        .system(size: 24, weight: .bold)
    }
    /// 20pt semibold — section headers
    static func sectionHeader() -> Font {
        .system(size: 20, weight: .semibold)
    }
    /// 13pt bold — section label (use with .tracking(1.5) and .uppercased())
    static func sectionLabel() -> Font {
        .system(size: 13, weight: .bold)
    }
    /// 17pt semibold — card titles
    static func cardTitle() -> Font {
        .system(size: 17, weight: .semibold)
    }
    /// 15pt regular — body text
    static func body() -> Font {
        .system(size: 15, weight: .regular)
    }
    /// 13pt medium — captions/meta
    static func caption() -> Font {
        .system(size: 13, weight: .medium)
    }
    /// 13pt medium — data labels
    static func dataLabel() -> Font {
        .system(size: 13, weight: .medium)
    }
    /// 11pt bold — badge/pill text (use with .tracking(1) and .uppercased)
    static func badge() -> Font {
        .system(size: 11, weight: .bold)
    }
}

// MARK: - Spacing
enum Spacing {
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 16
    static let lg: CGFloat = 24
    static let sectionGap: CGFloat = 28
    static let xl: CGFloat = 32
    static let xxl: CGFloat = 48
    /// Standard screen horizontal padding
    static let screenH: CGFloat = 20
}

// MARK: - Corner Radius
enum CornerRadius {
    static let small: CGFloat = 8
    static let medium: CGFloat = 12
    static let large: CGFloat = 16
    static let xl: CGFloat = 20
}
