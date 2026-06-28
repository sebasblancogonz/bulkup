# Apple Watch Companion (Slice 1) — Design

**Date:** 2026-06-28
**Scope:** A standalone-capable watchOS app's **first slice**: a WatchConnectivity-driven companion that mirrors and drives the active iPhone workout from the wrist (start, log sets, weight/reps steppers, rest timer + haptics). The **iPhone remains the authoritative engine and sole backend writer.**

This is slice 1 of 4 (see Decomposition). HealthKit (HR/calories) is slice 2; phone-absent standalone + direct-backend writes is slice 3.

---

## Goals
- A watchOS app that, when the iPhone is reachable, shows today's workout and the active session, lets the user **complete sets, adjust weight/reps, run the rest timer (with haptics), and start/finish** — all from the wrist.
- The iPhone applies every watch action through its **existing** workout methods and persists via the existing `saveSessionToBackend()` path. The watch never touches the backend.

## Non-goals (later slices)
- HealthKit / `HKWorkoutSession` / heart rate / calories (slice 2).
- Phone-*absent* workouts, watch writing the backend directly, cross-device KeyChain auth, `generateWeightKey` replication on the watch (slice 3).
- Watch complications / Smart Stack (later).

## Decisions (locked)
- Target created by the user in Xcode (I supply entitlements/Info.plist + steps). I write all code; user builds (watchOS not buildable in this env → code-based review).
- First slice = companion + on-wrist logging. iPhone = authoritative writer.
- Transport = WatchConnectivity (`WCSession`). The App Group is same-device-only and does **not** bridge iPhone↔Watch.

---

## Slice 0 — Xcode target setup (USER does in Xcode; I provide the artifacts)

