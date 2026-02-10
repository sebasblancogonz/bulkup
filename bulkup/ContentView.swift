//
//  ContentView.swift
//  bulkup
//
//  Created by sebastianblancogonz on 17/8/25.
//

import SwiftData
import SwiftUI

// MARK: - Vista de Contenido Principal
struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var authManager = AuthManager.shared
    @AppStorage("theme") private var theme = "system"

    var body: some View {
        Group {
            if authManager.isAuthenticated {
                MainAppView(modelContext: modelContext)
                    .environmentObject(authManager)
            } else {
                LoginContentView()
                    .environmentObject(authManager)
            }
        }
        .onAppear {
            // ✅ Configurar el contexto solo una vez
            if authManager.modelContext !== modelContext {
                authManager.modelContext = modelContext
                authManager.loadStoredUser()
            }
            applyTheme(theme)
        }
        .animation(.easeInOut(duration: 0.3), value: authManager.isAuthenticated)
    }

    private func applyTheme(_ theme: String) {
        guard
            let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
            let window = windowScene.windows.first
        else { return }

        switch theme {
        case "light":
            window.overrideUserInterfaceStyle = .light
        case "dark":
            window.overrideUserInterfaceStyle = .dark
        default:
            window.overrideUserInterfaceStyle = .unspecified
        }
    }
}

// MARK: - Vista de Preview
#Preview {
    ContentView()
        .modelContainer(ModelContainer.bulkUpContainer)
}
