//
//  ExerciseExplorerManager.swift
//  bulkup
//
//  Refactored to use APIService
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
    @Published var errorMessage: String?
    
    private let pageSize = 18
    private let apiService = APIService.shared
    
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
        errorMessage = nil
        
        // Try to load from cache first
        if let cached = ExerciseCacheManager.shared.getCachedExercises() {
            exercises = cached
            loading = false
            return
        }
        
        // If no cache, load from API using APIService
        do {
            // Note: We'll need to add this method to APIService
            let exercisesList = try await apiService.fetchFullExercises()
            exercises = exercisesList
            ExerciseCacheManager.shared.setCachedExercises(exercisesList)
        } catch {
            print("Error fetching exercises: \(error)")
            errorMessage = "Error loading exercises"
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
    
    // Clear data on logout
    func clearData() {
        exercises = []
        searchTerm = ""
        resetFilters()
        errorMessage = nil
    }
}
