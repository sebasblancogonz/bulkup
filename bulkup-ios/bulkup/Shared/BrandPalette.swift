//
//  BrandPalette.swift
//  bulkup
//
//  "Graphite & Voltage" for the surfaces that cannot import the app's design
//  system: the watch app and the widget extension. Pure SwiftUI, no UIKit, so
//  it compiles on watchOS. Dark values only: the watch ground is OLED black
//  by platform convention and the lock-screen card is graphite in both
//  appearances. Keep in sync with `BulkUpColors` / `BulkUpFont`.
//

import CoreText
import SwiftUI

enum Brand {
    // Ground and slabs (the warm graphite ramp, ≥6 L* between steps)
    static let ground = rgb(0x0E0F0C)
    static let glow = rgb(0x1C1E19)
    static let surface = rgb(0x1A1B17)
    static let raised = rgb(0x272923)
    static let line = rgb(0x2C2E27)
    static let edgeLight = Color.white.opacity(0.09)

    // Text
    static let textPrimary = rgb(0xF3F1EA)
    static let textSecondary = rgb(0xA6A89D)
    static let textTertiary = rgb(0x8E9086)

    // Voltage: action and live progress. Sky: done. Amber: the only error.
    static let lime = rgb(0xB4FF2E)
    static let limePressed = rgb(0x93D414)
    static let onLime = ground
    static let sky = rgb(0x00A9DD)
    static let amber = rgb(0xF5A524)

    private static func rgb(_ hex: UInt32) -> Color {
        Color(.sRGB,
              red: Double((hex >> 16) & 0xFF) / 255,
              green: Double((hex >> 8) & 0xFF) / 255,
              blue: Double(hex & 0xFF) / 255)
    }
}

// MARK: - Type voices
extension Font {
    /// JetBrains Mono where the number *is* the element (timers, fields).
    /// Never below 16pt. Falls back to SF monospaced digits if the face is
    /// not in the bundle.
    static func brandMono(_ size: CGFloat, weight: Font.Weight = .semibold) -> Font {
        let name = weight == .medium ? "JetBrainsMono-Medium" : "JetBrainsMono-SemiBold"
        return BrandFonts.isRegistered(name)
            ? .custom(name, size: size)
            : .system(size: size, weight: weight, design: .default).monospacedDigit()
    }

    /// SF bold with the condensed width: the day's name and screen titles.
    static func brandTitle(_ style: Font.TextStyle) -> Font {
        .system(style, design: .default, weight: .bold).width(.condensed)
    }
}

/// Registers the bundled brand faces for processes without `UIAppFonts`.
enum BrandFonts {
    private static var registered: Set<String> = []
    private static let lock = NSLock()

    static func register() {
        lock.lock(); defer { lock.unlock() }
        for name in ["JetBrainsMono-Medium", "JetBrainsMono-SemiBold"] where !registered.contains(name) {
            if let url = Bundle.main.url(forResource: name, withExtension: "ttf") {
                CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
            }
            // The process may already have the face (UIAppFonts); trust CoreText, not the result code.
            let font = CTFontCreateWithName(name as CFString, 12, nil)
            if CTFontCopyPostScriptName(font) as String == name {
                registered.insert(name)
            }
        }
    }

    static func isRegistered(_ name: String) -> Bool {
        lock.lock(); defer { lock.unlock() }
        return registered.contains(name)
    }
}

// MARK: - Light instead of lines
/// A container separated from the ground by its fill and a 1pt light along its
/// top edge, never by an outline. Mirrors the app's `LiftModifier`.
struct BrandLift: ViewModifier {
    var radius: CGFloat
    var stroke: Color?

    func body(content: Content) -> some View {
        content.overlay(
            RoundedRectangle(cornerRadius: radius, style: .continuous)
                .strokeBorder(
                    stroke.map { AnyShapeStyle($0) } ?? AnyShapeStyle(
                        LinearGradient(colors: [Brand.edgeLight, Color.white.opacity(0.015)],
                                       startPoint: .top, endPoint: .bottom)),
                    lineWidth: 1
                )
        )
    }
}

extension View {
    func brandLift(_ radius: CGFloat = 12, stroke: Color? = nil) -> some View {
        modifier(BrandLift(radius: radius, stroke: stroke))
    }
}

// MARK: - Numbers
enum BrandFormat {
    /// "62,5" in es, "62.5" in en; never a trailing ".0".
    static func weight(_ w: Double) -> String {
        w.formatted(.number.precision(.fractionLength(0...2)))
    }
}
