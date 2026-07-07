# Workout & Widget Improvements Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Fix two active-workout bugs, re-skin the Live Activity widget, and add delete-set + per-set local video features — iOS only.

**Architecture:** All changes live in the existing training/workout files. Pure logic gets `assert`-based `runSelfCheck()` statics wired into `BulkUp.swift`'s DEBUG block (the project's test convention — there is no XCTest target). UI changes are verified by building and running on a simulator.

**Tech Stack:** SwiftUI, ActivityKit (Live Activity), PhotosUI (`PhotosPicker`), AVKit (`VideoPlayer`), `FileManager` (local Documents storage).

## Global Constraints

- No backend changes. iOS app + widget targets only.
- No new third-party dependencies.
- Music control is OUT OF SCOPE.
- Lime brand accent is `#84CC16` = `Color(red: 0.518, green: 0.800, blue: 0.086)` (`DesignSystem.swift:78`). The widget target cannot import `DesignSystem`; mirror the literal.
- Self-checks follow the project pattern: a `static func runSelfCheck()` (DEBUG) invoked from `BulkUp.swift` init (`bulkup/App/BulkUp.swift:16-25`).
- Per-set persistence keys reuse `TrainingManager.generateWeightKey(day:exerciseIndex:exerciseName:setIndex:weekStart:)`.
- Build/verify command (no scheme automation exists): build and run the app on an iOS simulator in Xcode (⌘R). DEBUG self-checks run at launch — **no assertion crash = pass**. UI steps are verified by interacting with the running app.

---

## Task 1: Per-set reps input bug

The reps input field fills every set with one value. Parse per-set targets instead.

**Files:**
- Modify: `bulkup/Views/Components/Training/ExerciseCardView.swift` (add helper + self-check to `ExerciseWeightLogger`; change line 813)
- Modify: `bulkup/App/BulkUp.swift:16-25` (wire self-check)

**Interfaces:**
- Produces: `static func ExerciseWeightLogger.perSetReps(from: String, count: Int, fallback: String) -> [String]`

- [ ] **Step 1: Add the parsing helper + self-check**

Add this extension at the end of `ExerciseCardView.swift` (after the `ExerciseWeightLogger` struct):

```swift
extension ExerciseWeightLogger {
    /// Per-set rep targets parsed from `exercise.reps`. Mirrors the comma-splitting
    /// `setRepsPills` already uses (ExerciseCardView.swift:215-217). A range like
    /// "8-12" resolves to its upper bound; a single value repeats for every set.
    static func perSetReps(from reps: String, count: Int, fallback: String) -> [String] {
        guard count > 0 else { return [] }
        let parts = reps.components(separatedBy: ",")
            .map { $0.trimmingCharacters(in: .whitespaces) }
        func upperBound(_ s: String) -> String {
            s.contains("-") ? (s.split(separator: "-").last.map(String.init) ?? s) : s
        }
        if parts.count > 1 {
            return (0..<count).map { i in i < parts.count ? upperBound(parts[i]) : fallback }
        }
        return Array(repeating: fallback, count: count)
    }

    #if DEBUG
    static func runSelfCheck() {
        assert(perSetReps(from: "10, 8, 6", count: 3, fallback: "10") == ["10", "8", "6"])
        assert(perSetReps(from: "10, 8, 6", count: 4, fallback: "10") == ["10", "8", "6", "10"])
        assert(perSetReps(from: "8-12", count: 3, fallback: "12") == ["12", "12", "12"])
        assert(perSetReps(from: "12", count: 2, fallback: "12") == ["12", "12"])
        assert(perSetReps(from: "12, 10-8", count: 2, fallback: "12") == ["12", "8"])
    }
    #endif
}
```

- [ ] **Step 2: Use the helper at line 813**

Replace `ExerciseCardView.swift:813`:

```swift
        repsTexts = (0..<setsCount).map { _ in defaultReps }
```

with:

```swift
        repsTexts = Self.perSetReps(from: exercise.reps, count: setsCount, fallback: defaultReps)
```

- [ ] **Step 3: Wire the self-check**

