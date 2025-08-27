//
//  APIService+Extensions.swift
//  bulkup
//
//  Created by sebastianblancogonz on 17/8/25.
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

    // Función register actualizada para incluir dateOfBirth
    func register(
        email: String,
        password: String,
        name: String,
        dateOfBirth: Date? = nil
    ) async throws -> AuthResponse {
        let request = RegisterRequest(
            email: email,
            password: password,
            name: name,
            dateOfBirth: dateOfBirth
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

    func loadActiveTrainingPlan(userId: String) async throws -> ServerWorkout {
        let plans = try await listTrainingPlans(userId: userId)

        guard let activePlan = plans.first(where: { $0.active }) else {
            // Si no hay plan activo, lanzar un error específico
            throw APIError.noData
        }

        return activePlan
    }

    // Diet - TAMBIÉN estructura anidada (ARREGLO)
    func loadActiveDietPlan(userId: String) async throws -> LoadDietPlanResponse
    {
        let requestBody = ["userId": userId]

        // Usar estructura exterior para diet también
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

        let response: APIResponse<[ServerWorkout]> = try await requestWithBody(
            endpoint: "list-training-plans",
            method: .POST,
            body: request
        )

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

        let response: APIResponse<CreateTrainingPlanResponse> =
            try await requestWithBody(
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

    // MARK: - Profile Management
    func getProfile() async throws -> ProfileResponse {
        let response: APIResponse<ProfileResponse> = try await request(
            endpoint: "profile",
            method: .GET
        )

        guard let profile = response.data else {
            throw APIError.noData
        }

        return profile
    }

    func updateProfile(request: UpdateProfileRequest) async throws
        -> ProfileResponse
    {
        AppLogger.shared.info("APIService: Iniciando PUT /profile")

        do {
            let response: APIResponse<ProfileResponse> =
                try await requestWithBody(
                    endpoint: "profile",
                    method: .PUT,
                    body: request
                )

            // Log de la respuesta
            AppLogger.shared.info(
                "APIService: Respuesta recibida - Success: \(response.success)"
            )

            guard let profile = response.data else {
                AppLogger.shared.error(
                    "APIService: No data in response - Success: \(response.success), Error: \(response.error ?? "nil"), Message: \(response.message ?? "nil")"
                )
                throw APIError.noData
            }

            AppLogger.shared.info(
                "APIService: Perfil recibido correctamente - UserID: \(profile.userId)"
            )
            return profile

        } catch {
            AppLogger.shared.error(
                "APIService: Error en updateProfile - \(error)"
            )
            throw error
        }
    }

    func uploadProfileImage(imageUrl: String) async throws -> Bool {
        let request = UploadImageRequest(imageUrl: imageUrl)

        let _: APIResponse<EmptyResponse> = try await requestWithBody(
            endpoint: "profile/image",
            method: .POST,
            body: request
        )

        return true
    }

    func deleteProfileImage() async throws -> Bool {
        let _: APIResponse<EmptyResponse> = try await request(
            endpoint: "profile/image",
            method: .DELETE
        )

        return true
    }

    // MARK: - Zipline Integration
    func uploadImageToZipline(
        imageData: Data,
        ziplineURL: String,
        token: String,
        userId: String?
    ) async throws -> String {
        guard let url = URL(string: "\(ziplineURL)/api/upload") else {
            AppLogger.shared.error("Invalid zipline URL: \(ziplineURL)")
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(token, forHTTPHeaderField: "Authorization")

        // Create multipart form data
        let boundary = UUID().uuidString
        request.setValue(
            "multipart/form-data; boundary=\(boundary)",
            forHTTPHeaderField: "Content-Type"
        )

        var body = Data()

        // Add image data
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append(
            "Content-Disposition: form-data; name=\"file\"; filename=\"profile.jpg\"\r\n"
                .data(using: .utf8)!
        )
        body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
        body.append(imageData)
        body.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)

        let dir = userId != nil ? "profile-images/\(userId!)" : "profile-images"
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append(
            "Content-Disposition: form-data; name=\"dir\"\r\n\r\n".data(
                using: .utf8
            )!
        )
        body.append("\(dir)\r\n".data(using: .utf8)!)

        request.httpBody = body

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
            httpResponse.statusCode == 200
        else {
            throw APIError.requestFailed
        }

        let uploadResponse = try JSONDecoder().decode(
            ZiplineUploadResponse.self,
            from: data
        )
        return uploadResponse.files[0].url
    }
}
