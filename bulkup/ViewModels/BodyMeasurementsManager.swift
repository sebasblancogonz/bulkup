//
//  BodyMeasurementsManager.swift
//  bulkup
//
//  Created by sebastian.blanco on 25/8/25.
//

import Foundation
import SwiftUI

// MARK: - Body Measurements Manager
@MainActor
class BodyMeasurementsManager: ObservableObject {
    static let shared = BodyMeasurementsManager()
    
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var currentMeasurements: BodyMeasurements?
    @Published var measurementsHistory: [BodyMeasurements] = []
    @Published var bodyComposition: BodyComposition?
    
    private let apiService = APIService.shared
    private var currentTask: Task<Void, Never>?
    
    init() {}
    
    // MARK: - Cancel current operations
    private func cancelCurrentTask() {
        currentTask?.cancel()
        currentTask = nil
    }
    
    // MARK: - Save Measurements
    func saveMeasurements(
        userId: String,
        weight: Double,
        height: Double,
        age: Int,
        sex: String,
        waist: Double,
        neck: Double,
        hip: Double? = nil,
        arm: Double? = nil,
        thigh: Double? = nil,
        calf: Double? = nil
    ) async {
        cancelCurrentTask()
        
        isLoading = true
        errorMessage = nil
        
        currentTask = Task {
            let request = SaveMeasurementsRequest(
                userId: userId,
                peso: weight,
                altura: height,
                edad: age,
                sexo: sex,
                cintura: waist,
                cuello: neck,
                cadera: hip,
                brazo: arm,
                muslo: thigh,
                pantorrilla: calf,
                fecha: Date()
            )
            
            do {
                let _ = try await apiService.saveMeasurements(request: request)
                if !Task.isCancelled {
                    await loadLatestMeasurements(userId: userId)
                }
            } catch {
                if !Task.isCancelled {
                    errorMessage = "Error al guardar medidas: \(error.localizedDescription)"
                }
            }
            
            if !Task.isCancelled {
                isLoading = false
            }
        }
        
        await currentTask?.value
    }
    
    // MARK: - Load Latest Measurements
    func loadLatestMeasurements(userId: String) async {
        cancelCurrentTask()
        
        isLoading = true
        errorMessage = nil
        
        currentTask = Task {
            do {
                let measurements = try await apiService.getLatestMeasurements(userId: userId)
                if !Task.isCancelled {
                    currentMeasurements = measurements
                }
            } catch {
                if !Task.isCancelled {
                    // Solo mostrar error si es un error real, no cuando no hay datos
                    if case APIError.noData = error {
                        // Sin datos es normal para usuarios nuevos
                        currentMeasurements = nil
                    } else {
                        errorMessage = "Error al cargar medidas: \(error.localizedDescription)"
                    }
                }
            }
            
            if !Task.isCancelled {
                isLoading = false
            }
        }
        
        await currentTask?.value
    }
    
    // MARK: - Load Measurements History
    func loadMeasurementsHistory(userId: String) async {
        cancelCurrentTask()
        
        isLoading = true
        errorMessage = nil
        
        currentTask = Task {
            do {
                let history = try await apiService.getMeasurementsHistory(userId: userId)
                if !Task.isCancelled {
                    measurementsHistory = history
                }
            } catch {
                if !Task.isCancelled {
                    // Solo mostrar error si es un error real, no cuando no hay datos
                    if case APIError.noData = error {
                        // Sin historial es normal
                        measurementsHistory = []
                    } else {
                        errorMessage = "Error al cargar historial: \(error.localizedDescription)"
                    }
                }
            }
            
            if !Task.isCancelled {
                isLoading = false
            }
        }
        
        await currentTask?.value
    }
    
    // MARK: - Calculate Body Composition
    func calculateBodyComposition(userId: String, date: Date? = nil) async {
        // Don't cancel current task for composition calculation as it's secondary
        guard !isLoading else { return }
        
        isLoading = true
        
        let request = CalculateCompositionRequest(userId: userId, fecha: date)
        
        do {
            let composition = try await apiService.calculateBodyComposition(request: request)
            bodyComposition = composition
        } catch {
            errorMessage = "Error al calcular composición: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    // MARK: - Delete Measurement
    func deleteMeasurement(measurementId: String, userId: String) async -> Bool {
        isLoading = true
        errorMessage = nil
        
        do {
            let success = try await apiService.deleteMeasurement(measurementId: measurementId)
            
            if success {
                // Remover de la lista local
                measurementsHistory.removeAll { $0.id == measurementId }
                
                // Si es la medida actual, limpiarla
                if currentMeasurements?.id == measurementId {
                    currentMeasurements = nil
                    bodyComposition = nil
                    
                    // Cargar la siguiente medida más reciente
                    if !measurementsHistory.isEmpty {
                        currentMeasurements = measurementsHistory.first
                    }
                }
                
                // Recalcular composición si hay medidas
                if currentMeasurements != nil {
                    await calculateBodyComposition(userId: userId)
                }
            }
            
            return success
        } catch {
            errorMessage = "Error al eliminar medida: \(error.localizedDescription)"
            return false
        }
        
        isLoading = false
    }
}
