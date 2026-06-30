//
//  WorkoutSessionManager.swift
//  bulkup
//
//  Manages active workout session state: elapsed timer, rest countdown,
//  per-set completion tracking, failure marking, and summary data.
//

import Combine
import SwiftUI

@MainActor
class WorkoutSessionManager: ObservableObject {
    static let shared = WorkoutSessionManager()

    init() {
        setupDarwinBridge()
    }

    // MARK: - Published State

    @Published var isActive = false
    @Published var startTime: Date?
    @Published var elapsedSeconds: Int = 0
    @Published var isPaused = false
    @Published var currentDayName: String?
    @Published var workoutName: String?

    /// "{day}-{exerciseIndex}-{setIndex}" keys for completed sets
    @Published var completedSetIds: Set<String> = []
    /// Sets marked as failure
    @Published var failedSetIds: Set<String> = []
    /// Exercises marked as skipped/discarded: key = "{day}-{exerciseIndex}"
    @Published var skippedExercises: Set<String> = []

    // Rest timer
    @Published var restTimerActive = false
    @Published var restTimerRemaining: Int = 0
    @Published var restTimerTotal: Int = 0
    @Published var nextSetInfo: String?

    /// Extra sets added per exercise: key = "{day}-{exerciseIndex}"
    @Published var addedSets: [String: Int] = [:]

    /// Reps actually performed per set (overrides plan reps)
    @Published var actualReps: [String: Int] = [:]

    // MARK: - Summary Data (populated on finish)

    @Published var showSummary = false
    @Published var summaryData: WorkoutSummary?

    // MARK: - Save State

    enum SaveState: Equatable { case idle, saving, saved, failed }
    @Published var saveState: SaveState = .idle
    private var pendingSaveRequest: SaveWorkoutSessionRequest?

    /// Metrics delivered from the watch at finish; included in the next backend save, then cleared.
    var pendingWatchMetrics: WorkoutMetrics?

    // MARK: - Private

    private var elapsedTimer: AnyCancellable?
    private var restTimer: AnyCancellable?
    private var restEndTime: Date?
    private var pauseStartTime: Date?
    private var totalPausedSeconds: TimeInterval = 0

    // MARK: - Session Lifecycle

    func startWorkout(dayName: String, workoutName: String?, trainingManager: TrainingManager? = nil) {
        isActive = true
        startTime = Date()
        elapsedSeconds = 0
        isPaused = false
        currentDayName = dayName
        self.workoutName = workoutName
        completedSetIds.removeAll()
        failedSetIds.removeAll()
        skippedExercises.removeAll()
        addedSets.removeAll()
        actualReps.removeAll()
        totalPausedSeconds = 0
        summaryData = nil
        showSummary = false

        // Pre-populate completed sets from already-logged weights
        if let tm = trainingManager {
            prePopulateFromWeights(dayName: dayName, trainingManager: tm)
        }

        startElapsedTimer()
        UIImpactFeedbackGenerator(style: .heavy).impactOccurred()

        // Seed the shared store and start the Live Activity
        let tm = trainingManager ?? TrainingManager.shared
        let live = buildLiveWorkout(dayName: dayName, trainingManager: tm, seedCursorAtZero: true)
        SharedWorkoutStore.save(live)
        WorkoutActivityController.shared.start(
            dayName: dayName,
            state: WorkoutActivityController.contentState(from: live)
        )
        PhoneWCManager.shared.broadcast()
    }

