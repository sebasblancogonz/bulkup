//
//  APIService+Extensions.swift
//  bulkup
//
//  Created by sebastianblancogonz on 17/8/25.
//

import Foundation

// MARK: - Recipe DTOs

private struct RecipeRequest: Codable {
    let mealType: String
    let ingredients: [String]
    let complexity: String
    let language: String
}

struct RecipeResponse: Codable {
    let recipe: String
    let dish: String
}

private struct RecipeImageRequest: Codable {
    let dish: String
}

private struct RecipeImageResponse: Codable {
    let imageBase64: String
}

// MARK: - APIService Extensions

extension APIService {

    func login(email: String, password: String) async throws -> AuthResponse {
        let request = LoginRequest(email: email, password: password)

        let response: APIResponse<AuthResponse> = try await requestWithBody(
            endpoint: "auth/login",
            method: .POST,
            body: request
        )

        if !response.success {
            throw APIError.networkError(response.error ?? "Error al iniciar sesión")
        }

        guard let authData = response.data else {
            throw APIError.noData
        }

        return authData
    }

    func appleSignIn(identityToken: String, firstName: String?, lastName: String?) async throws -> AuthResponse {
        let request = AppleSignInRequest(
            identityToken: identityToken,
            firstName: firstName,
            lastName: lastName
        )

        let response: APIResponse<AuthResponse> = try await requestWithBody(
            endpoint: "auth/apple",
            method: .POST,
            body: request
        )

        if !response.success {
            throw APIError.networkError(response.error ?? "Error al iniciar sesión con Apple")
        }

        guard let authData = response.data else {
            throw APIError.noData
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

        if !response.success {
            throw APIError.networkError(response.error ?? "Error al registrar usuario")
        }

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

        // Make request manually to log raw JSON
        guard let url = URL(string: "\(APIConfig.baseURL)/load-diet-plan") else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        if let token = UserDefaults.standard.string(forKey: "auth_token") {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        request.httpBody = try JSONEncoder().encode(requestBody)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0
            throw APIError.serverError(statusCode)
        }

        // Always log raw JSON for debugging
        if let jsonString = String(data: data, encoding: .utf8) {
            print("[Diet API] Raw response: \(jsonString)")
        }

        let decoder = JSONDecoder()
        let outerResponse = try decoder.decode(LoadDietPlanOuterResponse.self, from: data)
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

    func loadWeightHistory(userId: String, planId: String) async throws -> [ServerWeightHistoryItem] {
        let requestBody = ["userId": userId, "planId": planId]
        let outer: WeightHistoryOuterResponse = try await requestWithBody(
            endpoint: "load-weight-history",
            method: .POST,
            body: requestBody
        )
        return outer.data.records ?? []
    }

    func listTrainingPlans(userId: String) async throws -> [ServerWorkout] {
        let request = LoadPlanRequest(userId: userId)

        let response: APIResponse<[FailableDecodable<ServerWorkout>]> = try await requestWithBody(
            endpoint: "list-training-plans",
            method: .POST,
            body: request
        )

        return (response.data ?? []).compactMap { $0.value }
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

    // MARK: - Shared Plans

    func sharePlan(userId: String, planId: String) async throws -> SharePlanResponse {
        let request = SharePlanRequest(userId: userId, planId: planId)

        let response: APIResponse<SharePlanResponse> = try await requestWithBody(
            endpoint: "share-plan",
            method: .POST,
            body: request
        )

        guard let data = response.data else {
            throw APIError.noData
        }

        return data
    }

    func importSharedPlan(userId: String, code: String) async throws -> ImportSharedPlanResponse {
        let request = ImportSharedPlanRequest(userId: userId, code: code)

        let response: APIResponse<ImportSharedPlanResponse> = try await requestWithBody(
            endpoint: "import-shared-plan",
            method: .POST,
            body: request
        )

        guard let data = response.data else {
            throw APIError.noData
        }

        return data
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

        // Add dir field
        let dir = userId != nil ? "profile-images/\(userId!)" : "profile-images"
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append(
            "Content-Disposition: form-data; name=\"dir\"\r\n\r\n".data(
                using: .utf8
            )!
        )
        body.append("\(dir)\r\n".data(using: .utf8)!)

        // Add image data
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append(
            "Content-Disposition: form-data; name=\"file\"; filename=\"profile.jpg\"\r\n"
                .data(using: .utf8)!
        )
        body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
        body.append(imageData)
        body.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)

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
        let imageUrl = uploadResponse.files[0].url
        return imageUrl.replacingOccurrences(of: "http://", with: "https://")
    }

    // MARK: - Workout Sessions

    func saveWorkoutSession(_ request: SaveWorkoutSessionRequest) async throws {
        let _: APIResponse<EmptyResponse> = try await requestWithBody(
            endpoint: "workout-sessions",
            method: .POST,
            body: request
        )
    }

    func getWorkoutSessions(userId: String, limit: Int = 50) async throws -> [WorkoutSessionRecord] {
        let response: APIResponse<[WorkoutSessionRecord]> = try await request(
            endpoint: "workout-sessions?userId=\(userId)&limit=\(limit)",
            method: .GET
        )
        return response.data ?? []
    }

    // MARK: - Diet Plan Management

    func createDietPlan(
        userId: String,
        filename: String,
        dietData: [ServerDietDay]
    ) async throws -> CreateDietPlanResponse {
        let request = CreateDietPlanRequest(
            userId: userId,
            filename: filename,
            dietData: dietData
        )

        let response: APIResponse<CreateDietPlanResponse> =
            try await requestWithBody(
                endpoint: "diet-plans",
                method: .POST,
                body: request
            )

        guard let data = response.data else {
            throw APIError.noData
        }

        return data
    }

    func updateDietPlan(
        planId: String,
        userId: String,
        filename: String,
        dietData: [ServerDietDay]
    ) async throws {
        let request = CreateDietPlanRequest(
            userId: userId,
            filename: filename,
            dietData: dietData
        )

        let _: APIResponse<EmptyResponse> = try await requestWithBody(
            endpoint: "diet-plans/\(planId)",
            method: .PUT,
            body: request
        )
    }

    func listDietPlans(userId: String) async throws -> [ServerDietPlan] {
        let request = LoadPlanRequest(userId: userId)

        let response: APIResponse<[FailableDecodable<ServerDietPlan>]> = try await requestWithBody(
            endpoint: "list-diet-plans",
            method: .POST,
            body: request
        )

        // Skip any individual plan that fails to decode so one bad plan doesn't
        // blank the whole library.
        return (response.data ?? []).compactMap { $0.value }
    }

    func activateDietPlan(userId: String, planId: String) async throws {
        let request = ActivateDietPlanRequest(userId: userId)

        let _: APIResponse<EmptyResponse> = try await requestWithBody(
            endpoint: "diet-plans/\(planId)/activate",
            method: .POST,
            body: request
        )
    }

    func deleteDietPlan(userId: String, planId: String) async throws {
        let request = DeleteDietPlanRequest(userId: userId)

        let _: APIResponse<EmptyResponse> = try await requestWithBody(
            endpoint: "diet-plans/\(planId)",
            method: .DELETE,
            body: request
        )
    }

    // MARK: - Recipe (one-shot) + AI image

    func generateRecipe(mealType: String, ingredients: [String], complexity: String, language: String) async throws -> RecipeResponse {
        guard let url = URL(string: "\(APIConfig.baseURL)/diet/recipe") else {
            throw APIError.invalidURL
        }
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let token = UserDefaults.standard.string(forKey: "auth_token") {
            urlRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        urlRequest.httpBody = try JSONEncoder().encode(RecipeRequest(mealType: mealType, ingredients: ingredients, complexity: complexity, language: language))
        let (data, response) = try await URLSession.shared.data(for: urlRequest)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw APIError.serverError((response as? HTTPURLResponse)?.statusCode ?? 0)
        }
        return try JSONDecoder().decode(RecipeResponse.self, from: data)
    }

    /// Returns decoded image bytes for the dish (backend sends base64).
    func generateRecipeImage(dish: String) async throws -> Data {
        guard let url = URL(string: "\(APIConfig.baseURL)/diet/recipe-image") else {
            throw APIError.invalidURL
        }
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let token = UserDefaults.standard.string(forKey: "auth_token") {
            urlRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        urlRequest.httpBody = try JSONEncoder().encode(RecipeImageRequest(dish: dish))
        let (data, response) = try await URLSession.shared.data(for: urlRequest)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw APIError.serverError((response as? HTTPURLResponse)?.statusCode ?? 0)
        }
        let base64 = try JSONDecoder().decode(RecipeImageResponse.self, from: data).imageBase64
        guard let imageData = Data(base64Encoded: base64) else {
            throw APIError.serverError(0)
        }
        return imageData
    }

    // MARK: - Diet Fidelity (skipped days)

    func logSkippedDay(date: String, description: String) async throws -> SkippedDay {
        guard let url = URL(string: "\(APIConfig.baseURL)/diet/skipped-day") else {
            throw APIError.invalidURL
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let token = UserDefaults.standard.string(forKey: "auth_token") {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        request.httpBody = try JSONEncoder().encode(LogSkippedDayBody(date: date, description: description))
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw APIError.serverError((response as? HTTPURLResponse)?.statusCode ?? 0)
        }
        return try JSONDecoder().decode(SkippedDay.self, from: data)
    }

    func getSkippedDays() async throws -> [SkippedDay] {
        guard let url = URL(string: "\(APIConfig.baseURL)/diet/skipped-days") else {
            throw APIError.invalidURL
        }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let token = UserDefaults.standard.string(forKey: "auth_token") {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw APIError.serverError((response as? HTTPURLResponse)?.statusCode ?? 0)
        }
        return try JSONDecoder().decode(SkippedDaysResponse.self, from: data).skippedDays
    }

    func deleteSkippedDay(date: String) async throws {
        let encodedDate = date.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? date
        guard let url = URL(string: "\(APIConfig.baseURL)/diet/skipped-day?date=\(encodedDate)") else {
            throw APIError.invalidURL
        }
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let token = UserDefaults.standard.string(forKey: "auth_token") {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        let (_, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw APIError.serverError((response as? HTTPURLResponse)?.statusCode ?? 0)
        }
    }
}

// MARK: - Diet Fidelity DTOs

struct SkippedDay: Codable, Identifiable {
    var id: String { date }
    let date: String
    let description: String
    let calories: Int
}

private struct SkippedDaysResponse: Codable { let skippedDays: [SkippedDay] }
private struct LogSkippedDayBody: Codable { let date: String; let description: String }
