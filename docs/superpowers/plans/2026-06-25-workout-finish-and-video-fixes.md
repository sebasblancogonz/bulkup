# Workout Finish & Video Fixes Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax.

**Goal:** Fix the per-set video picker (selection never attaches), and polish the finish-workout behavior (floating button stays over the summary; Live Activity keeps running; backend save fails silently).

**Architecture:** iOS app only, no backend changes. Three tasks: (1) video picker presentation fix; (2) finish-behavior polish (hide FAB on summary + Live Activity shows "completed" then auto-dismisses); (3) save-failure feedback + retry.

**Tech Stack:** SwiftUI, ActivityKit, PhotosUI.

## Global Constraints

- iOS app only. No backend changes, no new dependencies.
- ENV: this iOS project CANNOT be compiled/run in the agent environment (needs Xcode + signing + secrets). Verify by code-reading and hand-tracing; the user builds in Xcode. SourceKit cross-target "cannot find type" / "'main' attribute" errors are spurious noise — NOT findings.
- Self-checks (where logic warrants) follow the project pattern: a DEBUG `static func runSelfCheck()` wired into `bulkup/App/BulkUp.swift` init. Most of this work is UI/binding with no pure logic to assert → manual verification.
- Live Activity on finish: show "Entreno completado", then auto-dismiss after a few seconds (the widget already renders `state.isFinished` as "Entreno completado" at `BulkUpWidgetsLiveActivity.swift:64-67`).

---

## Task 1: Fix per-set video picker (selection never attaches)

**Root cause:** The `.photosPicker` `isPresented` is a *derived* binding (`get: { pendingVideoSet != nil && hasSeenVideoWarning }`, `set: { if !$0 { pendingVideoSet = nil } }`). A single-select picker auto-dismisses on tap → SwiftUI calls the setter → `pendingVideoSet = nil` — which races ahead of `.onChange(of: selectedVideoItem)`, whose `guard let setIndex = pendingVideoSet else { return }` then bails, so the video is never saved. Fix: present the picker with a dedicated `@State` bool; clear `pendingVideoSet` only after the save completes.

**Files:**
- Modify: `bulkup/Views/Components/Training/ExerciseCardView.swift` (state ~268-272, `.photosPicker` ~343-350, `.alert` "Entendido" ~366-368, `startVideoFlow` ~924-930)

**Interfaces:** none new.

- [ ] **Step 1: Add a dedicated presentation flag**

In `ExerciseWeightLogger`'s state block (near line 272, after `showVideoWarning`), add:

```swift
    @State private var showVideoPicker = false
```

- [ ] **Step 2: Drive the picker with the bool**

Replace the `.photosPicker(...)` modifier (the block starting around line 343):

```swift
        .photosPicker(
            isPresented: Binding(
                get: { pendingVideoSet != nil && hasSeenVideoWarning },
                set: { if !$0 { pendingVideoSet = nil } }
            ),
            selection: $selectedVideoItem,
            matching: .videos,
            photoLibrary: .shared()
        )
```

with:

```swift
        .photosPicker(
            isPresented: $showVideoPicker,
            selection: $selectedVideoItem,
            matching: .videos,
            photoLibrary: .shared()
        )
```

- [ ] **Step 3: Open the picker explicitly from `startVideoFlow`**

Replace `startVideoFlow` (around line 924):

```swift
    private func startVideoFlow(for setIndex: Int) {
        pendingVideoSet = setIndex
        if hasSeenVideoWarning {
            // PhotosPicker is presented via the .photosPicker modifier bound to pendingVideoSet.
        } else {
            showVideoWarning = true
        }
    }
```

with:

```swift
    private func startVideoFlow(for setIndex: Int) {
        pendingVideoSet = setIndex
        if hasSeenVideoWarning {
            showVideoPicker = true
        } else {
            showVideoWarning = true
        }
    }
```

- [ ] **Step 4: Open the picker after the warning is acknowledged**

In the `.alert("Vídeos en este dispositivo", ...)` block, replace the "Entendido" button:

```swift
            Button("Entendido") {
                hasSeenVideoWarning = true   // picker opens automatically (binding above)
            }
```