    /// Mark sets as completed if they already have weight data saved
    private func prePopulateFromWeights(dayName: String, trainingManager: TrainingManager) {
        let normalizedDay = dayName.lowercased()
            .folding(options: .diacriticInsensitive, locale: .current)

        guard let dayData = trainingManager.trainingData.first(where: {
            $0.day.lowercased()
                .folding(options: .diacriticInsensitive, locale: .current) == normalizedDay
        }) else { return }

        for exercise in dayData.exercises.sorted(by: { $0.orderIndex < $1.orderIndex }) {
            for setIdx in 0..<exercise.sets {
                let weightKey = trainingManager.generateWeightKey(
                    day: normalizedDay,
                    exerciseIndex: exercise.orderIndex,
                    exerciseName: exercise.name,
                    setIndex: setIdx
                )
                if let w = trainingManager.weights[weightKey], w > 0 {
                    let key = setKey(day: normalizedDay, exerciseIndex: exercise.orderIndex, setIndex: setIdx)
                    completedSetIds.insert(key)
                }
            }
        }
    }

    func pauseWorkout() {
        isPaused = true
        pauseStartTime = Date()
        elapsedTimer?.cancel()
    }

    func resumeWorkout() {
        if let pauseStart = pauseStartTime {
            totalPausedSeconds += Date().timeIntervalSince(pauseStart)
        }
        isPaused = false
        pauseStartTime = nil
        startElapsedTimer()
    }

    func finishWorkout(
        trainingManager: TrainingManager
    ) -> WorkoutSummary {
        elapsedTimer?.cancel()
        restTimer?.cancel()
        restTimerActive = false

        let duration = elapsedSeconds
        let summary = buildSummary(
            duration: duration,
            trainingManager: trainingManager
        )
        summaryData = summary
        showSummary = true
        // The workout is done: show a final "completed" card on the Live Activity, then
        // let it auto-dismiss. (resetAll() still ends it immediately on summary dismiss.)
        if let live = SharedWorkoutStore.load() {
            var finished = WorkoutActivityController.contentState(from: live)
            finished.isFinished = true
            WorkoutActivityController.shared.finish(state: finished)
        }
        SharedWorkoutStore.save(nil)
        PhoneWCManager.shared.broadcast()
        return summary
    }

    func discardWorkout() {
        resetAll()
    }

    func saveAndDismissSummary() {
        showSummary = false
        resetAll()
    }

    /// Persist workout session to backend
    func saveSessionToBackend(
        userId: String,
        planId: String?,
        trainingManager: TrainingManager
    ) {
        let watchMetrics = pendingWatchMetrics
        pendingWatchMetrics = nil
        guard let summary = summaryData, let dayName = currentDayName else { return }

        let normalizedDay = dayName.lowercased()
            .folding(options: .diacriticInsensitive, locale: .current)

        // Build per-exercise data
        var exerciseData: [ExerciseSessionData] = []
        if let dayData = trainingManager.trainingData.first(where: {
            $0.day.lowercased()
                .folding(options: .diacriticInsensitive, locale: .current) == normalizedDay
        }) {
            for exercise in dayData.exercises.sorted(by: { $0.orderIndex < $1.orderIndex }) {
                let skipped = isExerciseSkipped(day: normalizedDay, exerciseIndex: exercise.orderIndex)
                let total = exercise.sets + extraSets(day: normalizedDay, exerciseIndex: exercise.orderIndex)
                let done = skipped ? 0 : completedSetsCount(day: normalizedDay, exerciseIndex: exercise.orderIndex, totalSets: total)

                var volume: Double = 0
                if !skipped {
                    for setIdx in 0..<total {
                        let key = setKey(day: normalizedDay, exerciseIndex: exercise.orderIndex, setIndex: setIdx)
                        if completedSetIds.contains(key) {
                            let weightKey = trainingManager.generateWeightKey(
                                day: normalizedDay,
                                exerciseIndex: exercise.orderIndex,
                                exerciseName: exercise.name,
                                setIndex: setIdx
                            )
                            let weight = trainingManager.weights[weightKey] ?? 0
                            let reps = actualReps[key] ?? parseReps(exercise.reps)
                            volume += weight * Double(reps)
                        }
                    }
                }

                exerciseData.append(ExerciseSessionData(
                    name: exercise.name,
                    exerciseIndex: exercise.orderIndex,
                    setsCompleted: done,
                    setsTotal: total,
                    totalVolume: volume,
                    skipped: skipped
                ))
            }
        }

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        let dateStr = dateFormatter.string(from: summary.date)

        let request = SaveWorkoutSessionRequest(
            userId: userId,
            planId: planId,
            dayName: dayName,
            workoutName: workoutName,
            durationSeconds: summary.duration,
            totalVolume: summary.totalVolume,
            totalSets: summary.totalSets,
            exercisesCompleted: summary.exercisesCompleted,
            exercisesTotal: summary.exercisesTotal,
            exercisesSkipped: Int(skippedExercises.count),
            exercises: exerciseData,
            date: dateStr,
            avgHeartRate: watchMetrics.map { $0.avgHeartRate > 0 ? $0.avgHeartRate : nil } ?? nil,
            maxHeartRate: watchMetrics.map { $0.maxHeartRate > 0 ? $0.maxHeartRate : nil } ?? nil,
            activeEnergyKcal: watchMetrics.map { $0.activeEnergyKcal > 0 ? $0.activeEnergyKcal : nil } ?? nil
        )

        pendingSaveRequest = request
        performSave()
    }

