# Interactive Workout Live Activity — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** A Lock Screen Live Activity for the active workout that shows live timer/exercise/set/rest status and lets the user complete sets, adjust weight/reps (±), and control rest from the Lock Screen.

**Architecture:** A new Widget Extension renders an ActivityKit Live Activity. An App-Group-backed `SharedWorkoutStore` is the single source of truth (V2); `WorkoutSessionManager` and the live weight/rep fields refactor onto it. Buttons are `LiveActivityIntent`s that mutate the store and update the activity; the app reconciles mutations into `TrainingManager.weights`/SwiftData/sync.

**Tech Stack:** SwiftUI, ActivityKit, WidgetKit, App Intents, App Group (`UserDefaults`), Objective-C Darwin notifications.

**Verification note:** No XCTest target exists. Verification = `xcodebuild` build success + a `#if DEBUG` assert self-check for pure store logic + manual on-device/simulator checks. Do NOT add a test target.

**IDs (use exactly):**
- App bundle id: `com.whitesolutions.bulkup`
- Widget bundle id: `com.whitesolutions.bulkup.BulkUpWidgets`
- App Group: `group.com.whitesolutions.bulkup`

**Build command (app):**
```bash
cd /Users/sebastian.blanco/Documents/Sebas/bulkup
xcodebuild -scheme bulkup-Dev -destination 'generic/platform=iOS Simulator' build CODE_SIGNING_ALLOWED=NO 2>&1 | grep -E "error:|BUILD SUCCEEDED|BUILD FAILED"
```

> **⚠️ MANUAL XCODE STEPS REQUIRED.** Creating the Widget Extension target and adding the App Group capability cannot be done from the CLI/agent — they need Xcode UI (and an Apple Developer account for the App Group). Tasks 1–2 are written as explicit human instructions. Everything after is normal code with build verification.

---

## File Structure

Shared files (target membership: **app AND widget**):
- `bulkup/Shared/WorkoutActivityAttributes.swift` — `ActivityAttributes` + `ContentState`.
- `bulkup/Shared/SharedWorkoutStore.swift` — App-Group source of truth + cursor/stepping/progress logic (pure, testable).
- `bulkup/Shared/WorkoutLiveActivityIntents.swift` — the `LiveActivityIntent` button intents.

App-only:
- `bulkup/ViewModels/WorkoutActivityController.swift` — request/update/end the Activity; observe the store.
- Modified: `bulkup/ViewModels/WorkoutSessionManager.swift` — route live fields through the store; add current-set cursor; reconcile.
- Modified: `bulkup/bulkupDevelopment.entitlements` (+ Prod entitlements) — App Group.

Widget-only (new target `BulkUpWidgets`):
- `BulkUpWidgets/BulkUpWidgetsBundle.swift` — `@main WidgetBundle`.
- `BulkUpWidgets/WorkoutLiveActivity.swift` — `ActivityConfiguration`, Lock Screen view, minimal Dynamic Island.

---

## PHASE 1 — Scaffold + read-only activity

### Task 1: Create the Widget Extension target (MANUAL — Xcode)

- [ ] **Step 1: Add the target**

In Xcode: File ▸ New ▸ Target ▸ **Widget Extension**. Product name `BulkUpWidgets`. **Check "Include Live Activity"**, **uncheck** "Include Configuration App Intent". Bundle id `com.whitesolutions.bulkup.BulkUpWidgets`. Embed in the `bulkup` app. Set the extension's **iOS Deployment Target to 26.0** to match the app. Do NOT activate the scheme prompt’s separate scheme (keep building via `bulkup-Dev`).

- [ ] **Step 2: Confirm it builds**

Run the build command. Expected `BUILD SUCCEEDED` (Xcode generates placeholder widget files; we replace them in later tasks).

- [ ] **Step 3: Commit the generated scaffold**

```bash
git add -A bulkup.xcodeproj BulkUpWidgets
git commit -m "chore(widget): add BulkUpWidgets extension target (Live Activity)"
```

### Task 2: Add the App Group capability (MANUAL — Xcode)

- [ ] **Step 1: Add capability to both targets**

