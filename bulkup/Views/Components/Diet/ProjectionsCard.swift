//
//  ProjectionsCard.swift
//  bulkup
//

import SwiftUI

struct ProjectionsCard: View {
    let projection: NutritionProjection?
    let reviewDate: Date?

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .foregroundColor(BulkUpColors.training)

                Text("Proyecciones")
                    .font(BulkUpFont.cardTitle())
                    .fontWeight(.bold)
                    .foregroundColor(BulkUpColors.textPrimary)

                Spacer()

                if let date = reviewDate {
                    let daysRemaining = Calendar.current.dateComponents([.day], from: Date(), to: date).day ?? 0
                    Text("Faltan \(max(daysRemaining, 0)) dias")
                        .font(BulkUpFont.caption())
                        .foregroundColor(BulkUpColors.secondary)
                        .padding(.horizontal, Spacing.sm)
                        .padding(.vertical, Spacing.xs)
                        .background(BulkUpColors.secondary.opacity(0.1))
                        .cornerRadius(CornerRadius.small)
                }
            }

            if let p = projection {
                HStack(spacing: 0) {
                    ProjectionMetric(
                        label: "Peso",
                        projected: String(format: "%.1f kg", p.projectedWeight),
                        change: p.weightChange,
                        unit: "kg"
                    )
                    Spacer()
                    ProjectionMetric(
                        label: "Masa Magra",
                        projected: String(format: "%.1f kg", p.projectedLeanMass),
                        change: p.leanMassChange,
                        unit: "kg"
                    )
                    Spacer()
                    ProjectionMetric(
                        label: "% Grasa",
                        projected: String(format: "%.1f%%", p.projectedBodyFat),
                        change: p.bodyFatPercentageChange,
                        unit: "%"
                    )
                }

                HStack(spacing: Spacing.xs) {
                    Image(systemName: "info.circle")
                    Text("Basado en \(Int(p.complianceRate * 100))% de cumplimiento")
                }
                .font(BulkUpFont.caption())
                .foregroundColor(BulkUpColors.textSecondary)
            } else {
                HStack(spacing: Spacing.sm) {
                    Image(systemName: "info.circle")
                        .foregroundColor(BulkUpColors.textSecondary)
                        .font(BulkUpFont.caption())

                    Text("Necesitas medidas corporales y una fecha de revision para ver proyecciones")
                        .font(BulkUpFont.caption())
                        .foregroundColor(BulkUpColors.textSecondary)
                }
            }
        }
        .cardStyle()
    }
}

// MARK: - Projection Metric
struct ProjectionMetric: View {
    let label: String
    let projected: String
    let change: Double
    let unit: String

    var body: some View {
        VStack(spacing: Spacing.xs) {
            Text(projected)
                .font(BulkUpFont.body())
                .foregroundColor(BulkUpColors.textPrimary)

            HStack(spacing: 2) {
                Image(systemName: change >= 0 ? "arrow.up.right" : "arrow.down.right")
                    .font(.system(size: 8))
                Text(String(format: "%+.1f %@", change, unit))
                    .font(.system(size: 10))
            }
            .foregroundColor(changeColor)

            Text(label)
                .font(BulkUpFont.caption())
                .foregroundColor(BulkUpColors.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Spacing.sm)
        .background(BulkUpColors.surfaceElevated)
        .cornerRadius(CornerRadius.small)
    }

    private var changeColor: Color {
        // For body fat, negative is good. For everything else, positive is good
        if label == "% Grasa" {
            return change <= 0 ? BulkUpColors.diet : BulkUpColors.error
        }
        return change >= 0 ? BulkUpColors.diet : BulkUpColors.error
    }
}