    private func performSave() {
        guard let request = pendingSaveRequest else { return }
        saveState = .saving
        Task { @MainActor in
            do {
                try await APIService.shared.saveWorkoutSession(request)
                saveState = .saved
                pendingSaveRequest = nil
            } catch {
                print("Error saving workout session: \(error)")
                saveState = .failed
            }
        }
    }

    /// Re-attempt the last failed backend save (uses the already-built request so
    /// it works even after session state has been cleared).
    func retrySave() {
        guard pendingSaveRequest != nil else { return }
        performSave()
    }

    private func resetAll() {
        elapsedTimer?.cancel()
        restTimer?.cancel()
        isActive = false
        startTime = nil
        elapsedSeconds = 0
        isPaused = false
        currentDayName = nil
        workoutName = nil
        completedSetIds.removeAll()
        failedSetIds.removeAll()
        skippedExercises.removeAll()
        addedSets.removeAll()
        actualReps.removeAll()
        restTimerActive = false
        restTimerRemaining = 0
        restTimerTotal = 0
        restEndTime = nil
        nextSetInfo = nil
        totalPausedSeconds = 0
        pauseStartTime = nil
        summaryData = nil
        showSummary = false
        saveState = .idle
        pendingSaveRequest = nil
        SharedWorkoutStore.save(nil)
        WorkoutActivityController.shared.end()
    }

    // MARK: - Set Completion

    func setKey(day: String, exerciseIndex: Int, setIndex: Int) -> String {
        "\(day)-\(exerciseIndex)-\(setIndex)"
    }

    func exerciseKey(day: String, exerciseIndex: Int) -> String {
        "\(day)-\(exerciseIndex)"
    }

    func completeSet(
        day: String,
        exerciseIndex: Int,
        setIndex: Int,
        restSeconds: Int,
        nextInfo: String? = nil
    ) {
        let key = setKey(day: day, exerciseIndex: exerciseIndex, setIndex: setIndex)
        completedSetIds.insert(key)
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()

        if restSeconds > 0 {
            startRestTimer(seconds: restSeconds, nextSetInfo: nextInfo)
        }

        // App → store: mirror this completion into the shared store + activity.
        if isActive {
            mirrorCompletionToStore(
                exerciseIndex: exerciseIndex,
                setIndex: setIndex,
                restSeconds: restSeconds,
                trainingManager: .shared
            )
        }
    }

