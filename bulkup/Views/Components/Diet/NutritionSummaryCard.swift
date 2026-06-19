//
//  NutritionSummaryCard.swift
//  bulkup
//

import SwiftUI

struct NutritionSummaryCard: View {
    let measurements: BodyMeasurements?
    let composition: BodyComposition?
    let complianceStats: ComplianceStatsResponse?

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack {
                Image(systemName: "chart.bar.fill")
                    .foregroundColor(BulkUpColors.diet)

                Text("Resumen Nutricional")
                    .font(BulkUpFont.cardTitle())
                    .fontWeight(.bold)
                    .foregroundColor(BulkUpColors.textPrimary)

                Spacer()
            }

            if let m = measurements, let c = composition {
                HStack(spacing: 0) {
                    MetricPill(label: "Peso", value: String(format: "%.1f kg", m.peso), color: BulkUpColors.training)
                    Spacer()
                    MetricPill(label: "% Grasa", value: String(format: "%.1f%%", c.bodyFatPercentage), color: BulkUpColors.accent)
                    Spacer()
                    MetricPill(label: "Masa Magra", value: String(format: "%.1f kg", c.leanMass), color: BulkUpColors.diet)
                }

                if let stats = complianceStats {
                    Divider()

                    HStack {
                        Label(
                            String(format: String(localized: "Cumplimiento: %.0f%%"), stats.complianceRate * 100),
                            systemImage: "checkmark.circle"
                        )
                        .font(BulkUpFont.caption())
                        .foregroundColor(stats.complianceRate >= 0.8 ? BulkUpColors.diet : BulkUpColors.accent)

                        Spacer()

                        if stats.currentStreak > 0 {
                            Label(
                                String(localized: "\(stats.currentStreak) dias seguidos"),
                                systemImage: "flame"
                            )
                            .font(BulkUpFont.caption())
                            .foregroundColor(BulkUpColors.accent)
                        }
                    }
                }
            } else {
                HStack(spacing: Spacing.sm) {
                    Image(systemName: "info.circle")
                        .foregroundColor(BulkUpColors.textSecondary)
                        .font(BulkUpFont.caption())

                    Text("Agrega tus medidas corporales para ver tu resumen")
                        .font(BulkUpFont.caption())
                        .foregroundColor(BulkUpColors.textSecondary)
                }
            }
        }
        .flatCardStyle()
    }
}

// MARK: - Metric Pill
struct MetricPill: View {
    let label: String
    let value: String
    let color: Color

    var body: some View {
        VStack(spacing: Spacing.xs) {
            Text(value)
                .font(BulkUpFont.sectionHeader())
                .foregroundColor(BulkUpColors.textPrimary)

            Text(label)
                .font(BulkUpFont.caption())
                .foregroundColor(BulkUpColors.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Spacing.sm)
        .background(color.opacity(0.08))
        .cornerRadius(CornerRadius.small)
    }
}
