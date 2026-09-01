//
//  WatchWCManager.swift
//  BulkUpWatch Watch App
//

import Foundation
import WatchConnectivity
internal import Combine

@MainActor
final class WatchWCManager: NSObject, ObservableObject, WCSessionDelegate {
    @Published var ctx: WatchContext?
    @Published var live: LiveWorkout?
    private var lastSeq = -1
    private var session: WCSession? { WCSession.isSupported() ? WCSession.default : nil }

    func activate() {
        guard let session else { return }
        session.delegate = self
        session.activate()
    }

    /// Send an action to the phone. Prefer sendMessage when reachable; otherwise
    /// queue with transferUserInfo so completions aren't lost.
    /// `queueOnFailure: false` for non-idempotent deltas (adjustWeight/adjustReps):
    /// a duplicate or minutes-late queued delivery lands on whatever set the
    /// cursor points at by then and corrupts its weight. completeSet carries
    /// absolute weight/reps, so deltas are best-effort UI sync only.
    func send(_ msg: WatchMessage, queueOnFailure: Bool = true) {
        guard let session, let data = WatchSync.encode(msg) else { return }
        let payload = [WatchSync.messageKey: data]
        if session.isReachable {
            session.sendMessage(payload, replyHandler: nil, errorHandler: { _ in
                if queueOnFailure { session.transferUserInfo(payload) }
            })
        } else if queueOnFailure {
            session.transferUserInfo(payload)
        }
    }

    // Optimistic: mutate the local working copy for instant UI, and send the action to
    // the phone (which stays authoritative — its next broadcast reconciles `live`).
    func completeSet() {
        guard let s = live?.current else { return }
        live?.completeCurrentSet()
        send(.completeSet(exerciseIndex: s.exerciseIndex, setIndex: s.setIndex, weight: s.weight, reps: s.reps))
    }
    func adjustWeight(_ d: Double) { live?.adjustWeight(d); send(.adjustWeight(delta: d), queueOnFailure: false) }
    func adjustReps(_ d: Int) { live?.adjustReps(d); send(.adjustReps(delta: d), queueOnFailure: false) }
    func skipRest() { live?.skipRest(); send(.skipRest) }
    func addRest(_ s: Int) { live?.addRest(s); send(.addRest(seconds: s)) }
    /// Finish: send the watch's authoritative LiveWorkout snapshot so the phone
    /// persists the correct final state even if it was unreachable during the workout.
    func finishWorkout(metrics: WorkoutMetrics?) { send(.finishWorkout(live: live, metrics: metrics)) }

    /// Optimistic meal toggle: flip locally for instant UI, send the absolute
    /// state; the phone's next broadcast reconciles.
    func toggleMeal(order: Int) {
        guard var meals = ctx?.meals, let date = ctx?.mealsDate,
              let i = meals.firstIndex(where: { $0.order == order }) else { return }
        meals[i].completed.toggle()
        ctx?.meals = meals
        send(.setMealCompleted(order: order, date: date, completed: meals[i].completed))
    }

    private func apply(_ data: Data?) {
        guard let next = WatchSync.decode(WatchContext.self, from: data), next.seq > lastSeq else { return }
        lastSeq = next.seq
        ctx = next
        live = next.live
    }

    nonisolated func session(_ s: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
        let data = applicationContext[WatchSync.contextKey] as? Data
        Task { @MainActor in self.apply(data) }
    }
    nonisolated func session(_ s: WCSession, activationDidCompleteWith state: WCSessionActivationState, error: Error?) {
        // Pull the latest applicationContext + ask for a fresh broadcast.
        let data = s.receivedApplicationContext[WatchSync.contextKey] as? Data
        Task { @MainActor in
            self.apply(data)
            self.send(.requestSync)
        }
    }
}
