import SwiftUI

struct TodayView: View {
    @EnvironmentObject var wc: WatchWCManager
    let plan: TodaysPlan?
    let meals: [MealStatus]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 10) {
                Text("TODAY")
                    .font(.caption2).fontWeight(.semibold).tracking(1.5)
                    .foregroundStyle(Color.lime)

                if let plan, !plan.exercises.isEmpty {
                    Text(plan.dayDisplay).font(.headline)
                        .fixedSize(horizontal: false, vertical: true)

                    ForEach(plan.exercises, id: \.orderIndex) { ex in
                        HStack(alignment: .top, spacing: 8) {
                            Text(ex.name)
                                .font(.caption).lineLimit(2)
                                .fixedSize(horizontal: false, vertical: true)
                            Spacer(minLength: 4)
                            Text("\(ex.sets)×\(ex.reps)")
                                .font(.caption2).fontWeight(.medium).monospacedDigit()
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, 6).padding(.horizontal, 9)
                        .background(Color.card, in: RoundedRectangle(cornerRadius: 9))
                    }

                    Button {
                        wc.send(.startWorkout(day: plan.dayDisplay))
                    } label: {
                        Label("Start workout", systemImage: "play.fill")
                            .fontWeight(.semibold).frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Color.lime).foregroundStyle(.black)
                    .padding(.top, 6)
                }

                if !meals.isEmpty {
                    Text("MEALS")
                        .font(.caption2).fontWeight(.semibold).tracking(1.5)
                        .foregroundStyle(Color.lime)
                        .padding(.top, plan == nil ? 0 : 8)

                    ForEach(meals, id: \.order) { meal in
                        Button {
                            wc.toggleMeal(order: meal.order)
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: meal.completed ? "checkmark.circle.fill" : "circle")
                                    .foregroundStyle(meal.completed ? Color.lime : .secondary)
                                VStack(alignment: .leading, spacing: 1) {
                                    Text(meal.name)
                                        .font(.caption).lineLimit(2)
                                        .strikethrough(meal.completed)
                                        .foregroundStyle(meal.completed ? .secondary : .primary)
                                    if let t = meal.time, !t.isEmpty {
                                        Text(t).font(.caption2).foregroundStyle(.secondary)
                                    }
                                }
                                Spacer(minLength: 0)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.vertical, 6).padding(.horizontal, 9)
                            .background(Color.card, in: RoundedRectangle(cornerRadius: 9))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }.padding()
        }
    }
}