    /// Reflect an in-app set completion into the shared store and refresh the
    /// Live Activity. Matches the store `LiveSet` by exerciseIndex + setIndex.
    /// Additive: does NOT touch weight persistence — only the live mirror.
    private func mirrorCompletionToStore(
        exerciseIndex: Int,
        setIndex: Int,
        restSeconds: Int,
        trainingManager: TrainingManager
    ) {
        guard var w = SharedWorkoutStore.load() else { return }
        guard let day = currentDayName else { return }
        let normalizedDay = day.lowercased()
            .folding(options: .diacriticInsensitive, locale: .current)

        guard let idx = w.sets.firstIndex(where: {
            $0.exerciseIndex == exerciseIndex && $0.setIndex == setIndex
        }) else { return }

        w.sets[idx].completed = true

        // Pull the latest weight/reps from in-app state where available.
        let exerciseName = w.sets[idx].exerciseName
        let weightKey = trainingManager.generateWeightKey(
            day: normalizedDay,
            exerciseIndex: exerciseIndex,
            exerciseName: exerciseName,
            setIndex: setIndex
        )
        if let weight = trainingManager.weights[weightKey], weight > 0 {
            w.sets[idx].weight = weight
        }
        let repsKey = setKey(day: normalizedDay, exerciseIndex: exerciseIndex, setIndex: setIndex)
        if let reps = actualReps[repsKey] {
            w.sets[idx].reps = reps
        }

        w.restEndDate = restSeconds > 0
            ? Date().addingTimeInterval(TimeInterval(restSeconds))
            : nil
        w.advanceCursor()

        SharedWorkoutStore.save(w)
        WorkoutActivityController.shared.update(
            WorkoutActivityController.contentState(from: w)
        )
        PhoneWCManager.shared.broadcast()
    }

    /// Rebuild the shared store's per-set weight/reps/completed from the current
    /// session + TrainingManager state and refresh the activity. Use after
    /// weight edits made in-app. Reuses the same iteration as `buildLiveWorkout`,
    /// preserving the existing cursor/restEndDate when possible.
    func syncStoreFromSession(trainingManager: TrainingManager) {
        guard isActive, let dayName = currentDayName else { return }
        let existing = SharedWorkoutStore.load()
        var live = buildLiveWorkout(dayName: dayName, trainingManager: trainingManager)
        // Preserve any in-flight rest timer state from the existing store.
        if let existing {
            live.restEndDate = existing.restEndDate
        }
        SharedWorkoutStore.save(live)
        WorkoutActivityController.shared.update(
            WorkoutActivityController.contentState(from: live)
        )
    }

    // MARK: - Store → App Reconciliation (widget mutations)

    /// Pull mutations made via the widget (in the shared store) back into the
    /// session and TrainingManager. Idempotent: safe to call repeatedly.
    ///
    /// Mapping:
    /// - For each store `LiveSet` with `completed == true` whose `setKey`
    ///   (day = normalized `currentDayName`) is NOT already in `completedSetIds`:
    ///   insert into `completedSetIds`, record `actualReps[key] = liveSet.reps`,
    ///   and push `liveSet.weight` into `trainingManager.weights` via `updateWeight`.
    /// - For the CURRENT (incomplete) cursor set, mirror its weight/reps so live
    ///   widget adjustments show in-app even before completion.
    /// - Each exercise that gained newly-completed sets is persisted via
    ///   `saveWeightsToDatabase` (skipped if no authenticated userId).
    func reconcileFromStore(trainingManager: TrainingManager) {
        guard isActive, let dayName = currentDayName else { return }
        guard let w = SharedWorkoutStore.load() else { return }

        let normalizedDay = dayName.lowercased()
            .folding(options: .diacriticInsensitive, locale: .current)

        var newlyCompleted = false
        // exerciseIndex -> exerciseName, for exercises that gained completed sets
        var exercisesToPersist: [Int: String] = [:]

        for liveSet in w.sets {
            let key = setKey(
                day: normalizedDay,
                exerciseIndex: liveSet.exerciseIndex,
                setIndex: liveSet.setIndex
            )

            if liveSet.completed {
                // Always reflect the widget's weight/reps for completed sets.
                if liveSet.weight > 0 {
                    trainingManager.updateWeight(
                        day: normalizedDay,
                        exerciseIndex: liveSet.exerciseIndex,
                        exerciseName: liveSet.exerciseName,
                        setIndex: liveSet.setIndex,
                        weight: liveSet.weight
                    )
                }
                if !completedSetIds.contains(key) {
                    completedSetIds.insert(key)
                    actualReps[key] = liveSet.reps
                    newlyCompleted = true
                    exercisesToPersist[liveSet.exerciseIndex] = liveSet.exerciseName
                } else if actualReps[key] != liveSet.reps {
                    actualReps[key] = liveSet.reps
                }
            }
        }

        // Mirror the current (incomplete) cursor set's adjustments in-app.
        if let current = w.current, !current.completed, current.weight > 0 {
            trainingManager.updateWeight(
                day: normalizedDay,
                exerciseIndex: current.exerciseIndex,
                exerciseName: current.exerciseName,
                setIndex: current.setIndex,
                weight: current.weight
            )
        }

        // Persist exercises that gained completed sets (if authenticated).
        if newlyCompleted, let userId = AuthManager.shared.user?.id {
            for (exerciseIndex, exerciseName) in exercisesToPersist {
                let name = exerciseName
                let idx = exerciseIndex
                Task {
                    await trainingManager.saveWeightsToDatabase(
                        day: normalizedDay,
                        exerciseIndex: idx,
                        exerciseName: name,
                        note: "",
                        userId: userId
                    )
                }
            }
        }

        // Refresh the Live Activity from the (authoritative) store state.
        WorkoutActivityController.shared.update(
            WorkoutActivityController.contentState(from: w)
        )
        PhoneWCManager.shared.broadcast()
    }

