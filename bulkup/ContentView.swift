//
//  ContentView.swift
//  bulkup
//
//  Created by sebastian.blanco on 17/8/25.
//

import SwiftUI
import SwiftData

// MARK: - Vista de Contenido Principal
struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var authManager: AuthManager
    
    init() {
        // Use a placeholder, will be replaced in .onAppear
        self._authManager = StateObject(wrappedValue: AuthManager(modelContext: ModelContainer.bulkUpContainer.mainContext))
    }
    
    var body: some View {
        Group {
            if authManager.isAuthenticated {
                DietView()
                    .environmentObject(authManager)
            } else {
                LoginView()
                    .environmentObject(authManager)
            }
        }
        .onAppear {
            // Re-initialize authManager with the correct context if needed
            if authManager.modelContext !== modelContext {
                authManager.modelContext = modelContext
                authManager.loadStoredUser()
            }
        }
    }
}

// MARK: - Vista de Preview
#Preview {
    ContentView()
        .modelContainer(ModelContainer.bulkUpContainer)
}
