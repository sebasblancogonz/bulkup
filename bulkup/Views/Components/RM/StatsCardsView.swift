//
//  StatsCardsView.swift
//  bulkup
//
//  Created by sebastian.blanco on 20/8/25.
//
import SwiftUI

// MARK: - Stats Cards View
struct StatsCardsView: View {
    let stats: RecordStats
    
    var body: some View {
        LazyVGrid(columns: columns, spacing: 16) {
            StatsCard(
                icon: "trophy.fill",
                title: "Pesos Registrados",
                value: "\(stats.totalRecords)",
                subtitle: "Total de sets registrados",
                gradientColors: [Color.green, Color.green.opacity(0.8)]
            )
            
            StatsCard(
                icon: "chart.line.uptrend.xyaxis",
                title: "Ejercicios con RM",
                value: "\(stats.exercisesWithRM)",
                subtitle: "Con récords registrados",
                gradientColors: [Color.purple, Color.purple.opacity(0.8)]
            )
            
            StatsCard(
                icon: "calendar",
                title: "Este Mes",
                value: "\(stats.recordsThisMonth)",
                subtitle: "Nuevos registros",
                gradientColors: [Color.blue, Color.blue.opacity(0.8)]
            )
        }
    }
    
    private var columns: [GridItem] {
        [
            GridItem(.flexible(), spacing: 16),
            GridItem(.flexible(), spacing: 16)
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
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(.white)
                
                Text(title)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white.opacity(0.9))
                    .lineLimit(1)
                
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                
                Text(subtitle)
                    .font(.system(size: 10))
                    .foregroundColor(.white.opacity(0.75))
                    .lineLimit(2)
            }
        }
        .padding(16)
        .background(
            LinearGradient(
                colors: gradientColors,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
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
        .background(Color(.systemGroupedBackground))
    }
}

// MARK: - Responsive Layout Helper
extension StatsCardsView {
    // For different screen sizes, you might want different layouts
    static func adaptiveColumns(for geometry: GeometryProxy) -> [GridItem] {
        let width = geometry.size.width
        
        if width < 400 {
            // Small screens: 1 column
            return [GridItem(.flexible())]
        } else if width < 600 {
            // Medium screens: 2 columns
            return Array(repeating: GridItem(.flexible(), spacing: 16), count: 2)
        } else {
            // Large screens: 3 columns
            return Array(repeating: GridItem(.flexible(), spacing: 16), count: 3)
        }
    }
}

// MARK: - Usage Example with Adaptive Layout
struct AdaptiveStatsCardsView: View {
    let stats: RecordStats
    
    var body: some View {
        GeometryReader { geometry in
            LazyVGrid(columns: StatsCardsView.adaptiveColumns(for: geometry), spacing: 16) {
                StatsCard(
                    icon: "trophy.fill",
                    title: "Pesos Registrados",
                    value: "\(stats.totalRecords)",
                    subtitle: "Total de sets registrados",
                    gradientColors: [Color.green, Color.green.opacity(0.8)]
                )
                
                StatsCard(
                    icon: "chart.line.uptrend.xyaxis",
                    title: "Ejercicios con RM",
                    value: "\(stats.exercisesWithRM)",
                    subtitle: "Con récords registrados",
                    gradientColors: [Color.purple, Color.purple.opacity(0.8)]
                )
                
                StatsCard(
                    icon: "calendar",
                    title: "Este Mes",
                    value: "\(stats.recordsThisMonth)",
                    subtitle: "Nuevos registros",
                    gradientColors: [Color.blue, Color.blue.opacity(0.8)]
                )
            }
        }
    }
}
