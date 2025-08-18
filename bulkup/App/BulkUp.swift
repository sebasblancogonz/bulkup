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
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(ModelContainer.dietAppContainer)
    }
}
