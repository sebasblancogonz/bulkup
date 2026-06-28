import SwiftUI

struct ActiveWorkoutView: View {
    @EnvironmentObject var wc: WatchWCManager
    @EnvironmentObject var metrics: WorkoutMetricsManager
    @State private var finishing = false
    let live: LiveWorkout
    private let lime = Color(red: 0.518, green: 0.800, blue: 0.086)

    var body: some View {
        Group {
            if let restEnd = live.restEndDate, restEnd > Date() {
                RestTimerView(end: restEnd) // Task 6
            } else if let s = live.current {
                ScrollView {
                    VStack(spacing: 10) {
                        Text(s.exerciseName).font(.headline).lineLimit(1)
                        Text("Serie \(s.setIndex + 1)/\(s.setsTotalForExercise)")
                            .font(.caption).foregroundStyle(.secondary)

                        if metrics.isRunning {
                            HStack(spacing: 12) {
                                Label("\(metrics.heartRate)", systemImage: "heart.fill")
                                    .foregroundStyle(.red)
                                Label("\(Int(metrics.activeEnergy)) kcal", systemImage: "flame.fill")
                                    .foregroundStyle(.orange)
                            }.font(.caption).monospacedDigit()
                        }

                        stepper(label: "\(fmt(s.weight)) \(live.weightUnit)",
                                minus: { wc.adjustWeight(-live.weightStep) },
                                plus: { wc.adjustWeight(live.weightStep) })
                        stepper(label: "\(s.reps) reps",
                                minus: { wc.adjustReps(-1) }, plus: { wc.adjustReps(1) })

                        Button { wc.completeSet() } label: {
                            Text("Complete set").frame(maxWidth: .infinity)
                        }.buttonStyle(.borderedProminent).tint(lime)

                        ProgressView(value: Double(live.completedCount), total: Double(max(live.sets.count, 1)))
                            .tint(lime)

                        Button(finishing ? "Finishing…" : "Finish") {
                            finishing = true
                            Task {
                                let m = await metrics.end()
                                wc.send(.finishWorkout(metrics: m))
                            }
                        }
                        .disabled(finishing)
                        .font(.caption).foregroundStyle(.secondary)
                    }.padding()
                }
            } else {
                Text("Workout complete").padding()
            }
        }
        .onAppear { metrics.start() }
        .onDisappear { Task { _ = await metrics.end() } }
    }

    private func stepper(label: String, minus: @escaping () -> Void, plus: @escaping () -> Void) -> some View {
        HStack {
            Button { minus() } label: { Image(systemName: "minus") }.buttonStyle(.bordered)
            Text(label).font(.body).monospacedDigit().frame(maxWidth: .infinity)
            Button { plus() } label: { Image(systemName: "plus") }.buttonStyle(.bordered)
        }
    }
    private func fmt(_ w: Double) -> String { w == w.rounded() ? String(format: "%.0f", w) : String(format: "%.1f", w) }
}