In Xcode ▸ target `bulkup` ▸ Signing & Capabilities ▸ + Capability ▸ **App Groups** ▸ add `group.com.whitesolutions.bulkup`. Repeat for target `BulkUpWidgets` (same group). This requires being signed into a team; it edits the `.entitlements` files and provisioning.

- [ ] **Step 2: Verify entitlements**

Confirm `bulkup/bulkupDevelopment.entitlements` (and the Production entitlements, and the widget’s entitlements) contain:
```xml
<key>com.apple.security.application-groups</key>
<array><string>group.com.whitesolutions.bulkup</string></array>
```

- [ ] **Step 3: Build + commit**

Run the build command (Expected `BUILD SUCCEEDED`), then:
```bash
git add -A bulkup.xcodeproj BulkUpWidgets bulkup/*.entitlements
git commit -m "chore(widget): add App Group group.com.whitesolutions.bulkup to app + widget"
```

### Task 3: ActivityAttributes + ContentState (shared)

**Files:** Create `bulkup/Shared/WorkoutActivityAttributes.swift` (add to BOTH app + widget target membership in the File Inspector).

- [ ] **Step 1: Write the types**

```swift
import ActivityKit
import Foundation

struct WorkoutActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Identity / header
        var workoutName: String
        var startDate: Date          // drives elapsed Text(timerInterval:)
        var isPaused: Bool

        // Current-set cursor
        var exerciseName: String
        var setIndex: Int            // 0-based
        var setsTotal: Int

        // Current working values
        var weight: Double
        var reps: Int
        var weightUnit: String       // "kg" or "lb"

        // Progress
        var completedSets: Int
        var totalSets: Int

        // Rest
        var isResting: Bool
        var restEndDate: Date?

        // Terminal
        var isFinished: Bool
    }

    // Static for the whole activity (rarely changes)
    var dayName: String
}
```

- [ ] **Step 2: Build + commit**

Run the build command. Expected `BUILD SUCCEEDED`.
```bash
git add bulkup/Shared/WorkoutActivityAttributes.swift bulkup.xcodeproj
git commit -m "feat(widget): WorkoutActivityAttributes + ContentState"
```

### Task 4: Lock Screen + minimal Dynamic Island view (read-only)

**Files:** Replace `BulkUpWidgets/WorkoutLiveActivity.swift`; ensure `BulkUpWidgets/BulkUpWidgetsBundle.swift` includes it.

- [ ] **Step 1: Write the read-only activity view**

```swift
import ActivityKit
import SwiftUI
import WidgetKit

struct WorkoutLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: WorkoutActivityAttributes.self) { context in
            // Lock Screen
            WorkoutLockScreenView(state: context.state)
                .padding()
                .activityBackgroundTint(Color.black.opacity(0.6))
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Text(timerInterval: context.state.startDate...Date.distantFuture, countsDown: false)
                        .monospacedDigit().font(.caption)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text("\(context.state.completedSets)/\(context.state.totalSets)").font(.caption)
                }
            } compactLeading: {
                Image(systemName: "dumbbell.fill")
            } compactTrailing: {
                Text("\(context.state.completedSets)/\(context.state.totalSets)").font(.caption2)
            } minimal: {
                Image(systemName: "dumbbell.fill")
            }
        }
    }
}

struct WorkoutLockScreenView: View {
    let state: WorkoutActivityAttributes.ContentState

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(state.workoutName).font(.headline).lineLimit(1)
                Spacer()
                Text(timerInterval: state.startDate...Date.distantFuture, countsDown: false)
                    .monospacedDigit().font(.subheadline)
            }
            if state.isFinished {
                Text("Workout complete").font(.subheadline)
            } else if state.isResting, let end = state.restEndDate {
                HStack {
                    Text("Rest").font(.subheadline)
                    Text(timerInterval: Date()...end, countsDown: true)
                        .monospacedDigit().font(.title3.bold())
                }
            } else {
                Text("\(state.exerciseName) · Set \(state.setIndex + 1)/\(state.setsTotal)")
                    .font(.subheadline)
                Text("\(formatWeight(state.weight)) \(state.weightUnit) × \(state.reps)")
                    .font(.subheadline).foregroundStyle(.secondary)
            }
            ProgressView(value: Double(state.completedSets),
                         total: Double(max(state.totalSets, 1)))
                .tint(.green)
        }
    }

    private func formatWeight(_ w: Double) -> String {
        w == w.rounded() ? String(format: "%.0f", w) : String(format: "%.1f", w)
    }
}
```

