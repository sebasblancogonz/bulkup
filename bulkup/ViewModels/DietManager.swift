//
//  DietManager.swift
//  bulkup
//
//  Created by sebastianblancogonz on 17/8/25.
//

import Foundation
import SwiftData


@MainActor
class DietManager: ObservableObject {
    static let shared = DietManager(modelContext: ModelContainer.bulkUpContainer.mainContext)

    @Published var dietData: [DietDay] = []
    @Published var dietPlanId: String?
    @Published var activePlanName: String?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    public var modelContext: ModelContext // <-- Make public for external access
    private let apiService = APIService.shared
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        loadLocalDietData()
    }
    
    public func loadLocalDietData() {
        let descriptor = FetchDescriptor<DietDay>() // Remove sortBy to preserve API order
        
        do {
            dietData = try modelContext.fetch(descriptor)
            // Si hay datos, usar el planId del primero
            dietPlanId = dietData.first?.planId
        } catch {
            print("Error loading local diet data: \(error)")
            dietData = []
        }
    }
    
    func setDietData(_ newData: [DietDay], planId: String? = nil) {
        // Limpiar datos anteriores
        let descriptor = FetchDescriptor<DietDay>()
        do {
            let existingDays = try modelContext.fetch(descriptor)
            for day in existingDays {
                modelContext.delete(day)
            }
        } catch {
            print("Error clearing existing diet data: \(error)")
        }
        
        // Insertar nuevos datos
        for day in newData {
            day.planId = planId
            modelContext.insert(day)
        }
        
        do {
            try modelContext.save()
            self.dietData = newData
            self.dietPlanId = planId
        } catch {
            print("Error saving diet data: \(error)")
            self.errorMessage = "Error guardando datos de dieta"
        }
    }
    
    func loadActiveDietPlan(userId: String, retryCount: Int = 0) async {
        print("[DietManager] loadActiveDietPlan called for userId: \(userId) (attempt \(retryCount + 1))")
        isLoading = true
        errorMessage = nil

        do {
            let response = try await apiService.loadActiveDietPlan(userId: userId)
            print("[DietManager] Response received - dietData: \(response.dietData?.count ?? 0) days, planId: \(response.planId ?? "nil")")

            if let serverDietData = response.dietData, !serverDietData.isEmpty {
                let localDietDays = convertServerDataToLocal(serverDietData)
                setDietData(localDietDays, planId: response.planId)
                self.activePlanName = response.filename
                print("[DietManager] Diet data set: \(localDietDays.count) days")
            } else if retryCount < 3 {
                // Retry with delay - backend may not have persisted data yet
                let delay = UInt64((retryCount + 1) * 2) * 1_000_000_000
                print("[DietManager] No diet data yet, retrying in \((retryCount + 1) * 2)s...")
                try? await Task.sleep(nanoseconds: delay)
                isLoading = false
                await loadActiveDietPlan(userId: userId, retryCount: retryCount + 1)
                return
            } else {
                setDietData([])
                print("[DietManager] No diet data after \(retryCount + 1) attempts")
            }
        } catch {
            errorMessage = error.localizedDescription
            print("[DietManager] Error loading diet plan: \(error)")
        }

        isLoading = false
    }
    
    func clearAllData() {
        dietData = []
        dietPlanId = nil
        activePlanName = nil
        errorMessage = nil

        let descriptor = FetchDescriptor<DietDay>()
        do {
            let existingDays = try modelContext.fetch(descriptor)
            for day in existingDays {
                modelContext.delete(day)
            }
            try modelContext.save()
        } catch {
            print("Error clearing local diet data: \(error)")
        }
    }

    private func convertServerDataToLocal(_ serverData: [ServerDietDay]) -> [DietDay] {
        return serverData.map { serverDay in
            let localDay = DietDay(day: serverDay.day)

            // Map macros
            if let macros = serverDay.macros {
                localDay.hasMacros = true
                localDay.macroCalories = macros.calories
                localDay.macroProtein = macros.protein
                localDay.macroCarbs = macros.carbs
                localDay.macroFat = macros.fat
            }

            // Map cheat meal
            localDay.allowsCheatMeal = serverDay.allowsCheatMeal ?? false

            localDay.meals = serverDay.meals.enumerated().map { (idx, serverMeal) in
                let localMeal = Meal(
                    type: serverMeal.type,
                    time: serverMeal.time,
                    date: serverMeal.date,
                    notes: serverMeal.notes,
                    order: idx // <-- Set order from API index
                )
                
                if let serverOptions = serverMeal.options {
                    localMeal.options = serverOptions.map { serverOption in
                        MealOption(
                            optionDescription: serverOption.description,
                            ingredients: serverOption.ingredients, // Will be stored as string
                            instructions: serverOption.instructions ?? [] // Will be stored as string
                        )
                    }
                }
                
                // Manejar conditions si existen
                if let serverConditions = serverMeal.conditions {
                    let localConditions = MealConditions()
                    
                    if let trainingDays = serverConditions.trainingDays {
                        localConditions.trainingDays = ConditionalMeal(
                            mealDescription: trainingDays.description,
                            ingredients: trainingDays.ingredients ?? []
                        )
                    }

                    if let nonTrainingDays = serverConditions.nonTrainingDays {
                        localConditions.nonTrainingDays = ConditionalMeal(
                            mealDescription: nonTrainingDays.description,
                            ingredients: nonTrainingDays.ingredients ?? []
                        )
                    }
                    
                    localMeal.conditions = localConditions
                }
                
                return localMeal
            }
            
            if let serverSupplements = serverDay.supplements {
                localDay.supplements = serverSupplements.map { serverSupplement in
                    Supplement(
                        name: serverSupplement.name,
                        dosage: serverSupplement.dosage,
                        timing: serverSupplement.timing,
                        frequency: serverSupplement.frequency,
                        notes: serverSupplement.notes
                    )
                }
            }
            
            return localDay
        }
    }
}