In `bulkup/App/BulkUp.swift`, inside the `#if DEBUG` block (after line 23 `WorkoutFeedbackManager.runSelfCheck()`), add:

```swift
        ExerciseWeightLogger.runSelfCheck()
```

- [ ] **Step 4: Build & run**

Run the app on a simulator (⌘R). Expected: launches with no assertion crash. Then start a workout for an exercise whose plan reps are e.g. `"10, 8, 6"` and confirm the three set inputs read `10`, `8`, `6` (not all `10`/`12`).

- [ ] **Step 5: Commit**

```bash
git add bulkup/Views/Components/Training/ExerciseCardView.swift bulkup/App/BulkUp.swift
git commit -m "fix(workout): per-set reps input respects per-set targets"
```

---

## Task 2: Widget lime accent + padding

**Files:**
- Modify: `BulkUpWidgets/BulkUpWidgetsLiveActivity.swift:9` and `:25`

**Interfaces:** none.

- [ ] **Step 1: Swap accent to lime**

Replace `BulkUpWidgetsLiveActivity.swift:9`:

```swift
    static let accent = Color(red: 0.0, green: 0.902, blue: 0.765)        // #00E6C3
```

with:

```swift
    static let accent = Color(red: 0.518, green: 0.800, blue: 0.086)      // #84CC16 LIME
```

- [ ] **Step 2: Increase padding**

Replace `BulkUpWidgetsLiveActivity.swift:25`:

```swift
                .padding(14)
```

with:

```swift
                .padding(20)
```

- [ ] **Step 3: Build & run the Live Activity**

Run the app, start a workout, and confirm the Lock Screen widget shows the lime accent (buttons, timer, progress bar) and more breathing room around the content.

- [ ] **Step 4: Commit**

```bash
git add BulkUpWidgets/BulkUpWidgetsLiveActivity.swift
git commit -m "style(widget): lime accent and larger content padding"
```

---

## Task 3: Live Activity shows wrong exercise at start

On a fresh start the cursor must point at the first exercise. `buildLiveWorkout` is shared with `syncStoreFromSession` (where advancing IS correct), so gate the behavior with a parameter.

**Files:**
- Modify: `bulkup/ViewModels/WorkoutSessionManager.swift:719` (signature + cursor logic) and `:89` (start call site)
- Modify: `bulkup/Shared/SharedWorkoutStore.swift:90` (extend `runSelfCheck`)

**Interfaces:**
- Produces: `buildLiveWorkout(dayName:trainingManager:seedCursorAtZero:)` with `seedCursorAtZero: Bool = false`

- [ ] **Step 1: Add diagnostic logs (temporary) to confirm the cursor**

In `WorkoutSessionManager.swift`, at the end of `buildLiveWorkout` (just before `return live`, currently line 774), temporarily add:

```swift
        print("[LiveWorkout] cursor=\(live.cursor) current=\(live.current?.exerciseName ?? "nil") completedIds=\(completedSetIds.count)")
```

Run a workout that you have partially logged earlier this week. Confirm the log shows `cursor` > 0 / a later exercise at start — this reproduces the bug. (Remove this log in Step 5.)

- [ ] **Step 2: Add the `seedCursorAtZero` parameter**

Change the `buildLiveWorkout` signature (`WorkoutSessionManager.swift:719`):

```swift
    private func buildLiveWorkout(dayName: String, trainingManager: TrainingManager) -> LiveWorkout {
```

to:

```swift
    private func buildLiveWorkout(dayName: String, trainingManager: TrainingManager, seedCursorAtZero: Bool = false) -> LiveWorkout {
```

Then replace the cursor advance (`WorkoutSessionManager.swift:773`):

```swift
        live.advanceCursor()
        return live
```

with:

```swift
        if !seedCursorAtZero { live.advanceCursor() }
        return live
```

- [ ] **Step 3: Make fresh start seed cursor 0**

Change the start call site (`WorkoutSessionManager.swift:89`):

```swift
        let live = buildLiveWorkout(dayName: dayName, trainingManager: tm)
```

to:

```swift
        let live = buildLiveWorkout(dayName: dayName, trainingManager: tm, seedCursorAtZero: true)
```