Ensure `BulkUpWidgetsBundle.swift` is:
```swift
import SwiftUI
import WidgetKit

@main
struct BulkUpWidgetsBundle: WidgetBundle {
    var body: some Widget {
        WorkoutLiveActivity()
    }
}
```

- [ ] **Step 2: Build + commit**

Run the build command. Expected `BUILD SUCCEEDED`.
```bash
git add BulkUpWidgets bulkup.xcodeproj
git commit -m "feat(widget): read-only Lock Screen + minimal Dynamic Island views"
```

### Task 5: Start/end the activity from the workout session (read-only)

**Files:** Create `bulkup/ViewModels/WorkoutActivityController.swift` (app target). Modify `bulkup/ViewModels/WorkoutSessionManager.swift`.

- [ ] **Step 1: Write the controller**

```swift
import ActivityKit
import Foundation

@MainActor
final class WorkoutActivityController {
    static let shared = WorkoutActivityController()
    private var activity: Activity<WorkoutActivityAttributes>?

    func start(dayName: String, state: WorkoutActivityAttributes.ContentState) {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }
        endStaleActivities()
        do {
            activity = try Activity.request(
                attributes: WorkoutActivityAttributes(dayName: dayName),
                content: .init(state: state, staleDate: nil)
            )
        } catch {
            print("Live Activity start failed: \(error)")
        }
    }

    func update(_ state: WorkoutActivityAttributes.ContentState) {
        guard let activity else { return }
        Task { await activity.update(.init(state: state, staleDate: nil)) }
    }

    func end() {
        Task {
            for a in Activity<WorkoutActivityAttributes>.activities {
                await a.end(nil, dismissalPolicy: .immediate)
            }
        }
        activity = nil
    }

    /// End orphaned activities left by a crash.
    func endStaleActivities() {
        for a in Activity<WorkoutActivityAttributes>.activities {
            Task { await a.end(nil, dismissalPolicy: .immediate) }
        }
    }
}
```

- [ ] **Step 2: Build a ContentState from the session and start/end it**

In `WorkoutSessionManager`, add a helper that builds the current `ContentState` from existing state (use the first incomplete set as the cursor — this is the temporary cursor before Phase 2 formalizes it):

```swift
func currentActivityState(trainingManager: TrainingManager) -> WorkoutActivityAttributes.ContentState {
    let (exName, setIdx, setsTotal, weight, reps) = currentCursor(trainingManager: trainingManager)
    return .init(
        workoutName: workoutName ?? currentDayName ?? "",
        startDate: startTime ?? Date(),
        isPaused: isPaused,
        exerciseName: exName,
        setIndex: setIdx,
        setsTotal: setsTotal,
        weight: weight,
        reps: reps,
        weightUnit: UserDefaults.standard.string(forKey: "units") == "imperial" ? "lb" : "kg",
        completedSets: completedSetIds.count,
        totalSets: totalSetsForCurrentDay(trainingManager: trainingManager),
        isResting: restTimerActive,
        restEndDate: restTimerActive ? Date().addingTimeInterval(TimeInterval(restTimerRemaining)) : nil,
        isFinished: false
    )
}
```

Implement `currentCursor(trainingManager:)` returning the first incomplete `(exerciseName, setIndex, setsTotal, weight, reps)` for `currentDayName`, and `totalSetsForCurrentDay(trainingManager:)`. (Use the existing `trainingData`/`weights` lookups already in this file — mirror `buildSummary`’s iteration. Default reps via the existing `parseReps`.)

