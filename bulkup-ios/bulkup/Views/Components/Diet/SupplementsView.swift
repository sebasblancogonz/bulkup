//
//  SupplementsView.swift
//  bulkup
//
//  Supplements as rows of one lifted slab: name, when, and the dose in
//  tabular figures on a quiet chip.
//

import SwiftUI
import SwiftData

struct SupplementsView: View {
    let supplements: [Supplement]

    var body: some View {
        VStack(spacing: 0) {
            ForEach(supplements.indices, id: \.self) { index in
                SupplementRow(supplement: supplements[index], showsSeparator: index < supplements.count - 1)
            }
        }
        .background(BulkUpColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.large, style: .continuous))
        .lift()
    }
}

struct SupplementRow: View {
    let supplement: Supplement
    var showsSeparator: Bool = true

    var body: some View {
        HStack(spacing: Spacing.md) {
            Image(systemName: "pills")
                .font(.system(.footnote, weight: .semibold))
                .foregroundColor(BulkUpColors.textSecondary)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(supplement.name)
                    .font(.system(.subheadline, weight: .semibold))
                    .foregroundColor(BulkUpColors.textPrimary)

                HStack(spacing: 4) {
                    Text(supplement.timing)
                    if !supplement.frequency.isEmpty {
                        Text("·")
                        Text(supplement.frequency)
                    }
                }
                .font(BulkUpFont.caption())
                .foregroundColor(BulkUpColors.textSecondary)
            }

            Spacer(minLength: Spacing.sm)

            Text(supplement.dosage)
                .font(BulkUpFont.numeric(.footnote, weight: .semibold))
                .foregroundColor(BulkUpColors.textPrimary)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(BulkUpColors.surfaceElevated)
                .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
        }
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, 12)
        .overlay(alignment: .bottom) {
            if showsSeparator {
                Rectangle().fill(BulkUpColors.line).frame(height: 1).padding(.leading, Spacing.md)
            }
        }
    }
}
