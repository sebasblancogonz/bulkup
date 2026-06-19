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

                            Text(translateMuscle(firstMuscle))
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
        case "beginner": return String(localized: "Básico")
        case "intermediate": return String(localized: "Medio")
        case "expert": return String(localized: "Avanzado")
        default: return level
        }
    }

    private func equipmentShortName(_ equipment: String) -> String {
        let translations: [String: String] = [
            "barbell": String(localized: "Barra"),
            "dumbbell": String(localized: "Mancuerna"),
            "body only": String(localized: "Corporal"),
            "machine": String(localized: "Máquina"),
            "cable": String(localized: "Cable"),
            "kettlebells": String(localized: "Pesa rusa"),
            "bands": String(localized: "Banda"),
            "medicine ball": String(localized: "Balón"),
            "exercise ball": String(localized: "Pelota"),
            "e-z curl bar": String(localized: "Barra Z"),
            "foam roll": String(localized: "Rodillo")
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

struct CompactTag: View {
    let text: String
    let color: Color

    var body: some View {
        Text(text)
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