    // MARK: - Darwin Bridge

    private func setupDarwinBridge() {
        let name = SharedWorkoutStore.darwinName as CFString
        let observer = Unmanaged.passUnretained(self).toOpaque()
        CFNotificationCenterAddObserver(
            CFNotificationCenterGetDarwinNotifyCenter(),
            observer,
            { _, _, _, _, _ in
                // Darwin callbacks arrive on an arbitrary thread; bounce to main
                // and post an in-app notification the session observes.
                DispatchQueue.main.async {
                    NotificationCenter.default.post(
                        name: .liveWorkoutStoreChanged,
                        object: nil
                    )
                }
            },
            name,
            nil,
            .deliverImmediately
        )

        NotificationCenter.default.addObserver(
            forName: .liveWorkoutStoreChanged,
            object: nil,
            queue: .main
        ) { _ in
            Task { @MainActor in
                WorkoutSessionManager.shared.reconcileFromStore(
                    trainingManager: .shared
                )
            }
        }
    }

    func uncompleteSet(day: String, exerciseIndex: Int, setIndex: Int) {
        let key = setKey(day: day, exerciseIndex: exerciseIndex, setIndex: setIndex)
        completedSetIds.remove(key)
        failedSetIds.remove(key)
    }

    func isSetCompleted(day: String, exerciseIndex: Int, setIndex: Int) -> Bool {
        completedSetIds.contains(
            setKey(day: day, exerciseIndex: exerciseIndex, setIndex: setIndex)
        )
    }

    func toggleFailure(day: String, exerciseIndex: Int, setIndex: Int) {
        let key = setKey(day: day, exerciseIndex: exerciseIndex, setIndex: setIndex)
        if failedSetIds.contains(key) {
            failedSetIds.remove(key)
        } else {
            failedSetIds.insert(key)
        }
    }

    func isSetFailed(day: String, exerciseIndex: Int, setIndex: Int) -> Bool {
        failedSetIds.contains(
            setKey(day: day, exerciseIndex: exerciseIndex, setIndex: setIndex)
        )
    }

    // MARK: - Exercise Skipping