In `startWorkout(...)`, after the existing setup, add:
```swift
WorkoutActivityController.shared.start(
    dayName: dayName,
    state: currentActivityState(trainingManager: trainingManager ?? .shared)
)
```
In `resetAll()` add `WorkoutActivityController.shared.end()`.

- [ ] **Step 3: Build + commit**

Run the build command. Expected `BUILD SUCCEEDED`.
```bash
git add bulkup/ViewModels/WorkoutActivityController.swift bulkup/ViewModels/WorkoutSessionManager.swift bulkup.xcodeproj
git commit -m "feat(widget): start/end Live Activity with the workout session"
```

- [ ] **Step 4: Manual verification**

Run on a simulator/device, start a workout, lock the screen (or check the Dynamic Island): the activity appears, the elapsed timer ticks, and current exercise/set/progress render. Finishing the workout removes it.

---

## PHASE 2 — SharedWorkoutStore as source of truth + reconciliation

### Task 6: SharedWorkoutStore with pure cursor/stepping logic

**Files:** Create `bulkup/Shared/SharedWorkoutStore.swift` (BOTH targets).

- [ ] **Step 1: Write the store**

```swift
import Foundation

/// Single source of truth for the live workout, shared between app and widget
/// via the App Group. All live-session mutations go through here.
struct LiveWorkout: Codable, Equatable {
    var dayName: String
    var workoutName: String
    var startDate: Date
    var isPaused: Bool
    var weightUnit: String
    var weightStep: Double
    var repStep: Int

    /// Per (exerciseIndex,setIndex) completion + working values, ordered by exercise then set.
    var sets: [LiveSet]
    var cursor: Int           // index into `sets` of the current (first incomplete) set
    var restEndDate: Date?

    struct LiveSet: Codable, Equatable {
        var exerciseIndex: Int
        var exerciseName: String
        var setIndex: Int
        var setsTotalForExercise: Int
        var weight: Double
        var reps: Int
        var restSeconds: Int
        var completed: Bool
    }

    var completedCount: Int { sets.filter(\.completed).count }
    var isFinished: Bool { cursor >= sets.count }
    var current: LiveSet? { sets.indices.contains(cursor) ? sets[cursor] : nil }

    /// Advance cursor to the next incomplete set.
    mutating func advanceCursor() {
        var i = cursor
        while i < sets.count && sets[i].completed { i += 1 }
        cursor = i
    }
}

enum SharedWorkoutStore {
    static let suite = "group.com.whitesolutions.bulkup"
    private static let key = "live_workout"
    static let darwinName = "com.whitesolutions.bulkup.liveWorkoutChanged"

    private static var defaults: UserDefaults { UserDefaults(suiteName: suite)! }

    static func load() -> LiveWorkout? {
        guard let data = defaults.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(LiveWorkout.self, from: data)
    }

    static func save(_ w: LiveWorkout?) {
        if let w, let data = try? JSONEncoder().encode(w) {
            defaults.set(data, forKey: key)
        } else {
            defaults.removeObject(forKey: key)
        }
    }

    // MARK: Pure mutations (used by intents AND the app)
    static func completeCurrentSet() {
        guard var w = load(), var s = w.current else { return }
        s.completed = true
        w.sets[w.cursor] = s
        w.restEndDate = s.restSeconds > 0 ? Date().addingTimeInterval(TimeInterval(s.restSeconds)) : nil
        w.advanceCursor()
        save(w)
    }
    static func adjustWeight(_ delta: Double) {
        guard var w = load(), w.current != nil else { return }
        w.sets[w.cursor].weight = max(0, w.sets[w.cursor].weight + delta)
        save(w)
    }
    static func adjustReps(_ delta: Int) {
        guard var w = load(), w.current != nil else { return }
        w.sets[w.cursor].reps = max(0, w.sets[w.cursor].reps + delta)
        save(w)
    }
    static func skipRest() { guard var w = load() else { return }; w.restEndDate = nil; save(w) }
    static func addRest(_ seconds: Int) {
        guard var w = load() else { return }
        w.restEndDate = (w.restEndDate ?? Date()).addingTimeInterval(TimeInterval(seconds))
        save(w)
    }
}
```

