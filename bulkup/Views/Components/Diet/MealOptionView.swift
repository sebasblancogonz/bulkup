//
//  MealOptionView.swift
//  bulkup
//
//  Created by sebastianblancogonz on 17/8/25.
//

import SwiftUI
import SwiftData

// MARK: - Meal option — indented text block, no card wrapper
struct MealOptionView: View {
    let option: MealOption
    let mealType: String

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            // Option description
            Text(option.optionDescription)
                .font(BulkUpFont.body())
                .foregroundColor(BulkUpColors.textPrimary)

            // Ingredients as bullet list
            if !option.ingredients.isEmpty {
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    ForEach(option.ingredients.indices, id: \.self) { index in
                        HStack(alignment: .top, spacing: Spacing.sm) {
                            Text("\u{2022}")
                                .font(BulkUpFont.caption())
                                .foregroundColor(BulkUpColors.textTertiary)

                            Text(option.ingredients[index])
                                .font(BulkUpFont.caption())
                                .foregroundColor(BulkUpColors.textSecondary)
                        }
                    }
                }
            }

            // Instructions below ingredients
            let instructions = option.instructions
            if !instructions.isEmpty {
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    ForEach(instructions.indices, id: \.self) { index in
                        HStack(alignment: .top, spacing: Spacing.sm) {
                            Text("\(index + 1).")
                                .font(BulkUpFont.caption())
                                .foregroundColor(BulkUpColors.textTertiary)

                            Text(instructions[index])
                                .font(BulkUpFont.caption())
                                .foregroundColor(BulkUpColors.textTertiary)
                        }
                    }
                }
            }
        }
        .padding(.leading, Spacing.sm)
    }
}
