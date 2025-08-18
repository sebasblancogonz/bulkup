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
    
    func loadActiveDietPlan(userId: String) async throws -> LoadDietPlanResponse {
        let requestBody = ["userId": userId]
        let response: LoadDietPlanOuterResponse = try await requestWithBody(
            endpoint: "load-diet-plan",
            method: .POST,
            body: requestBody
        )
        return response.data
    }
}
