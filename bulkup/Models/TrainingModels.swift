//
//  TrainingModels.swift
//  bulkup
//
//  Created by sebastian.blanco on 18/8/25.
//

import SwiftUI
import SwiftData
import Foundation

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
    var reps: String // Puede ser "12" o "8-12"
    var restSeconds: Int
    var notes: String?
    var tempo: String?
    var weightTracking: Bool
    var orderIndex: Int = 0 // Para mantener orden
    
    init(name: String, sets: Int, reps: String, restSeconds: Int, notes: String? = nil, tempo: String? = nil, weightTracking: Bool = false, orderIndex: Int = 0) {
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
    var weekStart: String // Formato "2025-01-15"
    var createdAt: Date = Date()
    var updatedAt: Date = Date()
    var needsSync: Bool = false
    
    init(userId: String, planId: String, day: String, exerciseName: String, exerciseIndex: Int, sets: [WeightSet] = [], note: String = "", weekStart: String) {
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
    let force: String?
    let level: String?
    let mechanic: String?
    let equipment: String?
    let primaryMuscles: [String]?
    let secondaryMuscles: [String]?
    let instructions: [String]?
    let category: String?
    
    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case name, force, level, mechanic, equipment
        case primaryMuscles, secondaryMuscles, instructions, category
    }
}
