import Foundation

/// Single source of truth for the live workout, shared between app and widget
/// via the App Group. All live-session mutations go through here.
struct LiveWorkout: Codable, Equatable {
    var dayName: String
    var workoutName: String
    var startDate: Date
    var isPaused: Bool
    var weightUnit: String
    var weightStep: Double
    var repStep: Int

    var sets: [LiveSet]
    var cursor: Int           // index into `sets` of the current (first incomplete) set
    var restEndDate: Date?

    struct LiveSet: Codable, Equatable {
        var exerciseIndex: Int
        var exerciseName: String
        var setIndex: Int
        var setsTotalForExercise: Int
        var weight: Double
        var reps: Int
        var restSeconds: Int
        var completed: Bool
    }

    var completedCount: Int { sets.filter(\.completed).count }
    var isFinished: Bool { cursor >= sets.count }
    var current: LiveSet? { sets.indices.contains(cursor) ? sets[cursor] : nil }

    mutating func advanceCursor() {
        var i = cursor
        while i < sets.count && sets[i].completed { i += 1 }
        cursor = i
    }

    mutating func completeCurrentSet() {
        guard let s0 = current else { return }
        var s = s0
        s.completed = true
        sets[cursor] = s
        restEndDate = s.restSeconds > 0 ? Date().addingTimeInterval(TimeInterval(s.restSeconds)) : nil
        advanceCursor()
    }
    mutating func adjustWeight(_ delta: Double) {
        guard current != nil else { return }
        sets[cursor].weight = max(0, sets[cursor].weight + delta)
    }
    mutating func adjustReps(_ delta: Int) {
        guard current != nil else { return }
        sets[cursor].reps = max(0, sets[cursor].reps + delta)
    }
    mutating func skipRest() { restEndDate = nil }
    mutating func addRest(_ seconds: Int) {
        restEndDate = (restEndDate ?? Date()).addingTimeInterval(TimeInterval(seconds))
    }
}

enum SharedWorkoutStore {
    static let suite = "group.com.whitesolutions.bulkup"
    private static let key = "live_workout"
    static let darwinName = "com.whitesolutions.bulkup.liveWorkoutChanged"

    private static var defaults: UserDefaults { UserDefaults(suiteName: suite)! }

    static func load() -> LiveWorkout? {
        guard let data = defaults.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(LiveWorkout.self, from: data)
    }

    static func save(_ w: LiveWorkout?) {
        if let w, let data = try? JSONEncoder().encode(w) {
            defaults.set(data, forKey: key)
        } else {
            defaults.removeObject(forKey: key)
        }
    }

    // MARK: Pure mutations (used by intents AND the app)
    static func completeCurrentSet() { guard var w = load(), w.current != nil else { return }; w.completeCurrentSet(); save(w) }
    static func adjustWeight(_ delta: Double) { guard var w = load(), w.current != nil else { return }; w.adjustWeight(delta); save(w) }
    static func adjustReps(_ delta: Int) { guard var w = load(), w.current != nil else { return }; w.adjustReps(delta); save(w) }
    static func skipRest() { guard var w = load() else { return }; w.skipRest(); save(w) }
    static func addRest(_ seconds: Int) { guard var w = load() else { return }; w.addRest(seconds); save(w) }
}

#if DEBUG
extension SharedWorkoutStore {
    static func runSelfCheck() {
        var w = LiveWorkout(
            dayName: "Lunes", workoutName: "Push", startDate: Date(), isPaused: false,
            weightUnit: "kg", weightStep: 2.5, repStep: 1,
            sets: [
                .init(exerciseIndex: 0, exerciseName: "Press", setIndex: 0, setsTotalForExercise: 2,
                      weight: 40, reps: 10, restSeconds: 60, completed: false),
                .init(exerciseIndex: 0, exerciseName: "Press", setIndex: 1, setsTotalForExercise: 2,
                      weight: 40, reps: 10, restSeconds: 60, completed: false),
            ],
            cursor: 0, restEndDate: nil
        )
        assert(w.current?.setIndex == 0 && !w.isFinished)
        w.sets[0].completed = true; w.advanceCursor()
        assert(w.cursor == 1, "cursor should skip completed set")
        w.sets[1].completed = true; w.advanceCursor()
        assert(w.isFinished, "all sets done -> finished")
        assert(w.completedCount == 2)

        // Bug-3: a freshly seeded workout (cursor 0, no advance) shows the first
        // exercise even when its first set is pre-marked completed.
        let fresh = LiveWorkout(
            dayName: "Lunes", workoutName: "Push", startDate: Date(), isPaused: false,
            weightUnit: "kg", weightStep: 2.5, repStep: 1,
            sets: [
                .init(exerciseIndex: 0, exerciseName: "Press", setIndex: 0, setsTotalForExercise: 1,
                      weight: 40, reps: 10, restSeconds: 60, completed: true),
                .init(exerciseIndex: 1, exerciseName: "Curl", setIndex: 0, setsTotalForExercise: 1,
                      weight: 20, reps: 12, restSeconds: 60, completed: false),
            ],
            cursor: 0, restEndDate: nil
        )
        assert(fresh.current?.exerciseName == "Press", "fresh start must show the first exercise")

        // Slice 3a: LiveWorkout instance mutations.
        var lm = LiveWorkout(
            dayName: "Lunes", workoutName: "Push", startDate: Date(), isPaused: false,
            weightUnit: "kg", weightStep: 2.5, repStep: 1,
            sets: [
                .init(exerciseIndex: 0, exerciseName: "Press", setIndex: 0, setsTotalForExercise: 2,
                      weight: 40, reps: 10, restSeconds: 90, completed: false),
                .init(exerciseIndex: 0, exerciseName: "Press", setIndex: 1, setsTotalForExercise: 2,
                      weight: 40, reps: 10, restSeconds: 0, completed: false),
            ],
            cursor: 0, restEndDate: nil)
        lm.completeCurrentSet()
        assert(lm.sets[0].completed && lm.cursor == 1 && lm.restEndDate != nil, "complete advances + sets rest")
        lm.adjustWeight(-1000)
        assert(lm.sets[1].weight == 0, "weight clamps at 0")
        lm.adjustReps(5)
        assert(lm.sets[1].reps == 15, "reps adjust")
        lm.skipRest()
        assert(lm.restEndDate == nil, "skipRest nils restEndDate")
        lm.addRest(30)
        assert(lm.restEndDate != nil, "addRest sets restEndDate")
        lm.completeCurrentSet()
        assert(lm.isFinished, "second complete -> finished")
    }
}
#endif
