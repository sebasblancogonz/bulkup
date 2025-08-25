//
//  SimpleDayCardView.swift
//  bulkup
//
//  Created by sebastianblancogonz on 18/8/25.
//
import SwiftData
import SwiftUI

// MARK: - Vista de tarjeta de día SIMPLIFICADA para evitar bloqueos
struct SimpleDayCardView: View {
    let day: DietDay
    let dayIndex: Int
    let isExpanded: Bool
    let onToggleExpand: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // Header clickeable MÁS SIMPLE
            Button(action: onToggleExpand) {
                HStack {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 10, height: 10)
                    
                    Text(day.day.capitalized.replacingOccurrences(of: "_", with: " "))
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Text("\(day.meals.count) comidas")
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color(.systemGray5))
                        .cornerRadius(6)
                    
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .foregroundColor(.secondary)
                        .font(.caption)
                }
                .padding()
                .background(Color(.systemGray6))
            }
            .buttonStyle(PlainButtonStyle())
            
            // Contenido SIN ANIMACIONES COMPLEJAS
            if isExpanded {
                VStack(spacing: 12) {
                    // ✅ Limitar el número de comidas mostradas para evitar sobrecarga
                    let sortedMeals = day.meals.sorted(by: { $0.orderIndex < $1.orderIndex })
                    let mealsToShow = Array(sortedMeals.prefix(10)) // Máximo 10 comidas
                    
                    ForEach(mealsToShow, id: \.id) { meal in
                        CompactMealView(meal: meal)
                    }
                    
                    if sortedMeals.count > 10 {
                        Text("... y \(sortedMeals.count - 10) comidas más")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding()
                    }
                }
                .padding()
                .background(Color(.systemBackground))
            }
        }
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
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
                Text(meal.type.capitalized.replacingOccurrences(of: "_", with: " "))
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                if !meal.time.isEmpty {
                    Text(meal.time)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            Text("\(meal.options.count) opciones")
                .font(.caption2)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(Color(.systemGray5))
                .cornerRadius(4)
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 8)
        .background(Color(.systemGray6).opacity(0.5))
        .cornerRadius(8)
    }
    
    private var mealIcon: some View {
        let iconName: String
        let iconColor: Color
        
        switch meal.type.lowercased() {
        case let type where type.contains("desayuno") || type.contains("breakfast"):
            iconName = "cup.and.saucer.fill"
            iconColor = .orange
        case let type where type.contains("almuerzo") || type.contains("comida") || type.contains("lunch"):
            iconName = "sun.max.fill"
            iconColor = .yellow
        case let type where type.contains("merienda") || type.contains("snack"):
            iconName = "sunset.fill"
            iconColor = .purple
        case let type where type.contains("cena") || type.contains("dinner"):
            iconName = "moon.fill"
            iconColor = .blue
        default:
            iconName = "fork.knife"
            iconColor = .green
        }
        
        return Image(systemName: iconName)
            .foregroundColor(iconColor)
            .font(.caption)
    }
}
