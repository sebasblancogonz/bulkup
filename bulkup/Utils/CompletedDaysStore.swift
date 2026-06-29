import Foundation

/// Persists a set of completed training day keys to UserDefaults.
///
/// A day is "completed" when the user finishes it via the per-set checkmarks,
/// regardless of whether any weight was logged (handles bodyweight-only days).
///
/// Key format: "\(planId)|\(weekStartString)|\(normalizedDay)"
/// where weekStartString is Monday of the week formatted as "yyyy-MM-dd"
/// and normalizedDay is diacritic-folded + lowercased day name.
/// Nil planId is stored as an empty string.
enum CompletedDaysStore {

    private static let defaultsKey = "completedTrainingDays"

    // MARK: - Private helpers

    private static let weekFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()

    /// Returns the ISO-8601 Monday of the week containing `date`, formatted
    /// as "yyyy-MM-dd" — identical to TrainingManager.getCurrentWeekString().
    private static func weekStartString(for date: Date) -> String {
        var calendar = Calendar(identifier: .iso8601)
        calendar.locale = Locale.current
        let components = calendar.dateComponents(
            [.yearForWeekOfYear, .weekOfYear],
            from: date
        )
        let monday = calendar.date(from: components) ?? date
        return weekFormatter.string(from: monday)
    }

    /// Normalises a day name the same way TrainingManager.hasWeightForExercise
    /// does: lowercased then diacritic-folded (Miércoles → miercoles).
    private static func normalizeDay(_ day: String) -> String {
        day.lowercased()
            .folding(options: .diacriticInsensitive, locale: .current)
            .trimmingCharacters(in: .whitespaces)
    }

    private static func makeKey(planId: String?, weekStart: Date, day: String) -> String {
        let pid = planId ?? ""
        let week = weekStartString(for: weekStart)
        let normDay = normalizeDay(day)
        return "\(pid)|\(week)|\(normDay)"
    }

    // MARK: - Public API

    /// Marks a training day as completed.
    static func markCompleted(planId: String?, weekStart: Date, day: String) {
        let key = makeKey(planId: planId, weekStart: weekStart, day: day)
        var stored = UserDefaults.standard.stringArray(forKey: defaultsKey) ?? []
        if !stored.contains(key) {
            stored.append(key)
            UserDefaults.standard.set(stored, forKey: defaultsKey)
        }
    }

    /// Returns true if the day has been marked completed via `markCompleted`.
    static func isCompleted(planId: String?, weekStart: Date, day: String) -> Bool {
        let key = makeKey(planId: planId, weekStart: weekStart, day: day)
        let stored = UserDefaults.standard.stringArray(forKey: defaultsKey) ?? []
        return stored.contains(key)
    }

    // MARK: - Self-check

#if DEBUG
    static func runSelfCheck() {
        // Round-trip: mark → isCompleted returns true
        let planId = "plan_test_42"
        let week = Date()
        let day = "Miércoles"
        markCompleted(planId: planId, weekStart: week, day: day)
        assert(isCompleted(planId: planId, weekStart: week, day: day),
               "CompletedDaysStore: marked day should be completed")

        // Diacritic normalization: accented and bare form are the same key
        assert(isCompleted(planId: planId, weekStart: week, day: "miercoles"),
               "CompletedDaysStore: diacritic-folded day should match")

        // Different day is NOT completed
        assert(!isCompleted(planId: planId, weekStart: week, day: "viernes"),
               "CompletedDaysStore: different day should not be completed")

        // Different plan is NOT completed
        assert(!isCompleted(planId: "other_plan", weekStart: week, day: day),
               "CompletedDaysStore: different planId should not be completed")

        // Different week is NOT completed
        let otherWeek = Calendar.current.date(byAdding: .day, value: -7, to: week)!
        assert(!isCompleted(planId: planId, weekStart: otherWeek, day: day),
               "CompletedDaysStore: different week should not be completed")

        // nil planId round-trip
        let nilDay = "Lunes"
        markCompleted(planId: nil, weekStart: week, day: nilDay)
        assert(isCompleted(planId: nil, weekStart: week, day: nilDay),
               "CompletedDaysStore: nil planId round-trip should work")

        // Clean up test keys so they don't pollute real data
        var stored = UserDefaults.standard.stringArray(forKey: defaultsKey) ?? []
        let testKeys: Set<String> = [
            makeKey(planId: planId, weekStart: week, day: day),
            makeKey(planId: nil, weekStart: week, day: nilDay),
        ]
        stored.removeAll { testKeys.contains($0) }
        UserDefaults.standard.set(stored, forKey: defaultsKey)

        print("✅ CompletedDaysStore.runSelfCheck passed")
    }
#endif
}
