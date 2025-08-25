//
//  FilterSection.swift
//  bulkup
//
//  Created by sebastianblancogonz on 20/8/25.
//
import SwiftUI

struct FilterSection: View {
    let title: String
    let options: [String]
    let selected: Set<String>
    let onSelectionChange: (Set<String>) -> Void
    
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button(action: { isExpanded.toggle() }) {
                HStack {
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    
                    if !selected.isEmpty {
                        Text("(\(selected.count))")
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                    
                    Spacer()
                    
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption)
                }
            }
            .foregroundColor(.primary)
            
            if isExpanded {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(options, id: \.self) { option in
                        Button(action: {
                            var newSelection = selected
                            if newSelection.contains(option) {
                                newSelection.remove(option)
                            } else {
                                newSelection.insert(option)
                            }
                            onSelectionChange(newSelection)
                        }) {
                            HStack {
                                Image(systemName: selected.contains(option) ? "checkmark.square.fill" : "square")
                                    .foregroundColor(selected.contains(option) ? .blue : .secondary)
                                
                                Text(translateOption(option))
                                    .font(.caption)
                                
                                Spacer()
                            }
                        }
                        .foregroundColor(.primary)
                    }
                    
                    if !selected.isEmpty {
                        Button(action: { onSelectionChange([]) }) {
                            Text("Limpiar")
                                .font(.caption)
                                .foregroundColor(.blue)
                        }
                        .padding(.top, 4)
                    }
                }
                .padding(.leading, 4)
            }
        }
    }
    
    private func translateOption(_ option: String) -> String {
        // Aquí puedes agregar traducciones según necesites
        let translations: [String: String] = [
            // Categorías
            "strength": "Fuerza",
            "stretching": "Estiramiento",
            "plyometrics": "Pliometría",
            "strongman": "Strongman",
            "powerlifting": "Powerlifting",
            "cardio": "Cardio",
            "olympic weightlifting": "Halterofilia",
            
            // Niveles
            "beginner": "Principiante",
            "intermediate": "Intermedio",
            "expert": "Experto",
            
            // Fuerza
            "push": "Empuje",
            "pull": "Jalón",
            "static": "Estático",
            
            // Mecánica
            "compound": "Compuesto",
            "isolation": "Aislamiento",
            
            // Equipo
            "barbell": "Barra",
            "dumbbell": "Mancuerna",
            "body only": "Peso corporal",
            "machine": "Máquina",
            "cable": "Cable",
            "kettlebells": "Pesas rusas",
            "bands": "Bandas",
            "medicine ball": "Balón medicinal",
            "exercise ball": "Pelota de ejercicio",
            "e-z curl bar": "Barra Z",
            "foam roll": "Rodillo de espuma"
        ]
        
        return translations[option.lowercased()] ?? option.capitalized
    }
}
