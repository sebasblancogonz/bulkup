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
    init() {}
    init(delta: Double) { self.delta = delta }
    func perform() async throws -> some IntentResult {
        SharedWorkoutStore.adjustWeight(delta); notifyStoreChanged(); return .result()
    }
}

struct AdjustRepsIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "Adjust reps"
    @Parameter(title: "Delta") var delta: Int
    init() {}
    init(delta: Int) { self.delta = delta }
    func perform() async throws -> some IntentResult {
        SharedWorkoutStore.adjustReps(delta); notifyStoreChanged(); return .result()
    }
}

struct SkipRestIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "Skip rest"
    func perform() async throws -> some IntentResult {
        SharedWorkoutStore.skipRest(); notifyStoreChanged(); return .result()
    }
}

struct AddRestIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "Add rest"
    @Parameter(title: "Seconds") var seconds: Int
    init() {}
    init(seconds: Int) { self.seconds = seconds }
    func perform() async throws -> some IntentResult {
        SharedWorkoutStore.addRest(seconds); notifyStoreChanged(); return .result()
    }
}
