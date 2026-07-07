//
//  WorkoutActivityController.swift
//  bulkup
//
//  Manages the Live Activity lifecycle for the active workout session.
//  Creates, updates, and ends the Lock Screen / Dynamic Island activity.
//

import ActivityKit
import Foundation

@MainActor
final class WorkoutActivityController {
    static let shared = WorkoutActivityController()

    private var activity: Activity<WorkoutActivityAttributes>?

    // MARK: - Lifecycle

    func start(dayName: String, state: WorkoutActivityAttributes.ContentState) {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            print("[WorkoutActivityController] Live Activities are disabled.")
            return
        }
        endStaleActivities()

        do {
            let attributes = WorkoutActivityAttributes(dayName: dayName)
            let content = ActivityContent(state: state, staleDate: nil)
            activity = try Activity.request(attributes: attributes, content: content)
            print("[WorkoutActivityController] Started Live Activity: \(activity?.id ?? "?")")
        } catch {
            print("[WorkoutActivityController] Failed to start Live Activity: \(error)")
        }
    }

    func update(_ state: WorkoutActivityAttributes.ContentState) {
        Task {
            let content = ActivityContent(state: state, staleDate: nil)
            await activity?.update(content)
        }
    }

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

    func end() {
        for activity in Activity<WorkoutActivityAttributes>.activities {
            Task {
                await activity.end(nil, dismissalPolicy: .immediate)
            }
        }
        activity = nil
    }

    func endStaleActivities() {
        for stale in Activity<WorkoutActivityAttributes>.activities {
            Task {
                await stale.end(nil, dismissalPolicy: .immediate)
            }
        }
    }

    // MARK: - State Mapping

    static func contentState(from w: LiveWorkout) -> WorkoutActivityAttributes.ContentState {
        return .init(from: w)
    }
}
