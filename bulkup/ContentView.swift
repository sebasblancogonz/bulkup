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
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

    var body: some View {
        Group {
            if authManager.isAuthenticated {
                if hasCompletedOnboarding {
                    MainAppView(modelContext: modelContext)
                        .environmentObject(authManager)
                } else {
                    OnboardingView()
                        .environmentObject(authManager)
                }
            } else {
                LoginContentView()
                    .environmentObject(authManager)
            }
        }
        .background(BulkUpColors.background.ignoresSafeArea())
        .preferredColorScheme(.dark)
        .onAppear {
            // Configurar el contexto solo una vez
            if authManager.modelContext !== modelContext {
                authManager.modelContext = modelContext
                authManager.loadStoredUser()
            }
            forceDarkMode()
        }
        .animation(.easeInOut(duration: 0.3), value: authManager.isAuthenticated)
        .animation(.easeInOut(duration: 0.3), value: hasCompletedOnboarding)
    }

    private func forceDarkMode() {
        guard
            let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
            let window = windowScene.windows.first
        else { return }
        window.overrideUserInterfaceStyle = .dark
    }
}

// MARK: - Vista de Preview
#Preview {
    ContentView()
        .modelContainer(ModelContainer.bulkUpContainer)
}
