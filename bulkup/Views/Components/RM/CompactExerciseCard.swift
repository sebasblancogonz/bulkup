//
//  CompactExerciseCard.swift
//  bulkup
//
//  Created by sebastian.blanco on 10/9/25.
//

import SwiftUI

struct CompactExerciseCard: View {
    let exercise: RMExerciseFull
    @State private var showingDetail = false

    var body: some View {
        Button(action: {
            showingDetail = true
        }) {
            VStack(alignment: .leading, spacing: 10) {
                // Imagen miniatura o icono
                thumbnailView

                // Información básica
                VStack(alignment: .leading, spacing: 6) {
                    // Nombre del ejercicio
                    Text(exercise.nameEs)
                        .font(BulkUpFont.body())
                        .fontWeight(.semibold)
                        .foregroundColor(BulkUpColors.textPrimary)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)

                    // Músculo principal
                    if let primaryMuscles = exercise.primaryMuscles,
                       !primaryMuscles.isEmpty,
                       let firstMuscle = primaryMuscles.first {
                        HStack(spacing: 4) {
                            Image(systemName: "figure.strengthtraining.traditional")
                                .font(BulkUpFont.caption())
                                .foregroundColor(BulkUpColors.training)

                            Text(LocalizedStringKey(translateMuscle(firstMuscle)))
                                .font(BulkUpFont.caption())
                                .foregroundColor(BulkUpColors.textSecondary)
                                .lineLimit(1)
                        }
                    }

                    // Tags compactos
                    HStack(spacing: 4) {
                        // Nivel
                        if let level = exercise.level, !level.isEmpty {
                            CompactTag(
                                text: levelShortName(level),
                                color: levelColor(level)
                            )
                        }

                        // Equipo
                        if let equipment = exercise.equipment, !equipment.isEmpty {
                            CompactTag(
                                text: equipmentShortName(equipment),
                                color: BulkUpColors.secondary
                            )
                        }
                    }
                }

                Spacer(minLength: 0)
            }
            .padding(Spacing.md)
            .frame(maxWidth: .infinity, minHeight: 140)
            .background(BulkUpColors.surface)
            .cornerRadius(CornerRadius.large)
            .overlay(RoundedRectangle(cornerRadius: CornerRadius.medium).stroke(BulkUpColors.border, lineWidth: 0.5))
        }
        .buttonStyle(ScaleButtonStyle())
        .sheet(isPresented: $showingDetail) {
            RMExerciseDetailSheet(exercise: exercise)
        }
    }

    private var thumbnailView: some View {
        Group {
            if let images = exercise.images,
               !images.isEmpty,
               let firstImage = images.first,
               let url = URL(string: firstImage) {

                CachedAsyncImage(
                    url: url,
                    content: { image, colors in
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(height: 80)
                            .clipped()
                    },
                    placeholder: {
                        defaultThumbnail
                    }
                )
            } else {
                defaultThumbnail
            }
        }
    }

    private var defaultThumbnail: some View {
        ZStack {
            BulkUpColors.surfaceElevated

            Image(systemName: iconForCategory(exercise.category))
                .font(.system(size: 30))
                .foregroundColor(BulkUpColors.textSecondary)
        }
        .frame(height: 80)
        .frame(maxWidth: .infinity)
        .cornerRadius(CornerRadius.small)
    }

    // MARK: - Helper Functions

    private func iconForCategory(_ category: String?) -> String {
        guard let category = category else { return "figure.strengthtraining.traditional" }

        switch category.lowercased() {
        case "strength": return "figure.strengthtraining.traditional"
        case "stretching": return "figure.flexibility"
        case "cardio": return "figure.run"
        case "plyometrics": return "figure.jumprope"
        case "powerlifting": return "dumbbell.fill"
        default: return "figure.strengthtraining.traditional"
        }
    }

    private func levelShortName(_ level: String) -> String {
        switch level.lowercased() {
        case "beginner": return "Básico"
        case "intermediate": return "Medio"
        case "expert": return "Avanzado"
        default: return level
        }
    }

    private func equipmentShortName(_ equipment: String) -> String {
        let translations: [String: String] = [
            "barbell": "Barra",
            "dumbbell": "Mancuerna",
            "body only": "Corporal",
            "machine": "Máquina",
            "cable": "Cable",
            "kettlebells": "Pesa rusa",
            "bands": "Banda",
            "medicine ball": "Balón",
            "exercise ball": "Pelota",
            "e-z curl bar": "Barra Z",
            "foam roll": "Rodillo"
        ]
        return translations[equipment.lowercased()] ?? equipment
    }

    private func levelColor(_ level: String) -> Color {
        switch level.lowercased() {
        case "beginner": return BulkUpColors.success
        case "intermediate": return BulkUpColors.warning
        case "expert": return BulkUpColors.error
        default: return BulkUpColors.textTertiary
        }
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

struct CompactTag: View {
    let text: String
    let color: Color

    var body: some View {
        Text(LocalizedStringKey(text))
            .font(BulkUpFont.dataLabel())
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(color.opacity(0.15))
            .foregroundColor(color)
            .cornerRadius(4)
    }
}

struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}
