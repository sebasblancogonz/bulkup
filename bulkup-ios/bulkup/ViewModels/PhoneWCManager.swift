//
//  PhoneWCManager.swift
//  bulkup
//
//  iPhone half of the watch companion. Broadcasts the current workout/plan to the
//  watch and routes watch actions into the existing workout engine. The phone
//  stays the authoritative writer; the watch never touches the backend.
//

import Foundation
import WatchConnectivity

@MainActor
final class PhoneWCManager: NSObject, WCSessionDelegate {
    static let shared = PhoneWCManager()
    private var seq = 0
    private var session: WCSession? { WCSession.isSupported() ? WCSession.default : nil }

    func activate() {
        guard let session else { return }
        session.delegate = self
        session.activate()
    }

    /// Re-send the latest plan + live state to the watch (coalesced, latest-wins).
    func broadcast() {
        guard let session, session.activationState == .activated else { return }
        // Timestamp-seeded so seq stays monotonic across app relaunches: the watch
        // drops any context whose seq isn't greater than the last one it applied,
        // and a plain counter restarts at 0 when iOS terminates the app mid-workout
        // (the watch would then ignore every broadcast and keep showing stale sets).
        seq = max(seq + 1, Int(Date().timeIntervalSince1970))
        let meals = currentMeals()
        let ctx = WatchContext(seq: seq, todaysPlan: currentTodaysPlan(), live: SharedWorkoutStore.load(),
                               mealsDate: meals?.date, meals: meals?.items)
        guard let data = WatchSync.encode(ctx) else { return }
        try? session.updateApplicationContext([WatchSync.contextKey: data])
    }

    private func todaysDietDay() -> DietDay? {
        todaysDay(DietManager.shared.dietData, name: { $0.day })
    }

    private func currentMeals() -> (date: String, items: [MealStatus])? {
        guard let day = todaysDietDay(), !day.meals.isEmpty else { return nil }
        let df = DateFormatter(); df.dateFormat = "yyyy-MM-dd"
        let date = df.string(from: Date())
        // Read records straight from the store: the published todayTracking is
        // empty when a watch message wakes the app in the background.
        let records = MealTrackingManager.shared.records(for: date)
        let items = day.meals.sorted { $0.orderIndex < $1.orderIndex }.map { meal in
            MealStatus(order: meal.order, name: meal.type, time: meal.time.isEmpty ? nil : meal.time,
                       completed: records.first { $0.mealOrder == meal.order }?.completed ?? false)
        }
        return (date, items)
    }

    /// Build today's plan from TrainingManager. Maps the SwiftData TrainingDay/Exercise
    /// into the plain TodaysPlan structs. Picks the day matching the current weekday by
    /// display name, falling back to the first day.
    private func currentTodaysPlan() -> TodaysPlan? {
        let tm = TrainingManager.shared
        guard let planId = tm.trainingPlanId, !tm.trainingData.isEmpty else { return nil }
        let df = DateFormatter(); df.dateFormat = "yyyy-MM-dd"
        let weekStart = df.string(from: tm.getWeekStart(tm.selectedWeek))
        let day = todaysDay(tm.trainingData, name: { $0.day }) ?? tm.trainingData[0]
        return TodaysPlan(
            planId: planId,
            dayName: fold(day.day),
            dayDisplay: day.day,
            weekStart: weekStart,
            exercises: day.exercises
                .sorted { $0.orderIndex < $1.orderIndex }
                .map { PlanExercise(orderIndex: $0.orderIndex, name: $0.name, sets: $0.sets,
                                    reps: $0.reps, restSeconds: $0.restSeconds, weightTracking: $0.weightTracking) }
        )
    }

    private func fold(_ s: String) -> String {
        s.lowercased().folding(options: .diacriticInsensitive, locale: .current)
    }
    private func foldedWeekday() -> String {
        // Matched against the plan's Spanish day-name data — must stay Spanish,
        // NOT the device locale (English would yield "wednesday" ≠ "miercoles").
        let f = DateFormatter(); f.locale = Locale(identifier: "es_ES"); f.dateFormat = "EEEE"
        return fold(f.string(from: Date()))
    }

    // MARK: - Day matching (mirrors TodayView: Spanish names + "Día N" fallback)

    private static let spanishDayOrder: [String: Int] = [
        "lunes": 0, "martes": 1, "miercoles": 2, "jueves": 3,
        "viernes": 4, "sabado": 5, "domingo": 6,
    ]

    private func weekdayIndex(for dayString: String) -> Int? {
        let norm = fold(dayString)
        if let idx = Self.spanishDayOrder[norm] { return idx }
        let stripped = norm.replacingOccurrences(of: "dia", with: "")
            .trimmingCharacters(in: .whitespaces)
        if let num = Int(stripped) { return (num - 1) % 7 }
        return nil
    }

    private var todayWeekdayIndex: Int {
        (Calendar.current.component(.weekday, from: Date()) + 5) % 7  // Monday = 0
    }

