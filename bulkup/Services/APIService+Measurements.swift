//
//  APIService+Body.swift
//  bulkup
//
//  Body Measurements API extensions
//

import Foundation

// MARK: - Request Models
struct SaveMeasurementsRequest: Codable {
    let userId: String
    let peso: Double
    let altura: Double
    let edad: Int
    let sexo: String
    let cintura: Double
    let cuello: Double
    let cadera: Double?
    let brazo: Double?
    let muslo: Double?
    let pantorrilla: Double?
    let fecha: Date?

    init(
        userId: String,
        peso: Double,
        altura: Double,
        edad: Int,
        sexo: String,
        cintura: Double,
        cuello: Double,
        cadera: Double? = nil,
        brazo: Double? = nil,
        muslo: Double? = nil,
        pantorrilla: Double? = nil,
        fecha: Date? = nil
    ) {
        self.userId = userId
        self.peso = peso
        self.altura = altura
        self.edad = edad
        self.sexo = sexo
        self.cintura = cintura
        self.cuello = cuello
        self.cadera = cadera
        self.brazo = brazo
        self.muslo = muslo
        self.pantorrilla = pantorrilla
        self.fecha = fecha
    }
}

struct CalculateCompositionRequest: Codable {
    let userId: String
    let fecha: Date?

    init(userId: String, fecha: Date? = nil) {
        self.userId = userId
        self.fecha = fecha
    }
}

// MARK: - Response Models
struct BodyMeasurements: Codable, Identifiable {
    let id: String?
    let userId: String
    let peso: Double
    let altura: Double
    let edad: Int
    let sexo: String
    let cintura: Double
    let cuello: Double
    let cadera: Double?
    let brazo: Double?
    let muslo: Double?
    let pantorrilla: Double?
    let fecha: Date
    let createdAt: Date
    let updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case userId, peso, altura, edad, sexo, cintura, cuello
        case cadera, brazo, muslo, pantorrilla, fecha, createdAt, updatedAt
    }
}

struct BodyComposition: Codable {
    let porcentajeGrasa: Double
    let masaGrasa: Double
    let masaMagra: Double
    let aguaCorporal: Double
    let masaMuscular: Double

    enum CodingKeys: String, CodingKey {
        case porcentajeGrasa = "porcentaje_grasa"
        case masaGrasa = "masa_grasa"
        case masaMagra = "masa_magra"
        case aguaCorporal = "agua_corporal"
        case masaMuscular = "masa_muscular"
    }
}

extension APIService {

    // MARK: - Body Measurements
    func saveMeasurements(request: SaveMeasurementsRequest) async throws -> Bool
    {
        let _: APIResponse<EmptyResponse> = try await requestWithBody(
            endpoint: "body/measurements",
            method: .POST,
            body: request
        )

        return true  // If no error thrown, save was successful
    }

    func getLatestMeasurements(userId: String) async throws -> BodyMeasurements?
    {
        let response: APIResponse<BodyMeasurements> = try await request(
            endpoint: "body/measurements/latest?userId=\(userId)",
            method: .GET
        )

        return response.data
    }

    func getMeasurementsHistory(userId: String) async throws
        -> [BodyMeasurements]
    {
        let response: APIResponse<[BodyMeasurements]> = try await request(
            endpoint: "body/measurements/history?userId=\(userId)",
            method: .GET
        )

        return response.data ?? []
    }

    func calculateBodyComposition(request: CalculateCompositionRequest)
        async throws -> BodyComposition
    {
        let response: APIResponse<BodyComposition> = try await requestWithBody(
            endpoint: "body/composition",
            method: .POST,
            body: request
        )

        guard let composition = response.data else {
            throw APIError.noData
        }

        return composition
    }

    func deleteMeasurement(measurementId: String) async throws -> Bool {
        print("Deleting measure", measurementId)
        let _: APIResponse<EmptyResponse> = try await request(
            endpoint: "body/measurements/\(measurementId)",
            method: .DELETE
        )

        return true
    }

}
