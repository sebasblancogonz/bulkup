//
//  ProjectionsCard.swift
//  bulkup
//

import SwiftUI

struct ProjectionsCard: View {
    let projection: NutritionProjection?
    let reviewDate: Date?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .foregroundColor(.blue)

                Text("Proyecciones")
                    .font(.headline)
                    .fontWeight(.bold)

                Spacer()

                if let date = reviewDate {
                    let daysRemaining = Calendar.current.dateComponents([.day], from: Date(), to: date).day ?? 0
                    Text("Faltan \(max(daysRemaining, 0)) dias")
                        .font(.caption)
                        .foregroundColor(.purple)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.purple.opacity(0.1))
                        .cornerRadius(6)
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

                HStack(spacing: 4) {
                    Image(systemName: "info.circle")
                    Text("Basado en \(Int(p.complianceRate * 100))% de cumplimiento")
                }
                .font(.caption2)
                .foregroundColor(.secondary)
            } else {
                HStack(spacing: 8) {
                    Image(systemName: "info.circle")
                        .foregroundColor(.secondary)
                        .font(.caption)

                    Text("Necesitas medidas corporales y una fecha de revision para ver proyecciones")
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

// MARK: - Projection Metric
struct ProjectionMetric: View {
    let label: String
    let projected: String
    let change: Double
    let unit: String

    var body: some View {
        VStack(spacing: 4) {
            Text(projected)
                .font(.system(size: 14, weight: .bold, design: .rounded))

            HStack(spacing: 2) {
                Image(systemName: change >= 0 ? "arrow.up.right" : "arrow.down.right")
                    .font(.system(size: 8))
                Text(String(format: "%+.1f %@", change, unit))
                    .font(.system(size: 10))
            }
            .foregroundColor(changeColor)

            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(Color(.systemGray5).opacity(0.5))
        .cornerRadius(8)
    }

    private var changeColor: Color {
        // For body fat, negative is good. For everything else, positive is good
        if label == "% Grasa" {
            return change <= 0 ? .green : .red
        }
        return change >= 0 ? .green : .red
    }
}
