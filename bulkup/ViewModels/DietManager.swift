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
    
    func loadActiveDietPlan(userId: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            let response = try await apiService.loadActiveDietPlan(userId: userId)
            
            if let serverDietData = response.dietData {
                // Convertir datos del servidor a modelos locales
                let localDietDays = convertServerDataToLocal(serverDietData)
                setDietData(localDietDays, planId: response.planId)
            } else {
                // No hay plan activo
                setDietData([])
            }
        } catch {
            errorMessage = error.localizedDescription
            print("Error loading active diet plan: \(error)")
        }
        
        isLoading = false
    }
    
    private func convertServerDataToLocal(_ serverData: [ServerDietDay]) -> [DietDay] {
        return serverData.map { serverDay in
            let localDay = DietDay(day: serverDay.day)
            
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
                            ingredients: trainingDays.ingredients
                        )
                    }
                    
                    if let nonTrainingDays = serverConditions.nonTrainingDays {
                        localConditions.nonTrainingDays = ConditionalMeal(
                            mealDescription: nonTrainingDays.description,
                            ingredients: nonTrainingDays.ingredients
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
