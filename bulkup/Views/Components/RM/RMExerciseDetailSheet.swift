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
                VStack(alignment: .leading, spacing: Spacing.lg) {
                    // Imágenes del ejercicio
                    if let images = exercise.images, !images.isEmpty {
                        imageCarousel(images: images)
                    } else {
                        placeholderImage
                    }

                    VStack(alignment: .leading, spacing: Spacing.lg) {
                        // Nombre y categoría
                        VStack(alignment: .leading, spacing: Spacing.sm) {
                            Text(exercise.localizedName)
                                .font(BulkUpFont.screenTitle())
                                .fontWeight(.bold)
                                .foregroundColor(BulkUpColors.textPrimary)
                        }

                        // Tags principales
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: Spacing.sm) {
                                if let category = exercise.localizedCategory {
                                    TagView(
                                        text: category,
                                        color: BulkUpColors.training,
                                        icon: "tag.fill"
                                    )
                                }

                                if let equipment = exercise.localizedEquipment {
                                    TagView(
                                        text: equipment,
                                        color: BulkUpColors.secondary,
                                        icon: "dumbbell.fill"
                                    )
                                }

                                if let level = exercise.localizedLevel {
                                    TagView(
                                        text: level,
                                        color: levelColor(exercise.level ?? ""),
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
                        if !exercise.localizedInstructions.isEmpty {
                            Divider()
                            instructionsSection(exercise.localizedInstructions)
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
            if !exercise.localizedPrimaryMuscles.isEmpty {
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    Label("Principales", systemImage: "figure.strengthtraining.traditional")
                        .font(BulkUpFont.body())
                        .foregroundColor(BulkUpColors.textPrimary)

                    FlowLayout(spacing: 6) {
                        ForEach(exercise.localizedPrimaryMuscles, id: \.self) { muscle in
                            MuscleChip(name: muscle, isPrimary: true)
                        }
                    }
                }
            }

            // Músculos secundarios
            if !exercise.localizedSecondaryMuscles.isEmpty {
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    Label("Secundarios", systemImage: "figure.walk")
                        .font(BulkUpFont.body())
                        .foregroundColor(BulkUpColors.textSecondary)

                    FlowLayout(spacing: 6) {
                        ForEach(exercise.localizedSecondaryMuscles, id: \.self) { muscle in
                            MuscleChip(name: muscle, isPrimary: false)
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
                if let force = exercise.localizedForce {
                    DetailRow(icon: "arrow.up.arrow.down", title: "Tipo de fuerza", value: force)
                }

                if let mechanic = exercise.localizedMechanic {
                    DetailRow(icon: "gearshape.2", title: "Mecánica", value: mechanic)
                }

                if let equipment = exercise.localizedEquipment {
                    DetailRow(icon: "dumbbell", title: "Equipo necesario", value: equipment)
                }

                if let level = exercise.localizedLevel {
                    DetailRow(icon: "chart.bar", title: "Nivel de dificultad", value: level)
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
                            .foregroundColor(Color.onFill(BulkUpColors.training))
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

                Text(LocalizedStringKey(value))
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
        Text(LocalizedStringKey(name))
            .font(BulkUpFont.caption())
            .fontWeight(isPrimary ? .semibold : .regular)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(isPrimary ? BulkUpColors.training.opacity(0.2) : BulkUpColors.surfaceElevated)
            .foregroundColor(isPrimary ? BulkUpColors.training : BulkUpColors.textPrimary)
            .cornerRadius(CornerRadius.medium)
    }
}
