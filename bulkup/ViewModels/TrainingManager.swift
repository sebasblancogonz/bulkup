//
//  TrainingManager.swift
//  bulkup
//
//  Created by sebastian.blanco on 18/8/25.
//
import Foundation
import SwiftData

@MainActor
class TrainingManager: ObservableObject {
    @Published var trainingData: [TrainingDay] = []
    @Published var trainingPlanId: String?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // Estado para pesos
    @Published var weights: [String: Double] = [:]
    @Published var selectedWeek: Date = Date()
    @Published var exerciseNotes: [String: String] = [:]
    @Published var savedWeights: [String: Bool] = [:]
    @Published var savingWeights: [String: Bool] = [:]
    
    private let modelContext: ModelContext
    private let apiService = APIService.shared
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        loadLocalTrainingData()
        loadWeightsForWeek(selectedWeek)
    }
    
    private func loadLocalTrainingData() {
        let descriptor = FetchDescriptor<TrainingDay>(
            sortBy: [SortDescriptor(\.day)]
        )
        
        do {
            trainingData = try modelContext.fetch(descriptor)
            trainingPlanId = trainingData.first?.planId
        } catch {
            print("Error loading local training data: \(error)")
            trainingData = []
        }
    }
    
    func setTrainingData(_ newData: [TrainingDay], planId: String? = nil) {
        // Limpiar datos anteriores
        let descriptor = FetchDescriptor<TrainingDay>()
        do {
            let existingDays = try modelContext.fetch(descriptor)
            for day in existingDays {
                modelContext.delete(day)
            }
        } catch {
            print("Error clearing existing training data: \(error)")
        }
        
        // Insertar nuevos datos
        for day in newData {
            day.planId = planId
            modelContext.insert(day)
        }
        
        do {
            try modelContext.save()
            self.trainingData = newData
            self.trainingPlanId = planId
        } catch {
            print("Error saving training data: \(error)")
            self.errorMessage = "Error guardando datos de entrenamiento"
        }
    }
    
    func loadActiveTrainingPlan(userId: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            let response = try await apiService.loadActiveTrainingPlan(userId: userId)
            
            if let serverTrainingData = response.trainingData {
                let localTrainingDays = convertServerDataToLocal(serverTrainingData)
                setTrainingData(localTrainingDays, planId: response.planId)
            } else {
                setTrainingData([])
            }
        } catch {
            errorMessage = error.localizedDescription
            print("Error loading active training plan: \(error)")
        }
        
        isLoading = false
    }
    
    private func convertServerDataToLocal(_ serverData: [ServerTrainingDay]) -> [TrainingDay] {
        return serverData.map { serverDay in
            let localDay = TrainingDay(day: serverDay.day, workoutName: serverDay.workoutName)
            
            localDay.exercises = serverDay.output.enumerated().map { (index, serverExercise) in
                Exercise(
                    name: serverExercise.name,
                    sets: serverExercise.sets,
                    reps: serverExercise.reps,
                    restSeconds: serverExercise.restSeconds,
                    notes: serverExercise.notes,
                    tempo: serverExercise.tempo,
                    weightTracking: serverExercise.weightTracking,
                    orderIndex: index
                )
            }
            
            return localDay
        }
    }
    
    // MARK: - Manejo de pesos
    
    func generateWeightKey(planId: String?, day: String, exerciseIndex: Int, setIndex: Int? = nil) -> String {
        let baseKey = planId != nil ? "\(planId!)-\(day)-\(exerciseIndex)" : "\(day)-\(exerciseIndex)"
        return setIndex != nil ? "\(baseKey)-\(setIndex!)" : baseKey
    }
    
    func updateWeight(day: String, exerciseIndex: Int, setIndex: Int, weight: Double) {
        let key = generateWeightKey(planId: trainingPlanId, day: day, exerciseIndex: exerciseIndex, setIndex: setIndex)
        weights[key] = weight
    }
    
    func getCompletedSets(day: String, exerciseIndex: Int, totalSets: Int) -> Int {
        var completed = 0
        for i in 0..<totalSets {
            let weightKey = generateWeightKey(planId: trainingPlanId, day: day, exerciseIndex: exerciseIndex, setIndex: i)
            if let weight = weights[weightKey], weight > 0 {
                completed += 1
            }
        }
        return completed
    }
    
    func loadWeightsForWeek(_ weekStart: Date) {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let weekStartString = dateFormatter.string(from: getWeekStart(weekStart))
        
        let predicate = #Predicate<WeightRecord> { record in
            record.weekStart == weekStartString
        }
        
        let descriptor = FetchDescriptor<WeightRecord>(predicate: predicate)
        
        do {
            let records = try modelContext.fetch(descriptor)
            
            // Limpiar pesos actuales
            weights.removeAll()
            exerciseNotes.removeAll()
            
            // Cargar pesos de los registros
            for record in records {
                for (setIndex, weightSet) in record.sets.enumerated() {
                    let key = generateWeightKey(
                        planId: record.planId,
                        day: record.day,
                        exerciseIndex: record.exerciseIndex,
                        setIndex: setIndex
                    )
                    weights[key] = weightSet.weight
                }
                
                // Cargar nota del ejercicio
                let noteKey = generateWeightKey(
                    planId: record.planId,
                    day: record.day,
                    exerciseIndex: record.exerciseIndex
                )
                exerciseNotes[noteKey] = record.note
            }
        } catch {
            print("Error loading weights for week: \(error)")
        }
    }
    
    func saveWeightsToDatabase(day: String, exerciseIndex: Int, exerciseName: String, note: String, userId: String) async {
        let key = generateWeightKey(planId: trainingPlanId, day: day, exerciseIndex: exerciseIndex)
        
        savingWeights[key] = true
        
        do {
            guard let planId = trainingPlanId else {
                throw TrainingError.noPlanId
            }
            
            // Obtener el ejercicio para saber cuántas series tiene
            guard let exercise = trainingData.first(where: { $0.day == day })?.exercises.first(where: { $0.orderIndex == exerciseIndex }) else {
                throw TrainingError.exerciseNotFound
            }
            
            // Crear sets con los pesos actuales
            var weightSets: [WeightSet] = []
            for i in 0..<exercise.sets {
                let weightKey = generateWeightKey(planId: planId, day: day, exerciseIndex: exerciseIndex, setIndex: i)
                let weight = weights[weightKey] ?? 0
                let reps = Int(exercise.reps.components(separatedBy: "-").first ?? "0") ?? 0
                weightSets.append(WeightSet(weight: weight, reps: reps))
            }
            
            let weekStartString = DateFormatter().apply {
                $0.dateFormat = "yyyy-MM-dd"
            }.string(from: getWeekStart(selectedWeek))
            
            // Buscar registro existente o crear uno nuevo
            let predicate = #Predicate<WeightRecord> { record in
                record.userId == userId &&
                record.planId == planId &&
                record.day == day &&
                record.exerciseIndex == exerciseIndex &&
                record.weekStart == weekStartString
            }
            
            let descriptor = FetchDescriptor<WeightRecord>(predicate: predicate)
            let existingRecords = try modelContext.fetch(descriptor)
            
            let record: WeightRecord
            if let existingRecord = existingRecords.first {
                record = existingRecord
                record.sets = weightSets
                record.note = note
            } else {
                record = WeightRecord(
                    userId: userId,
                    planId: planId,
                    day: day,
                    exerciseName: exerciseName,
                    exerciseIndex: exerciseIndex,
                    sets: weightSets,
                    note: note,
                    weekStart: weekStartString
                )
                modelContext.insert(record)
            }
            
            try modelContext.save()
            
            // Sincronizar con el servidor
            try await syncWeightRecord(record)
            
            // Actualizar UI
            savedWeights[key] = true
            
            // Quitar el indicador después de 2 segundos
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                self.savedWeights[key] = false
            }
            
        } catch {
            print("Error saving weights: \(error)")
            errorMessage = error.localizedDescription
        }
        
        savingWeights[key] = false
    }
    
    private func syncWeightRecord(_ record: WeightRecord) async throws {
        let request = SaveWeightsRequest(
            userId: record.userId,
            planId: record.planId,
            weightRecord: WeightRecordRequest(
                day: record.day,
                exerciseName: record.exerciseName,
                exerciseIndex: record.exerciseIndex,
                sets: record.sets.map { ServerWeightSet(weight: $0.weight, reps: $0.reps) },
                note: record.note
            ),
            weekStart: record.weekStart
        )
        
        let _: APIResponse<EmptyResponse> = try await apiService.saveWeights(request)
        
        // Marcar como sincronizado
        record.needsSync = false
        try modelContext.save()
    }
    
    func getWeekStart(_ date: Date) -> Date {
        let calendar = Calendar.current
        let diff = calendar.dateInterval(of: .weekOfYear, for: date)?.start ?? date
        return diff
    }
    
    func changeWeek(direction: WeekDirection) async {
        let currentWeekStart = getWeekStart(selectedWeek)
        let newWeek: Date
        
        switch direction {
        case .previous:
            newWeek = Calendar.current.date(byAdding: .day, value: -7, to: currentWeekStart) ?? currentWeekStart
        case .next:
            newWeek = Calendar.current.date(byAdding: .day, value: 7, to: currentWeekStart) ?? currentWeekStart
        case .current:
            newWeek = getWeekStart(Date())
        }
        
        selectedWeek = newWeek
        loadWeightsForWeek(newWeek)
    }
}

enum WeekDirection {
    case previous, next, current
}

enum TrainingError: Error, LocalizedError {
    case noPlanId
    case exerciseNotFound
    
    var errorDescription: String? {
        switch self {
        case .noPlanId:
            return "No hay plan de entrenamiento activo"
        case .exerciseNotFound:
            return "Ejercicio no encontrado"
        }
    }
}