(`syncStoreFromSession` at `:361` keeps the default and still advances — leave it unchanged.)

- [ ] **Step 4: Extend the self-check**

In `SharedWorkoutStore.swift`, inside `runSelfCheck()` (before the closing brace at `:108`), add:

```swift
        // Bug-3: a freshly seeded workout (cursor 0, no advance) shows the first
        // exercise even when its first set is pre-marked completed.
        let fresh = LiveWorkout(
            dayName: "Lunes", workoutName: "Push", startDate: Date(), isPaused: false,
            weightUnit: "kg", weightStep: 2.5, repStep: 1,
            sets: [
                .init(exerciseIndex: 0, exerciseName: "Press", setIndex: 0, setsTotalForExercise: 1,
                      weight: 40, reps: 10, restSeconds: 60, completed: true),
                .init(exerciseIndex: 1, exerciseName: "Curl", setIndex: 0, setsTotalForExercise: 1,
                      weight: 20, reps: 12, restSeconds: 60, completed: false),
            ],
            cursor: 0, restEndDate: nil
        )
        assert(fresh.current?.exerciseName == "Press", "fresh start must show the first exercise")
```

- [ ] **Step 5: Remove the diagnostic log, build & verify**

Delete the `print(...)` added in Step 1. Run the app; confirm no assertion crash. Re-run the same partially-logged workout and confirm the widget now shows the **first** exercise at start.

- [ ] **Step 6: Commit**

```bash
git add bulkup/ViewModels/WorkoutSessionManager.swift bulkup/Shared/SharedWorkoutStore.swift
git commit -m "fix(widget): Live Activity starts at the first exercise"
```

---

## Task 4: Delete added sets

Remove user-added sets only; planned sets are untouched. The set rows are in a VStack (not a List), so use a symmetric +/− control next to "Añadir serie" that removes the last added set.

**Files:**
- Modify: `bulkup/ViewModels/WorkoutSessionManager.swift` (add `removeLastSet`, near `addSet` at `:542`)
- Modify: `bulkup/Views/Components/Training/ExerciseCardView.swift` (the add-set button block, `:373-386`)

**Interfaces:**
- Consumes (Task 1): `Self.perSetReps(...)` (unrelated; no dependency)
- Produces: `WorkoutSessionManager.removeLastSet(day:exerciseIndex:plannedSets:)`

- [ ] **Step 1: Add `removeLastSet` to the manager**

In `WorkoutSessionManager.swift`, immediately after `addSet` (`:542-545`), add:

```swift
    /// Removes the most recently added set for an exercise (added sets only —
    /// planned sets are never removed). Clears that set's session state.
    func removeLastSet(day: String, exerciseIndex: Int, plannedSets: Int) {
        let key = exerciseKey(day: day, exerciseIndex: exerciseIndex)
        guard let extra = addedSets[key], extra > 0 else { return }
        let removedIndex = plannedSets + extra - 1
        let sk = setKey(day: day, exerciseIndex: exerciseIndex, setIndex: removedIndex)
        completedSetIds.remove(sk)
        failedSetIds.remove(sk)
        actualReps[sk] = nil
        if extra - 1 == 0 { addedSets[key] = nil } else { addedSets[key] = extra - 1 }
    }
```

- [ ] **Step 2: Add a self-check for the manager**

Add to `WorkoutSessionManager.swift` (DEBUG), following the same pattern as the existing `runSelfCheck` statics in sibling managers (`WorkoutFeedbackManager.runSelfCheck`):

```swift
    #if DEBUG
    @MainActor
    static func runSelfCheck() {
        let m = WorkoutSessionManager()
        m.addSet(day: "lunes", exerciseIndex: 0)
        m.addSet(day: "lunes", exerciseIndex: 0)
        assert(m.extraSets(day: "lunes", exerciseIndex: 0) == 2)
        m.removeLastSet(day: "lunes", exerciseIndex: 0, plannedSets: 3)
        assert(m.extraSets(day: "lunes", exerciseIndex: 0) == 1)
        m.removeLastSet(day: "lunes", exerciseIndex: 0, plannedSets: 3)
        m.removeLastSet(day: "lunes", exerciseIndex: 0, plannedSets: 3) // floor at 0
        assert(m.extraSets(day: "lunes", exerciseIndex: 0) == 0)
    }
    #endif
```

