//
//  APIService+Extensions.swift
//  bulkup
//
//  Created by sebastian.blanco on 17/8/25.
//

import Foundation

extension APIService {

    func login(email: String, password: String) async throws -> AuthResponse {
        let request = LoginRequest(email: email, password: password)

        let response: APIResponse<AuthResponse> = try await requestWithBody(
            endpoint: "auth/login",
            method: .POST,
            body: request
        )

        guard let authData = response.data else {
            throw APIError.unauthorized
        }

        return authData
    }

    func register(email: String, password: String, name: String) async throws
        -> AuthResponse
    {
        let request = RegisterRequest(
            email: email,
            password: password,
            name: name
        )

        let response: APIResponse<AuthResponse> = try await requestWithBody(
            endpoint: "auth/register",
            method: .POST,
            body: request
        )

        guard let authData = response.data else {
            throw APIError.noData
        }

        return authData
    }

    func loadActiveTrainingPlan(userId: String) async throws
        -> ServerWorkout
    {
        let requestBody = ["userId": userId]

        let outerResponse: LoadTrainingPlanOuterResponse =
            try await requestWithBody(
                endpoint: "load-training-plan",
                method: .POST,
                body: requestBody
            )

        return outerResponse.data
    }

    // ✅ Diet - TAMBIÉN estructura anidada (ARREGLO)
    func loadActiveDietPlan(userId: String) async throws -> LoadDietPlanResponse
    {
        let requestBody = ["userId": userId]

        // ✅ Usar estructura exterior para diet también
        let outerResponse: LoadDietPlanOuterResponse =
            try await requestWithBody(
                endpoint: "load-diet-plan",
                method: .POST,
                body: requestBody
            )

        return outerResponse.data
    }

    func saveWeights(_ request: SaveWeightsRequest) async throws -> APIResponse<
        EmptyResponse
    > {
        let response: APIResponse<EmptyResponse> = try await requestWithBody(
            endpoint: "save-weights",
            method: .POST,
            body: request
        )

        return response
    }

    func loadWeights(userId: String, weekStart: String) async throws
        -> LoadWeightsResponse
    {
        let requestBody = ["userId": userId, "weekStart": weekStart]

        let outerResponse: LoadWeightsOuterResponse = try await requestWithBody(
            endpoint: "load-weights",
            method: .POST,
            body: requestBody
        )

        return outerResponse.data
    }
    func listTrainingPlans(userId: String) async throws -> [ServerWorkout] {
            let request = LoadPlanRequest(userId: userId)
            
            // Debug: Print the request
            print("📤 Sending request to /list-training-plans: \(request)")
            
            let response: APIResponse<[ServerWorkout]> = try await requestWithBody(
                endpoint: "list-training-plans",
                method: .POST,
                body: request
            )
            
            print("📥 Response: \(response)")
            
            return response.data ?? []
        }
        
        func createTrainingPlan(
            userId: String,
            filename: String,
            trainingData: [ServerTrainingDay],
            planStartDate: Date?,
            planEndDate: Date?
        ) async throws -> CreateTrainingPlanResponse {
            let request = CreateTrainingPlanRequest(
                userId: userId,
                filename: filename,
                trainingData: trainingData,
                planStartDate: planStartDate,
                planEndDate: planEndDate
            )
            
            let response: APIResponse<CreateTrainingPlanResponse> = try await requestWithBody(
                endpoint: "training-plans",
                method: .POST,
                body: request
            )
            
            guard let data = response.data else {
                throw APIError.noData
            }
            
            return data
        }
        
        func updateTrainingPlan(
            planId: String,
            userId: String,
            filename: String,
            trainingData: [ServerTrainingDay],
            planStartDate: Date?,
            planEndDate: Date?
        ) async throws {
            let request = CreateTrainingPlanRequest(
                userId: userId,
                filename: filename,
                trainingData: trainingData,
                planStartDate: planStartDate,
                planEndDate: planEndDate
            )
            
            let _: APIResponse<EmptyResponse> = try await requestWithBody(
                endpoint: "training-plans/\(planId)",
                method: .PUT,
                body: request
            )
        }
        
        func activateTrainingPlan(userId: String, planId: String) async throws {
            let request = ActivateTrainingPlanRequest(userId: userId)
            
            let _: APIResponse<EmptyResponse> = try await requestWithBody(
                endpoint: "training-plans/\(planId)/activate",
                method: .POST,
                body: request
            )
        }
        
        func deleteTrainingPlan(userId: String, planId: String) async throws {
            let request = DeleteTrainingPlanRequest(userId: userId)
            
            let _: APIResponse<EmptyResponse> = try await requestWithBody(
                endpoint: "training-plans/\(planId)",
                method: .DELETE,
                body: request
            )
        }
}
