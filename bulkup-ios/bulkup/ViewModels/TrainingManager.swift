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
    /// Reps actually logged per set, same key scheme as `weights`.
    @Published var setReps: [String: Int] = [:]
    @Published var selectedWeek: Date = Date()
    @Published var exerciseNotes: [String: String] = [:]
    @Published var backendExerciseNotes: [String: String] = [:]
    @Published var savedWeights: [String: Bool] = [:]
    @Published var savingWeights: [String: Bool] = [:]

    // Cross-plan mirror of weights/setReps keyed only by folded exercise name +
    // set + week. A new plan changes planId/day/orderIndex, which breaks every
    // generateWeightKey lookup; this mirror lets "anterior" find weights the
    // same exercise logged under any previous plan.
    var weightsByName: [String: Double] = [:]
    var repsByName: [String: Int] = [:]

    static func nameKey(exerciseName: String, setIndex: Int, weekStart: String) -> String {
        "\(ExerciseProgress.fold(exerciseName))|\(setIndex)|\(weekStart)"
    }

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
    /// Per-set planned reps parsed from the plan's reps string. Handles per-set
    /// comma lists ("10, 8, 6"), ranges ("8-12" → upper bound), and plain values.
    /// Extra sets beyond a comma list reuse its last entry. Mirrors
    /// ExerciseCardView.perSetReps' semantics.
    static func plannedReps(_ plan: String, setIndex: Int) -> Int {
        var parts = plan.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespaces) }
        guard let first = parts.first, !first.isEmpty else { return 0 }
        // Dash-separated per-set lists ("8-12-10"): 3+ numbers is a list, not a
        // range — exactly two ("8-12") keeps meaning a range (upper bound).
        if parts.count == 1 {
            let dashed = first.split(separator: "-").map { $0.trimmingCharacters(in: .whitespaces) }
            if dashed.count >= 3, dashed.allSatisfy({ Int($0) != nil }) { parts = dashed }
        }
        let part = parts.count > 1 ? parts[min(setIndex, parts.count - 1)] : parts[0]
        let upper = part.contains("-") ? String(part.split(separator: "-").last ?? "") : part
        return Int(upper) ?? 0
    }

    #if DEBUG
    static func runSelfCheck() {
        assert(plannedReps("10, 8, 6", setIndex: 0) == 10)
        assert(plannedReps("10, 8, 6", setIndex: 2) == 6)
        assert(plannedReps("10, 8, 6", setIndex: 3) == 6, "extra sets reuse the last entry")
        assert(plannedReps("8-12", setIndex: 1) == 12, "range takes the upper bound")
        assert(plannedReps("12", setIndex: 0) == 12)
        assert(plannedReps("12, 10-8", setIndex: 1) == 8)
        assert(plannedReps("", setIndex: 0) == 0)
        assert(plannedReps("8-12-10", setIndex: 0) == 8, "3+ dashed numbers is a per-set list")
        assert(plannedReps("8-12-10", setIndex: 1) == 12)
        assert(plannedReps("8-12-10", setIndex: 2) == 10)
        assert(plannedReps("8-12-10", setIndex: 3) == 10, "extra sets reuse the last entry")
        assert(plannedReps("8-12", setIndex: 0) == 12, "two dashed numbers is still a range")
    }
    #endif

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

    func updateReps(
        day: String,
        exerciseIndex: Int,
        exerciseName: String,
        setIndex: Int,
        reps: Int
    ) {
        let key = generateWeightKey(
            day: day,
            exerciseIndex: exerciseIndex,
            exerciseName: exerciseName,
            setIndex: setIndex,
            weekStart: getCurrentWeekString()
        )

        if reps > 0 {
            setReps[key] = reps
        } else {
            setReps.removeValue(forKey: key)
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

    /// Checks if all weight-tracking exercises for a given day have at least one set completed this week.
    /// Returns a tuple: (allComplete, exerciseCount, totalSetsCompleted)
    func getDayCompletionStatus(dayName: String) -> (allComplete: Bool, exerciseCount: Int, totalSetsCompleted: Int) {
        let normalizedDay = dayName.lowercased()
            .folding(options: .diacriticInsensitive, locale: .current)

        guard let dayData = trainingData.first(where: {
            $0.day.lowercased()
                .folding(options: .diacriticInsensitive, locale: .current) == normalizedDay
        }) else {
            return (false, 0, 0)
        }

        let trackableExercises = dayData.exercises.filter { $0.weightTracking }
        guard !trackableExercises.isEmpty else {
            return (false, 0, 0)
        }

        var totalSetsCompleted = 0
        var allComplete = true

        for exercise in trackableExercises {
            let completed = getCompletedSets(
                day: normalizedDay,
                exerciseIndex: exercise.orderIndex,
                exerciseName: exercise.name,
                totalSets: exercise.sets
            )
            totalSetsCompleted += completed
            if completed == 0 {
                allComplete = false
            }
        }

        return (allComplete, trackableExercises.count, totalSetsCompleted)
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

        // Weights are stored under diacritic-folded, lowercased day keys.
        // Pass the raw "Lunes"/"Miércoles" through and getCompletedSets never matches.
        let normalizedDay = day.lowercased()
            .folding(options: .diacriticInsensitive, locale: .current)

        return getCompletedSets(
            day: normalizedDay,
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

        // Every reload starts "not loaded" so the false→true transition reliably
        // re-runs each exercise card's loadInitialData for the new week (some
        // reload paths set selectedWeek directly without going through changeWeek).
        isFullyLoaded = false

        do {
            let weekStartDate = getWeekStart(weekStart)
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            let weekStartString = dateFormatter.string(from: weekStartDate)
            
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
                    key.hasSuffix("-\(weekStartString)")
                }
                for key in keysToRemove {
                    self.weights.removeValue(forKey: key)
                }
                for key in self.weightsByName.keys where key.hasSuffix("|\(weekStartString)") {
                    self.weightsByName.removeValue(forKey: key)
                    self.repsByName.removeValue(forKey: key)
                }
                
                // Limpiar notas solo de la semana actual
                let noteKeysToRemove = self.backendExerciseNotes.keys.filter { key in
                    key.hasSuffix("-\(weekStartString)")
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
                    let existingKeys = weights.keys.filter { $0.hasSuffix("-\(week)") }
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
                    var newReps: [String: Int] = [:]
                    var newNotes: [String: String] = [:]
                    var newWeightsByName: [String: Double] = [:]
                    var newRepsByName: [String: Int] = [:]

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
                                if weightSet.reps > 0 {
                                    newReps[key] = weightSet.reps
                                }

                                // ponytail: last record wins if the same exercise
                                // shows up twice in one week (e.g. two plans/days)
                                let nameKey = Self.nameKey(
                                    exerciseName: record.exerciseName,
                                    setIndex: actualSetIndex,
                                    weekStart: week
                                )
                                if weightSet.weight > 0 {
                                    newWeightsByName[nameKey] = weightSet.weight
                                }
                                if weightSet.reps > 0 {
                                    newRepsByName[nameKey] = weightSet.reps
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
                        for (key, reps) in newReps {
                            self.setReps[key] = reps
                        }
                        for (key, note) in newNotes {
                            self.backendExerciseNotes[key] = note
                        }
                        for (key, weight) in newWeightsByName {
                            self.weightsByName[key] = weight
                        }
                        for (key, reps) in newRepsByName {
                            self.repsByName[key] = reps
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
            let currentWeekCount = self.weights.keys.filter { $0.hasSuffix("-\(currentWeek)") }.count
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
                    if setReps[key] == nil, weightSet.reps > 0 {
                        setReps[key] = weightSet.reps
                    }

                    let nameKey = Self.nameKey(
                        exerciseName: record.exerciseName,
                        setIndex: setIndex,
                        weekStart: weekStartString
                    )
                    if weightsByName[nameKey] == nil, weightSet.weight > 0 {
                        weightsByName[nameKey] = weightSet.weight
                    }
                    if repsByName[nameKey] == nil, weightSet.reps > 0 {
                        repsByName[nameKey] = weightSet.reps
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
        userId: String,
        // Authoritative per-set values (setIndex → weight/reps). The watch path
        // passes these from the live store snapshot: reading `weights` here races
        // with loadWeightsForWeek's clear-then-refetch and used to save zeros
        // over just-logged sets when the app was woken in the background.
        setOverrides: [Int: (weight: Double, reps: Int)]? = nil
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

            // Callers pass a diacritic-folded day (e.g. "miercoles"), but the
            // plan stores it with accents ("Miércoles"). Fold both sides or
            // Wednesday/Saturday workouts fail to match and never persist.
            let foldedDay = day.lowercased()
                .folding(options: .diacriticInsensitive, locale: .current)
            guard
                let dayData = trainingData.first(where: {
                    $0.day.lowercased()
                        .folding(options: .diacriticInsensitive, locale: .current) == foldedDay
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

                let weight = setOverrides?[setIndex]?.weight ?? weights[weightKey] ?? 0

                // Reps the user logged for this set; fall back to the plan's
                // per-set target. The old fallback couldn't parse comma lists
                // ("10, 8, 6") and stored reps=0, which is why previous-week
                // reps never came back on "Usar anterior".
                var reps: Int = setOverrides?[setIndex]?.reps ?? setReps[weightKey] ?? 0
                if reps == 0 {
                    reps = Self.plannedReps(exercise.reps, setIndex: setIndex)
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
        var calendar = Calendar(identifier: .iso8601)
        calendar.locale = Locale.current
        let components = calendar.dateComponents(
            [.yearForWeekOfYear, .weekOfYear],
            from: date
        )
        return calendar.date(from: components) ?? date
    }

    func changeWeek(direction: WeekDirection) async {
        guard !WorkoutSessionManager.shared.isActive else { return }
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

        await selectWeek(newWeek)
    }

    /// Jump directly to the week containing `date` (used by the tappable weekly
    /// strip). Shares the reload path with the nav arrows.
    func selectWeek(_ date: Date) async {
        guard !WorkoutSessionManager.shared.isActive else { return }
        let newWeek = getWeekStart(date)
        guard newWeek != getWeekStart(selectedWeek) else { return }
        await applyWeekChange(to: newWeek)
    }

    private func applyWeekChange(to newWeek: Date) async {
        selectedWeek = newWeek

        await MainActor.run {
            self.isFullyLoaded = false
        }

        await loadWeightsForWeek(newWeek)
    }
    
    func clearAllData() {
        // Limpiar datos de memoria
        trainingData = []
        trainingPlanId = nil
        weights.removeAll()
        exerciseNotes.removeAll()
        backendExerciseNotes.removeAll()
        savedWeights.removeAll()
        savingWeights.removeAll()
        isFullyLoaded = false
        
        // Limpiar datos persistidos en SwiftData
        let descriptor = FetchDescriptor<TrainingDay>()
        do {
            let existingDays = try modelContext.fetch(descriptor)
            for day in existingDays {
                modelContext.delete(day)
            }
            try modelContext.save()
        } catch {
            print("Error clearing local training data: \(error)")
        }
        
        // Limpiar registros de pesos locales
        do {
            let allRecords = try modelContext.fetch(FetchDescriptor<WeightRecord>())
            for record in allRecords {
                modelContext.delete(record)
            }
            try modelContext.save()
        } catch {
            print("Error clearing weight records: \(error)")
        }
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
