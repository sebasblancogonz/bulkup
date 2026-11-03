//
//  ActiveWorkoutHeader.swift
//  bulkup
//
//  Timer + workout name + pause button during active workout session.
//

import SwiftUI

struct ActiveWorkoutHeader: View {
    @ObservedObject var session: WorkoutSessionManager
    // Drives the per-second elapsed refresh (session itself no longer ticks).
    @ObservedObject private var ticker = WorkoutSessionManager.shared.ticker
    var onFinish: () -> Void
    var onDiscard: () -> Void

    @State private var showActionSheet = false
    @State private var showDiscardConfirm = false
    @State private var pulseAnimation = false

    var body: some View {
        HStack(alignment: .center, spacing: Spacing.md) {
            // Elapsed time + pulsing dot
            HStack(spacing: 6) {
                Circle()
                    .fill(BulkUpColors.accent)
                    .frame(width: 8, height: 8)
                    .scaleEffect(pulseAnimation ? 1.3 : 1.0)
                    .opacity(pulseAnimation ? 0.6 : 1.0)
                    .animation(
                        .easeInOut(duration: 1.0).repeatForever(autoreverses: true),
                        value: pulseAnimation
                    )

                Text(session.formattedElapsed())
                    .font(BulkUpFont.mono(17, weight: .semibold, relativeTo: .headline))
                    .foregroundColor(BulkUpColors.textPrimary)
            }

            Spacer()

            // Workout name
            if let name = session.workoutName {
                Text(name)
                    .font(.system(.headline, weight: .semibold))
                    .foregroundColor(BulkUpColors.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }

            Spacer()

            // Pause / actions button
            Button {
                if session.isPaused {
                    session.resumeWorkout()
                } else {
                    showActionSheet = true
                }
            } label: {
                Image(systemName: session.isPaused ? "play.fill" : "pause.fill")
                    .font(.system(.footnote, weight: .bold))
                    .foregroundColor(session.isPaused ? BulkUpColors.onAccent : BulkUpColors.textPrimary)
                    .frame(width: 36, height: 36)
                    .background(session.isPaused ? BulkUpColors.accent : BulkUpColors.surfaceElevated)
                    .clipShape(RoundedRectangle(cornerRadius: CornerRadius.medium, style: .continuous))
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
            .accessibilityLabel(session.isPaused ? "Continuar" : "Pausar")
        }
        .padding(.horizontal, Spacing.screenH)
        .padding(.vertical, Spacing.sm)
        .onAppear { pulseAnimation = true }
        .onDisappear { pulseAnimation = false }
        .confirmationDialog("Entreno en curso", isPresented: $showActionSheet) {
            if session.isPaused {
                Button("Continuar") {
                    session.resumeWorkout()
                }
            } else {
                Button("Pausar") {
                    session.pauseWorkout()
                }
            }

            Button("Descartar", role: .destructive) {
                showDiscardConfirm = true
            }

            Button("Cancelar", role: .cancel) {}
        }
        .alert("¿Descartar entreno?", isPresented: $showDiscardConfirm) {
            Button("Descartar", role: .destructive) {
                onDiscard()
            }
            Button("Cancelar", role: .cancel) {}
        } message: {
            Text("Se perderá todo el progreso de esta sesión.")
        }
    }
}
