# Apple Watch Companion (Slice 1) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development. Steps use checkbox (`- [ ]`) syntax. **Task 3 is a manual USER step in Xcode — the controller pauses there and does NOT dispatch a subagent for it.**

**Goal:** A watchOS companion that mirrors and drives the active iPhone workout from the wrist (start, complete sets, weight/reps steppers, rest timer + haptics) over WatchConnectivity, with the iPhone remaining the authoritative engine and sole backend writer.

**Architecture:** New `WCSession` on both sides. Phone broadcasts `{TodaysPlan?, LiveWorkout?, seq}` via `updateApplicationContext`; watch sends typed `WatchMessage` actions back; the phone routes them into its existing methods (`startWorkout`, `SharedWorkoutStore` mutations + `reconcileFromStore`, `finishWorkout` + `saveSessionToBackend`) and re-broadcasts. The watch reuses the Foundation-only `LiveWorkout` model.

**Tech Stack:** SwiftUI (watchOS), WatchConnectivity, the existing shared `LiveWorkout` model.

## Global Constraints

- watchOS app target `BulkUpWatch`, bundle id `com.whitesolutions.bulkup.watchkitapp`, team `B7QM936873`, App Group `group.com.whitesolutions.bulkup`.
- ENV: neither the iOS app nor watchOS is buildable here — verification is code-based + the project's DEBUG `runSelfCheck()` convention (wired into `bulkup/App/BulkUp.swift`'s init). The USER builds in Xcode. SourceKit cross-target "cannot find type" errors are spurious.
- The iPhone is the authoritative writer; the watch never calls the backend (slice 1). HealthKit and phone-absent standalone are later slices.
- Reuse `LiveWorkout`/`LiveSet` (`bulkup/Shared/SharedWorkoutStore.swift`, Foundation-only). Do NOT share `WorkoutActivityAttributes.swift` (ActivityKit/iOS-only) or `TrainingModels.swift` (SwiftData `@Model`s).
- Phone routing reuses verified signatures: `WorkoutSessionManager.shared.startWorkout(dayName:workoutName:trainingManager:)`, `.finishWorkout(trainingManager:)`, `.saveSessionToBackend(userId:planId:trainingManager:)`, `.reconcileFromStore(trainingManager:)`; `SharedWorkoutStore.{completeCurrentSet(),adjustWeight(_:),adjustReps(_:),skipRest(),addRest(_:),load()}`; `TrainingManager.shared.{trainingData,trainingPlanId}`, `AuthManager.shared.user?.id`.

---

## Task 1: Shared transport types (`TodaysPlan`, `WatchMessage`, `WatchContext`)

Foundation-only types used by both targets. They compile into the iOS app now (watch membership is added in Task 3).

**Files:**
- Create: `bulkup/Shared/TodaysPlan.swift`
- Create: `bulkup/Shared/WatchMessage.swift`
- Modify: `bulkup/App/BulkUp.swift` (wire the self-check)

**Interfaces:**
- Produces: `TodaysPlan`, `PlanExercise`, `WatchMessage`, `WatchContext`, `WatchSync.runSelfCheck()`

- [ ] **Step 1: Create `TodaysPlan.swift`**

```swift
import Foundation

/// A lightweight, Codable snapshot of one day's plan, sent phone → watch so the
/// watch can show and start today's workout. (TrainingDay/Exercise are SwiftData
/// @Models and not shareable, so the phone maps them into these plain structs.)
struct TodaysPlan: Codable, Equatable {
    var planId: String
    var dayName: String      // diacritic-folded, lowercased (key form)
    var dayDisplay: String   // the human day label (TrainingDay.day) — sent back on start
    var weekStart: String    // yyyy-MM-dd
    var exercises: [PlanExercise]
}

struct PlanExercise: Codable, Equatable {
    var orderIndex: Int
    var name: String
    var sets: Int
    var reps: String
    var restSeconds: Int
    var weightTracking: Bool
}
```

