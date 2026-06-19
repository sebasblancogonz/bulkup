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
                    TagView(text: String(localized: "Nivel: \(translateLevel(level))"), color: BulkUpColors.training)
                }

                if let force = exercise.force {
                    TagView(text: String(localized: "Fuerza: \(translateForce(force))"), color: BulkUpColors.success)
                }

                if let mechanic = exercise.mechanic {
                    TagView(text: String(localized: "Mecánica: \(translateMechanic(mechanic))"), color: BulkUpColors.warning)
                }

                if let equipment = exercise.equipment {
                    TagView(text: String(localized: "Equipo: \(translateEquipment(equipment))"), color: BulkUpColors.secondary)
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
            "strength": String(localized: "Fuerza"),
            "stretching": String(localized: "Estiramiento"),
            "plyometrics": String(localized: "Pliometría"),
            "strongman": String(localized: "Strongman"),
            "powerlifting": String(localized: "Powerlifting"),
            "cardio": String(localized: "Cardio"),
            "olympic weightlifting": String(localized: "Halterofilia")
        ]
        return translations[category.lowercased()] ?? category.capitalized
    }

    private func translateLevel(_ level: String) -> String {
        let translations: [String: String] = [
            "beginner": String(localized: "Principiante"),
            "intermediate": String(localized: "Intermedio"),
            "expert": String(localized: "Experto")
        ]
        return translations[level.lowercased()] ?? level.capitalized
    }

    private func translateForce(_ force: String) -> String {
        let translations: [String: String] = [
            "push": String(localized: "Empuje"),
            "pull": String(localized: "Jalón"),
            "static": String(localized: "Estático")
        ]
        return translations[force.lowercased()] ?? force.capitalized
    }

    private func translateMechanic(_ mechanic: String) -> String {
        let translations: [String: String] = [
            "compound": String(localized: "Compuesto"),
            "isolation": String(localized: "Aislamiento")
        ]
        return translations[mechanic.lowercased()] ?? mechanic.capitalized
    }

    private func translateEquipment(_ equipment: String) -> String {
        let translations: [String: String] = [
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
        return translations[equipment.lowercased()] ?? equipment.capitalized
    }

    private func translateMuscle(_ muscle: String) -> String {
        let translations: [String: String] = [
            "chest": String(localized: "Pecho"),
            "shoulders": String(localized: "Hombros"),
            "triceps": String(localized: "Tríceps"),
            "biceps": String(localized: "Bíceps"),
            "forearms": String(localized: "Antebrazos"),
            "abdominals": String(localized: "Abdominales"),
            "quadriceps": String(localized: "Cuádriceps"),
            "hamstrings": String(localized: "Isquiotibiales"),
            "calves": String(localized: "Pantorrillas"),
            "glutes": String(localized: "Glúteos"),
            "lower back": String(localized: "Espalda baja"),
            "middle back": String(localized: "Espalda media"),
            "lats": String(localized: "Dorsales"),
            "traps": String(localized: "Trapecios"),
            "neck": String(localized: "Cuello"),
            "adductors": String(localized: "Aductores"),
            "abductors": String(localized: "Abductores")
        ]
        return translations[muscle.lowercased()] ?? muscle.capitalized
    }
}
