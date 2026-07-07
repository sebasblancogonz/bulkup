//
//  ExerciseDetailSheet.swift
//  bulkup
//
//  Created by sebastianblancogonz on 18/8/25.
//

import SwiftUI

struct ExerciseDetailSheet: View {
    let exercise: Exercise
    let exerciseIndex: Int
    let dayName: String
    let currentDate: Date

    @EnvironmentObject var trainingManager: TrainingManager
    @EnvironmentObject var authManager: AuthManager
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            ExerciseCardView(
                exercise: exercise,
                exerciseIndex: exercise.orderIndex,
                dayName: dayName,
                currentDate: currentDate,
                isExpanded: true,
                onToggleExpand: {}
            )
            .environmentObject(trainingManager)
            .environmentObject(authManager)
            .navigationTitle(exercise.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cerrar") {
                        dismiss()
                    }
                    .foregroundColor(BulkUpColors.training)
                }
            }
        }
        .background(BulkUpColors.background)
    }
}
