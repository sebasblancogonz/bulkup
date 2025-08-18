//
//  ConditionCardView.swift
//  bulkup
//
//  Created by sebastian.blanco on 17/8/25.
//

import SwiftUI
import SwiftData


struct ConditionCardView: View {
    let condition: ConditionalMeal
    let title: String
    let color: Color
    let icon: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(color)
                
                Spacer()
            }
            
            Text(condition.mealDescription)
                .font(.caption)
                .foregroundColor(.primary)
            
            if !condition.ingredients.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(condition.ingredients.indices, id: \.self) { index in
                        HStack(alignment: .top, spacing: 8) {
                            Circle()
                                .fill(color)
                                .frame(width: 6, height: 6)
                            
                            Text(condition.ingredients[index])
                                .font(.caption)
                                .foregroundColor(.primary)
                        }
                    }
                }
            }
        }
        .padding()
        .background(color.opacity(0.1))
        .cornerRadius(8)
    }
}