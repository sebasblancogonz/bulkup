//
//  APIService+RM.swift
//  bulkup
//
//  RM (Personal Records) API extensions
//

import Foundation

// MARK: - Request Models
struct CreateRecordRequest: Codable {
    let exerciseId: String
    let weight: Double
    let reps: Int
    let date: String
    let notes: String
    
    init(exerciseId: String, weight: Double, reps: Int, date: String, notes: String = "") {
        self.exerciseId = exerciseId
        self.weight = weight
        self.reps = reps
        self.date = date
        self.notes = notes
    }
    
    init(from formData: RMFormData) {
        let formatter = ISO8601DateFormatter()
        self.exerciseId = formData.exerciseId
        self.weight = Double(formData.weight) ?? 0
        self.reps = Int(formData.reps) ?? 1
        self.date = formatter.string(from: formData.date)
        self.notes = formData.notes
    }
}

extension APIService {
    
    // MARK: - Exercises
    func fetchExercises() async throws -> [RMExercise] {
        let response: APIResponse<[RMExercise]> = try await request(
            endpoint: "exercises",
            method: .GET
        )
        
        return response.data ?? []
    }
    
    func fetchFullExercises() async throws -> [RMExerciseFull] {
            // Intenta decodificar como wrapper
            let response: [RMExerciseFull] = try await request(
                endpoint: "exercises",
                method: .GET
            )
        return response
    }
    
    // MARK: - Records
    func fetchRecords(userId: String) async throws -> [PersonalRecord] {
        let response: APIResponse<[PersonalRecord]> = try await request(
            endpoint: "records",
            method: .GET
        )
        
        return response.data ?? []
    }
    
    func fetchBestRecords(userId: String) async throws -> [PersonalRecord] {
        let response: APIResponse<[PersonalRecord]> = try await request(
            endpoint: "records/best",
            method: .GET
        )
        
        return response.data ?? []
    }
    
    func fetchRecordStats(userId: String) async throws -> RecordStats {
        let response: APIResponse<RecordStats> = try await request(
            endpoint: "records/stats",
            method: .GET
        )
        
        return response.data ?? RecordStats.empty
    }
    
    func createRecord(_ request: CreateRecordRequest) async throws -> PersonalRecord {
        let response: APIResponse<PersonalRecord> = try await requestWithBody(
            endpoint: "records",
            method: .POST,
            body: request
        )
        
        guard let record = response.data else {
            throw APIError.noData
        }
        
        return record
    }
    
    func updateRecord(recordId: String, request: CreateRecordRequest) async throws -> PersonalRecord {
        let response: APIResponse<PersonalRecord> = try await requestWithBody(
            endpoint: "records/\(recordId)",
            method: .PUT,
            body: request
        )
        
        guard let record = response.data else {
            throw APIError.noData
        }
        
        return record
    }
    
    func deleteRecord(recordId: String) async throws -> Bool {
        let _: APIResponse<EmptyResponse> = try await request(
            endpoint: "records/\(recordId)",
            method: .DELETE
        )
        
        return true // If no error thrown, deletion was successful
    }
}
