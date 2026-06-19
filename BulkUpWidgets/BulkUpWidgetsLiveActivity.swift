import ActivityKit
import AppIntents
import SwiftUI
import WidgetKit

/// Local mirror of the app's design tokens (DesignSystem.swift lives in the app
/// target only). Keep in sync with BulkUpColors if the brand palette changes.
private enum WidgetTheme {
    static let accent = Color(red: 0.0, green: 0.902, blue: 0.765)        // #00E6C3
    static let background = Color(red: 0.039, green: 0.039, blue: 0.039)  // #0A0A0A
    static let surface = Color(red: 0.086, green: 0.086, blue: 0.086)     // #161616
    static let textPrimary = Color.white
    static let textSecondary = Color(red: 0.557, green: 0.557, blue: 0.576) // #8E8E93
    static let onAccent = Color.black

    static func number(_ size: CGFloat, _ weight: Font.Weight = .bold) -> Font {
        .system(size: size, weight: weight, design: .rounded).monospacedDigit()
    }
}

struct WorkoutLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: WorkoutActivityAttributes.self) { context in
            WorkoutLockScreenView(state: context.state)
                .padding(14)
                .activityBackgroundTint(WidgetTheme.background)
                .activitySystemActionForegroundColor(WidgetTheme.accent)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Label {
                        Text(timerInterval: context.state.startDate...Date.distantFuture, countsDown: false)
                            .font(WidgetTheme.number(15)).foregroundStyle(WidgetTheme.accent)
                    } icon: {
                        Image(systemName: "dumbbell.fill").foregroundStyle(WidgetTheme.accent)
                    }
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text("\(context.state.completedSets)/\(context.state.totalSets)")
                        .font(WidgetTheme.number(15)).foregroundStyle(WidgetTheme.textSecondary)
                }
            } compactLeading: {
                Image(systemName: "dumbbell.fill").foregroundStyle(WidgetTheme.accent)
            } compactTrailing: {
                Text("\(context.state.completedSets)/\(context.state.totalSets)")
                    .font(WidgetTheme.number(13)).foregroundStyle(WidgetTheme.accent)
            } minimal: {
                Image(systemName: "dumbbell.fill").foregroundStyle(WidgetTheme.accent)
            }
            .keylineTint(WidgetTheme.accent)
        }
    }
}

struct WorkoutLockScreenView: View {
    let state: WorkoutActivityAttributes.ContentState

    private var weightStep: Double { state.weightUnit == "lb" ? 5.0 : 2.5 }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            header

            if state.isFinished {
                Label("Entreno completado", systemImage: "checkmark.seal.fill")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(WidgetTheme.accent)
            } else if state.isResting, let end = state.restEndDate {
                restControls(end: end)
            } else {
                setControls
            }

            progressBar
        }
        .tint(WidgetTheme.accent)
    }

    // MARK: Header
    private var header: some View {
        HStack(spacing: 8) {
            Image(systemName: "dumbbell.fill")
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(WidgetTheme.accent)
            Text(state.workoutName)
                .font(.headline)
                .foregroundStyle(WidgetTheme.textPrimary)
                .lineLimit(1)
            Spacer()
            Text(timerInterval: state.startDate...Date.distantFuture, countsDown: false)
                .font(WidgetTheme.number(17))
                .foregroundStyle(WidgetTheme.accent)
        }
    }

    // MARK: During a set
    private var setControls: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("\(state.exerciseName) · Serie \(state.setIndex + 1)/\(state.setsTotal)")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(WidgetTheme.textSecondary)
                .lineLimit(1)

            HStack(spacing: 14) {
                stepper(value: "\(formatWeight(state.weight)) \(state.weightUnit)",
                        minus: AdjustWeightIntent(delta: -weightStep),
                        plus: AdjustWeightIntent(delta: weightStep),
                        minWidth: 78)
                Spacer(minLength: 4)
                stepper(value: "\(state.reps) reps",
                        minus: AdjustRepsIntent(delta: -1),
                        plus: AdjustRepsIntent(delta: 1),
                        minWidth: 64)
            }

            Button(intent: CompleteCurrentSetIntent()) {
                Text("Completar serie")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(WidgetTheme.onAccent)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 9)
                    .background(WidgetTheme.accent, in: Capsule())
            }
            .buttonStyle(.plain)
        }
    }

    private func stepper<I: AppIntent>(value: String, minus: I, plus: I, minWidth: CGFloat) -> some View {
        HStack(spacing: 8) {
            Button(intent: minus) {
                Image(systemName: "minus.circle.fill").font(.title3).foregroundStyle(WidgetTheme.accent)
            }.buttonStyle(.plain)
            Text(value)
                .font(WidgetTheme.number(17))
                .foregroundStyle(WidgetTheme.textPrimary)
                .frame(minWidth: minWidth)
            Button(intent: plus) {
                Image(systemName: "plus.circle.fill").font(.title3).foregroundStyle(WidgetTheme.accent)
            }.buttonStyle(.plain)
        }
    }

    // MARK: During rest
    private func restControls(end: Date) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline, spacing: 10) {
                Text("DESCANSO")
                    .font(.caption.weight(.bold)).tracking(1.5)
                    .foregroundStyle(WidgetTheme.textSecondary)
                Text(timerInterval: Date()...end, countsDown: true)
                    .font(WidgetTheme.number(28))
                    .foregroundStyle(WidgetTheme.accent)
            }
            HStack(spacing: 8) {
                restButton("Saltar", intent: SkipRestIntent())
                restButton("+30s", intent: AddRestIntent(seconds: 30))
            }
        }
    }

    private func restButton<I: AppIntent>(_ title: String, intent: I) -> some View {
        Button(intent: intent) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(WidgetTheme.accent)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 7)
                .overlay(Capsule().stroke(WidgetTheme.accent.opacity(0.5), lineWidth: 1))
        }
        .buttonStyle(.plain)
    }

    // MARK: Progress
    private var progressBar: some View {
        GeometryReader { geo in
            let fraction = state.totalSets > 0 ? Double(state.completedSets) / Double(state.totalSets) : 0
            ZStack(alignment: .leading) {
                Capsule().fill(WidgetTheme.surface)
                Capsule().fill(WidgetTheme.accent)
                    .frame(width: max(0, geo.size.width * fraction))
            }
        }
        .frame(height: 5)
    }

    private func formatWeight(_ w: Double) -> String {
        w == w.rounded() ? String(format: "%.0f", w) : String(format: "%.1f", w)
    }
}
