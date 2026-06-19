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
        let currentSet = w.current
        let isResting = w.restEndDate.map { $0 > Date() } ?? false

        return WorkoutActivityAttributes.ContentState(
            workoutName: w.workoutName,
            startDate: w.startDate,
            isPaused: w.isPaused,
            exerciseName: currentSet?.exerciseName ?? "",
            setIndex: currentSet?.setIndex ?? 0,
            setsTotal: currentSet?.setsTotalForExercise ?? 0,
            weight: currentSet?.weight ?? 0,
            reps: currentSet?.reps ?? 0,
            weightUnit: w.weightUnit,
            completedSets: w.completedCount,
            totalSets: w.sets.count,
            isResting: isResting,
            restEndDate: w.restEndDate,
            isFinished: w.isFinished
        )
    }
}
