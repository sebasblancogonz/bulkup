//
//  WorkoutSummaryView.swift
//  bulkup
//
//  Full-screen celebration overlay after finishing a workout session.
//

import SwiftUI

struct WorkoutSummaryView: View {
    let summary: WorkoutSummary
    var onSave: () -> Void

    @State private var showCheck = false
    @State private var showCard = false

    var body: some View {
        ZStack {
            BulkUpColors.background
                .ignoresSafeArea()

            VStack(spacing: Spacing.xl) {
                Spacer()

                // Checkmark animation
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [BulkUpColors.success.opacity(0.2), BulkUpColors.success.opacity(0.05)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 100, height: 100)
                        .scaleEffect(showCheck ? 1.0 : 0.3)

                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(BulkUpColors.success)
                        .scaleEffect(showCheck ? 1.0 : 0.0)
                }
                .shadow(color: BulkUpColors.success.opacity(0.2), radius: 20, y: 10)

                // Title
                VStack(spacing: Spacing.sm) {
                    Text("Entreno completado!")
                        .font(BulkUpFont.largeTitle())
                        .foregroundColor(BulkUpColors.textPrimary)

                    if summary.isPartialCompletion {
                        Text("\(summary.exercisesCompleted)/\(summary.exercisesTotal) ejercicios completados")
                            .font(BulkUpFont.body())
                            .foregroundColor(BulkUpColors.textSecondary)
                    }
                }
                .opacity(showCard ? 1 : 0)
                .offset(y: showCard ? 0 : 20)

                // Stats grid
                statsGrid
                    .opacity(showCard ? 1 : 0)
                    .offset(y: showCard ? 0 : 30)

                Spacer()

                // Actions
                VStack(spacing: Spacing.md) {
                    Button {
                        onSave()
                    } label: {
                        HStack(spacing: Spacing.sm) {
                            Image(systemName: "checkmark.circle.fill")
                            Text("Guardar y salir")
                                .fontWeight(.semibold)
                        }
                        .primaryButtonStyle(color: BulkUpColors.accent)
                    }
                }
                .padding(.horizontal, Spacing.xl)
                .opacity(showCard ? 1 : 0)

                Spacer()
                    .frame(height: 40)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                showCheck = true
            }
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.6)) {
                showCard = true
            }
        }
    }

    // MARK: - Stats Grid

    private var statsGrid: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible()),
        ], spacing: Spacing.md) {
            statCell(
                value: summary.formattedDuration,
                label: String(localized: "Duracion"),
                icon: "clock.fill"
            )
            statCell(
                value: "\(summary.formattedVolume) kg",
                label: String(localized: "Volumen"),
                icon: "scalemass.fill"
            )
            statCell(
                value: "\(summary.totalSets)",
                label: String(localized: "Series"),
                icon: "number"
            )
            statCell(
                value: "\(summary.exercisesCompleted)",
                label: String(localized: "Ejercicios"),
                icon: "figure.strengthtraining.traditional"
            )
        }
        .padding(.horizontal, Spacing.xl)
    }

    private func statCell(value: String, label: String, icon: String) -> some View {
        VStack(spacing: Spacing.sm) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(BulkUpColors.accent)

            Text(value)
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundColor(BulkUpColors.textPrimary)

            Text(label)
                .font(BulkUpFont.caption())
                .foregroundColor(BulkUpColors.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Spacing.md)
        .background(BulkUpColors.surface)
        .cornerRadius(CornerRadius.medium)
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.medium)
                .stroke(BulkUpColors.border, lineWidth: 0.5)
        )
    }
}
