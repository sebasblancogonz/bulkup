//
//  DietApp.swift
//  bulkup
//
//  Created by sebastianblancogonz on 17/8/25.
//
import AuthenticationServices
import SwiftUI
import SwiftData

@main
struct BulkUp: App {

    init() {
        APIConfig.validateConfiguration()
#if DEBUG
        LanguageManager.runSelfCheck()
        SharedWorkoutStore.runSelfCheck()
        ThemeSelfCheck.run()
        FoodTagInput.runSelfCheck()
        DietFidelity.runSelfCheck()
        DietCompliance.runSelfCheck()
        WorkoutFeedbackManager.runSelfCheck()
        WorkoutSessionManager.runSelfCheck()
        WatchSync.runSelfCheck()
        ExerciseWeightLogger.runSelfCheck()
        APIService.runDateParsingSelfCheck()
        WorkoutVideoStore.runSelfCheck()
#endif

        NotificationCenter.default.addObserver(
            forName: ASAuthorizationAppleIDProvider.credentialRevokedNotification,
            object: nil,
            queue: .main
        ) { _ in
            Task { @MainActor in
                AuthManager.shared.logout()
            }
        }
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .modelContainer(ModelContainer.bulkUpContainer)
        }
    }
}
