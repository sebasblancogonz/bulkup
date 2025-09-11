import Combine
import Foundation
import SwiftData

struct RecordStats: Codable {
    let totalRecords: Int
    let exercisesWithRM: Int
    let recordsThisMonth: Int

    static let empty = RecordStats(
        totalRecords: 0,
        exercisesWithRM: 0,
        recordsThisMonth: 0
    )
}
// MARK: - Models
struct RMExercise: Codable, Identifiable {
    let id: String
    let name: String
    let nameEs: String
    let category: String

    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case nameEs
        case name
        case category
    }
}

struct PersonalRecord: Codable, Identifiable {
    let id: String
    let exerciseId: String
    let weight: Double
    let reps: Int
    let date: String
    let notes: String?

    var dateValue: Date {
        let formatter = ISO8601DateFormatter()
        return formatter.date(from: date) ?? Date()
    }
}

// MARK: - RM Calculations
struct RMCalculator {
    static func calculateHybridRM(weight: Double, reps: Int) -> Double? {
        guard reps > 0 && weight > 0 else { return nil }

        if reps == 1 {
            return weight
        }

        // Hybrid formula combining multiple RM formulas for better accuracy
        let epley = weight * (1 + Double(reps) / 30.0)
        let brzycki = weight * (36.0 / (37.0 - Double(reps)))
        let lander = weight * (100.0 / (101.3 - 2.67123 * Double(reps)))

        // Weight the formulas based on rep range
        let hybridRM: Double
        if reps <= 6 {
            hybridRM = (epley * 0.4 + brzycki * 0.4 + lander * 0.2)
        } else if reps <= 12 {
            hybridRM = (epley * 0.5 + brzycki * 0.3 + lander * 0.2)
        } else {
            hybridRM = epley  // Epley works better for higher reps
        }

        return round(hybridRM * 10) / 10  // Round to 1 decimal place
    }

    static func calculatePercentages(oneRM: Double) -> [(
        percentage: Int, weight: Double, reps: String
    )] {
        let percentages = [95, 90, 85, 80, 75, 70, 65, 60]
        return percentages.map { percent in
            let weight = round(((oneRM * Double(percent)) / 100.0) * 10) / 10
            let reps: String
            switch percent {
            case 95...: reps = "1-3"
            case 85..<95: reps = "3-5"
            case 80..<85: reps = "5-7"
            case 70..<80: reps = "8-12"
            default: reps = "12+"
            }
            return (percentage: percent, weight: weight, reps: reps)
        }
    }
}

// MARK: - RM Manager
@MainActor
class RMManager: ObservableObject {
    static let shared = RMManager()

    @Published var exercises: [RMExercise] = []
    @Published var records: [PersonalRecord] = []
    @Published var bestRecords: [PersonalRecord] = []
    @Published var stats: RecordStats = .empty
    @Published var isLoading = false
    @Published var isSubmitting = false
    @Published var errorMessage: String?

    private let apiService = APIService.shared
    private let exerciseCache = ExerciseCacheManager.shared
    private let authManager = AuthManager.shared
    private var cancellables = Set<AnyCancellable>()

    init() {}

    // MARK: - Data Fetching

    func loadInitialData(token: String) async {
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }

        await withTaskGroup(of: Void.self) { group in
            group.addTask { await self.fetchExercises() }
            group.addTask { await self.fetchRecords() }
            group.addTask { await self.fetchBestRecords() }
            group.addTask { await self.fetchStats() }
        }

