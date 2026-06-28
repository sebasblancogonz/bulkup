# Workout-flow tweaks (B/C/D) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development. Steps use checkbox (`- [ ]`) syntax. **iOS-only**, one PR, independent of feature A. NOT buildable here → code review + (where logic exists) DEBUG `runSelfCheck()`; user builds in Xcode.

**Goal:** Three small workout-flow improvements: (C) sensation logging becomes on-demand instead of auto-prompted; (B) exercises without weight tracking can be marked completed; (D) recorded set videos are viewable outside an active workout.

**Architecture:** Each reuses an existing system (the set-completion control, the `WorkoutFeedbackView` + `WorkoutFeedbackManager`, the `AVPlayer` sheet + `WorkoutVideoStore`). No backend, no new data model.

**Tech Stack:** SwiftUI; existing managers/stores.

## Global Constraints
- `bulkup` repo, branch `feat/workout-flow-tweaks` (base `main` `99a3b43`), independent of feature A.
- ENV: iOS not buildable here. SourceKit "cannot find type/Manager" cross-file errors are spurious.
- Reuse, don't reinvent: completion via `WorkoutSessionManager.completeSet/uncompleteSet/isSetCompleted`; feedback via `WorkoutFeedbackManager` + `WorkoutFeedbackView`; videos via `WorkoutVideoStore.url(for:)/hasVideo(for:)` + the existing player sheet.
- Active-workout vs browse is `ExerciseCardView.isWorkoutMode` (`= workoutSession.isActive`).

---

## Task 1: [C] Sensations on-demand (remove the auto-prompt)

**Files:**
- Modify: `bulkup/Views/TrainingView.swift` (remove the auto-trigger ~lines 393–398; make the completed-pill a clear on-demand entry ~lines 444–478)

**Interfaces:**
- Consumes (existing): `WorkoutFeedbackManager.shared.feedback(planId:dayName:) -> WorkoutFeedback?`; `WorkoutFeedbackManager.emoji(for:)`; the `@State showFeedback`, `feedbackDayName`, and the `.sheet(isPresented: $showFeedback) { WorkoutFeedbackView(...) }` (~line 403).

- [ ] **Step 1: Stop auto-presenting feedback after finish** — in `TrainingView.swift`, in the `WorkoutSummaryView` finish closure (currently ~lines 393–398):
```swift
{
    markWorkoutComplete()
    let finishedDay = currentTrainingDay ?? selectedDay
    workoutSession.saveAndDismissSummary()
    // Prompt for post-workout sensations   ← REMOVE these two lines:
    feedbackDayName = finishedDay
    showFeedback = true
}
```
Delete the two lines `feedbackDayName = finishedDay` and `showFeedback = true` (keep `markWorkoutComplete()` + `saveAndDismissSummary()`). `finishedDay` may become unused — if the compiler warns, replace `let finishedDay = …` usage or remove it. Read the closure and keep it compiling.

