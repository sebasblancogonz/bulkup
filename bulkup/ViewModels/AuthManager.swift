//
//  AuthManager.swift
//  bulkup
//
//  Created by sebastian.blanco on 17/8/25.
//
import Foundation
import SwiftData

@MainActor
class AuthManager: ObservableObject {
    @Published var user: User?
    @Published var isAuthenticated = false
    @Published var isLoading = false
    
    public var modelContext: ModelContext // <-- Make public for external access
    private let apiService = APIService.shared
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        loadStoredUser()
    }
    
    public func loadStoredUser() {
        let descriptor = FetchDescriptor<User>()
        do {
            let users = try modelContext.fetch(descriptor)
            if let storedUser = users.first {
                self.user = storedUser
                self.isAuthenticated = true
            }
        } catch {
            print("Error loading stored user: \(error)")
        }
    }
    
    func login(email: String, password: String) async throws {
        isLoading = true
        defer { isLoading = false }
        
        let response = try await apiService.login(email: email, password: password)
        
        // Limpiar usuario anterior
        let descriptor = FetchDescriptor<User>()
        let existingUsers = try modelContext.fetch(descriptor)
        for user in existingUsers {
            modelContext.delete(user)
        }
        
        // Crear nuevo usuario
        let newUser = User(
            id: response.userId,
            email: response.email,
            name: response.name,
            token: response.token
        )
        
        modelContext.insert(newUser)
        try modelContext.save()
        
        self.user = newUser
        self.isAuthenticated = true
        
        NotificationCenter.default.post(name: .userDidLogin, object: newUser)
    }
    
    func register(email: String, password: String, name: String) async throws {
        isLoading = true
        defer { isLoading = false }
        
        let response = try await apiService.register(email: email, password: password, name: name)
        
        let newUser = User(
            id: response.userId,
            email: response.email,
            name: response.name,
            token: response.token
        )
        
        modelContext.insert(newUser)
        try modelContext.save()
        
        self.user = newUser
        self.isAuthenticated = true
        
        NotificationCenter.default.post(name: .userDidLogin, object: newUser)
    }
    
    func logout() {
        // Eliminar datos locales
        let descriptor = FetchDescriptor<User>()
        do {
            let users = try modelContext.fetch(descriptor)
            for user in users {
                modelContext.delete(user)
            }
            try modelContext.save()
        } catch {
            print("Error clearing user data: \(error)")
        }
        
        self.user = nil
        self.isAuthenticated = false
    }
}
