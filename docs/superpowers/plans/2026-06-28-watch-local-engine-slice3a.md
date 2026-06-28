# Apple Watch Slice 3a — Watch local workout engine Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development. Steps use checkbox (`- [ ]`) syntax.

**Goal:** Give the watch a local `LiveWorkout` working copy it mutates optimistically (instant UI), still sending each action to the phone; the phone's broadcast stays authoritative and reconciles.

**Architecture:** Move the workout mutation logic onto `LiveWorkout` as `mutating` methods (DRY: `SharedWorkoutStore` statics become load→mutate→save wrappers; the watch mutates an in-memory copy). The watch holds `@Published var live`, applies actions optimistically + sends them, and adopts the phone's `live` on each broadcast.

**Tech Stack:** SwiftUI (watchOS), WatchConnectivity, the shared `LiveWorkout` model.

## Global Constraints
- `bulkup` repo, branch `feat/watch-local-engine` — **stacked on Slice 2** (`feat/watch-healthkit`/#41); merges after #41.
- ENV: not buildable here (watchOS needs a real device for HealthKit, but 3a is engine/UI — verified by code review + the project's DEBUG `runSelfCheck()` for the shared logic; user builds in Xcode). SourceKit cross-module/"No such module" errors are spurious.
- Phone side and backend are UNCHANGED. The watch is still not a backend writer.
- Refactor must keep `SharedWorkoutStore`'s static-mutation external behavior IDENTICAL (load→mutate→save).
- `finishWorkout` stays on the existing `wc.send(.finishWorkout(metrics:))` path (offline finish-sync is Slice 3b).
- Lime accent `Color(red: 0.518, green: 0.800, blue: 0.086)`.

---

## Task 1: Refactor mutations to `LiveWorkout` instance methods

**Files:**
- Modify: `bulkup/Shared/SharedWorkoutStore.swift` (add `LiveWorkout` `mutating` methods; rewrite the 5 statics as wrappers; extend `runSelfCheck`)

**Interfaces:**
- Produces: `LiveWorkout.{completeCurrentSet(),adjustWeight(_:),adjustReps(_:),skipRest(),addRest(_:)}` (all `mutating`)

- [ ] **Step 1: Add the `LiveWorkout` mutating methods**

In `bulkup/Shared/SharedWorkoutStore.swift`, add to the `LiveWorkout` struct (after `advanceCursor()`):

```swift
    mutating func completeCurrentSet() {
        guard let s0 = current else { return }
        var s = s0
        s.completed = true
        sets[cursor] = s
        restEndDate = s.restSeconds > 0 ? Date().addingTimeInterval(TimeInterval(s.restSeconds)) : nil
        advanceCursor()
    }
    mutating func adjustWeight(_ delta: Double) {
        guard current != nil else { return }
        sets[cursor].weight = max(0, sets[cursor].weight + delta)
    }
    mutating func adjustReps(_ delta: Int) {
        guard current != nil else { return }
        sets[cursor].reps = max(0, sets[cursor].reps + delta)
    }
    mutating func skipRest() { restEndDate = nil }
    mutating func addRest(_ seconds: Int) {
        restEndDate = (restEndDate ?? Date()).addingTimeInterval(TimeInterval(seconds))
    }
```

- [ ] **Step 2: Rewrite the `SharedWorkoutStore` statics as wrappers**

Replace the five static mutations (currently `completeCurrentSet`/`adjustWeight`/`adjustReps`/`skipRest`/`addRest`) with:

```swift
    static func completeCurrentSet() { guard var w = load() else { return }; w.completeCurrentSet(); save(w) }
    static func adjustWeight(_ delta: Double) { guard var w = load() else { return }; w.adjustWeight(delta); save(w) }
    static func adjustReps(_ delta: Int) { guard var w = load() else { return }; w.adjustReps(delta); save(w) }
    static func skipRest() { guard var w = load() else { return }; w.skipRest(); save(w) }
    static func addRest(_ seconds: Int) { guard var w = load() else { return }; w.addRest(seconds); save(w) }
```

(Behavior is identical: the old code did `guard var w = load()...` then the same mutation then `save(w)`. The `completeCurrentSet` old static also guarded `let s0 = w.current` — that guard now lives inside the instance method, so the wrapper's `guard var w = load()` is sufficient.)

- [ ] **Step 3: Extend `runSelfCheck` with instance-method asserts**

In `SharedWorkoutStore.runSelfCheck()` (DEBUG), append before the closing brace:

```swift
        // Slice 3a: LiveWorkout instance mutations.
        var lm = LiveWorkout(
            dayName: "Lunes", workoutName: "Push", startDate: Date(), isPaused: false,
            weightUnit: "kg", weightStep: 2.5, repStep: 1,
            sets: [
                .init(exerciseIndex: 0, exerciseName: "Press", setIndex: 0, setsTotalForExercise: 2,
                      weight: 40, reps: 10, restSeconds: 90, completed: false),
                .init(exerciseIndex: 0, exerciseName: "Press", setIndex: 1, setsTotalForExercise: 2,
                      weight: 40, reps: 10, restSeconds: 0, completed: false),
            ],
            cursor: 0, restEndDate: nil)
        lm.completeCurrentSet()
        assert(lm.sets[0].completed && lm.cursor == 1 && lm.restEndDate != nil, "complete advances + sets rest")
        lm.adjustWeight(-1000)
        assert(lm.sets[1].weight == 0, "weight clamps at 0")
        lm.adjustReps(5)
        assert(lm.sets[1].reps == 15, "reps adjust")
        lm.skipRest()
        assert(lm.restEndDate == nil, "skipRest nils restEndDate")
        lm.addRest(30)
        assert(lm.restEndDate != nil, "addRest sets restEndDate")
        lm.completeCurrentSet()
        assert(lm.isFinished, "second complete -> finished")
```

- [ ] **Step 4: Verify**

User builds the iOS app — no assertion crash at launch (the wrappers + instance methods compile; existing store-level asserts + the new instance asserts all hold). Agent: hand-trace the asserts and state expected results in the report.

- [ ] **Step 5: Commit**

```bash
git add bulkup/Shared/SharedWorkoutStore.swift
git commit -m "refactor(watch): LiveWorkout instance mutations; store statics wrap them"
```

---

## Task 2: Watch engine — optimistic `live` + action methods

**Files:**
- Modify: `BulkUpWatch Watch App/WatchWCManager.swift`

**Interfaces:**
- Consumes: `LiveWorkout.{completeCurrentSet,adjustWeight,adjustReps,skipRest,addRest}` (Task 1)
- Produces: `WatchWCManager.live` (`@Published LiveWorkout?`), `.completeSet()`, `.adjustWeight(_:)`, `.adjustReps(_:)`, `.skipRest()`, `.addRest(_:)`

- [ ] **Step 1: Add the working copy + adopt-on-broadcast**

In `WatchWCManager`, add the property (after `@Published var ctx`):

```swift
    @Published var live: LiveWorkout?
```

In `apply(_ data:)`, after `ctx = next`, adopt the authoritative live:

```swift
        ctx = next
        live = next.live
```

- [ ] **Step 2: Add the optimistic action methods**

Add to `WatchWCManager` (after `send(_:)`):

```swift
    // Optimistic: mutate the local working copy for instant UI, and send the action to
    // the phone (which stays authoritative — its next broadcast reconciles `live`).
    func completeSet() { live?.completeCurrentSet(); send(.completeSet) }
    func adjustWeight(_ d: Double) { live?.adjustWeight(d); send(.adjustWeight(delta: d)) }
    func adjustReps(_ d: Int) { live?.adjustReps(d); send(.adjustReps(delta: d)) }
    func skipRest() { live?.skipRest(); send(.skipRest) }
    func addRest(_ s: Int) { live?.addRest(s); send(.addRest(seconds: s)) }
```

- [ ] **Step 2b: Verify**

Read-through: `live` is adopted from every broadcast (authoritative); the action methods mutate `live` then send; `send` is unchanged (sendMessage when reachable, else transferUserInfo). State this in the report.

- [ ] **Step 3: Commit**

```bash
git add "BulkUpWatch Watch App/WatchWCManager.swift"
git commit -m "feat(watch): local LiveWorkout working copy + optimistic action methods"
```

---

## Task 3: Watch views read the working copy + call the manager

**Files:**
- Modify: `BulkUpWatch Watch App/RootView.swift`
- Modify: `BulkUpWatch Watch App/ActiveWorkoutView.swift`
- Modify: `BulkUpWatch Watch App/RestTimerView.swift`

**Interfaces:**
- Consumes: `WatchWCManager.{live, completeSet, adjustWeight, adjustReps, skipRest, addRest}` (Task 2)

- [ ] **Step 1: `RootView` routes on `wc.live`**

In `BulkUpWatch Watch App/RootView.swift`, change the first branch from `wc.ctx?.live` to `wc.live`:

```swift
        if let live = wc.live, !live.isFinished {
            ActiveWorkoutView(live: live)
        } else if let plan = wc.ctx?.todaysPlan, !plan.exercises.isEmpty {
            TodayView(plan: plan)
        } else {
            VStack(spacing: 8) {
                Image(systemName: "iphone").font(.title2)
                Text("Open BulkUp on your iPhone").font(.footnote).multilineTextAlignment(.center)
            }.padding()
        }
```

- [ ] **Step 2: `ActiveWorkoutView` — steppers + complete call the manager; helper takes closures**

In `ActiveWorkoutView.swift`: change the two `stepper(...)` calls and the Complete-set button to call the manager, and change the `stepper` helper signature to take action closures. Replace the steppers block (lines ~30-38):

```swift
                        stepper(label: "\(fmt(s.weight)) \(live.weightUnit)",
                                minus: { wc.adjustWeight(-live.weightStep) },
                                plus: { wc.adjustWeight(live.weightStep) })
                        stepper(label: "\(s.reps) reps",
                                minus: { wc.adjustReps(-1) }, plus: { wc.adjustReps(1) })

                        Button { wc.completeSet() } label: {
                            Text("Complete set").frame(maxWidth: .infinity)
                        }.buttonStyle(.borderedProminent).tint(lime)
```

And replace the `stepper(...)` helper:

```swift
    private func stepper(label: String, minus: @escaping () -> Void, plus: @escaping () -> Void) -> some View {
        HStack {
            Button { minus() } label: { Image(systemName: "minus") }.buttonStyle(.bordered)
            Text(label).font(.body).monospacedDigit().frame(maxWidth: .infinity)
            Button { plus() } label: { Image(systemName: "plus") }.buttonStyle(.bordered)
        }
    }
```

(Leave the Finish button — `wc.send(.finishWorkout(metrics: m))` — and the HealthKit metrics row / `metrics.start()`/`end()` lifecycle UNCHANGED. Finish-over-sync is Slice 3b.)

- [ ] **Step 3: `RestTimerView` — Skip/+30s call the manager**

In `RestTimerView.swift`, change the two buttons:

```swift
            HStack {
                Button("Skip") { wc.skipRest() }.buttonStyle(.bordered)
                Button("+30s") { wc.addRest(30) }.buttonStyle(.bordered)
            }
```

- [ ] **Step 4: Verify (read-through; no build here)**

Confirm: `RootView` routes on `wc.live`; the steppers/complete/skip/+30s call `wc.*` (optimistic + send); the Finish button + HealthKit row unchanged; the `stepper` helper now takes closures and both call sites pass closures. State this in the report.

- [ ] **Step 5: Commit**

```bash
git add "BulkUpWatch Watch App/RootView.swift" "BulkUpWatch Watch App/ActiveWorkoutView.swift" "BulkUpWatch Watch App/RestTimerView.swift"
git commit -m "feat(watch): UI drives the local engine (optimistic), reads the working copy"
```

---

## Self-Review

**Spec coverage:** shared refactor → LiveWorkout instance methods + static wrappers + self-check (Task 1) · watch working copy + adopt-on-broadcast + optimistic action methods (Task 2) · views read `wc.live` and call the manager, with finish/HealthKit untouched (Task 3). Phone/backend unchanged (no task — by design). 3b (offline finish-sync) + offline cold-start correctly deferred.

**Placeholder scan:** No TBD/TODO. Every code step shows complete code.

**Type consistency:** `LiveWorkout.{completeCurrentSet,adjustWeight,adjustReps,skipRest,addRest}` (Task 1) are the exact names `WatchWCManager` (Task 2) and the views (Task 3) call; `WatchWCManager.{live, completeSet, adjustWeight, adjustReps, skipRest, addRest}` are referenced consistently. The `stepper` helper's new closure signature matches both call sites.
