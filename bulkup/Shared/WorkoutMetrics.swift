import Foundation

/// HealthKit summary captured by the watch at workout finish.
struct WorkoutMetrics: Codable, Equatable {
    var avgHeartRate: Int        // bpm, 0 if unavailable
    var maxHeartRate: Int        // bpm, 0 if unavailable
    var activeEnergyKcal: Double // total kcal
}
