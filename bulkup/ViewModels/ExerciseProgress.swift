import Foundation

/// One week's aggregated metrics for a single exercise.
struct ExerciseWeekPoint: Identifiable, Equatable {
    let weekStart: String       // "yyyy-MM-dd"
    let topSet: Double          // heaviest set that week
    let volume: Double          // Σ weight × reps
    let est1RM: Double          // max hybrid 1RM over the week's sets
    let bestReps: Int
    var isWeightPR: Bool = false
    var isEst1RMPR: Bool = false
    var id: String { weekStart }
}

enum ExerciseProgress {
    /// Diacritic-folded, lowercased — matches the app's weight-key convention.
    static func fold(_ s: String) -> String {
        s.folding(options: .diacriticInsensitive, locale: .current)
            .lowercased()
            .trimmingCharacters(in: .whitespaces)
    }

    /// Per-week points for ONE exercise, sorted by weekStart ascending, with PR flags
    /// (a week is a PR if it beats every earlier week on top set / est-1RM).
    static func points(from records: [ServerWeightHistoryItem],
                       exerciseName: String, exerciseIndex: Int) -> [ExerciseWeekPoint] {
        let target = fold(exerciseName)
        var byWeek: [String: ExerciseWeekPoint] = [:]
        for r in records where fold(r.exerciseName) == target {
            let sets = r.sets ?? []
            guard !sets.isEmpty else { continue }
            let top = sets.map(\.weight).max() ?? 0
            let vol = sets.reduce(0.0) { $0 + $1.weight * Double($1.reps) }
            let e1rm = sets.compactMap { RMCalculator.calculateHybridRM(weight: $0.weight, reps: $0.reps) }.max() ?? top
            let reps = sets.map(\.reps).max() ?? 0
            // server already dedupes per week+exercise; if duplicates slip through, keep the heavier
            if let ex = byWeek[r.weekStart], ex.topSet >= top { continue }
            byWeek[r.weekStart] = ExerciseWeekPoint(
                weekStart: r.weekStart, topSet: top, volume: vol, est1RM: e1rm, bestReps: reps)
        }
        var pts = byWeek.values.sorted { $0.weekStart < $1.weekStart }
        var maxTop = -1.0, max1RM = -1.0
        for i in pts.indices {
            if pts[i].topSet > maxTop { pts[i].isWeightPR = true; maxTop = pts[i].topSet }
            if pts[i].est1RM > max1RM { pts[i].isEst1RMPR = true; max1RM = pts[i].est1RM }
        }
        return pts
    }
}

#if DEBUG
extension ExerciseProgress {
    static func runSelfCheck() {
        func item(_ week: String, _ name: String, _ sets: [(Double, Int)]) -> ServerWeightHistoryItem {
            ServerWeightHistoryItem(
                weekStart: week, day: "lunes", exerciseName: name, exerciseIndex: 0,
                sets: sets.enumerated().map { ServerWeightSet(setNumber: $0.offset, weight: $0.element.0, reps: $0.element.1) },
                planId: "p1")
        }
        let recs = [
            item("2026-05-04", "Press Banca", [(60, 10), (62.5, 8)]),
            item("2026-05-11", "Press Banca", [(65, 8), (60, 10)]),
            item("2026-05-18", "Press Banca", [(62.5, 6)]),     // dip — not a PR
            item("2026-05-25", "Press Bánca", [(70, 5)]),        // accented name still matches; PR
            item("2026-05-11", "Sentadilla", [(100, 5)]),        // other exercise, ignored
        ]
        let p = points(from: recs, exerciseName: "press banca", exerciseIndex: 0)
        assert(p.count == 4, "4 weeks for Press Banca")
        assert(p.map(\.weekStart) == ["2026-05-04", "2026-05-11", "2026-05-18", "2026-05-25"], "sorted by week")
        assert(p[0].topSet == 62.5 && p[1].topSet == 65 && p[3].topSet == 70, "top set per week")
        assert(p[0].volume == 60*10 + 62.5*8, "volume Σ w×reps")
        assert(p[0].isWeightPR && p[1].isWeightPR && !p[2].isWeightPR && p[3].isWeightPR, "PR flags")
        // Week 4 (70×5) is a WEIGHT PR but NOT a 1RM PR — fewer reps estimates a lower 1RM
        // than week 2 (65×8), so the two PR kinds genuinely diverge.
        assert(p[3].isWeightPR && !p[3].isEst1RMPR, "70×5 is a weight PR but not a 1RM PR")
        assert(p[1].isEst1RMPR && p[1].est1RM > p[3].est1RM, "the 65×8 week holds the est-1RM PR")
    }
}
#endif