Exact steps (the plan repeats these as a checklist):
1. **File → New → Target → App (watchOS)**. Product name `BulkUpWatch`. Interface: SwiftUI. Bundle id `com.whitesolutions.bulkup.watchkitapp`. Embed in the `bulkup` app. Watch-only app (not "with companion iOS app", since the iOS app already exists). Deployment target watchOS 11 (or the team's floor).
2. Set the watch target's **Team = `B7QM936873`** (same as the app/widget).
3. **Signing & Capabilities → + Capability → App Groups** → check `group.com.whitesolutions.bulkup`. (HealthKit capability is added in slice 2, not now.)
4. **Shared-file membership:** add these files to the `BulkUpWatch` target (Target Membership checkbox), since the project manages cross-target membership by hand (the same way `Shared/` is scoped for the widget):
   - `bulkup/Shared/SharedWorkoutStore.swift` (the `LiveWorkout`/`LiveSet` model + mutations — Foundation only)
   - the new `bulkup/Shared/TodaysPlan.swift` and `bulkup/Shared/WatchMessage.swift` (created in slice 1)
   - Do **NOT** add `WorkoutActivityAttributes.swift` (imports ActivityKit, iOS-only) or `TrainingModels.swift` (SwiftData `@Model`s).
5. The watch target's source folder `BulkUpWatch/` is a file-system-synchronized group, so the `.swift` files I add there auto-compile into the watch target.

Xcode generates the watch target's `Info.plist` and `.entitlements` when the target is created; the **App Group is added via the Signing & Capabilities UI** (step 3), which edits the generated `.entitlements`. I do **NOT** pre-commit these Xcode-managed files (it would clash with what Xcode generates) — I provide the exact values to set in the UI, and the only files I author are the Swift sources under `BulkUpWatch/` and the new `Shared/` types.

> The plan's first task is this checklist + a pause for the user to confirm "target builds (empty app launches in the watch sim)" before the code tasks land — because subsequent tasks add files into `BulkUpWatch/`.

---

## Architecture (Slice 1)

```
iPhone (authoritative)                         Apple Watch (mirror + controller)
─────────────────────                          ────────────────────────────────
WorkoutSessionManager  ── state change ──▶ PhoneWCManager
   (start/complete/rest/                       │ updateApplicationContext({TodaysPlan?, LiveWorkout?, seq})
    weight/reps/finish)                         ▼
                                            WatchWCManager  ──▶ @Published ctx ──▶ SwiftUI watch views
                                                ▲                                      │ user taps
PhoneWCManager.didReceiveMessage ◀── sendMessage / transferUserInfo(WatchMessage) ◀────┘
   routes into existing methods
   → re-broadcast
```

- **Phone → Watch:** `WCSession.updateApplicationContext(["ctx": <encoded WatchContext>])` — coalesced latest-state, re-sent on every workout state change. Carries `TodaysPlan?` (so the watch can show/start today's workout) and the current `LiveWorkout?` (nil when no session) + a monotonic `seq`.
- **Watch → Phone:** each user action is a typed `WatchMessage`, JSON-encoded, sent via `sendMessage` when reachable, else `transferUserInfo` (reliable queue) so completions aren't lost. The phone decodes and routes into its existing methods, then re-broadcasts.
- **Watch UX:** optimistic local apply for snappiness; the next broadcast is the source of truth (reconciles).

---

## Components

### Shared (new files; Foundation-only; app + watch membership)

`bulkup/Shared/TodaysPlan.swift`
```swift
struct TodaysPlan: Codable, Equatable {
    var planId: String
    var dayName: String      // diacritic-folded, lowercased (the canonical key form)
    var dayDisplay: String   // human label for the watch UI
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

`bulkup/Shared/WatchMessage.swift`
```swift
enum WatchMessage: Codable, Equatable {
    case startWorkout(dayName: String)
    case completeSet
    case uncompleteSet
    case adjustWeight(delta: Double)
    case adjustReps(delta: Int)
    case skipRest
    case addRest(seconds: Int)
    case finishWorkout
    case requestSync           // watch asks the phone to resend the context
}

struct WatchContext: Codable, Equatable {
    var seq: Int
    var todaysPlan: TodaysPlan?
    var live: LiveWorkout?
}
```
(Swift synthesizes `Codable` for the enum-with-associated-values. WCSession payloads are `[String: Any]`, so we JSON-encode these to `Data` and ship under a single key.)

### Phone side

`bulkup/ViewModels/PhoneWCManager.swift` (`@MainActor`, `NSObject`, `WCSessionDelegate`, singleton)
- `activate()` — if `WCSession.isSupported()`, set delegate + `activate()`. Called once at app launch (`BulkUp.swift`).
- `broadcast()` — build `WatchContext(seq:, todaysPlan: currentTodaysPlan(), live: SharedWorkoutStore.load())`, JSON-encode, `try? session.updateApplicationContext(["ctx": data])`. `seq` is an incrementing counter.
- `currentTodaysPlan()` — from `TrainingManager.shared`: map the current weekday → the matching `TrainingDay` (fallback: first day), build a `TodaysPlan` (using the same diacritic-folded `dayName` and `weekStart` the app uses).
- `session(_:didReceiveMessage:)` and `session(_:didReceiveUserInfo:)` — decode `WatchMessage`, hop to `@MainActor`, route:
  - `.startWorkout(day)` → `WorkoutSessionManager.shared.startWorkout(dayName:…, trainingManager:.shared)`
  - `.completeSet` → `WorkoutSessionManager.shared.`… the same method the in-app "complete set" uses, then it already mirrors to the store; OR `SharedWorkoutStore.completeCurrentSet()` + `WorkoutSessionManager.shared.reconcileFromStore(trainingManager:.shared)` (mirror the widget-intent path).
  - `.adjustWeight/.adjustReps/.skipRest/.addRest` → the matching `SharedWorkoutStore` pure mutation (+ reconcile where the app already does).
  - `.finishWorkout` → `WorkoutSessionManager.shared.finishWorkout(trainingManager:.shared)` (+ the existing `saveSessionToBackend`).
  - `.requestSync` → `broadcast()`.
  - After any mutation → `broadcast()`.
- WCSessionDelegate stubs (`activationDidComplete`, `sessionDidBecomeInactive`, `sessionDidDeactivate` — iOS requires re-activation).

Hooks (small edits to existing code): call `PhoneWCManager.shared.broadcast()` after the workout state mutations in `WorkoutSessionManager` (`startWorkout`, `completeSet`/mirror, rest changes, weight/reps adjust, `finishWorkout`), and `PhoneWCManager.shared.activate()` in `BulkUp.swift` init.

### Watch side (`BulkUpWatch/`)

- `BulkUpWatchApp.swift` — `@main` `App`, owns a `WatchWCManager` `@StateObject`, shows `RootView`.
- `WatchWCManager.swift` — `ObservableObject`, `NSObject`, `WCSessionDelegate`. `@Published var ctx: WatchContext?`. On `didReceiveApplicationContext`, decode + publish (ignore if `seq` ≤ last). `send(_ msg:)` — encode; `sendMessage` if `isReachable` else `transferUserInfo`. On activate, `send(.requestSync)`.
- `RootView.swift` — routes: `ctx.live` active & not finished → `ActiveWorkoutView`; else `ctx.todaysPlan` present → `TodayView`; else a "Open BulkUp on your iPhone" placeholder.
- `ActiveWorkoutView.swift` — current exercise + `Serie i/total`, weight & reps with `-/+` (send `adjustWeight`/`adjustReps`), a prominent **Complete set** button (send `completeSet`), a progress indicator, a **rest** state (countdown from `live.restEndDate`, Skip / +30s), and a Finish action. Optimistic local copy for instant feedback.
- `RestTimerView` / helper — compute remaining from `restEndDate` (wall-clock, survives backgrounding); play `WKInterfaceDevice.current().play(.notification)` once when it reaches 0.

---

## Data flow (complete a set, from the wrist)
1. User taps **Complete set** on the watch → `WatchWCManager.send(.completeSet)` + optimistic local `live` cursor advance.
2. Phone `PhoneWCManager` receives → `SharedWorkoutStore.completeCurrentSet()` + `WorkoutSessionManager.reconcileFromStore(...)` (updates session + `TrainingManager.weights`, persists on finish) → `broadcast()`.
3. Watch receives the new `WatchContext` (higher `seq`) → replaces local `live` → UI reconciles (optimistic and real now agree).

## Error handling
- `WCSession` unreachable: state via `applicationContext` is latest-wins (no loss); actions via `transferUserInfo` are queued and delivered on reconnect. `sendMessage` only when `isReachable`.
- Stale context: the watch ignores any `WatchContext` whose `seq` ≤ the last applied.
- Idempotency: `completeSet` is cursor-based (completing an already-complete set is a no-op), so a duplicate delivery is safe.
- No phone / not paired: watch shows the "open on iPhone" placeholder; nothing crashes.

## Testing
- `landing`-style isn't available; watchOS isn't buildable here. Verification = user builds in Xcode + the project's `runSelfCheck()` convention for pure logic.
- `runSelfCheck()` (DEBUG) for: `WatchMessage`/`WatchContext`/`TodaysPlan` JSON encode→decode round-trip; the rest-remaining computation from a `restEndDate`. Wired into the watch app launch and/or `BulkUp.swift` for the shared types.
- Manual (user): pair the watch sim, start a workout on the phone → watch mirrors; complete a set on the watch → phone reflects it + the rest timer + haptic fire; start from the watch → phone starts the session.

## Decomposition (the whole watch project, for context)
- **Slice 1 (this spec):** companion + on-wrist logging over `WCSession`; phone authoritative.
- **Slice 2:** HealthKit — `HKWorkoutSession`/`HKLiveWorkoutBuilder`, HR + active energy + ring, write to Apple Health (adds the HealthKit capability + usage strings).
- **Slice 3:** phone-absent standalone — shared-KeyChain auth, watch writes the backend directly (`saveWeights`/`saveWorkoutSession`), `generateWeightKey` folding replicated + tested, cold-start plan fetch, co-writer reconciliation/dedupe.
- **Later:** complication / Smart Stack.
