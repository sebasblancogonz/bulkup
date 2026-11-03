//
//  StatsStrip.swift
//  bulkup
//
//  One lifted slab, up to three cells divided by 1×44pt lines: a mono value,
//  a caption label, an optional tabular detail line and an optional 3pt
//  progress rule. The summary's strip, generalised for Progress and Records.
//

import SwiftUI

struct StatCell: Identifiable {
    let id = UUID()
    let value: String
    /// Caption unit after the value ("kg", "%").
    var unit: String? = nil
    let label: LocalizedStringKey
    var detail: String? = nil
    var detailTint: Color? = nil
    /// 0…1 draws a lime rule under the value (lime = live progress).
    var progress: Double? = nil
}

struct StatsStrip: View {
    let cells: [StatCell]
    /// Inside another slab: no background, no outer padding.
    var bare: Bool = false
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        Group {
            if dynamicTypeSize.isAccessibilitySize {
                // Cells stack at accessibility sizes so no label truncates.
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(Array(cells.enumerated()), id: \.element.id) { i, cell in
                        cellView(cell)
                            .padding(.vertical, Spacing.sm)
                        if i < cells.count - 1 {
                            Rectangle().fill(BulkUpColors.line).frame(height: 1)
                        }
                    }
                }
            } else {
                HStack(alignment: .top, spacing: 0) {
                    ForEach(Array(cells.enumerated()), id: \.element.id) { i, cell in
                        cellView(cell)
                        if i < cells.count - 1 {
                            Rectangle()
                                .fill(BulkUpColors.line)
                                .frame(width: 1, height: 44)
                                .padding(.horizontal, Spacing.sm + 2)
                        }
                    }
                }
            }
        }
        .padding(bare ? 0 : Spacing.md)
        .background(bare ? Color.clear : BulkUpColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: bare ? 0 : CornerRadius.large, style: .continuous))
        .if(!bare) { $0.lift() }
    }

    private func cellView(_ cell: StatCell) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .firstTextBaseline, spacing: 3) {
                Text(cell.value)
                    .font(BulkUpFont.mono(22, weight: .semibold, relativeTo: .title2))
                    .foregroundColor(BulkUpColors.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                if let unit = cell.unit {
                    Text(unit)
                        .font(BulkUpFont.caption())
                        .foregroundColor(BulkUpColors.textSecondary)
                }
            }
            Text(cell.label)
                .font(BulkUpFont.caption())
                .foregroundColor(BulkUpColors.textSecondary)
                .lineLimit(dynamicTypeSize.isAccessibilitySize ? nil : 1)
                .minimumScaleFactor(dynamicTypeSize.isAccessibilitySize ? 1 : 0.85)
            if let progress = cell.progress {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(BulkUpColors.line)
                        Capsule().fill(BulkUpColors.accent)
                            .frame(width: max(0, geo.size.width * min(1, max(0, progress))))
                    }
                }
                .frame(height: 3)
                .padding(.top, 2)
            }
            if let detail = cell.detail {
                Text(detail)
                    .font(BulkUpFont.numeric(.caption2, weight: .medium))
                    .foregroundColor(cell.detailTint ?? BulkUpColors.textTertiary)
                    .lineLimit(1)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Slab rows
/// A list row inside a lifted slab: 16pt inset, 1pt `line` separator beneath.
struct SlabRow<Content: View>: View {
    var showsSeparator: Bool = true
    var minHeight: CGFloat = 52
    @ViewBuilder var content: Content

    var body: some View {
        VStack(spacing: 0) {
            content
                .padding(.horizontal, Spacing.md)
                .padding(.vertical, Spacing.sm + 2)
                .frame(maxWidth: .infinity, minHeight: minHeight, alignment: .leading)
            if showsSeparator {
                Rectangle()
                    .fill(BulkUpColors.line)
                    .frame(height: 1)
                    .padding(.leading, Spacing.md)
            }
        }
    }
}

extension View {
    /// A lifted surface slab with no inner padding (rows bring their own).
    func slab() -> some View {
        self
            .background(BulkUpColors.surface)
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.large, style: .continuous))
            .lift()
    }
}
