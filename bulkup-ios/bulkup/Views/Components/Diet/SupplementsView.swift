//
//  SupplementsView.swift
//  bulkup
//
//  Created by sebastianblancogonz on 17/8/25.
//

import SwiftUI
import SwiftData

// MARK: - Supplements — card-based, first-class tracked items
struct SupplementsView: View {
    let supplements: [Supplement]

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            ForEach(supplements.indices, id: \.self) { index in
                SupplementRow(supplement: supplements[index])
            }
        }
    }
}

// MARK: - Single supplement card
struct SupplementRow: View {
    let supplement: Supplement

    var body: some View {
        HStack(spacing: Spacing.md) {
            // Icon
            Image(systemName: "pills.fill")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(BulkUpColors.accent)
                .frame(width: 24)

            // Name + timing
            VStack(alignment: .leading, spacing: 2) {
                Text(supplement.name)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(BulkUpColors.textPrimary)

                HStack(spacing: 4) {
                    Text(supplement.timing)
                        .font(BulkUpFont.caption())
                        .foregroundColor(BulkUpColors.textSecondary)

                    if !supplement.frequency.isEmpty {
                        Text("·")
                            .foregroundColor(BulkUpColors.textTertiary)
                        Text(supplement.frequency)
                            .font(BulkUpFont.caption())
                            .foregroundColor(BulkUpColors.textSecondary)
                    }
                }
            }

            Spacer()

            // Dosage pill
            Text(supplement.dosage)
                .font(BulkUpFont.badge())
                .foregroundColor(BulkUpColors.accent)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(BulkUpColors.accent.opacity(0.12))
                .clipShape(Capsule())
        }
        .padding(Spacing.md)
        .background(BulkUpColors.surface)
        .cornerRadius(CornerRadius.large)
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.large)
                .stroke(BulkUpColors.border, lineWidth: 0.5)
        )
    }
}