    func skipExercise(day: String, exerciseIndex: Int) {
        let key = exerciseKey(day: day, exerciseIndex: exerciseIndex)
        skippedExercises.insert(key)
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    func unskipExercise(day: String, exerciseIndex: Int) {
        let key = exerciseKey(day: day, exerciseIndex: exerciseIndex)
        skippedExercises.remove(key)
    }

    func isExerciseSkipped(day: String, exerciseIndex: Int) -> Bool {
        skippedExercises.contains(exerciseKey(day: day, exerciseIndex: exerciseIndex))
    }

    // MARK: - Added Sets

    func addSet(day: String, exerciseIndex: Int) {
        let key = exerciseKey(day: day, exerciseIndex: exerciseIndex)
        addedSets[key, default: 0] += 1
    }

    func extraSets(day: String, exerciseIndex: Int) -> Int {
        addedSets[exerciseKey(day: day, exerciseIndex: exerciseIndex)] ?? 0
    }

    /// Removes the most recently added set for an exercise (added sets only —
    /// planned sets are never removed). Clears that set's session state.
    func removeLastSet(day: String, exerciseIndex: Int, plannedSets: Int) {
        let key = exerciseKey(day: day, exerciseIndex: exerciseIndex)
        guard let extra = addedSets[key], extra > 0 else { return }
        let removedIndex = plannedSets + extra - 1
        let sk = setKey(day: day, exerciseIndex: exerciseIndex, setIndex: removedIndex)
        completedSetIds.remove(sk)
        failedSetIds.remove(sk)
        actualReps[sk] = nil
        if extra - 1 == 0 { addedSets[key] = nil } else { addedSets[key] = extra - 1 }
    }

    #if DEBUG
    @MainActor
    static func runSelfCheck() {
        let m = WorkoutSessionManager()
        m.addSet(day: "lunes", exerciseIndex: 0)
        m.addSet(day: "lunes", exerciseIndex: 0)
        assert(m.extraSets(day: "lunes", exerciseIndex: 0) == 2)
        m.removeLastSet(day: "lunes", exerciseIndex: 0, plannedSets: 3)
        assert(m.extraSets(day: "lunes", exerciseIndex: 0) == 1)
        m.removeLastSet(day: "lunes", exerciseIndex: 0, plannedSets: 3)
        m.removeLastSet(day: "lunes", exerciseIndex: 0, plannedSets: 3) // floor at 0
        assert(m.extraSets(day: "lunes", exerciseIndex: 0) == 0)

        // Save-state checks
        assert(m.saveState == .idle, "save state starts idle")
        m.retrySave() // no pending request → no-op, stays idle
        assert(m.saveState == .idle, "retry with nothing pending is a no-op")
    }
    #endif

    // MARK: - Actual Reps

    func setActualReps(day: String, exerciseIndex: Int, setIndex: Int, reps: Int) {
        let key = setKey(day: day, exerciseIndex: exerciseIndex, setIndex: setIndex)
        actualReps[key] = reps
    }

    func getActualReps(day: String, exerciseIndex: Int, setIndex: Int) -> Int? {
        actualReps[setKey(day: day, exerciseIndex: exerciseIndex, setIndex: setIndex)]
    }

    // MARK: - Rest Timer

    func startRestTimer(seconds: Int, nextSetInfo: String?) {
        restTimer?.cancel()
        restTimerTotal = seconds
        restTimerRemaining = seconds
        restEndTime = Date().addingTimeInterval(TimeInterval(seconds))
        self.nextSetInfo = nextSetInfo
        restTimerActive = true

        restTimer = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.tickRest()
            }
    }

    /// Recompute remaining from a wall-clock end time so the countdown stays
    /// correct after the app is backgrounded (Combine timers pause in the bg).
    private func tickRest() {
        guard let end = restEndTime else { return }
        let remaining = Int(ceil(end.timeIntervalSinceNow))
        if remaining > 0 {
            restTimerRemaining = remaining
        } else {
            restTimerRemaining = 0
            restTimerActive = false
            restTimer?.cancel()
            restEndTime = nil
            UINotificationFeedbackGenerator().notificationOccurred(.warning)
        }
    }

    func skipRest() {
        restTimerActive = false
        restTimerRemaining = 0
        restEndTime = nil
        restTimer?.cancel()
        PhoneWCManager.shared.broadcast()
    }

