# Root-cause report — Apple Watch workout bugs (2026-06-29)

Multi-agent investigation (19 agents, 11 candidates → 1 confirmed, 9 refuted, 1 unclear). Two user-reported symptoms.

## Symptom A — watch runs the WRONG exercise · CONFIRMED root cause
`buildLiveWorkout()` iterates `dayData.exercises` **without sorting by `orderIndex`** (`bulkup/ViewModels/WorkoutSessionManager.swift:813`). `TrainingDay.exercises` is a SwiftData to-many relation with **no guaranteed order** (`TrainingModels.swift:18`, no `@Relationship` ordering). The session cursor indexes into the flat `sets[]` array this builds, and the watch renders `live.current` (`SharedWorkoutStore.swift:31`, `ActiveWorkoutView.swift:13`). When SwiftData returns exercises out of `orderIndex` order (the cold-launch fetch path, `TrainingManager.swift:37,46`), the session starts at / advances through the wrong exercise.

It is an **order/sequence** bug, not a wrong-name bug: each `LiveSet` embeds its own `exerciseName`, so name+cursor are always the same element. `buildLiveWorkout` is the **only** order-sensitive consumer that doesn't sort — `PhoneWCManager.swift:50`, `TrainingView.swift:523/775/924`, `TodayView.swift:513` all sort by `orderIndex`.

**Fix (P0, one line):** sort the loop by `orderIndex`. (+ optionally the order-independent loops at ~117/202/748 for regression-proofing.)

Verified CLEAN (do not chase): WCSession encode/decode, `WatchWCManager.apply()`, `RootView→ActiveWorkoutView`, `SharedWorkoutStore.current`.

## Symptom B — weight entered on the watch is NOT saved
User repro: **the set shows completed, but the weight is not persisted** (gone when opening the phone app). This matches the confirmed mechanism below.

- **`.completeSet` carries no weight payload** (`WatchMessage.swift:8`, `WatchWCManager.swift:38`). The watch sends `.adjustWeight(delta)` messages then a bare `.completeSet`; the phone reconstructs the completed set's weight **only from its own store**. `.adjustWeight` mutates only `SharedWorkoutStore` and does **not** trigger `reconcileFromStore` (`PhoneWCManager.swift:79-80`), and is transported via `sendMessage` with `transferUserInfo` fallback. If a delta is lost/reordered relative to `.completeSet`, the completion persists but the weight is stale/0; `reconcileFromStore`'s `if liveSet.weight > 0` guard (`WorkoutSessionManager.swift:450`) then drops the 0 → **set completed, weight lost.** The `finishWorkout` snapshot (Slice 3b) is the only backstop and fails if it never arrives (watch crash) or in the reorder window.

**Fixes (chosen: harden B):**
- **P1 (primary):** make `.completeSet` self-contained — carry `(exerciseIndex, setIndex, weight, reps)`; the phone applies it by identity before completing, instead of depending on prior deltas + cursor. `WatchMessage.swift`, `WatchWCManager.completeSet`, `PhoneWCManager.handle`.
- **P3 (latency/visibility):** call `reconcileFromStore` after `.adjustWeight`/`.adjustReps` in `PhoneWCManager` (idempotent) so weights surface immediately, not only at finish.
- **P2 (week-key fragility):** anchor `weekStart` at capture time in `saveWeightsToDatabase` / `reconcileFromStore` (TOCTOU if the user changes week mid-workout → saves 0). Real but rare, not watch-specific.

REFUTED (do not chase): the `newlyCompleted` guard (unreachable — can't edit a completed set from the watch); accented-day key mismatch (the watch flow pre-normalizes — CLEAN today); `transferUserInfo` coalescing (FIFO guaranteed delivery, premise wrong).

## Prioritized fixes
1. **P0 (A, confirmed):** `WorkoutSessionManager.swift:813` — `.sorted(by: { $0.orderIndex < $1.orderIndex })`.
2. **P1 (B, primary):** self-contained `.completeSet` (weight/reps by identity).
3. **P3 (B):** reconcile after adjustWeight/adjustReps.
4. **P2 (B):** anchor weekStart at capture.
5. **P4 (A, optional):** same sort on the other `dayData.exercises` loops.

Do NOT: touch `PhoneWCManager:50` (already correct); chase the `newlyCompleted` guard or `transferUserInfo` coalescing.
