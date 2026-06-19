//
//  ActiveWorkoutHeader.swift
//  bulkup
//
//  Timer + workout name + pause button during active workout session.
//

import SwiftUI

struct ActiveWorkoutHeader: View {
    @ObservedObject var session: WorkoutSessionManager
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
                    .fill(BulkUpColors.error)
                    .frame(width: 8, height: 8)
                    .scaleEffect(pulseAnimation ? 1.3 : 1.0)
                    .opacity(pulseAnimation ? 0.6 : 1.0)
                    .animation(
                        .easeInOut(duration: 1.0).repeatForever(autoreverses: true),
                        value: pulseAnimation
                    )

                Text(session.formattedElapsed())
                    .font(.system(size: 17, weight: .medium, design: .monospaced))
                    .monospacedDigit()
                    .foregroundColor(BulkUpColors.textPrimary)
            }

            Spacer()

            // Workout name
            if let name = session.workoutName {
                Text(name)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(BulkUpColors.textPrimary)
                    .lineLimit(1)
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
                Image(systemName: session.isPaused ? "play.circle" : "pause.circle")
                    .font(.system(size: 28, weight: .medium))
                    .foregroundColor(
                        session.isPaused ? BulkUpColors.accent : BulkUpColors.textSecondary
                    )
            }
        }
        .padding(.horizontal, Spacing.screenH)
        .padding(.vertical, Spacing.sm)
        .onAppear { pulseAnimation = true }
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

            Button("Finalizar entreno") {
                onFinish()
            }

            Button("Descartar", role: .destructive) {
                showDiscardConfirm = true
            }

            Button("Cancelar", role: .cancel) {}
        }
        .alert("Descartar entreno?", isPresented: $showDiscardConfirm) {
            Button("Descartar", role: .destructive) {
                onDiscard()
            }
            Button("Cancelar", role: .cancel) {}
        } message: {
            Text("Se perdera todo el progreso de esta sesion.")
        }
    }
}
