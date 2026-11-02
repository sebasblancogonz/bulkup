import Foundation
import SwiftData

/// Post-workout sensations: an emoji rating, sensation tags, an optional note,
/// and locally-stored photo filenames. One record per workout day per week
/// (per plan); editing the same day in the same week updates it. All local —
/// never uploaded.
@Model
final class WorkoutFeedback {
    @Attribute(.unique) var id: String  // "\(planId ?? "local")_\(weekStart)_\(normalizedDayName)"
    var dayName: String
    var planId: String?
    /// ISO week Monday, "yyyy-MM-dd". nil on records written before the key
    /// included the week; WorkoutFeedbackManager migrates those lazily.
    var weekStart: String?
    var rating: Int  // 1...5 (emoji index), 0 = unset
    var tagsRaw: String  // "|"-joined
    var note: String?
    var photoFilenamesRaw: String  // "|"-joined filenames in Documents/WorkoutPhotos
    var updatedAt: Date

    init(
        id: String,
        dayName: String,
        planId: String?,
        weekStart: String? = nil,
        rating: Int = 0,
        tagsRaw: String = "",
        note: String? = nil,
        photoFilenamesRaw: String = "",
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.dayName = dayName
        self.planId = planId
        self.weekStart = weekStart
        self.rating = rating
        self.tagsRaw = tagsRaw
        self.note = note
        self.photoFilenamesRaw = photoFilenamesRaw
        self.updatedAt = updatedAt
    }

    var tags: [String] {
        get { tagsRaw.isEmpty ? [] : tagsRaw.components(separatedBy: "|") }
        set { tagsRaw = newValue.joined(separator: "|") }
    }

    var photoFilenames: [String] {
        get { photoFilenamesRaw.isEmpty ? [] : photoFilenamesRaw.components(separatedBy: "|") }
        set { photoFilenamesRaw = newValue.joined(separator: "|") }
    }

    /// Stable id for a workout day in a given week, so finishing/viewing
    /// resolve to the same record. Without the week, every Monday overwrote
    /// the previous Monday's notes and photos.
    static func makeID(planId: String?, dayName: String, weekStart: String) -> String {
        "\(planId ?? "local")_\(weekStart)_\(normalizedDay(dayName))"
    }

    /// Id format used before the week was part of the key.
    static func legacyID(planId: String?, dayName: String) -> String {
        "\(planId ?? "local")_\(normalizedDay(dayName))"
    }

    static func normalizedDay(_ dayName: String) -> String {
        dayName.lowercased().folding(options: .diacriticInsensitive, locale: Locale(identifier: "es_ES"))
    }

    /// ISO-8601 Monday of the week containing `date`, "yyyy-MM-dd" (matches
    /// TrainingManager.getWeekStart + the weight keys).
    static func weekString(for date: Date) -> String {
        var calendar = Calendar(identifier: .iso8601)
        calendar.locale = Locale.current
        let components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)
        let monday = calendar.date(from: components) ?? date
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "yyyy-MM-dd"
        return f.string(from: monday)
    }
}
