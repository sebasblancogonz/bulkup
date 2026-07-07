# Workout-flow tweaks (B/C/D) — Design

**Date:** 2026-06-28
**Scope:** Three small, independent improvements to the existing workout/exercise flow. iOS-only, no backend change. Each reuses systems that already exist.

- **B** — exercises without weight tracking can be **marked completed** (today they can only be skipped).
- **C** — **sensation logging becomes on-demand** (pull) instead of an auto-prompt after every workout (push).
- **D** — recorded **set videos are viewable outside an active workout**.

---

## B — Complete non-weight exercises

**Today:** in `ExerciseCardView`, an exercise with `weightTracking == false` renders "Sin seguimiento de peso" and shows **no per-set completion control** — it can only be removed via the context-menu "Omitir ejercicio". So bodyweight / stretch / cardio work can't be marked *done*; it only counts if skipped, which is the opposite meaning.

**Change:** for `weightTracking == false`, render the **same per-set completion checkmark** the weight-tracking branch uses (the one that calls `WorkoutSessionManager.completeSet(day, exerciseIndex, setIndex, restSeconds)` → `completedSetIds`), just **without the weight fields**. The set rows show `Serie i` + the rest timer + the complete button.
- Completion uses the existing `completedSetIds` mechanism, so these sets immediately count in the workout summary and the Progreso "Workouts" ring (which counts completed sets).
- Keep "Omitir ejercicio" available (skip ≠ complete).
- Optional nicety: a single "Marcar ejercicio completado" that completes all its sets at once, in addition to per-set. (Per-set is the primary; the bulk action is a small add.)

**Non-goals:** no new data model; no backend (completion is session-local + already mirrored to `SharedWorkoutStore`).

## C — Sensation logging on-demand

**Today:** finishing a workout in `TrainingView` sets `showFeedback = true`, which **auto-presents** `WorkoutFeedbackView` (the emoji rating + tags + note + photos sheet). It's dismissible (not mandatory), but it's *pushed* at the user every time.

**Change:** make it **pull, not push**.
- Remove the automatic `showFeedback = true` after finish.
- Add an explicit entry point — a **"Registrar sensaciones" button** — where it's discoverable on-demand: in the post-workout summary and/or on the day card (a finished day shows "Cómo te sentiste" / an emoji affordance). Tapping it opens the same `WorkoutFeedbackView`.
- If feedback already exists for that day, the entry point shows the saved rating (and tapping edits it).
- Everything else (`WorkoutFeedback` model, `WorkoutFeedbackManager`, the sheet UI, local persistence per `(planId, day)`) is unchanged.

**Non-goals:** no in-set RPE, no backend sync, no analytics view (those were noted as future in the exploration).

## D — View set videos outside an active workout

**Today:** users record one video per set during an active workout; the video button + `AVPlayer` sheet in `ExerciseCardView` are only wired in **workout mode**. Videos persist in `WorkoutVideoStore`, keyed by `videoKey(setIndex)` (which is `generateWeightKey(...)`), so they survive after the workout — but there's no way to *view* them outside a live session.

**Change:** surface the recorded videos in **browse mode** too.
- In `ExerciseCardView` when NOT in an active workout (plan-browsing), for each set that **has a saved video** (`WorkoutVideoStore` has an entry for that `videoKey`), show the ▶ `video.fill` button → open the **same** `AVPlayer` player sheet (reuse the existing player + replace/delete toolbar).
- Also expose them from the new **`ExerciseProgressView`** (feature A) if convenient — a small "tus vídeos" row per logged week — but the primary surface is the exercise card in browse mode.
- Recording stays workout-only (you record while training); browse mode is **playback-only** (and replace/delete, which already exist).

**Non-goals:** no instructional/coach videos (the Exercise model has no such field); no cloud upload (videos stay on-device in `WorkoutVideoStore`).

---

## Cross-cutting

- **No backend.** All three are iOS-only and reuse existing managers/stores (`WorkoutSessionManager`, `WorkoutFeedbackManager`, `WorkoutVideoStore`).
- **Testing:** mostly UI wiring (low pure-logic surface). Where a pure helper changes (e.g., a "set has a video" lookup or "all sets complete" for the bulk-complete action), add/extend a DEBUG `runSelfCheck()`. iOS not buildable here → code review + user builds in Xcode.
- **One PR** (iOS), independent of feature A. Can land before or after A; D optionally references A's view but doesn't depend on it (the primary D surface is the exercise card).

## Spec self-review note
B/C/D are intentionally small and decoupled; each could be its own commit/task within the single iOS PR.
