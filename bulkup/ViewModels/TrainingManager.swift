//
//  TrainingManager.swift
//  bulkup
//
//  Fixed version with proper week-specific weight tracking
//

import Foundation
import SwiftData

@MainActor
class TrainingManager: ObservableObject {
    static let shared = TrainingManager(
        modelContext: ModelContainer.bulkUpContainer.mainContext
    )

    @Published var trainingData: [TrainingDay] = []
    @Published var trainingPlanId: String?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var isFullyLoaded = false

    // Estado para pesos - SIEMPRE incluir la fecha de la semana
    @Published var weights: [String: Double] = [:]
    @Published var selectedWeek: Date = Date()
    @Published var exerciseNotes: [String: String] = [:]
    @Published var backendExerciseNotes: [String: String] = [:]
    @Published var savedWeights: [String: Bool] = [:]
    @Published var savingWeights: [String: Bool] = [:]

    private let modelContext: ModelContext
    private let apiService = APIService.shared
    private let authManager = AuthManager.shared

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        loadLocalTrainingData()
    }

    private func loadLocalTrainingData() {
        let descriptor = FetchDescriptor<TrainingDay>(
            sortBy: [SortDescriptor(\.day)]
        )

        do {
            let fetchedData = try modelContext.fetch(descriptor)
            
            let dayOrder: [String: Int] = [
                "lunes": 1,
                "martes": 2,
                "miercoles": 3,
                "miércoles": 3,
                "jueves": 4,
                "viernes": 5,
                "sabado": 6,
                "sábado": 6,
                "domingo": 7
            ]
            
            trainingData = fetchedData.sorted { day1, day2 in
                let order1 = dayOrder[day1.day.lowercased()] ?? 8
                let order2 = dayOrder[day2.day.lowercased()] ?? 8
                return order1 < order2
            }
            
            trainingPlanId = trainingData.first?.planId

            if trainingPlanId != nil {
                Task {
                    await loadWeightsForWeek(selectedWeek)
                }
            }
        } catch {
            print("Error loading local training data: \(error)")
            trainingData = []
        }
    }

    func setTrainingData(_ newData: [TrainingDay], planId: String? = nil) {
        let descriptor = FetchDescriptor<TrainingDay>()
        do {
            let existingDays = try modelContext.fetch(descriptor)
            for day in existingDays {
                modelContext.delete(day)
            }
        } catch {
            print("Error clearing existing training data: \(error)")
        }

        for day in newData {
            day.planId = planId
            modelContext.insert(day)
        }

        do {
            try modelContext.save()
            self.trainingData = newData
            self.trainingPlanId = planId
            if self.trainingPlanId != nil {
                Task {
                    await loadWeightsForWeek(selectedWeek)
                }
            }
        } catch {
            print("Error saving training data: \(error)")
            self.errorMessage = "Error guardando datos de entrenamiento"
        }
    }

    func loadActiveTrainingPlan(userId: String) async {
        print("🏋️ Iniciando carga de plan de entrenamiento...")
        isLoading = true
        isFullyLoaded = false
        errorMessage = nil

        do {
            let response = try await apiService.loadActiveTrainingPlan(
                userId: userId
            )

            if let serverTrainingData = response.trainingData {
                print("✅ Datos de entrenamiento recibidos del servidor")
                let localTrainingDays = convertServerDataToLocal(
                    serverTrainingData
                )
                setTrainingData(localTrainingDays, planId: response.id)

                print("🏋️ Cargando pesos para la semana...")
                await loadWeightsForWeek(selectedWeek)
                print("✅ Pesos cargados completamente")

            } else {
                print("❌ No hay datos de entrenamiento en el servidor")
                setTrainingData([])
                await MainActor.run {
                    self.isFullyLoaded = true
                }
            }
        } catch {
            errorMessage = error.localizedDescription
            print("❌ Error loading active training plan: \(error)")
            await MainActor.run {
                self.isFullyLoaded = true
            }
        }

        print("🏋️ Finalizando carga - isLoading: false, isFullyLoaded: true")
        isLoading = false
    }

    func loadTrainingDataForTab(userId: String) async {
        print(
            "📱 loadTrainingDataForTab - trainingData.count: \(trainingData.count), isFullyLoaded: \(isFullyLoaded)"
        )

        if !trainingData.isEmpty && isFullyLoaded {
            print("✅ Datos ya cargados, no es necesario recargar")
            return
        }

        print("🔄 Recargando datos de entrenamiento...")
        await loadActiveTrainingPlan(userId: userId)
    }

    private func convertServerDataToLocal(_ serverData: [ServerTrainingDay])
        -> [TrainingDay]
    {
        let dayOrder: [String: Int] = [
            "lunes": 1,
            "martes": 2,
            "miercoles": 3,
            "miércoles": 3,
            "jueves": 4,
            "viernes": 5,
            "sabado": 6,
            "sábado": 6,
            "domingo": 7
        ]
        
        let convertedDays = serverData.map { serverDay in
            let localDay = TrainingDay(
                day: serverDay.day,
                workoutName: serverDay.workoutName
            )

            localDay.exercises =
                serverDay.output?.enumerated().map {
                    (index, serverExercise) in
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
                } ?? []

            return localDay
        }
        
        return convertedDays.sorted { day1, day2 in
            let order1 = dayOrder[day1.day.lowercased()] ?? 8
            let order2 = dayOrder[day2.day.lowercased()] ?? 8
            return order1 < order2
        }
    }

    // MARK: - Manejo de pesos

    func generateWeightKey(
        planId: String? = nil,
        day: String,
        exerciseIndex: Int,
        exerciseName: String,
        setIndex: Int? = nil,
        weekStart: String? = nil
    ) -> String {
        let actualPlanId = planId ?? trainingPlanId

        let normalizedExerciseName =
            exerciseName
            .lowercased()
            .replacingOccurrences(of: " ", with: "_")
            .replacingOccurrences(of: "ñ", with: "n")
            .replacingOccurrences(of: "á", with: "a")
            .replacingOccurrences(of: "é", with: "e")
            .replacingOccurrences(of: "í", with: "i")
            .replacingOccurrences(of: "ó", with: "o")
            .replacingOccurrences(of: "ú", with: "u")

        var baseKey = ""
        
        if let actualPlanId = actualPlanId {
            baseKey = "\(actualPlanId)-\(day)-\(exerciseIndex)-\(normalizedExerciseName)"
        } else {
            baseKey = "\(day)-\(exerciseIndex)-\(normalizedExerciseName)"
        }
        
        if let setIndex = setIndex {
            baseKey = "\(baseKey)-\(setIndex)"
        }
        
        // SIEMPRE incluir la fecha de la semana
        let actualWeekStart = weekStart ?? getCurrentWeekString()
        baseKey = "\(baseKey)-\(actualWeekStart)"

        return baseKey
    }
    
    // Helper para obtener la fecha de la semana actual como string
    private func getCurrentWeekString() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        return dateFormatter.string(from: getWeekStart(selectedWeek))
    }

    func updateWeight(
        day: String,
        exerciseIndex: Int,
        exerciseName: String,
        setIndex: Int,
        weight: Double
    ) {
        // SIEMPRE usar la key con fecha de la semana actual
        let key = generateWeightKey(
            day: day,
            exerciseIndex: exerciseIndex,
            exerciseName: exerciseName,
            setIndex: setIndex,
            weekStart: getCurrentWeekString()
        )
        
        if weight > 0 {
            weights[key] = weight
        } else {
            weights.removeValue(forKey: key)
        }
    }

    func getCompletedSets(
        day: String,
        exerciseIndex: Int,
        exerciseName: String,
        totalSets: Int
    ) -> Int {
        var completed = 0
        let currentWeekString = getCurrentWeekString()
        
        for i in 0..<totalSets {
            let weightKey = generateWeightKey(
                day: day,
                exerciseIndex: exerciseIndex,
                exerciseName: exerciseName,
                setIndex: i,
                weekStart: currentWeekString
            )
            if let weight = weights[weightKey], weight > 0 {
                completed += 1
            }
        }
        return completed
    }

    func hasWeightForExercise(exerciseName: String, day: String, week: Date)
        -> Bool
    {
        guard let dayData = trainingData.first(where: { $0.day == day }),
            let exercise = dayData.exercises.first(where: {
                $0.name == exerciseName
            }),
            dayData.exercises.firstIndex(where: {
                $0.name == exerciseName
            }) != nil
        else {
            return false
        }

        return getCompletedSets(
            day: day,
            exerciseIndex: exercise.orderIndex,
            exerciseName: exerciseName,
            totalSets: exercise.sets
        ) > 0
    }

    func loadWeightsForWeek(_ weekStart: Date) async {
        guard let userId = authManager.user?.id else {
            print("❌ Usuario no autenticado")
            return
        }

        do {
            let weekStartDate = getWeekStart(weekStart)
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            let weekStartString = dateFormatter.string(from: weekStartDate)
            
            // También cargar la semana anterior para referencias
            let previousWeekDate = Calendar.current.date(byAdding: .weekOfYear, value: -1, to: weekStartDate) ?? weekStartDate
            let previousWeekString = dateFormatter.string(from: getWeekStart(previousWeekDate))

            // Cargar hasta 4 semanas anteriores para tener suficiente historial
            var weeksToLoad = [weekStartString]
            var checkWeek = weekStartDate
            for _ in 0..<4 {
                checkWeek = Calendar.current.date(byAdding: .weekOfYear, value: -1, to: checkWeek) ?? checkWeek
                let weekString = dateFormatter.string(from: getWeekStart(checkWeek))
                weeksToLoad.append(weekString)
            }
            
            print("📊 Cargando pesos para semanas: \(weeksToLoad)")
            print("📊 PlanId actual: \(trainingPlanId ?? "nil")")
            
            // Limpiar SOLO los pesos de la semana actual antes de recargar
            await MainActor.run {
                // Eliminar solo las keys que contienen la fecha de la semana actual
                let keysToRemove = self.weights.keys.filter { key in
                    key.contains(weekStartString)
                }
                for key in keysToRemove {
                    self.weights.removeValue(forKey: key)
                }
                
                // Limpiar notas solo de la semana actual
                let noteKeysToRemove = self.backendExerciseNotes.keys.filter { key in
                    key.contains(weekStartString)
                }
                for key in noteKeysToRemove {
                    self.backendExerciseNotes.removeValue(forKey: key)
                }
                
                print("🧹 Limpiadas \(keysToRemove.count) keys de pesos y \(noteKeysToRemove.count) keys de notas de la semana actual")
            }
            
            // Cargar pesos de todas las semanas necesarias
            for week in weeksToLoad {
                // Solo cargar si no tenemos ya datos para esa semana (excepto la actual que acabamos de limpiar)
                if week != weekStartString {
                    let existingKeys = weights.keys.filter { $0.contains(week) }
                    if !existingKeys.isEmpty {
                        print("⏭️ Saltando semana \(week) - ya tenemos \(existingKeys.count) registros")
                        continue
                    }
                }
                
                let response = try await apiService.loadWeights(
                    userId: userId,
                    weekStart: week
                )

                print("📊 Respuesta del servidor para \(week):")
                print("   - Registros recibidos: \(response.weights?.count ?? 0)")
                
                if let serverWeights = response.weights, !serverWeights.isEmpty {
                    var newWeights: [String: Double] = [:]
                    var newNotes: [String: String] = [:]

                    for record in serverWeights {
                        if let sets = record.sets {
                            let sortedSets = sets.enumerated().sorted { (a, b) in
                                let aNumber = a.element.setNumber ?? a.offset
                                let bNumber = b.element.setNumber ?? b.offset
                                return aNumber < bNumber
                            }

                            for (index, weightSet) in sortedSets {
                                let actualSetIndex = weightSet.setNumber ?? index

                                // SIEMPRE generar key con la fecha específica
                                let key = generateWeightKey(
                                    planId: record.planId ?? trainingPlanId,
                                    day: record.day,
                                    exerciseIndex: record.exerciseIndex,
                                    exerciseName: record.exerciseName,
                                    setIndex: actualSetIndex,
                                    weekStart: week
                                )
                                
                                // Solo agregar si el peso es válido
                                if weightSet.weight > 0 {
                                    newWeights[key] = weightSet.weight
                                }
                            }
                        }

                        // Cargar nota solo para la semana actual
                        if week == weekStartString, let note = record.note, !note.isEmpty {
                            let noteKey = generateWeightKey(
                                planId: record.planId ?? trainingPlanId,
                                day: record.day,
                                exerciseIndex: record.exerciseIndex,
                                exerciseName: record.exerciseName,
                                weekStart: week
                            )
                            newNotes[noteKey] = note
                        }
                    }

                    await MainActor.run {
                        for (key, weight) in newWeights {
                            self.weights[key] = weight
                        }
                        for (key, note) in newNotes {
                            self.backendExerciseNotes[key] = note
                        }
                    }

                    print("✅ Pesos cargados para \(week): \(newWeights.count) registros")
                }

                // También cargar de la base de datos local
                loadWeightsFromLocalDatabase(week)
            }

        } catch {
            print("❌ Error cargando pesos del servidor:", error)
            // Intentar cargar de la base de datos local
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            let weekStartString = dateFormatter.string(from: getWeekStart(weekStart))
            
            loadWeightsFromLocalDatabase(weekStartString)
            
            // También cargar semanas anteriores de la base de datos local
            var checkWeek = weekStart
            for _ in 0..<4 {
                checkWeek = Calendar.current.date(byAdding: .weekOfYear, value: -1, to: checkWeek) ?? checkWeek
                let weekString = dateFormatter.string(from: getWeekStart(checkWeek))
                loadWeightsFromLocalDatabase(weekString)
            }
        }

        await MainActor.run {
            self.isFullyLoaded = true
            print("🎉 isFullyLoaded configurado a true")
            print("📊 Total final de pesos en memoria: \(self.weights.count)")
            
            // Debug: mostrar cuántos pesos hay por semana
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            let currentWeek = dateFormatter.string(from: getWeekStart(weekStart))
            let currentWeekCount = self.weights.keys.filter { $0.contains(currentWeek) }.count
            print("📊 Pesos para la semana actual (\(currentWeek)): \(currentWeekCount)")
        }
    }

    private func loadWeightsFromLocalDatabase(_ weekStartString: String) {
        do {
            let allRecords = try modelContext.fetch(
                FetchDescriptor<WeightRecord>()
            )
            let records = allRecords.filter { record in
                record.weekStart == weekStartString
            }

            for record in records {
                let sortedSets = record.sets.sorted {
                    $0.setNumber < $1.setNumber
                }

                for (index, weightSet) in sortedSets.enumerated() {
                    let setIndex =
                        weightSet.setNumber > 0 ? weightSet.setNumber : index

                    // SIEMPRE usar key con fecha
                    let key = generateWeightKey(
                        planId: record.planId,
                        day: record.day,
                        exerciseIndex: record.exerciseIndex,
                        exerciseName: record.exerciseName,
                        setIndex: setIndex,
                        weekStart: weekStartString
                    )

                    if weights[key] == nil {
                        weights[key] = weightSet.weight
                    }
                }

                // Load note for current week
                let currentWeekString = getCurrentWeekString()
                if weekStartString == currentWeekString {
                    let noteKey = generateWeightKey(
                        planId: record.planId,
                        day: record.day,
                        exerciseIndex: record.exerciseIndex,
                        exerciseName: record.exerciseName,
                        weekStart: weekStartString
                    )
                    if backendExerciseNotes[noteKey] == nil && !record.note.isEmpty {
                        backendExerciseNotes[noteKey] = record.note
                    }
                }
            }

            print(
                "📱 Pesos cargados desde base de datos local para \(weekStartString): \(records.count) registros"
            )
        } catch {
            print("Error loading weights from local database: \(error)")
        }
    }

    func saveWeightsToDatabase(
        day: String,
        exerciseIndex: Int,
        exerciseName: String,
        note: String,
        userId: String
    ) async {
        let currentWeekString = getCurrentWeekString()
        let key = generateWeightKey(
            day: day,
            exerciseIndex: exerciseIndex,
            exerciseName: exerciseName,
            weekStart: currentWeekString
        )

        savingWeights[key] = true

        do {
            guard let planId = trainingPlanId else {
                throw TrainingError.noPlanId
            }

            guard
                let dayData = trainingData.first(where: {
                    $0.day.lowercased() == day.lowercased()
                }),
                let exercise = dayData.exercises.first(where: {
                    $0.name.lowercased() == exerciseName.lowercased()
                })
            else {
                print(
                    "❌ No se encontró ejercicio: \(exerciseName) en día: \(day)"
                )
                print("📋 Días disponibles: \(trainingData.map { $0.day })")
                throw TrainingError.exerciseNotFound
            }

            let actualExerciseIndex = exercise.orderIndex

            // Create sets with current weights
            var weightSets: [WeightSet] = []
            for setIndex in 0..<exercise.sets {
                let weightKey = generateWeightKey(
                    day: day,
                    exerciseIndex: actualExerciseIndex,
                    exerciseName: exerciseName,
                    setIndex: setIndex,
                    weekStart: currentWeekString
                )

                let weight = weights[weightKey] ?? 0

                var reps: Int = 0
                if exercise.reps.contains("-") {
                    let lastPart = exercise.reps.split(separator: "-").last
                    reps = lastPart.flatMap { Int($0) } ?? 0
                } else if !exercise.reps.isEmpty {
                    reps = Int(exercise.reps) ?? 0
                }

                weightSets.append(
                    WeightSet(setNumber: setIndex, weight: weight, reps: reps)
                )
            }

            // Find or create record
            let allRecords = try modelContext.fetch(
                FetchDescriptor<WeightRecord>()
            )

            let existingRecord = allRecords.first { record in
                record.userId == userId && record.planId == planId
                    && record.day == day
                    && record.exerciseIndex == actualExerciseIndex
                    && record.exerciseName == exerciseName
                    && record.weekStart == currentWeekString
            }

            let record: WeightRecord
            if let existing = existingRecord {
                record = existing
                record.sets = weightSets
                record.note = note
                record.updatedAt = Date()
            } else {
                record = WeightRecord(
                    userId: userId,
                    planId: planId,
                    day: day,
                    exerciseName: exerciseName,
                    exerciseIndex: actualExerciseIndex,
                    sets: weightSets,
                    note: note,
                    weekStart: currentWeekString
                )
                modelContext.insert(record)
            }

            try modelContext.save()

            // Update notes in memory with week date
            let noteKey = generateWeightKey(
                day: day,
                exerciseIndex: actualExerciseIndex,
                exerciseName: exerciseName,
                weekStart: currentWeekString
            )
            backendExerciseNotes[noteKey] = note

            // Sync with server
            try await syncWeightRecord(record)

            // Update UI
            savedWeights[key] = true

            // Remove indicator after 2 seconds
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
        let sortedSets = record.sets.sorted { $0.setNumber < $1.setNumber }

        let request = SaveWeightsRequest(
            userId: record.userId,
            planId: record.planId,
            weightRecord: WeightRecordRequest(
                day: record.day,
                exerciseName: record.exerciseName,
                exerciseIndex: record.exerciseIndex,
                sets: sortedSets.map { set in
                    ServerWeightSet(
                        setNumber: set.setNumber,
                        weight: set.weight,
                        reps: set.reps
                    )
                },
                note: record.note
            ),
            weekStart: record.weekStart
        )

        let _: APIResponse<EmptyResponse> = try await apiService.saveWeights(
            request
        )

        record.needsSync = false
        try modelContext.save()
    }

    func getWeekStart(_ date: Date) -> Date {
        let calendar = Calendar.current
        let components = calendar.dateComponents(
            [.yearForWeekOfYear, .weekOfYear],
            from: date
        )
        let monday = calendar.date(from: components) ?? date
        return calendar.date(byAdding: .day, value: 1, to: monday) ?? monday
    }

    func changeWeek(direction: WeekDirection) async {
        let currentWeekStart = getWeekStart(selectedWeek)
        let newWeek: Date

        switch direction {
        case .previous:
            newWeek =
                Calendar.current.date(
                    byAdding: .day,
                    value: -7,
                    to: currentWeekStart
                ) ?? currentWeekStart
        case .next:
            newWeek =
                Calendar.current.date(
                    byAdding: .day,
                    value: 7,
                    to: currentWeekStart
                ) ?? currentWeekStart
        case .current:
            newWeek = getWeekStart(Date())
        }

        selectedWeek = newWeek

        await MainActor.run {
            self.isFullyLoaded = false
        }

        await loadWeightsForWeek(newWeek)
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

// Extension helper
extension DateFormatter {
    func apply(closure: (DateFormatter) -> Void) -> DateFormatter {
        closure(self)
        return self
    }
}