with:

```swift
            Button("Entendido") {
                hasSeenVideoWarning = true
                showVideoPicker = true
            }
```

Leave the `Button("Cancelar", role: .cancel) { pendingVideoSet = nil }` as-is. Leave the `.onChange(of: selectedVideoItem)` handler as-is — it already clears `selectedVideoItem`/`pendingVideoSet` after the save, and now `pendingVideoSet` survives until then because nothing else clears it.

- [ ] **Step 5: Verify (read-through; no build)**

Confirm: tapping a no-video set with the warning already seen sets `showVideoPicker = true` and `pendingVideoSet`; first-time shows the alert, and "Entendido" sets both; picking a video fires `onChange`, where `pendingVideoSet` is still set → save runs → `refreshVideoSets()` lights the icon. Picker auto-dismiss now just flips the plain bool. State this trace in the report.

- [ ] **Step 6: Commit**

```bash
git add bulkup/Views/Components/Training/ExerciseCardView.swift
git commit -m "fix(workout): attach picked per-set video (decouple picker presentation from pendingVideoSet)"
```

---

## Task 2: Finish behavior — hide FAB on summary + Live Activity "completed" then dismiss

**Root cause (FAB):** `finishWorkout()` sets `showSummary = true` but not `isActive = false`; the FAB (`MainAppView.swift:121`) is gated only on `isActive` and sits in the parent ZStack above the summary overlay (a `zIndex(100)` child of `TrainingView`), so it shows through. **Root cause (Live Activity):** it's only ended in `resetAll()` (on summary dismiss), so the Lock Screen keeps counting after finish.

**Files:**
- Modify: `bulkup/Views/MainAppView.swift:121`
- Modify: `bulkup/ViewModels/WorkoutActivityController.swift` (add `finish(state:)`)
- Modify: `bulkup/ViewModels/WorkoutSessionManager.swift` (`finishWorkout`, ~138-153)

**Interfaces:**
- Produces: `WorkoutActivityController.finish(state: WorkoutActivityAttributes.ContentState)`

- [ ] **Step 1: Hide the FAB while the summary is shown**

In `MainAppView.swift`, replace (line 121):

```swift
                    if workoutSession.isActive {
                        workoutFAB
                    }
```

with:

```swift
                    if workoutSession.isActive && !workoutSession.showSummary {
                        workoutFAB
                    }
```

- [ ] **Step 2: Add a `finish(state:)` method to the activity controller**

In `WorkoutActivityController.swift`, add after `update(_:)` (around line 42):

```swift
    /// Show a final "completed" state, then auto-dismiss the Live Activity after a
    /// few seconds. Used when the workout is finished (vs. `end()` which is immediate).
    func finish(state: WorkoutActivityAttributes.ContentState) {
        let content = ActivityContent(state: state, staleDate: nil)
        let dismissAt = Date().addingTimeInterval(4)
        if let activity {
            Task {
                await activity.update(content)
                await activity.end(content, dismissalPolicy: .after(dismissAt))
            }
            self.activity = nil
        } else {
            for stray in Activity<WorkoutActivityAttributes>.activities {
                Task { await stray.end(content, dismissalPolicy: .after(dismissAt)) }
            }
        }
    }
```

- [ ] **Step 3: Call it from `finishWorkout`**

In `WorkoutSessionManager.swift`, in `finishWorkout(trainingManager:)`, after `showSummary = true` (line 151) and before `return summary`:

```swift
        // The workout is done: show a final "completed" card on the Live Activity, then
        // let it auto-dismiss. (resetAll() still ends it immediately on summary dismiss.)
        if let live = SharedWorkoutStore.load() {
            var finished = WorkoutActivityController.contentState(from: live)
            finished.isFinished = true
            WorkoutActivityController.shared.finish(state: finished)
        }
        SharedWorkoutStore.save(nil)
```

(`resetAll()` keeps its existing `SharedWorkoutStore.save(nil)` + `WorkoutActivityController.shared.end()` for the discard path and as a safety net.)

- [ ] **Step 4: Verify (read-through; no build)**

