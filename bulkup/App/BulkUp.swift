//
//  DietApp.swift
//  bulkup
//
//  Created by sebastian.blanco on 17/8/25.
//
import SwiftUI
import SwiftData

@main
struct BulkUp: App {
        @StateObject private var authManager = AuthManager(modelContext: ModelContainer.bulkUpContainer.mainContext)
        var body: some Scene {
            WindowGroup {
                MainAppView(modelContext: ModelContainer.bulkUpContainer.mainContext)
                    .environmentObject(authManager)
            }
            .modelContainer(ModelContainer.bulkUpContainer)
        }
}

