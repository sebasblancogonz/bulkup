# Apple Watch Slice 2 — HealthKit HR/calories (persisted) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development. Steps use checkbox (`- [ ]`) syntax. **Spans TWO repos** — Task 1 is in `weight-tracker-backend` (own branch/PR, lands first), Tasks 2–7 are in `bulkup`. **Task 4 is a manual USER step in Xcode.**

**Goal:** The watch records HR + active energy via an `HKWorkoutSession`, writes the workout to Apple Health, shows live metrics, and sends avg/max HR + total active energy to the phone on finish, which persists them to the backend workout-session record.

**Architecture:** Watch-side HealthKit (`HKWorkoutSession`/`HKLiveWorkoutBuilder`) auto-started for the active-workout lifetime; metrics delivered to the phone via a `WatchMessage.finishWorkout(metrics:)` payload; phone includes them in the existing `saveSessionToBackend`; backend stores three new optional fields.

**Tech Stack:** HealthKit (watchOS), WatchConnectivity, SwiftUI; Go + MongoDB (backend).

## Global Constraints
- Two repos: backend `/Users/sebastian.blanco/Documents/Sebas/weight-tracker-backend` (Go, builds locally with `go build ./...`); app `/Users/sebastian.blanco/Documents/Sebas/bulkup` (iOS/watch, NOT buildable here — code review + user builds in Xcode; HealthKit/HR only work on a REAL Apple Watch, not the sim).
- New shared type `WorkoutMetrics { avgHeartRate: Int, maxHeartRate: Int, activeEnergyKcal: Double }`; backend uses pointers (`*int`/`*float64`, optional). iOS DTO uses optionals (`Int?`/`Double?`).
- `WatchMessage.finishWorkout` becomes `finishWorkout(metrics: WorkoutMetrics?)`. All call sites update.
- Activity type `.traditionalStrengthTraining`, indoor. Watch target needs the HealthKit capability + `NSHealthShareUsageDescription`/`NSHealthUpdateUsageDescription` (Task 4, manual).
- iPhone authoritative writer; the watch never calls the backend (metrics ride the existing phone save path).
- Self-checks: DEBUG `runSelfCheck()` wired into `bulkup/App/BulkUp.swift`. SourceKit cross-target / "No such module" errors are spurious.

---

## Task 1: [BACKEND repo] Persist HR/calories fields

**Repo:** `weight-tracker-backend`. Own branch `feat/workout-hr-calories`, own PR (lands first).

**Files:**
- Modify: `internal/models/workout_session.go` (both structs)
- Modify: `internal/services/workout_session.go` (`SaveSession` mapping)

- [ ] **Step 1: Branch**

```bash
cd /Users/sebastian.blanco/Documents/Sebas/weight-tracker-backend
git checkout -b feat/workout-hr-calories
```

- [ ] **Step 2: Add fields to both structs**

In `internal/models/workout_session.go`, add to `WorkoutSession` (after `Date string ...`):

```go
	AvgHeartRate     *int     `json:"avgHeartRate,omitempty" bson:"avgHeartRate,omitempty"`
	MaxHeartRate     *int     `json:"maxHeartRate,omitempty" bson:"maxHeartRate,omitempty"`
	ActiveEnergyKcal *float64 `json:"activeEnergyKcal,omitempty" bson:"activeEnergyKcal,omitempty"`
```

And to `SaveWorkoutSessionRequest` (after `Date string ...`):

```go
	AvgHeartRate     *int     `json:"avgHeartRate,omitempty"`
	MaxHeartRate     *int     `json:"maxHeartRate,omitempty"`
	ActiveEnergyKcal *float64 `json:"activeEnergyKcal,omitempty"`
```

- [ ] **Step 3: Map them in `SaveSession`**

In `internal/services/workout_session.go`, in `SaveSession`, add to the `models.WorkoutSession{ ... }` literal (after `Date: req.Date,`):

```go
		AvgHeartRate:     req.AvgHeartRate,
		MaxHeartRate:     req.MaxHeartRate,
		ActiveEnergyKcal: req.ActiveEnergyKcal,
```

- [ ] **Step 4: Build**

