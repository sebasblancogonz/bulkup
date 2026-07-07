# Apple Watch Slice 2 — HealthKit HR/calories (persisted) — Design

**Date:** 2026-06-28
**Scope:** Slice 2 of the Apple Watch integration. The watch records heart rate + active energy via an `HKWorkoutSession`, writes the workout to Apple Health, shows live metrics, and — on finish — sends avg/max HR + total active energy back to the phone, which persists them in the backend workout-session record.

**Spans two repos:** the iOS/watch app `bulkup`, and the Go backend `weight-tracker-backend`. Two branches / two PRs. **Backend lands first** (so the data contract exists before the iOS side writes to it).

---

## Goals
- On the watch, auto-start an `HKWorkoutSession`/`HKLiveWorkoutBuilder` for the duration of an active workout (background runtime + the workout ring + live HR/energy), and save the `HKWorkout` to Apple Health.
- Show live heart rate + active energy on the watch's active-workout screen.
- Persist avg HR, max HR, and total active energy to the backend workout-session record, delivered from the watch at finish.

## Non-goals (later)
- GPS/route, HRV, other Health metrics.
- iPhone reading HealthKit (the session lives on the watch).
- Phone-initiated finish capturing watch metrics into the backend (accepted edge — see below).

## Decisions (locked)
- HK session auto-starts with the active workout (tied to `ActiveWorkoutView` lifetime).
- Metrics are sent to the phone + persisted to the backend.
- Activity type `.traditionalStrengthTraining`, indoor.

---

## Manual step (USER, in Xcode — like the App Group in Slice 1)
On the **`BulkUpWatch`** target:
1. Signing & Capabilities → + Capability → **HealthKit**.
2. `BulkUpWatch Watch App/Info.plist`: add **`NSHealthShareUsageDescription`** ("BulkUp uses your heart rate and energy to track your workouts.") and **`NSHealthUpdateUsageDescription`** ("BulkUp saves your workouts to Apple Health.").
No background-mode key is needed — an active `HKWorkoutSession` grants watchOS background runtime on its own.

(The phone target does NOT get HealthKit — the session is watch-only.)

---

## Components

### Shared (`bulkup/Shared/`) — compiled into app + watch
`WorkoutMetrics.swift` (new):
```swift
struct WorkoutMetrics: Codable, Equatable {
    var avgHeartRate: Int       // bpm, 0 if none
    var maxHeartRate: Int       // bpm, 0 if none
    var activeEnergyKcal: Double // total kcal
}
```
`WatchMessage.swift` (modify): the finish case carries optional metrics:
```swift
case finishWorkout(metrics: WorkoutMetrics?)
```
All `.finishWorkout` call sites update (the watch sends `.finishWorkout(metrics:)`; the phone's `handle()` switch binds `metrics`). `WatchSync.runSelfCheck()` adds a round-trip for `.finishWorkout(metrics: …)` and a bare `WorkoutMetrics`.

### Watch (`BulkUpWatch Watch App/`) — new + modified
`WorkoutMetricsManager.swift` (new) — `@MainActor ObservableObject`, `HKWorkoutSessionDelegate`, `HKLiveWorkoutBuilderDelegate`:
- `HKHealthStore`, `HKWorkoutSession?`, `HKLiveWorkoutBuilder?`.
- `requestAuthorization()` — read `heartRate` + `activeEnergyBurned`; share `HKWorkoutType` + `activeEnergyBurned`. Idempotent.
- `start()` — request auth if needed; build `HKWorkoutConfiguration(activityType: .traditionalStrengthTraining, locationType: .indoor)`; create session + `session.associatedWorkoutBuilder()`; set delegates + `liveWorkoutBuilder.dataSource = HKLiveWorkoutDataSource(...)`; `session.startActivity(with: Date())`; `builder.beginCollection(withStart:)`. No-op if HealthKit unavailable or already running.
- `end() async -> WorkoutMetrics?` — `session.end()`; `builder.endCollection(withEnd:)`; read `builder.statistics(for:)` for heartRate (avg/max) + activeEnergyBurned (sum); `builder.finishWorkout()` (saves to Apple Health); return `WorkoutMetrics`. Returns nil if no session was running.
- `@Published var heartRate: Int = 0`, `@Published var activeEnergy: Double = 0` — updated from `workoutBuilder(_:didCollectDataOf:)`.
- Running avg/max HR computed from the builder's statistics at `end()` (authoritative), not hand-accumulated.

`ActiveWorkoutView.swift` (modify):
- `@EnvironmentObject var metrics: WorkoutMetricsManager`.
- `.onAppear { metrics.start() }`, `.onDisappear { Task { _ = await metrics.end() } }` — but the **Finish button** needs the metrics, so: the Finish button does `Task { let m = await metrics.end(); wc.send(.finishWorkout(metrics: m)) }` and shows a brief "Finishing…" state (a `@State finishing` flag). `.onDisappear`'s `end()` is a safety net that no-ops if already ended (so finishing via the button + the disappear don't double-end).
- A metrics row: `❤️ \(metrics.heartRate)` and `🔥 \(Int(metrics.activeEnergy)) kcal` (only shown when an HK session is active / values > 0).

