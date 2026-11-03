//
//  RMExerciseDetailSheet.swift
//  bulkup
//
//  One exercise from the library: its images on a raised slab, the name in
//  the title voice, the meta line, muscles and details as slab rows, the
//  instructions as a numbered list. Opened from the explorer's rows.
//

import SwiftUI

struct RMExerciseDetailSheet: View {
    let exercise: RMExerciseFull
    @Environment(\.dismiss) private var dismiss
    @State private var selectedImageIndex = 0

    private var meta: String {
        [exercise.localizedCategory, exercise.localizedEquipment, exercise.localizedLevel]
            .compactMap { $0 }
            .joined(separator: " · ")
    }

    var body: some View {
        ZStack {
            BulkUpGround()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: Spacing.lg) {
                    header
                    imageSlab
                    musclesSlab
                    detailsSlab
                    if !exercise.localizedInstructions.isEmpty {
                        instructions(exercise.localizedInstructions)
                    }
                }
                .padding(.horizontal, Spacing.screenH)
                .padding(.top, Spacing.lg)
                .padding(.bottom, Spacing.xxl)
            }
        }
        .presentationDragIndicator(.visible)
        .presentationBackground(BulkUpColors.background)
    }

    // MARK: - Header

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text(exercise.localizedName)
                    .titleVoice(.title)
                    .foregroundColor(BulkUpColors.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
                if !meta.isEmpty {
                    Text(meta)
                        .font(BulkUpFont.body())
                        .foregroundColor(BulkUpColors.textSecondary)
                }
            }
            Spacer(minLength: Spacing.md)
            Button {
                dismiss()
            } label: {
                Text("Cerrar")
                    .font(.system(.footnote, weight: .semibold))
                    .foregroundColor(BulkUpColors.textSecondary)
                    .frame(minHeight: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Images

    @ViewBuilder
    private var imageSlab: some View {
        let images = (exercise.images ?? []).compactMap { URL(string: $0) }
        if images.isEmpty {
            HStack(spacing: Spacing.sm) {
                Image(systemName: ExerciseVocabulary.glyph(forCategory: exercise.category))
                    .font(.system(.title3, weight: .medium))
                    .foregroundColor(BulkUpColors.textTertiary)
                Text("Sin imágenes disponibles")
                    .font(BulkUpFont.caption())
                    .foregroundColor(BulkUpColors.textSecondary)
            }
            .frame(maxWidth: .infinity, minHeight: 72)
            .background(BulkUpColors.surfaceElevated)
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.large, style: .continuous))
        } else {
            VStack(spacing: Spacing.sm) {
                TabView(selection: $selectedImageIndex) {
                    ForEach(Array(images.enumerated()), id: \.offset) { index, url in
                        CachedAsyncImage(
                            url: url,
                            content: { image, _ in
                                image.resizable().scaledToFit()
                            },
                            placeholder: {
                                ProgressView().tint(BulkUpColors.accent)
                            }
                        )
                        .frame(maxWidth: .infinity)
                        .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .accessibilityLabel(exercise.localizedName)
                .frame(height: 240)
                .background(BulkUpColors.surfaceElevated)
                .clipShape(RoundedRectangle(cornerRadius: CornerRadius.large, style: .continuous))
                .lift()

                if images.count > 1 {
                    HStack(spacing: 6) {
                        ForEach(images.indices, id: \.self) { index in
                            Capsule()
                                .fill(index == selectedImageIndex ? BulkUpColors.textSecondary : BulkUpColors.line)
                                .frame(width: index == selectedImageIndex ? 16 : 6, height: 6)
                        }
                    }
                    .animation(.easeOut(duration: 0.2), value: selectedImageIndex)
                    .accessibilityHidden(true)
                }
            }
        }
    }

    // MARK: - Muscles / details

    private var musclesSlab: some View {
        VStack(spacing: 0) {
            labelRow("Principales", value: exercise.localizedPrimaryMuscles.joined(separator: ", "),
                     showsSeparator: !exercise.localizedSecondaryMuscles.isEmpty)
            if !exercise.localizedSecondaryMuscles.isEmpty {
                labelRow("Secundarios", value: exercise.localizedSecondaryMuscles.joined(separator: ", "),
                         showsSeparator: false)
            }
        }
        .slab()
    }

    @ViewBuilder
    private var detailsSlab: some View {
        let rows: [(LocalizedStringKey, String)] = [
            ("Tipo de fuerza", exercise.localizedForce),
            ("Mecánica", exercise.localizedMechanic),
            ("Equipo necesario", exercise.localizedEquipment),
            ("Nivel de dificultad", exercise.localizedLevel),
        ].compactMap { label, value in value.map { (label, $0) } }

        if !rows.isEmpty {
            VStack(spacing: 0) {
                ForEach(Array(rows.enumerated()), id: \.offset) { index, row in
                    SlabRow(showsSeparator: index < rows.count - 1, minHeight: 48) {
                        HStack(alignment: .firstTextBaseline, spacing: Spacing.md) {
                            Text(row.0)
                                .font(BulkUpFont.caption())
                                .foregroundColor(BulkUpColors.textSecondary)
                            Spacer(minLength: Spacing.sm)
                            Text(row.1)
                                .font(.system(.subheadline, weight: .semibold))
                                .foregroundColor(BulkUpColors.textPrimary)
                                .multilineTextAlignment(.trailing)
                        }
                    }
                }
            }
            .slab()
        }
    }

    private func labelRow(_ label: LocalizedStringKey, value: String, showsSeparator: Bool) -> some View {
        SlabRow(showsSeparator: showsSeparator, minHeight: 56) {
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(BulkUpFont.caption())
                    .foregroundColor(BulkUpColors.textSecondary)
                Text(value.isEmpty ? "—" : value)
                    .font(.system(.subheadline, weight: .semibold))
                    .foregroundColor(BulkUpColors.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    // MARK: - Instructions

    private func instructions(_ steps: [String]) -> some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Instrucciones")
                .font(.system(.headline, weight: .semibold))
                .foregroundColor(BulkUpColors.textPrimary)

            VStack(alignment: .leading, spacing: Spacing.sm + 2) {
                ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                    HStack(alignment: .firstTextBaseline, spacing: Spacing.md) {
                        Text("\(index + 1)")
                            .font(BulkUpFont.numeric(.footnote, weight: .semibold))
                            .foregroundColor(BulkUpColors.textTertiary)
                            .frame(width: 20, alignment: .trailing)
                        Text(step)
                            .font(BulkUpFont.body())
                            .foregroundColor(BulkUpColors.textPrimary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
            .padding(Spacing.md)
            .frame(maxWidth: .infinity, alignment: .leading)
            .slab()
        }
    }
}
