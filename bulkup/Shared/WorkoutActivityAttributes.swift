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

        // Progress
        var completedSets: Int
        var totalSets: Int

        // Rest
        var isResting: Bool
        var restEndDate: Date?

        // Terminal
        var isFinished: Bool
    }

    var dayName: String
}
