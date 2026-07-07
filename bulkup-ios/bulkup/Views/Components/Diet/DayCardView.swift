//
//  DayCardView.swift
//  bulkup
//
//  Created by sebastianblancogonz on 17/8/25.
//

import SwiftUI
import SwiftData

// MARK: - Compact day row for weekly view — logbook style
struct DayCardView: View {
    let day: DietDay
    let dayIndex: Int
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: Spacing.md) {
                // Day name
                Text(WeekdayLabel.localized(day.day))
                    .font(BulkUpFont.body())
                    .foregroundColor(BulkUpColors.textPrimary)
                    .lineLimit(1)

                Spacer()

                // Meal count
                Text("\(day.meals.count) comidas")
                    .font(BulkUpFont.caption())
                    .foregroundColor(BulkUpColors.textSecondary)
                    .fontDesign(.monospaced)

                // Supplements indicator
                if !day.supplements.isEmpty {
                    Text("+\(day.supplements.count)")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(BulkUpColors.textTertiary)
                }

                Image(systemName: "chevron.right")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(BulkUpColors.textTertiary)
            }
            .padding(.horizontal, Spacing.screenH)
            .padding(.vertical, Spacing.md)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