(If `WorkoutSessionManager()` is not directly constructible — e.g. it is a `.shared` singleton with a private init — instead exercise the shared instance and reset it: `let m = WorkoutSessionManager.shared` and remove the local construction. Verify the init access level before writing this step.)

- [ ] **Step 3: Wire the self-check**

In `bulkup/App/BulkUp.swift` DEBUG block, add:

```swift
        WorkoutSessionManager.runSelfCheck()
```

If `runSelfCheck` is `@MainActor` and `BulkUp.init` is not, wrap the call: `MainActor.assumeIsolated { WorkoutSessionManager.runSelfCheck() }`.

- [ ] **Step 4: Add the remove control in the UI**

In `ExerciseCardView.swift`, replace the add-set button block (`:373-386`):

```swift
        // Add set button
        Button {
            workoutSession.addSet(day: normalizedDay, exerciseIndex: exercise.orderIndex)
            ensureArrayCapacity()
        } label: {
            HStack(spacing: Spacing.xs) {
                Image(systemName: "plus.circle")
                    .font(.system(size: 12))
                Text("Anadir serie")
                    .font(.system(size: 12, weight: .medium))
            }
            .foregroundColor(BulkUpColors.accent)
            .padding(.vertical, Spacing.xs)
        }
```

with:

```swift
        // Add / remove set buttons
        HStack(spacing: Spacing.md) {
            Button {
                workoutSession.addSet(day: normalizedDay, exerciseIndex: exercise.orderIndex)
                ensureArrayCapacity()
            } label: {
                HStack(spacing: Spacing.xs) {
                    Image(systemName: "plus.circle")
                        .font(.system(size: 12))
                    Text("Anadir serie")
                        .font(.system(size: 12, weight: .medium))
                }
                .foregroundColor(BulkUpColors.accent)
                .padding(.vertical, Spacing.xs)
            }

            if workoutSession.extraSets(day: normalizedDay, exerciseIndex: exercise.orderIndex) > 0 {
                Button {
                    workoutSession.removeLastSet(
                        day: normalizedDay, exerciseIndex: exercise.orderIndex, plannedSets: exercise.sets
                    )
                    trimArrayCapacity()
                } label: {
                    HStack(spacing: Spacing.xs) {
                        Image(systemName: "minus.circle")
                            .font(.system(size: 12))
                        Text("Quitar serie")
                            .font(.system(size: 12, weight: .medium))
                    }
                    .foregroundColor(BulkUpColors.textTertiary)
                    .padding(.vertical, Spacing.xs)
                }
            }
        }
```

- [ ] **Step 5: Add `trimArrayCapacity` helper**

In `ExerciseCardView.swift`, next to `ensureArrayCapacity` (`:785`), add a helper that drops the trailing local entries and clears the removed set's weight so it isn't persisted:

```swift
    private func trimArrayCapacity() {
        let removedIndex = weightTexts.count - 1
        if removedIndex >= 0 {
            let key = trainingManager.generateWeightKey(
                day: normalizedDay, exerciseIndex: exercise.orderIndex,
                exerciseName: exercise.name, setIndex: removedIndex, weekStart: currentWeekString
            )
            trainingManager.weights[key] = nil
        }
        if weightTexts.count > totalSetsCount { weightTexts.removeLast() }
        if repsTexts.count > totalSetsCount { repsTexts.removeLast() }
    }
```

(Confirm `trainingManager.weights` is a mutable `@Published var [String: Double]`; if it is exposed only through setters, call the existing setter instead of assigning `nil` — check `TrainingManager` for a `removeWeight`/`setWeight` API and use it.)

- [ ] **Step 6: Build & verify**

Run the app. Start a workout, tap "Añadir serie" twice (2 extra rows appear, "Quitar serie" appears), tap "Quitar serie" once → one extra row disappears, planned sets and their data are unchanged. No assertion crash at launch.

- [ ] **Step 7: Commit**

