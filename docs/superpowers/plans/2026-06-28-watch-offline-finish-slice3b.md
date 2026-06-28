# Apple Watch Slice 3b — Offline finish + reconciliation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development. Steps use checkbox (`- [ ]`) syntax.

**Goal:** The watch's finish message carries its full authoritative `LiveWorkout` snapshot; the phone adopts it before saving, so a workout driven while the phone was unreachable persists correctly on reconnect.

**Architecture:** `WatchMessage.finishWorkout` gains a `live: LiveWorkout?` snapshot. The watch sends its Slice-3a working copy on finish. The phone routes the new case, writes the snapshot into the App-Group store + `reconcileFromStore` (adopting the offline-completed sets/weights into the live session), then runs the existing `finishWorkout` + `saveSessionToBackend`.

**Tech Stack:** SwiftUI (watchOS), WatchConnectivity, the shared `LiveWorkout` model.

## Global Constraints
- `bulkup` repo, branch `feat/watch-offline-finish` — **stacked on Slice 3a** (`feat/watch-local-engine`/#42), itself on Slice 2 (#41). Merges after 3a.
- ENV: not buildable here (watchOS needs a real device; the iOS app builds in Xcode). Verified by code review + the DEBUG `runSelfCheck()` for the shared type. SourceKit cross-module/"No such module" errors are spurious.
- **Lean:** adopt the snapshot into the live (alive/suspended) phone session; no session-independent save. Killed-app edge accepted (workout still in Apple Health + the store).
- Backend + `WorkoutSessionManager` internals UNCHANGED — reuse `reconcileFromStore`/`finishWorkout`/`saveSessionToBackend` as-is.
- `live == nil` (phone-driven finish): skip the adopt; behave exactly as Slice 2.

---

## Task 1: Shared `finishWorkout(live:metrics:)` + watch sends the snapshot

**Files:**
- Modify: `bulkup/Shared/WatchMessage.swift` (the `finishWorkout` case + self-check)
- Modify: `BulkUpWatch Watch App/WatchWCManager.swift` (add `finishWorkout(metrics:)`)
- Modify: `BulkUpWatch Watch App/ActiveWorkoutView.swift` (Finish button calls the manager)

**Interfaces:**
- Produces: `WatchMessage.finishWorkout(live: LiveWorkout?, metrics: WorkoutMetrics?)`; `WatchWCManager.finishWorkout(metrics: WorkoutMetrics?)`

- [ ] **Step 1: Change the `finishWorkout` case**

In `bulkup/Shared/WatchMessage.swift`, replace:
```swift
    case finishWorkout(metrics: WorkoutMetrics?)
```
with:
```swift
    case finishWorkout(live: LiveWorkout?, metrics: WorkoutMetrics?)
```

- [ ] **Step 2: Update the self-check round-trip**

In `WatchSync.runSelfCheck()` (`#if DEBUG`), replace the two `.finishWorkout(...)` entries in the `msgs` array (currently `.finishWorkout(metrics: WorkoutMetrics(...))` and `.finishWorkout(metrics: nil)`) with snapshot-carrying versions. First add a sample workout just above the `let msgs = [...]` declaration:

```swift
        let sampleLive = LiveWorkout(
            dayName: "lunes", workoutName: "Push", startDate: Date(timeIntervalSince1970: 1_700_000_000),
            isPaused: false, weightUnit: "kg", weightStep: 2.5, repStep: 1,
            sets: [LiveWorkout.LiveSet(exerciseIndex: 0, exerciseName: "Press", setIndex: 0,
                   setsTotalForExercise: 1, weight: 40, reps: 10, restSeconds: 60, completed: true)],
            cursor: 1, restEndDate: nil)
```
and the two array entries become:
```swift
            .finishWorkout(live: sampleLive, metrics: WorkoutMetrics(avgHeartRate: 142, maxHeartRate: 171, activeEnergyKcal: 320.5)),
            .finishWorkout(live: nil, metrics: nil),
```

- [ ] **Step 3: Add `finishWorkout(metrics:)` to `WatchWCManager`**

In `BulkUpWatch Watch App/WatchWCManager.swift`, add after the other optimistic action methods (after `addRest(_:)`):
```swift
    /// Finish: send the watch's authoritative LiveWorkout snapshot so the phone
    /// persists the correct final state even if it was unreachable during the workout.
    func finishWorkout(metrics: WorkoutMetrics?) { send(.finishWorkout(live: live, metrics: metrics)) }
```

- [ ] **Step 4: Finish button calls the manager**

In `BulkUpWatch Watch App/ActiveWorkoutView.swift`, in the Finish button's `Task`, replace:
```swift
                                wc.send(.finishWorkout(metrics: m))
```
with:
```swift
                                wc.finishWorkout(metrics: m)
```
(The `finishing` disabled state and `let m = await metrics.end()` from Slice 2 are unchanged.)

- [ ] **Step 5: Verify**

The WATCH target now compiles (shared + watch updated). The iOS app target will NOT compile until Task 2 fixes the phone's `.finishWorkout` switch case — expected; note it. Agent: hand-trace the two new self-check round-trips (`sampleLive` + metrics, and the `nil/nil` case) and confirm they hold (`LiveWorkout` is `Codable`+`Equatable`; the fixed `startDate` round-trips deterministically).

- [ ] **Step 6: Commit**

```bash
git add bulkup/Shared/WatchMessage.swift "BulkUpWatch Watch App/WatchWCManager.swift" "BulkUpWatch Watch App/ActiveWorkoutView.swift"
git commit -m "feat(watch): finish carries the LiveWorkout snapshot; watch sends it"
```

---

## Task 2: Phone adopts the snapshot before saving

**Files:**
- Modify: `bulkup/ViewModels/PhoneWCManager.swift` (the `.finishWorkout` routing)

**Interfaces:**
- Consumes: `WatchMessage.finishWorkout(live:metrics:)` (Task 1); existing `SharedWorkoutStore.save(_:)`, `WorkoutSessionManager.{reconcileFromStore(trainingManager:), pendingWatchMetrics, finishWorkout(trainingManager:), saveSessionToBackend(userId:planId:trainingManager:)}`

- [ ] **Step 1: Adopt the snapshot in the finish route**

In `bulkup/ViewModels/PhoneWCManager.swift`, replace the `.finishWorkout` case:
```swift
        case .finishWorkout(let metrics):
            WorkoutSessionManager.shared.pendingWatchMetrics = metrics
            _ = wsm.finishWorkout(trainingManager: tm)
            wsm.saveSessionToBackend(
                userId: AuthManager.shared.user?.id ?? "",
                planId: tm.trainingPlanId,
                trainingManager: tm
            )
```
with:
```swift
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
```

- [ ] **Step 2: Verify**

User builds the iOS app — compiles (the `.finishWorkout` switch now binds `live` + `metrics`, resolving the Task-1 gap). Read-through: when `live != nil` the store is overwritten with the snapshot and `reconcileFromStore` (guards `isActive`/`currentDayName`) adopts it; when `live == nil` the adopt is skipped (Slice 2 behavior preserved). State this in the report. SourceKit "No such module 'WatchConnectivity'" spurious.

- [ ] **Step 3: Commit**

```bash
git add bulkup/ViewModels/PhoneWCManager.swift
git commit -m "feat(watch): phone adopts the watch snapshot on finish (offline-resilient save)"
```

---

## Self-Review

**Spec coverage:** snapshot-carrying finish message + self-check (Task 1 Steps 1–2) · watch sends its `live` snapshot on finish (Task 1 Steps 3–4) · phone adopts (`save(live)` + `reconcileFromStore`) then existing finish/save, with `live == nil` skipping the adopt (Task 2). Backend/WorkoutSessionManager internals unchanged (no task — by design). Killed-app edge accepted per spec (no task).

**Placeholder scan:** No TBD/TODO; every code step shows complete code. The `sampleLive` literal matches the `LiveWorkout`/`LiveSet` field order from `SharedWorkoutStore.swift`.

**Type consistency:** `finishWorkout(live: LiveWorkout?, metrics: WorkoutMetrics?)` is identical in the case definition (Task 1), the self-check (Task 1), the watch sender `WatchWCManager.finishWorkout` (Task 1), and the phone binding `case .finishWorkout(let live, let metrics)` (Task 2). `wsm`/`tm` match the existing handler's local names. `reconcileFromStore(trainingManager:)`, `saveSessionToBackend(userId:planId:trainingManager:)`, `pendingWatchMetrics`, `SharedWorkoutStore.save(_:)` are the existing signatures.
