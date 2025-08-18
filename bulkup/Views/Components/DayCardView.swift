//
//  DayCardView.swift
//  bulkup
//
//  Created by sebastian.blanco on 17/8/25.
//

import SwiftUI
import SwiftData


struct DayCardView: View {
    let day: DietDay
    let dayIndex: Int
    let isExpanded: Bool
    let onToggleExpand: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            Button(action: onToggleExpand) {
                HStack {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 12, height: 12)
                    
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
                    
                    Image(systemName: "chevron.down")
                        .foregroundColor(.secondary)
                        .rotationEffect(.degrees(isExpanded ? 180 : 0))
                        .animation(.easeInOut(duration: 0.2), value: isExpanded)
                }
                .padding()
                .background(Color(.systemGray6))
            }
            .buttonStyle(PlainButtonStyle())
            
            // Content
            if isExpanded {
                VStack(spacing: 16) {
                    ForEach(day.meals.indices, id: \.self) { index in
                        MealCardView(meal: day.meals[index])
                    }
                    
                    if !day.supplements.isEmpty {
                        SupplementsView(supplements: day.supplements)
                    }
                }
                .padding()
                .background(Color(.systemBackground))
            }
        }
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
}