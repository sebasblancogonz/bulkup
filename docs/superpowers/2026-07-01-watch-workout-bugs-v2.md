# Watch workout bugs — corrected root cause (v2, after fix #1 failed)

Fix #1 (sort exercises by `orderIndex`) did NOT resolve either symptom. Focused re-investigation (7 agents) corrected the mechanisms.

## A — "watch shows the LAST exercise"
**Root cause:** `prePopulateFromWeights` (`WorkoutSessionManager.swift:108-131`, called from `startWorkout:90`) marks every set already logged this week as completed, and `startWorkout` builds with `seedCursorAtZero: true` (`:98`). So on start it shows the **first** (completed) exercise, and after the **first "complete" tap**, `advanceCursor` skips all pre-marked sets → lands on the first incomplete = the **last** exercise. Deterministic, but only when there are already-logged sets ("Continuar Entreno", `logged > 0`).

**Product decision (user):** respect the button — "Comenzar" = fresh (first exercise), "Continuar" = resume (first *incomplete* set). Both currently call the same `startWorkout` with `seedCursorAtZero: true`.

**Fix:** keep `prePopulateFromWeights` (it marks the done sets for "Continuar"), but seed the cursor by resume-state in `startWorkout`:
```swift
let isResume = !completedSetIds.isEmpty            // prePopulate marked ≥1 done set
let live = buildLiveWorkout(dayName: dayName, trainingManager: tm, seedCursorAtZero: !isResume)
```
Fresh (nothing pre-marked) → cursor 0 → first exercise. Resume → advance to first incomplete. Does NOT touch the `buildLiveWorkout`/`SharedWorkoutStore` Bug-3 self-check (that tests the struct with `seedCursorAtZero:true` directly). Do NOT make `advanceCursor` unconditional (that reverts #33 + breaks Bug-3).

## B — "set completed with EMPTY weight, also from the phone"
Two independent gaps; **phone is the primary reported one**.

**B-phone (primary):** `ExerciseCardView.completeSetAndSave` (~858-900) + `completeButton` (~536) complete a set with **no weight guard**. `weightTexts` starts empty (the previous-week weight is only a *hint* → `previousWeights`, never the value). Completing a weight-tracking set without a typed weight → `weightValue == 0` → `updateWeight` skipped, but the set is marked completed and `saveWeights` persists weight 0. → "completed but empty."

**B-watch (secondary):** `WatchWCManager.completeSet()` sends `s.weight`; a never-logged set has `weight = 0`. Completing without adjusting the stepper → persists 0.

**Product decision (user):** block completing a weight-tracking set with an empty weight.

**Fix B-phone:** in `completeSetAndSave`, `guard !exercise.weightTracking || weightValue > 0 else { <focus the weight field>; return }`.

**Fix B-watch:** add `weightTracking: Bool` to `LiveWorkout.LiveSet` (populate from `exercise.weightTracking` in `buildLiveWorkout`); on the watch, disable/guard the complete button when `current.weightTracking && current.weight == 0` (bodyweight exercises, `weightTracking == false`, still complete at 0).

## Deferred (not the reported symptom)
- **reconcile `newlyCompleted` guard** (`WorkoutSessionManager.swift:459`): with `prePopulate` kept, a resumed pre-marked set re-logged from the watch persists STALE not empty (corner case). Low priority.

## Ruled out (clean)
key-mismatch across `generateWeightKey` callers (current week); `syncStoreFromSession` is dead code; the second `broadcast()` doesn't move the cursor; `seq` monotonic guard is correct.
