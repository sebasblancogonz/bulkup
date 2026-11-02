//
//  DesignSystem.swift
//  bulkup
//
//  "Graphite & Voltage": the brand system shared with getbulkup.com, translated
//  to native iOS. Graphite ground (never pure black), bone-white text, one
//  electric-lime accent that fires only where there is action or progress,
//  sky for "done", amber for the only error colour. Saira Condensed carries the
//  display moments, SF Pro carries the UI, JetBrains Mono carries every number.
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

    /// Best-contrast label color (white or black) for text/icons sitting on top
    /// of a filled element, chosen per light/dark trait via WCAG luminance.
    static func onFill(_ fill: Color) -> Color {
        Color(uiColor: UIColor { traits in
            let c = UIColor(fill).resolvedColor(with: traits)
            var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
            c.getRed(&r, green: &g, blue: &b, alpha: &a)
            func lin(_ v: CGFloat) -> CGFloat { v <= 0.03928 ? v / 12.92 : pow((v + 0.055) / 1.055, 2.4) }
            let L = 0.2126 * lin(r) + 0.7152 * lin(g) + 0.0722 * lin(b)
            return L > 0.45 ? UIColor(hex: "#0E1110") : UIColor(hex: "#F2F4F1")
        })
    }
}

// MARK: - Color Tokens
enum BulkUpColors {
    // Ground — graphite at night, bone by day. Never pure black or pure white.
    static let background = Color.adaptive(dark: "#0E1110", light: "#F2F4F1")
    /// Slightly lighter graphite the top of a screen fades from (the canvas is
    /// never a flat swatch).
    static let backgroundGlow = Color.adaptive(dark: "#181D1E", light: "#FFFFFF")
    static let surface = Color.adaptive(dark: "#15191A", light: "#FFFFFF")
    static let surfaceElevated = Color.adaptive(dark: "#1D2224", light: "#E8EBE6")
    /// 1pt hairline: the structural grammar between blocks.
    static let line = Color.adaptive(dark: "#2A3033", light: "#D3D8D2")
    static let border = line

    // Text
    static let textPrimary = Color.adaptive(dark: "#F2F4F1", light: "#0E1110")
    static let textSecondary = Color.adaptive(dark: "#9BA39E", light: "#5B635E")
    static let textTertiary = Color.adaptive(dark: "#7C8581", light: "#747C78")

    // Voltage — electric lime, rationed to action and progress (≤10% of a screen).
    static let accent = Color.adaptive(dark: "#B4FF2E", light: "#8FDC14")
    /// Pressed / deep end of the accent.
    static let accentMuted = Color.adaptive(dark: "#93D414", light: "#6DB10C")
    static let accentGlow = Color.adaptive(dark: "#C9FF66", light: "#A8E83A")
    /// Lime as *text* — legible on the ground in both appearances.
    static let accentText = Color.adaptive(dark: "#B4FF2E", light: "#3E7000")
    static let accentGradient = LinearGradient(
        colors: [accent, accentMuted],
        startPoint: .leading, endPoint: .trailing
    )
    /// Text/icons on a lime fill: always graphite.
    static let onAccent = Color.adaptive(dark: "#0E1110", light: "#0E1110")
    /// Small "PRO" tags and locked-feature hints.
    static let secondary = accentMuted

    // Two-greens rule: lime means action/progress, sky means done/logged.
    static let complete = Color.adaptive(dark: "#00A9DD", light: "#007DA8")
    static let success = complete
    /// Amber is the only error/warning colour; lime is never "wrong" and red
    /// never competes with it.
    static let warning = Color.adaptive(dark: "#F5A524", light: "#A86400")
    static let error = Color.adaptive(dark: "#F5A524", light: "#A86400")

    // Context tints used by the training/diet hubs.
    static let training = complete
    static let diet = accentMuted

    // Muscle map states
    static let muscleDefault = surfaceElevated
    static let muscleActive = accent.opacity(0.9)

    // Shadow (earned only: sheets, floating controls)
    static let shadow = Color.adaptive(dark: "#000000", light: "#1A1F1C")
}

// MARK: - Ground
/// The screen canvas: graphite with a faint lighter radial at the top so the
/// surface reads as material, not a flat swatch. Use behind every top-level screen.
struct BulkUpGround: View {
    var body: some View {
        ZStack {
            BulkUpColors.background
            RadialGradient(
                colors: [BulkUpColors.backgroundGlow.opacity(0.85), .clear],
                center: UnitPoint(x: 0.5, y: 0),
                startRadius: 0,
                endRadius: 460
            )
        }
        .ignoresSafeArea()
    }
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
        // Brand fonts must be registered (Info.plist UIAppFonts + bundled TTFs).
        for name in ["SairaCondensed-SemiBold", "SairaCondensed-Bold", "SairaCondensed-ExtraBold",
                     "JetBrainsMono-Medium", "JetBrainsMono-SemiBold"] {
            assert(UIFont(name: name, size: 12) != nil, "font not registered: \(name)")
        }
    }
}
#endif

