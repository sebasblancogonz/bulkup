//
//  DietFidelityManager.swift
//  bulkup
//
//  Diet fidelity by calories: scores how close each day's intake was to the
//  active plan's per-day calorie target over the last 30 days.
//

import Foundation

enum DietFidelity {
    /// window: the calendar days to average. consumed[day] = logged kcal for skipped days.
    /// target(day) = plan kcal target for that day (nil/0 → can't score a *logged* day → excluded).
    /// A day with no log counts as 1.0 (followed). Returns percent 0–100, or nil if no includable day.
    static func percent(window: [Date], consumed: [Date: Int], target: (Date) -> Int?) -> Double? {
        var sum = 0.0
        var n = 0
        for day in window {
            if let c = consumed[day] {
                guard let t = target(day), t > 0 else { continue }  // logged day, unknown target → exclude
                sum += max(0.0, 1.0 - abs(Double(c) - Double(t)) / Double(t))
                n += 1
            } else {
                sum += 1.0  // no log → followed
                n += 1
            }
        }
        return n == 0 ? nil : (sum / Double(n)) * 100.0
    }

    #if DEBUG
    static func runSelfCheck() {
        let cal = Calendar(identifier: .gregorian)
        let d0 = cal.startOfDay(for: Date())
        let d1 = cal.date(byAdding: .day, value: -1, to: d0)!
        // no logs → 100
        assert(percent(window: [d0, d1], consumed: [:], target: { _ in 2000 }) == 100)
        // exact target on a logged day → 100
        assert(percent(window: [d0], consumed: [d0: 2000], target: { _ in 2000 }) == 100)
        // double target → 0
        assert(percent(window: [d0], consumed: [d0: 4000], target: { _ in 2000 }) == 0)
        // logged day, unknown target → excluded; only day → nil
        assert(percent(window: [d0], consumed: [d0: 4000], target: { _ in nil }) == nil)
    }
    #endif
}

@MainActor
final class DietFidelityManager: ObservableObject {
    static let shared = DietFidelityManager()

    @Published var skippedDays: [SkippedDay] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let api = APIService.shared

    private static let ymd: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()

    // Spanish weekday for matching the plan day (FIXED es locale — NOT the app locale).
    private static let weekday: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "es_ES")
        f.dateFormat = "EEEE"
        return f
    }()

    func load() async {
        isLoading = true
        defer { isLoading = false }
        do {
            skippedDays = try await api.getSkippedDays()
        } catch {
            errorMessage = "No se pudieron cargar los días"
        }
    }

    func logSkippedDay(date: Date, description: String) async -> Bool {
        do {
            let entry = try await api.logSkippedDay(date: Self.ymd.string(from: date), description: description)
            skippedDays.removeAll { $0.date == entry.date }
            skippedDays.insert(entry, at: 0)
            return true
        } catch {
            errorMessage = "No se pudo estimar las calorías"
            return false
        }
    }

    func deleteSkippedDay(_ day: SkippedDay) async {
        do {
            try await api.deleteSkippedDay(date: day.date)
            skippedDays.removeAll { $0.date == day.date }
        } catch {
            errorMessage = "No se pudo eliminar"
        }
    }

    /// 30-day fidelity using the active plan (DietManager) day targets.
    func fidelityPercent(dietData: [DietDay]) -> Double? {
        let cal = Calendar(identifier: .gregorian)
        let today = cal.startOfDay(for: Date())
        let window = (0..<30).compactMap { cal.date(byAdding: .day, value: -$0, to: today) }
        var consumed: [Date: Int] = [:]
        for s in skippedDays {
            if let d = Self.ymd.date(from: s.date) {
                consumed[cal.startOfDay(for: d)] = s.calories
            }
        }
        func norm(_ s: String) -> String {
            s.lowercased().folding(options: .diacriticInsensitive, locale: Locale(identifier: "es_ES"))
        }
        return DietFidelity.percent(window: window, consumed: consumed) { day in
            let wd = norm(Self.weekday.string(from: day))
            guard let match = dietData.first(where: { norm($0.day) == wd }) else { return nil }
            return match.macroCalories
        }
    }
}