- [ ] **Step 2: Create `WatchMessage.swift` (with `WatchContext` + self-check)**

```swift
import Foundation

/// Watch → phone actions. The phone routes each into its existing workout methods.
enum WatchMessage: Codable, Equatable {
    case startWorkout(day: String)   // day = the display day (TrainingDay.day)
    case completeSet
    case uncompleteSet
    case adjustWeight(delta: Double)
    case adjustReps(delta: Int)
    case skipRest
    case addRest(seconds: Int)
    case finishWorkout
    case requestSync                 // ask the phone to re-send context
}

/// Phone → watch state. Coalesced latest-state via updateApplicationContext.
struct WatchContext: Codable, Equatable {
    var seq: Int
    var todaysPlan: TodaysPlan?
    var live: LiveWorkout?           // from SharedWorkoutStore.swift (same target)
}

enum WatchSync {
    static let messageKey = "msg"    // WCSession payload key for a WatchMessage
    static let contextKey = "ctx"    // WCSession payload key for a WatchContext

    static func encode<T: Encodable>(_ value: T) -> Data? { try? JSONEncoder().encode(value) }
    static func decode<T: Decodable>(_ type: T.Type, from data: Data?) -> T? {
        guard let data else { return nil }
        return try? JSONDecoder().decode(type, from: data)
    }

    #if DEBUG
    static func runSelfCheck() {
        // WatchMessage round-trip for every case.
        let msgs: [WatchMessage] = [
            .startWorkout(day: "Lunes"), .completeSet, .uncompleteSet,
            .adjustWeight(delta: 2.5), .adjustReps(delta: -1), .skipRest,
            .addRest(seconds: 30), .finishWorkout, .requestSync,
        ]
        for m in msgs {
            let back = decode(WatchMessage.self, from: encode(m))
            assert(back == m, "WatchMessage round-trip failed for \(m)")
        }
        // WatchContext round-trip (with a sample LiveWorkout + TodaysPlan).
        let live = LiveWorkout(
            dayName: "Lunes", workoutName: "Push", startDate: Date(), isPaused: false,
            weightUnit: "kg", weightStep: 2.5, repStep: 1,
            sets: [.init(exerciseIndex: 0, exerciseName: "Press", setIndex: 0, setsTotalForExercise: 1,
                         weight: 40, reps: 10, restSeconds: 60, completed: false)],
            cursor: 0, restEndDate: nil)
        let plan = TodaysPlan(planId: "p1", dayName: "lunes", dayDisplay: "Lunes", weekStart: "2026-06-22",
            exercises: [.init(orderIndex: 0, name: "Press", sets: 3, reps: "10, 8, 6", restSeconds: 90, weightTracking: true)])
        let ctx = WatchContext(seq: 7, todaysPlan: plan, live: live)
        let backCtx = decode(WatchContext.self, from: encode(ctx))
        assert(backCtx == ctx, "WatchContext round-trip failed")
    }
    #endif
}
```

