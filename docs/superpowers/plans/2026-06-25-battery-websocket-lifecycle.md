# Battery: WebSocket lifecycle + reconnect cap + stop pulse animation

> **For agentic workers:** REQUIRED SUB-SKILL: superpowers:subagent-driven-development.

**Goal:** Stop the Gotify WebSocket from surviving backgrounding (and reconnecting forever), and stop the workout-header pulse animation when it leaves screen. Addresses battery/overheat root causes #1, #2, and the cheap part of #3.

**Architecture:** iOS app only, no backend, no new deps. One cohesive task across the WebSocket manager, the two plan-creation views, and the workout header.

## Global Constraints
- ENV: iOS CANNOT be compiled/run here. Verify by code-reading; user builds in Xcode. SourceKit cross-target / macOS-availability errors are spurious — NOT findings.
- The Gotify WebSocket is only used on the plan-creation screens; the actual "processing done" push still arrives via the system push when backgrounded, so disconnecting the in-app socket on background loses nothing.
- `disconnect()` must NOT remove the `GotifyNotificationReceived` NotificationCenter observer (that lives in the create views' `cleanupNotifications`); on background only the socket is torn down, so notifications still flow after reconnect.

---

## Task 1: WebSocket lifecycle + reconnect cap + animation stop

**Files:**
- Modify: `bulkup/ViewModels/GotifyWebSocketManager.swift` (connect signature + reset guard; reconnect call)
- Modify: `bulkup/Views/Components/Training/CreateTrainingPlanView.swift` (scenePhase)
- Modify: `bulkup/Views/Components/Diet/CreateDietPlanView.swift` (scenePhase)
- Modify: `bulkup/Views/Components/Training/ActiveWorkoutHeader.swift` (animation stop)

**Interfaces:**
- Produces: `GotifyWebSocketManager.connect(userId:isReconnect:)` with `isReconnect: Bool = false`

- [ ] **Step 1: Stop the reconnect loop from resetting its own cap (#2)**

In `GotifyWebSocketManager.swift`, change the `connect` signature (line 115):

```swift
    func connect(userId: String) {
```
to:
```swift
    func connect(userId: String, isReconnect: Bool = false) {
```

Then change the counter reset inside `connect()` (line 135):

```swift
        isIntentionalDisconnect = false
        reconnectAttempts = 0
```
to:
```swift
        isIntentionalDisconnect = false
        if !isReconnect { reconnectAttempts = 0 }
```

(The confirmed-connection block at ~line 154-156 already sets `reconnectAttempts = 0` on a successful open — leave it. So a user/view-initiated `connect()` starts fresh, an auto-reconnect preserves the count, and a successful connection resets it. The 5-attempt cap now actually terminates.)

Then in `attemptReconnect()`, change the reconnect call (line 244):

```swift
                self.connect(userId: self.currentUserId)
```
to:
```swift
                self.connect(userId: self.currentUserId, isReconnect: true)
```

- [ ] **Step 2: Disconnect the socket on background, reconnect on foreground — CreateTrainingPlanView (#1)**

In `CreateTrainingPlanView.swift`, add the scenePhase environment near the other `@Environment` declarations (after line 14 `@Environment(\.dismiss) var dismiss`):

```swift
    @Environment(\.scenePhase) private var scenePhase
```

Then add an `.onChange(of: scenePhase)` modifier next to the existing `.onAppear { setupNotificationObserver() ... }` (the `.onAppear` at line 246). Add it immediately after that `.onAppear { ... }` block:

```swift
        .onChange(of: scenePhase) { _, phase in
            switch phase {
            case .background:
                GotifyWebSocketManager.shared.disconnect()
            case .active:
                if let userId = authManager.user?.id {
                    GotifyWebSocketManager.shared.connect(userId: userId)
                }
            default:
                break
            }
        }
```

(Do NOT call `cleanupNotifications()` here — that would remove the notification observer. Only the socket is toggled.)

- [ ] **Step 3: Same scenePhase handling — CreateDietPlanView (#1)**

In `CreateDietPlanView.swift`, add near the other `@Environment` declarations (after line 14):

```swift
    @Environment(\.scenePhase) private var scenePhase
```

Then add immediately after the existing `.onAppear { setupNotificationObserver() ... }` block (line 170):

```swift
        .onChange(of: scenePhase) { _, phase in
            switch phase {
            case .background:
                GotifyWebSocketManager.shared.disconnect()
            case .active:
                if let userId = authManager.user?.id {
                    GotifyWebSocketManager.shared.connect(userId: userId)
                }
            default:
                break
            }
        }
```

- [ ] **Step 4: Stop the pulse animation when the header leaves screen (#3)**

In `ActiveWorkoutHeader.swift`, find `.onAppear { pulseAnimation = true }` (line ~67) and add an `.onDisappear` right after it:

```swift
        .onAppear { pulseAnimation = true }
        .onDisappear { pulseAnimation = false }
```

- [ ] **Step 5: Verify (read-through; no build)**

Confirm:
- `connect()` no longer zeroes `reconnectAttempts` when `isReconnect: true`; `attemptReconnect` passes `isReconnect: true`; a successful connection still resets the count; so after 5 failed reconnects the loop stops.
- Both create views disconnect the socket on `.background` and reconnect on `.active`; neither removes the notification observer on background; `.onDisappear` still calls `cleanupNotifications()` (full teardown) unchanged.
- `scenePhase` env var compiles (added to both views).
- Header pulse stops on `.onDisappear`.
State this trace in the report.

- [ ] **Step 6: Commit**

```bash
git add bulkup/ViewModels/GotifyWebSocketManager.swift bulkup/Views/Components/Training/CreateTrainingPlanView.swift bulkup/Views/Components/Diet/CreateDietPlanView.swift bulkup/Views/Components/Training/ActiveWorkoutHeader.swift
git commit -m "fix(battery): disconnect Gotify socket on background, cap reconnects, stop workout pulse on disappear"
```

---

## Self-Review
- #1 (socket survives background) → Steps 2-3. #2 (reconnect never gives up) → Step 1. #3-animation → Step 4.
- No placeholders. The scenePhase blocks are identical across the two views by design (same socket lifecycle); duplicating ~10 lines is cheaper than a shared modifier for two sites.
- `connect(userId:isReconnect:)` signature is consistent between Step 1's definition and the `attemptReconnect` call site.
