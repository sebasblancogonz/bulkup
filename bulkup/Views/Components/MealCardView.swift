//
//  MealCardView.swift
//  bulkup
//
//  Created by sebastian.blanco on 17/8/25.
//


// MARK: - Componentes auxiliares
struct MealCardView: View {
    let meal: Meal
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header de la comida
            HStack {
                mealIcon
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(meal.type.capitalized.replacingOccurrences(of: "_", with: " "))
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    HStack(spacing: 16) {
                        Label(meal.time, systemImage: "clock")
                        
                        if let date = meal.date {
                            Label(formatDate(date), systemImage: "calendar")
                        }
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Text("\(meal.options.count) opciones")
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color(.systemGray5))
                    .cornerRadius(8)
            }
            
            // Notas de la comida
            if let notes = meal.notes {
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "lightbulb.fill")
                        .foregroundColor(.yellow)
                        .font(.caption)
                    
                    Text(notes)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(8)
                .background(Color.yellow.opacity(0.1))
                .cornerRadius(8)
            }
            
            // Opciones de la comida
            ForEach(meal.options.indices, id: \.self) { index in
                MealOptionView(option: meal.options[index], mealType: meal.type)
            }
            
            // Condiciones especiales
            if let conditions = meal.conditions {
                MealConditionsView(conditions: conditions, mealType: meal.type)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
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
            .font(.title2)
    }
    
    private func formatDate(_ dateString: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        if let date = formatter.date(from: dateString) {
            formatter.dateFormat = "dd MMM"
            formatter.locale = Locale(identifier: "es_ES")
            return formatter.string(from: date)
        }
        return dateString
    }
}