//
//  StatsCardsView.swift
//  bulkup
//
//  Created by sebastianblancogonz on 20/8/25.
//
import SwiftUI

// MARK: - Stats Cards View
struct StatsCardsView: View {
    let stats: RecordStats

    var body: some View {
        LazyVGrid(columns: columns, spacing: Spacing.lg) {
            StatsCard(
                icon: "trophy.fill",
                title: "Pesos Registrados",
                value: "\(stats.totalRecords)",
                subtitle: "Total de sets registrados",
                gradientColors: [BulkUpColors.success, BulkUpColors.success.opacity(0.8)]
            )

            StatsCard(
                icon: "chart.line.uptrend.xyaxis",
                title: "Ejercicios con RM",
                value: "\(stats.exercisesWithRM)",
                subtitle: "Con récords registrados",
                gradientColors: [BulkUpColors.secondary, BulkUpColors.secondary.opacity(0.8)]
            )

            StatsCard(
                icon: "calendar",
                title: "Este Mes",
                value: "\(stats.recordsThisMonth)",
                subtitle: "Nuevos registros",
                gradientColors: [BulkUpColors.training, BulkUpColors.training.opacity(0.8)]
            )
        }
    }

    private var columns: [GridItem] {
        [
            GridItem(.flexible(), spacing: Spacing.lg),
            GridItem(.flexible(), spacing: Spacing.lg)
        ]
    }
}

// MARK: - Individual Stats Card
struct StatsCard: View {
    let icon: String
    let title: String
    let value: String
    let subtitle: String
    let gradientColors: [Color]

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack(spacing: Spacing.sm) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(.white)

                Text(LocalizedStringKey(title))
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white.opacity(0.9))
                    .lineLimit(1)

                Spacer()
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(.white)

                Text(LocalizedStringKey(subtitle))
                    .font(.system(size: 10))
                    .foregroundColor(.white.opacity(0.75))
                    .lineLimit(2)
            }
        }
        .padding(Spacing.lg)
        .background(
            LinearGradient(
                colors: gradientColors,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(CornerRadius.large)
        .overlay(RoundedRectangle(cornerRadius: CornerRadius.large).stroke(BulkUpColors.border, lineWidth: 0.5))
    }
}

// MARK: - Preview
struct StatsCardsView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            StatsCardsView(stats: RecordStats(
                totalRecords: 125,
                exercisesWithRM: 15,
                recordsThisMonth: 23
            ))

            StatsCardsView(stats: RecordStats.empty)
        }
        .padding()
        .background(BulkUpColors.background)
    }
}

// MARK: - Responsive Layout Helper
extension StatsCardsView {
    static func adaptiveColumns(for geometry: GeometryProxy) -> [GridItem] {
        let width = geometry.size.width

        if width < 400 {
            return [GridItem(.flexible())]
        } else if width < 600 {
            return Array(repeating: GridItem(.flexible(), spacing: Spacing.lg), count: 2)
        } else {
            return Array(repeating: GridItem(.flexible(), spacing: Spacing.lg), count: 3)
        }
    }
}

// MARK: - Usage Example with Adaptive Layout
struct AdaptiveStatsCardsView: View {
    let stats: RecordStats

    var body: some View {
        GeometryReader { geometry in
            LazyVGrid(columns: StatsCardsView.adaptiveColumns(for: geometry), spacing: Spacing.lg) {
                StatsCard(
                    icon: "trophy.fill",
                    title: "Pesos Registrados",
                    value: "\(stats.totalRecords)",
                    subtitle: "Total de sets registrados",
                    gradientColors: [BulkUpColors.success, BulkUpColors.success.opacity(0.8)]
                )

                StatsCard(
                    icon: "chart.line.uptrend.xyaxis",
                    title: "Ejercicios con RM",
                    value: "\(stats.exercisesWithRM)",
                    subtitle: "Con récords registrados",
                    gradientColors: [BulkUpColors.secondary, BulkUpColors.secondary.opacity(0.8)]
                )

                StatsCard(
                    icon: "calendar",
                    title: "Este Mes",
                    value: "\(stats.recordsThisMonth)",
                    subtitle: "Nuevos registros",
                    gradientColors: [BulkUpColors.training, BulkUpColors.training.opacity(0.8)]
                )
            }
        }
    }
}
