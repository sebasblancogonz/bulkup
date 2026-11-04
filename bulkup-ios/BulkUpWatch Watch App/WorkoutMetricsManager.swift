import Foundation
import HealthKit
internal import Combine

/// Owns the watch HKWorkoutSession + live builder: live HR/energy for the UI, and
/// avg/max HR + total active energy captured at finish. Watch-only.
@MainActor
final class WorkoutMetricsManager: NSObject, ObservableObject {
    @Published var heartRate: Int = 0
    @Published var activeEnergy: Double = 0   // kcal
    @Published var isRunning = false

    private let store = HKHealthStore()
    private var session: HKWorkoutSession?
    private var builder: HKLiveWorkoutBuilder?
    private var sessionStart: Date?
    /// The iPhone writes its own strength workout when it believes the watch
    /// didn't run; both apps share this bundle prefix.
    nonisolated private static let bundlePrefix = "com.whitesolutions.bulkup"

    // nonisolated: read from the nonisolated HKLiveWorkoutBuilderDelegate callback
    // (HKQuantityType is Sendable). Needed under the watch target's MainActor-by-default.
    nonisolated private let hrType = HKQuantityType(.heartRate)
    nonisolated private let energyType = HKQuantityType(.activeEnergyBurned)

    func requestAuthorization() {
        guard HKHealthStore.isHealthDataAvailable() else { return }
        let share: Set = [HKQuantityType.workoutType(), energyType]
        // Workouts are read to spot one the iPhone already saved for this session.
        let read: Set<HKObjectType> = [hrType, energyType, HKObjectType.workoutType()]
        store.requestAuthorization(toShare: share, read: read) { _, _ in }
    }

    func start() {
        #if DEBUG
        if WatchDesignPreview.isActive {
            heartRate = 142
            activeEnergy = 186
            isRunning = true
            return
        }
        #endif
        guard HKHealthStore.isHealthDataAvailable(), session == nil else { return }
        heartRate = 0
        activeEnergy = 0
        let config = HKWorkoutConfiguration()
        config.activityType = .traditionalStrengthTraining
        config.locationType = .indoor
        do {
            let s = try HKWorkoutSession(healthStore: store, configuration: config)
            let b = s.associatedWorkoutBuilder()
            b.dataSource = HKLiveWorkoutDataSource(healthStore: store, workoutConfiguration: config)
            s.delegate = self
            b.delegate = self
            session = s
            builder = b
            let start = Date()
            sessionStart = start
            s.startActivity(with: start)
            b.beginCollection(withStart: start) { _, _ in }
            isRunning = true
        } catch {
            session = nil; builder = nil
        }
    }

    /// Ends the session, saves the HKWorkout to Health, and returns the summary.
    /// If the iPhone already saved a workout for this span (it finished the
    /// session while the watch was unreachable), the watch's copy is discarded
    /// so Fitness shows one workout, not two.
    func end() async -> WorkoutMetrics? {
        guard let s = session, let b = builder else { return nil }
        session = nil; builder = nil; isRunning = false
        let start = sessionStart ?? b.startDate ?? Date()
        sessionStart = nil
        let end = Date()
        s.end()
        let avg = stat(b, hrType, .discreteAverage)
        let mx  = stat(b, hrType, .discreteMax)
        let kcal = b.statistics(for: energyType)?.sumQuantity()?.doubleValue(for: .kilocalorie()) ?? 0
        let phoneSaved = await hasPhoneWorkout(between: start, and: end)
        await withCheckedContinuation { (cont: CheckedContinuation<Void, Never>) in
            b.endCollection(withEnd: end) { _, _ in
                if phoneSaved {
                    b.discardWorkout()
                    cont.resume()
                } else {
                    b.finishWorkout { _, error in
                        if let error { print("HealthKit: finishWorkout failed: \(error.localizedDescription)") }
                        cont.resume()
                    }
                }
            }
        }
        return WorkoutMetrics(
            avgHeartRate: Int(avg.rounded()),
            maxHeartRate: Int(mx.rounded()),
            activeEnergyKcal: kcal
        )
    }

    private func hasPhoneWorkout(between start: Date, and end: Date) async -> Bool {
        let predicate = HKQuery.predicateForSamples(withStart: start, end: end, options: [])
        let samples: [HKSample] = await withCheckedContinuation { cont in
            let q = HKSampleQuery(sampleType: HKObjectType.workoutType(), predicate: predicate,
                                  limit: 20, sortDescriptors: nil) { _, result, _ in
                cont.resume(returning: result ?? [])
            }
            store.execute(q)
        }
        return samples.contains {
            let id = $0.sourceRevision.source.bundleIdentifier
            return id.hasPrefix(Self.bundlePrefix) && !id.hasSuffix(".watchkitapp")
        }
    }

    private func stat(_ b: HKLiveWorkoutBuilder, _ t: HKQuantityType, _ k: HKStatisticsOptions) -> Double {
        let q: HKQuantity? = (k == .discreteMax)
            ? b.statistics(for: t)?.maximumQuantity()
            : b.statistics(for: t)?.averageQuantity()
        return q?.doubleValue(for: HKUnit.count().unitDivided(by: .minute())) ?? 0
    }
}

extension WorkoutMetricsManager: HKWorkoutSessionDelegate {
    nonisolated func workoutSession(_ ws: HKWorkoutSession, didChangeTo to: HKWorkoutSessionState,
                                    from: HKWorkoutSessionState, date: Date) {}
    nonisolated func workoutSession(_ ws: HKWorkoutSession, didFailWithError error: Error) {}
}

extension WorkoutMetricsManager: HKLiveWorkoutBuilderDelegate {
    nonisolated func workoutBuilderDidCollectEvent(_ b: HKLiveWorkoutBuilder) {}
    nonisolated func workoutBuilder(_ b: HKLiveWorkoutBuilder, didCollectDataOf types: Set<HKSampleType>) {
        let hrVal = (b.statistics(for: hrType)?.mostRecentQuantity())?
            .doubleValue(for: HKUnit.count().unitDivided(by: .minute()))
        let kcal = b.statistics(for: energyType)?.sumQuantity()?.doubleValue(for: .kilocalorie())
        Task { @MainActor in
            if let hrVal { self.heartRate = Int(hrVal.rounded()) }
            if let kcal { self.activeEnergy = kcal }
        }
    }
}
