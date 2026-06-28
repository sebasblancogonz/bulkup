# Apple Watch Slice 3a — Watch local workout engine — Design

**Date:** 2026-06-28
**Scope:** Give the watch a **local working copy** of the `LiveWorkout` that it mutates **optimistically** (instant UI), while still sending each action to the phone; when the phone is reachable, its broadcast remains authoritative and reconciles. Foundation for the offline-resilient standalone (Slice 3a of the "Option A" decomposition: 3a engine → 3b offline finish-sync).

**Stacking:** branched on top of Slice 2 (`feat/watch-healthkit`, PR #41). It must merge **after** #41 (or be rebased onto main once #41 lands).

---

## Goals
- The watch UI advances immediately on a tap (no round-trip lag) by applying the action to a local `LiveWorkout` copy.
- The watch still sends each action to the phone; the phone stays authoritative and its next broadcast reconciles the watch (adopt-on-receive).
- A clean DRY refactor: the workout mutation logic lives on `LiveWorkout` as `mutating` methods, used by both `SharedWorkoutStore` (phone/widget App-Group store) and the watch's in-memory copy.

## Non-goals (later)
- **3b:** offline finish + reconciliation (watch pushes its full authoritative `LiveWorkout` so the phone saves a workout it didn't witness). Not here.
- **Offline cold-start** (start a workout with the phone never present) — out of scope for Option A entirely (worst reconciliation).
- No phone-side behavior change; no backend change.

## Decisions (locked)
- Option A (phone stays backend writer); build 3a first.

---

## Components

### Shared refactor — `bulkup/Shared/SharedWorkoutStore.swift`
Move the five mutation bodies from `SharedWorkoutStore`'s statics onto `LiveWorkout` as `mutating` methods (behavior **identical** to today):

```swift
extension LiveWorkout {
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
}
```

`SharedWorkoutStore`'s statics become thin wrappers (same external behavior — load → mutate → save):

```swift
    static func completeCurrentSet() { guard var w = load() else { return }; w.completeCurrentSet(); save(w) }
    static func adjustWeight(_ delta: Double) { guard var w = load() else { return }; w.adjustWeight(delta); save(w) }
    static func adjustReps(_ delta: Int) { guard var w = load() else { return }; w.adjustReps(delta); save(w) }
    static func skipRest() { guard var w = load() else { return }; w.skipRest(); save(w) }
    static func addRest(_ seconds: Int) { guard var w = load() else { return }; w.addRest(seconds); save(w) }
```

`SharedWorkoutStore.runSelfCheck()` gains asserts on the instance methods: `completeCurrentSet()` marks the current set completed, sets `restEndDate` (when restSeconds>0), and advances the cursor; `adjustWeight(-1000)` clamps to 0; `skipRest()` nils `restEndDate`. (`LiveWorkout.advanceCursor()` already exists.)

### Watch engine — `BulkUpWatch Watch App/WatchWCManager.swift`
- Add `@Published var live: LiveWorkout?` — the watch's working copy.
- On `apply(context)` (broadcast received): `ctx = next; live = next.live` — adopt the phone's authoritative `live` (overwrites any optimistic local state; converges).
- Add optimistic action methods that mutate `live` **and** send the action:
```swift
    func completeSet() { live?.completeCurrentSet(); send(.completeSet) }
    func adjustWeight(_ d: Double) { live?.adjustWeight(d); send(.adjustWeight(delta: d)) }
    func adjustReps(_ d: Int) { live?.adjustReps(d); send(.adjustReps(delta: d)) }
    func skipRest() { live?.skipRest(); send(.skipRest) }
    func addRest(_ s: Int) { live?.addRest(s); send(.addRest(seconds: s)) }
```
(Keep `send(_:)` as-is — it already prefers `sendMessage` when reachable, else queues `transferUserInfo`. So offline, the optimistic local apply stands and the action is queued for the phone — laying the groundwork for 3b. `finishWorkout` stays on the existing `wc.send(.finishWorkout(metrics:))` path from Slice 2 for now.)

### Watch views — read the working copy + call the manager
- `RootView.swift`: route on `wc.live` instead of `wc.ctx?.live` (still `wc.ctx?.todaysPlan` for the TodayView branch). Since `live` is `@Published`, optimistic mutations re-render the tree.
- `ActiveWorkoutView.swift`: the steppers/complete-set/skip/+30s call the manager methods (`wc.completeSet()`, `wc.adjustWeight(±live.weightStep)`, `wc.adjustReps(±1)`) instead of `wc.send(.adjustWeight(...))` etc. The `stepper(...)` helper changes from taking a `WatchMessage` to taking an action closure. (Finish + the HealthKit metrics row from Slice 2 are unchanged.)
- `RestTimerView` Skip/+30s call `wc.skipRest()` / `wc.addRest(30)`.

### Phone — unchanged
The phone still receives the same `WatchMessage`s, mutates the App-Group store, reconciles, and broadcasts. No edits.

---

## Data flow (complete a set, phone reachable)
1. Tap → `wc.completeSet()` → `live.completeCurrentSet()` (cursor advances locally, rest starts) → UI updates instantly → `send(.completeSet)`.
2. Phone applies `.completeSet` + reconciles + broadcasts a fresh `WatchContext` (higher `seq`).
3. Watch `apply` adopts the phone's `live` (authoritative) → converges (matches the optimistic state; the `restEndDate` adopts the phone's exact value).

## Data flow (phone briefly unreachable)
- Optimistic applies advance the local `live`; the actions queue via `transferUserInfo`. No broadcast arrives, so the local copy is the truth until the phone reconnects and replays the queued actions (then broadcasts → adopt). 3a does NOT yet handle finishing while offline (3b) — but the engine + queue make the in-progress workout usable through a brief drop.

## Error handling
- `live == nil` (no active workout): action methods no-op (optional chaining); no crash.
- Idempotency: `.completeSet` is cursor-based on both sides — optimistic-then-authoritative can't double-complete; a replayed queued action completes the same set the phone is on.
- The `seq` dedupe is unchanged; the broadcast always wins on adopt.

## Testing
- `SharedWorkoutStore.runSelfCheck()` (DEBUG) extended for the new instance methods (complete advances + sets rest; adjust clamps; skip nils rest). Wired already into `BulkUp.swift`.
- The `SharedWorkoutStore` static wrappers keep identical behavior (the existing store-level asserts still hold).
- Watch UI optimism is not unit-testable here (no watchOS build); USER verifies on the watch sim/device: taps advance instantly; with the phone reachable the state stays consistent after each broadcast.

## Decomposition (Option A)
- **3a (this):** local engine + optimistic apply, phone authoritative.
- **3b:** offline finish + reconciliation — the watch sends its full authoritative `LiveWorkout` on finish/reconnect; the phone adopts + saves; persists a phone-absent workout.
