//
//  RMDataCache.swift
//  bulkup
//
//  Created by sebastian.blanco on 11/9/25.
//

import Foundation

// MARK: - Cache Models
struct RMDataCache: Codable {
    let records: [PersonalRecord]
    let bestRecords: [PersonalRecord]
    let stats: RecordStats
    let timestamp: Date
    
    var isExpired: Bool {
        // El caché nunca expira automáticamente, solo se invalida con pull-to-refresh
        return false
    }
}

// MARK: - Enhanced Cache Manager
@MainActor
class RMCacheManager: ObservableObject {
    static let shared = RMCacheManager()
    
    private let cacheKey = "rm_data_cache"
    private let exercisesCacheKey = "rm_exercises_cache"
    
    // In-memory cache
    private var memoryCache: RMDataCache?
    private var exercisesMemoryCache: [RMExercise]?
    
    private init() {
        loadFromDisk()
    }
    
    // MARK: - Cache Management
    
    func getCachedData() -> RMDataCache? {
        // Primero intentar memoria
        if let memoryCache = memoryCache {
            return memoryCache
        }
        
        // Si no está en memoria, cargar de disco
        loadFromDisk()
        return memoryCache
    }
    
    func setCachedData(records: [PersonalRecord], bestRecords: [PersonalRecord], stats: RecordStats) {
        let cache = RMDataCache(
            records: records,
            bestRecords: bestRecords,
            stats: stats,
            timestamp: Date()
        )
        
        // Guardar en memoria
        memoryCache = cache
        
        // Guardar en disco de forma asíncrona
        Task {
            saveToDisk(cache)
        }
    }
    
    func getCachedExercises() -> [RMExercise]? {
        // Primero intentar memoria
        if let exercisesMemoryCache = exercisesMemoryCache {
            return exercisesMemoryCache
        }
        
        // Si no está en memoria, cargar de disco
        if let data = UserDefaults.standard.data(forKey: exercisesCacheKey),
           let exercises = try? JSONDecoder().decode([RMExercise].self, from: data) {
            exercisesMemoryCache = exercises
            return exercises
        }
        
        return nil
    }
    
    func setCachedExercises(_ exercises: [RMExercise]) {
        // Guardar en memoria
        exercisesMemoryCache = exercises
        
        // Guardar en disco
        if let data = try? JSONEncoder().encode(exercises) {
            UserDefaults.standard.set(data, forKey: exercisesCacheKey)
        }
    }
    
    func invalidateCache() {
        memoryCache = nil
        exercisesMemoryCache = nil
        UserDefaults.standard.removeObject(forKey: cacheKey)
        // No eliminar ejercicios del caché ya que raramente cambian
    }
    
    // MARK: - Private Methods
    
    private func loadFromDisk() {
        if let data = UserDefaults.standard.data(forKey: cacheKey),
           let cache = try? JSONDecoder().decode(RMDataCache.self, from: data) {
            memoryCache = cache
        }
    }
    
    private func saveToDisk(_ cache: RMDataCache) {
        if let data = try? JSONEncoder().encode(cache) {
            UserDefaults.standard.set(data, forKey: cacheKey)
        }
    }
}
