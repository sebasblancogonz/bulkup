import SwiftUI

/// One set at a time: the exercise, the set line and the clock, the metrics
/// when HealthKit is running, the kilos and reps as raised mono fields, the
/// lime CTA, the progress rule, and a quiet way out.
struct ActiveWorkoutView: View {
    @EnvironmentObject var wc: WatchWCManager
    @EnvironmentObject var metrics: WorkoutMetricsManager
    @State private var finishing = false
    let live: LiveWorkout

    var body: some View {
        Group {
            if let restEnd = live.restEndDate, restEnd > Date() {
                RestTimerView(end: restEnd, start: live.restStartDate, next: live.current, unit: live.weightUnit)
            } else if let s = live.current {
                ScrollView {
                    VStack(spacing: 6) {
                        VStack(spacing: 2) {
                            Text(s.exerciseName)
                                .font(.brandTitle(.headline))
                                .foregroundStyle(Brand.textPrimary)
                                .multilineTextAlignment(.center)
                                .fixedSize(horizontal: false, vertical: true)
                                .frame(maxWidth: .infinity)
                            HStack(spacing: 6) {
                                Text("Serie \(s.setIndex + 1) de \(s.setsTotalForExercise)")
                                    .font(.footnote.monospacedDigit())
                                    .foregroundStyle(Brand.textSecondary)
                                Text("·").foregroundStyle(Brand.textTertiary)
                                WatchElapsed(start: live.startDate)
                            }
                        }

                        WatchValueField(value: BrandFormat.weight(s.weight), unit: LocalizedStringKey(live.weightUnit),
                                        size: 22,
                                        minus: { wc.adjustWeight(-live.weightStep) },
                                        plus: { wc.adjustWeight(live.weightStep) })
                        WatchValueField(value: "\(s.reps)", unit: "reps", size: 18, height: 40,
                                        minus: { wc.adjustReps(-1) }, plus: { wc.adjustReps(1) })

                        WatchPrimaryButton(title: s.needsWeight ? "Ajusta el peso" : "Completar serie",
                                           enabled: !s.needsWeight) {
                            wc.completeSet()
                        }

                        if metrics.isRunning {
                            HStack(spacing: 14) {
                                HStack(spacing: 4) {
                                    Image(systemName: "heart.fill").font(.system(size: 10, weight: .semibold))
                                    Text("\(metrics.heartRate)")
                                }
                                HStack(spacing: 4) {
                                    Image(systemName: "flame.fill").font(.system(size: 10, weight: .semibold))
                                    Text("\(Int(metrics.activeEnergy)) kcal")
                                }
                            }
                            .font(.caption2.monospacedDigit())
                            .foregroundStyle(Brand.textSecondary)
                            .padding(.top, 2)
                        }

                        VStack(spacing: 5) {
                            GeometryReader { geo in
                                let fraction = live.sets.isEmpty ? 0 : Double(live.completedCount) / Double(live.sets.count)
                                ZStack(alignment: .leading) {
                                    Capsule().fill(Brand.line)
                                    Capsule().fill(Brand.lime).frame(width: max(0, geo.size.width * fraction))
                                }
                            }
                            .frame(height: 3)
                            Text("\(live.completedCount)/\(live.sets.count) series")
                                .font(.caption2.monospacedDigit())
                                .foregroundStyle(Brand.textTertiary)
                        }
                        .padding(.top, 2)

                        Button {
                            finishing = true
                            Task {
                                let m = await metrics.end()
                                wc.finishWorkout(metrics: m)
                            }
                        } label: {
                            Text(finishing ? "Guardando..." : "Finalizar")
                                .font(.footnote.weight(.semibold))
                                .foregroundStyle(Brand.textSecondary)
                                .frame(maxWidth: .infinity)
                                .frame(height: 44)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .disabled(finishing)
                    }
                    .padding(.horizontal, 2)
                }
            } else {
                VStack(spacing: 10) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 8, style: .continuous).fill(Brand.sky)
                        Image(systemName: "checkmark")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundStyle(Brand.onLime)
                    }
                    .frame(width: 32, height: 32)
                    Text("Entreno completado")
                        .font(.headline)
                        .foregroundStyle(Brand.textPrimary)
                }
                .padding()
            }
        }
        .onAppear { metrics.start() }
        .onDisappear { Task { _ = await metrics.end() } }
    }
}
