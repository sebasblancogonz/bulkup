//
//  ExerciseAlternatives.swift
//  bulkup
//
//  Suggests substitutes for a plan exercise (e.g. the machine is occupied)
//  with the same muscle impact and stimulus, ranked from the exercise DB.
//

import Foundation

enum ExerciseAlternatives {

    /// Find the DB entry for a plan exercise. Plan names are free text — typed
    /// by the user or extracted from a PDF — so after an exact folded-name pass
    /// we fall back to token matching: at least 60% of the plan name's tokens
    /// (stopwords removed, naive plural-stripped) must appear in a DB name,
    /// best coverage wins, closest-length name breaks ties.
    static func match(planName: String, in all: [RMExerciseFull]) -> RMExerciseFull? {
        let target = fold(planName)
        if let exact = all.first(where: { fold($0.name) == target || fold($0.nameEs) == target }) {
            return exact
        }

        let targetTokens = tokens(target)
        guard !targetTokens.isEmpty else { return nil }

        var best: (exercise: RMExerciseFull, coverage: Double, extra: Int)?
        for ex in all {
            for candidateName in [fold(ex.name), fold(ex.nameEs)] {
                let candidateTokens = tokens(candidateName)
                guard !candidateTokens.isEmpty else { continue }
                let covered = targetTokens.filter { t in
                    candidateTokens.contains { tokenMatches(t, $0) }
                }.count
                let coverage = Double(covered) / Double(targetTokens.count)
                let extra = candidateTokens.filter { c in
                    !targetTokens.contains { tokenMatches(c, $0) }
                }.count
                if coverage > (best?.coverage ?? 0) ||
                    (coverage == best?.coverage && extra < best!.extra) {
                    best = (ex, coverage, extra)
                }
            }
        }
        if let best, best.coverage >= 0.6 { return best.exercise }
        return nil
    }

    /// Meaningful word set of a folded name (stopwords removed).
    private static let stopwords: Set<String> = [
        "de", "con", "en", "el", "la", "los", "las", "al", "del", "y", "a", "un", "una",
        "of", "with", "the", "on", "in", "and", "to"
    ]
    private static func tokens(_ folded: String) -> Set<String> {
        Set(
            folded.split(whereSeparator: { !$0.isLetter && !$0.isNumber })
                .map(String.init)
                .filter { !stopwords.contains($0) }
        )
    }

    /// Plural/inflection-tolerant token equality: "sentadilla(s)", "raise(s)",
    /// "extension(es)" all match. ponytail: prefix + ≤2 trailing chars; a real
    /// stemmer if PDF plans still miss too often.
    private static func tokenMatches(_ a: String, _ b: String) -> Bool {
        if a == b { return true }
        let (short, long) = a.count <= b.count ? (a, b) : (b, a)
        return short.count >= 4 && long.hasPrefix(short) && long.count - short.count <= 2
    }

    /// Top substitutes for `current`: same first primary muscle (required),
    /// then scored by same mechanic (+2), same force (+1), and *different*
    /// equipment (+1 — the trigger is "my machine is taken").
    static func rank(for current: RMExerciseFull, in all: [RMExerciseFull], limit: Int = 3) -> [RMExerciseFull] {
        guard let muscle = current.primaryMuscles?.first else { return [] }

        let scored: [(RMExerciseFull, Int)] = all.compactMap { candidate in
            guard candidate.id != current.id,
                  candidate.primaryMuscles?.first == muscle,
                  candidate.category == current.category // strength ↔ strength, not stretching
            else { return nil }
            var score = 0
            if let m = candidate.mechanic, m == current.mechanic { score += 2 }
            if let f = candidate.force, f == current.force { score += 1 }
            if candidate.equipment != current.equipment { score += 1 }
            return (candidate, score)
        }

        return scored
            .sorted { $0.1 != $1.1 ? $0.1 > $1.1 : $0.0.name < $1.0.name }
            .prefix(limit)
            .map { $0.0 }
    }

