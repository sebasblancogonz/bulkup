//
//  TrainingModels.swift
//  bulkup
//
//  Created by sebastianblancogonz on 18/8/25.
//

import Foundation
import SwiftData
import SwiftUI

// MARK: - Modelos de entrenamiento
@Model
class TrainingDay {
    @Attribute(.unique) var id: String = UUID().uuidString
    var day: String
    var workoutName: String?
    var exercises: [Exercise] = []

    // Para sincronización
    var planId: String?
    var needsSync: Bool = false
    var lastSynced: Date?

    init(day: String, workoutName: String? = nil, exercises: [Exercise] = []) {
        self.day = day
        self.workoutName = workoutName
        self.exercises = exercises
        self.needsSync = true
    }
}

@Model
class Exercise {
    var name: String
    var sets: Int
    var reps: String  // Puede ser "12" o "8-12"
    var restSeconds: Int
    var notes: String?
    var tempo: String?
    var weightTracking: Bool
    var orderIndex: Int = 0  // Para mantener orden

    init(
        name: String,
        sets: Int,
        reps: String,
        restSeconds: Int,
        notes: String? = nil,
        tempo: String? = nil,
        weightTracking: Bool = false,
        orderIndex: Int = 0
    ) {
        self.name = name
        self.sets = sets
        self.reps = reps
        self.restSeconds = restSeconds
        self.notes = notes
        self.tempo = tempo
        self.weightTracking = weightTracking
        self.orderIndex = orderIndex
    }
}

@Model
class WeightRecord {
    @Attribute(.unique) var id: String = UUID().uuidString
    var userId: String
    var planId: String
    var day: String
    var exerciseName: String
    var exerciseIndex: Int
    var sets: [WeightSet] = []
    var note: String = ""
    var weekStart: String  // Formato "2025-01-15"
    var createdAt: Date = Date()
    var updatedAt: Date = Date()
    var needsSync: Bool = false

    init(
        userId: String,
        planId: String,
        day: String,
        exerciseName: String,
        exerciseIndex: Int,
        sets: [WeightSet] = [],
        note: String = "",
        weekStart: String
    ) {
        self.userId = userId
        self.planId = planId
        self.day = day
        self.exerciseName = exerciseName
        self.exerciseIndex = exerciseIndex
        self.sets = sets
        self.note = note
        self.weekStart = weekStart
        self.needsSync = true
    }
}

@Model
class WeightSet {
    var setNumber: Int
    var weight: Double
    var reps: Int

    init(setNumber: Int = 0, weight: Double, reps: Int) {
        self.setNumber = setNumber
        self.weight = weight
        self.reps = reps
    }
}

struct RMExerciseFull: Identifiable, Codable {
    let id: String
    let name: String
    let nameEs: String
    let force: String?
    let forceEs: String?
    let level: String?
    let levelEs: String?
    let mechanic: String?
    let mechanicEs: String?
    let equipment: String?
    let equipmentEs: String?
    let primaryMuscles: [String]?
    let primaryMusclesEs: [String]?
    let secondaryMuscles: [String]?
    let secondaryMusclesEs: [String]?
    let instructions: [String]?
    let instructionsEs: [String]?
    let category: String?
    let categoryEs: String?
    let images: [String]?

    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case nameEs, forceEs, levelEs, mechanicEs, equipmentEs,
            primaryMusclesEs, secondaryMusclesEs, instructionsEs, categoryEs
        case images
        case name, force, level, mechanic, equipment
        case primaryMuscles, secondaryMuscles, instructions, category
    }
}

// Language-aware accessors: the backend ships every field in English and
// Spanish; pick the field that matches the app language (falling back to the
// other when a translation is missing) so the explorer follows the in-app switch.
extension RMExerciseFull {
    // Resolve the app language without touching the @MainActor LanguageManager,
    // so these accessors can be read from any context. Mirrors its logic:
    // explicit override ("en"/"es") wins, else fall back to the device language.
    private var isEnglish: Bool {
        switch UserDefaults.standard.string(forKey: "app_language") {
        case "en": return true
        case "es": return false
        default: return (Locale.preferredLanguages.first ?? "es").lowercased().hasPrefix("en")
        }
    }

    private func pick(_ en: String?, _ es: String?) -> String? {
        let primary = isEnglish ? en : es
        let fallback = isEnglish ? es : en
        let value = (primary?.isEmpty == false) ? primary : fallback
        guard let value, !value.isEmpty else { return nil }
        return value
    }

    private func pickList(_ en: [String]?, _ es: [String]?) -> [String] {
        let primary = isEnglish ? en : es
        let fallback = isEnglish ? es : en
        return (primary?.isEmpty == false ? primary : fallback) ?? []
    }

    var localizedName: String { pick(name, nameEs) ?? name }
    var localizedCategory: String? { pick(category, categoryEs)?.capitalized }
    var localizedForce: String? { pick(force, forceEs)?.capitalized }
    var localizedLevel: String? { pick(level, levelEs)?.capitalized }
    var localizedMechanic: String? { pick(mechanic, mechanicEs)?.capitalized }
    var localizedEquipment: String? { pick(equipment, equipmentEs)?.capitalized }
    var localizedPrimaryMuscles: [String] { pickList(primaryMuscles, primaryMusclesEs).map { $0.capitalized } }
    var localizedSecondaryMuscles: [String] { pickList(secondaryMuscles, secondaryMusclesEs).map { $0.capitalized } }
    var localizedInstructions: [String] { pickList(instructions, instructionsEs) }
}