- [ ] **Step 2: Add a DEBUG self-check for the pure logic**

In `SharedWorkoutStore.swift`:
```swift
#if DEBUG
extension SharedWorkoutStore {
    static func runSelfCheck() {
        var w = LiveWorkout(
            dayName: "Lunes", workoutName: "Push", startDate: Date(), isPaused: false,
            weightUnit: "kg", weightStep: 2.5, repStep: 1,
            sets: [
                .init(exerciseIndex: 0, exerciseName: "Press", setIndex: 0, setsTotalForExercise: 2,
                      weight: 40, reps: 10, restSeconds: 60, completed: false),
                .init(exerciseIndex: 0, exerciseName: "Press", setIndex: 1, setsTotalForExercise: 2,
                      weight: 40, reps: 10, restSeconds: 60, completed: false),
            ],
            cursor: 0, restEndDate: nil
        )
        assert(w.current?.setIndex == 0 && !w.isFinished)
        w.advanceCursor(); assert(w.cursor == 0) // nothing completed yet
        w.sets[0].completed = true; w.advanceCursor()
        assert(w.cursor == 1, "cursor should skip completed set")
        w.sets[1].completed = true; w.advanceCursor()
        assert(w.isFinished, "all sets done → finished")
        assert(w.completedCount == 2)
    }
}
#endif
```
Call it from `bulkup/App/BulkUp.swift` `init()` inside the existing `#if DEBUG` block:
```swift
SharedWorkoutStore.runSelfCheck()
```

- [ ] **Step 3: Build + run (debug) to exercise the assert**

Run the build command (Expected `BUILD SUCCEEDED`), launch in the simulator, confirm no assertion failure.

- [ ] **Step 4: Commit**

```bash
git add bulkup/Shared/SharedWorkoutStore.swift bulkup/App/BulkUp.swift bulkup.xcodeproj
git commit -m "feat(widget): SharedWorkoutStore source of truth + cursor logic + self-check"
```

### Task 7: Seed/refactor WorkoutSessionManager onto the store + reconcile

**Files:** Modify `bulkup/ViewModels/WorkoutSessionManager.swift`, `bulkup/ViewModels/WorkoutActivityController.swift`.

- [ ] **Step 1: Seed the store on workout start**

In `startWorkout`, build a `LiveWorkout` by iterating the active day’s exercises/sets (mirror `buildSummary`’s loop), reading initial weights from `trainingManager.weights` and reps via `parseReps`, set `cursor` to the first incomplete set, `weightStep` = 2.5 (or 5 if imperial), `repStep` = 1. `SharedWorkoutStore.save(liveWorkout)`. Then start the activity from a `ContentState` mapped from the store (add `WorkoutActivityController.contentState(from: LiveWorkout)`).

- [ ] **Step 2: Map LiveWorkout → ContentState in the controller**

```swift
extension WorkoutActivityController {
    static func contentState(from w: LiveWorkout) -> WorkoutActivityAttributes.ContentState {
        let cur = w.current
        return .init(
            workoutName: w.workoutName, startDate: w.startDate, isPaused: w.isPaused,
            exerciseName: cur?.exerciseName ?? "", setIndex: cur?.setIndex ?? 0,
            setsTotal: cur?.setsTotalForExercise ?? 0,
            weight: cur?.weight ?? 0, reps: cur?.reps ?? 0, weightUnit: w.weightUnit,
            completedSets: w.completedCount, totalSets: w.sets.count,
            isResting: w.restEndDate.map { $0 > Date() } ?? false,
            restEndDate: w.restEndDate, isFinished: w.isFinished
        )
    }
}
```

- [ ] **Step 3: Route in-app actions through the store + reconcile**

When the in-app UI completes a set (existing `completeSet` path in `WorkoutSessionManager`/`ExerciseCardView`), also call `SharedWorkoutStore.completeCurrentSet()` (or set the matching set’s completion) and `WorkoutActivityController.shared.update(contentState(from:))`. Add `reconcileFromStore(trainingManager:)` that reads the store and writes completed sets’ weight/reps into `TrainingManager.weights` (via existing `updateWeight`) + `completedSetIds`, then persists/syncs via the existing `saveWeightsToDatabase`. Call it on app foreground (`scenePhase`) and on the Darwin notification (Task 9).