Confirm: on finish, the FAB disappears (gated on `!showSummary`); the Live Activity updates to the finished state and ends with `.after(4s)`; `discardWorkout()` still ends immediately via `resetAll()`. Confirm `ContentState.isFinished` is a settable `var` and `contentState(from:)` is accessible. State this in the report.

- [ ] **Step 5: Commit**

```bash
git add bulkup/Views/MainAppView.swift bulkup/ViewModels/WorkoutActivityController.swift bulkup/ViewModels/WorkoutSessionManager.swift
git commit -m "fix(workout): hide FAB on summary; Live Activity shows completed then auto-dismisses on finish"
```

---

## Task 3: Save-failure feedback + retry

**Root cause:** `saveSessionToBackend` (`WorkoutSessionManager.swift:235-241`) fires a fire-and-forget `Task` that only `print`s on error — the user is never told a save failed and cannot retry.

**Files:**
- Modify: `bulkup/ViewModels/WorkoutSessionManager.swift` (save state + refactor `saveSessionToBackend` + `retrySave` + `resetAll`)
- Modify: `bulkup/Views/Components/Training/WorkoutSummaryView.swift` (state/retry UI)
- Modify: `bulkup/Views/TrainingView.swift:386` (pass save state + retry into the summary)

**Interfaces:**
- Produces: `WorkoutSessionManager.SaveState` (`enum { idle, saving, saved, failed }`), `@Published var saveState`, `func retrySave()`

- [ ] **Step 1: Add save state to the manager**

In `WorkoutSessionManager`, near the other `@Published` properties, add:

```swift
    enum SaveState: Equatable { case idle, saving, saved, failed }
    @Published var saveState: SaveState = .idle
    private var pendingSaveRequest: SaveWorkoutSessionRequest?
```

- [ ] **Step 2: Refactor `saveSessionToBackend` to track state**

In `saveSessionToBackend(...)`, replace the trailing `Task { ... }` block (currently lines ~235-241):

```swift
        Task {
            do {
                try await APIService.shared.saveWorkoutSession(request)
            } catch {
                print("Error saving workout session: \(error)")
            }
        }
```

with:

```swift
        pendingSaveRequest = request
        performSave()
```

Then add these two methods to the manager (right after `saveSessionToBackend`):

```swift
    private func performSave() {
        guard let request = pendingSaveRequest else { return }
        saveState = .saving
        Task { @MainActor in
            do {
                try await APIService.shared.saveWorkoutSession(request)
                saveState = .saved
                pendingSaveRequest = nil
            } catch {
                print("Error saving workout session: \(error)")
                saveState = .failed
            }
        }
    }

    /// Re-attempt the last failed backend save (uses the already-built request so
    /// it works even after session state has been cleared).
    func retrySave() {
        guard pendingSaveRequest != nil else { return }
        performSave()
    }
```

