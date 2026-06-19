# Interactive Workout Live Activity (Lock Screen) — Design

**Date:** 2026-06-19
**Status:** Approved (design), pending implementation plan

## Goal

While a workout is in progress, show a **Lock Screen Live Activity** that displays
live status (elapsed time, current exercise, set progress, rest countdown) and
lets the user **drive the workout from the Lock Screen** via buttons: complete the
current set, adjust weight ±, adjust reps ±, and control rest (skip / +30s).

## Scope

**In scope:**
- An ActivityKit Live Activity tied to the existing in-app workout session
  (`WorkoutSessionManager`). Auto-starts when a workout starts; ends on
  finish/discard.
- Lock Screen presentation with interactive buttons (App Intents).
- A **minimal** Dynamic Island presentation (required by the ActivityKit API) —
  compact timer + progress, no full interactive expanded layout.
- A new **Widget Extension** target + **App Group** shared container.
- **V2 state model:** the App Group store is the single source of truth for the
  live session; `WorkoutSessionManager` and the live weight/rep fields of
  `TrainingManager` are refactored to read/write through it.
- Reconciliation of Lock-Screen-driven mutations back into SwiftData /
  `TrainingManager.weights` / backend sync.

**Out of scope:**
- Full Dynamic Island interactive/expanded experience.
- Free-text weight/rep entry on the Lock Screen (not supported by iOS — steppers
  only).
- Home Screen (WidgetKit) widgets.
- Changing the in-app workout UX beyond what V2 requires.

## Platform notes

- Deployment target iOS 26 → Live Activities (16.1+) and interactive App Intent
  buttons (17+) are fully available.
- Elapsed and rest timers render with `Text(timerInterval:)` so they self-tick on
  the Lock Screen without per-second pushes (respects ActivityKit update rate
  limits).
- `LiveActivityIntent` runs in the app process when the app is alive, otherwise in
  the widget extension process — hence the App Group must be the source of truth.

## Architecture & Components

### New targets / entitlements
- **Widget Extension target** `BulkUpWidgets`.
- **App Group** `group.com.whitesolutions.bulkup` entitlement added to BOTH the
  app and the widget extension.

### Shared module (member of both app + widget targets)
- `WorkoutActivityAttributes: ActivityAttributes` with a nested `ContentState`
  struct carrying the renderable live state (below).
- `SharedWorkoutStore` — the single source of truth, backed by App-Group storage
  (`UserDefaults(suiteName:)` for small scalar state; a JSON file in the shared
  container if it grows). Exposes typed read/write for the live-session fields and
  a change-notification mechanism (Darwin notification via `CFNotificationCenter`)
  so the app reconciles immediately when running.
- `LiveActivityIntent` button intents: `CompleteCurrentSetIntent`,
  `AdjustWeightIntent(delta:)`, `AdjustRepsIntent(delta:)`, `SkipRestIntent`,
  `AddRestIntent(seconds:)`. Each mutates `SharedWorkoutStore`, then requests an
  `Activity.update(...)`.

### Live session state (source of truth; mirrored into `ContentState`)
- `workoutName`, `dayName`
- `startDate` (drives elapsed `Text(timerInterval:)`), `isPaused`
- **current-set cursor:** `exerciseIndex`, `exerciseName`, `setIndex`, `setsTotal`
- current set's working `weight`, `reps`
- progress: `completedSets`, `totalSets`, `exercisesDone`, `exercisesTotal`
- rest: `isResting`, `restEndDate`, `restTotalSeconds`
- `units` (kg/lb), `weightStep` (2.5 kg default), `repStep` (1 default)

### App-side refactor (V2)
- `WorkoutSessionManager`’s live-session fields (active flag, cursor, completed
  sets, rest state, elapsed start) become a **view over `SharedWorkoutStore`**
  rather than independent `@Published` truth; the manager publishes by observing
  the store.
- The **live working weight/reps** for the current set route through
  `SharedWorkoutStore`; on set completion they are drained into
  `TrainingManager.weights` (the existing per-set weight model) and persisted/
  synced exactly as the in-app `completeSet` + `saveWeightsToDatabase` flow does.
- A new **current-set cursor** = first incomplete `(exerciseIndex, setIndex)` in
  order for the active day; recomputed as sets complete. (The app currently lets
  any set be checked in any order with no "current" notion — this adds it.)

## Data Flow

