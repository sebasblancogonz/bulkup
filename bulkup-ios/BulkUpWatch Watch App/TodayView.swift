import SwiftUI

/// Today on the wrist: the workout's name, its size, the exercises as rows in
/// one lifted slab, the lime CTA, then the day's meals as a checklist.
struct TodayView: View {
    @EnvironmentObject var wc: WatchWCManager
    let plan: TodaysPlan?
    let meals: [MealStatus]

    private var totalSets: Int { plan?.exercises.reduce(0) { $0 + $1.sets } ?? 0 }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                if let plan, !plan.exercises.isEmpty {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(plan.dayDisplay)
                            .font(.brandTitle(.title3))
                            .foregroundStyle(Brand.textPrimary)
                            .fixedSize(horizontal: false, vertical: true)
                        Text("\(plan.exercises.count) ejercicios · \(totalSets) series")
                            .font(.footnote.monospacedDigit())
                            .foregroundStyle(Brand.textSecondary)
                    }

                    WatchPrimaryButton(title: "Empezar entreno") {
                        wc.send(.startWorkout(day: plan.dayDisplay))
                    }

                    WatchSlab {
                        ForEach(Array(plan.exercises.enumerated()), id: \.element.orderIndex) { i, ex in
                            VStack(alignment: .leading, spacing: 1) {
                                Text(ex.name)
                                    .font(.caption)
                                    .foregroundStyle(Brand.textPrimary)
                                    .lineLimit(2)
                                    .fixedSize(horizontal: false, vertical: true)
                                Text("\(ex.sets) × \(ex.reps)")
                                    .font(.caption2.monospacedDigit())
                                    .foregroundStyle(Brand.textSecondary)
                                    .lineLimit(1)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.vertical, 8).padding(.horizontal, 10)
                            if i < plan.exercises.count - 1 { WatchSeparator() }
                        }
                    }
                }

                if !meals.isEmpty {
                    Text("Comidas")
                        .font(.headline)
                        .foregroundStyle(Brand.textPrimary)
                        .padding(.top, plan == nil ? 0 : 6)

                    WatchSlab {
                        ForEach(Array(meals.enumerated()), id: \.element.order) { i, meal in
                            Button {
                                wc.toggleMeal(order: meal.order)
                            } label: {
                                HStack(spacing: 8) {
                                    WatchCheck(done: meal.completed)
                                    Text(meal.name)
                                        .font(.caption)
                                        .lineLimit(2)
                                        .strikethrough(meal.completed, color: Brand.textSecondary)
                                        .foregroundStyle(meal.completed ? Brand.textSecondary : Brand.textPrimary)
                                    Spacer(minLength: 4)
                                    if let t = meal.time, !t.isEmpty {
                                        Text(t)
                                            .font(.caption2.monospacedDigit())
                                            .foregroundStyle(Brand.textTertiary)
                                    }
                                }
                                .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                                .padding(.vertical, 4).padding(.horizontal, 10)
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                            if i < meals.count - 1 { WatchSeparator() }
                        }
                    }
                }
            }
            .padding(.horizontal, 2)
        }
    }
}