```bash
git add bulkup/ViewModels/WorkoutSessionManager.swift bulkup/Views/Components/Training/ExerciseCardView.swift bulkup/App/BulkUp.swift
git commit -m "feat(workout): remove added sets"
```

---

## Task 5: WorkoutVideoStore (local per-set video storage)

A standalone store mirroring `WorkoutPhotoStore`, plus a `[setKey: filename]` JSON index and a `PickedVideo` transferable for `PhotosPicker`.

**Files:**
- Create: `bulkup/Utils/WorkoutVideoStore.swift`
- Modify: `bulkup/App/BulkUp.swift:16-25` (wire self-check)

**Interfaces:**
- Produces:
  - `struct PickedVideo: Transferable { let url: URL }`
  - `WorkoutVideoStore.url(for: String) -> URL?`
  - `WorkoutVideoStore.hasVideo(for: String) -> Bool`
  - `WorkoutVideoStore.save(from: URL, for: String) -> String?` (`@discardableResult`)
  - `WorkoutVideoStore.delete(for: String)`

- [ ] **Step 1: Create the store**

Create `bulkup/Utils/WorkoutVideoStore.swift`:

```swift
import Foundation
import CoreTransferable
import UniformTypeIdentifiers

/// Wraps a PhotosPicker-selected video as a file URL we can move into storage.
/// PhotosPicker deletes its delivered file after the importing closure returns,
/// so we copy it to a temp location first.
struct PickedVideo: Transferable {
    let url: URL
    static var transferRepresentation: some TransferRepresentation {
        FileRepresentation(contentType: .movie) { SentTransferredFile($0.url) } importing: { received in
            let temp = FileManager.default.temporaryDirectory
                .appendingPathComponent(UUID().uuidString + ".mov")
            try? FileManager.default.removeItem(at: temp)
            try FileManager.default.copyItem(at: received.file, to: temp)
            return Self(url: temp)
        }
    }
}

/// Stores per-set workout videos in Documents/WorkoutVideos (on-device only —
/// never uploaded). A JSON index maps a set key to its filename. Mirrors
/// WorkoutPhotoStore.
enum WorkoutVideoStore {
    private static var directory: URL {
        let base = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("WorkoutVideos", isDirectory: true)
        try? FileManager.default.createDirectory(at: base, withIntermediateDirectories: true)
        return base
    }
    private static var indexURL: URL { directory.appendingPathComponent("index.json") }

    private static func loadIndex() -> [String: String] {
        guard let data = try? Data(contentsOf: indexURL),
              let map = try? JSONDecoder().decode([String: String].self, from: data) else { return [:] }
        return map
    }
    private static func saveIndex(_ map: [String: String]) {
        if let data = try? JSONEncoder().encode(map) { try? data.write(to: indexURL) }
    }

    /// File URL of the video for a set, or nil if none / missing on disk.
    static func url(for setKey: String) -> URL? {
        guard let name = loadIndex()[setKey] else { return nil }
        let u = directory.appendingPathComponent(name)
        return FileManager.default.fileExists(atPath: u.path) ? u : nil
    }

    static func hasVideo(for setKey: String) -> Bool { url(for: setKey) != nil }

    /// Moves a picked temp video into storage and indexes it under `setKey`,
    /// replacing any existing video for that set. Returns the stored filename.
    @discardableResult
    static func save(from tempURL: URL, for setKey: String) -> String? {
        delete(for: setKey)
        let filename = "\(UUID().uuidString).mov"
        let dest = directory.appendingPathComponent(filename)
        do {
            try FileManager.default.moveItem(at: tempURL, to: dest)
        } catch {
            guard (try? FileManager.default.copyItem(at: tempURL, to: dest)) != nil else { return nil }
        }
        var map = loadIndex(); map[setKey] = filename; saveIndex(map)
        return filename
    }

    static func delete(for setKey: String) {
        var map = loadIndex()
        if let name = map[setKey] {
            try? FileManager.default.removeItem(at: directory.appendingPathComponent(name))
            map[setKey] = nil; saveIndex(map)
        }
    }

    #if DEBUG
    static func runSelfCheck() {
        // Index encode/decode round-trip (no disk side effects).
        let sample = ["plan-lunes-0-press-0-2026-06-22": "abc.mov"]
        guard let data = try? JSONEncoder().encode(sample),
              let back = try? JSONDecoder().decode([String: String].self, from: data) else {
            assertionFailure("video index codec"); return
        }
        assert(back == sample, "video index round-trip")
    }
    #endif
}
```