`BulkUpWatchApp.swift` (modify): own `@StateObject var metrics = WorkoutMetricsManager()`, inject `.environmentObject(metrics)`, and `metrics.requestAuthorization()` on appear (so the prompt is ready before the first start).

### Phone (`bulkup/`) — modify
- `PhoneWCManager.handle()` `.finishWorkout(let metrics)` → stash `metrics` on `WorkoutSessionManager` (a new `pendingWatchMetrics` property) before calling `finishWorkout` + `saveSessionToBackend`.
- `WorkoutSessionManager.saveSessionToBackend(...)` includes the stashed metrics in the request (and clears it after).
- `SaveWorkoutSessionRequest` (`Models/APIModels.swift:489`) gains optional `avgHeartRate: Int?`, `maxHeartRate: Int?`, `activeEnergyKcal: Double?`.

### Backend (`weight-tracker-backend`) — modify (lands first)
- `internal/models/workout_session.go`: `SaveWorkoutSessionRequest` (line 39) + `WorkoutSession` (line 20) gain `AvgHeartRate *int`, `MaxHeartRate *int`, `ActiveEnergyKcal *float64` with `json`/`bson` tags (pointers = optional/omitempty).
- `internal/services/workout_session.go`: map the new request fields onto the persisted `WorkoutSession` document.
- Verify with `go build ./...` (backend builds locally with the Homebrew leptonica/tesseract cgo flags).

---

## Data flow (finish from the watch)
1. User taps **Finish** → watch sets `finishing = true`, `Task { let m = await metrics.end() }` (ends HK session, saves HKWorkout to Health, reads avg/max HR + total energy).
2. Watch `wc.send(.finishWorkout(metrics: m))`.
3. Phone routes → stashes metrics → `finishWorkout` (shows summary) → `saveSessionToBackend` includes `avgHeartRate/maxHeartRate/activeEnergyKcal` → backend persists them.
4. Phone re-broadcasts `live = nil` → watch `RootView` → placeholder; `finishing` resets.

## Error handling
- HealthKit unavailable / unauthorized: `start()`/`end()` no-op; `end()` returns `nil`; `.finishWorkout(metrics: nil)` → backend save omits the fields. No crash, workout still finishes.
- Phone-initiated finish while the watch session runs: watch `ActiveWorkoutView.onDisappear` ends the HK session (HKWorkout saved to Health) but does NOT send a finish message (the phone already finished) → metrics not persisted to backend. Accepted edge.
- Double-end guard: `end()` is idempotent (no session → returns nil), so the Finish button + `.onDisappear` can't double-finish.

## Testing
- Backend: `go build ./...` passes; the new fields round-trip (add/verify in the existing test path if one exists, else a focused check).
- Shared: `WatchSync.runSelfCheck()` round-trips `.finishWorkout(metrics:)` + `WorkoutMetrics` (DEBUG asserts, wired into `BulkUp.swift`).
- Watch/HealthKit: not unit-testable without a device — the USER builds + runs on a real Apple Watch (HealthKit + HR don't work in the simulator). Manual: start a workout, see HR/energy climb, finish, confirm the workout appears in Apple Health and the avg/max HR + calories land in the backend record.

## Sequencing (two PRs)
1. **Backend PR** (`weight-tracker-backend`): add the optional fields + persistence. Build-verified, merged first.
2. **iOS/watch PR** (`bulkup`): shared `WorkoutMetrics` + finishWorkout signature, `WorkoutMetricsManager`, UI, phone routing + DTO. Built by the user.

## Decomposition context (remaining watch slices)
- Slice 3: phone-absent standalone (shared-KeyChain auth, watch writes backend directly, key-fold replication).
- Later: complications / Smart Stack.