        await MainActor.run { isLoading = false }
    }

    private func fetchExercises() async {

        // Try to load from cache first
        if let cached = ExerciseCacheManager.shared.getCachedRMExercises() {
            exercises = cached
            return
        }

        // If no cache, load from API using APIService
        do {
            // Note: We'll need to add this method to APIService
            let exercisesList = try await apiService.fetchExercises()
            exercises = exercisesList
            ExerciseCacheManager.shared.setCachedRMExercises(exercisesList)
        } catch {
            print("Error fetching exercises: \(error)")
            errorMessage = "Error loading exercises"
            exercises = []
        }

    }

    private func fetchRecords() async {
        guard let userId = authManager.user?.id else { return }

        do {
            let records = try await apiService.fetchRecords(userId: userId)
            await MainActor.run {
                self.records = records
            }
        } catch {
            print("Error fetching records: \(error)")
            await MainActor.run {
                self.errorMessage = "Error loading records"
                self.records = []
            }
        }
    }

    private func fetchBestRecords() async {
        guard let userId = authManager.user?.id else { return }

        do {
            let bestRecords = try await apiService.fetchBestRecords(
                userId: userId
            )
            await MainActor.run {
                self.bestRecords = bestRecords
            }
        } catch {
            print("Error fetching best records: \(error)")
            await MainActor.run {
                self.errorMessage = "Error loading best records"
                self.bestRecords = []
            }
        }
    }

    private func fetchStats() async {
        guard let userId = authManager.user?.id else { return }

        do {
            let stats = try await apiService.fetchRecordStats(userId: userId)
            await MainActor.run {
                self.stats = stats
            }
        } catch {
            print("Error fetching stats: \(error)")
            await MainActor.run {
                self.stats = RecordStats.empty
            }
        }
    }

    // MARK: - Record Management

    func createRecord(_ recordData: [String: Any], token: String) async -> Bool
    {
        await MainActor.run {
            isSubmitting = true
            errorMessage = nil
        }
        defer {
            Task {
                await MainActor.run { isSubmitting = false }
            }
        }

        do {
            guard let exerciseId = recordData["exerciseId"] as? String,
                let weight = recordData["weight"] as? Double,
                let reps = recordData["reps"] as? Int
            else {
                throw APIError.invalidClientRequest
            }
            // Formatear la fecha al formato correcto
            var formattedDate: String = ""
            if let dateString = recordData["date"] as? String {
                let isoFormatter = ISO8601DateFormatter()
                if let dateObj = isoFormatter.date(from: dateString) {
                    let dateFormatter = DateFormatter()
                    dateFormatter.dateFormat = "yyyy-MM-dd"
                    dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
                    formattedDate = dateFormatter.string(from: dateObj)
                } else {
                    // Si ya está en formato yyyy-MM-dd, úsalo directo
                    formattedDate = dateString
                }
            }
            let notes = recordData["notes"] as? String ?? ""
            let request = CreateRecordRequest(
                exerciseId: exerciseId,
                weight: weight,
                reps: reps,
                date: formattedDate,
                notes: notes
            )
            let _ = try await apiService.createRecord(request)
            await refreshData(token: token)
            return true
        } catch {
            print("Error creating record: \(error)")
            await MainActor.run {
                self.errorMessage = "Error creating record"
            }
            return false
        }
    }

    func updateRecord(
        recordId: String,
        recordData: [String: Any],
        token: String
    ) async -> Bool {
        await MainActor.run {
            isSubmitting = true
            errorMessage = nil
        }
        defer {
            Task {
                await MainActor.run { isSubmitting = false }
            }
        }

        do {
            // Convert dictionary to typed request
            guard let exerciseId = recordData["exerciseId"] as? String,
                let weight = recordData["weight"] as? Double,
                let reps = recordData["reps"] as? Int
            else {
                throw APIError.invalidClientRequest
            }

            let notes = recordData["notes"] as? String ?? ""
            var formattedDate: String = ""
            if let dateString = recordData["date"] as? String {
                let isoFormatter = ISO8601DateFormatter()
                if let dateObj = isoFormatter.date(from: dateString) {
                    let dateFormatter = DateFormatter()
                    dateFormatter.dateFormat = "yyyy-MM-dd"
                    dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
                    formattedDate = dateFormatter.string(from: dateObj)
                } else {
                    // Si ya está en formato yyyy-MM-dd, úsalo directo
                    formattedDate = dateString
                }
            }
            let request = CreateRecordRequest(
                exerciseId: exerciseId,
                weight: weight,
                reps: reps,
                date: formattedDate,
                notes: notes
            )

            let _ = try await apiService.updateRecord(
                recordId: recordId,
                request: request
            )
            await refreshData(token: token)
            return true
        } catch {
            print("Error updating record: \(error)")
            await MainActor.run {
                self.errorMessage = "Error updating record"
            }
            return false
        }
    }

    func deleteRecord(recordId: String, token: String) async -> Bool {
        do {
            let _ = try await apiService.deleteRecord(recordId: recordId)
            await refreshData(token: token)
            return true
        } catch {
            print("Error deleting record: \(error)")
            await MainActor.run {
                self.errorMessage = "Error deleting record"
            }
            return false
        }
    }

    private func refreshData(token: String) async {
        await withTaskGroup(of: Void.self) { group in
            group.addTask { await self.fetchRecords() }
            group.addTask { await self.fetchBestRecords() }
            group.addTask { await self.fetchStats() }
        }
    }

    // MARK: - Helper Methods

    func getRecordsForExercise(_ exerciseId: String) -> [PersonalRecord] {
        return records.filter { $0.exerciseId == exerciseId }
            .sorted { $0.dateValue > $1.dateValue }
    }

    func getBestRecordForExercise(_ exerciseId: String) -> PersonalRecord? {
        return bestRecords.first { $0.exerciseId == exerciseId }
    }

    func getExerciseById(_ exerciseId: String) -> RMExercise? {
        return exercises.first { $0.id == exerciseId }
    }

    func filteredExercises(searchTerm: String, category: String = "all")
        -> [RMExercise]
    {
        let allowedCategories = [
            "powerlifting", "olympic weightlifting", "strength",
        ]

        var filtered = exercises.filter { exercise in
            allowedCategories.contains(exercise.category.lowercased())
        }

        if !searchTerm.isEmpty {
            filtered = filtered.filter { exercise in
                exercise.name.lowercased().contains(searchTerm.lowercased()) ||
                exercise.nameEs.lowercased().contains(searchTerm.lowercased())
            }
        } else {
            // Show only exercises with records when no search term
            let exerciseIdsWithRecords = Set(records.map { $0.exerciseId })
            filtered = filtered.filter {
                exerciseIdsWithRecords.contains($0.id)
            }
        }

        if category != "all" {
            filtered = filtered.filter {
                $0.category.lowercased() == category.lowercased()
            }
        }

        return filtered
    }

    // Clear data on logout
    func clearData() {
        exercises = []
        records = []
        bestRecords = []
        stats = .empty
        errorMessage = nil
    }
}
