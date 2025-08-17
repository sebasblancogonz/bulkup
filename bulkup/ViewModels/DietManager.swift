@MainActor
class DietManager: ObservableObject {
    @Published var dietData: [DietDay] = []
    @Published var dietPlanId: String?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let modelContext: ModelContext
    private let apiService = APIService.shared
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        loadLocalDietData()
    }
    
    private func loadLocalDietData() {
        let descriptor = FetchDescriptor<DietDay>(
            sortBy: [SortDescriptor(\.day)]
        )
        
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
            
            localDay.meals = serverDay.meals.map { serverMeal in
                let localMeal = Meal(
                    type: serverMeal.type,
                    time: serverMeal.time,
                    date: serverMeal.date,
                    notes: serverMeal.notes
                )
                
                if let serverOptions = serverMeal.options {
                    localMeal.options = serverOptions.compactMap { option in
                        if let optionDict = option as? [String: Any],
                           let description = optionDict["description"] as? String {
                            let ingredients = optionDict["ingredients"] as? [String] ?? []
                            let instructions = optionDict["instructions"] as? [String] ?? []
                            return MealOption(
                                description: description,
                                ingredients: ingredients,
                                instructions: instructions
                            )
                        }
                        return nil
                    }
                }
                
                // Manejar conditions si existen
                if let serverConditions = serverMeal.conditions {
                    let localConditions = MealConditions()
                    
                    if let trainingDays = serverConditions.trainingDays {
                        localConditions.trainingDays = ConditionalMeal(
                            description: trainingDays.description,
                            ingredients: trainingDays.ingredients
                        )
                    }
                    
                    if let nonTrainingDays = serverConditions.nonTrainingDays {
                        localConditions.nonTrainingDays = ConditionalMeal(
                            description: nonTrainingDays.description,
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