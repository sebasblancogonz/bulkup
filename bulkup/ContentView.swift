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
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var authManager = AuthManager.shared
    @StateObject private var languageManager = LanguageManager.shared
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
        .onChange(of: scenePhase) { _, newPhase in
            // Reconcile any widget-side mutations when returning to foreground.
            if newPhase == .active, WorkoutSessionManager.shared.isActive {
                WorkoutSessionManager.shared.reconcileFromStore(
                    trainingManager: .shared
                )
            }
        }
        .animation(.easeInOut(duration: 0.3), value: authManager.isAuthenticated)
        .animation(.easeInOut(duration: 0.3), value: hasCompletedOnboarding)
        .environment(\.locale, languageManager.locale)
        .environmentObject(languageManager)
        .id(languageManager.language)
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
