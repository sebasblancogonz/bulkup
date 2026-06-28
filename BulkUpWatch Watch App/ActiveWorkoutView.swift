import SwiftUI

struct ActiveWorkoutView: View {
    @EnvironmentObject var wc: WatchWCManager
    let live: LiveWorkout
    private let lime = Color(red: 0.518, green: 0.800, blue: 0.086)

    var body: some View {
        if let restEnd = live.restEndDate, restEnd > Date() {
            RestTimerView(end: restEnd) // Task 6
        } else if let s = live.current {
            ScrollView {
                VStack(spacing: 10) {
                    Text(s.exerciseName).font(.headline).lineLimit(1)
                    Text("Serie \(s.setIndex + 1)/\(s.setsTotalForExercise)")
                        .font(.caption).foregroundStyle(.secondary)

                    stepper(label: "\(fmt(s.weight)) \(live.weightUnit)",
                            minus: .adjustWeight(delta: -live.weightStep),
                            plus: .adjustWeight(delta: live.weightStep))
                    stepper(label: "\(s.reps) reps",
                            minus: .adjustReps(delta: -1), plus: .adjustReps(delta: 1))

                    Button { wc.send(.completeSet) } label: {
                        Text("Complete set").frame(maxWidth: .infinity)
                    }.buttonStyle(.borderedProminent).tint(lime)

                    ProgressView(value: Double(live.completedCount), total: Double(max(live.sets.count, 1)))
                        .tint(lime)

                    Button("Finish") { wc.send(.finishWorkout) }
                        .font(.caption).foregroundStyle(.secondary)
                }.padding()
            }
        } else {
            Text("Workout complete").padding()
        }
    }

    private func stepper(label: String, minus: WatchMessage, plus: WatchMessage) -> some View {
        HStack {
            Button { wc.send(minus) } label: { Image(systemName: "minus") }.buttonStyle(.bordered)
            Text(label).font(.body).monospacedDigit().frame(maxWidth: .infinity)
            Button { wc.send(plus) } label: { Image(systemName: "plus") }.buttonStyle(.bordered)
        }
    }
    private func fmt(_ w: Double) -> String { w == w.rounded() ? String(format: "%.0f", w) : String(format: "%.1f", w) }
}
