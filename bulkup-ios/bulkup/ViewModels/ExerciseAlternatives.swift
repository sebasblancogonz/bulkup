//
//  ExerciseAlternatives.swift
//  bulkup
//
//  Suggests substitutes for a plan exercise (e.g. the machine is occupied)
//  with the same muscle impact and stimulus, ranked from the exercise DB.
//

import Foundation

enum ExerciseAlternatives {

    /// Find the DB entry for a plan exercise by folded name (plans may store
    /// either the English or Spanish name).
    static func match(planName: String, in all: [RMExerciseFull]) -> RMExerciseFull? {
        let target = fold(planName)
        return all.first { fold($0.name) == target || fold($0.nameEs) == target }
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
