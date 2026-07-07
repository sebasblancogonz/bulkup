import Foundation
import SwiftData

/// Post-workout sensations: an emoji rating, sensation tags, an optional note,
/// and locally-stored photo filenames. One record per workout day (per plan);
/// finishing the same day again updates it. All local — never uploaded.
@Model
final class WorkoutFeedback {
    @Attribute(.unique) var id: String  // "\(planId ?? "local")_\(normalizedDayName)"
    var dayName: String
    var planId: String?
    var rating: Int  // 1...5 (emoji index), 0 = unset
    var tagsRaw: String  // "|"-joined
    var note: String?
    var photoFilenamesRaw: String  // "|"-joined filenames in Documents/WorkoutPhotos
    var updatedAt: Date

    init(
        id: String,
        dayName: String,
        planId: String?,
        rating: Int = 0,
        tagsRaw: String = "",
        note: String? = nil,
        photoFilenamesRaw: String = "",
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.dayName = dayName
        self.planId = planId
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

    /// Stable id for a workout day so finishing/viewing resolve to the same record.
    static func makeID(planId: String?, dayName: String) -> String {
        let day = dayName.lowercased().folding(options: .diacriticInsensitive, locale: Locale(identifier: "es_ES"))
        return "\(planId ?? "local")_\(day)"
    }
}
