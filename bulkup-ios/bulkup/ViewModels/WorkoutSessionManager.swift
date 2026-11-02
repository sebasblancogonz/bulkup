//
//  WorkoutSessionManager.swift
//  bulkup
//
//  Manages active workout session state: elapsed timer, rest countdown,
//  per-set completion tracking, failure marking, and summary data.
//

import Combine
import SwiftUI

/// The 1 Hz values (elapsed, rest remaining) live in their own observable so
/// the per-second tick only re-renders the few views that display them
/// (header, FAB label, rest sheet/banner) — NOT every exercise card. Publishing
/// them from WorkoutSessionManager itself made the whole workout screen rebuild
/// every second, which showed up as scroll hitches.
@MainActor
final class WorkoutTicker: ObservableObject {
    @Published var elapsedSeconds = 0
    @Published var restRemaining = 0
}

@MainActor
class WorkoutSessionManager: ObservableObject {
    static let shared = WorkoutSessionManager()

    init() {
        setupDarwinBridge()
    }

    // MARK: - Published State

    @Published var isActive = false
    @Published var startTime: Date?
    /// Not @Published on purpose — ticks every second; observe `ticker` to display it.
    var elapsedSeconds: Int = 0 { didSet { ticker.elapsedSeconds = elapsedSeconds } }
    @Published var isPaused = false

    let ticker = WorkoutTicker()
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
    /// Not @Published on purpose — ticks every second; observe `ticker` to display it.
    var restTimerRemaining: Int = 0 { didSet { ticker.restRemaining = restTimerRemaining } }
    @Published var restTimerTotal: Int = 0
    @Published var nextSetInfo: String?

    /// Session-only exercise swaps (machine occupied → alternative): key =
    /// "{day}-{exerciseIndex}" → alternative display name. The plan is never
    /// mutated; weights/history persist under the alternative's own name.
    /// ponytail: in-memory only — lost on process-death restore (plan names return).
    @Published var exerciseOverrides: [String: String] = [:]

    /// Whether the rest sheet is on screen. Separate from restTimerActive so
    /// dismissing the sheet doesn't hide the countdown (a banner takes over).
    @Published var restSheetVisible = false

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
        actualReps.removeAll()
        exerciseOverrides.removeAll()
        totalPausedSeconds = 0
        summaryData = nil
        showSummary = false

        // Pre-populate completed sets from already-logged weights
        if let tm = trainingManager {
            prePopulateFromWeights(dayName: dayName, trainingManager: tm)
        }

        startElapsedTimer()
        UIImpactFeedbackGenerator(style: .heavy).impactOccurred()

