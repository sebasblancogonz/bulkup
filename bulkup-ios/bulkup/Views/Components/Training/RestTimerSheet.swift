//
//  RestTimerSheet.swift
//  bulkup
//
//  Rest countdown bottom sheet with circular progress, skip, and +30s.
//

import SwiftUI

struct RestTimerSheet: View {
    @ObservedObject var session: WorkoutSessionManager
    // Drives the per-second countdown refresh (session itself no longer ticks).
    @ObservedObject private var ticker = WorkoutSessionManager.shared.ticker

    private var progress: CGFloat {
        guard session.restTimerTotal > 0 else { return 0 }
        return CGFloat(session.restTimerTotal - session.restTimerRemaining) / CGFloat(session.restTimerTotal)
    }

    var body: some View {
        VStack(spacing: Spacing.lg) {
            // Drag indicator
            Capsule()
                .fill(BulkUpColors.textTertiary)
                .frame(width: 36, height: 5)
                .padding(.top, Spacing.md)

            // Label
            Text("DESCANSO")
                .font(.system(size: 13, weight: .bold))
                .tracking(1.5)
                .foregroundColor(BulkUpColors.textSecondary)

            // Circular progress + countdown
            ZStack {
                Circle()
                    .stroke(BulkUpColors.border, lineWidth: 8)
                    .frame(width: 120, height: 120)

                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(
                        AngularGradient(
                            colors: [BulkUpColors.accent, BulkUpColors.accentGlow, BulkUpColors.accent],
                            center: .center,
                            startAngle: .degrees(-90),
                            endAngle: .degrees(270)
                        ),
                        style: StrokeStyle(lineWidth: 8, lineCap: .round)
                    )
                    .frame(width: 120, height: 120)
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 1), value: progress)
                    .shadow(color: BulkUpColors.accent.opacity(0.4), radius: 6, x: 0, y: 0)

                Text(WorkoutSessionManager.formatTime(session.restTimerRemaining))
                    .font(.system(size: 56, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .foregroundColor(BulkUpColors.textPrimary)
            }

            // Next set info
            if let info = session.nextSetInfo {
                Text("Siguiente: \(info)")
                    .font(BulkUpFont.caption())
                    .foregroundColor(BulkUpColors.textSecondary)
            }

            // Action buttons
            HStack(spacing: Spacing.md) {
                Button {
                    session.skipRest()
                } label: {
                    Text("Saltar")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(BulkUpColors.accent)
                        .padding(.horizontal, Spacing.lg)
                        .padding(.vertical, Spacing.sm)
                        .overlay(
                            Capsule()
                                .stroke(BulkUpColors.accent, lineWidth: 1.5)
                        )
                }

                Button {
                    session.addRestTime(seconds: 30)
                } label: {
                    Text("+30s")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(BulkUpColors.textPrimary)
                        .padding(.horizontal, Spacing.lg)
                        .padding(.vertical, Spacing.sm)
                        .background(BulkUpColors.surfaceElevated)
                        .clipShape(Capsule())
                }
            }

            Spacer()
        }
        .frame(maxWidth: .infinity)
        .background(BulkUpColors.background)
    }
}

/// Compact rest countdown pinned under the workout header while the sheet is
/// dismissed — the timer never disappears from view mid-rest. Tapping the time
/// re-opens the sheet.
struct RestTimerBanner: View {
    @ObservedObject var session: WorkoutSessionManager
    // Drives the per-second countdown refresh (session itself no longer ticks).
    @ObservedObject private var ticker = WorkoutSessionManager.shared.ticker

    private var progress: Double {
        guard session.restTimerTotal > 0 else { return 0 }
        return Double(session.restTimerTotal - session.restTimerRemaining) / Double(session.restTimerTotal)
    }

    var body: some View {
        HStack(spacing: Spacing.md) {
            Button {
                session.restSheetVisible = true
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "timer")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(BulkUpColors.accent)
                    Text(WorkoutSessionManager.formatTime(session.restTimerRemaining))
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .monospacedDigit()
                        .foregroundColor(BulkUpColors.textPrimary)
                }
            }
            .buttonStyle(.plain)

            ProgressView(value: progress)
                .tint(BulkUpColors.accent)

            Button("Saltar") { session.skipRest() }
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(BulkUpColors.accent)

            Button("+30s") { session.addRestTime(seconds: 30) }
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(BulkUpColors.textSecondary)
        }
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.sm)
        .background(
            RoundedRectangle(cornerRadius: 12).fill(BulkUpColors.surfaceElevated)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(BulkUpColors.accent.opacity(0.25), lineWidth: 1)
        )
    }
}
