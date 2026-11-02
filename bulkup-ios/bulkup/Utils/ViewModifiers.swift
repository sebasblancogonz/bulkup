//
//  ViewModifiers.swift
//  bulkup
//
//  Shared component grammar for the "Graphite & Voltage" system: hairline
//  cards, squared lime buttons, mono data, sky for done.
//

import SwiftUI

// MARK: - Liquid Glass Note
// Glass effects (.glassEffect()) are ONLY for navigation layer elements.
// Content cards use opaque surfaces with depth via elevation + borders.

// MARK: - Elevated Card (primary content container)
struct CardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(Spacing.md)
            .background(BulkUpColors.surface)
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.large, style: .continuous))
            .hairline()
    }
}

// MARK: - Flat Card (nested/secondary container)
struct FlatCardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(Spacing.md)
            .background(BulkUpColors.surfaceElevated)
            .cornerRadius(CornerRadius.medium)
    }
}

// MARK: - Accent Card (highlights, streaks, active state)
struct AccentCardStyle: ViewModifier {
    var color: Color = BulkUpColors.accent

    func body(content: Content) -> some View {
        content
            .padding(Spacing.md)
            .background(BulkUpColors.surface)
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.large, style: .continuous))
            .hairline(color: color.opacity(0.6))
    }
}

// MARK: - Active Card (in-progress items: tinted hairline, no side stripe)
struct ActiveCardStyle: ViewModifier {
    var color: Color = BulkUpColors.accent

    func body(content: Content) -> some View {
        content
            .padding(Spacing.md)
            .background(BulkUpColors.surface)
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.large, style: .continuous))
            .hairline(color: color.opacity(0.7))
    }
}

// MARK: - Photo Card (photography-forward, gradient scrim)
struct PhotoCardModifier: ViewModifier {
    var height: CGFloat = 200

    func body(content: Content) -> some View {
        content
            .frame(height: height)
            .frame(maxWidth: .infinity)
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.large))
    }
}

// MARK: - Primary CTA Button
struct PrimaryButtonModifier: ViewModifier {
    var color: Color = BulkUpColors.accent

    func body(content: Content) -> some View {
        content
            .font(BulkUpFont.display(19, weight: .semibold, relativeTo: .headline))
            .textCase(.uppercase)
            .tracking(0.8)
            .foregroundColor(Color.onFill(color))
            .frame(maxWidth: .infinity)
            .frame(minHeight: 54)
            .background(color)
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.medium, style: .continuous))
    }
}

// MARK: - Secondary Button
struct SecondaryButtonModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.system(.subheadline, weight: .semibold))
            .foregroundColor(BulkUpColors.textPrimary)
            .frame(maxWidth: .infinity)
            .frame(minHeight: 48)
            .background(BulkUpColors.surfaceElevated)
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.medium, style: .continuous))
            .hairline(CornerRadius.medium)
    }
}

// MARK: - Outline Button (e.g. "Skip Rest")
struct OutlineButtonModifier: ViewModifier {
    var color: Color = BulkUpColors.accent

    func body(content: Content) -> some View {
        content
            .font(.system(.subheadline, weight: .semibold))
            .foregroundColor(color)
            .frame(maxWidth: .infinity)
            .frame(minHeight: 48)
            .background(Color.clear)
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.medium, style: .continuous))
            .hairline(CornerRadius.medium, color: color.opacity(0.7))
    }
}

// MARK: - Section Header
struct SectionHeaderStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(BulkUpFont.sectionHeader())
            .foregroundColor(BulkUpColors.textPrimary)
    }
}

// MARK: - Gradient Progress Ring
struct GradientProgressRing: View {
    let progress: CGFloat
    var lineWidth: CGFloat = 6
    var size: CGFloat = 48
    var color: Color = BulkUpColors.accent

    var body: some View {
        ZStack {
            Circle()
                .stroke(BulkUpColors.line, lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: max(0, min(1, progress)))
                .stroke(color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .butt))
                .rotationEffect(.degrees(-90))
                .animation(.easeOut(duration: 0.8), value: progress)
        }
        .frame(width: size, height: size)
    }
}

// MARK: - Pill Badge
struct PillBadge: View {
    let text: String
    var color: Color = BulkUpColors.accent
    var icon: String? = nil

