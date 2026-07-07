//
//  PremiumMetrics.swift
//  bulkup
//
//  Whoop/Apple-style minimal building blocks: hero metric rings, quiet flat
//  cards, and uppercase micro-labels. Deliberately monochrome + single lime
//  accent — few colors, few shapes, lots of breathing room.
//

import SwiftUI

/// A circular metric ring: thin gray track + lime progress arc, with a big
/// centered value and an uppercase micro-label underneath.
struct MetricRing: View {
    let value: String              // "76%", "3/4", "5"
    let label: String              // localized via catalog (e.g. "ENTRENOS")
    var progress: Double           // 0...1
    var tint: Color = BulkUpColors.accent
    var size: CGFloat = 96
    var dimmed: Bool = false       // no data → muted ring + value

    private var lineWidth: CGFloat { max(7, size * 0.085) }

    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .stroke(BulkUpColors.muscleDefault, lineWidth: lineWidth)  // visible track in both themes
                Circle()
                    .trim(from: 0, to: max(0.0001, min(1, progress)))
                    .stroke(
                        dimmed ? BulkUpColors.textTertiary : tint,
                        style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                Text(value)
                    .font(.system(size: size * 0.3, weight: .bold, design: .rounded))
                    .foregroundColor(dimmed ? BulkUpColors.textSecondary : BulkUpColors.textPrimary)
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)
                    .padding(lineWidth + 6)
            }
            .frame(width: size, height: size)

            Text(LocalizedStringKey(label))
                .font(.system(size: 11, weight: .bold))
                .tracking(1.3)
                .foregroundColor(BulkUpColors.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }
}

/// Uppercase micro section label.
struct MicroLabel: View {
    let text: String
    init(_ text: String) { self.text = text }
    var body: some View {
        Text(LocalizedStringKey(text))
            .font(.system(size: 12, weight: .bold))
            .tracking(1.3)
            .foregroundColor(BulkUpColors.textSecondary)
    }
}

extension View {
    /// Quiet premium card: flat #111827 surface, 22pt continuous radius,
    /// generous padding, NO border or shadow.
    func whoopCard(padding: CGFloat = 18) -> some View {
        self
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(BulkUpColors.surface)
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
    }
}
