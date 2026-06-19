//
//  ConditionCardView.swift
//  bulkup
//
//  Created by sebastianblancogonz on 17/8/25.
//
//  Note: This view is no longer used. Conditional meals are now rendered
//  inline by MealConditionsView using a tab-style toggle.
//

import SwiftUI
import SwiftData

struct ConditionCardView: View {
    let condition: ConditionalMeal
    let title: String
    let color: Color
    let icon: String

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text(title)
                .font(BulkUpFont.dataLabel())
                .foregroundColor(color)

            Text(condition.mealDescription)
                .font(BulkUpFont.body())
                .foregroundColor(BulkUpColors.textPrimary)

            if !condition.ingredients.isEmpty {
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    ForEach(condition.ingredients.indices, id: \.self) { index in
                        HStack(alignment: .top, spacing: Spacing.sm) {
                            Text("\u{2022}")
                                .font(BulkUpFont.caption())
                                .foregroundColor(BulkUpColors.textTertiary)

                            Text(condition.ingredients[index])
                                .font(BulkUpFont.caption())
                                .foregroundColor(BulkUpColors.textSecondary)
                        }
                    }
                }
            }
        }
        .padding(.leading, Spacing.sm)
    }
}
