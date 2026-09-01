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
    /// Receives the chosen exercise name — a ranked suggestion or a typed one.
    let onSelect: (String) -> Void

    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var explorer = ExerciseExplorerManager.shared
    @State private var customName: String = ""

    private var suggestions: [RMExerciseFull]? {
        guard let current = ExerciseAlternatives.match(planName: currentName, in: explorer.exercises)
        else { return nil }
        return ExerciseAlternatives.rank(for: current, in: explorer.exercises)
    }

    private var trimmedCustom: String {
        customName.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var body: some View {
        ScrollView {
            content
                .padding(Spacing.screenH)
        }
        .scrollDismissesKeyboard(.interactively)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(BulkUpColors.background)
        .task {
            if explorer.exercises.isEmpty {
                await explorer.fetchExercises()
            }
        }
    }

    @ViewBuilder
    private var content: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Alternativas")
                    .font(BulkUpFont.cardTitle())
                    .foregroundColor(BulkUpColors.textPrimary)
                Text("Mismo músculo y estímulo que \(currentName)")
                    .font(BulkUpFont.caption())
                    .foregroundColor(BulkUpColors.textSecondary)
            }

            customSection

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
                            onSelect(alt.localizedName)
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
    }

    /// Escape hatch when the DB has nothing suitable: type any exercise name.
    private var customSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("Otra alternativa")
                .font(BulkUpFont.badge())
                .tracking(0.5)
                .foregroundColor(BulkUpColors.textTertiary)

            HStack(spacing: Spacing.sm) {
                TextField("Escribe un ejercicio...", text: $customName)
                    .font(.system(size: 15))
                    .foregroundColor(BulkUpColors.textPrimary)
                    .autocorrectionDisabled()
                    .submitLabel(.done)
                    .onSubmit(applyCustom)
                    .padding(.horizontal, Spacing.md)
                    .frame(height: 44)
                    .background(
                        RoundedRectangle(cornerRadius: 12).fill(BulkUpColors.surfaceElevated)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(BulkUpColors.textTertiary.opacity(0.15), lineWidth: 1)
                    )

                Button(action: applyCustom) {
                    Image(systemName: "checkmark")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(BulkUpColors.onAccent)
                        .frame(width: 44, height: 44)
                        .background(
                            RoundedRectangle(cornerRadius: 12).fill(BulkUpColors.accent)
                        )
                }
                .disabled(trimmedCustom.isEmpty)
                .opacity(trimmedCustom.isEmpty ? 0.4 : 1)
                .accessibilityLabel("Usar alternativa personalizada")
            }
        }
    }

    private func applyCustom() {
        let name = trimmedCustom
        guard !name.isEmpty else { return }
        onSelect(name)
        dismiss()
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
