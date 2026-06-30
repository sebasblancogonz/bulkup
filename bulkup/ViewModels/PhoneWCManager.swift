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
        seq += 1
        let ctx = WatchContext(seq: seq, todaysPlan: currentTodaysPlan(), live: SharedWorkoutStore.load())
        guard let data = WatchSync.encode(ctx) else { return }
        try? session.updateApplicationContext([WatchSync.contextKey: data])
    }

    /// Build today's plan from TrainingManager. Maps the SwiftData TrainingDay/Exercise
    /// into the plain TodaysPlan structs. Picks the day matching the current weekday by
    /// display name, falling back to the first day.
    private func currentTodaysPlan() -> TodaysPlan? {
        let tm = TrainingManager.shared
        guard let planId = tm.trainingPlanId, !tm.trainingData.isEmpty else { return nil }
        let df = DateFormatter(); df.dateFormat = "yyyy-MM-dd"
        let weekStart = df.string(from: tm.getWeekStart(tm.selectedWeek))
        // Match by folded day name against the localized current weekday; fallback to first.
        let day = tm.trainingData.first(where: { fold($0.day) == foldedWeekday() }) ?? tm.trainingData[0]
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
        let f = DateFormatter(); f.locale = .current; f.dateFormat = "EEEE"
        return fold(f.string(from: Date()))
    }

    // MARK: - Watch → phone

    private func handle(_ data: Data) {
        guard let msg = WatchSync.decode(WatchMessage.self, from: data) else { return }
        let tm = TrainingManager.shared
        let wsm = WorkoutSessionManager.shared
        switch msg {
        case .startWorkout(let day):
            wsm.startWorkout(dayName: day, workoutName: nil, trainingManager: tm)
        case .completeSet(let exerciseIndex, let setIndex, let weight, let reps):
            SharedWorkoutStore.applySetValue(exerciseIndex: exerciseIndex, setIndex: setIndex, weight: weight, reps: reps)
            SharedWorkoutStore.completeCurrentSet()
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

    // Required iOS-only delegate stubs (not needed on watchOS).
    nonisolated func sessionDidBecomeInactive(_ session: WCSession) {}
    nonisolated func sessionDidDeactivate(_ session: WCSession) {
        // Re-activate to keep connectivity alive when the user switches Apple Watch.
        session.activate()
    }
}
