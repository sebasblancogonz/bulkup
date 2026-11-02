//
//  DesignSystem.swift
//  bulkup
//
//  "Graphite & Voltage" on native iOS, second pass: light instead of lines.
//  Warm graphite ground that is lighter where it is nearer, bone-white text,
//  one electric-lime accent that fires only where there is action or
//  progress, sky for "done", amber as the only error colour. Three voices,
//  each with a small territory: SF Pro (condensed-bold for the day's name)
//  carries the UI, Saira Condensed is reserved for two posters, JetBrains Mono
//  carries numbers that stand alone (fields, timers, prices, big stats).
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
            return L > 0.30 ? UIColor(hex: "#0E0F0C") : UIColor(hex: "#F3F1EA")
        })
    }
}

// MARK: - Color Tokens
/// The ramp is wide enough to carry depth on its own (≥6 L* between adjacent
/// steps) and leans one step warm, so emptiness reads as calm, not as cold.
enum BulkUpColors {
    // Ground — warm graphite at night, warm bone by day. Never pure black or white.
    static let background = Color.adaptive(dark: "#0E0F0C", light: "#F0EEE8")
    /// Where the ground is nearest the light: the top of every screen fades
    /// from this to `background`.
    static let backgroundGlow = Color.adaptive(dark: "#1C1E19", light: "#FAF9F6")
    /// Content containers sit on the ground as a lighter slab.
    static let surface = Color.adaptive(dark: "#1A1B17", light: "#FDFCF8")
    /// Fills inside a container (fields, chips, segments), and the active row.
    static let surfaceElevated = Color.adaptive(dark: "#272923", light: "#F3F1EB")
    /// 1pt structural line: list separators only, never a container border.
    static let line = Color.adaptive(dark: "#2C2E27", light: "#DCD9D1")
    static let border = line
    /// Top-edge light catch on a lifted container (dark appearance only).
    static let edgeLight = Color.white.opacity(0.09)

    // Text
    static let textPrimary = Color.adaptive(dark: "#F3F1EA", light: "#141510")
    static let textSecondary = Color.adaptive(dark: "#A6A89D", light: "#5C5E56")
    static let textTertiary = Color.adaptive(dark: "#8E9086", light: "#66685F")

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
    static let onAccent = Color.adaptive(dark: "#0E0F0C", light: "#0E0F0C")
    /// Small "PRO" tags and locked-feature hints.
    static let secondary = accentMuted

    // Two-greens rule: lime means action/progress, sky means done/logged.
    static let complete = Color.adaptive(dark: "#00A9DD", light: "#00729A")
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

    // Shadow: earned by whatever floats, and the light-mode lift of a container.
    static let shadow = Color.adaptive(dark: "#000000", light: "#2A2A22")
}

