# Apple Watch Slice 3b — Offline finish + reconciliation — Design

**Date:** 2026-06-28
**Scope:** Make finishing a watch-driven workout persist correctly even when the phone was unreachable during it. The watch sends its **full authoritative `LiveWorkout` snapshot** with the finish; the phone **adopts** that snapshot, then saves via its existing path. The iPhone stays the sole backend writer.

**Stacking:** branched on Slice 3a (`feat/watch-local-engine`, PR #42), which is itself on Slice 2 (#41). Merges after 3a. This is the final slice of the offline-resilient standalone (Option A: 3a engine → 3b offline finish-sync).

---

## Goals
- A workout the watch drove while the phone was unreachable (the "phone in the locker" case) persists to the backend with the **correct final state** — every offline-completed set + adjusted weight — once the phone reconnects.
- Robust by construction: the finish carries the watch's final state as a **snapshot**, so the save doesn't depend on replaying intermediate offline actions in order.

## Non-goals (out of scope)
- **Killed-app case:** if the phone app was fully terminated mid-workout (not merely suspended), its in-memory session is gone and the deferred backend save is skipped. The workout still lives in **Apple Health** (the watch `HKWorkout`, Slice 2) and in the App-Group store. A session-independent reconstruct-from-snapshot save is a future hardening (decided: lean).
- **Offline cold-start** (start a workout with the phone never present) — out of Option A entirely.
- No backend change; the watch is still not a backend writer.

## Decision (locked)
- **Lean:** adopt the snapshot into the live (alive/suspended) phone session, then save via the existing path.

---

## Mechanism

The realistic offline flow: the workout is **started with the phone present** (phone holds an active `WorkoutSessionManager` session). The phone goes unreachable mid-workout but the app is **suspended, not killed**, so the session stays in memory. The watch keeps driving locally (Slice 3a) and finishes offline. The finish — and the queued action messages — ride the existing reliable `transferUserInfo` queue and are delivered when the phone resumes on reconnect. The phone adopts the watch's final snapshot and saves.

Why a snapshot rather than relying on Slice 3a's action replay: `transferUserInfo` is ordered + reliable, but reconstructing state by replaying N actions is fragile (and weights can diverge if seeded differently). A single authoritative snapshot at finish makes the save self-contained and idempotent.

## Components

### Shared — `bulkup/Shared/WatchMessage.swift`
Change the finish case to carry the snapshot:
```swift
case finishWorkout(live: LiveWorkout?, metrics: WorkoutMetrics?)
```
All call sites update. `WatchSync.runSelfCheck()` round-trips `.finishWorkout(live: <a LiveWorkout>, metrics: <m>)` and `.finishWorkout(live: nil, metrics: nil)`.

### Watch — `BulkUpWatch Watch App/WatchWCManager.swift` + `ActiveWorkoutView.swift`
- `WatchWCManager` gains:
  ```swift
  func finishWorkout(metrics: WorkoutMetrics?) { send(.finishWorkout(live: live, metrics: metrics)) }
  ```
  (sends the manager's own authoritative `live` working copy from Slice 3a).
- `ActiveWorkoutView`'s Finish button changes from `wc.send(.finishWorkout(metrics: m))` to `wc.finishWorkout(metrics: m)`. The "Finishing…" disabled state + `await metrics.end()` (Slice 2) are unchanged.

### Phone — `bulkup/ViewModels/PhoneWCManager.swift`
Route the new signature; adopt the snapshot before finishing:
```swift
case .finishWorkout(let live, let metrics):
    if let live {
        SharedWorkoutStore.save(live)
        wsm.reconcileFromStore(trainingManager: tm)
    }
    wsm.pendingWatchMetrics = metrics
    _ = wsm.finishWorkout(trainingManager: tm)
    wsm.saveSessionToBackend(userId: AuthManager.shared.user?.id ?? "", planId: tm.trainingPlanId, trainingManager: tm)
```
- `SharedWorkoutStore.save(live)` writes the watch's final state into the App-Group store.
- `reconcileFromStore(trainingManager:)` (existing; guards `isActive` + `currentDayName`) pulls the store's completed sets + weights into the in-memory session — including the offline-completed ones.
- The existing `finishWorkout` + `saveSessionToBackend` then build + persist the record (with the watch's HR/calorie `metrics` from Slice 2).

### Backend / WorkoutSessionManager internals — unchanged
No new fields, no new save path. `reconcileFromStore`/`finishWorkout`/`saveSessionToBackend` are used as-is.

---

## Data flow (finish after an offline stretch)
1. Phone present: workout started (phone session `isActive`). Phone goes unreachable; app suspends (session retained).
2. Watch drives locally (Slice 3a optimistic engine), finishes → `wc.finishWorkout(metrics:)` → `send(.finishWorkout(live: <final snapshot>, metrics:))` → queued via `transferUserInfo`.
3. Phone reconnects → resumes → delivers the queued message → routes `.finishWorkout(live:metrics:)` → `save(live)` + `reconcileFromStore` (session adopts the offline sets + weights) → `finishWorkout` + `saveSessionToBackend` (includes metrics).
4. Backend record reflects the watch-driven workout.

## Error handling
- `live == nil` (phone-driven finish, or HK-less path): skip the adopt; behave exactly as Slice 2 (`finishWorkout` + save from the phone's own state). No regression for finishing on the phone.
- Phone session NOT active when the finish arrives (killed-app edge): `reconcileFromStore` + `saveSessionToBackend` guard on `isActive`/`currentDayName` and no-op → backend save skipped. The `HKWorkout` (Apple Health) + the App-Group snapshot remain. Accepted (lean).
- Idempotency: adopting a snapshot is overwrite-then-reconcile; a duplicate finish delivery re-adopts the same state and re-saves the same record content (the save path is the existing one; a duplicate is at worst a duplicate row — same as today's double-finish behavior, unchanged by 3b).

## Testing
- `WatchSync.runSelfCheck()` (DEBUG) round-trips the new `finishWorkout(live:metrics:)` (with a `LiveWorkout` and `nil`). Wired into `BulkUp.swift`.
- watchOS/iOS not buildable here — USER verifies on a real Apple Watch: start a workout with the phone present, put the phone in airplane mode / out of range, complete sets on the watch, finish on the watch, restore the phone connection, confirm the backend session record shows the offline-completed sets + weights + HR/calories.

## Decomposition (Option A — complete after this)
- 3a: local engine (optimistic, phone-reconciled) — done (#42).
- **3b (this): offline finish-sync** — snapshot-on-finish + phone adopt.
- Future hardening (not scheduled): reconstruct-from-snapshot save for the killed-app case; complications / Smart Stack.
