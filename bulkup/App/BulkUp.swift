//
//  DietApp.swift
//  bulkup
//
//  Created by sebastianblancogonz on 17/8/25.
//
import SwiftUI
import SwiftData

@main
struct BulkUp: App {
    
    init() {
        // La validación va en el inicializador
        APIConfig.validateConfiguration()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .modelContainer(ModelContainer.bulkUpContainer)
        }
    }
}