- [ ] **Step 2: Wire the self-check**

In `bulkup/App/BulkUp.swift` DEBUG block, add:

```swift
        WorkoutVideoStore.runSelfCheck()
```

- [ ] **Step 3: Build & verify**

Run the app. Expected: no assertion crash at launch.

- [ ] **Step 4: Commit**

```bash
git add bulkup/Utils/WorkoutVideoStore.swift bulkup/App/BulkUp.swift
git commit -m "feat(workout): local per-set video store"
```

---

## Task 6: Per-set video UI (pick, warn, play, replace, delete)

Add a video button to each set row using the store from Task 5, with a one-time local-storage warning and an AVKit playback sheet.

**Files:**
- Modify: `bulkup/Views/Components/Training/ExerciseCardView.swift` (imports, state, row button, modifiers)

**Interfaces:**
- Consumes (Task 5): `WorkoutVideoStore.{hasVideo,url,save,delete}`, `PickedVideo`

- [ ] **Step 1: Add imports**

At the top of `ExerciseCardView.swift`, add (below `import SwiftUI`):

```swift
import PhotosUI
import AVKit
```

- [ ] **Step 2: Add view state to `ExerciseWeightLogger`**

After the existing `@State` declarations (`:257-263`), add:

```swift
    @State private var videoSets: Set<Int> = []          // set indices that have a video
    @State private var pendingVideoSet: Int?             // set awaiting a picker result
    @State private var selectedVideoItem: PhotosPickerItem?
    @State private var playerSet: Int?                   // set whose video is playing
    @AppStorage("hasSeenVideoStorageWarning") private var hasSeenVideoWarning = false
    @State private var showVideoWarning = false
```

- [ ] **Step 3: Add the per-set key + presence helpers**

Add these methods inside `ExerciseWeightLogger` (near `loadInitialData`):

```swift
    private func videoKey(_ setIndex: Int) -> String {
        trainingManager.generateWeightKey(
            day: normalizedDay, exerciseIndex: exercise.orderIndex,
            exerciseName: exercise.name, setIndex: setIndex, weekStart: currentWeekString
        )
    }

    private func refreshVideoSets() {
        videoSets = Set((0..<totalSetsCount).filter { WorkoutVideoStore.hasVideo(for: videoKey($0)) })
    }

    private func startVideoFlow(for setIndex: Int) {
        pendingVideoSet = setIndex
        if hasSeenVideoWarning {
            // PhotosPicker is presented via the .photosPicker modifier bound to pendingVideoSet.
        } else {
            showVideoWarning = true
        }
    }
```

- [ ] **Step 4: Load presence on appear**

In `loadInitialData()` (`:798-816`), add at the end (after `loadExerciseNote()`):

```swift
        refreshVideoSets()
```

- [ ] **Step 5: Add the video button to the set row**

In `workoutSetRow(setIndex:)`, just before the check `Button` (`:519`), add:

```swift
            // Per-set video
            Button {
                if videoSets.contains(setIndex) {
                    playerSet = setIndex
                } else {
                    startVideoFlow(for: setIndex)
                }
            } label: {
                Image(systemName: videoSets.contains(setIndex) ? "video.fill" : "video.badge.plus")
                    .font(.system(size: 14))
                    .foregroundColor(videoSets.contains(setIndex) ? BulkUpColors.accent : BulkUpColors.textTertiary)
                    .frame(width: 28, height: 28)
                    .contentShape(Rectangle())
            }
```

- [ ] **Step 6: Add picker, warning alert, and player sheet modifiers**

