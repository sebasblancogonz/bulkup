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
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Button(action: { isExpanded.toggle() }) {
                HStack {
                    Text(LocalizedStringKey(title))
                        .font(BulkUpFont.body())
                        .fontWeight(.semibold)
                        .foregroundColor(BulkUpColors.textPrimary)

                    if !selected.isEmpty {
                        Text("(\(selected.count))")
                            .font(BulkUpFont.caption())
                            .foregroundColor(BulkUpColors.training)
                    }

                    Spacer()

                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(BulkUpFont.caption())
                        .foregroundColor(BulkUpColors.textSecondary)
                }
                .contentShape(Rectangle())
            }
            .foregroundColor(BulkUpColors.textPrimary)

            if isExpanded {
                VStack(alignment: .leading, spacing: Spacing.xs) {
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
                                    .foregroundColor(selected.contains(option) ? BulkUpColors.training : BulkUpColors.textSecondary)

                                Text(translateOption(option))
                                    .font(BulkUpFont.caption())
                                    .foregroundColor(BulkUpColors.textPrimary)

                                Spacer()
                            }
                            .contentShape(Rectangle())
                        }
                        .foregroundColor(BulkUpColors.textPrimary)
                    }

                    if !selected.isEmpty {
                        Button(action: { onSelectionChange([]) }) {
                            Text("Limpiar")
                                .font(BulkUpFont.caption())
                                .foregroundColor(BulkUpColors.training)
                        }
                        .padding(.top, Spacing.xs)
                    }
                }
                .padding(.leading, Spacing.xs)
            }
        }
    }

    private func translateOption(_ option: String) -> String {
        // Aquí puedes agregar traducciones según necesites
        let translations: [String: String] = [
            // Categorías
            "strength": String(localized: "Fuerza"),
            "stretching": String(localized: "Estiramiento"),
            "plyometrics": String(localized: "Pliometría"),
            "strongman": String(localized: "Strongman"),
            "powerlifting": String(localized: "Powerlifting"),
            "cardio": String(localized: "Cardio"),
            "olympic weightlifting": String(localized: "Halterofilia"),

            // Niveles
            "beginner": String(localized: "Principiante"),
            "intermediate": String(localized: "Intermedio"),
            "expert": String(localized: "Experto"),

            // Fuerza
            "push": String(localized: "Empuje"),
            "pull": String(localized: "Jalón"),
            "static": String(localized: "Estático"),

            // Mecánica
            "compound": String(localized: "Compuesto"),
            "isolation": String(localized: "Aislamiento"),

            // Equipo
            "barbell": String(localized: "Barra"),
            "dumbbell": String(localized: "Mancuerna"),
            "body only": String(localized: "Peso corporal"),
            "machine": String(localized: "Máquina"),
            "cable": String(localized: "Cable"),
            "kettlebells": String(localized: "Pesas rusas"),
            "bands": String(localized: "Bandas"),
            "medicine ball": String(localized: "Balón medicinal"),
            "exercise ball": String(localized: "Pelota de ejercicio"),
            "e-z curl bar": String(localized: "Barra Z"),
            "foam roll": String(localized: "Rodillo de espuma")
        ]

        return translations[option.lowercased()] ?? option.capitalized
    }
}
