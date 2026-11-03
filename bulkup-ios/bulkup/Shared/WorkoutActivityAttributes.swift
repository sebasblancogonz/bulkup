import ActivityKit
import Foundation

struct WorkoutActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Identity / header
        var workoutName: String
        var startDate: Date          // drives elapsed Text(timerInterval:)
        var isPaused: Bool

        // Current-set cursor
        var exerciseName: String
        var setIndex: Int            // 0-based
        var setsTotal: Int

        // Current working values
        var weight: Double
        var reps: Int
        var weightUnit: String       // "kg" or "lb"
        var needsWeight: Bool        // weight-tracking set at 0 — completion blocked

        // Progress
        var completedSets: Int
        var totalSets: Int

        // Rest
        var isResting: Bool
        var restEndDate: Date?
        /// When the rest began (end minus the completed set's rest), so the
        /// card can drain a `ProgressView(timerInterval:)` without updates.
        var restStartDate: Date?

        // Terminal
        var isFinished: Bool
    }

    var dayName: String
}

extension WorkoutActivityAttributes.ContentState {
    init(from w: LiveWorkout) {
        let cur = w.current
        self.init(
            workoutName: w.workoutName, startDate: w.startDate, isPaused: w.isPaused,
            exerciseName: cur?.exerciseName ?? "", setIndex: cur?.setIndex ?? 0,
            setsTotal: cur?.setsTotalForExercise ?? 0,
            weight: cur?.weight ?? 0, reps: cur?.reps ?? 0, weightUnit: w.weightUnit,
            needsWeight: cur?.needsWeight ?? false,
            completedSets: w.completedCount, totalSets: w.sets.count,
            isResting: w.restEndDate.map { $0 > Date() } ?? false,
            restEndDate: w.restEndDate, restStartDate: w.restStartDate, isFinished: w.isFinished
        )
    }
}
