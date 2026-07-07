import ActivityKit
import AppIntents
import Foundation

private func notifyStoreChanged() {
    CFNotificationCenterPostNotification(
        CFNotificationCenterGetDarwinNotifyCenter(),
        CFNotificationName(SharedWorkoutStore.darwinName as CFString), nil, nil, true
    )
}

@available(iOS 16.1, *)
private func refreshActivity() async {
    guard let w = SharedWorkoutStore.load() else { return }
    let content = ActivityContent(state: WorkoutActivityAttributes.ContentState(from: w), staleDate: nil)
    for activity in Activity<WorkoutActivityAttributes>.activities {
        await activity.update(content)
    }
}

struct CompleteCurrentSetIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "Complete set"
    func perform() async throws -> some IntentResult {
        SharedWorkoutStore.completeCurrentSet()
        notifyStoreChanged()
        await refreshActivity()
        return .result()
    }
}

struct AdjustWeightIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "Adjust weight"
    @Parameter(title: "Delta") var delta: Double
    init() {}
    init(delta: Double) { self.delta = delta }
    func perform() async throws -> some IntentResult {
        // No Darwin notify: a transient weight tweak doesn't need to wake the app
        // to reconcile (avoids a second activity update + contention → snappier tap).
        // The final value is reconciled on set completion / app foreground.
        SharedWorkoutStore.adjustWeight(delta)
        await refreshActivity()
        return .result()
    }
}

struct AdjustRepsIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "Adjust reps"
    @Parameter(title: "Delta") var delta: Int
    init() {}
    init(delta: Int) { self.delta = delta }
    func perform() async throws -> some IntentResult {
        // No Darwin notify (see AdjustWeightIntent): keeps the ± tap snappy.
        SharedWorkoutStore.adjustReps(delta)
        await refreshActivity()
        return .result()
    }
}

struct SkipRestIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "Skip rest"
    func perform() async throws -> some IntentResult {
        SharedWorkoutStore.skipRest()
        notifyStoreChanged()
        await refreshActivity()
        return .result()
    }
}

struct AddRestIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "Add rest"
    @Parameter(title: "Seconds") var seconds: Int
    init() {}
    init(seconds: Int) { self.seconds = seconds }
    func perform() async throws -> some IntentResult {
        SharedWorkoutStore.addRest(seconds)
        notifyStoreChanged()
        await refreshActivity()
        return .result()
    }
}