- [ ] **Step 4: Build + commit**

Run the build command. Expected `BUILD SUCCEEDED`.
```bash
git add bulkup/ViewModels bulkup.xcodeproj
git commit -m "feat(widget): seed SharedWorkoutStore, map to ContentState, reconcile into weights"
```

- [ ] **Step 5: Regression check (CRITICAL)**

Manual: run a full in-app workout (no Lock Screen) — log weights, complete sets, finish — and confirm weights persist and sync exactly as before. This guards the weight-tracking core.

### Task 8: Darwin notification bridge (store → app reconcile)

**Files:** Modify `WorkoutSessionManager.swift` (or a small observer in `WorkoutActivityController`).

- [ ] **Step 1: Observe the Darwin notification**

```swift
import Foundation

extension WorkoutActivityController {
    func startObservingStore(_ onChange: @escaping () -> Void) {
        let name = SharedWorkoutStore.darwinName as CFString
        let center = CFNotificationCenterGetDarwinNotifyCenter()
        CFNotificationCenterAddObserver(
            center, Unmanaged.passUnretained(self).toOpaque(),
            { _, _, _, _, _ in
                NotificationCenter.default.post(name: .liveWorkoutStoreChanged, object: nil)
            },
            CFNotificationName(name).rawValue, nil, .deliverImmediately
        )
    }
}
extension Notification.Name { static let liveWorkoutStoreChanged = Notification.Name("liveWorkoutStoreChanged") }
```
The app observes `.liveWorkoutStoreChanged` and calls `reconcileFromStore` + refreshes published state. Intents (Task 9) post the Darwin notification after mutating the store via `CFNotificationCenterPostNotification`.

- [ ] **Step 2: Build + commit**

Run the build command. Expected `BUILD SUCCEEDED`.
```bash
git add bulkup/ViewModels bulkup.xcodeproj
git commit -m "feat(widget): Darwin-notification bridge for store changes"
```

---

## PHASE 3 — Interactive buttons

### Task 9: LiveActivityIntents (shared)

**Files:** Create `bulkup/Shared/WorkoutLiveActivityIntents.swift` (BOTH targets).

- [ ] **Step 1: Write the intents**

```swift
import AppIntents
import Foundation

private func notifyStoreChanged() {
    CFNotificationCenterPostNotification(
        CFNotificationCenterGetDarwinNotifyCenter(),
        CFNotificationName(SharedWorkoutStore.darwinName as CFString), nil, nil, true
    )
}

struct CompleteCurrentSetIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "Complete set"
    func perform() async throws -> some IntentResult {
        SharedWorkoutStore.completeCurrentSet(); notifyStoreChanged(); return .result()
    }
}
struct AdjustWeightIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "Adjust weight"
    @Parameter(title: "Delta") var delta: Double
    init() {}; init(delta: Double) { self.delta = delta }
    func perform() async throws -> some IntentResult {
        SharedWorkoutStore.adjustWeight(delta); notifyStoreChanged(); return .result()
    }
}
struct AdjustRepsIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "Adjust reps"
    @Parameter(title: "Delta") var delta: Int
    init() {}; init(delta: Int) { self.delta = delta }
    func perform() async throws -> some IntentResult {
        SharedWorkoutStore.adjustReps(delta); notifyStoreChanged(); return .result()
    }
}
struct SkipRestIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "Skip rest"
    func perform() async throws -> some IntentResult { SharedWorkoutStore.skipRest(); notifyStoreChanged(); return .result() }
}
struct AddRestIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "Add rest"
    @Parameter(title: "Seconds") var seconds: Int
    init() {}; init(seconds: Int) { self.seconds = seconds }
    func perform() async throws -> some IntentResult { SharedWorkoutStore.addRest(seconds); notifyStoreChanged(); return .result() }
}
```

