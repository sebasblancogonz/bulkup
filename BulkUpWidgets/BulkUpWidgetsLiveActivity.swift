import ActivityKit
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

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(state.workoutName).font(.headline).lineLimit(1)
                Spacer()
                Text(timerInterval: state.startDate...Date.distantFuture, countsDown: false)
                    .monospacedDigit().font(.subheadline)
            }
            if state.isFinished {
                Text("Workout complete").font(.subheadline)
            } else if state.isResting, let end = state.restEndDate {
                HStack {
                    Text("Rest").font(.subheadline)
                    Text(timerInterval: Date()...end, countsDown: true)
                        .monospacedDigit().font(.title3.bold())
                }
            } else {
                Text("\(state.exerciseName) · Set \(state.setIndex + 1)/\(state.setsTotal)")
                    .font(.subheadline)
                Text("\(formatWeight(state.weight)) \(state.weightUnit) × \(state.reps)")
                    .font(.subheadline).foregroundStyle(.secondary)
            }
            ProgressView(value: Double(state.completedSets),
                         total: Double(max(state.totalSets, 1)))
                .tint(.green)
        }
    }

    private func formatWeight(_ w: Double) -> String {
        w == w.rounded() ? String(format: "%.0f", w) : String(format: "%.1f", w)
    }
}
