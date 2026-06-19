//
//  ViewModifiers.swift
//  bulkup
//
//  Premium fitness component modifiers — Freeletics-inspired dark immersive aesthetic.
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
            .cornerRadius(CornerRadius.large)
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadius.large)
                    .stroke(BulkUpColors.border, lineWidth: 0.5)
            )
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
            .cornerRadius(CornerRadius.large)
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadius.large)
                    .stroke(color.opacity(0.4), lineWidth: 1.5)
            )
    }
}

// MARK: - Active Card (left accent border — in-progress items)
struct ActiveCardStyle: ViewModifier {
    var color: Color = BulkUpColors.accent

    func body(content: Content) -> some View {
        content
            .padding(Spacing.md)
            .background(BulkUpColors.surface)
            .cornerRadius(CornerRadius.large)
            .overlay(alignment: .leading) {
                UnevenRoundedRectangle(
                    topLeadingRadius: CornerRadius.large,
                    bottomLeadingRadius: CornerRadius.large,
                    bottomTrailingRadius: 0,
                    topTrailingRadius: 0
                )
                .fill(color)
                .frame(width: 3)
            }
            .clipped()
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
            .font(.system(size: 17, weight: .semibold))
            .foregroundColor(BulkUpColors.onAccent)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(
                LinearGradient(
                    colors: [color, color.opacity(0.7)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .cornerRadius(CornerRadius.medium)
            .shadow(color: color.opacity(0.3), radius: 12, x: 0, y: 4)
    }
}

// MARK: - Secondary Button
struct SecondaryButtonModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.system(size: 15, weight: .medium))
            .foregroundColor(BulkUpColors.textPrimary)
            .frame(maxWidth: .infinity)
            .frame(height: 48)
            .background(BulkUpColors.surfaceElevated)
            .cornerRadius(CornerRadius.medium)
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadius.medium)
                    .stroke(BulkUpColors.border, lineWidth: 0.5)
            )
    }
}

// MARK: - Outline Button (e.g. "Skip Rest")
struct OutlineButtonModifier: ViewModifier {
    var color: Color = BulkUpColors.accent

    func body(content: Content) -> some View {
        content
            .font(.system(size: 15, weight: .medium))
            .foregroundColor(color)
            .frame(maxWidth: .infinity)
            .frame(height: 48)
            .background(Color.clear)
            .cornerRadius(CornerRadius.medium)
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadius.medium)
                    .stroke(color.opacity(0.5), lineWidth: 1.5)
            )
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
                .stroke(color.opacity(0.15), lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    AngularGradient(
                        colors: [color, color.opacity(0.5), color],
                        center: .center,
                        startAngle: .degrees(-90),
                        endAngle: .degrees(270)
                    ),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
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
            Text(text.uppercased())
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
                    .foregroundColor(BulkUpColors.accent)
            }
            HStack(alignment: .firstTextBaseline, spacing: Spacing.xs) {
                Text(value)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .foregroundColor(BulkUpColors.textPrimary)
                if let trend {
                    Text(trend)
                        .font(BulkUpFont.caption())
                        .foregroundColor(trendUp ? BulkUpColors.success : BulkUpColors.error)
                }
            }
            Text(label.uppercased())
                .font(BulkUpFont.badge())
                .tracking(0.5)
                .foregroundColor(BulkUpColors.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .flatCardStyle()
    }
}

// MARK: - Calendar Day (week strip)
struct CalendarDayView: View {
    let dayLetter: String
    let isToday: Bool
    let isCompleted: Bool

    var body: some View {
        VStack(spacing: 6) {
            Text(dayLetter)
                .font(.system(size: 13, weight: isToday ? .bold : .medium))
                .foregroundColor(isToday ? BulkUpColors.textPrimary : BulkUpColors.textSecondary)

            Circle()
                .fill(
                    isToday ? BulkUpColors.accent :
                    isCompleted ? BulkUpColors.accent.opacity(0.6) :
                    Color.clear
                )
                .frame(width: isToday ? 32 : 6, height: isToday ? 32 : 6)
                .overlay {
                    if isToday {
                        Text(Calendar.current.component(.day, from: Date()).description)
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(BulkUpColors.onAccent)
                    }
                }

            if !isToday && isCompleted {
                Circle()
                    .fill(BulkUpColors.accent)
                    .frame(width: 4, height: 4)
            } else if !isToday {
                Circle()
                    .fill(Color.clear)
                    .frame(width: 4, height: 4)
            }
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
