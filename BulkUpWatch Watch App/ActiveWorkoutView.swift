import SwiftUI

struct ActiveWorkoutView: View {
    @EnvironmentObject var wc: WatchWCManager
    @EnvironmentObject var metrics: WorkoutMetricsManager
    @State private var finishing = false
    let live: LiveWorkout

    var body: some View {
        Group {
            if let restEnd = live.restEndDate, restEnd > Date() {
                RestTimerView(end: restEnd)
            } else if let s = live.current {
                ScrollView {
                    VStack(spacing: 12) {
                        // Full exercise name — wraps instead of truncating.
                        Text(s.exerciseName)
                            .font(.headline)
                            .multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true)
                            .frame(maxWidth: .infinity)

                        Text("SERIE \(s.setIndex + 1) / \(s.setsTotalForExercise)")
                            .font(.caption2).fontWeight(.semibold).monospacedDigit()
                            .foregroundStyle(.black)
                            .padding(.horizontal, 10).padding(.vertical, 3)
                            .background(Color.lime, in: Capsule())

                        HStack(spacing: 4) {
                            Image(systemName: "stopwatch")
                            Text(timerInterval: live.startDate...Date.distantFuture, countsDown: false)
                                .monospacedDigit()
                        }
                        .font(.caption)
                        .foregroundStyle(.secondary)

                        if metrics.isRunning {
                            HStack(spacing: 16) {
                                Label("\(metrics.heartRate)", systemImage: "heart.fill")
                                    .foregroundStyle(.red)
                                Label("\(Int(metrics.activeEnergy)) kcal", systemImage: "flame.fill")
                                    .foregroundStyle(.orange)
                            }
                            .font(.caption).monospacedDigit()
                            .padding(.vertical, 6).frame(maxWidth: .infinity)
                            .background(Color.card, in: RoundedRectangle(cornerRadius: 10))
                        }

                        stepper(label: "\(fmt(s.weight)) \(live.weightUnit)",
                                emphasized: true,
                                minus: { wc.adjustWeight(-live.weightStep) },
                                plus: { wc.adjustWeight(live.weightStep) })
                        stepper(label: "\(s.reps) reps",
                                emphasized: false,
                                minus: { wc.adjustReps(-1) }, plus: { wc.adjustReps(1) })

                        Button { wc.completeSet() } label: {
                            Label("Complete set", systemImage: "checkmark")
                                .fontWeight(.semibold).frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent).tint(Color.lime).foregroundStyle(.black)

                        ProgressView(value: Double(live.completedCount), total: Double(max(live.sets.count, 1)))
                            .tint(Color.lime)
                        Text("\(live.completedCount)/\(live.sets.count) sets")
                            .font(.caption2).foregroundStyle(.secondary)

                        Button(finishing ? "Finishing…" : "Finish") {
                            finishing = true
                            Task {
                                let m = await metrics.end()
                                wc.finishWorkout(metrics: m)
                            }
                        }
                        .disabled(finishing)
                        .font(.caption).foregroundStyle(.secondary)
                        .padding(.top, 2)
                    }.padding()
                }
            } else {
                Text("Workout complete").padding()
            }
        }
        .onAppear { metrics.start() }
        .onDisappear { Task { _ = await metrics.end() } }
    }

    private func stepper(label: String, emphasized: Bool,
                         minus: @escaping () -> Void, plus: @escaping () -> Void) -> some View {
        HStack(spacing: 8) {
            Button { minus() } label: { Image(systemName: "minus") }.buttonStyle(.bordered)
            Text(label)
                .font(emphasized ? .title3 : .body).fontWeight(.medium).monospacedDigit()
                .frame(maxWidth: .infinity)
                .padding(.vertical, 6)
                .background(Color.card, in: RoundedRectangle(cornerRadius: 8))
            Button { plus() } label: { Image(systemName: "plus") }.buttonStyle(.bordered)
        }
    }
    private func fmt(_ w: Double) -> String { w == w.rounded() ? String(format: "%.0f", w) : String(format: "%.1f", w) }
}