// MARK: - Typography
/// Three voices: Saira Condensed for display moments (uppercase, tight), SF Pro
/// text styles for the UI (Dynamic Type), JetBrains Mono for every datapoint.
enum BulkUpFont {
    enum DisplayWeight {
        case semibold, bold, extraBold
        var name: String {
            switch self {
            case .semibold: return "SairaCondensed-SemiBold"
            case .bold: return "SairaCondensed-Bold"
            case .extraBold: return "SairaCondensed-ExtraBold"
            }
        }
    }

    enum MonoWeight {
        case medium, semibold
        var name: String {
            switch self {
            case .medium: return "JetBrainsMono-Medium"
            case .semibold: return "JetBrainsMono-SemiBold"
            }
        }
    }

    /// Display voice — set uppercase at the call site. Scales with Dynamic Type.
    static func display(_ size: CGFloat, weight: DisplayWeight = .bold,
                        relativeTo style: Font.TextStyle = .title) -> Font {
        .custom(weight.name, size: size, relativeTo: style)
    }

    /// Data voice — kilos, reps, %, timers, prices, streaks.
    static func mono(_ size: CGFloat, weight: MonoWeight = .medium,
                     relativeTo style: Font.TextStyle = .body) -> Font {
        .custom(weight.name, size: size, relativeTo: style)
    }

    /// 44pt mono — hero numbers (timer, big stat)
    static func heroStat() -> Font { mono(44, weight: .semibold, relativeTo: .largeTitle) }
    /// 36pt mono — secondary hero numbers
    static func heroStatMedium() -> Font { mono(36, weight: .semibold, relativeTo: .largeTitle) }
    /// Display 30pt — screen titles
    static func screenTitle() -> Font { display(30, weight: .bold, relativeTo: .title) }
    /// Display 26pt — workout / plan names
    static func largeTitle() -> Font { display(26, weight: .bold, relativeTo: .title2) }
    /// 20pt semibold — section headers
    static func sectionHeader() -> Font { .system(.title3, weight: .semibold) }
    /// 13pt bold — section label (use with .tracking(1.5) and .uppercased())
    static func sectionLabel() -> Font { .system(.footnote, weight: .bold) }
    /// 17pt semibold — card titles
    static func cardTitle() -> Font { .system(.headline, weight: .semibold) }
    /// 15pt regular — body text
    static func body() -> Font { .system(.subheadline, weight: .regular) }
    /// 13pt medium — captions/meta
    static func caption() -> Font { .system(.footnote, weight: .medium) }
    /// 13pt mono — data labels
    static func dataLabel() -> Font { mono(13, relativeTo: .footnote) }
    /// 11pt bold — badge/pill text (use with .tracking(1) and .uppercased)
    static func badge() -> Font { .system(.caption2, weight: .bold) }
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
/// Hierarchised radii: 8 fields/chips-in-rows, 10 buttons & inputs, 14 cards,
/// 18 sheets and hero blocks. Pills (capsules) are for chips only.
enum CornerRadius {
    static let small: CGFloat = 8
    static let medium: CGFloat = 10
    static let large: CGFloat = 14
    static let xl: CGFloat = 18
}

// MARK: - Hairline
extension View {
    /// 1pt structural border in the brand line colour.
    func hairline(_ radius: CGFloat = CornerRadius.large, color: Color = BulkUpColors.line) -> some View {
        overlay(
            RoundedRectangle(cornerRadius: radius, style: .continuous)
                .stroke(color, lineWidth: 1)
        )
    }

    /// Display-voice text: Saira Condensed, uppercase, tight tracking.
    func displayVoice(_ size: CGFloat = 26, weight: BulkUpFont.DisplayWeight = .bold,
                      relativeTo style: Font.TextStyle = .title2) -> some View {
        self.font(BulkUpFont.display(size, weight: weight, relativeTo: style))
            .textCase(.uppercase)
            .tracking(-0.2)
    }

    /// Uppercase micro label: 11pt bold SF with wide tracking.
    func microLabel(color: Color = BulkUpColors.textSecondary) -> some View {
        self.font(BulkUpFont.badge())
            .tracking(1.4)
            .textCase(.uppercase)
            .foregroundColor(color)
    }
}
