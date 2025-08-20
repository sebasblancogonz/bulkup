import SwiftData
//
//  ExerciseCardView.swift
//  bulkup
//
//  Created by sebastian.blanco on 18/8/25.
//
import SwiftUI

struct ExerciseCardView: View {
    let exercise: Exercise
    let exerciseIndex: Int
    let dayName: String  // ✅ Día de entrenamiento (ej: "lunes")
    let currentDate: Date  // ✅ Fecha del calendario para guardar pesos

    @EnvironmentObject var trainingManager: TrainingManager
    @EnvironmentObject var authManager: AuthManager
    @State private var localNote: String = ""

    var body: some View {
        let completedSets = trainingManager.getCompletedSets(
            day: dayName,  // ✅ Usamos dayName para obtener sets completados
            exerciseIndex: exerciseIndex,
            totalSets: exercise.sets
        )
        let isCompleted =
            exercise.weightTracking && completedSets == exercise.sets
        let progressPercentage =
            exercise.weightTracking
            ? Double(completedSets) / Double(exercise.sets) * 100 : 0

        let key = trainingManager.generateWeightKey(
            day: dayName,  // ✅ Usamos dayName para la clave
            exerciseIndex: exerciseIndex
        )

        let isSaving = trainingManager.savingWeights[key] ?? false
        let isSaved = trainingManager.savedWeights[key] ?? false

        VStack(alignment: .leading, spacing: 16) {
            // Header del ejercicio
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 8) {
                        Circle()
                            .fill(isCompleted ? Color.green : Color.blue)
                            .frame(width: 12, height: 12)

                        Text(exercise.name)
                            .font(.headline)
                            .fontWeight(.semibold)

                        if isCompleted {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                                .font(.title3)
                        }
                    }

                    HStack(spacing: 16) {
                        Label(
                            "\(exercise.sets) × \(exercise.reps)",
                            systemImage: "target"
                        )
                        Label("\(exercise.restSeconds)s", systemImage: "timer")
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                }

                Spacer()

                if exercise.weightTracking {
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("\(completedSets)/\(exercise.sets)")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(isCompleted ? .green : .secondary)

                        Text("\(Int(progressPercentage))%")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }

            // Notas del ejercicio
            if let notes = exercise.notes {
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "lightbulb.fill")
                        .foregroundColor(.yellow)
                        .font(.caption)

                    Text(notes)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(8)
                .background(Color.yellow.opacity(0.1))
                .cornerRadius(8)
            }

            // Registro de pesos
            if exercise.weightTracking {
                WeightTrackingView(
                    exercise: exercise,
                    exerciseIndex: exerciseIndex,
                    currentDate: currentDate,  // ✅ Pasamos la fecha actual
                    localNote: $localNote,
                    isSaving: isSaving,
                    isSaved: isSaved
                )
                .environmentObject(trainingManager)
                .environmentObject(authManager)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        .onAppear {
            let noteKey = trainingManager.generateWeightKey(
                day: dayName,  // ✅ Usamos dayName para la clave de notas
                exerciseIndex: exerciseIndex
            )
            localNote = trainingManager.exerciseNotes[noteKey] ?? ""
        }
    }
}
