//
//  ContentView.swift
//  bulkup
//
//  Created by sebastian.blanco on 17/8/25.
//

import SwiftData
import SwiftUI

// MARK: - Vista de Contenido Principal
import SwiftData
import SwiftUI

// MARK: - Vista de Contenido Principal
struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var authManager = AuthManager.shared

    var body: some View {
        Group {
            if authManager.isAuthenticated {
                MainAppView(modelContext: modelContext)
                    .environmentObject(authManager)
            } else {
                LoginView()
                    .environmentObject(authManager)
            }
        }
        .onAppear {
            // ✅ Configurar el contexto solo una vez
            if authManager.modelContext !== modelContext {
                authManager.modelContext = modelContext
                authManager.loadStoredUser()
            }
        }
        .animation(.easeInOut(duration: 0.3), value: authManager.isAuthenticated)
    }
}

// MARK: - Vista de Preview
#Preview {
    ContentView()
        .modelContainer(ModelContainer.bulkUpContainer)
}