        // Seed the shared store and start the Live Activity.
        // "Comenzar" (fresh, nothing pre-marked) → cursor at the first exercise.
        // "Continuar" (sets already logged this week were pre-marked complete by
        // prePopulateFromWeights) → cursor at the first INCOMPLETE set (resume).
        let tm = trainingManager ?? TrainingManager.shared
        let isResume = !completedSetIds.isEmpty
        let live = buildLiveWorkout(dayName: dayName, trainingManager: tm, seedCursorAtZero: !isResume)
        SharedWorkoutStore.save(live)
        WorkoutActivityController.shared.start(
            dayName: dayName,
            state: WorkoutActivityController.contentState(from: live)
        )
        PhoneWCManager.shared.broadcast()
    }

    // MARK: - Session Restoration (process death mid-workout)

    /// The session lives in memory and dies with the process; the shared store
    /// does not. If iOS terminated the app during a workout (routine after an
    /// hour+ in the background), rebuild the session from the store on return
    /// so the workout isn't lost. Safe to call any time: no-ops when a session
    /// is already active or nothing is stored.
    func restoreIfNeeded(trainingManager: TrainingManager) {
        guard !isActive, let live = SharedWorkoutStore.load() else { return }
        // ponytail: 8h cutoff — a workout abandoned that long ago is garbage, not a resume.
        guard Date().timeIntervalSince(live.startDate) < 8 * 3600 else {
            SharedWorkoutStore.save(nil)
            WorkoutActivityController.shared.end()
            return
        }
        restore(from: live)
        WorkoutActivityController.shared.adoptOrStart(
            dayName: live.dayName,
            state: WorkoutActivityController.contentState(from: live)
        )
        // Pushes the restored completions/weights into TrainingManager and re-broadcasts.
        reconcileFromStore(trainingManager: trainingManager)
    }

    /// Rebuild in-memory session state from a stored LiveWorkout. Pure state —
    /// no store/activity side effects (kept separate for the DEBUG self-check).
    func restore(from live: LiveWorkout) {
        isActive = true
        startTime = live.startDate
        elapsedSeconds = max(0, Int(Date().timeIntervalSince(live.startDate)))
        isPaused = false
        currentDayName = live.dayName
        workoutName = live.workoutName
        completedSetIds.removeAll()
        failedSetIds.removeAll()
        skippedExercises.removeAll()
        actualReps.removeAll()
        totalPausedSeconds = 0 // ponytail: pause spans don't survive relaunch; elapsed runs from startDate
        summaryData = nil
        showSummary = false
        let day = live.dayName.lowercased()
            .folding(options: .diacriticInsensitive, locale: .current)
        for s in live.sets where s.completed {
            let key = setKey(day: day, exerciseIndex: s.exerciseIndex, setIndex: s.setIndex)
            completedSetIds.insert(key)
            actualReps[key] = s.reps
        }
        startElapsedTimer()
    }

    /// Mark sets as completed if they already have weight data saved
    private func prePopulateFromWeights(dayName: String, trainingManager: TrainingManager) {
        let normalizedDay = dayName.lowercased()
            .folding(options: .diacriticInsensitive, locale: .current)

        guard let dayData = trainingManager.trainingData.first(where: {
            $0.day.lowercased()
                .folding(options: .diacriticInsensitive, locale: .current) == normalizedDay
        }) else { return }

        var totalSets = 0
        for exercise in dayData.exercises.sorted(by: { $0.orderIndex < $1.orderIndex }) {
            for setIdx in 0..<trainingManager.effectiveSets(for: exercise, day: normalizedDay) {
                totalSets += 1
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

        // Every set already logged → the user is redoing the day, not resuming.
        // Start fresh instead of seeding an instantly-finished session (the watch
        // would otherwise open on "Workout complete" with no way to do anything).
        if totalSets > 0 && completedSetIds.count == totalSets {
            completedSetIds.removeAll()
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
        restSheetVisible = false

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
                let total = trainingManager.effectiveSets(for: exercise, day: normalizedDay)
                let done = skipped ? 0 : completedSetsCount(day: normalizedDay, exerciseIndex: exercise.orderIndex, totalSets: total)
                let name = effectiveExerciseName(day: normalizedDay,
                                                 exerciseIndex: exercise.orderIndex,
                                                 planName: exercise.name)

                var volume: Double = 0
                if !skipped {
                    for setIdx in 0..<total {
                        let key = setKey(day: normalizedDay, exerciseIndex: exercise.orderIndex, setIndex: setIdx)
                        if completedSetIds.contains(key) {
                            let weightKey = trainingManager.generateWeightKey(
                                day: normalizedDay,
                                exerciseIndex: exercise.orderIndex,
                                exerciseName: name,
                                setIndex: setIdx
                            )
                            let weight = trainingManager.weights[weightKey] ?? 0
                            let reps = actualReps[key] ?? TrainingManager.plannedReps(exercise.reps, setIndex: setIdx)
                            volume += weight * Double(reps)
                        }
                    }
                }

                exerciseData.append(ExerciseSessionData(
                    name: name,
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
        actualReps.removeAll()
        exerciseOverrides.removeAll()
        restTimerActive = false
        restSheetVisible = false
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
        // Without this, a discarded workout stays on the watch until the next broadcast.
        PhoneWCManager.shared.broadcast()
    }

    // MARK: - Exercise Overrides (session-only alternatives)

    func overrideExercise(day: String, exerciseIndex: Int, name: String) {
        exerciseOverrides[exerciseKey(day: day, exerciseIndex: exerciseIndex)] = name
    }

    /// The name the session is actually performing for this slot: the swapped
    /// alternative if one was chosen, otherwise the plan's exercise name.
    func effectiveExerciseName(day: String, exerciseIndex: Int, planName: String) -> String {
        exerciseOverrides[exerciseKey(day: day, exerciseIndex: exerciseIndex)] ?? planName
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
        // Only for the session's own day: the store's set identities are
        // (exerciseIndex, setIndex) and would collide with another day's.
        if isActive, isSessionDay(day) {
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
        // The watch reads the same live state — without this, weights typed on the
        // phone never reach it and its completion guard blocks a valid set.
        PhoneWCManager.shared.broadcast()
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
    /// - Incomplete sets are NOT mirrored: their store weight may be a seeded
    ///   previous-week prefill, which must only persist on completion.
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
        // exerciseIndex -> (setIndex -> weight/reps): the store's authoritative
        // values for completed sets, passed to the save so it doesn't re-read
        // the `weights` dict (which loadWeightsForWeek can clear mid-flight).
        var setValuesByExercise: [Int: [Int: (weight: Double, reps: Int)]] = [:]

        for liveSet in w.sets {
            let key = setKey(
                day: normalizedDay,
                exerciseIndex: liveSet.exerciseIndex,
                setIndex: liveSet.setIndex
            )

            if liveSet.completed {
                setValuesByExercise[liveSet.exerciseIndex, default: [:]][liveSet.setIndex] =
                    (weight: liveSet.weight, reps: liveSet.reps)
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
                // Reps too — without this, sets completed on the watch keep the
                // plan's reps in the app (setReps is what the cards/recap read
                // and what saveWeightsToDatabase falls back to).
                if liveSet.reps > 0 {
                    trainingManager.updateReps(
                        day: normalizedDay,
                        exerciseIndex: liveSet.exerciseIndex,
                        exerciseName: liveSet.exerciseName,
                        setIndex: liveSet.setIndex,
                        reps: liveSet.reps
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

        // Persist exercises that gained completed sets (if authenticated).
        if newlyCompleted, let userId = AuthManager.shared.user?.id {
            for (exerciseIndex, exerciseName) in exercisesToPersist {
                let name = exerciseName
                let idx = exerciseIndex
                let setValues = setValuesByExercise[idx]
                Task {
                    await trainingManager.saveWeightsToDatabase(
                        day: normalizedDay,
                        exerciseIndex: idx,
                        exerciseName: name,
                        note: "",
                        userId: userId,
                        setOverrides: setValues
                    )
                }
            }
        }

        // Rest started/skipped/extended on the watch or Live Activity lives only
        // in the store's restEndDate; mirror it into the phone's countdown.
        syncRestTimer(from: w)

        // Refresh the Live Activity from the (authoritative) store state.
        WorkoutActivityController.shared.update(
            WorkoutActivityController.contentState(from: w)
        )
        PhoneWCManager.shared.broadcast()
    }

    /// Store → phone rest countdown. A rest running elsewhere shows as the
    /// banner (not the sheet) so returning to the app isn't hijacked; a rest
    /// skipped elsewhere stops the phone's countdown.
    private func syncRestTimer(from w: LiveWorkout) {
        if let end = w.restEndDate, end > Date() {
            if let current = restEndTime {
                let delta = end.timeIntervalSince(current)
                // Same rest (phone-originated, mirrored ms apart) → nothing to do.
                guard abs(delta) > 1.5 else { return }
                restEndTime = end
                restTimerTotal = max(1, restTimerTotal + Int(delta.rounded()))
                tickRest()
            } else {
                let remaining = Int(ceil(end.timeIntervalSinceNow))
                startRestTimer(seconds: remaining, nextSetInfo: nil, showSheet: false)
                restEndTime = end
                tickRest()
            }
        } else if restEndTime != nil {
            stopRestTimer(haptic: false)
        }
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

        // Mirror into the store too. Without this the store still says
        // "completed", and the next reconcile (foreground, any watch message)
        // silently re-completes the set the user just unchecked.
        if isActive, isSessionDay(day), var w = SharedWorkoutStore.load() {
            w.uncomplete(exerciseIndex: exerciseIndex, setIndex: setIndex)
            SharedWorkoutStore.save(w)
            WorkoutActivityController.shared.update(
                WorkoutActivityController.contentState(from: w)
            )
            PhoneWCManager.shared.broadcast()
        }
    }

    /// Whether `day` (already diacritic-folded) is the active session's day.
    private func isSessionDay(_ day: String) -> Bool {
        guard let current = currentDayName else { return false }
        return current.lowercased()
            .folding(options: .diacriticInsensitive, locale: .current) == day
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

    // MARK: - Added / removed sets

    /// Sets beyond (or short of) the plan's count for this week. The count
    /// itself lives in TrainingManager so it survives the session and shows the
    /// same in the recap and the non-session logger.
    func extraSets(day: String, exerciseIndex: Int) -> Int {
        TrainingManager.shared.setCountDelta(day: day, exerciseIndex: exerciseIndex)
    }

    func addSet(day: String, exerciseIndex: Int, plannedSets: Int, trainingManager: TrainingManager) {
        trainingManager.addSet(day: day, exerciseIndex: exerciseIndex, plannedSets: plannedSets)
        if isActive, isSessionDay(day) {
            // The watch / Live Activity need the new row.
            syncStoreFromSession(trainingManager: trainingManager)
        }
    }

    /// Removes one set (any index, planned or added) for this week: the stored
    /// weights/reps shift down in TrainingManager, the per-set session state
    /// shifts here, and the live store is rebuilt so the watch matches.
    func removeSet(
        day: String, exerciseIndex: Int, exerciseName: String, plannedSets: Int, setIndex: Int,
        trainingManager: TrainingManager
    ) {
        let total = trainingManager.effectiveSets(
            plannedSets: plannedSets, day: day, exerciseIndex: exerciseIndex
        )
        guard trainingManager.removeSet(
            day: day, exerciseIndex: exerciseIndex, exerciseName: exerciseName,
            plannedSets: plannedSets, setIndex: setIndex
        ) != nil else { return }
        shiftSessionState(day: day, exerciseIndex: exerciseIndex, removedIndex: setIndex, total: total)
        if isActive, isSessionDay(day) {
            syncStoreFromSession(trainingManager: trainingManager)
        }
    }

    /// Shift completed/failed/reps state down one slot after `removedIndex`
    /// and clear the (now unused) last slot. Pure session state — testable.
    func shiftSessionState(day: String, exerciseIndex: Int, removedIndex: Int, total: Int) {
        guard total > 0, removedIndex >= 0, removedIndex < total else { return }
        for i in removedIndex..<(total - 1) {
            let from = setKey(day: day, exerciseIndex: exerciseIndex, setIndex: i + 1)
            let to = setKey(day: day, exerciseIndex: exerciseIndex, setIndex: i)
            if completedSetIds.contains(from) { completedSetIds.insert(to) } else { completedSetIds.remove(to) }
            if failedSetIds.contains(from) { failedSetIds.insert(to) } else { failedSetIds.remove(to) }
            actualReps[to] = actualReps[from]
        }
        let last = setKey(day: day, exerciseIndex: exerciseIndex, setIndex: total - 1)
        completedSetIds.remove(last)
        failedSetIds.remove(last)
        actualReps[last] = nil
    }

    #if DEBUG
    @MainActor
    static func runSelfCheck() {
        let m = WorkoutSessionManager()
        // Removing set 1 of 3 (sets 0 and 2 done, set 2 failed with 8 reps)
        // leaves set 0 as-is, moves set 2's state into slot 1 and clears slot 2.
        m.completedSetIds = [m.setKey(day: "lunes", exerciseIndex: 0, setIndex: 0),
                             m.setKey(day: "lunes", exerciseIndex: 0, setIndex: 2)]
        m.failedSetIds = [m.setKey(day: "lunes", exerciseIndex: 0, setIndex: 2)]
        m.actualReps[m.setKey(day: "lunes", exerciseIndex: 0, setIndex: 2)] = 8
        m.shiftSessionState(day: "lunes", exerciseIndex: 0, removedIndex: 1, total: 3)
        assert(m.isSetCompleted(day: "lunes", exerciseIndex: 0, setIndex: 0))
        assert(m.isSetCompleted(day: "lunes", exerciseIndex: 0, setIndex: 1), "set 2 shifted into slot 1")
        assert(m.isSetFailed(day: "lunes", exerciseIndex: 0, setIndex: 1))
        assert(m.getActualReps(day: "lunes", exerciseIndex: 0, setIndex: 1) == 8)
        assert(!m.isSetCompleted(day: "lunes", exerciseIndex: 0, setIndex: 2), "last slot cleared")
        assert(m.getActualReps(day: "lunes", exerciseIndex: 0, setIndex: 2) == nil)
        // Removing the last set just clears it.
        m.shiftSessionState(day: "lunes", exerciseIndex: 0, removedIndex: 1, total: 2)
        assert(!m.isSetCompleted(day: "lunes", exerciseIndex: 0, setIndex: 1))
        assert(m.isSetCompleted(day: "lunes", exerciseIndex: 0, setIndex: 0), "earlier sets untouched")

        // Session-only exercise overrides
        assert(m.effectiveExerciseName(day: "lunes", exerciseIndex: 2, planName: "Press banca") == "Press banca")
        m.overrideExercise(day: "lunes", exerciseIndex: 2, name: "Press mancuernas")
        assert(m.effectiveExerciseName(day: "lunes", exerciseIndex: 2, planName: "Press banca") == "Press mancuernas")
        assert(m.effectiveExerciseName(day: "lunes", exerciseIndex: 3, planName: "Sentadilla") == "Sentadilla",
               "override is scoped to its exercise slot")

        // Save-state checks
        assert(m.saveState == .idle, "save state starts idle")
        m.retrySave() // no pending request → no-op, stays idle
        assert(m.saveState == .idle, "retry with nothing pending is a no-op")

        // Restoration: a stored LiveWorkout rebuilds the in-memory session.
        let r = WorkoutSessionManager()
        let live = LiveWorkout(
            dayName: "Miércoles", workoutName: "Pull", startDate: Date().addingTimeInterval(-1800),
            isPaused: false, weightUnit: "kg", weightStep: 2.5, repStep: 1,
            sets: [
                .init(exerciseIndex: 0, exerciseName: "Remo", setIndex: 0, setsTotalForExercise: 2,
                      weight: 60, reps: 8, restSeconds: 90, completed: true, weightTracking: true),
                .init(exerciseIndex: 0, exerciseName: "Remo", setIndex: 1, setsTotalForExercise: 2,
                      weight: 60, reps: 8, restSeconds: 90, completed: false, weightTracking: true),
            ],
            cursor: 1, restEndDate: nil
        )
        r.restore(from: live)
        assert(r.isActive, "restore reactivates the session")
        assert(r.currentDayName == "Miércoles" && r.workoutName == "Pull", "restore recovers identity")
        assert(r.isSetCompleted(day: "miercoles", exerciseIndex: 0, setIndex: 0), "restore rebuilds completed sets (folded day key)")
        assert(!r.isSetCompleted(day: "miercoles", exerciseIndex: 0, setIndex: 1), "incomplete sets stay incomplete")
        assert(r.getActualReps(day: "miercoles", exerciseIndex: 0, setIndex: 0) == 8, "restore recovers reps")
        assert(r.elapsedSeconds >= 1799, "elapsed resumes from the original start date")
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

    func startRestTimer(seconds: Int, nextSetInfo: String?, showSheet: Bool = true) {
        restTimer?.cancel()
        restTimerTotal = seconds
        restTimerRemaining = seconds
        restEndTime = Date().addingTimeInterval(TimeInterval(seconds))
        self.nextSetInfo = nextSetInfo
        restTimerActive = true
        restSheetVisible = showSheet

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
            stopRestTimer(haptic: true)
        }
    }

    private func stopRestTimer(haptic: Bool) {
        restTimerRemaining = 0
        restTimerActive = false
        restSheetVisible = false
        restTimer?.cancel()
        restEndTime = nil
        if haptic {
            UINotificationFeedbackGenerator().notificationOccurred(.warning)
        }
    }

    func skipRest() {
        stopRestTimer(haptic: false)
        // The watch and Live Activity count down from the store's restEndDate;
        // clear it or they keep showing a rest the user already skipped.
        mirrorRestToStore { $0.skipRest() }
        PhoneWCManager.shared.broadcast()
    }

    func addRestTime(seconds: Int) {
        restTimerRemaining += seconds
        restTimerTotal += seconds
        restEndTime = (restEndTime ?? Date()).addingTimeInterval(TimeInterval(seconds))
        mirrorRestToStore { $0.addRest(seconds) }
        PhoneWCManager.shared.broadcast()
    }

    /// Apply a rest mutation to the shared store and refresh the Live Activity.
    private func mirrorRestToStore(_ mutate: (inout LiveWorkout) -> Void) {
        guard isActive, var w = SharedWorkoutStore.load() else { return }
        mutate(&w)
        // Keep the store's end in lockstep with the phone's (addRest on a store
        // without a running rest would otherwise start from "now").
        w.restEndDate = restEndTime
        SharedWorkoutStore.save(w)
        WorkoutActivityController.shared.update(
            WorkoutActivityController.contentState(from: w)
        )
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

            let totalSetsForExercise = trainingManager.effectiveSets(for: exercise, day: normalizedDay)
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
                        exerciseName: effectiveExerciseName(day: normalizedDay,
                                                            exerciseIndex: exercise.orderIndex,
                                                            planName: exercise.name),
                        setIndex: setIdx
                    )
                    let weight = trainingManager.weights[weightKey] ?? 0
                    let reps = actualReps[key] ?? TrainingManager.plannedReps(exercise.reps, setIndex: setIdx)
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
                let totalSets = trainingManager.effectiveSets(for: exercise, day: normalizedDay)
                let name = effectiveExerciseName(day: normalizedDay,
                                                 exerciseIndex: exercise.orderIndex,
                                                 planName: exercise.name)
                for setIdx in 0..<totalSets {
                    let weightKey = trainingManager.generateWeightKey(
                        day: normalizedDay,
                        exerciseIndex: exercise.orderIndex,
                        exerciseName: name,
                        setIndex: setIdx
                    )
                    // Fall back to the last logged weight (up to 4 weeks back) so the
                    // watch/widget steppers start from a real value instead of 0 —
                    // completion requires weight > 0 and their only input is ±step.
                    let weight = trainingManager.weights[weightKey]
                        ?? previousWeekWeight(trainingManager: trainingManager, day: normalizedDay,
                                              exerciseIndex: exercise.orderIndex, exerciseName: name,
                                              setIndex: setIdx)
                        ?? 0
                    // Per-set target: "10, 8, 6" → 10/8/6, "8-12-10" → 8/12/10.
                    let reps = TrainingManager.plannedReps(exercise.reps, setIndex: setIdx)
                    let key = setKey(day: normalizedDay, exerciseIndex: exercise.orderIndex, setIndex: setIdx)
                    let completed = completedSetIds.contains(key)

                    liveSets.append(LiveWorkout.LiveSet(
                        exerciseIndex: exercise.orderIndex,
                        exerciseName: name,
                        setIndex: setIdx,
                        setsTotalForExercise: totalSets,
                        weight: weight,
                        reps: reps,
                        restSeconds: exercise.restSeconds,
                        completed: completed,
                        weightTracking: exercise.weightTracking
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

    /// Last logged weight for this set in the 4 weeks before the selected week
    /// (same lookup as ExerciseCardView.loadPreviousWeights).
    private func previousWeekWeight(trainingManager: TrainingManager, day: String,
                                    exerciseIndex: Int, exerciseName: String, setIndex: Int) -> Double? {
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd"
        var checkWeek = trainingManager.selectedWeek
        for _ in 0..<4 {
            checkWeek = Calendar.current.date(byAdding: .weekOfYear, value: -1, to: checkWeek) ?? checkWeek
            let key = trainingManager.generateWeightKey(
                day: day,
                exerciseIndex: exerciseIndex,
                exerciseName: exerciseName,
                setIndex: setIndex,
                weekStart: df.string(from: trainingManager.getWeekStart(checkWeek))
            )
            if let w = trainingManager.weights[key], w > 0 { return w }
        }
        return nil
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

    var formattedDuration: String { Self.format(seconds: duration) }

    static func format(seconds: Int) -> String {
        String(format: "%d:%02d", seconds / 60, seconds % 60)
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
