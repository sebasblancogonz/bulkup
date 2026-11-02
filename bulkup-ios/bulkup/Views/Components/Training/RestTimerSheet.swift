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
            Text("Descanso")
                .font(.system(.subheadline, weight: .semibold))
                .foregroundColor(BulkUpColors.textSecondary)

            // Countdown: a lime rule drains as the rest runs out
            VStack(spacing: Spacing.md) {
                Text(WorkoutSessionManager.formatTime(session.restTimerRemaining))
                    .font(BulkUpFont.mono(64, weight: .semibold, relativeTo: .largeTitle))
                    .foregroundColor(BulkUpColors.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                    .contentTransition(.numericText(countsDown: true))
                    .animation(.linear(duration: 0.3), value: session.restTimerRemaining)

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Rectangle().fill(BulkUpColors.line)
                        Rectangle()
                            .fill(BulkUpColors.accent)
                            .frame(width: geo.size.width * (1 - progress))
                            .animation(.linear(duration: 1), value: progress)
                    }
                }
                .frame(height: 4)
                .padding(.horizontal, Spacing.xl)
            }

            // Next set info
            if let info = session.nextSetInfo {
                HStack(spacing: Spacing.xs) {
                    Text("Siguiente")
                        .font(.system(.body))
                        .foregroundColor(BulkUpColors.textSecondary)
                    Text(info)
                        .font(BulkUpFont.numeric(.body, weight: .semibold))
                        .foregroundColor(BulkUpColors.textPrimary)
                }
            }

            // Action buttons
            HStack(spacing: Spacing.md) {
                Button {
                    session.skipRest()
                } label: {
                    Text("Saltar")
                        .outlineButtonStyle()
                }
                Button {
                    session.addRestTime(seconds: 30)
                } label: {
                    Text("+30 s")
                        .secondaryButtonStyle()
                }
            }
            .padding(.horizontal, Spacing.xl)

            Spacer()
        }
        .frame(maxWidth: .infinity)
        .background(BulkUpColors.surface)
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
                        .font(.system(.footnote, weight: .semibold))
                        .foregroundColor(BulkUpColors.accentText)
                    Text(WorkoutSessionManager.formatTime(session.restTimerRemaining))
                        .font(BulkUpFont.mono(17, weight: .semibold, relativeTo: .body))
                        .foregroundColor(BulkUpColors.textPrimary)
                }
            }
            .buttonStyle(.plain)

            ProgressView(value: progress)
                .tint(BulkUpColors.accent)

            Button("Saltar") { session.skipRest() }
                .font(.system(.footnote, weight: .semibold))
                .foregroundColor(BulkUpColors.accentText)

            Button("+30 s") { session.addRestTime(seconds: 30) }
                .font(.system(.footnote, weight: .semibold))
                .foregroundColor(BulkUpColors.textSecondary)
        }
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.sm)
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.medium, style: .continuous)
                .fill(BulkUpColors.surfaceElevated)
        )
        .lift(CornerRadius.medium)
    }
}
