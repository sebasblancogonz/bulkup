//
//  ExerciseDetailSheet.swift
//  bulkup
//
//  Created by sebastian.blanco on 18/8/25.
//
import SwiftUI

struct ExerciseDetailSheet: View {
    let exercise: Exercise
    let exerciseIndex: Int
    let dayName: String
    
    @EnvironmentObject var trainingManager: TrainingManager
    @EnvironmentObject var authManager: AuthManager
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            ExerciseCardView(
                exercise: exercise,
                exerciseIndex: exerciseIndex,
                dayName: dayName
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
                }
            }
        }
    }
}
