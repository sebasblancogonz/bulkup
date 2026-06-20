import Foundation

/// Completion-based weekly diet compliance: how many of the meals the plan
/// expects over the last 7 days have been marked done.
///
/// The bug this fixes: the backend computed completed/total only over days
/// that had tracking records, so a single-template plan ("same every day")
/// with one day marked collapsed to 100%. Here the *expected* denominator
/// comes from the plan applied across all 7 days; completed comes from the
/// server's 7-day count.
enum DietCompliance {
    /// Expected trackable meals over the last 7 calendar days for the active plan.
    /// - Single-template plan (one DietDay, e.g. "diario"/"Dieta Semanal") → applies to every day.
    /// - Multi-day plan → each of the last 7 days matched to its weekday's plan day (Spanish-folded).
    /// - Phase/period plans (days that don't map to weekdays) contribute 0.
    static func expectedMealsLast7(
        dietData: [DietDay],
        today: Date = Date(),
        calendar: Calendar = Calendar(identifier: .gregorian)
    ) -> Int {
        guard !dietData.isEmpty else { return 0 }

        if dietData.count == 1 {
            return dietData[0].meals.count * 7
        }

        let fmt = DateFormatter()
        // Plan day names are Spanish data keys — match in es_ES, NOT the app locale.
        fmt.locale = Locale(identifier: "es_ES")
        fmt.dateFormat = "EEEE"
        func norm(_ s: String) -> String {
            s.lowercased().folding(options: .diacriticInsensitive, locale: Locale(identifier: "es_ES"))
        }

        let mealsByDay = Dictionary(
            dietData.map { (norm($0.day), $0.meals.count) },
            uniquingKeysWith: { first, _ in first }
        )

        var total = 0
        for offset in 0..<7 {
            guard let date = calendar.date(byAdding: .day, value: -offset, to: today) else { continue }
            total += mealsByDay[norm(fmt.string(from: date))] ?? 0
        }
        return total
    }

    /// Weekly compliance percent (0–100), or nil if the plan expects no measurable meals.
    static func percent(completedLast7: Int, expectedLast7: Int) -> Double? {
        guard expectedLast7 > 0 else { return nil }
        return min(1.0, Double(completedLast7) / Double(expectedLast7)) * 100
    }

    #if DEBUG
    static func runSelfCheck() {
        // Single-template plan, 5 meals → expected 35 over 7 days.
        let single = [DietDay(day: "diario")]
        single[0].meals = (0..<5).map { Meal(type: "m\($0)", time: "08:00", order: $0) }
        assert(expectedMealsLast7(dietData: single) == 35)

        // Empty plan → 0 expected → nil percent.
        assert(expectedMealsLast7(dietData: []) == 0)
        assert(percent(completedLast7: 0, expectedLast7: 0) == nil)

        // One day done of an everyday plan is NOT 100%.
        assert(percent(completedLast7: 5, expectedLast7: 35) != 100)
        // Exact and clamp.
        assert(percent(completedLast7: 35, expectedLast7: 35) == 100)
        assert(percent(completedLast7: 40, expectedLast7: 35) == 100)
    }
    #endif
}
