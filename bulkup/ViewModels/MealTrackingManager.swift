//
//  MealTrackingManager.swift
//  bulkup
//

import Foundation
import SwiftData

@MainActor
class MealTrackingManager: ObservableObject {
    static let shared = MealTrackingManager(modelContext: ModelContainer.bulkUpContainer.mainContext)

    @Published var todayTracking: [MealTrackingRecord] = []
    @Published var complianceStats: ComplianceStatsResponse?
    @Published var isLoading = false
    @Published var errorMessage: String?

    private var modelContext: ModelContext
    private let apiService = APIService.shared

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - Load tracking for a specific date

    func loadTracking(userId: String, date: String, dayName: String, planId: String?, meals: [Meal]) async {
        isLoading = true

        // 1. Create local records for each meal if they don't exist
        for meal in meals {
            let recordId = "\(date)_\(meal.order)"
            let descriptor = FetchDescriptor<MealTrackingRecord>(
                predicate: #Predicate { $0.id == recordId }
            )
            let existing = try? modelContext.fetch(descriptor)
            if existing?.isEmpty ?? true {
                let record = MealTrackingRecord(
                    date: date,
                    dayName: dayName,
                    planId: planId,
                    mealType: meal.type,
                    mealOrder: meal.order
                )
                modelContext.insert(record)
            }
        }
        try? modelContext.save()

        // 2. Try to load from server and merge
        do {
            if let serverTracking = try await apiService.getMealTracking(userId: userId, date: date) {
                for serverMeal in serverTracking.meals {
                    let recordId = "\(date)_\(serverMeal.mealOrder)"
                    let descriptor = FetchDescriptor<MealTrackingRecord>(
                        predicate: #Predicate { $0.id == recordId }
                    )
                    if let localRecords = try? modelContext.fetch(descriptor),
                       let local = localRecords.first {
                        // Only update from server if local doesn't need sync
                        if !local.needsSync {
                            local.completed = serverMeal.completed
                            local.notes = serverMeal.notes
                            local.completedAt = serverMeal.completedAt
                        }
                    }
                }
                try? modelContext.save()
            }
        } catch {
            // Server load failed — use local data
        }

        // 3. Fetch all local records for this date
        let dateToFetch = date
        let descriptor = FetchDescriptor<MealTrackingRecord>(
            predicate: #Predicate { $0.date == dateToFetch },
            sortBy: [SortDescriptor(\.mealOrder)]
        )
        todayTracking = (try? modelContext.fetch(descriptor)) ?? []
        isLoading = false
    }

    // MARK: - Toggle meal completion

    func toggleMealCompletion(record: MealTrackingRecord, userId: String) async {
        record.completed.toggle()
        record.completedAt = record.completed ? Date() : nil
        record.needsSync = true
        try? modelContext.save()

        // Update local published state
        refreshLocalTracking(for: record.date)

        // Sync to server
        await syncToServer(userId: userId, date: record.date)
    }

    // MARK: - Update notes

    func updateNotes(record: MealTrackingRecord, notes: String, userId: String) async {
        record.notes = notes.isEmpty ? nil : notes
        record.needsSync = true
        try? modelContext.save()

        await syncToServer(userId: userId, date: record.date)
    }

    // MARK: - Load compliance stats

    func loadComplianceStats(userId: String) async {
        do {
            complianceStats = try await apiService.getComplianceStats(userId: userId)
        } catch {
            // Silently fail
        }
    }

    // MARK: - Computed properties

    var todayComplianceRate: Double {
        guard !todayTracking.isEmpty else { return 0 }
        return Double(todayTracking.filter { $0.completed }.count) / Double(todayTracking.count)
    }

    var todayComplianceSummary: String {
        let completed = todayTracking.filter { $0.completed }.count
        let total = todayTracking.count
        return "\(completed)/\(total) comidas"
    }

    func trackingRecord(for mealOrder: Int, date: String) -> MealTrackingRecord? {
        todayTracking.first { $0.mealOrder == mealOrder && $0.date == date }
    }

    // MARK: - Clear data

    func clearAllData() {
        let descriptor = FetchDescriptor<MealTrackingRecord>()
        if let records = try? modelContext.fetch(descriptor) {
            for record in records {
                modelContext.delete(record)
            }
        }
        try? modelContext.save()
        todayTracking = []
        complianceStats = nil
    }

    // MARK: - Private

    private func syncToServer(userId: String, date: String) async {
        let dateToSync = date
        let descriptor = FetchDescriptor<MealTrackingRecord>(
            predicate: #Predicate { $0.date == dateToSync },
            sortBy: [SortDescriptor(\.mealOrder)]
        )
        guard let records = try? modelContext.fetch(descriptor), !records.isEmpty else { return }

        let meals = records.map { record in
            MealCompletionData(
                mealType: record.mealType,
                mealOrder: record.mealOrder,
                completed: record.completed,
                notes: record.notes,
                completedAt: record.completedAt
            )
        }

        let request = SaveMealTrackingRequest(
            userId: userId,
            planId: records.first?.planId ?? "",
            date: date,
            dayName: records.first?.dayName ?? "",
            meals: meals
        )

        do {
            _ = try await apiService.saveMealTracking(request: request)
            // Mark all as synced
            for record in records {
                record.needsSync = false
            }
            try? modelContext.save()
        } catch {
            // Sync failed — records keep needsSync = true for next attempt
        }
    }

    private func refreshLocalTracking(for date: String) {
        let dateToFetch = date
        let descriptor = FetchDescriptor<MealTrackingRecord>(
            predicate: #Predicate { $0.date == dateToFetch },
            sortBy: [SortDescriptor(\.mealOrder)]
        )
        todayTracking = (try? modelContext.fetch(descriptor)) ?? []
    }
}
