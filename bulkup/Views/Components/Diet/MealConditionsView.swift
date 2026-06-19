//
//  MealConditionsView.swift
//  bulkup
//
//  Created by sebastianblancogonz on 17/8/25.
//

import SwiftUI
import SwiftData

// MARK: - Conditional meals — simple toggle between training/rest day
struct MealConditionsView: View {
    let conditions: MealConditions
    let mealType: String

    @State private var showTrainingDay: Bool = true

    private var hasTraining: Bool { conditions.trainingDays != nil }
    private var hasRest: Bool { conditions.nonTrainingDays != nil }
    private var hasBoth: Bool { hasTraining && hasRest }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            // Toggle between conditions (only if both exist)
            if hasBoth {
                HStack(spacing: 0) {
                    conditionTab(
                        label: "Entreno",
                        isSelected: showTrainingDay,
                        action: { showTrainingDay = true }
                    )
                    conditionTab(
                        label: "Descanso",
                        isSelected: !showTrainingDay,
                        action: { showTrainingDay = false }
                    )
                }
                .background(BulkUpColors.surfaceElevated)
                .cornerRadius(CornerRadius.small)
            }

            // Content
            if showTrainingDay, let trainingDays = conditions.trainingDays {
                if !hasBoth {
                    Text("Dias de entrenamiento")
                        .font(BulkUpFont.dataLabel())
                        .foregroundColor(BulkUpColors.training)
                }
                conditionContent(trainingDays)
            } else if !showTrainingDay, let restDays = conditions.nonTrainingDays {
                if !hasBoth {
                    Text("Dias de descanso")
                        .font(BulkUpFont.dataLabel())
                        .foregroundColor(BulkUpColors.textTertiary)
                }
                conditionContent(restDays)
            } else if !hasTraining, let restDays = conditions.nonTrainingDays {
                Text("Dias de descanso")
                    .font(BulkUpFont.dataLabel())
                    .foregroundColor(BulkUpColors.textTertiary)
                conditionContent(restDays)
            }
        }
        .padding(.leading, Spacing.sm)
        .onAppear {
            // Default to training if only rest exists
            if !hasTraining && hasRest {
                showTrainingDay = false
            }
        }
    }

    private func conditionTab(label: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: {
            withAnimation(.easeInOut(duration: 0.15)) {
                action()
            }
        }) {
            Text(label)
                .font(BulkUpFont.dataLabel())
                .foregroundColor(isSelected ? BulkUpColors.textPrimary : BulkUpColors.textTertiary)
                .padding(.horizontal, Spacing.md)
                .padding(.vertical, Spacing.sm)
                .background(isSelected ? BulkUpColors.surface : Color.clear)
                .cornerRadius(CornerRadius.small)
        }
        .buttonStyle(.plain)
    }

    private func conditionContent(_ condition: ConditionalMeal) -> some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
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
    }
}