On the `ExerciseWeightLogger` body, after the existing `.onChange(of:)` modifiers (`:331-333`), add:

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
        .onChange(of: selectedVideoItem) { _, item in
            guard let item, let setIndex = pendingVideoSet else { return }
            Task {
                if let picked = try? await item.loadTransferable(type: PickedVideo.self) {
                    WorkoutVideoStore.save(from: picked.url, for: videoKey(setIndex))
                    await MainActor.run {
                        refreshVideoSets()
                        selectedVideoItem = nil
                        pendingVideoSet = nil
                    }
                }
            }
        }
        .alert("Vídeos en este dispositivo", isPresented: $showVideoWarning) {
            Button("Entendido") {
                hasSeenVideoWarning = true   // picker opens automatically (binding above)
            }
            Button("Cancelar", role: .cancel) { pendingVideoSet = nil }
        } message: {
            Text("Los vídeos se guardan solo en este dispositivo y no se suben a la nube.")
        }
        .sheet(item: Binding(
            get: { playerSet.map { VideoSheetItem(setIndex: $0) } },
            set: { playerSet = $0?.setIndex }
        )) { sheet in
            videoPlayerSheet(for: sheet.setIndex)
        }
```

- [ ] **Step 7: Add the player sheet + its item type**

Add inside `ExerciseWeightLogger`:

```swift
    private struct VideoSheetItem: Identifiable { let setIndex: Int; var id: Int { setIndex } }

    @ViewBuilder
    private func videoPlayerSheet(for setIndex: Int) -> some View {
        NavigationStack {
            Group {
                if let url = WorkoutVideoStore.url(for: videoKey(setIndex)) {
                    VideoPlayer(player: AVPlayer(url: url))
                        .ignoresSafeArea(edges: .bottom)
                } else {
                    Text("Vídeo no disponible").foregroundColor(BulkUpColors.textSecondary)
                }
            }
            .navigationTitle("Serie \(setIndex + 1)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Reemplazar") { playerSet = nil; startVideoFlow(for: setIndex) }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Eliminar", role: .destructive) {
                        WorkoutVideoStore.delete(for: videoKey(setIndex))
                        refreshVideoSets()
                        playerSet = nil
                    }
                }
            }
        }
    }
```

- [ ] **Step 8: Build & verify the full flow**

Run the app, start a workout:
1. Tap the video button on a set → warning alert appears (first time) → "Entendido" → photo picker opens → pick a video → button turns to a filled icon.
2. Tap the filled button → video plays in a sheet; "Reemplazar" lets you pick another; "Eliminar" removes it and the icon reverts.
3. Kill and relaunch the app, reopen the same workout/week → the video is still associated and plays.
No assertion crash at launch.

- [ ] **Step 9: Commit**

```bash
git add bulkup/Views/Components/Training/ExerciseCardView.swift
git commit -m "feat(workout): attach, play, replace and delete per-set videos"
```

---

## Self-Review

**Spec coverage:**
- Spec §1 (reps input) → Task 1 ✓
- Spec §2 (widget lime + padding) → Task 2 ✓
- Spec §3 (widget wrong exercise) → Task 3 ✓
- Spec §4 (delete sets) → Task 4 ✓ (last-added removal via +/−; see note below)
- Spec §5 (per-set videos) → Tasks 5 + 6 ✓
- Spec "out of scope: music" → no task ✓

**Deviation from spec (flagged):** Spec §4 described `.swipeActions`. The set rows live in a VStack, not a List, so native swipe is unavailable without restructuring the rows into a List (disproportionate to the change). This plan implements a symmetric "Añadir serie / Quitar serie" pair that removes the last added set — same capability, no layout refactor. If true per-row swipe is required, that becomes a separate task to migrate the set rows into a `List` with `.swipeActions`.

**Placeholder scan:** No TBD/TODO/"handle edge cases". Two steps contain explicit "confirm X before writing" guards (Task 4 Step 2 init access; Task 4 Step 5 `weights` mutability) — these are verification instructions, not placeholders, because the surrounding code is fully specified for the common case.

**Type consistency:** `videoKey`/`setVideoKey` unified to `videoKey` throughout Task 6. `perSetReps`, `removeLastSet`, `WorkoutVideoStore.save(from:for:)`, `PickedVideo.url` are referenced with consistent signatures across tasks.
