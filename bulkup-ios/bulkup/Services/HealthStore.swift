//
//  HealthStore.swift
//  bulkup
//
//  The iPhone's HealthKit writer. The watch owns the workout when its live
//  session ran (heart rate, energy, ring credit); the phone writes a plain
//  strength workout only when no watch workout exists for the session, so a
//  user training from the phone alone still sees the workout in Fitness.
//

import Foundation
import HealthKit

@MainActor
final class HealthStore {
    static let shared = HealthStore()

    private let store = HKHealthStore()
    private let workoutType = HKObjectType.workoutType()
    private let energyType = HKQuantityType(.activeEnergyBurned)

    /// Our own apps' source bundle ids share this prefix (iPhone and watch).
    static let bundlePrefix = "com.whitesolutions.bulkup"

    var isAvailable: Bool { HKHealthStore.isHealthDataAvailable() }

    /// Ask once; a no-op after the user has answered. Called when a workout
    /// starts from the UI so the sheet never lands on top of the summary.
    func requestAuthorizationIfNeeded() async {
        guard isAvailable,
              store.authorizationStatus(for: workoutType) == .notDetermined else { return }
        do {
            try await store.requestAuthorization(toShare: [workoutType, energyType], read: [workoutType])
        } catch {
            AppLogger.shared.warning("HealthKit: authorization request failed: \(error.localizedDescription)")
        }
    }

    /// One finished BulkUp session, as the phone knows it.
    struct Session {
        var start: Date
        var end: Date
        var pauses: [DateInterval]
        var activeEnergyKcal: Double?
    }

    /// Saves the session as a strength workout unless a BulkUp workout already
    /// covers it. Waits a moment first so a paired watch that is finishing the
    /// same session gets to save its richer workout and win the dedupe.
    func saveWorkoutIfNeeded(_ session: Session, graceSeconds: Double = 6) async {
        guard isAvailable else { return }
        await requestAuthorizationIfNeeded()
        guard store.authorizationStatus(for: workoutType) == .sharingAuthorized else {
            AppLogger.shared.info("HealthKit: workout sharing not authorized; skipping save")
            return
        }
        guard session.end > session.start else { return }

        if graceSeconds > 0 {
            try? await Task.sleep(nanoseconds: UInt64(graceSeconds * 1_000_000_000))
        }
        if await hasBulkUpWorkout(overlapping: DateInterval(start: session.start, end: session.end)) {
            AppLogger.shared.info("HealthKit: a BulkUp workout already covers this session; not duplicating")
            return
        }

        do {
            let config = HKWorkoutConfiguration()
            config.activityType = .traditionalStrengthTraining
            config.locationType = .indoor
            let builder = HKWorkoutBuilder(healthStore: store, configuration: config, device: .local())
            try await builder.beginCollection(at: session.start)

            var events: [HKWorkoutEvent] = []
            for pause in session.pauses where pause.duration > 0 {
                events.append(HKWorkoutEvent(type: .pause, dateInterval: DateInterval(start: pause.start, duration: 0), metadata: nil))
                events.append(HKWorkoutEvent(type: .resume, dateInterval: DateInterval(start: pause.end, duration: 0), metadata: nil))
            }
            if !events.isEmpty { try await builder.addWorkoutEvents(events) }

            if let kcal = session.activeEnergyKcal, kcal > 0 {
                let sample = HKQuantitySample(
                    type: energyType,
                    quantity: HKQuantity(unit: .kilocalorie(), doubleValue: kcal),
                    start: session.start, end: session.end
                )
                try await builder.addSamples([sample])
            }

            try await builder.endCollection(at: session.end)
            _ = try await builder.finishWorkout()
            AppLogger.shared.info("HealthKit: strength workout saved from the phone")
        } catch {
            AppLogger.shared.error("HealthKit: saving the workout failed: \(error.localizedDescription)")
        }
    }

    /// True when any BulkUp app (phone or watch) already saved a workout that
    /// overlaps the interval. Reading our own writes needs no permission; the
    /// watch's need read access, which the authorization request asks for.
    func hasBulkUpWorkout(overlapping interval: DateInterval) async -> Bool {
        let predicate = HKQuery.predicateForSamples(withStart: interval.start, end: interval.end, options: [])
        let samples: [HKSample] = await withCheckedContinuation { cont in
            let query = HKSampleQuery(sampleType: workoutType, predicate: predicate, limit: 20, sortDescriptors: nil) { _, result, _ in
                cont.resume(returning: result ?? [])
            }
            store.execute(query)
        }
        return samples.contains { $0.sourceRevision.source.bundleIdentifier.hasPrefix(Self.bundlePrefix) }
    }
}
