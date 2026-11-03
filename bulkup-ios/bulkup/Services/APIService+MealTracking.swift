//
//  APIService+MealTracking.swift
//  bulkup
//
//  Meal Tracking API extensions
//

import Foundation

extension APIService {

    // MARK: - Meal Tracking

    func saveMealTracking(request: SaveMealTrackingRequest) async throws -> Bool {
        let _: APIResponse<EmptyResponse> = try await requestWithBody(
            endpoint: "diet/tracking",
            method: .POST,
            body: request
        )
        return true
    }

    func getMealTracking(userId: String, date: String) async throws -> DailyMealTrackingResponse? {
        let response: APIResponse<DailyMealTrackingResponse> = try await request(
            endpoint: "diet/tracking?date=\(date)",
            method: .GET
        )
        return response.data
    }

    func getMealTrackingHistory(userId: String, from: String, to: String) async throws -> [DailyMealTrackingResponse] {
        let response: APIResponse<[DailyMealTrackingResponse]> = try await request(
            endpoint: "diet/tracking/history?from=\(from)&to=\(to)",
            method: .GET
        )
        return response.data ?? []
    }

    func getComplianceStats(userId: String, days: Int = 30) async throws -> ComplianceStatsResponse? {
        let response: APIResponse<ComplianceStatsResponse> = try await request(
            endpoint: "diet/tracking/stats?days=\(days)&today=\(Self.localToday)",
            method: .GET
        )
        return response.data
    }
}
