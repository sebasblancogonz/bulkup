//
//  ExerciseCacheManager.swift
//  bulkup
//
//  Created by sebastian.blanco on 20/8/25.
//
import Foundation

class ExerciseCacheManager {
    static let shared = ExerciseCacheManager()
    private let cacheKey = "cached_exercises"
    private let rmExercisesCacheKey = "cached_rm_exercises"
    private let cacheExpirationKey = "cache_expiration"
    private let cacheExpirationTime: TimeInterval = 3600 // 1 hora
    
    private init() {}
    
    func getCachedExercises() -> [RMExerciseFull]? {
        guard let expirationDate = UserDefaults.standard.object(forKey: cacheExpirationKey) as? Date,
              Date() < expirationDate else {
            return nil
        }
        
        guard let data = UserDefaults.standard.data(forKey: cacheKey) else { return nil }
        return try? JSONDecoder().decode([RMExerciseFull].self, from: data)
    }
    
    func getCachedRMExercises() -> [RMExercise]? {
        guard let expirationDate = UserDefaults.standard.object(forKey: cacheExpirationKey) as? Date,
              Date() < expirationDate else {
            return nil
        }
        
        guard let data = UserDefaults.standard.data(forKey: rmExercisesCacheKey) else { return nil }
        _ = try! JSONDecoder().decode([RMExercise].self, from: data)
        return try? JSONDecoder().decode([RMExercise].self, from: data)
    }
    
    func setCachedExercises(_ exercises: [RMExerciseFull]) {
        guard let data = try? JSONEncoder().encode(exercises) else { return }
        UserDefaults.standard.set(data, forKey: cacheKey)
        UserDefaults.standard.set(Date().addingTimeInterval(cacheExpirationTime), forKey: cacheExpirationKey)
    }
    
    func setCachedRMExercises(_ exercises: [RMExercise]) {
        guard let data = try? JSONEncoder().encode(exercises) else { return }
        UserDefaults.standard.set(data, forKey: rmExercisesCacheKey)
        UserDefaults.standard.set(Date().addingTimeInterval(cacheExpirationTime), forKey: cacheExpirationKey)
    }
}
