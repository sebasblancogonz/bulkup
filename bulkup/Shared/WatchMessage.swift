import Foundation

/// Watch → phone actions. The phone routes each into its existing workout methods.
enum WatchMessage: Codable, Equatable {
    case startWorkout(day: String)   // day = the display day (TrainingDay.day)
    case completeSet
    case uncompleteSet
    case adjustWeight(delta: Double)
    case adjustReps(delta: Int)
    case skipRest
    case addRest(seconds: Int)
    case finishWorkout
    case requestSync                 // ask the phone to re-send context
}

/// Phone → watch state. Coalesced latest-state via updateApplicationContext.
struct WatchContext: Codable, Equatable {
    var seq: Int
    var todaysPlan: TodaysPlan?
    var live: LiveWorkout?           // from SharedWorkoutStore.swift (same target)
}

enum WatchSync {
    static let messageKey = "msg"    // WCSession payload key for a WatchMessage
    static let contextKey = "ctx"    // WCSession payload key for a WatchContext

    static func encode<T: Encodable>(_ value: T) -> Data? { try? JSONEncoder().encode(value) }
    static func decode<T: Decodable>(_ type: T.Type, from data: Data?) -> T? {
        guard let data else { return nil }
        return try? JSONDecoder().decode(type, from: data)
    }

    #if DEBUG
    static func runSelfCheck() {
        // WatchMessage round-trip for every case.
        let msgs: [WatchMessage] = [
            .startWorkout(day: "Lunes"), .completeSet, .uncompleteSet,
            .adjustWeight(delta: 2.5), .adjustReps(delta: -1), .skipRest,
            .addRest(seconds: 30), .finishWorkout, .requestSync,
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
                         weight: 40, reps: 10, restSeconds: 60, completed: false)],
            cursor: 0, restEndDate: nil)
        let plan = TodaysPlan(planId: "p1", dayName: "lunes", dayDisplay: "Lunes", weekStart: "2026-06-22",
            exercises: [.init(orderIndex: 0, name: "Press", sets: 3, reps: "10, 8, 6", restSeconds: 90, weightTracking: true)])
        let ctx = WatchContext(seq: 7, todaysPlan: plan, live: live)
        let backCtx = decode(WatchContext.self, from: encode(ctx))
        assert(backCtx == ctx, "WatchContext round-trip failed")
    }
    #endif
}
