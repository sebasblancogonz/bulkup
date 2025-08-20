import Foundation
import Combine
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
    let category: String
    
    enum CodingKeys: String, CodingKey {
        case id = "_id"
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
            hybridRM = epley // Epley works better for higher reps
        }
        
        return round(hybridRM * 10) / 10 // Round to 1 decimal place
    }
    
    static func calculatePercentages(oneRM: Double) -> [(percentage: Int, weight: Double, reps: String)] {
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
class RMManager: ObservableObject {
    static let shared = RMManager()
    @Published var exercises: [RMExercise] = []
    @Published var records: [PersonalRecord] = []
    @Published var bestRecords: [PersonalRecord] = []
    @Published var stats: RecordStats = .empty
    @Published var isLoading = false
    @Published var isSubmitting = false
    
    private let baseURL: String
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        self.baseURL = APIConfig.baseURL
    }
    
    // MARK: - Data Fetching
    
    func loadInitialData(token: String) async {
        await MainActor.run { isLoading = true }
        
        await withTaskGroup(of: Void.self) { group in
            group.addTask { await self.fetchExercises(token: token) }
            group.addTask { await self.fetchRecords(token: token) }
            group.addTask { await self.fetchBestRecords(token: token) }
            group.addTask { await self.fetchStats(token: token) }
        }
        
        await MainActor.run { isLoading = false }
    }
    
    private func fetchExercises(token: String) async {
        guard let url = URL(string: "\(baseURL)/exercises") else { return }
        
        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            let exercises = try JSONDecoder().decode([RMExercise].self, from: data)
            
            await MainActor.run {
                self.exercises = exercises
            }
        } catch {
            print("Error fetching exercises: \(error)")
        }
    }
    
    private func fetchRecords(token: String) async {
        guard let url = URL(string: "\(baseURL)/records") else { return }
        
        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            
            // Try to decode as direct array first
            if let records = try? JSONDecoder().decode([PersonalRecord].self, from: data) {
                await MainActor.run {
                    self.records = records
                }
                return
            }
            
            // Try to decode as wrapped response
            if let response = try? JSONDecoder().decode(APIResponse<[PersonalRecord]>.self, from: data),
               let records = response.data {
                await MainActor.run {
                    self.records = records
                }
                return
            }
            
            // Fallback: empty array
            await MainActor.run {
                self.records = []
            }
            
        } catch {
            print("Error fetching records: \(error)")
            await MainActor.run {
                self.records = []
            }
        }
    }
    
    private func fetchBestRecords(token: String) async {
        guard let url = URL(string: "\(baseURL)/records/best") else { return }
        
        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            
            // Try to decode as direct array first
            if let bestRecords = try? JSONDecoder().decode([PersonalRecord].self, from: data) {
                await MainActor.run {
                    self.bestRecords = bestRecords
                }
                return
            }
            
            // Try to decode as wrapped response
            if let response = try? JSONDecoder().decode(APIResponse<[PersonalRecord]>.self, from: data),
               let bestRecords = response.data {
                await MainActor.run {
                    self.bestRecords = bestRecords
                }
                return
            }
            
            // Fallback: empty array
            await MainActor.run {
                self.bestRecords = []
            }
            
        } catch {
            print("Error fetching best records: \(error)")
            await MainActor.run {
                self.bestRecords = []
            }
        }
    }
    
    private func fetchStats(token: String) async {
        guard let url = URL(string: "\(baseURL)/records/stats") else { return }
        
        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            
            // Debug: Print the raw JSON response
            if let jsonString = String(data: data, encoding: .utf8) {
                print("Stats API Response: \(jsonString)")
            }
            
            // Try to decode as wrapped response FIRST
            if let response = try? JSONDecoder().decode(APIResponse<RecordStats>.self, from: data),
               let stats = response.data {
                print("Successfully decoded wrapped stats: \(stats)")
                await MainActor.run {
                    self.stats = stats
                }
                return
            }
            
            // Try to decode as direct stats object (secondary)
            if let stats = try? JSONDecoder().decode(RecordStats.self, from: data) {
                print("Successfully decoded direct stats: \(stats)")
                await MainActor.run {
                    self.stats = stats
                }
                return
            }
            
            // Debug: Try to decode as generic dictionary
            if let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                print("Available keys in stats response: \(dict.keys)")
                if let dataDict = dict["data"] as? [String: Any] {
                    print("Data keys: \(dataDict.keys)")
                    print("Data values: \(dataDict)")
                }
            }
            
            // Fallback: empty stats
            print("Failed to decode stats, using empty")
            await MainActor.run {
                self.stats = RecordStats.empty
            }
            
        } catch {
            print("Error fetching stats: \(error)")
            await MainActor.run {
                self.stats = RecordStats.empty
            }
        }
    }
    
    // MARK: - Record Management
    
    func createRecord(_ recordData: [String: Any], token: String) async -> Bool {
        await MainActor.run { isSubmitting = true }
        defer { Task { await MainActor.run { isSubmitting = false } } }
        
        guard let url = URL(string: "\(baseURL)/records") else { return false }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: recordData)
            let (_, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse {
                let success = httpResponse.statusCode == 200 || httpResponse.statusCode == 201
                if success {
                    await refreshData(token: token)
                }
                return success
            }
        } catch {
            print("Error creating record: \(error)")
        }
        
        return false
    }
    
    func updateRecord(recordId: String, recordData: [String: Any], token: String) async -> Bool {
        await MainActor.run { isSubmitting = true }
        defer { Task { await MainActor.run { isSubmitting = false } } }
        
        guard let url = URL(string: "\(baseURL)/records/\(recordId)") else { return false }
        
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: recordData)
            let (_, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse {
                let success = httpResponse.statusCode == 200
                if success {
                    await refreshData(token: token)
                }
                return success
            }
        } catch {
            print("Error updating record: \(error)")
        }
        
        return false
    }
    
    func deleteRecord(recordId: String, token: String) async -> Bool {
        guard let url = URL(string: "\(baseURL)/records/\(recordId)") else { return false }
        
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse {
                let success = httpResponse.statusCode == 200
                if success {
                    await refreshData(token: token)
                }
                return success
            }
        } catch {
            print("Error deleting record: \(error)")
        }
        
        return false
    }
    
    private func refreshData(token: String) async {
        await withTaskGroup(of: Void.self) { group in
            group.addTask { await self.fetchRecords(token: token) }
            group.addTask { await self.fetchBestRecords(token: token) }
            group.addTask { await self.fetchStats(token: token) }
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
    
    func filteredExercises(searchTerm: String, category: String = "all") -> [RMExercise] {
        let allowedCategories = ["powerlifting", "olympic weightlifting", "strength"]
        
        var filtered = exercises.filter { exercise in
            allowedCategories.contains(exercise.category.lowercased())
        }
        
        if !searchTerm.isEmpty {
            filtered = filtered.filter { exercise in
                exercise.name.lowercased().contains(searchTerm.lowercased())
            }
        } else {
            // Show only exercises with records when no search term
            let exerciseIdsWithRecords = Set(records.map { $0.exerciseId })
            filtered = filtered.filter { exerciseIdsWithRecords.contains($0.id) }
        }
        
        if category != "all" {
            filtered = filtered.filter { $0.category.lowercased() == category.lowercased() }
        }
        
        return filtered
    }
}
