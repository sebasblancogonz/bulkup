//
//  BulkUpWatchApp.swift
//  BulkUpWatch Watch App
//
//  Created by sebastian.blanco on 28/6/26.
//

import SwiftUI

@main
struct BulkUpWatch_Watch_AppApp: App {
    @StateObject private var wc = WatchWCManager()
    @StateObject private var metrics = WorkoutMetricsManager()
    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(wc)
                .environmentObject(metrics)
                .onAppear {
                    wc.activate()
                    metrics.requestAuthorization()
                }
        }
    }
}