// MARK: - Ground
/// The screen canvas: graphite lit from the top. A real luminance step (not a
/// faint radial) so the surface reads as material, not a flat swatch.
struct BulkUpGround: View {
    var body: some View {
        LinearGradient(
            stops: [
                .init(color: BulkUpColors.backgroundGlow, location: 0),
                .init(color: BulkUpColors.background, location: 0.42),
                .init(color: BulkUpColors.background, location: 1),
            ],
            startPoint: .top, endPoint: .bottom
        )
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
/// Roles, not sizes:
/// - poster   — Saira Condensed, uppercase. Two homes only: the paywall headline
///              and "Entreno completado".
/// - title    — SF, bold, condensed width: the day's workout name, screen titles.
/// - UI       — SF text styles (Dynamic Type) for everything people read.
/// - numeric  — SF with tabular figures where a number sits inside a sentence.
/// - mono     — JetBrains Mono where a number *is* the element: fields,
///              timers, prices, big stats. Never below 16pt.
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

    /// Poster voice — Saira Condensed, set uppercase at the call site.
    static func display(_ size: CGFloat, weight: DisplayWeight = .bold,
                        relativeTo style: Font.TextStyle = .title) -> Font {
        .custom(weight.name, size: size, relativeTo: style)
    }

    /// Data voice — kilos, reps, timers, prices, big stats. Keep ≥16pt.
    static func mono(_ size: CGFloat, weight: MonoWeight = .medium,
                     relativeTo style: Font.TextStyle = .body) -> Font {
        .custom(weight.name, size: size, relativeTo: style)
    }

    /// A number inside a sentence or a label: SF with tabular figures.
    static func numeric(_ style: Font.TextStyle = .body, weight: Font.Weight = .regular) -> Font {
        .system(style, weight: weight).monospacedDigit()
    }

    /// 44pt mono — hero numbers (timer, big stat)
    static func heroStat() -> Font { mono(44, weight: .semibold, relativeTo: .largeTitle) }
    /// 36pt mono — secondary hero numbers
    static func heroStatMedium() -> Font { mono(36, weight: .semibold, relativeTo: .largeTitle) }
    /// Screen titles — SF large title, bold (pair with `.fontWidth(.condensed)`)
    static func screenTitle() -> Font { .system(.largeTitle, weight: .bold) }
    /// Workout / plan names — SF title, bold (pair with `.fontWidth(.condensed)`)
    static func largeTitle() -> Font { .system(.title, weight: .bold) }
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
    /// 13pt — data labels inside sentences (tabular SF, not mono)
    static func dataLabel() -> Font { numeric(.footnote, weight: .medium) }
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
/// Hierarchised radii: 8 fields/chips-in-rows, 12 buttons & inputs, 16 cards,
/// 20 sheets and hero blocks. Pills (capsules) are for chips only.
enum CornerRadius {
    static let small: CGFloat = 8
    static let medium: CGFloat = 12
    static let large: CGFloat = 16
    static let xl: CGFloat = 20
}

// MARK: - Lift (light instead of lines)
/// A container's depth: in the dark appearance a 1pt light catch along the
/// top edge (brighter where it is nearer), in the light appearance a soft
/// offset shadow. Neither draws an outline; the fill does the separating.
struct LiftModifier: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme
    var radius: CGFloat
    /// Optional tinted 1pt stroke for a state (active, done, locked).
    var stroke: Color?

    func body(content: Content) -> some View {
        content
            .overlay {
                let shape = RoundedRectangle(cornerRadius: radius, style: .continuous)
                if let stroke {
                    shape.strokeBorder(stroke, lineWidth: 1)
                } else if colorScheme == .dark {
                    shape.strokeBorder(
                        LinearGradient(
                            colors: [BulkUpColors.edgeLight, Color.white.opacity(0.015)],
                            startPoint: .top, endPoint: .bottom
                        ),
                        lineWidth: 1
                    )
                }
            }
            .shadow(
                color: colorScheme == .dark ? Color.clear : BulkUpColors.shadow.opacity(0.07),
                radius: colorScheme == .dark ? 0 : 12, x: 0, y: colorScheme == .dark ? 0 : 3
            )
    }
}

// MARK: - View helpers
extension View {
    /// Depth for a container: top-edge light (dark) or a soft shadow (light).
    func lift(_ radius: CGFloat = CornerRadius.large, stroke: Color? = nil) -> some View {
        modifier(LiftModifier(radius: radius, stroke: stroke))
    }

    /// 1pt border in the brand line colour. For outline buttons and the few
    /// places a border is the point; separators use a 1pt Rectangle.
    func hairline(_ radius: CGFloat = CornerRadius.large, color: Color = BulkUpColors.line) -> some View {
        overlay(
            RoundedRectangle(cornerRadius: radius, style: .continuous)
                .strokeBorder(color, lineWidth: 1)
        )
    }

    /// Poster voice: Saira Condensed, uppercase, tight tracking. Two homes.
    func displayVoice(_ size: CGFloat = 26, weight: BulkUpFont.DisplayWeight = .bold,
                      relativeTo style: Font.TextStyle = .title2) -> some View {
        self.font(BulkUpFont.display(size, weight: weight, relativeTo: style))
            .textCase(.uppercase)
            .tracking(-0.2)
    }

    /// Title voice: SF bold, condensed width, sentence case. The day's name,
    /// screen titles, the PRO gate.
    func titleVoice(_ style: Font.TextStyle = .largeTitle) -> some View {
        self.font(.system(style, weight: .bold))
            .fontWidth(.condensed)
            .tracking(-0.3)
    }

    /// Uppercase micro label: 11pt bold SF with wide tracking. Table column
    /// headers and tags only, never above a heading.
    func microLabel(color: Color = BulkUpColors.textSecondary) -> some View {
        self.font(BulkUpFont.badge())
            .tracking(1.2)
            .textCase(.uppercase)
            .foregroundColor(color)
    }
}
