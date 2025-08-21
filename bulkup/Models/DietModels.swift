//
//  DietModels.swift
//  bulkup
//
//  Created by sebastian.blanco on 17/8/25.
//

import SwiftUI
import SwiftData
import Foundation

@Model
class DietDay {
    @Attribute(.unique) var id: String = UUID().uuidString
    var day: String
    var meals: [Meal] = []
    var supplements: [Supplement] = []
    
    // Para sincronización
    var planId: String?
    var needsSync: Bool = false
    var lastSynced: Date?
    
    init(day: String, meals: [Meal] = [], supplements: [Supplement] = []) {
        self.day = day
        self.meals = meals
        self.supplements = supplements
        self.needsSync = true
    }
}

@Model
class Meal {
    var type: String
    var time: String
    var date: String?
    var notes: String?
    var options: [MealOption] = []
    var conditions: MealConditions?
    var order: Int = 0 // <-- Default value for migration safety
    var orderIndex: Int { order } // Add computed property for clarity
    
    init(type: String, time: String, date: String? = nil, notes: String? = nil, order: Int = 0) {
        self.type = type
        self.time = time
        self.date = date
        self.notes = notes
        self.order = order
    }
}

@Model
class MealOption {
    var optionDescription: String
    var ingredientsRaw: String = ""
    var instructionsRaw: String = ""

    var ingredients: [String] {
        get { ingredientsRaw.isEmpty ? [] : ingredientsRaw.components(separatedBy: "\n") }
        set { ingredientsRaw = newValue.joined(separator: "\n") }
    }
    var instructions: [String] {
        get { instructionsRaw.isEmpty ? [] : instructionsRaw.components(separatedBy: "\n") }
        set { instructionsRaw = newValue.joined(separator: "\n") }
    }

    init(optionDescription: String, ingredients: [String] = [], instructions: [String] = []) {
        self.optionDescription = optionDescription
        self.ingredientsRaw = ingredients.joined(separator: "\n")
        self.instructionsRaw = instructions.joined(separator: "\n")
    }
}

@Model
class MealConditions {
    var trainingDays: ConditionalMeal?
    var nonTrainingDays: ConditionalMeal?
    
    init(trainingDays: ConditionalMeal? = nil, nonTrainingDays: ConditionalMeal? = nil) {
        self.trainingDays = trainingDays
        self.nonTrainingDays = nonTrainingDays
    }
}

@Model
class ConditionalMeal {
    var mealDescription: String
    var ingredientsRaw: String = ""
    var ingredients: [String] {
        get { ingredientsRaw.isEmpty ? [] : ingredientsRaw.components(separatedBy: "\n") }
        set { ingredientsRaw = newValue.joined(separator: "\n") }
    }
    init(mealDescription: String, ingredients: [String] = []) {
        self.mealDescription = mealDescription
        self.ingredientsRaw = ingredients.joined(separator: "\n")
    }
}

@Model
class Supplement {
    var name: String
    var dosage: String
    var timing: String
    var frequency: String
    var notes: String?
    
    init(name: String, dosage: String, timing: String, frequency: String, notes: String? = nil) {
        self.name = name
        self.dosage = dosage
        self.timing = timing
        self.frequency = frequency
        self.notes = notes
    }
}

@Model
class User {
    @Attribute(.unique) var id: String
    var email: String
    var name: String
    var hasActiveSubscription: Bool = false
    var subscriptionExpiryDate: Date?
    var createdAt: Date
    var token: String?
    
    init(id: String, email: String, name: String, token: String? = nil) {
        self.id = id
        self.email = email
        self.name = name
        self.createdAt = Date()
        self.token = token
    }
}
