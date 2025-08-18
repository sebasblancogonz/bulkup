//
//  DayCardView.swift
//  bulkup
//
//  Created by sebastian.blanco on 17/8/25.
//

import SwiftUI
import SwiftData


// MARK: - Vista de tarjeta de día para dieta (CON ANIMACIONES SEGURAS)
struct DayCardView: View {
    let day: DietDay
    let dayIndex: Int
    let isExpanded: Bool
    let onToggleExpand: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // Header clickeable - SIEMPRE visible y fijo
            Button(action: onToggleExpand) {
                HStack {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 12, height: 12)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(day.day.capitalized.replacingOccurrences(of: "_", with: " "))
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                        
                        Text("Plan del día")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    HStack(spacing: 8) {
                        Text("\(day.meals.count) comidas")
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color(.systemGray5))
                            .cornerRadius(6)
                        
                        // ✅ Solo chevron simple, sin animación automática
                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
                .background(Color(.systemGray6))
            }
            .buttonStyle(PlainButtonStyle())
            
            // ✅ Contenido SIN if/else - siempre existe pero con height 0 cuando collapsed
            VStack(spacing: 16) {
                let sortedMeals = day.meals.sorted(by: { $0.orderIndex < $1.orderIndex })
                
                ForEach(0..<sortedMeals.count, id: \.self) { mealIndex in
                    if mealIndex < sortedMeals.count {
                        MealCardView(meal: sortedMeals[mealIndex])
                    }
                }
                
                if !day.supplements.isEmpty {
                    SupplementsView(supplements: day.supplements)
                }
            }
            .padding(isExpanded ? 16 : 0)
            .background(Color(.systemBackground))
            .frame(maxHeight: isExpanded ? .infinity : 0)
            .clipped()
            .opacity(isExpanded ? 1 : 0)
        }
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
}
