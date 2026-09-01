import Foundation

/// Watch → phone actions. The phone routes each into its existing workout methods.
enum WatchMessage: Codable, Equatable {
    case startWorkout(day: String)   // day = the display day (TrainingDay.day)
    case completeSet(exerciseIndex: Int, setIndex: Int, weight: Double, reps: Int)
    case uncompleteSet
    case adjustWeight(delta: Double)
    case adjustReps(delta: Int)
    case skipRest
    case addRest(seconds: Int)
    case finishWorkout(live: LiveWorkout?, metrics: WorkoutMetrics?)
    // Absolute (not a toggle) so duplicate deliveries are idempotent; carries the
    // date the watch saw so a message queued overnight can't mark the wrong day.
    case setMealCompleted(order: Int, date: String, completed: Bool)
    case requestSync                 // ask the phone to re-send context
}

/// One meal of today's diet, for the watch list.
struct MealStatus: Codable, Equatable {
    var order: Int
    var name: String
    var time: String?
    var completed: Bool
}

/// Phone → watch state. Coalesced latest-state via updateApplicationContext.
struct WatchContext: Codable, Equatable {
    var seq: Int
    var todaysPlan: TodaysPlan?
    var live: LiveWorkout?           // from SharedWorkoutStore.swift (same target)
    // Optional so payloads from older phone builds still decode.
    var mealsDate: String?           // "yyyy-MM-dd" the meals list refers to
    var meals: [MealStatus]?
}

enum WatchSync {
    // nonisolated: read from WCSession delegate methods + the @Sendable errorHandler
    // closure, which are nonisolated even under the watch target's MainActor-by-default.
    nonisolated static let messageKey = "msg"    // WCSession payload key for a WatchMessage
    nonisolated static let contextKey = "ctx"    // WCSession payload key for a WatchContext

    static func encode<T: Encodable>(_ value: T) -> Data? { try? JSONEncoder().encode(value) }
    static func decode<T: Decodable>(_ type: T.Type, from data: Data?) -> T? {
        guard let data else { return nil }
        return try? JSONDecoder().decode(type, from: data)
    }

    #if DEBUG
    static func runSelfCheck() {
        // WatchMessage round-trip for every case.
        let sampleLive = LiveWorkout(
            dayName: "lunes", workoutName: "Push", startDate: Date(timeIntervalSince1970: 1_700_000_000),
            isPaused: false, weightUnit: "kg", weightStep: 2.5, repStep: 1,
            sets: [LiveWorkout.LiveSet(exerciseIndex: 0, exerciseName: "Press", setIndex: 0,
                   setsTotalForExercise: 1, weight: 40, reps: 10, restSeconds: 60, completed: true, weightTracking: true)],
            cursor: 1, restEndDate: nil)
        let msgs: [WatchMessage] = [
            .startWorkout(day: "Lunes"), .completeSet(exerciseIndex: 0, setIndex: 0, weight: 40, reps: 10), .uncompleteSet,
            .adjustWeight(delta: 2.5), .adjustReps(delta: -1), .skipRest,
            .addRest(seconds: 30),
            .finishWorkout(live: sampleLive, metrics: WorkoutMetrics(avgHeartRate: 142, maxHeartRate: 171, activeEnergyKcal: 320.5)),
            .finishWorkout(live: nil, metrics: nil),
            .setMealCompleted(order: 2, date: "2026-07-23", completed: true),
            .requestSync,
        ]
        for m in msgs {
            let back = decode(WatchMessage.self, from: encode(m))
            assert(back == m, "WatchMessage round-trip failed for \(m)")
        }
        // WatchContext round-trip (with a sample LiveWorkout + TodaysPlan).
        let live = LiveWorkout(
            dayName: "Lunes", workoutName: "Push", startDate: Date(), isPaused: false,
            weightUnit: "kg", weightStep: 2.5, repStep: 1,
            sets: [.init(exerciseIndex: 0, exerciseName: "Press", setIndex: 0, setsTotalForExercise: 1,
                         weight: 40, reps: 10, restSeconds: 60, completed: false, weightTracking: true)],
            cursor: 0, restEndDate: nil)
        let plan = TodaysPlan(planId: "p1", dayName: "lunes", dayDisplay: "Lunes", weekStart: "2026-06-22",
            exercises: [.init(orderIndex: 0, name: "Press", sets: 3, reps: "10, 8, 6", restSeconds: 90, weightTracking: true)])
        let ctx = WatchContext(seq: 7, todaysPlan: plan, live: live, mealsDate: "2026-07-23",
                               meals: [MealStatus(order: 1, name: "Desayuno", time: "08:00", completed: true)])
        let backCtx = decode(WatchContext.self, from: encode(ctx))
        assert(backCtx == ctx, "WatchContext round-trip failed")
        // Old-phone payload (no meals fields) must still decode on the watch.
        let legacy = "{\"seq\":1}".data(using: .utf8)
        assert(decode(WatchContext.self, from: legacy)?.meals == nil, "legacy context must decode with nil meals")
    }
    #endif
}
