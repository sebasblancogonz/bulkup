//
//  ExerciseAlternativesSheet.swift
//  bulkup
//
//  "Machine occupied" escape hatch: suggests substitutes with the same muscle
//  impact and stimulus, ranked from the exercise DB. Selecting one swaps the
//  exercise for the current session only (the plan is never modified).
//

import SwiftUI

struct ExerciseAlternativesSheet: View {
    /// The name currently being performed (plan name or an earlier swap).
    let currentName: String
    let onSelect: (RMExerciseFull) -> Void

    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var explorer = ExerciseExplorerManager.shared

    private var suggestions: [RMExerciseFull]? {
        guard let current = ExerciseAlternatives.match(planName: currentName, in: explorer.exercises)
        else { return nil }
        return ExerciseAlternatives.rank(for: current, in: explorer.exercises)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Alternativas")
                    .font(BulkUpFont.cardTitle())
                    .foregroundColor(BulkUpColors.textPrimary)
                Text("Mismo músculo y estímulo que \(currentName)")
                    .font(BulkUpFont.caption())
                    .foregroundColor(BulkUpColors.textSecondary)
            }

            if explorer.exercises.isEmpty {
                if explorer.loading {
                    HStack {
                        Spacer()
                        ProgressView()
                        Spacer()
                    }
                    .padding(.vertical, Spacing.xl)
                } else {
                    emptyState("No se pudo cargar la base de ejercicios. Inténtalo con conexión.")
                }
            } else if let suggestions, !suggestions.isEmpty {
                VStack(spacing: Spacing.sm) {
                    ForEach(suggestions) { alt in
                        Button {
                            onSelect(alt)
                            dismiss()
                        } label: {
                            row(for: alt)
                        }
                        .buttonStyle(.plain)
                    }
                }
                Text("El cambio solo afecta al entreno de hoy; tu plan no se modifica.")
                    .font(BulkUpFont.caption())
                    .foregroundColor(BulkUpColors.textTertiary)
            } else {
                emptyState("No encontramos una alternativa equivalente para este ejercicio.")
            }

            Spacer(minLength: 0)
        }
        .padding(Spacing.screenH)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(BulkUpColors.background)
        .task {
            if explorer.exercises.isEmpty {
                await explorer.fetchExercises()
            }
        }
    }

    private func row(for alt: RMExerciseFull) -> some View {
        HStack(spacing: Spacing.md) {
            VStack(alignment: .leading, spacing: 3) {
                Text(alt.localizedName)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(BulkUpColors.textPrimary)
                    .multilineTextAlignment(.leading)

                HStack(spacing: Spacing.xs) {
                    if let equipment = alt.localizedEquipment {
                        tag(equipment)
                    }
                    if let muscle = alt.localizedPrimaryMuscles.first {
                        tag(muscle)
                    }
                }
            }
            Spacer()
            Image(systemName: "arrow.triangle.2.circlepath")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(BulkUpColors.accent)
        }
        .padding(Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: 12).fill(BulkUpColors.surfaceElevated)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(BulkUpColors.textTertiary.opacity(0.15), lineWidth: 1)
        )
        .contentShape(RoundedRectangle(cornerRadius: 12))
    }

    private func tag(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 11, weight: .medium))
            .foregroundColor(BulkUpColors.textSecondary)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(Capsule().fill(BulkUpColors.surface))
    }

    private func emptyState(_ message: String) -> some View {
        Text(message)
            .font(BulkUpFont.caption())
            .foregroundColor(BulkUpColors.textSecondary)
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.vertical, Spacing.xl)
    }
}
