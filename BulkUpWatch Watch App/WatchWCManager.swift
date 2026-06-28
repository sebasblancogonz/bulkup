//
//  WatchWCManager.swift
//  BulkUpWatch Watch App
//

import Foundation
import WatchConnectivity

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
    func send(_ msg: WatchMessage) {
        guard let session, let data = WatchSync.encode(msg) else { return }
        if session.isReachable {
            session.sendMessage([WatchSync.messageKey: data], replyHandler: nil, errorHandler: { _ in
                session.transferUserInfo([WatchSync.messageKey: data])
            })
        } else {
            session.transferUserInfo([WatchSync.messageKey: data])
        }
    }

    // Optimistic: mutate the local working copy for instant UI, and send the action to
    // the phone (which stays authoritative — its next broadcast reconciles `live`).
    func completeSet() { live?.completeCurrentSet(); send(.completeSet) }
    func adjustWeight(_ d: Double) { live?.adjustWeight(d); send(.adjustWeight(delta: d)) }
    func adjustReps(_ d: Int) { live?.adjustReps(d); send(.adjustReps(delta: d)) }
    func skipRest() { live?.skipRest(); send(.skipRest) }
    func addRest(_ s: Int) { live?.addRest(s); send(.addRest(seconds: s)) }
    /// Finish: send the watch's authoritative LiveWorkout snapshot so the phone
    /// persists the correct final state even if it was unreachable during the workout.
    func finishWorkout(metrics: WorkoutMetrics?) { send(.finishWorkout(live: live, metrics: metrics)) }

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