    func addRestTime(seconds: Int) {
        restTimerRemaining += seconds
        restTimerTotal += seconds
        restEndTime = (restEndTime ?? Date()).addingTimeInterval(TimeInterval(seconds))
        PhoneWCManager.shared.broadcast()
    }

    // MARK: - Elapsed Timer

    private func startElapsedTimer() {
        elapsedTimer?.cancel()
        elapsedTimer = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self, let start = self.startTime, !self.isPaused else { return }
                let total = Date().timeIntervalSince(start) - self.totalPausedSeconds
                self.elapsedSeconds = max(0, Int(total))
            }
    }

    // MARK: - Formatting

    func formattedElapsed() -> String {
        let m = elapsedSeconds / 60
        let s = elapsedSeconds % 60
        return String(format: "%d:%02d", m, s)
    }

    static func formatTime(_ seconds: Int) -> String {
        let m = seconds / 60
        let s = seconds % 60
        return String(format: "%02d:%02d", m, s)
    }

    // MARK: - Summary Builder

    private func buildSummary(
        duration: Int,
        trainingManager: TrainingManager
    ) -> WorkoutSummary {
        guard let dayName = currentDayName else {
            return WorkoutSummary(
                duration: duration, totalVolume: 0,
                totalSets: 0, exercisesCompleted: 0,
                exercisesTotal: 0, prs: [], date: Date()
            )
        }

        let normalizedDay = dayName.lowercased()
            .folding(options: .diacriticInsensitive, locale: .current)

        guard let dayData = trainingManager.trainingData.first(where: {
            $0.day.lowercased()
                .folding(options: .diacriticInsensitive, locale: .current) == normalizedDay
        }) else {
            return WorkoutSummary(
                duration: duration, totalVolume: 0,
                totalSets: 0, exercisesCompleted: 0,
                exercisesTotal: 0, prs: [], date: Date()
            )
        }

        var totalVolume: Double = 0
        var totalSetsCompleted = 0
        var exercisesCompleted = 0
        var skippedCount = 0

        for exercise in dayData.exercises.sorted(by: { $0.orderIndex < $1.orderIndex }) {
            // Skip discarded exercises
            if isExerciseSkipped(day: normalizedDay, exerciseIndex: exercise.orderIndex) {
                skippedCount += 1
                continue
            }

            let totalSetsForExercise = exercise.sets + extraSets(day: normalizedDay, exerciseIndex: exercise.orderIndex)
            var exerciseHasCompletedSet = false

            for setIdx in 0..<totalSetsForExercise {
                let key = setKey(day: normalizedDay, exerciseIndex: exercise.orderIndex, setIndex: setIdx)
                if completedSetIds.contains(key) {
                    totalSetsCompleted += 1
                    exerciseHasCompletedSet = true

                    // Volume = weight × reps
                    let weightKey = trainingManager.generateWeightKey(
                        day: normalizedDay,
                        exerciseIndex: exercise.orderIndex,
                        exerciseName: exercise.name,
                        setIndex: setIdx
                    )
                    let weight = trainingManager.weights[weightKey] ?? 0
                    let reps = actualReps[key] ?? parseReps(exercise.reps)
                    totalVolume += weight * Double(reps)
                }
            }

            if exerciseHasCompletedSet {
                exercisesCompleted += 1
            }
        }

        let effectiveTotal = dayData.exercises.count - skippedCount

        return WorkoutSummary(
            duration: duration,
            totalVolume: totalVolume,
            totalSets: totalSetsCompleted,
            exercisesCompleted: exercisesCompleted,
            exercisesTotal: effectiveTotal,
            prs: [],
            date: Date()
        )
    }

    // MARK: - Live Workout Builder

    /// Mirrors buildSummary's iteration to produce a LiveWorkout for the shared store
    /// and the Lock Screen Live Activity.
    private func buildLiveWorkout(dayName: String, trainingManager: TrainingManager, seedCursorAtZero: Bool = false) -> LiveWorkout {
        let normalizedDay = dayName.lowercased()
            .folding(options: .diacriticInsensitive, locale: .current)

        let weightUnit = UserDefaults.standard.string(forKey: "units") == "imperial" ? "lb" : "kg"
        let weightStep: Double = weightUnit == "lb" ? 5 : 2.5
        let repStep = 1

        var liveSets: [LiveWorkout.LiveSet] = []

        if let dayData = trainingManager.trainingData.first(where: {
            $0.day.lowercased()
                .folding(options: .diacriticInsensitive, locale: .current) == normalizedDay
        }) {
            for exercise in dayData.exercises.sorted(by: { $0.orderIndex < $1.orderIndex }) {
                let totalSets = exercise.sets
                for setIdx in 0..<totalSets {
                    let weightKey = trainingManager.generateWeightKey(
                        day: normalizedDay,
                        exerciseIndex: exercise.orderIndex,
                        exerciseName: exercise.name,
                        setIndex: setIdx
                    )
                    let weight = trainingManager.weights[weightKey] ?? 0
                    let reps = parseReps(exercise.reps)
                    let key = setKey(day: normalizedDay, exerciseIndex: exercise.orderIndex, setIndex: setIdx)
                    let completed = completedSetIds.contains(key)

                    liveSets.append(LiveWorkout.LiveSet(
                        exerciseIndex: exercise.orderIndex,
                        exerciseName: exercise.name,
                        setIndex: setIdx,
                        setsTotalForExercise: totalSets,
                        weight: weight,
                        reps: reps,
                        restSeconds: exercise.restSeconds,
                        completed: completed
                    ))
                }
            }
        }

        var live = LiveWorkout(
            dayName: dayName,
            workoutName: workoutName ?? dayName,
            startDate: startTime ?? Date(),
            isPaused: isPaused,
            weightUnit: weightUnit,
            weightStep: weightStep,
            repStep: repStep,
            sets: liveSets,
            cursor: 0,
            restEndDate: nil
        )
        if !seedCursorAtZero { live.advanceCursor() }
        return live
    }

    private func parseReps(_ repsString: String) -> Int {
        // Handle "8-12" → take higher, "10" → 10, "10, 8, 6" → average
        let cleaned = repsString.components(separatedBy: ",").first?
            .trimmingCharacters(in: .whitespaces) ?? repsString

        if cleaned.contains("-") {
            let parts = cleaned.split(separator: "-")
            return parts.last.flatMap { Int($0) } ?? 0
        }
        return Int(cleaned) ?? 0
    }

    // MARK: - Exercise completion helpers

    func completedSetsCount(day: String, exerciseIndex: Int, totalSets: Int) -> Int {
        (0..<totalSets).filter { isSetCompleted(day: day, exerciseIndex: exerciseIndex, setIndex: $0) }.count
    }

    func isExerciseComplete(day: String, exerciseIndex: Int, totalSets: Int) -> Bool {
        isExerciseSkipped(day: day, exerciseIndex: exerciseIndex) ||
        completedSetsCount(day: day, exerciseIndex: exerciseIndex, totalSets: totalSets) == totalSets
    }
}

// MARK: - Summary Model

struct WorkoutSummary {
    let duration: Int
    let totalVolume: Double
    let totalSets: Int
    let exercisesCompleted: Int
    let exercisesTotal: Int
    let prs: [String] // exercise names with new PRs
    let date: Date

    var formattedDuration: String {
        let m = duration / 60
        let s = duration % 60
        return String(format: "%d:%02d", m, s)
    }

    var formattedVolume: String {
        if totalVolume >= 1000 {
            return String(format: "%.1fk", totalVolume / 1000)
        }
        return String(format: "%.0f", totalVolume)
    }

    var isPartialCompletion: Bool {
        exercisesCompleted < exercisesTotal
    }
}
