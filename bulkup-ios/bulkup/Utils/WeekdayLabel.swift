import Foundation

/// Localizes a plan's `day` value for display.
///
/// Plan day values are stored canonically in Spanish (lunes, martes, …) because
/// the app matches the current weekday — formatted in Spanish — against them for
/// "today's workout" and diet compliance. This maps that canonical value (or an
/// English source value) to the label in the app's current language, leaving
/// non-weekday labels (e.g. "Día 1", "Push") capitalized as-is.
enum WeekdayLabel {
    private static let canonical: [String: String] = [
        "lunes": "Lunes", "monday": "Lunes",
        "martes": "Martes", "tuesday": "Martes",
        "miercoles": "Miércoles", "wednesday": "Miércoles",
        "jueves": "Jueves", "thursday": "Jueves",
        "viernes": "Viernes", "friday": "Viernes",
        "sabado": "Sábado", "saturday": "Sábado",
        "domingo": "Domingo", "sunday": "Domingo",
    ]

    /// Full localized weekday name, or the original (capitalized, underscores → spaces) if not a weekday.
    static func localized(_ raw: String) -> String {
        let norm = raw
            .lowercased()
            .folding(options: .diacriticInsensitive, locale: Locale(identifier: "es_ES"))
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard let key = canonical[norm] else {
            return raw.replacingOccurrences(of: "_", with: " ").capitalized
        }
        // NSLocalizedString resolves against the swizzled main bundle, so it
        // follows the in-app language switch.
        return NSLocalizedString(key, comment: "weekday name")
    }

    /// Short label (first 3 letters of the localized weekday, uppercased) for calendar chips.
    static func abbreviated(_ raw: String) -> String {
        String(localized(raw).prefix(3)).uppercased()
    }
}
