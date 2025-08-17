//
//  DietApp.swift
//  bulkup
//
//  Created by sebastian.blanco on 17/8/25.
//


@main
struct DietApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [DietDay.self, User.self, Meal.self, MealOption.self, MealConditions.self, ConditionalMeal.self, Supplement.self])
    }
}