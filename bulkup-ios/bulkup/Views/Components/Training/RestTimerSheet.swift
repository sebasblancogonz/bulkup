//
//  RestTimerSheet.swift
//  bulkup
//
//  Rest countdown bottom sheet with circular progress, skip, and +30s.
//

import SwiftUI

struct RestTimerSheet: View {
    @ObservedObject var session: WorkoutSessionManager

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
                // Dark fill behind the ring for contrast
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                BulkUpColors.shadow.opacity(0.4),
                                BulkUpColors.shadow.opacity(0.15),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 30,
                            endRadius: 70
                        )
                    )
                    .frame(width: 140, height: 140)

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
