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
    static let shared = TrainingManager(
        modelContext: ModelContainer.bulkUpContainer.mainContext
    )

    @Published var trainingData: [TrainingDay] = []
    @Published var trainingPlanId: String?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var isFullyLoaded = false

    // Estado para pesos
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
            trainingData = try modelContext.fetch(descriptor)
            trainingPlanId = trainingData.first?.planId

            // Cargar pesos después de cargar los datos de entrenamiento
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
                setTrainingData(localTrainingDays, planId: response.planId)

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

        // Si ya hay datos y están completamente cargados, no recargar
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
        return serverData.map { serverDay in
            let localDay = TrainingDay(
                day: serverDay.day,
                workoutName: serverDay.workoutName
            )

            localDay.exercises = serverDay.output.enumerated().map {
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
            }

            return localDay
        }
    }

    // MARK: - Manejo de pesos

    func generateWeightKey(
        planId: String? = nil,
        day: String,
        exerciseIndex: Int,
        exerciseName: String,  // 🔧 ADD: Exercise name to ensure uniqueness
        setIndex: Int? = nil
    ) -> String {
        // Use the planId passed as parameter, or the trainingPlanId actual
        let actualPlanId = planId ?? trainingPlanId

        // Create a normalized exercise name (remove spaces, convert to lowercase)
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

        let baseKey =
            actualPlanId != nil
            ? "\(actualPlanId!)-\(day)-\(exerciseIndex)-\(normalizedExerciseName)"
            : "\(day)-\(exerciseIndex)-\(normalizedExerciseName)"

        return setIndex != nil ? "\(baseKey)-\(setIndex!)" : baseKey
    }

    func updateWeight(
        day: String,
        exerciseIndex: Int,
        exerciseName: String,  // 🔧 ADD: Exercise name parameter
        setIndex: Int,
        weight: Double
    ) {
        let key = generateWeightKey(
            day: day,
            exerciseIndex: exerciseIndex,
            exerciseName: exerciseName,  // 🔧 ADD: Pass exercise name
            setIndex: setIndex
        )
        weights[key] = weight
    }

    func getCompletedSets(
        day: String,
        exerciseIndex: Int,
        exerciseName: String,  // 🔧 ADD: Exercise name parameter
        totalSets: Int
    ) -> Int {
        var completed = 0
        for i in 0..<totalSets {
            let weightKey = generateWeightKey(
                day: day,
                exerciseIndex: exerciseIndex,
                exerciseName: exerciseName,  // 🔧 ADD: Pass exercise name
                setIndex: i
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
            let exerciseIndex = dayData.exercises.firstIndex(where: {
                $0.name == exerciseName
            })
        else {
            return false
        }

        return getCompletedSets(
            day: day,
            exerciseIndex: exerciseIndex,
            exerciseName: exerciseName,  // 🔧 ADD: Pass exercise name
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

            let response = try await apiService.loadWeights(
                userId: userId,
                weekStart: weekStartString
            )

            print("📊 Pesos cargados del servidor:", response)

            // Clear current weights and notes
            await MainActor.run {
                self.weights.removeAll()
                self.backendExerciseNotes.removeAll()
            }

            // Process server response
            if let serverWeights = response.weights, !serverWeights.isEmpty {
                var newWeights: [String: Double] = [:]
                var newNotes: [String: String] = [:]

                for record in serverWeights {
                    // Load weights for each set
                    if let sets = record.sets {
                        for (setIndex, weightSet) in sets.enumerated() {
                            // 🔧 IMPORTANT: Include exercise name in key generation
                            let key = generateWeightKey(
                                planId: record.planId ?? trainingPlanId,
                                day: record.day,
                                exerciseIndex: record.exerciseIndex,
                                exerciseName: record.exerciseName,  // 🔧 ADD: Use exercise name from record
                                setIndex: setIndex
                            )
                            newWeights[key] = weightSet.weight
                        }
                    }

                    // Load exercise note
                    if let note = record.note, !note.isEmpty {
                        let noteKey = generateWeightKey(
                            planId: record.planId ?? trainingPlanId,
                            day: record.day,
                            exerciseIndex: record.exerciseIndex,
                            exerciseName: record.exerciseName  // 🔧 ADD: Use exercise name from record
                        )
                        newNotes[noteKey] = note
                    }
                }

                await MainActor.run {
                    self.weights = newWeights
                    self.backendExerciseNotes = newNotes
                }

                print("✅ Pesos cargados: \(newWeights.count) registros")
            }

            // Also try loading from local database
            loadWeightsFromLocalDatabase(weekStartString)

        } catch {
            print("❌ Error cargando pesos del servidor:", error)
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            let weekStartString = dateFormatter.string(
                from: getWeekStart(weekStart)
            )
            loadWeightsFromLocalDatabase(weekStartString)
        }

        await MainActor.run {
            self.isFullyLoaded = true
            print("🎉 isFullyLoaded configurado a true")
        }
    }

    // También actualiza loadWeightsFromLocalDatabase:
    private func loadWeightsFromLocalDatabase(_ weekStartString: String) {
        let predicate = #Predicate<WeightRecord> { record in
            record.weekStart == weekStartString
        }

        let descriptor = FetchDescriptor<WeightRecord>(predicate: predicate)

        do {
            let records = try modelContext.fetch(descriptor)

            for record in records {
                for (setIndex, weightSet) in record.sets.enumerated() {
                    // 🔧 IMPORTANT: Use exercise name from record
                    let key = generateWeightKey(
                        planId: record.planId,
                        day: record.day,
                        exerciseIndex: record.exerciseIndex,
                        exerciseName: record.exerciseName,  // 🔧 ADD: Use exercise name from record
                        setIndex: setIndex
                    )

                    // Only update if doesn't exist from server
                    if weights[key] == nil {
                        weights[key] = weightSet.weight
                    }
                }

                // Load exercise note if doesn't exist
                let noteKey = generateWeightKey(
                    planId: record.planId,
                    day: record.day,
                    exerciseIndex: record.exerciseIndex,
                    exerciseName: record.exerciseName  // 🔧 ADD: Use exercise name from record
                )
                if backendExerciseNotes[noteKey] == nil && !record.note.isEmpty
                {
                    backendExerciseNotes[noteKey] = record.note
                }
            }

            print(
                "📱 Pesos cargados desde base de datos local: \(records.count) registros"
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
        let key = generateWeightKey(
            day: day,
            exerciseIndex: exerciseIndex,
            exerciseName: exerciseName  // 🔧 ADD: Pass exercise name
        )

        savingWeights[key] = true

        do {
            guard let planId = trainingPlanId else {
                throw TrainingError.noPlanId
            }

            // Get exercise to know how many sets it has
            guard
                let exercise = trainingData.first(where: { $0.day == day })?
                    .exercises.first(where: { $0.orderIndex == exerciseIndex })
            else {
                throw TrainingError.exerciseNotFound
            }

            // Create sets with current weights
            var weightSets: [WeightSet] = []
            for i in 0..<exercise.sets {
                let weightKey = generateWeightKey(
                    day: day,
                    exerciseIndex: exerciseIndex,
                    exerciseName: exerciseName,  // 🔧 ADD: Pass exercise name
                    setIndex: i
                )
                let weight = weights[weightKey] ?? 0
                var reps: Int = 0
                if exercise.reps.contains("-") {
                    let lastPart = exercise.reps.split(separator: "-").last
                    reps = lastPart.flatMap { Int($0) } ?? 0
                } else if !exercise.reps.isEmpty {
                    reps = Int(exercise.reps) ?? 0
                }
                weightSets.append(WeightSet(weight: weight, reps: reps))
            }

            let weekStartString = DateFormatter().apply {
                $0.dateFormat = "yyyy-MM-dd"
            }.string(from: getWeekStart(selectedWeek))

            // Find existing record or create new one
            let predicate = #Predicate<WeightRecord> { record in
                record.userId == userId && record.planId == planId
                    && record.day == day
                    && record.exerciseIndex == exerciseIndex
                    && record.exerciseName == exerciseName  // 🔧 ADD: Include exercise name in predicate
                    && record.weekStart == weekStartString
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

            // Update notes in memory
            let noteKey = generateWeightKey(
                day: day,
                exerciseIndex: exerciseIndex,
                exerciseName: exerciseName  // 🔧 ADD: Pass exercise name
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
        let request = SaveWeightsRequest(
            userId: record.userId,
            planId: record.planId,
            weightRecord: WeightRecordRequest(
                day: record.day,
                exerciseName: record.exerciseName,
                exerciseIndex: record.exerciseIndex,
                sets: record.sets.map {
                    ServerWeightSet(weight: $0.weight, reps: $0.reps)
                },
                note: record.note
            ),
            weekStart: record.weekStart
        )

        let _: APIResponse<EmptyResponse> = try await apiService.saveWeights(
            request
        )

        // Marcar como sincronizado
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

        // Limpiar pesos antes de cargar los nuevos
        await MainActor.run {
            self.isFullyLoaded = false
        }
        weights.removeAll()
        backendExerciseNotes.removeAll()

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
