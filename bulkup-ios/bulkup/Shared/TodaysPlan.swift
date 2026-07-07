import Foundation

/// A lightweight, Codable snapshot of one day's plan, sent phone → watch so the
/// watch can show and start today's workout. (TrainingDay/Exercise are SwiftData
/// @Models and not shareable, so the phone maps them into these plain structs.)
struct TodaysPlan: Codable, Equatable {
    var planId: String
    var dayName: String      // diacritic-folded, lowercased (key form)
    var dayDisplay: String   // the human day label (TrainingDay.day) — sent back on start
    var weekStart: String    // yyyy-MM-dd
    var exercises: [PlanExercise]
}

struct PlanExercise: Codable, Equatable {
    var orderIndex: Int
    var name: String
    var sets: Int
    var reps: String
    var restSeconds: Int
    var weightTracking: Bool
}
