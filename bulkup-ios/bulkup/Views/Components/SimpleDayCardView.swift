//
//  SimpleDayCardView.swift
//  bulkup
//
//  Created by sebastianblancogonz on 18/8/25.
//
import SwiftData
import SwiftUI

// MARK: - Vista de tarjeta de dia SIMPLIFICADA para evitar bloqueos
struct SimpleDayCardView: View {
    let day: DietDay
    let dayIndex: Int
    let isExpanded: Bool
    let onToggleExpand: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            // Header clickeable
            Button(action: onToggleExpand) {
                HStack {
                    Circle()
                        .fill(BulkUpColors.diet)
                        .frame(width: 10, height: 10)

                    Text(WeekdayLabel.localized(day.day))
                        .font(BulkUpFont.cardTitle())
                        .foregroundColor(BulkUpColors.textPrimary)

                    Spacer()

                    Text("\(day.meals.count) comidas")
                        .font(BulkUpFont.caption())
                        .padding(.horizontal, Spacing.sm)
                        .padding(.vertical, Spacing.xs)
                        .background(BulkUpColors.surfaceElevated)
                        .foregroundColor(BulkUpColors.textSecondary)
                        .cornerRadius(CornerRadius.small)

                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .foregroundColor(BulkUpColors.textSecondary)
                        .font(BulkUpFont.caption())
                }
                .padding()
                .background(BulkUpColors.surfaceElevated)
                .contentShape(Rectangle())
            }
            .buttonStyle(PlainButtonStyle())

            // Contenido
            if isExpanded {
                VStack(spacing: Spacing.md) {
                    let sortedMeals = day.meals.sorted(by: { $0.orderIndex < $1.orderIndex })
                    let mealsToShow = Array(sortedMeals.prefix(10))

                    ForEach(mealsToShow, id: \.id) { meal in
                        CompactMealView(meal: meal)
                    }

                    if sortedMeals.count > 10 {
                        Text("... y \(sortedMeals.count - 10) comidas mas")
                            .font(BulkUpFont.caption())
                            .foregroundColor(BulkUpColors.textSecondary)
                            .padding()
                    }
                }
                .padding()
                .background(BulkUpColors.surface)
            }
        }
        .background(BulkUpColors.surface)
        .cornerRadius(CornerRadius.large)
        .overlay(RoundedRectangle(cornerRadius: CornerRadius.large).stroke(BulkUpColors.border, lineWidth: 0.5))
    }
}

// MARK: - Vista compacta de comida para evitar sobrecarga
struct CompactMealView: View {
    let meal: Meal

    var body: some View {
        HStack {
            // Icono de comida
            mealIcon
                .frame(width: 20, height: 20)

            VStack(alignment: .leading, spacing: 2) {
                Text(MealTypeLabel.localized(meal.type))
                    .font(BulkUpFont.body())
                    .foregroundColor(BulkUpColors.textPrimary)

                if !meal.time.isEmpty {
                    Text(meal.time)
                        .font(BulkUpFont.caption())
                        .foregroundColor(BulkUpColors.textSecondary)
                }
            }

            Spacer()

            Text("\(meal.options.count) opciones")
                .font(BulkUpFont.caption())
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(BulkUpColors.surfaceElevated)
                .foregroundColor(BulkUpColors.textSecondary)
                .cornerRadius(Spacing.xs)
        }
        .padding(.vertical, Spacing.xs)
        .padding(.horizontal, Spacing.sm)
        .background(BulkUpColors.surfaceElevated.opacity(0.5))
        .cornerRadius(CornerRadius.small)
    }

    private var mealIcon: some View {
        let iconName: String
        let iconColor: Color

        switch meal.type.lowercased() {
        case let type where type.contains("desayuno") || type.contains("breakfast"):
            iconName = "cup.and.saucer.fill"
            iconColor = BulkUpColors.accent
        case let type where type.contains("almuerzo") || type.contains("comida") || type.contains("lunch"):
            iconName = "sun.max.fill"
            iconColor = BulkUpColors.warning
        case let type where type.contains("merienda") || type.contains("snack"):
            iconName = "sunset.fill"
            iconColor = BulkUpColors.secondary
        case let type where type.contains("cena") || type.contains("dinner"):
            iconName = "moon.fill"
            iconColor = BulkUpColors.training
        default:
            iconName = "fork.knife"
            iconColor = BulkUpColors.diet
        }

        return Image(systemName: iconName)
            .foregroundColor(iconColor)
            .font(BulkUpFont.caption())
    }
}
