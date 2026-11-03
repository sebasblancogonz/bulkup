//
//  WatchDesignPreview.swift
//  BulkUpWatch Watch App
//
//  Debug-only design harness. Launch the watch app with
//  `--design-preview <today|workout|rest|done>` and the screen renders with a
//  seeded context: no phone, no WatchConnectivity. Used to screenshot the
//  watch simulator for design review.
//

#if DEBUG
import Foundation

enum WatchDesignPreview {
    static var screen: String? {
        let args = CommandLine.arguments
        guard let i = args.firstIndex(of: "--design-preview"), i + 1 < args.count else { return nil }
        return args[i + 1]
    }

    static var isActive: Bool { screen != nil }

    @MainActor
    static func seed(into wc: WatchWCManager) {
        let plan = TodaysPlan(
            planId: "preview", dayName: "miercoles", dayDisplay: "Pecho y hombros", weekStart: "2026-11-02",
            exercises: [
                .init(orderIndex: 0, name: "Press inclinado en multipower", sets: 4, reps: "12, 10, 8, 6", restSeconds: 90, weightTracking: true),
                .init(orderIndex: 1, name: "Cruces en polea", sets: 4, reps: "12", restSeconds: 60, weightTracking: true),
                .init(orderIndex: 2, name: "Press militar con mancuernas", sets: 4, reps: "10, 8, 8, 6", restSeconds: 90, weightTracking: true),
                .init(orderIndex: 3, name: "Elevaciones laterales", sets: 3, reps: "15", restSeconds: 45, weightTracking: true),
                .init(orderIndex: 4, name: "Fondos en paralelas", sets: 3, reps: "máx", restSeconds: 60, weightTracking: false),
                .init(orderIndex: 5, name: "Face pull", sets: 3, reps: "15", restSeconds: 45, weightTracking: true),
            ]
        )
        let meals = [
            MealStatus(order: 0, name: "Desayuno", time: "08:00", completed: true),
            MealStatus(order: 1, name: "Media mañana", time: "11:00", completed: true),
            MealStatus(order: 2, name: "Comida", time: "14:00", completed: false),
            MealStatus(order: 3, name: "Merienda", time: "17:30", completed: false),
            MealStatus(order: 4, name: "Cena", time: "21:00", completed: false),
        ]

        var sets: [LiveWorkout.LiveSet] = []
        let weights: [[Double]] = [[60, 62.5, 65, 67.5], [15, 15, 15, 15], [20, 22.5, 22.5, 25]]
        let reps: [[Int]] = [[12, 10, 8, 6], [12, 12, 12, 12], [10, 8, 8, 6]]
        for (ei, ex) in plan.exercises.prefix(3).enumerated() {
            for si in 0..<ex.sets {
                sets.append(.init(exerciseIndex: ei, exerciseName: ex.name, setIndex: si,
                                  setsTotalForExercise: ex.sets, weight: weights[ei][si], reps: reps[ei][si],
                                  restSeconds: ex.restSeconds, completed: ei == 0 && si < 2, weightTracking: true))
            }
        }
        var live = LiveWorkout(
            dayName: "miercoles", workoutName: "Pecho y hombros",
            startDate: Date().addingTimeInterval(-1265), isPaused: false,
            weightUnit: "kg", weightStep: 2.5, repStep: 1,
            sets: sets, cursor: 2, restEndDate: nil
        )
        switch screen {
        case "rest":
            live.restEndDate = Date().addingTimeInterval(67)
        case "done":
            for i in sets.indices { live.sets[i].completed = true }
            live.cursor = sets.count
        default:
            break
        }

        wc.ctx = WatchContext(seq: 1, todaysPlan: plan, live: screen == "today" ? nil : live,
                              mealsDate: "2026-11-03", meals: meals)
        wc.live = screen == "today" ? nil : live
    }
}
#endif
