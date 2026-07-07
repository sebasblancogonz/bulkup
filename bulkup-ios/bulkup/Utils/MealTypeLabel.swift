import Foundation

/// Localizes a meal's `type` for display. Plan meal types are stored in Spanish
/// ("Desayuno", "Comida 1", "Media mañana"…); this maps the known ones to the
/// app language, preserving a trailing number ("Comida 2" → "Lunch 2") and
/// leaving anything unrecognized capitalized as-is.
enum MealTypeLabel {
    // Canonical Spanish key (also a Localizable.xcstrings key with an EN value).
    private static let map: [String: String] = [
        "desayuno": "Desayuno",
        "media manana": "Media mañana",
        "almuerzo": "Almuerzo",
        "comida": "Comida",
        "merienda": "Merienda",
        "media tarde": "Media tarde",
        "cena": "Cena",
        "snack": "Snack",
        "pre entreno": "Pre-entreno",
        "preentreno": "Pre-entreno",
        "post entreno": "Post-entreno",
        "postentreno": "Post-entreno",
    ]

    static func localized(_ raw: String) -> String {
        let trimmed = raw.replacingOccurrences(of: "_", with: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        // Split off a trailing number, e.g. "Comida 1" → base "Comida", suffix " 1".
        var base = trimmed
        var suffix = ""
        if let r = trimmed.range(of: #"\s*\d+$"#, options: .regularExpression) {
            suffix = " " + trimmed[r].trimmingCharacters(in: .whitespaces)
            base = String(trimmed[..<r.lowerBound]).trimmingCharacters(in: .whitespaces)
        }

        let norm = base.lowercased()
            .folding(options: .diacriticInsensitive, locale: Locale(identifier: "es_ES"))
        guard let canon = map[norm] else {
            return base.capitalized + suffix
        }
        // NSLocalizedString resolves against the swizzled bundle → follows the switch.
        return NSLocalizedString(canon, comment: "meal type") + suffix
    }
}
