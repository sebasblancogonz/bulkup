import ActivityKit
import AppIntents
import SwiftUI
import WidgetKit

struct WorkoutLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: WorkoutActivityAttributes.self) { context in
            WorkoutLockScreenView(state: context.state)
                .padding()
                .activityBackgroundTint(Color.black.opacity(0.6))
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Text(timerInterval: context.state.startDate...Date.distantFuture, countsDown: false)
                        .monospacedDigit().font(.caption)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text("\(context.state.completedSets)/\(context.state.totalSets)").font(.caption)
                }
            } compactLeading: {
                Image(systemName: "dumbbell.fill")
            } compactTrailing: {
                Text("\(context.state.completedSets)/\(context.state.totalSets)").font(.caption2)
            } minimal: {
                Image(systemName: "dumbbell.fill")
            }
        }
    }
}

struct WorkoutLockScreenView: View {
    let state: WorkoutActivityAttributes.ContentState

    private var weightStep: Double { state.weightUnit == "lb" ? 5.0 : 2.5 }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header — always visible
            HStack {
                Text(state.workoutName).font(.headline).lineLimit(1)
                Spacer()
                Text(timerInterval: state.startDate...Date.distantFuture, countsDown: false)
                    .monospacedDigit().font(.subheadline)
            }

            if state.isFinished {
                Text("Workout complete").font(.subheadline)
            } else if state.isResting, let end = state.restEndDate {
                // During rest — countdown + skip/add buttons
                HStack {
                    Text("Rest").font(.subheadline)
                    Text(timerInterval: Date()...end, countsDown: true)
                        .monospacedDigit().font(.title3.bold())
                }
                HStack(spacing: 8) {
                    Button(intent: SkipRestIntent()) {
                        Text("Skip").frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    Button(intent: AddRestIntent(seconds: 30)) {
                        Text("+30s").frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                }
            } else {
                // During a set — weight/reps controls + complete button
                Text("\(state.exerciseName) · Set \(state.setIndex + 1)/\(state.setsTotal)")
                    .font(.subheadline)

                HStack(spacing: 4) {
                    Button(intent: AdjustWeightIntent(delta: -weightStep)) {
                        Image(systemName: "minus.circle")
                    }
                    Text("\(formatWeight(state.weight)) \(state.weightUnit)")
                        .monospacedDigit()
                        .frame(minWidth: 70)
                    Button(intent: AdjustWeightIntent(delta: weightStep)) {
                        Image(systemName: "plus.circle")
                    }
                    Spacer()
                    Button(intent: AdjustRepsIntent(delta: -1)) {
                        Image(systemName: "minus.circle")
                    }
                    Text("\(state.reps) reps")
                        .monospacedDigit()
                        .frame(minWidth: 60)
                    Button(intent: AdjustRepsIntent(delta: 1)) {
                        Image(systemName: "plus.circle")
                    }
                }
                .buttonStyle(.plain)

                Button(intent: CompleteCurrentSetIntent()) {
                    Label("Complete set", systemImage: "checkmark.circle.fill")
                        .frame(maxWidth: .infinity)
                }
                .tint(.green)
            }

            // Progress bar — always visible
            ProgressView(value: Double(state.completedSets),
                         total: Double(max(state.totalSets, 1)))
                .tint(.green)
        }
    }

    private func formatWeight(_ w: Double) -> String {
        w == w.rounded() ? String(format: "%.0f", w) : String(format: "%.1f", w)
    }
}