    var body: some View {
        HStack(spacing: 4) {
            if let icon {
                Image(systemName: icon)
                    .font(.system(size: 9, weight: .bold))
            }
            Text(LocalizedStringKey(text))
                .textCase(.uppercase)
                .font(BulkUpFont.badge())
                .tracking(1)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(color.opacity(0.15))
        .foregroundColor(color)
        .clipShape(Capsule())
    }
}

// MARK: - Stat Card (mini stat display)
struct StatCard: View {
    let value: String
    let label: String
    var icon: String? = nil
    var trend: String? = nil
    var trendUp: Bool = true

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            if let icon {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(BulkUpColors.accentText)
            }
            HStack(alignment: .firstTextBaseline, spacing: Spacing.xs) {
                Text(value)
                    .font(BulkUpFont.mono(26, weight: .semibold, relativeTo: .title2))
                    .foregroundColor(BulkUpColors.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                if let trend {
                    Text(trend)
                        .font(BulkUpFont.caption())
                        .foregroundColor(trendUp ? BulkUpColors.success : BulkUpColors.error)
                }
            }
            Text(LocalizedStringKey(label))
                .textCase(.uppercase)
                .font(BulkUpFont.badge())
                .tracking(0.5)
                .foregroundColor(BulkUpColors.textSecondary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .flatCardStyle()
    }
}

// MARK: - Calendar Day (week strip)
struct CalendarDayView: View {
    let dayLetter: String
    let dayNumber: String
    let isToday: Bool
    let isCompleted: Bool

    var body: some View {
        VStack(spacing: 6) {
            Text(dayLetter)
                .font(.system(size: 13, weight: isToday ? .bold : .medium))
                .foregroundColor(isToday ? BulkUpColors.textPrimary : BulkUpColors.textSecondary)

            ZStack {
                RoundedRectangle(cornerRadius: CornerRadius.small, style: .continuous)
                    .fill(isToday ? BulkUpColors.accent : Color.clear)
                    .frame(width: 32, height: 32)
                Text(dayNumber)
                    .font(BulkUpFont.mono(13, weight: isToday ? .semibold : .medium, relativeTo: .footnote))
                    .foregroundColor(isToday ? BulkUpColors.onAccent : BulkUpColors.textPrimary)
            }

            // Logged-day mark (sky = done); kept clear-sized so the row stays aligned
            Circle()
                .fill(isCompleted ? BulkUpColors.complete : Color.clear)
                .frame(width: 5, height: 5)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - View Extensions
extension View {
    func cardStyle() -> some View {
        modifier(CardStyle())
    }

    func flatCardStyle() -> some View {
        modifier(FlatCardStyle())
    }

    func accentCardStyle(color: Color = BulkUpColors.accent) -> some View {
        modifier(AccentCardStyle(color: color))
    }

    func activeCardStyle(color: Color = BulkUpColors.accent) -> some View {
        modifier(ActiveCardStyle(color: color))
    }

    func photoCard(height: CGFloat = 200) -> some View {
        modifier(PhotoCardModifier(height: height))
    }

    func primaryButtonStyle(color: Color = BulkUpColors.accent) -> some View {
        modifier(PrimaryButtonModifier(color: color))
    }

    func secondaryButtonStyle() -> some View {
        modifier(SecondaryButtonModifier())
    }

    func outlineButtonStyle(color: Color = BulkUpColors.accent) -> some View {
        modifier(OutlineButtonModifier(color: color))
    }

    func sectionHeader() -> some View {
        modifier(SectionHeaderStyle())
    }

    /// Scale-on-press effect for tappable cards
    func pressable() -> some View {
        self.buttonStyle(PressableButtonStyle())
    }

    /// Conditionally apply a modifier
    @ViewBuilder
    func `if`<Transform: View>(_ condition: Bool, transform: (Self) -> Transform) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }

    /// Soft adaptive card shadow (deep in dark, soft warm-gray in light).
    func cardShadow(radius: CGFloat = 12, y: CGFloat = 6) -> some View {
        shadow(color: BulkUpColors.shadow.opacity(0.18), radius: radius, x: 0, y: y)
    }

    /// Accent glow that reads in both modes.
    func accentGlowShadow(radius: CGFloat = 16) -> some View {
        shadow(color: BulkUpColors.accent.opacity(0.35), radius: radius, x: 0, y: 0)
    }

    /// Gradient scrim overlay for text readability on images
    func gradientScrim(alignment: Alignment = .bottom) -> some View {
        self.overlay(alignment: alignment) {
            LinearGradient(
                colors: [.clear, Color.black.opacity(0.8)],
                startPoint: alignment == .bottom ? .top : .bottom,
                endPoint: alignment == .bottom ? .bottom : .top
            )
        }
    }
}

// MARK: - Pressable Button Style (scale on press)
struct PressableButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: configuration.isPressed)
    }
}