(Confirm `LiveWorkout`'s memberwise `init` argument labels/order match the `runSelfCheck` sample by reading `SharedWorkoutStore.swift`; adjust the sample to the real init if it differs.)

- [ ] **Step 3: Wire the self-check**

In `bulkup/App/BulkUp.swift` `#if DEBUG` block (after `WorkoutSessionManager.runSelfCheck()`), add:

```swift
        WatchSync.runSelfCheck()
```

- [ ] **Step 4: Build & verify**

User builds the iOS app in Xcode (these compile into the app target). Expected: no assertion crash at launch. (Agent: hand-trace the round-trips and state expected results in the report.)

- [ ] **Step 5: Commit**

```bash
git add bulkup/Shared/TodaysPlan.swift bulkup/Shared/WatchMessage.swift bulkup/App/BulkUp.swift
git commit -m "feat(watch): shared TodaysPlan/WatchMessage/WatchContext transport types"
```

---

## Task 2: Phone-side WatchConnectivity (`PhoneWCManager`) + lifecycle hooks

The iPhone half — compiles into the app target (WatchConnectivity is available on iOS), independent of the watch target.

**Files:**
- Create: `bulkup/ViewModels/PhoneWCManager.swift`
- Modify: `bulkup/App/BulkUp.swift` (activate at launch)
- Modify: `bulkup/ViewModels/WorkoutSessionManager.swift` (broadcast on state changes)

**Interfaces:**
- Consumes: `WatchContext`, `WatchMessage`, `WatchSync`, `TodaysPlan` (Task 1)
- Produces: `PhoneWCManager.shared` with `.activate()`, `.broadcast()`

- [ ] **Step 1: Create `PhoneWCManager.swift`**

```swift
import Foundation
import WatchConnectivity

/// iPhone side of the watch companion. Broadcasts the current workout/plan to the
/// watch and routes watch actions into the existing workout engine. The phone
/// stays the authoritative writer; the watch never touches the backend.
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

    // MARK: Watch → phone
    private func handle(_ data: Data) {
        guard let msg = WatchSync.decode(WatchMessage.self, from: data) else { return }
        let tm = TrainingManager.shared
        switch msg {
        case .startWorkout(let day):
            WorkoutSessionManager.shared.startWorkout(dayName: day, workoutName: nil, trainingManager: tm)
        case .completeSet:
            SharedWorkoutStore.completeCurrentSet()
            WorkoutSessionManager.shared.reconcileFromStore(trainingManager: tm)
        case .uncompleteSet:
            // No store primitive for uncomplete in slice 1; reconcile is a no-op fallback.
            WorkoutSessionManager.shared.reconcileFromStore(trainingManager: tm)
        case .adjustWeight(let d): SharedWorkoutStore.adjustWeight(d)
        case .adjustReps(let d): SharedWorkoutStore.adjustReps(d)
        case .skipRest: SharedWorkoutStore.skipRest()
        case .addRest(let s): SharedWorkoutStore.addRest(s)
        case .finishWorkout:
            _ = WorkoutSessionManager.shared.finishWorkout(trainingManager: tm)
            WorkoutSessionManager.shared.saveSessionToBackend(
                userId: AuthManager.shared.user?.id ?? "", planId: tm.trainingPlanId, trainingManager: tm)
        case .requestSync:
            break
        }
        broadcast()
    }

    // MARK: WCSessionDelegate
    nonisolated func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        if let data = message[WatchSync.messageKey] as? Data { Task { @MainActor in self.handle(data) } }
    }
    nonisolated func session(_ session: WCSession, didReceiveUserInfo userInfo: [String: Any]) {
        if let data = userInfo[WatchSync.messageKey] as? Data { Task { @MainActor in self.handle(data) } }
    }
    nonisolated func session(_ session: WCSession, activationDidCompleteWith state: WCSessionActivationState, error: Error?) {
        Task { @MainActor in self.broadcast() }
    }
    nonisolated func sessionDidBecomeInactive(_ session: WCSession) {}
    nonisolated func sessionDidDeactivate(_ session: WCSession) { session.activate() }
}
```

(Confirm exact signatures while implementing: `finishWorkout` return value, `saveSessionToBackend` parameter labels, and that `reconcileFromStore(trainingManager:)` exists. Adjust calls to match. `User.id` type — coerce to the `String` the backend expects.)

- [ ] **Step 2: Activate at launch**

In `bulkup/App/BulkUp.swift` `init()`, after the existing setup (outside `#if DEBUG`), add:

```swift
        PhoneWCManager.shared.activate()
```

- [ ] **Step 3: Broadcast on workout state changes**

In `bulkup/ViewModels/WorkoutSessionManager.swift`, add `PhoneWCManager.shared.broadcast()` at the end of the methods that change live state: `startWorkout`, the set-completion path (where it mirrors to the store), the rest-timer change points, the weight/reps adjust points, and `finishWorkout`. (Implementer: locate each mutation site and append the broadcast; if a single chokepoint exists where the store is written, prefer hooking there once.)

- [ ] **Step 4: Build & verify**

User builds the iOS app. Expected: compiles; no behavior change when no watch is paired (`broadcast()` no-ops if the session isn't activated/reachable).

- [ ] **Step 5: Commit**

```bash
git add bulkup/ViewModels/PhoneWCManager.swift bulkup/App/BulkUp.swift bulkup/ViewModels/WorkoutSessionManager.swift
git commit -m "feat(watch): phone-side WCSession — broadcast state, route watch actions"
```

---

## Task 3: [USER, MANUAL IN XCODE] Create the `BulkUpWatch` target

**This is a human step. The controller presents this checklist, the user performs it in Xcode, and confirms the empty target builds & launches before any watch-code task is dispatched.** No subagent.

- [ ] **Step 1: Add the target** — File → New → Target → **App (watchOS)**. Product name `BulkUpWatch`, Interface **SwiftUI**, bundle id `com.whitesolutions.bulkup.watchkitapp`, watch-only (the iOS app already exists), embed in `bulkup`. Deployment target watchOS 11.
- [ ] **Step 2: Team** — set the watch target Team = `B7QM936873`.
- [ ] **Step 3: App Group** — Signing & Capabilities → + Capability → **App Groups** → check `group.com.whitesolutions.bulkup`. (HealthKit is added in slice 2.)
- [ ] **Step 4: Shared-file membership** — add to the `BulkUpWatch` target (Target Membership):
  `bulkup/Shared/SharedWorkoutStore.swift`, `bulkup/Shared/TodaysPlan.swift`, `bulkup/Shared/WatchMessage.swift`. Do NOT add `WorkoutActivityAttributes.swift` or `TrainingModels.swift`.
- [ ] **Step 5: Verify** — select the `BulkUpWatch` scheme, run on a paired watch simulator; the template app launches. Confirm to the controller, then watch-code tasks proceed.

---

## Task 4: Watch app skeleton (`BulkUpWatchApp`, `WatchWCManager`, `RootView`)

**Files (in the watch target's folder — auto-included via the synchronized group):**
- Replace/Create: `BulkUpWatch/BulkUpWatchApp.swift`
- Create: `BulkUpWatch/WatchWCManager.swift`
- Create: `BulkUpWatch/RootView.swift`

**Interfaces:**
- Consumes: `WatchContext`, `WatchMessage`, `WatchSync`, `LiveWorkout`, `TodaysPlan` (shared)
- Produces: `WatchWCManager` (`@Published ctx`, `send(_:)`), `RootView`

- [ ] **Step 1: `WatchWCManager.swift`**

```swift
import Foundation
import WatchConnectivity

@MainActor
final class WatchWCManager: NSObject, ObservableObject, WCSessionDelegate {
    @Published var ctx: WatchContext?
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

    private func apply(_ data: Data?) {
        guard let next = WatchSync.decode(WatchContext.self, from: data), next.seq > lastSeq else { return }
        lastSeq = next.seq
        ctx = next
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
```

- [ ] **Step 2: `BulkUpWatchApp.swift`**

```swift
import SwiftUI

@main
struct BulkUpWatchApp: App {
    @StateObject private var wc = WatchWCManager()
    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(wc)
                .onAppear { wc.activate() }
        }
    }
}
```

- [ ] **Step 3: `RootView.swift` (routing + placeholder)**

```swift
import SwiftUI

struct RootView: View {
    @EnvironmentObject var wc: WatchWCManager
    var body: some View {
        if let live = wc.ctx?.live, !live.isFinished {
            ActiveWorkoutView(live: live)
        } else if let plan = wc.ctx?.todaysPlan, !plan.exercises.isEmpty {
            TodayView(plan: plan)
        } else {
            VStack(spacing: 8) {
                Image(systemName: "iphone").font(.title2)
                Text("Open BulkUp on your iPhone").font(.footnote).multilineTextAlignment(.center)
            }.padding()
        }
    }
}
```

- [ ] **Step 4: Build & verify** — user builds the watch scheme; with the phone foregrounded it shows the placeholder (no active workout) or today's plan. Commit.

```bash
git add BulkUpWatch/BulkUpWatchApp.swift BulkUpWatch/WatchWCManager.swift BulkUpWatch/RootView.swift
git commit -m "feat(watch): watch app skeleton + WCSession receiver"
```

---

## Task 5: Watch workout UI (`TodayView`, `ActiveWorkoutView`)

**Files:**
- Create: `BulkUpWatch/TodayView.swift`
- Create: `BulkUpWatch/ActiveWorkoutView.swift`

**Interfaces:**
- Consumes: `WatchWCManager` (`send(_:)`), `LiveWorkout` (`current`, `completedCount`, `sets.count`, `isFinished`), `TodaysPlan`

- [ ] **Step 1: `TodayView.swift`**

```swift
import SwiftUI

struct TodayView: View {
    @EnvironmentObject var wc: WatchWCManager
    let plan: TodaysPlan
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 10) {
                Text(plan.dayDisplay).font(.headline)
                ForEach(plan.exercises, id: \.orderIndex) { ex in
                    HStack {
                        Text(ex.name).font(.caption).lineLimit(1)
                        Spacer()
                        Text("\(ex.sets)×\(ex.reps)").font(.caption2).foregroundStyle(.secondary)
                    }
                }
                Button {
                    wc.send(.startWorkout(day: plan.dayDisplay))
                } label: {
                    Text("Start workout").frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(Color(red: 0.518, green: 0.800, blue: 0.086)) // lime #84CC16
                .padding(.top, 6)
            }.padding()
        }
    }
}
```

- [ ] **Step 2: `ActiveWorkoutView.swift`**

```swift
import SwiftUI

struct ActiveWorkoutView: View {
    @EnvironmentObject var wc: WatchWCManager
    let live: LiveWorkout
    private let lime = Color(red: 0.518, green: 0.800, blue: 0.086)

    var body: some View {
        if let restEnd = live.restEndDate, restEnd > Date() {
            RestTimerView(end: restEnd) // Task 6
        } else if let s = live.current {
            ScrollView {
                VStack(spacing: 10) {
                    Text(s.exerciseName).font(.headline).lineLimit(1)
                    Text("Serie \(s.setIndex + 1)/\(s.setsTotalForExercise)")
                        .font(.caption).foregroundStyle(.secondary)

                    stepper(label: "\(fmt(s.weight)) \(live.weightUnit)",
                            minus: .adjustWeight(delta: -live.weightStep),
                            plus: .adjustWeight(delta: live.weightStep))
                    stepper(label: "\(s.reps) reps",
                            minus: .adjustReps(delta: -1), plus: .adjustReps(delta: 1))

                    Button { wc.send(.completeSet) } label: {
                        Text("Complete set").frame(maxWidth: .infinity)
                    }.buttonStyle(.borderedProminent).tint(lime)

                    ProgressView(value: Double(live.completedCount), total: Double(max(live.sets.count, 1)))
                        .tint(lime)

                    Button("Finish") { wc.send(.finishWorkout) }
                        .font(.caption).foregroundStyle(.secondary)
                }.padding()
            }
        } else {
            Text("Workout complete").padding()
        }
    }

    private func stepper(label: String, minus: WatchMessage, plus: WatchMessage) -> some View {
        HStack {
            Button { wc.send(minus) } label: { Image(systemName: "minus") }.buttonStyle(.bordered)
            Text(label).font(.body).monospacedDigit().frame(maxWidth: .infinity)
            Button { wc.send(plus) } label: { Image(systemName: "plus") }.buttonStyle(.bordered)
        }
    }
    private func fmt(_ w: Double) -> String { w == w.rounded() ? String(format: "%.0f", w) : String(format: "%.1f", w) }
}
```

(Confirm `LiveWorkout.current` / `LiveSet` field names — `exerciseName`, `setIndex`, `setsTotalForExercise`, `weight`, `reps`, `completed` — and `weightUnit`/`weightStep`/`completedCount`/`isFinished` against `SharedWorkoutStore.swift`; adjust if any differ.)

- [ ] **Step 3: Build & verify** — user: start a workout on the phone → watch shows the active set; tap steppers/complete on the watch → phone reflects it (and the watch re-renders from the rebroadcast). Commit.

```bash
git add BulkUpWatch/TodayView.swift BulkUpWatch/ActiveWorkoutView.swift
git commit -m "feat(watch): today + active-workout screens with on-wrist logging"
```

---

## Task 6: Rest timer + haptics (`RestTimerView`)

**Files:**
- Create: `BulkUpWatch/RestTimerView.swift`

**Interfaces:**
- Consumes: `WatchWCManager` (`send(.skipRest)` / `.addRest`), an end `Date`

- [ ] **Step 1: `RestTimerView.swift`**

```swift
import SwiftUI
import WatchKit

struct RestTimerView: View {
    @EnvironmentObject var wc: WatchWCManager
    let end: Date
    @State private var firedHaptic = false
    private let lime = Color(red: 0.518, green: 0.800, blue: 0.086)

    var body: some View {
        VStack(spacing: 10) {
            Text("REST").font(.caption2).tracking(1.5).foregroundStyle(.secondary)
            // Wall-clock countdown; survives backgrounding because it's derived from `end`.
            Text(timerInterval: Date()...end, countsDown: true)
                .font(.system(size: 30, weight: .bold, design: .rounded)).monospacedDigit()
                .foregroundStyle(lime)
            HStack {
                Button("Skip") { wc.send(.skipRest) }.buttonStyle(.bordered)
                Button("+30s") { wc.send(.addRest(seconds: 30)) }.buttonStyle(.bordered)
            }
        }
        .padding()
        .onAppear { scheduleHaptic() }
    }

    private func scheduleHaptic() {
        guard !firedHaptic else { return }
        let remaining = end.timeIntervalSinceNow
        guard remaining > 0 else { WKInterfaceDevice.current().play(.notification); firedHaptic = true; return }
        DispatchQueue.main.asyncAfter(deadline: .now() + remaining) {
            // Only fire if rest hasn't been skipped/extended away from this end.
            if !firedHaptic && abs(Date().timeIntervalSince(end)) < 1.5 {
                WKInterfaceDevice.current().play(.notification)
                firedHaptic = true
            }
        }
    }
}
```

- [ ] **Step 2: Build & verify** — user: complete a set with a rest period → the watch shows the countdown and taps haptically at zero; Skip/+30s reflect on the phone. Commit.

```bash
git add BulkUpWatch/RestTimerView.swift
git commit -m "feat(watch): rest-timer countdown + end-of-rest haptic"
```

---

## Self-Review

**Spec coverage:** WCSession transport (Task 1/2/4) · phone authoritative routing into existing methods (Task 2) · TodaysPlan cold-start + start-from-watch (Task 2 build, Task 5 TodayView) · on-wrist set logging + steppers (Task 5) · rest timer + haptics (Task 6) · Slice 0 target setup (Task 3) · seq-based stale-context dedup (Task 4) · transferUserInfo fallback (Task 4) · self-checks for the pure transport logic (Task 1). HealthKit/standalone correctly deferred.

**Placeholder scan:** No TBD/TODO. The "confirm exact signature / field names" notes are verification instructions (the code is fully written for the verified signatures), not placeholders.

**Type consistency:** `WatchMessage`/`WatchContext`/`TodaysPlan`/`WatchSync.{messageKey,contextKey,encode,decode}` are used identically across phone (Task 2) and watch (Task 4–6). `.startWorkout(day:)` carries the display day in both the sender (TodayView) and the phone router. `WatchWCManager.send(_:)` / `.ctx` referenced consistently by the views.

**Sequencing:** Tasks 1–2 compile into the iOS app and need no watch target; Task 3 (user) creates the target; Tasks 4–6 add files into `BulkUpWatch/`. The controller must pause for Task 3.
