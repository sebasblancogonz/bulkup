//
//  ExerciseExplorerViewModel.swift
//  bulkup
//
//  Created by sebastian.blanco on 20/8/25.
//
import SwiftData
import SwiftUI

@MainActor
class ExerciseExplorerManager: ObservableObject {
    static let shared = ExerciseExplorerManager()
    @Published var exercises: [RMExerciseFull] = []
    @Published var loading = true
    @Published var searchTerm = ""
    @Published var categoryFilter: Set<String> = []
    @Published var equipmentFilter: Set<String> = []
    @Published var forceFilter: Set<String> = []
    @Published var levelFilter: Set<String> = []
    @Published var currentPage = 1
    
    private let pageSize = 18
    private let apiBaseURL = "http://localhost:8080" // Cambiar según tu configuración
    
    var categories: [String] {
        Array(Set(exercises.compactMap { $0.category })).sorted()
    }
    
    var equipments: [String] {
        Array(Set(exercises.compactMap { $0.equipment })).sorted()
    }
    
    var forces: [String] {
        Array(Set(exercises.compactMap { $0.force })).sorted()
    }
    
    var levels: [String] {
        Array(Set(exercises.compactMap { $0.level })).sorted()
    }
    
    var filteredExercises: [RMExerciseFull] {
        var result = exercises
        
        if !searchTerm.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            result = result.filter { exercise in
                exercise.name.localizedCaseInsensitiveContains(searchTerm)
            }
        }
        
        if !categoryFilter.isEmpty {
            result = result.filter { exercise in
                guard let category = exercise.category else { return false }
                return categoryFilter.contains(category)
            }
        }
        
        if !equipmentFilter.isEmpty {
            result = result.filter { exercise in
                guard let equipment = exercise.equipment else { return false }
                return equipmentFilter.contains(equipment)
            }
        }
        
        if !forceFilter.isEmpty {
            result = result.filter { exercise in
                guard let force = exercise.force else { return false }
                return forceFilter.contains(force)
            }
        }
        
        if !levelFilter.isEmpty {
            result = result.filter { exercise in
                guard let level = exercise.level else { return false }
                return levelFilter.contains(level)
            }
        }
        
        return result
    }
    
    var totalPages: Int {
        max(1, Int(ceil(Double(filteredExercises.count) / Double(pageSize))))
    }
    
    var paginatedExercises: [RMExerciseFull] {
        let start = (currentPage - 1) * pageSize
        let end = min(start + pageSize, filteredExercises.count)
        
        guard start < filteredExercises.count else { return [] }
        return Array(filteredExercises[start..<end])
    }
    
    init() {
        Task {
            await fetchExercises()
        }
    }
    
    func fetchExercises() async {
        loading = true
        
        // Intentar cargar desde caché primero
        if let cached = ExerciseCacheManager.shared.getCachedExercises() {
            exercises = cached
            loading = false
            return
        }
        
        // Si no hay caché, cargar desde API
        guard let url = URL(string: "\(apiBaseURL)/exercises") else {
            loading = false
            return
        }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            
            // Intentar decodificar diferentes formatos de respuesta
            if let exercisesList = try? JSONDecoder().decode([RMExerciseFull].self, from: data) {
                exercises = exercisesList
                ExerciseCacheManager.shared.setCachedExercises(exercisesList)
            } else if let response = try? JSONDecoder().decode(APIResponse.self, from: data) {
                exercises = response.data ?? []
                ExerciseCacheManager.shared.setCachedExercises(exercises)
            }
        } catch {
            print("Error fetching exercises: \(error)")
            exercises = []
        }
        
        loading = false
    }
    
    func resetFilters() {
        searchTerm = ""
        categoryFilter = []
        equipmentFilter = []
        forceFilter = []
        levelFilter = []
        currentPage = 1
    }
    
    func resetPage() {
        currentPage = 1
    }
    
    // Helper struct para decodificar respuesta de API
    private struct APIResponse: Codable {
        let success: Bool?
        let data: [RMExerciseFull]?
    }
}
