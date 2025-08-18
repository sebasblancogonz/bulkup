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
    
    func register(email: String, password: String, name: String) async throws -> AuthResponse {
        let request = RegisterRequest(email: email, password: password, name: name)
        
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
    
    func loadActiveTrainingPlan(userId: String) async throws -> LoadTrainingPlanResponse {
            let requestBody = ["userId": userId]
            
            let outerResponse: LoadTrainingPlanOuterResponse = try await requestWithBody(
                endpoint: "load-training-plan",
                method: .POST,
                body: requestBody
            )
            
            return outerResponse.data
        }
        
        // ✅ Diet - TAMBIÉN estructura anidada (ARREGLO)
        func loadActiveDietPlan(userId: String) async throws -> LoadDietPlanResponse {
            let requestBody = ["userId": userId]
            
            // ✅ Usar estructura exterior para diet también
            let outerResponse: LoadDietPlanOuterResponse = try await requestWithBody(
                endpoint: "load-diet-plan",
                method: .POST,
                body: requestBody
            )
            
            return outerResponse.data
        }
        
        func saveWeights(_ request: SaveWeightsRequest) async throws -> APIResponse<EmptyResponse> {
            let response: APIResponse<EmptyResponse> = try await requestWithBody(
                endpoint: "save-weights",
                method: .POST,
                body: request
            )
            
            return response
        }
}
