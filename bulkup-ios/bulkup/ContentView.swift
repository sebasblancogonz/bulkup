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
    @AppStorage("theme") private var theme = "system"

    private var themeColorScheme: ColorScheme? {
        switch theme { case "light": return .light; case "dark": return .dark; default: return nil }
    }

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
        .preferredColorScheme(themeColorScheme)
        .onAppear {
            // Configurar el contexto solo una vez
            if authManager.modelContext !== modelContext {
                authManager.modelContext = modelContext
                authManager.loadStoredUser()
            }
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
}

// MARK: - Vista de Preview
#Preview {
    ContentView()
        .modelContainer(ModelContainer.bulkUpContainer)
}
