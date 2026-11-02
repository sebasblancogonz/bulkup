import Foundation
import SwiftData

@MainActor
final class WorkoutFeedbackManager: ObservableObject {
    static let shared = WorkoutFeedbackManager(modelContext: ModelContainer.bulkUpContainer.mainContext)

    /// Predefined sensation tags shown as chips.
    static let availableTags = ["Energía", "Fuerza", "Fatiga", "Dolor", "Ánimo"]

    /// Emoji rating scale, index 1...5.
    static let ratingEmojis = ["😫", "😕", "😐", "🙂", "💪"]

    static func emoji(for rating: Int) -> String? {
        guard rating >= 1, rating <= ratingEmojis.count else { return nil }
        return ratingEmojis[rating - 1]
    }

    private var modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    private func fetch(id: String) -> WorkoutFeedback? {
        let descriptor = FetchDescriptor<WorkoutFeedback>(predicate: #Predicate { $0.id == id })
        return try? modelContext.fetch(descriptor).first
    }

    /// Feedback for a workout day in the week starting `weekStart` ("yyyy-MM-dd").
    /// A record saved before the key included the week is adopted by the week
    /// it was last edited in (and re-keyed), so nothing already written is lost.
    func feedback(planId: String?, dayName: String, weekStart: String) -> WorkoutFeedback? {
        let id = WorkoutFeedback.makeID(planId: planId, dayName: dayName, weekStart: weekStart)
        if let record = fetch(id: id) { return record }

        let legacyID = WorkoutFeedback.legacyID(planId: planId, dayName: dayName)
        guard let legacy = fetch(id: legacyID),
              WorkoutFeedback.weekString(for: legacy.updatedAt) == weekStart else { return nil }
        legacy.id = id
        legacy.weekStart = weekStart
        try? modelContext.save()
        return legacy
    }

    /// Creates or updates the feedback for a workout day in a given week.
    func save(
        planId: String?,
        dayName: String,
        weekStart: String,
        rating: Int,
        tags: [String],
        note: String?,
        photoFilenames: [String]
    ) {
        let id = WorkoutFeedback.makeID(planId: planId, dayName: dayName, weekStart: weekStart)
        let existing = feedback(planId: planId, dayName: dayName, weekStart: weekStart)
        let record = existing ?? WorkoutFeedback(id: id, dayName: dayName, planId: planId, weekStart: weekStart)
        record.rating = rating
        record.tags = tags
        record.note = (note?.isEmpty ?? true) ? nil : note
        record.photoFilenames = photoFilenames
        record.updatedAt = Date()
        if existing == nil {
            modelContext.insert(record)
        }
        try? modelContext.save()
    }

    #if DEBUG
    static func runSelfCheck() {
        let f = WorkoutFeedback(id: "t", dayName: "lunes", planId: nil)
        f.tags = ["Energía", "Dolor"]
        f.photoFilenames = ["a.jpg", "b.jpg"]
        assert(f.tags == ["Energía", "Dolor"], "tags round-trip")
        assert(f.photoFilenames.count == 2, "photos round-trip")
        f.tags = []
        assert(f.tags.isEmpty && f.tagsRaw.isEmpty, "empty tags")
        assert(makeIDStable(), "id stable across accent/case")
    }

    private static func makeIDStable() -> Bool {
        WorkoutFeedback.makeID(planId: "p", dayName: "Miércoles", weekStart: "2026-09-14")
            == WorkoutFeedback.makeID(planId: "p", dayName: "miercoles", weekStart: "2026-09-14")
        && WorkoutFeedback.makeID(planId: "p", dayName: "lunes", weekStart: "2026-09-14")
            != WorkoutFeedback.makeID(planId: "p", dayName: "lunes", weekStart: "2026-09-07")
        && WorkoutFeedback.weekString(for: DateComponents(calendar: .init(identifier: .gregorian),
                                                          year: 2026, month: 9, day: 18).date!) == "2026-09-14"
    }
    #endif
}
