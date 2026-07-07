//
//  SmartFileUpload.swift
//  bulkup
//
//  Created by sebastianblancogonz on 20/8/25.
//
//  Server-model → SwiftData-model conversion initializers. The smart-upload
//  UI that previously lived here was dead (never instantiated) and removed.
//

import Foundation

// MARK: - SwiftData Model Extensions for Server Model Conversion
extension DietDay {
    convenience init(from serverDay: ServerDietDay) {
        self.init(day: serverDay.day)
        self.meals = serverDay.meals.map { Meal(from: $0) }
        self.supplements = serverDay.supplements?.map { Supplement(from: $0) } ?? []
    }
}

extension Meal {
    convenience init(from serverMeal: ServerMeal) {
        self.init(
            type: serverMeal.type,
            time: serverMeal.time,
            date: serverMeal.date,
            notes: serverMeal.notes
        )

        // Convert options
        if let serverOptions = serverMeal.options {
            self.options = serverOptions.map { MealOption(from: $0) }
        }

        // Convert conditions
        if let serverConditions = serverMeal.conditions {
            self.conditions = MealConditions(from: serverConditions)
        }
    }
}

extension MealOption {
    convenience init(from serverOption: ServerMeal.MealOptionData) {
        self.init(
            optionDescription: serverOption.description,
            ingredients: serverOption.ingredients,
            instructions: serverOption.instructions ?? []
        )
    }
}

extension MealConditions {
    convenience init(from serverConditions: ServerMealConditions) {
        self.init()

        if let trainingDays = serverConditions.trainingDays {
            self.trainingDays = ConditionalMeal(from: trainingDays)
        }

        if let nonTrainingDays = serverConditions.nonTrainingDays {
            self.nonTrainingDays = ConditionalMeal(from: nonTrainingDays)
        }
    }
}

extension ConditionalMeal {
    convenience init(from serverMeal: ServerConditionalMeal) {
        self.init(
            mealDescription: serverMeal.description,
            ingredients: serverMeal.ingredients ?? []
        )
    }
}

extension Supplement {
    convenience init(from serverSupplement: ServerSupplement) {
        self.init(
            name: serverSupplement.name,
            dosage: serverSupplement.dosage,
            timing: serverSupplement.timing,
            frequency: serverSupplement.frequency,
            notes: serverSupplement.notes
        )
    }
}

extension TrainingDay {
    convenience init(from serverDay: ServerTrainingDay) {
        self.init(
            day: serverDay.day,
            workoutName: serverDay.workoutName
        )
        self.exercises = serverDay.output?.enumerated().map { index, exercise in
            Exercise(from: exercise, orderIndex: index)
        } ?? []
    }
}

extension Exercise {
    convenience init(from serverExercise: ServerExercise, orderIndex: Int = 0) {
        self.init(
            name: serverExercise.name,
            sets: serverExercise.sets,
            reps: serverExercise.reps,
            restSeconds: serverExercise.restSeconds,
            notes: serverExercise.notes,
            tempo: serverExercise.tempo,
            weightTracking: serverExercise.weightTracking,
            orderIndex: orderIndex
        )
    }
}
