//
//  ExerciseDetailSheet.swift
//  bulkup
//
//  Created by sebastian.blanco on 10/9/25.
//

import SwiftUI

struct RMExerciseDetailSheet: View {
    let exercise: RMExerciseFull
    @Environment(\.dismiss) var dismiss
    @State private var selectedImageIndex = 0
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Imágenes del ejercicio
                    if let images = exercise.images, !images.isEmpty {
                        imageCarousel(images: images)
                    } else {
                        placeholderImage
                    }
                    
                    VStack(alignment: .leading, spacing: 16) {
                        // Nombre y categoría
                        VStack(alignment: .leading, spacing: 8) {
                            Text(exercise.nameEs)
                                .font(.largeTitle)
                                .fontWeight(.bold)
                        }
                        
                        // Tags principales
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                if let category = exercise.category {
                                    TagView(
                                        text: translateCategory(category),
                                        color: .blue,
                                        icon: "tag.fill"
                                    )
                                }
                                
                                if let equipment = exercise.equipment {
                                    TagView(
                                        text: translateEquipment(equipment),
                                        color: .purple,
                                        icon: "dumbbell.fill"
                                    )
                                }
                                
                                if let level = exercise.level {
                                    TagView(
                                        text: translateLevel(level),
                                        color: levelColor(level),
                                        icon: "chart.bar.fill"
                                    )
                                }
                            }
                        }
                        
                        Divider()
                        
                        // Información de músculos
                        musclesSection
                        
                        Divider()
                        
                        // Detalles técnicos
                        technicalDetailsSection
                        
                        // Instrucciones si están disponibles
                        if let instructions = exercise.instructionsEs, !instructions.isEmpty {
                            Divider()
                            instructionsSection(instructions)
                        }
                    }
                    .padding(.horizontal)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cerrar") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    // MARK: - Components
    
    private func imageCarousel(images: [String]) -> some View {
        TabView(selection: $selectedImageIndex) {
            ForEach(Array(images.enumerated()), id: \.offset) { index, imageUrl in
                AsyncImage(url: URL(string: imageUrl)) { phase in
                    switch phase {
                    case .empty:
                        ProgressView()
                            .frame(height: 300)
                            .frame(maxWidth: .infinity)
                            .background(Color(.systemGray6))
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(height: 300)
                            .frame(maxWidth: .infinity)
                    case .failure(_):
                        Image(systemName: "photo")
                            .font(.system(size: 50))
                            .foregroundColor(.secondary)
                            .frame(height: 300)
                            .frame(maxWidth: .infinity)
                            .background(Color(.systemGray6))
                    @unknown default:
                        EmptyView()
                    }
                }
                .tag(index)
            }
        }
        .tabViewStyle(PageTabViewStyle())
        .frame(height: 300)
        .background(Color(.systemGray6))
    }
    
    private var placeholderImage: some View {
        ZStack {
            Color(.systemGray6)
            
            VStack(spacing: 12) {
                Image(systemName: "figure.strengthtraining.traditional")
                    .font(.system(size: 60))
                    .foregroundColor(.secondary)
                
                Text("Sin imágenes disponibles")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .frame(height: 200)
    }
    
    private var musclesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Músculos trabajados")
                .font(.headline)
            
            // Músculos principales
            if let primaryMuscles = exercise.primaryMuscles, !primaryMuscles.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Label("Principales", systemImage: "figure.strengthtraining.traditional")
                        .font(.subheadline)
                        .foregroundColor(.primary)
                    
                    FlowLayout(spacing: 6) {
                        ForEach(primaryMuscles, id: \.self) { muscle in
                            MuscleChip(
                                name: translateMuscle(muscle),
                                isPrimary: true
                            )
                        }
                    }
                }
            }
            
            // Músculos secundarios
            if let secondaryMuscles = exercise.secondaryMuscles, !secondaryMuscles.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Label("Secundarios", systemImage: "figure.walk")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    FlowLayout(spacing: 6) {
                        ForEach(secondaryMuscles, id: \.self) { muscle in
                            MuscleChip(
                                name: translateMuscle(muscle),
                                isPrimary: false
                            )
                        }
                    }
                }
            }
        }
    }
    
    private var technicalDetailsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Detalles técnicos")
                .font(.headline)
            
            VStack(spacing: 8) {
                if let force = exercise.force, !force.isEmpty {
                    DetailRow(
                        icon: "arrow.up.arrow.down",
                        title: "Tipo de fuerza",
                        value: translateForce(force)
                    )
                }
                
                if let mechanic = exercise.mechanic, !mechanic.isEmpty {
                    DetailRow(
                        icon: "gearshape.2",
                        title: "Mecánica",
                        value: translateMechanic(mechanic)
                    )
                }
                
                if let equipment = exercise.equipment, !equipment.isEmpty {
                    DetailRow(
                        icon: "dumbbell",
                        title: "Equipo necesario",
                        value: translateEquipment(equipment)
                    )
                }
                
                if let level = exercise.level, !level.isEmpty  {
                    DetailRow(
                        icon: "chart.bar",
                        title: "Nivel de dificultad",
                        value: translateLevel(level)
                    )
                }
            }
        }
    }
    
    private func instructionsSection(_ instructions: [String]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Instrucciones")
                .font(.headline)
            
            VStack(alignment: .leading, spacing: 8) {
                ForEach(Array(instructions.enumerated()), id: \.offset) { index, instruction in
                    HStack(alignment: .top, spacing: 12) {
                        Text("\(index + 1)")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .frame(width: 24, height: 24)
                            .background(Color.blue)
                            .clipShape(Circle())
                        
                        Text(instruction)
                            .font(.body)
                            .fixedSize(horizontal: false, vertical: true)
                        
                        Spacer(minLength: 0)
                    }
                }
            }
        }
    }
    
    // MARK: - Helper Functions
    
    private func levelColor(_ level: String) -> Color {
        switch level.lowercased() {
        case "beginner": return .green
        case "intermediate": return .orange
        case "expert": return .red
        default: return .gray
        }
    }
    
    // MARK: - Translation Functions
    
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
            "foam roll": "Rodillo de espuma",
            "other": "Otro"
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

// MARK: - Supporting Views

struct DetailRow: View {
    let icon: String
    let title: String
    let value: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(.blue)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(value)
                    .font(.body)
                    .fontWeight(.medium)
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
}

struct MuscleChip: View {
    let name: String
    let isPrimary: Bool
    
    var body: some View {
        Text(name)
            .font(.caption)
            .fontWeight(isPrimary ? .semibold : .regular)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(isPrimary ? Color.blue.opacity(0.2) : Color.gray.opacity(0.1))
            .foregroundColor(isPrimary ? .blue : .primary)
            .cornerRadius(12)
    }
}
