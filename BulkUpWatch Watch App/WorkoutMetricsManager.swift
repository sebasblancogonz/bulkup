import Foundation
import HealthKit

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

    private let hrType = HKQuantityType(.heartRate)
    private let energyType = HKQuantityType(.activeEnergyBurned)

    func requestAuthorization() {
        guard HKHealthStore.isHealthDataAvailable() else { return }
        let share: Set = [HKQuantityType.workoutType(), energyType]
        let read: Set = [hrType, energyType]
        store.requestAuthorization(toShare: share, read: read) { _, _ in }
    }

    func start() {
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
            s.startActivity(with: start)
            b.beginCollection(withStart: start) { _, _ in }
            isRunning = true
        } catch {
            session = nil; builder = nil
        }
    }

    /// Ends the session, saves the HKWorkout to Health, and returns the summary.
    func end() async -> WorkoutMetrics? {
        guard let s = session, let b = builder else { return nil }
        session = nil; builder = nil; isRunning = false
        let end = Date()
        s.end()
        let avg = stat(b, hrType, .discreteAverage)
        let mx  = stat(b, hrType, .discreteMax)
        let kcal = b.statistics(for: energyType)?.sumQuantity()?.doubleValue(for: .kilocalorie()) ?? 0
        await withCheckedContinuation { (cont: CheckedContinuation<Void, Never>) in
            b.endCollection(withEnd: end) { _, _ in
                b.finishWorkout { _, _ in cont.resume() }
            }
        }
        return WorkoutMetrics(
            avgHeartRate: Int(avg.rounded()),
            maxHeartRate: Int(mx.rounded()),
            activeEnergyKcal: kcal
        )
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
