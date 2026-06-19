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
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "chart.bar.fill")
                    .foregroundColor(.green)

                Text("Resumen Nutricional")
                    .font(.headline)
                    .fontWeight(.bold)

                Spacer()
            }

            if let m = measurements, let c = composition {
                HStack(spacing: 0) {
                    MetricPill(label: "Peso", value: String(format: "%.1f kg", m.peso), color: .blue)
                    Spacer()
                    MetricPill(label: "% Grasa", value: String(format: "%.1f%%", c.bodyFatPercentage), color: .orange)
                    Spacer()
                    MetricPill(label: "Masa Magra", value: String(format: "%.1f kg", c.leanMass), color: .green)
                }

                if let stats = complianceStats {
                    Divider()

                    HStack {
                        Label(
                            String(format: "Cumplimiento: %.0f%%", stats.complianceRate * 100),
                            systemImage: "checkmark.circle"
                        )
                        .font(.caption)
                        .foregroundColor(stats.complianceRate >= 0.8 ? .green : .orange)

                        Spacer()

                        if stats.currentStreak > 0 {
                            Label(
                                "\(stats.currentStreak) dias seguidos",
                                systemImage: "flame"
                            )
                            .font(.caption)
                            .foregroundColor(.orange)
                        }
                    }
                }
            } else {
                HStack(spacing: 8) {
                    Image(systemName: "info.circle")
                        .foregroundColor(.secondary)
                        .font(.caption)

                    Text("Agrega tus medidas corporales para ver tu resumen")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - Metric Pill
struct MetricPill: View {
    let label: String
    let value: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundColor(color)

            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(color.opacity(0.08))
        .cornerRadius(8)
    }
}
