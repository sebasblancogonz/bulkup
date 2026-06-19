//
//  DesignSystem.swift
//  bulkup
//
//  Premium fitness design system — adaptive light/dark palette.
//

import SwiftUI
import UIKit

// MARK: - Color Hex Initializer (SwiftUI)
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

// MARK: - Color Hex Initializer (UIKit)
extension UIColor {
    convenience init(hex: String) {
        let s = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: s).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch s.count {
        case 6: (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default: (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(red: CGFloat(r) / 255, green: CGFloat(g) / 255, blue: CGFloat(b) / 255, alpha: CGFloat(a) / 255)
    }
}

// MARK: - Adaptive Color Helper
extension Color {
    static func adaptive(dark: String, light: String) -> Color {
        Color(uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark ? UIColor(hex: dark) : UIColor(hex: light)
        })
    }
}

// MARK: - Color Tokens
enum BulkUpColors {
    // Brand — Teal/Mint
    static let accent = Color.adaptive(dark: "#00E6C3", light: "#00E6C3")
    static let accentGlow = Color.adaptive(dark: "#00FFD5", light: "#00D9BC")
    static let accentMuted = Color.adaptive(dark: "#00997F", light: "#00A88F")
    static let accentText = Color.adaptive(dark: "#00E6C3", light: "#00A88F")
    static let accentGradient = LinearGradient(
        colors: [accent, accentGlow],
        startPoint: .leading, endPoint: .trailing
    )
    static let secondary = Color.adaptive(dark: "#7B61FF", light: "#6A4DF0") // electric violet (sparingly)

    // Surfaces — adaptive light/dark elevation
    static let background = Color.adaptive(dark: "#0A0A0A", light: "#FAF9F6")
    static let surface = Color.adaptive(dark: "#161616", light: "#FFFFFF")
    static let surfaceElevated = Color.adaptive(dark: "#1E1E1E", light: "#FFFFFF")
    static let border = Color.adaptive(dark: "#FFFFFF", light: "#000000").opacity(0.08)

    // Text
    static let textPrimary = Color.adaptive(dark: "#FFFFFF", light: "#1A1A1A")
    static let textSecondary = Color.adaptive(dark: "#8E8E93", light: "#6E6E73")
    static let textTertiary = Color.adaptive(dark: "#48484A", light: "#A0A0A5")
    static let onAccent = Color.adaptive(dark: "#000000", light: "#000000") // text on bright accent buttons

    // Semantic
    static let success = Color.adaptive(dark: "#30D158", light: "#28B14C")
    static let warning = Color.adaptive(dark: "#FFD60A", light: "#E6A700")
    static let error = Color.adaptive(dark: "#FF453A", light: "#E03B30")

    // Context — muted versions for backgrounds
    static let training = Color.adaptive(dark: "#00D1FF", light: "#0094C9") // cyan for training context
    static let diet = Color.adaptive(dark: "#30D158", light: "#28B14C")      // green for diet context

    // Muscle map states
    static let muscleDefault = Color.adaptive(dark: "#2A2A2A", light: "#E5E3DD")
    static let muscleActive = accent.opacity(0.9)

    // Shadow
    static let shadow = Color.adaptive(dark: "#000000", light: "#3A3733")
}

// MARK: - DEBUG Theme Self-Check
#if DEBUG
enum ThemeSelfCheck {
    static func run() {
        let d = UIColor(BulkUpColors.background).resolvedColor(with: UITraitCollection(userInterfaceStyle: .dark))
        let l = UIColor(BulkUpColors.background).resolvedColor(with: UITraitCollection(userInterfaceStyle: .light))
        assert(d != l, "theme: background must differ between light and dark")
        let td = UIColor(BulkUpColors.textPrimary).resolvedColor(with: UITraitCollection(userInterfaceStyle: .dark))
        let tl = UIColor(BulkUpColors.textPrimary).resolvedColor(with: UITraitCollection(userInterfaceStyle: .light))
        assert(td != tl, "theme: textPrimary must differ between light and dark")
    }
}
#endif

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
