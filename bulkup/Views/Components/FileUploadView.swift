//
//  FileUploadView.swift
//  bulkup
//
//  Created by sebastianblancogonz on 18/8/25.
//

import SwiftData
import SwiftUI
import UniformTypeIdentifiers

struct FileUploadView: View {
    @EnvironmentObject var dietManager: DietManager
    @EnvironmentObject var trainingManager: TrainingManager
    @EnvironmentObject var authManager: AuthManager
    @State private var selectedTab = 0

    var body: some View {
        VStack(spacing: 0) {
            SmartFileUploadView()
                .environmentObject(dietManager)
                .environmentObject(trainingManager)
                .environmentObject(authManager)

        }
        .navigationTitle("Subir Archivos")
        .navigationBarTitleDisplayMode(.large)
    }
}

// MARK: - File Type Enum Extension
extension FileType {
    init(from string: String) {
        switch string.lowercased() {
        case "diet":
            self = .diet
        case "training":
            self = .training
        default:
            self = .unknown
        }
    }
}
