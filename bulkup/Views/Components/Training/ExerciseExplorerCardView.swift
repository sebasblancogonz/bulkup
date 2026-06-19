//
//  ExerciseCardView 2.swift
//  bulkup
//
//  Created by sebastianblancogonz on 20/8/25.
//
import SwiftUI

struct ExerciseExplorerCardView: View {
    let exercise: RMExerciseFull

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            // Nombre del ejercicio
            Text(exercise.nameEs)
                .font(BulkUpFont.cardTitle())
                .foregroundColor(BulkUpColors.textPrimary)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)

            // Tags
            FlowLayout(spacing: Spacing.xs) {
                if let category = exercise.category {
                    TagView(text: translateCategory(category), color: BulkUpColors.textTertiary)
                }

                if let level = exercise.level {
                    TagView(text: "Nivel: \(translateLevel(level))", color: BulkUpColors.training)
                }

                if let force = exercise.force {
                    TagView(text: "Fuerza: \(translateForce(force))", color: BulkUpColors.success)
                }

                if let mechanic = exercise.mechanic {
                    TagView(text: "Mecánica: \(translateMechanic(mechanic))", color: BulkUpColors.warning)
                }

                if let equipment = exercise.equipment {
                    TagView(text: "Equipo: \(translateEquipment(equipment))", color: BulkUpColors.secondary)
                }
            }

            // Músculos principales
            if let primaryMuscles = exercise.primaryMuscles, !primaryMuscles.isEmpty {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Músculos principales:")
                        .font(BulkUpFont.dataLabel())
                        .foregroundColor(BulkUpColors.textSecondary)

                    Text(primaryMuscles.map { translateMuscle($0) }.joined(separator: ", "))
                        .font(BulkUpFont.caption())
                        .foregroundColor(BulkUpColors.textPrimary)
                }
            }

            // Músculos secundarios
            if let secondaryMuscles = exercise.secondaryMuscles, !secondaryMuscles.isEmpty {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Músculos secundarios:")
                        .font(BulkUpFont.dataLabel())
                        .foregroundColor(BulkUpColors.textSecondary)

                    Text(secondaryMuscles.map { translateMuscle($0) }.joined(separator: ", "))
                        .font(BulkUpFont.caption())
                        .foregroundColor(BulkUpColors.textPrimary)
                }
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Spacing.lg)
        .background(BulkUpColors.surface)
        .cornerRadius(CornerRadius.medium)
        .overlay(RoundedRectangle(cornerRadius: CornerRadius.medium).stroke(BulkUpColors.border, lineWidth: 0.5))
    }

    // Funciones de traducción
    private func translateCategory(_ category: String) -> String {
        let translations: [String: String] = [
            "strength": "Fuerza",
            "stretching": "Estiramiento",
            "plyometrics": "Pliometría",
            "strongman": "Strongman",
            "powerlifting": "Powerlifting",
            "cardio": "Cardio",
            "olympic weightlifting": "Halterofilia"
        ]
        return translations[category.lowercased()] ?? category.capitalized
    }

    private func translateLevel(_ level: String) -> String {
        let translations: [String: String] = [
            "beginner": "Principiante",
            "intermediate": "Intermedio",
            "expert": "Experto"
        ]
        return translations[level.lowercased()] ?? level.capitalized
    }

    private func translateForce(_ force: String) -> String {
        let translations: [String: String] = [
            "push": "Empuje",
            "pull": "Jalón",
            "static": "Estático"
        ]
        return translations[force.lowercased()] ?? force.capitalized
    }

    private func translateMechanic(_ mechanic: String) -> String {
        let translations: [String: String] = [
            "compound": "Compuesto",
            "isolation": "Aislamiento"
        ]
        return translations[mechanic.lowercased()] ?? mechanic.capitalized
    }

    private func translateEquipment(_ equipment: String) -> String {
        let translations: [String: String] = [
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
        return translations[equipment.lowercased()] ?? equipment.capitalized
    }

    private func translateMuscle(_ muscle: String) -> String {
        let translations: [String: String] = [
            "chest": "Pecho",
            "shoulders": "Hombros",
            "triceps": "Tríceps",
            "biceps": "Bíceps",
            "forearms": "Antebrazos",
            "abdominals": "Abdominales",
            "quadriceps": "Cuádriceps",
            "hamstrings": "Isquiotibiales",
            "calves": "Pantorrillas",
            "glutes": "Glúteos",
            "lower back": "Espalda baja",
            "middle back": "Espalda media",
            "lats": "Dorsales",
            "traps": "Trapecios",
            "neck": "Cuello",
            "adductors": "Aductores",
            "abductors": "Abductores"
        ]
        return translations[muscle.lowercased()] ?? muscle.capitalized
    }
}
