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
        VStack(alignment: .leading, spacing: 8) {
            // Nombre del ejercicio
            Text(exercise.name)
                .font(.headline)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
            
            // Tags
            FlowLayout(spacing: 4) {
                if let category = exercise.category {
                    TagView(text: translateCategory(category), color: .gray)
                }
                
                if let level = exercise.level {
                    TagView(text: "Nivel: \(translateLevel(level))", color: .blue)
                }
                
                if let force = exercise.force {
                    TagView(text: "Fuerza: \(translateForce(force))", color: .green)
                }
                
                if let mechanic = exercise.mechanic {
                    TagView(text: "Mecánica: \(translateMechanic(mechanic))", color: .yellow)
                }
                
                if let equipment = exercise.equipment {
                    TagView(text: "Equipo: \(translateEquipment(equipment))", color: .purple)
                }
            }
            
            // Músculos principales
            if let primaryMuscles = exercise.primaryMuscles, !primaryMuscles.isEmpty {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Músculos principales:")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                    
                    Text(primaryMuscles.map { translateMuscle($0) }.joined(separator: ", "))
                        .font(.caption)
                        .foregroundColor(.primary)
                }
            }
            
            // Músculos secundarios
            if let secondaryMuscles = exercise.secondaryMuscles, !secondaryMuscles.isEmpty {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Músculos secundarios:")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                    
                    Text(secondaryMuscles.map { translateMuscle($0) }.joined(separator: ", "))
                        .font(.caption)
                        .foregroundColor(.primary)
                }
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
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