- [ ] **Step 2: Make the completed-pill an explicit on-demand "Registrar sensaciones" affordance** — the `completedPill` (~lines 444–478) already looks up the saved emoji via `WorkoutFeedbackManager.shared.feedback(planId:dayName:)` and on tap sets `showFeedback = true`. Make it self-evidently a sensations entry: if no feedback exists yet, show a labeled button ("Registrar sensaciones" + `heart.fill`); if feedback exists, show the saved emoji + "Editar". Keep the tap action:
```swift
            Button {
                feedbackDayName = day
                showFeedback = true
            } label: {
                if let saved = WorkoutFeedbackManager.shared.feedback(planId: trainingManager.trainingPlanId, dayName: day),
                   let emoji = WorkoutFeedbackManager.emoji(for: saved.rating) {
                    Label(emoji, systemImage: "pencil")   // saved → show it + edit
                } else {
                    Label("Registrar sensaciones", systemImage: "heart.fill")
                }
            }
```
(Adapt to the real `completedPill` markup/styling — read it; keep the existing layout/colors. The point: it's now a discoverable on-demand entry, and the post-finish auto-sheet is gone.)

- [ ] **Step 3: Verify** — read-through: the finish flow no longer auto-opens the feedback sheet; the completed-pill is the on-demand entry (shows saved rating when present, a clear label when not); `WorkoutFeedbackView` + the sheet binding are otherwise unchanged. User builds. State this in the report.

- [ ] **Step 4: Commit**
```bash
git add bulkup/Views/TrainingView.swift
git commit -m "feat(training): sensations are on-demand, not auto-prompted after finish"
```

---

## Task 2: [B] Complete non-weight exercises

**Files:**
- Modify: `bulkup/Views/Components/Training/ExerciseCardView.swift` (the `weightTracking == false` branch ~lines 329–333; reuse the check button ~lines 618–645)

**Interfaces:**
- Consumes (existing): `ExerciseCardView.isWorkoutMode` (~294); `workoutSession.isSetCompleted(day:exerciseIndex:setIndex:)` (~547); `completeSetAndSave(setIndex:)` (~805) + `workoutSession.uncompleteSet(day:exerciseIndex:setIndex:)`; `normalizedDay`; `exercise.orderIndex`, `exercise.sets`.

- [ ] **Step 1: Render per-set completion rows for non-weight exercises in workout mode** — replace the static stub (~lines 329–333):
```swift
} else {
    Text("Sin seguimiento de peso")
        .font(BulkUpFont.caption())
        .foregroundColor(BulkUpColors.textTertiary)
}
```
with: when `isWorkoutMode`, a list of the exercise's sets each showing `Serie i` + a completion check (reusing the SAME check button used in `workoutSetRow`, ~lines 618–645 — extract that button into a small `completeButton(setIndex:)` helper if it isn't already, and call it from both places to stay DRY); when NOT in workout mode, keep the "Sin seguimiento de peso" caption.
```swift
} else if isWorkoutMode {
    VStack(spacing: 8) {
        ForEach(0..<exercise.sets, id: \.self) { setIndex in
            HStack {
                Text("Serie \(setIndex + 1)").font(BulkUpFont.body())
                Spacer()
                completeButton(setIndex: setIndex)   // reused from workoutSetRow
            }
        }
    }
} else {
    Text("Sin seguimiento de peso")
        .font(BulkUpFont.caption())
        .foregroundColor(BulkUpColors.textTertiary)
}
```
Read the real structure (the branch lives inside `ExerciseWeightLogger`/the weightTracking check ~line 323). The `completeButton(setIndex:)` helper wraps the existing check-button logic: `isSetCompleted(...)` → on tap `uncompleteSet(...)` else `completeSetAndSave(setIndex:)`. Reuse it in `workoutSetRow` too (don't duplicate the button body).

- [ ] **Step 2: Verify** — read-through: a non-weight exercise in an active workout shows a completion check per set; tapping it toggles `completedSetIds` (so it counts in the summary + the Progreso "Workouts" ring); outside a workout it still shows the caption; the check button is shared (DRY) with `workoutSetRow`. User builds + manually completes a bodyweight set. State this in the report.

- [ ] **Step 3: Commit**
```bash
git add "bulkup/Views/Components/Training/ExerciseCardView.swift"
git commit -m "feat(training): non-weight exercises can be marked complete per set"
```

---

## Task 3: [D] View set videos outside an active workout

**Files:**
- Modify: `bulkup/Views/Components/Training/ExerciseCardView.swift` (`normalModeContent` ~lines 670–789; reuse the player sheet ~lines 373–397)

**Interfaces:**
- Consumes (existing): `WorkoutVideoStore.hasVideo(for:) -> Bool` (~49), `WorkoutVideoStore.url(for:) -> URL?` (~43); `videoKey(_ setIndex:) -> String` (~912); `@State playerSet: Int?` (~270) + the player `.sheet` (~373–397) which is already at view scope (NOT gated to workout mode).

- [ ] **Step 1: Surface a play button in browse mode for sets that have a recorded video** — in `normalModeContent`, inside the per-set loop (`ForEach(0..<exercise.sets …)` ~line 686), add a play button shown only when a video exists:
```swift
            if WorkoutVideoStore.hasVideo(for: videoKey(setIndex)) {
                Button { playerSet = setIndex } label: {
                    Image(systemName: "play.circle.fill")
                        .font(.system(size: 18))
                        .foregroundColor(BulkUpColors.accent)
                }
                .accessibilityLabel("Ver vídeo de la serie \(setIndex + 1)")
            }
```
Setting `playerSet = setIndex` triggers the EXISTING player sheet (~lines 373–397), which loads `WorkoutVideoStore.url(for: videoKey(setIndex))` and shows `SetVideoPlayerView` with play (+ the existing delete; replace records a new clip via `startVideoFlow`, which works outside a workout too). No new player code.
Read `normalModeContent`'s set loop to place the button in the row layout cleanly (it may not currently iterate sets with an index — if it doesn't, add a lightweight per-set row or a small "vídeos" strip listing only sets that have a video, to avoid restructuring the whole browse layout).

- [ ] **Step 2: Verify** — read-through: outside an active workout, a set that has a saved video shows a play button → tapping opens the existing `SetVideoPlayerView`; sets without a video show nothing extra; the workout-mode video button (record/play) is unchanged. User builds + opens a past exercise's video without starting a workout. State this in the report.

- [ ] **Step 3: Commit**
```bash
git add "bulkup/Views/Components/Training/ExerciseCardView.swift"
git commit -m "feat(training): play recorded set videos outside an active workout"
```

---

## Self-Review
**Spec coverage:** C — remove auto-prompt + on-demand entry (Task 1); B — non-weight per-set completion reusing the check button (Task 2); D — browse-mode video playback reusing the player sheet (Task 3). All three reuse existing systems; no backend, no new model — matches the spec.

**Placeholder scan:** No TBD/TODO. The "read the real structure / adapt to the layout" notes are genuine integration instructions for an intricate 1100-line view (`ExerciseCardView`), with the exact reused symbols + insertion lines named — not vague placeholders. No new pure-logic helper warrants a `runSelfCheck` (all three are UI wiring over existing, already-tested managers); the plan says so explicitly.

**Type consistency:** `isWorkoutMode`, `isSetCompleted(day:exerciseIndex:setIndex:)`, `completeSetAndSave(setIndex:)`, `uncompleteSet(day:exerciseIndex:setIndex:)`, `WorkoutVideoStore.hasVideo(for:)/url(for:)`, `videoKey(_:)`, `playerSet`, `WorkoutFeedbackManager.shared.feedback(planId:dayName:)`/`emoji(for:)` are all the real signatures from the code map. Task 2's `completeButton(setIndex:)` is a new shared helper introduced + reused within the same task.
