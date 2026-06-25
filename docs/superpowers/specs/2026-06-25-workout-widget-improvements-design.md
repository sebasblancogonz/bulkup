# Workout & Widget Improvements — Design

**Date:** 2026-06-25
**Scope:** iOS app only. No backend changes. Music control is explicitly **out of scope**.

Five changes, all in the active-workout / Live Activity area. Two bug fixes, one
cosmetic tweak, two features.

---

## 1. Sets input always shows "12" *(bug)*

### Problem
During a workout, every set's reps input field initializes to a single value,
ignoring per-set rep targets. An exercise with `reps = "10, 8, 6"` shows three
correct pills in the description (`setRepsPills`, `ExerciseCardView.swift:213-244`)
but all three input fields read `10`.

### Root cause
`ExerciseCardView.swift:813`:
```swift
repsTexts = (0..<setsCount).map { _ in defaultReps }
```
`defaultReps` (`:292-299`) only extracts the *first* comma component, so every set
gets the same value.

### Fix
In `loadInitialData()`, build `repsTexts` per-set by splitting `exercise.reps` on
`,`, reusing the same splitting logic `setRepsPills` already uses (`:215-217`):
- Set *i* gets the *i*-th comma component.
- A range (`"8-12"`) keeps the current **upper-bound** default (no behavior change).
- A single value (`"12"`) → all sets show `12`.
- If there are fewer components than sets, remaining sets fall back to `defaultReps`.

Single file, single function. Extract the per-set parsing into a small helper so it
can be unit-checked.

### Verification
`assert`-based `demo()` self-check: `"10, 8, 6"` → `["10","8","6"]`;
`"8-12"` → `["12","12",...]`; `"12"` → `["12","12",...]`; short list falls back.

---

## 2. Widget → lime accent + more padding *(cosmetic)*

### Problem
The Lock Screen widget hardcodes teal `#00E6C3`; the brand accent is now lime
`#84CC16`. Content sits too close to the widget edges (`.padding(14)`).