(If `WorkoutSessionManager` is not `@MainActor`-isolated, confirm `@Published` mutations happen on the main actor — the `Task { @MainActor in ... }` above ensures this. Verify the class's isolation before writing and keep the state writes on the main actor.)

- [ ] **Step 3: Reset save state in `resetAll`**

In `resetAll()`, add (alongside the other resets, e.g. after `summaryData = nil`):

```swift
        saveState = .idle
        pendingSaveRequest = nil
```

- [ ] **Step 4: Add a DEBUG self-check for the guard**

Add to `WorkoutSessionManager` (DEBUG; if a `runSelfCheck` already exists from prior work, ADD these asserts to it rather than duplicating):

```swift
    #if DEBUG
    @MainActor
    static func runSelfCheck() {
        let m = WorkoutSessionManager()
        assert(m.saveState == .idle, "save state starts idle")
        m.retrySave() // no pending request → no-op, stays idle
        assert(m.saveState == .idle, "retry with nothing pending is a no-op")
    }
    #endif
```

If a `WorkoutSessionManager.runSelfCheck()` already exists (it does — from the earlier delete-sets work), MERGE these asserts into it instead of adding a second method, and ensure it's still wired into `BulkUp.swift`'s DEBUG block.

- [ ] **Step 5: Show save state + retry in the summary**

In `WorkoutSummaryView.swift`, add two parameters to the struct (after `var onSave`):

```swift
    var saveState: WorkoutSessionManager.SaveState
    var onRetry: () -> Void
```

Then in the actions `VStack` (the block at lines 68-79), ABOVE the "Guardar y salir" button, add the status/retry UI:

```swift
                    if saveState == .saving {
                        Text("Guardando...")
                            .font(BulkUpFont.caption())
                            .foregroundColor(BulkUpColors.textSecondary)
                    } else if saveState == .failed {
                        VStack(spacing: Spacing.sm) {
                            HStack(spacing: Spacing.xs) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                Text("No se pudo guardar tu entreno")
                            }
                            .font(BulkUpFont.caption())
                            .foregroundColor(BulkUpColors.warning)

                            Button {
                                onRetry()
                            } label: {
                                HStack(spacing: Spacing.sm) {
                                    Image(systemName: "arrow.clockwise")
                                    Text("Reintentar")
                                        .fontWeight(.semibold)
                                }
                                .primaryButtonStyle(color: BulkUpColors.warning)
                            }
                        }
                    }
```

(Match the existing button styling helper `.primaryButtonStyle(color:)` already used at line 77. If that helper isn't suitable for a secondary action, use the same style as the "Guardar y salir" button with `BulkUpColors.warning`.)

- [ ] **Step 6: Pass save state + retry from TrainingView**

In `TrainingView.swift`, at the `WorkoutSummaryView(summary: summary) { ... }` call (line 386), add the new arguments. Change:

```swift
                WorkoutSummaryView(summary: summary) {
                    // Save and mark complete
                    markWorkoutComplete()
                    let finishedDay = currentTrainingDay ?? selectedDay
                    workoutSession.saveAndDismissSummary()
                    // Prompt for post-workout sensations
                    feedbackDayName = finishedDay
                    showFeedback = true
                }
```

to:

```swift
                WorkoutSummaryView(
                    summary: summary,
                    saveState: workoutSession.saveState,
                    onRetry: { workoutSession.retrySave() }
                ) {
                    // Save and mark complete
                    markWorkoutComplete()
                    let finishedDay = currentTrainingDay ?? selectedDay
                    workoutSession.saveAndDismissSummary()
                    // Prompt for post-workout sensations
                    feedbackDayName = finishedDay
                    showFeedback = true
                }
```

(`WorkoutSummaryView`'s trailing closure remains its `onSave`. Confirm the parameter order matches the struct: `summary`, `saveState`, `onRetry`, then the trailing `onSave` closure.)

- [ ] **Step 7: Verify (read-through; hand-trace the self-check)**

Confirm: a failed save sets `saveState = .failed` (visible in the summary as the error + Reintentar); `retrySave()` re-runs with the stored `pendingSaveRequest` even after `resetAll` would have cleared session state (retry is only reachable while the summary is up, before dismiss); `resetAll` returns state to `.idle`. Hand-trace the self-check asserts. State this in the report.

- [ ] **Step 8: Commit**

```bash
git add bulkup/ViewModels/WorkoutSessionManager.swift bulkup/Views/Components/Training/WorkoutSummaryView.swift bulkup/Views/TrainingView.swift bulkup/App/BulkUp.swift
git commit -m "feat(workout): surface backend save failures with a retry on the summary"
```

---

## Self-Review

**Spec coverage:** video-attach bug → Task 1; FAB-on-summary → Task 2 Step 1; Live Activity keeps running → Task 2 Steps 2-3; save fails silently → Task 3. All requested items covered.

**Placeholder scan:** No TBD/TODO. The "(confirm X before writing)" notes (manager actor isolation, button-style helper, existing runSelfCheck) are verification instructions; the common-case code is fully specified.

**Type consistency:** `SaveState` / `saveState` / `retrySave` / `pendingSaveRequest` used consistently across Tasks 3's manager, view, and TrainingView wiring. `WorkoutActivityController.finish(state:)` signature matches its caller in `finishWorkout`. `showVideoPicker` introduced and referenced consistently in Task 1.