    /// Today's entry in a per-day plan: single-day plans apply every day,
    /// then match by Spanish day name, then by weekday index ("Día N" plans).
    private func todaysDay<T>(_ data: [T], name: (T) -> String) -> T? {
        guard !data.isEmpty else { return nil }
        if data.count == 1 { return data.first }
        if let match = data.first(where: { fold(name($0)) == foldedWeekday() }) { return match }
        return data.first { weekdayIndex(for: name($0)) == todayWeekdayIndex }
    }

    // MARK: - Watch → phone

    private func handle(_ data: Data) {
        guard let msg = WatchSync.decode(WatchMessage.self, from: data) else { return }
        let tm = TrainingManager.shared
        let wsm = WorkoutSessionManager.shared
        // If iOS terminated the app mid-workout, this delivery relaunched it in the
        // background with a blank session — rebuild it from the store first so the
        // action (especially finishWorkout) lands on real state instead of zeros.
        wsm.restoreIfNeeded(trainingManager: tm)
        switch msg {
        case .startWorkout(let day):
            wsm.startWorkout(dayName: day, workoutName: nil, trainingManager: tm)
        case .completeSet(let exerciseIndex, let setIndex, let weight, let reps):
            // Complete by identity, not cursor: the watch names the set it finished,
            // and duplicate deliveries (sendMessage + transferUserInfo fallback) no-op.
            SharedWorkoutStore.completeSet(exerciseIndex: exerciseIndex, setIndex: setIndex, weight: weight, reps: reps)
            wsm.reconcileFromStore(trainingManager: tm)
        case .uncompleteSet:
            // No store primitive for uncomplete in slice 1; reconcile is a no-op fallback.
            wsm.reconcileFromStore(trainingManager: tm)
        case .adjustWeight(let d):
            SharedWorkoutStore.adjustWeight(d)
            wsm.reconcileFromStore(trainingManager: tm)
        case .adjustReps(let d):
            SharedWorkoutStore.adjustReps(d)
            wsm.reconcileFromStore(trainingManager: tm)
        case .skipRest:
            SharedWorkoutStore.skipRest()
        case .addRest(let s):
            SharedWorkoutStore.addRest(s)
        case .finishWorkout(let live, let metrics):
            if let live {
                // Adopt the watch's authoritative final state (offline-completed sets + weights)
                // into the live session before finishing, so the saved record is correct.
                SharedWorkoutStore.save(live)
                wsm.reconcileFromStore(trainingManager: tm)
            }
            WorkoutSessionManager.shared.pendingWatchMetrics = metrics
            _ = wsm.finishWorkout(trainingManager: tm)
            wsm.saveSessionToBackend(
                userId: AuthManager.shared.user?.id ?? "",
                planId: tm.trainingPlanId,
                trainingManager: tm
            )
        case .setMealCompleted(let order, let date, let completed):
            guard let userId = AuthManager.shared.user?.id else { break }
            let day = todaysDietDay()
            let mealType = day?.meals.first { $0.order == order }?.type ?? "Comida"
            Task { @MainActor in
                // Broadcasts again itself once the record is saved.
                await MealTrackingManager.shared.setMealCompleted(
                    order: order, date: date, completed: completed, userId: userId,
                    dayName: day?.day ?? "", planId: DietManager.shared.dietPlanId,
                    mealType: mealType
                )
            }
        case .requestSync:
            break
        }
        broadcast()
    }

    // MARK: - WCSessionDelegate

    nonisolated func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        if let data = message[WatchSync.messageKey] as? Data {
            Task { @MainActor in self.handle(data) }
        }
    }

    nonisolated func session(_ session: WCSession, didReceiveUserInfo userInfo: [String: Any]) {
        if let data = userInfo[WatchSync.messageKey] as? Data {
            Task { @MainActor in self.handle(data) }
        }
    }

    nonisolated func session(_ session: WCSession, activationDidCompleteWith state: WCSessionActivationState, error: Error?) {
        Task { @MainActor in self.broadcast() }
    }

    #if DEBUG
    static func runSelfCheck() {
        let m = PhoneWCManager()
        assert(m.weekdayIndex(for: "Miércoles") == 2, "accented Spanish day maps to its index")
        assert(m.weekdayIndex(for: "sabado") == 5, "unaccented day maps too")
        assert(m.weekdayIndex(for: "Día 1") == 0 && m.weekdayIndex(for: "dia 8") == 0,
               "Día N wraps to Monday-based index")
        assert(m.weekdayIndex(for: "descanso") == nil, "unknown labels don't match")
        struct D { let day: String }
        let single = m.todaysDay([D(day: "Dieta Semanal")], name: { $0.day })
        assert(single?.day == "Dieta Semanal", "single-day plans apply every day")
        let numbered = (1...7).map { D(day: "Día \($0)") }
        assert(m.todaysDay(numbered, name: { $0.day }) != nil, "Día N plans always resolve a day")
    }
    #endif

    // Required iOS-only delegate stubs (not needed on watchOS).
    nonisolated func sessionDidBecomeInactive(_ session: WCSession) {}
    nonisolated func sessionDidDeactivate(_ session: WCSession) {
        // Re-activate to keep connectivity alive when the user switches Apple Watch.
        session.activate()
    }
}