### Fix
`BulkUpWidgetsLiveActivity.swift`:
- Line 9: `WidgetTheme.accent` → `Color(red: 0.518, green: 0.800, blue: 0.086)` with a
  `// #84CC16 LIME` comment (mirrors `DesignSystem.swift:78`; the widget target can't
  import the app's `DesignSystem`).
- Line 25: `.padding(14)` → `.padding(20)`.

Other `WidgetTheme` colors (background `#0A0A0A`, surface `#161616`, textSecondary
`#8E8E93`, onAccent black) are neutral darks and stay as-is — only the accent was
off-brand.

### Verification
Manual: run the Live Activity, confirm lime accent and the larger inset.

---

## 3. Widget shows wrong/random exercise at start *(bug)*

### Problem
When a workout starts, the Live Activity sometimes shows the wrong exercise —
"a veces el último". Reported as inconsistent across plans/sessions.

### Root cause
`startWorkout()` (`WorkoutSessionManager.swift:63-95`) calls
`prePopulateFromWeights()` (`:98-121`), which marks a set completed if a weight is
already saved for the selected week. `buildLiveWorkout()` (`:719-775`) then sets
`cursor = 0` and calls `advanceCursor()` (`SharedWorkoutStore.swift:33-37`), which
skips all leading completed sets. So on a fresh "Empezar entreno", any set with a
historically-logged weight is pre-marked done and the cursor jumps forward to the
first never-logged set — which varies by history and often lands on a late/last
exercise. The build itself is deterministic (exercises iterated in array order); the
apparent randomness comes entirely from which weights happen to exist.

### Fix
On a fresh workout start, the Live Activity must begin at the **first set of the
first exercise** (cursor 0), not the first historically-incomplete set. Concretely:
in `buildLiveWorkout()` (or at the `startWorkout` seed point), do **not** call
`advanceCursor()` at fresh-start time — seed `cursor = 0`. The in-app checkmark
pre-population (`completedSetIds`) is untouched; only the Live Activity's starting
cursor changes.

Trade-off accepted by the user: resuming a half-logged workout will now start the
widget at set 1 rather than jumping to where you left off.

Process: add three diagnostic logs first (completedSetIds after pre-populate; each
`LiveSet` as appended; cursor + `w.current?.exerciseName` before
`WorkoutActivityController.start()`), confirm the cursor value on a real start, apply
the fix, and verify the log shows exercise 1. Remove the logs before committing.

### Verification
Extend `SharedWorkoutStore.runSelfCheck` (`:88-110`): with some sets pre-marked
completed, a freshly-built workout's `current` is the first set of the first
exercise.

---

## 4. Delete sets *(feature)*

### Problem
Sets can be added during a workout (`addSet`, `WorkoutSessionManager.swift:542`) but
never deleted. There is no delete path anywhere.

### Design
Workout-mode only (plan editing untouched). Delete is allowed for **added sets
only** — planned sets (`setIndex < exercise.sets`) are not deletable.

- New `WorkoutSessionManager.deleteSet(day:exerciseIndex:)` mirroring `addSet`:
  decrement `addedSets[key]` (floored at 0) and clear that set's local state for the
  removed index — `weights[setKey]`, `actualReps`, completed/failed flags. If a
  middle added set is removed, re-index the trailing added sets' state so there are
  no gaps (or, simpler: only allow deleting the *last* added set — decide in plan;
  default to last-only for laziness if re-indexing proves fiddly).
- UI: `.swipeActions` on `workoutSetRow` (`ExerciseCardView.swift:400`), shown only
  when `setIndex >= exercise.sets`. A destructive "Eliminar" swipe.

**ponytail:** any weight already saved to the server for a deleted extra set is left
orphaned — it never renders again (the set no longer exists in the UI). Add server
cleanup only if it actually causes a problem.

### Verification
Manual: add 2 sets, swipe-delete one, confirm count drops and the planned sets and
their data are untouched. `deleteSet` floor-at-0 covered by an assert.

---

## 5. Per-set videos, stored locally *(feature)*

### Problem
Users want to attach a video to a specific set for form review. Videos must be
stored on-device only, and the user must be told.

### Design
Reuse the existing `WorkoutPhotoStore` pattern (`bulkup/Utils/WorkoutPhotoStore.swift`).

- New `WorkoutVideoStore` (`bulkup/Utils/WorkoutVideoStore.swift`): saves a picked
  video file into `Documents/WorkoutVideos/<uuid>.mov` and exposes
  `save → filename`, `load(filename) → URL`, `delete(filename)`. Plus a persisted
  `[setKey: filename]` index (JSON file in Documents) so a video survives app
  restarts and is tied to the exact set.
- Set key reuses `TrainingManager.generateWeightKey(..., setIndex:, weekStart:)` —
  the same scheme weights use, so a video is bound to day + exercise + set + week.
- UI: a small video button in `workoutSetRow`. No video → `video.badge.plus` icon
  opens a `PhotosPicker` filtered to `.videos`, one video per set. Video exists →
  filled icon; tapping opens an AVKit `VideoPlayer` sheet with **Replace** and
  **Delete** actions.
- Warning: the first time a user attaches any video, show an alert —
  *"Los vídeos se guardan solo en este dispositivo y no se suben a la nube."*
  Persist a `hasSeenVideoStorageWarning` flag in `UserDefaults` so it shows once.

No camera capture (gallery only) → no `NSCameraUsageDescription` needed; PhotosPicker
needs no photo-library permission.

### Verification
Manual: attach a video to a set, kill and relaunch the app, confirm the video is
still associated and plays; delete it and confirm the file is removed. The
`[setKey: filename]` index round-trip covered by an assert.

---

## Out of scope

- **Music control.** No audio code exists today. Controlling the system/Apple Music
  player is feasible but deferred; controlling Spotify needs their SDK + OAuth (large
  lift). Revisit as a separate spec if wanted.

## Files touched

- `bulkup/Views/Components/Training/ExerciseCardView.swift` — items 1, 4, 5
- `bulkup/ViewModels/WorkoutSessionManager.swift` — items 3, 4
- `bulkup/Shared/SharedWorkoutStore.swift` — item 3 (self-check)
- `BulkUpWidgets/BulkUpWidgetsLiveActivity.swift` — item 2
- `bulkup/Utils/WorkoutVideoStore.swift` — item 5 (new)