Run: `cd /Users/sebastian.blanco/Documents/Sebas/weight-tracker-backend && go build ./...`
Expected: builds with no errors. (If cgo/tesseract flags are needed, use the project's documented build env per CLAUDE.md/memory.)

- [ ] **Step 5: Commit**

```bash
git add internal/models/workout_session.go internal/services/workout_session.go
git commit -m "feat(workout): persist optional HR (avg/max) + active energy from the watch"
```

---

## Task 2: [bulkup] Shared `WorkoutMetrics` + `finishWorkout(metrics:)`

**Repo:** `bulkup` (branch `feat/watch-healthkit`).

**Files:**
- Create: `bulkup/Shared/WorkoutMetrics.swift`
- Modify: `bulkup/Shared/WatchMessage.swift` (the `finishWorkout` case + self-check)

**Interfaces:**
- Produces: `WorkoutMetrics`; `WatchMessage.finishWorkout(metrics: WorkoutMetrics?)`

- [ ] **Step 1: Create `WorkoutMetrics.swift`**

```swift
import Foundation

/// HealthKit summary captured by the watch at workout finish.
struct WorkoutMetrics: Codable, Equatable {
    var avgHeartRate: Int        // bpm, 0 if unavailable
    var maxHeartRate: Int        // bpm, 0 if unavailable
    var activeEnergyKcal: Double // total kcal
}
```

- [ ] **Step 2: Change the `finishWorkout` case**

In `bulkup/Shared/WatchMessage.swift`, replace:

```swift
    case finishWorkout
```
with:
```swift
    case finishWorkout(metrics: WorkoutMetrics?)
```

- [ ] **Step 3: Update the self-check**

In `WatchSync.runSelfCheck()` (`#if DEBUG`), replace the `.finishWorkout` entry in the `msgs` array with:

```swift
            .finishWorkout(metrics: WorkoutMetrics(avgHeartRate: 142, maxHeartRate: 171, activeEnergyKcal: 320.5)),
            .finishWorkout(metrics: nil),
```

- [ ] **Step 4: Verify**

User builds the iOS app — no assertion crash. (Agent: hand-trace the two new round-trips.) The compile will FAIL until Task 3 updates the phone's `handle()` switch (which binds the new associated value) — note this; Tasks 2+3 land together conceptually but commit separately.

- [ ] **Step 5: Commit**

```bash
git add bulkup/Shared/WorkoutMetrics.swift bulkup/Shared/WatchMessage.swift
git commit -m "feat(watch): WorkoutMetrics + finishWorkout carries optional HR/calories"
```

---

## Task 3: [bulkup] Phone routing + DTO + save path

**Repo:** `bulkup`.

**Files:**
- Modify: `bulkup/Models/APIModels.swift` (`SaveWorkoutSessionRequest`, ~line 489)
- Modify: `bulkup/ViewModels/WorkoutSessionManager.swift` (`pendingWatchMetrics` + `saveSessionToBackend`)
- Modify: `bulkup/ViewModels/PhoneWCManager.swift` (`handle` `.finishWorkout(let metrics)`)

**Interfaces:**
- Consumes: `WorkoutMetrics` (Task 2)
- Produces: `WorkoutSessionManager.pendingWatchMetrics`

- [ ] **Step 1: Add optional fields to the iOS DTO**

In `bulkup/Models/APIModels.swift`, in `SaveWorkoutSessionRequest`, after `let date: String`:

```swift
    let avgHeartRate: Int?
    let maxHeartRate: Int?
    let activeEnergyKcal: Double?
```

- [ ] **Step 2: Stash + send metrics in `WorkoutSessionManager`**

In `bulkup/ViewModels/WorkoutSessionManager.swift`, add a property near the other `@Published`/state:

```swift
    /// Metrics delivered from the watch at finish; included in the next backend save, then cleared.
    var pendingWatchMetrics: WorkoutMetrics?
```

In `saveSessionToBackend(...)`, where the `SaveWorkoutSessionRequest(...)` is constructed, add the three arguments (and clear after building):

```swift
        let request = SaveWorkoutSessionRequest(
            // ... existing args ...
            date: dateStr,
            avgHeartRate: pendingWatchMetrics.map { $0.avgHeartRate > 0 ? $0.avgHeartRate : nil } ?? nil,
            maxHeartRate: pendingWatchMetrics.map { $0.maxHeartRate > 0 ? $0.maxHeartRate : nil } ?? nil,
            activeEnergyKcal: pendingWatchMetrics.map { $0.activeEnergyKcal > 0 ? $0.activeEnergyKcal : nil } ?? nil
        )
        pendingWatchMetrics = nil
```

(Read the existing `SaveWorkoutSessionRequest(...)` call and append the three new arguments in the right position — the memberwise init order must match the struct: the three new fields come LAST, after `date`.)

- [ ] **Step 3: Route `finishWorkout(metrics:)` on the phone**

In `bulkup/ViewModels/PhoneWCManager.swift`, change the `handle` switch case:

```swift
        case .finishWorkout:
            _ = WorkoutSessionManager.shared.finishWorkout(trainingManager: tm)
            WorkoutSessionManager.shared.saveSessionToBackend(
                userId: AuthManager.shared.user?.id ?? "", planId: tm.trainingPlanId, trainingManager: tm)
```
to:
```swift
        case .finishWorkout(let metrics):
            WorkoutSessionManager.shared.pendingWatchMetrics = metrics
            _ = WorkoutSessionManager.shared.finishWorkout(trainingManager: tm)
            WorkoutSessionManager.shared.saveSessionToBackend(
                userId: AuthManager.shared.user?.id ?? "", planId: tm.trainingPlanId, trainingManager: tm)
```

- [ ] **Step 4: Verify**

User builds the iOS app — compiles (the `finishWorkout` switch now binds `metrics`, resolving the Task 2 exhaustiveness gap). No behavior change without a watch.

- [ ] **Step 5: Commit**

```bash
git add bulkup/Models/APIModels.swift bulkup/ViewModels/WorkoutSessionManager.swift bulkup/ViewModels/PhoneWCManager.swift
git commit -m "feat(watch): phone persists watch HR/calories via the existing save path"
```

---

## Task 4: [bulkup, MANUAL USER] HealthKit capability + usage strings

**This is a human step in Xcode. The controller presents this and waits for confirmation before the HealthKit code tasks are merged.** (Tasks 5–6 can be WRITTEN beforehand — `import HealthKit` compiles without the capability — but won't FUNCTION until this is done, so do it before building/running.)

- [ ] **Step 1:** `BulkUpWatch` target → Signing & Capabilities → **+ Capability → HealthKit**.
- [ ] **Step 2:** `BulkUpWatch Watch App/Info.plist` → add `NSHealthShareUsageDescription` = "BulkUp uses your heart rate and energy to track your workouts." and `NSHealthUpdateUsageDescription` = "BulkUp saves your workouts to Apple Health."
- [ ] **Step 3:** Confirm the watch target still builds.

---

## Task 5: [bulkup watch] `WorkoutMetricsManager` (HealthKit)

**Repo:** `bulkup`. File in `BulkUpWatch Watch App/` (synchronized group → auto-includes).

**Files:**
- Create: `BulkUpWatch Watch App/WorkoutMetricsManager.swift`

**Interfaces:**
- Produces: `WorkoutMetricsManager` (`@Published heartRate: Int`, `@Published activeEnergy: Double`, `requestAuthorization()`, `start()`, `end() async -> WorkoutMetrics?`)

- [ ] **Step 1: Create `WorkoutMetricsManager.swift`**

```swift
import Foundation
import HealthKit

/// Owns the watch HKWorkoutSession + live builder: live HR/energy for the UI, and
/// avg/max HR + total active energy captured at finish. Watch-only.
@MainActor
final class WorkoutMetricsManager: NSObject, ObservableObject {
    @Published var heartRate: Int = 0
    @Published var activeEnergy: Double = 0   // kcal
    @Published var isRunning = false

    private let store = HKHealthStore()
    private var session: HKWorkoutSession?
    private var builder: HKLiveWorkoutBuilder?

    private let hrType = HKQuantityType(.heartRate)
    private let energyType = HKQuantityType(.activeEnergyBurned)

    func requestAuthorization() {
        guard HKHealthStore.isHealthDataAvailable() else { return }
        let share: Set = [HKQuantityType.workoutType(), energyType]
        let read: Set = [hrType, energyType]
        store.requestAuthorization(toShare: share, read: read) { _, _ in }
    }

    func start() {
        guard HKHealthStore.isHealthDataAvailable(), session == nil else { return }
        let config = HKWorkoutConfiguration()
        config.activityType = .traditionalStrengthTraining
        config.locationType = .indoor
        do {
            let s = try HKWorkoutSession(healthStore: store, configuration: config)
            let b = s.associatedWorkoutBuilder()
            b.dataSource = HKLiveWorkoutDataSource(healthStore: store, workoutConfiguration: config)
            s.delegate = self
            b.delegate = self
            session = s
            builder = b
            let start = Date()
            s.startActivity(with: start)
            b.beginCollection(withStart: start) { _, _ in }
            isRunning = true
        } catch {
            session = nil; builder = nil
        }
    }

    /// Ends the session, saves the HKWorkout to Health, and returns the summary.
    func end() async -> WorkoutMetrics? {
        guard let s = session, let b = builder else { return nil }
        session = nil; builder = nil; isRunning = false
        let end = Date()
        s.end()
        let avg = stat(b, hrType, .discreteAverage)
        let mx  = stat(b, hrType, .discreteMax)
        let kcal = b.statistics(for: energyType)?.sumQuantity()?.doubleValue(for: .kilocalorie()) ?? 0
        await withCheckedContinuation { (cont: CheckedContinuation<Void, Never>) in
            b.endCollection(withEnd: end) { _, _ in
                b.finishWorkout { _, _ in cont.resume() }
            }
        }
        return WorkoutMetrics(
            avgHeartRate: Int(avg.rounded()),
            maxHeartRate: Int(mx.rounded()),
            activeEnergyKcal: kcal
        )
    }

    private func stat(_ b: HKLiveWorkoutBuilder, _ t: HKQuantityType, _ k: HKStatisticsOptions) -> Double {
        let q: HKQuantity? = (k == .discreteMax)
            ? b.statistics(for: t)?.maximumQuantity()
            : b.statistics(for: t)?.averageQuantity()
        return q?.doubleValue(for: HKUnit.count().unitDivided(by: .minute())) ?? 0
    }
}

extension WorkoutMetricsManager: HKWorkoutSessionDelegate {
    nonisolated func workoutSession(_ ws: HKWorkoutSession, didChangeTo to: HKWorkoutSessionState,
                                    from: HKWorkoutSessionState, date: Date) {}
    nonisolated func workoutSession(_ ws: HKWorkoutSession, didFailWithError error: Error) {}
}

extension WorkoutMetricsManager: HKLiveWorkoutBuilderDelegate {
    nonisolated func workoutBuilderDidCollectEvent(_ b: HKLiveWorkoutBuilder) {}
    nonisolated func workoutBuilder(_ b: HKLiveWorkoutBuilder, didCollectDataOf types: Set<HKSampleType>) {
        let hrVal = (b.statistics(for: hrType)?.mostRecentQuantity())?
            .doubleValue(for: HKUnit.count().unitDivided(by: .minute()))
        let kcal = b.statistics(for: energyType)?.sumQuantity()?.doubleValue(for: .kilocalorie())
        Task { @MainActor in
            if let hrVal { self.heartRate = Int(hrVal.rounded()) }
            if let kcal { self.activeEnergy = kcal }
        }
    }
}
```

(`hrType`/`energyType` are referenced from the `nonisolated` delegate — they're immutable `let`s set at init, so they're safe to read; if the compiler objects to actor isolation, mark them `nonisolated let`.)

- [ ] **Step 2: Verify (read-through; no build here)**

Confirm: `start()` is idempotent (guards `session == nil`); `end()` nils the session first (idempotent — Finish button + `.onDisappear` can't double-finish), reads avg/max HR + sum energy, awaits `finishWorkout`, returns `WorkoutMetrics`; `didCollectDataOf` updates `@Published` on the main actor. State this in the report.

- [ ] **Step 3: Commit**

```bash
git add "BulkUpWatch Watch App/WorkoutMetricsManager.swift"
git commit -m "feat(watch): WorkoutMetricsManager — HKWorkoutSession HR + active energy"
```

---

## Task 6: [bulkup watch] Wire metrics into the UI + finish

**Repo:** `bulkup`.

**Files:**
- Modify: `BulkUpWatch Watch App/BulkUpWatchApp.swift` (own + inject the manager, request auth)
- Modify: `BulkUpWatch Watch App/ActiveWorkoutView.swift` (lifecycle, metrics row, Finish sends metrics)

**Interfaces:**
- Consumes: `WorkoutMetricsManager` (Task 5), `WatchMessage.finishWorkout(metrics:)` (Task 2)

- [ ] **Step 1: Own + inject the manager**

In `BulkUpWatch Watch App/BulkUpWatchApp.swift`, replace the body:

```swift
@main
struct BulkUpWatch_Watch_AppApp: App {
    @StateObject private var wc = WatchWCManager()
    @StateObject private var metrics = WorkoutMetricsManager()
    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(wc)
                .environmentObject(metrics)
                .onAppear {
                    wc.activate()
                    metrics.requestAuthorization()
                }
        }
    }
}
```

- [ ] **Step 2: Lifecycle + metrics row + Finish in `ActiveWorkoutView`**

In `BulkUpWatch Watch App/ActiveWorkoutView.swift`: add `@EnvironmentObject var metrics: WorkoutMetricsManager` and `@State private var finishing = false`. Add the lifecycle modifiers on the root view and a metrics row, and change the Finish button to send metrics. The active-set `VStack` becomes:

```swift
            ScrollView {
                VStack(spacing: 10) {
                    Text(s.exerciseName).font(.headline).lineLimit(1)
                    Text("Serie \(s.setIndex + 1)/\(s.setsTotalForExercise)")
                        .font(.caption).foregroundStyle(.secondary)

                    if metrics.isRunning {
                        HStack(spacing: 12) {
                            Label("\(metrics.heartRate)", systemImage: "heart.fill")
                                .foregroundStyle(.red)
                            Label("\(Int(metrics.activeEnergy)) kcal", systemImage: "flame.fill")
                                .foregroundStyle(.orange)
                        }.font(.caption).monospacedDigit()
                    }

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

                    Button(finishing ? "Finishing…" : "Finish") {
                        finishing = true
                        Task {
                            let m = await metrics.end()
                            wc.send(.finishWorkout(metrics: m))
                        }
                    }
                    .disabled(finishing)
                    .font(.caption).foregroundStyle(.secondary)
                }.padding()
            }
```

Add the lifecycle modifiers to the **outer** `body` (so they cover rest + active states for the whole active workout) — wrap the existing `if/else if/else` in a `Group { ... }` and attach:

```swift
        .onAppear { metrics.start() }
        .onDisappear { Task { _ = await metrics.end() } }
```

- [ ] **Step 3: Verify (read-through; no build here)**

Confirm: `metrics.start()` on appear, `end()` safety-net on disappear (idempotent), the Finish button awaits `end()` then sends `.finishWorkout(metrics: m)` with a "Finishing…" disabled state; the HR/kcal row shows only while running. State this in the report.

- [ ] **Step 4: Commit**

```bash
git add "BulkUpWatch Watch App/BulkUpWatchApp.swift" "BulkUpWatch Watch App/ActiveWorkoutView.swift"
git commit -m "feat(watch): show live HR/calories and send metrics on finish"
```

---

## Self-Review

**Spec coverage:** backend persistence (Task 1) · shared `WorkoutMetrics` + `finishWorkout(metrics:)` (Task 2) · iOS DTO + phone routing + save path (Task 3) · HealthKit capability/usage strings (Task 4) · `HKWorkoutSession` HR + energy + Apple Health write (Task 5) · auto-start lifecycle + live UI + finish-sends-metrics (Tasks 5–6). Edge cases (HK unavailable → nil metrics; double-end idempotent; phone-initiated finish) handled in the manager + routing.

**Placeholder scan:** No TBD/TODO. The "read the existing call and append in the right position" notes (Task 3 Step 2) are because the existing `SaveWorkoutSessionRequest(...)` args aren't reproduced verbatim — the new fields go LAST after `date`; that's a precise instruction, not a placeholder.

**Type consistency:** `WorkoutMetrics{avgHeartRate:Int, maxHeartRate:Int, activeEnergyKcal:Double}` consistent across shared, the iOS DTO optionals, and the backend pointers. `finishWorkout(metrics:)` signature identical in the watch sender (Task 6), the self-check (Task 2), and the phone handler (Task 3). `WorkoutMetricsManager.{start,end,requestAuthorization,heartRate,activeEnergy,isRunning}` referenced consistently in Task 6.

**Cross-repo:** Task 1 (backend) is independent and lands first via its own branch/PR; Tasks 2–6 (bulkup) form the second PR. Task 4 is manual.
