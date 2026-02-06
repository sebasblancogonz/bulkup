//
//  ModelContainer+Configuration.swift
//  bulkup
//
//  Created by sebastianblancogonz on 17/8/25.
//

import Foundation
import SwiftData

// MARK: - Configuración del ModelContainer
extension ModelContainer {
    static let bulkUpContainer: ModelContainer = {
        let schema = Schema([
            DietDay.self,
            User.self,
            Meal.self,
            MealOption.self,
            MealConditions.self,
            ConditionalMeal.self,
            Supplement.self,
            TrainingDay.self,
            Exercise.self,
            WeightRecord.self,
            WeightSet.self,
        ])

        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            cloudKitDatabase: .none
        )

        do {
            return try ModelContainer(
                for: schema,
                configurations: [modelConfiguration]
            )
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()
}
