# Workout UX improvements — design

**Date:** 2026-07-08
**Source:** user feedback (4 items), refined with product owner.

## 1. Persistent rest countdown + workout focus mode

**Problem:** the rest countdown lives only in `RestTimerSheet`; swiping the sheet down hides the countdown even though the timer keeps running.

**Design:**
- Split "rest running" from "sheet visible" in `WorkoutSessionManager`: new `@Published var restSheetVisible`. `startRestTimer` sets both; rest end/skip clears both; sheet dismissal clears only `restSheetVisible`.
- `TrainingView` presents the sheet on `restSheetVisible`. While `restTimerActive && !restSheetVisible`, a slim full-width banner renders under `ActiveWorkoutHeader`: remaining time (monospaced, accent), thin linear progress, inline "Saltar" and "+30s". Tapping the time re-opens the sheet.
- Focus mode: while `workoutSession.isActive`, the "Mis planes / Plan activo" section pills are hidden.

## 2. Rest ring backdrop

Delete the `RadialGradient(BulkUpColors.shadow…)` disc behind the progress ring in `RestTimerSheet`. Ring, border, and countdown text unchanged.

## 3. Decimal weights truncated in workout mode

**Problem:** weight `TextField` is 36pt (`SetCol.kg` 100 − 2×32 steppers); "102.5" needs ~45pt.

**Design:** widen the field to 46pt without touching stepper tap targets (32pt, kept for accessibility): `SetCol.serie` 30→26, `SetCol.gap` 10→8, `SetCol.kg` 100→110. Total row width unchanged; reps/check columns untouched.

## 4. Exercise alternatives (session-only swap)

**Problem:** users need a substitute when a machine is occupied, with the same muscle impact and stimulus.

**Design:**
- Entry point: an "Alternativas" action on the exercise card in workout mode, opening a sheet with the top 3 candidates.
- Candidate source: the already-loaded exercise DB (`RMExerciseFull` via `ExerciseExplorerManager`). The current plan exercise is matched to a DB entry by folded name (`name` or `nameEs`). No match / DB not loaded → friendly empty state.
- Ranking (pure function, DEBUG self-checked): require same first primary muscle; score +2 same `mechanic`, +1 same `force`, +1 *different* `equipment` (the trigger is "machine occupied"); ties broken by name; top 3. Excludes the exercise itself.
- Swap semantics: session-only. `WorkoutSessionManager` gains `@Published var exerciseOverrides: [String: String]` (key = `exerciseKey(day, exerciseIndex)` → alternative display name), cleared on start/reset. The plan is never mutated.
- The overridden name is used consistently wherever the session derives per-exercise data: card display + weight keys, `buildLiveWorkout` (watch + Live Activity render it), `buildSummary`, and `saveSessionToBackend` (history records what was actually performed). Weight prefill naturally follows the alternative's own history because weight keys include the exercise name.
- Known limitation (accepted): overrides are in-memory; after a process-death restore the app-side session falls back to plan names. Marked with a `ponytail:` comment.

## Testing

- Ranking function + override key semantics: DEBUG `runSelfCheck` asserts (repo pattern).
- UI items: build + simulator launch (self-checks run at init) + manual pass.