    private static func fold(_ s: String) -> String {
        s.lowercased().folding(options: .diacriticInsensitive, locale: .current)
            .trimmingCharacters(in: .whitespaces)
    }
}

#if DEBUG
extension ExerciseAlternatives {
    private static func ex(_ id: String, name: String, nameEs: String? = nil, muscle: String,
                           mechanic: String? = "compound", force: String? = "push",
                           equipment: String? = "barbell", category: String? = "strength") -> RMExerciseFull {
        RMExerciseFull(
            id: id, name: name, nameEs: nameEs ?? name,
            force: force, forceEs: nil, level: nil, levelEs: nil,
            mechanic: mechanic, mechanicEs: nil,
            equipment: equipment, equipmentEs: nil,
            primaryMuscles: [muscle], primaryMusclesEs: nil,
            secondaryMuscles: nil, secondaryMusclesEs: nil,
            instructions: nil, instructionsEs: nil,
            category: category, categoryEs: nil, images: nil
        )
    }

    static func runSelfCheck() {
        let bench = ex("bench", name: "Barbell Bench Press", nameEs: "Press de banca", muscle: "chest")
        let db = ex("db-press", name: "Dumbbell Bench Press", muscle: "chest", equipment: "dumbbell")
        let machine = ex("m-press", name: "Machine Press", muscle: "chest", equipment: "machine")
        let fly = ex("fly", name: "Dumbbell Fly", muscle: "chest", mechanic: "isolation", equipment: "dumbbell")
        let squat = ex("squat", name: "Squat", muscle: "quadriceps")
        let stretch = ex("stretch", name: "Chest Stretch", muscle: "chest", category: "stretching")
        let all = [bench, db, machine, fly, squat, stretch]

        // Folded-name matching hits English and Spanish forms.
        assert(match(planName: "press de banca", in: all)?.id == "bench", "matches folded Spanish name")
        assert(match(planName: "Barbell Bench Press", in: all)?.id == "bench", "matches English name")
        assert(match(planName: "no existe", in: all) == nil, "unknown name -> nil")

        // Fuzzy matching: plan names are free text (typed or PDF-extracted).
        assert(match(planName: "Press banca", in: all)?.id == "bench",
               "stopwords ignored: 'Press banca' hits 'Press de banca'")
        assert(match(planName: "PRESS DE BANCA CON BARRA", in: all)?.id == "bench",
               "extra words still hit the closest name")
        let squats = ex("squat2", name: "Barbell Squat", nameEs: "Sentadilla con barra", muscle: "quadriceps")
        assert(match(planName: "Sentadillas", in: all + [squats])?.id != nil,
               "plural tolerated: Sentadillas -> Sentadilla")
        assert(match(planName: "Curl de biceps", in: all) == nil,
               "half-overlapping name (fly/curl world) must not false-match")
        let curlFem = ex("curl-fem", name: "Leg Curl", nameEs: "Curl femoral", muscle: "hamstrings")
        assert(match(planName: "Curl de biceps", in: all + [curlFem]) == nil,
               "'Curl de biceps' must not match 'Curl femoral' (coverage 50% < 60%)")

        let ranked = rank(for: bench, in: all)
        assert(!ranked.contains { $0.id == "bench" }, "never suggests itself")
        assert(!ranked.contains { $0.id == "squat" }, "different muscle excluded")
        assert(!ranked.contains { $0.id == "stretch" }, "different category excluded")
        assert(ranked.first?.id == "db-press" || ranked.first?.id == "m-press",
               "same mechanic+force, different equipment ranks first")
        assert(ranked.contains { $0.id == "fly" }, "isolation variant still suggested, ranked lower")
        assert(ranked.last?.id == "fly", "lower score sorts last")
        assert(rank(for: bench, in: all, limit: 1).count == 1, "limit respected")
    }
}
#endif