1. App `startWorkout` → seed `SharedWorkoutStore` (cursor at first set, progress,
   units/steps) → `Activity.request(attributes:content:)`.
2. Lock Screen button tap → `LiveActivityIntent` → mutate `SharedWorkoutStore`:
   - **Complete set:** mark current set done (weight/reps from store), advance
     cursor, start rest (`restEndDate = now + exercise.restSeconds`), recompute
     progress.
   - **Weight/Reps ±:** adjust the current set’s working value by the step.
   - **Skip rest / +30s:** clear or extend `restEndDate`.
   Then `Activity.update(content:)` and post a Darwin notification.
3. In-app actions (complete set, weight entry, rest controls) go through the SAME
   `SharedWorkoutStore`, so app and activity never diverge.
4. App reconciliation: on Darwin notification (app alive) or on next foreground,
   the app drains store mutations into `TrainingManager.weights` +
   `WorkoutSessionManager.completedSetIds`, persists to SwiftData, and triggers
   backend weight sync — the bridge from live shared state to durable records.
5. Finish/discard → `activity.end(...)`, clear the store.

## Lock Screen Layout (context-aware)

- **During a set:** exercise name + "Set X/Y"; weight stepper `− 2.5 +`; reps
  stepper `− 1 +`; **Complete set** button; thin overall-progress bar; elapsed time.
- **During rest:** large rest countdown (`Text(timerInterval:)`); **Skip** and
  **+30s** buttons; "next: <exercise> · set N".
- **All sets done:** "Workout complete" with a tap-to-open-app affordance to
  finish/save.
- **Dynamic Island (minimal):** compact leading = elapsed; trailing = "X/Y sets";
  minimal = progress glyph.

## Error Handling / Edge Cases

- Live Activities disabled by user (`ActivityAuthorizationInfo().areActivitiesEnabled
  == false`) → skip starting the activity; app works normally.
- ActivityKit update rate limits → update only on discrete events; never per
  second (timers self-tick).
- App killed by iOS mid-workout → App Group persists; the extension-process
  intents still mutate the store + update the activity; the app reconciles on next
  launch.
- Orphaned activity (app crashed without ending) → on launch, end any stale
  workout activities and clear the store if no session is active.
- Cursor past last set → "workout complete" state; buttons no-op except finish.
- Imperial units → weight step adapts (e.g., 5 lb); reps step stays 1.

## Testing

No XCTest target exists. Therefore:
- `SharedWorkoutStore` pure logic (cursor advancement, weight/rep stepping,
  progress counts, rest start/skip math) gets a `#if DEBUG` assert-based
  self-check invoked at launch.
- Manual: start a workout, lock the phone, exercise every button, confirm the
  activity reflects state and the app reconciles weights/sets + persists on
  return; verify finish/discard ends the activity; verify behavior with Live
  Activities permission off.

## Phasing (informs the implementation plan)

1. **Scaffold + read-only activity:** add the Widget Extension target + App Group;
   `WorkoutActivityAttributes`/`ContentState`; start/end the activity from
   `startWorkout`/finish; Lock Screen view showing elapsed + current exercise +
   set progress + rest countdown (no buttons yet). Verify it appears and ticks.
2. **`SharedWorkoutStore` as source of truth + reconciliation:** introduce the
   App Group store; refactor `WorkoutSessionManager` live fields + the current-set
   cursor onto it; wire in-app actions through it; implement reconciliation into
   `TrainingManager.weights`/SwiftData/sync. Verify in-app workout still works
   end-to-end (regression-critical).
3. **Interactive buttons:** add the `LiveActivityIntent`s and the context-aware
   button layout (complete set, weight/reps ±, skip/+30s rest); verify driving the
   workout from the Lock Screen and reconciliation.

## Risks

- **Touches the weight-tracking core.** The V2 refactor routes live weight/rep
  state through shared storage and reconciles into `TrainingManager.weights`,
  which has had day-key normalization bugs before. Phase 2 must be verified
  against the existing in-app flow before Phase 3. Regression risk is the main
  hazard.
- **Cross-process correctness.** Intent-in-extension vs intent-in-app, Darwin
  notification timing, and reconciliation ordering are subtle; the store must be
  the unambiguous source of truth to avoid divergence.
- **Largest single feature in the app to date** — multi-PR; each phase ships
  independently buildable and verifiable.
