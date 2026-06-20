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

    func feedback(planId: String?, dayName: String) -> WorkoutFeedback? {
        let id = WorkoutFeedback.makeID(planId: planId, dayName: dayName)
        let descriptor = FetchDescriptor<WorkoutFeedback>(predicate: #Predicate { $0.id == id })
        return try? modelContext.fetch(descriptor).first
    }

    /// Creates or updates the feedback for a workout day.
    func save(
        planId: String?,
        dayName: String,
        rating: Int,
        tags: [String],
        note: String?,
        photoFilenames: [String]
    ) {
        let id = WorkoutFeedback.makeID(planId: planId, dayName: dayName)
        let existing = feedback(planId: planId, dayName: dayName)
        let record = existing ?? WorkoutFeedback(id: id, dayName: dayName, planId: planId)
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
        WorkoutFeedback.makeID(planId: "p", dayName: "Miércoles")
            == WorkoutFeedback.makeID(planId: "p", dayName: "miercoles")
    }
    #endif
}
