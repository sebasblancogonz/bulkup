struct MealOptionView: View {
    let option: MealOption
    let mealType: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(option.optionDescription)
                .font(.subheadline)
                .fontWeight(.medium)
            
            if !option.ingredients.isEmpty || !option.instructions.isEmpty {
                HStack(alignment: .top, spacing: 16) {
                    // Ingredientes
                    if !option.ingredients.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Label("Ingredientes", systemImage: "list.bullet")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                ForEach(option.ingredients.indices, id: \.self) { index in
                                    HStack(alignment: .top, spacing: 8) {
                                        Circle()
                                            .fill(Color.green)
                                            .frame(width: 6, height: 6)
                                        
                                        Text(option.ingredients[index])
                                            .font(.caption)
                                            .foregroundColor(.primary)
                                    }
                                }
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    
                    // Instrucciones
                    if !option.instructions.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Label("Preparación", systemImage: "arrow.right")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                ForEach(option.instructions.indices, id: \.self) { index in
                                    HStack(alignment: .top, spacing: 8) {
                                        Text("\(index + 1)")
                                            .font(.caption)
                                            .fontWeight(.bold)
                                            .foregroundColor(.white)
                                            .frame(width: 20, height: 20)
                                            .background(Color.blue)
                                            .clipShape(Circle())
                                        
                                        Text(option.instructions[index])
                                            .font(.caption)
                                            .foregroundColor(.primary)
                                    }
                                }
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }
        }
        .padding()
        .background(mealBackgroundColor.opacity(0.1))
        .cornerRadius(8)
    }
    
    private var mealBackgroundColor: Color {
        switch mealType.lowercased() {
        case let type where type.contains("desayuno") || type.contains("breakfast"):
            return .orange
        case let type where type.contains("almuerzo") || type.contains("comida") || type.contains("lunch"):
            return .yellow
        case let type where type.contains("merienda") || type.contains("snack"):
            return .purple
        case let type where type.contains("cena") || type.contains("dinner"):
            return .blue
        default:
            return .green
        }
    }
}