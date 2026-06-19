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
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Imágenes del ejercicio
                    if let images = exercise.images, !images.isEmpty {
                        imageCarousel(images: images)
                    } else {
                        placeholderImage
                    }

                    VStack(alignment: .leading, spacing: Spacing.lg) {
                        // Nombre y categoría
                        VStack(alignment: .leading, spacing: Spacing.sm) {
                            Text(exercise.nameEs)
                                .font(BulkUpFont.screenTitle())
                                .fontWeight(.bold)
                                .foregroundColor(BulkUpColors.textPrimary)
                        }

                        // Tags principales
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: Spacing.sm) {
                                if let category = exercise.category {
                                    TagView(
                                        text: translateCategory(category),
                                        color: BulkUpColors.training,
                                        icon: "tag.fill"
                                    )
                                }

                                if let equipment = exercise.equipment {
                                    TagView(
                                        text: translateEquipment(equipment),
                                        color: BulkUpColors.secondary,
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
            .background(BulkUpColors.background.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cerrar") {
                        dismiss()
                    }
                    .foregroundColor(BulkUpColors.accent)
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
                            .background(BulkUpColors.surfaceElevated)
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(height: 300)
                            .frame(maxWidth: .infinity)
                    case .failure(_):
                        Image(systemName: "photo")
                            .font(.system(size: 50))
                            .foregroundColor(BulkUpColors.textSecondary)
                            .frame(height: 300)
                            .frame(maxWidth: .infinity)
                            .background(BulkUpColors.surfaceElevated)
                    @unknown default:
                        EmptyView()
                    }
                }
                .tag(index)
            }
        }
        .tabViewStyle(PageTabViewStyle())
        .frame(height: 300)
        .background(BulkUpColors.surfaceElevated)
    }

    private var placeholderImage: some View {
        ZStack {
            BulkUpColors.surfaceElevated

            VStack(spacing: Spacing.md) {
                Image(systemName: "figure.strengthtraining.traditional")
                    .font(.system(size: 60))
                    .foregroundColor(BulkUpColors.textSecondary)

                Text("Sin imágenes disponibles")
                    .font(BulkUpFont.caption())
                    .foregroundColor(BulkUpColors.textSecondary)
            }
        }
        .frame(height: 200)
    }

    private var musclesSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Músculos trabajados")
                .sectionHeader()

            // Músculos principales
            if let primaryMuscles = exercise.primaryMuscles, !primaryMuscles.isEmpty {
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    Label("Principales", systemImage: "figure.strengthtraining.traditional")
                        .font(BulkUpFont.body())
                        .foregroundColor(BulkUpColors.textPrimary)

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
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    Label("Secundarios", systemImage: "figure.walk")
                        .font(BulkUpFont.body())
                        .foregroundColor(BulkUpColors.textSecondary)

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
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Detalles técnicos")
                .sectionHeader()

            VStack(spacing: Spacing.sm) {
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
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Instrucciones")
                .sectionHeader()

            VStack(alignment: .leading, spacing: Spacing.sm) {
                ForEach(Array(instructions.enumerated()), id: \.offset) { index, instruction in
                    HStack(alignment: .top, spacing: Spacing.md) {
                        Text("\(index + 1)")
                            .font(BulkUpFont.caption())
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .frame(width: 24, height: 24)
                            .background(BulkUpColors.training)
                            .clipShape(Circle())

                        Text(instruction)
                            .font(BulkUpFont.body())
                            .foregroundColor(BulkUpColors.textPrimary)
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
        case "beginner": return BulkUpColors.success
        case "intermediate": return BulkUpColors.warning
        case "expert": return BulkUpColors.error
        default: return BulkUpColors.textTertiary
        }
    }

    // MARK: - Translation Functions

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
            "foam roll": String(localized: "Rodillo de espuma"),
            "other": String(localized: "Otro")
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

// MARK: - Supporting Views

struct DetailRow: View {
    let icon: String
    let title: String
    let value: String

    var body: some View {
        HStack(spacing: Spacing.md) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(BulkUpColors.accent)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(LocalizedStringKey(title))
                    .font(BulkUpFont.caption())
                    .foregroundColor(BulkUpColors.textSecondary)

                Text(value)
                    .font(BulkUpFont.body())
                    .foregroundColor(BulkUpColors.textPrimary)
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
            .font(BulkUpFont.caption())
            .fontWeight(isPrimary ? .semibold : .regular)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(isPrimary ? BulkUpColors.training.opacity(0.2) : BulkUpColors.surfaceElevated)
            .foregroundColor(isPrimary ? BulkUpColors.training : BulkUpColors.textPrimary)
            .cornerRadius(CornerRadius.medium)
    }
}