> NOTE: the intent must also call `WorkoutActivityController.shared.update(...)` so the activity re-renders when the app is alive; when the app is suspended, the app reconciles + updates on the next Darwin wake. Reload the activity content by re-deriving `ContentState` from the store inside the app’s store observer.

- [ ] **Step 2: Build + commit**

Run the build command. Expected `BUILD SUCCEEDED`.
```bash
git add bulkup/Shared/WorkoutLiveActivityIntents.swift bulkup.xcodeproj
git commit -m "feat(widget): LiveActivity button intents"
```

### Task 10: Context-aware interactive Lock Screen layout

**Files:** Modify `BulkUpWidgets/WorkoutLiveActivity.swift`.

- [ ] **Step 1: Add buttons to the Lock Screen view**

Replace the during-set / during-rest branches in `WorkoutLockScreenView` with interactive controls:

```swift
// During a set:
HStack(spacing: 12) {
    Button(intent: AdjustWeightIntent(delta: -state.weightStepFallback)) { Image(systemName: "minus") }
    Text("\(formatWeight(state.weight)) \(state.weightUnit)").monospacedDigit()
    Button(intent: AdjustWeightIntent(delta: state.weightStepFallback)) { Image(systemName: "plus") }
}
HStack(spacing: 12) {
    Button(intent: AdjustRepsIntent(delta: -1)) { Image(systemName: "minus") }
    Text("\(state.reps) reps").monospacedDigit()
    Button(intent: AdjustRepsIntent(delta: 1)) { Image(systemName: "plus") }
}
Button(intent: CompleteCurrentSetIntent()) { Label("Complete set", systemImage: "checkmark.circle.fill") }
    .buttonStyle(.borderedProminent).tint(.green)

// During rest:
HStack {
    Button(intent: SkipRestIntent()) { Text("Skip") }
    Button(intent: AddRestIntent(seconds: 30)) { Text("+30s") }
}
```
Use a fixed step (`2.5` kg / `5` lb) constant in the widget since `ContentState` carries `weightUnit`; add a `weightStepFallback` computed on the state (`weightUnit == "lb" ? 5 : 2.5`).

- [ ] **Step 2: Build + commit**

Run the build command. Expected `BUILD SUCCEEDED`.
```bash
git add BulkUpWidgets bulkup.xcodeproj
git commit -m "feat(widget): interactive Lock Screen controls (complete set, weight/reps ±, rest)"
```

- [ ] **Step 3: Full manual verification**

On device (Live Activities + App Intent buttons need a real device for full fidelity; simulator covers most): start a workout, lock the phone, use every button — weight/reps steppers change the displayed values, Complete set advances the cursor and starts the rest countdown, Skip/+30s adjust rest. Reopen the app and confirm the completed sets’ weights/reps persisted into the plan (reconciliation) and synced.

---

## Self-Review (completed during planning)

- **Spec coverage:** new target + App Group → Tasks 1–2; attributes/ContentState → Task 3; read-only Lock Screen + minimal Dynamic Island → Task 4; auto start/end → Task 5; SharedWorkoutStore source of truth + cursor → Task 6; refactor + reconcile → Tasks 7–8; intents + interactive layout (complete set, weight/reps ±, rest) → Tasks 9–10; timers via `Text(timerInterval:)` → Tasks 4/10; permission/orphan handling → Task 5 controller; testing self-check → Task 6; phasing → matches spec’s 3 phases. All spec sections mapped.
- **Placeholder scan:** manual Xcode steps (Tasks 1–2) are genuinely manual and labeled as such; all code tasks contain real code. The refactor steps (7) reference existing methods (`buildSummary`, `parseReps`, `updateWeight`, `saveWeightsToDatabase`, `weights`) that exist in `WorkoutSessionManager`/`TrainingManager`.
- **Type consistency:** `WorkoutActivityAttributes.ContentState`, `LiveWorkout`/`LiveSet`, `SharedWorkoutStore` mutation names (`completeCurrentSet`/`adjustWeight`/`adjustReps`/`skipRest`/`addRest`), `WorkoutActivityController.contentState(from:)`, and `SharedWorkoutStore.darwinName` are used consistently across tasks.
