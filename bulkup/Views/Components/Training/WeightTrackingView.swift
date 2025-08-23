//
//  WeightTrackingView.swift
//  bulkup
//
//  Fixed version with exercise name included in weight operations
//

import SwiftData
import SwiftUI

struct WeightTrackingView: View {
    let exercise: Exercise
    let exerciseIndex: Int
    let currentDate: Date  // Date from calendar for saving
    @Binding var localNote: String
    let isSaving: Bool
    let isSaved: Bool

    @StateObject var trainingManager = TrainingManager.shared
    @StateObject var authManager = AuthManager.shared

    // Formatter to convert currentDate to day of the week
    private var dayFormatter: DateFormatter {
        let f = DateFormatter()
        f.locale = Locale(identifier: "es_ES")
        f.dateFormat = "EEEE"
        f.calendar = Calendar(identifier: .gregorian)
        f.calendar?.firstWeekday = 2  // Monday as first day
        return f
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // No date navigation - just the content

            // Horizontal scroll of sets
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(0..<exercise.sets, id: \.self) { setIndex in
                        WeightSetView(
                            setIndex: setIndex,
                            exercise: exercise,
                            exerciseIndex: exerciseIndex,
                            dayName: dayFormatter.string(from: currentDate).capitalized,
                            onSubmit: saveWeights
                        )
                        .frame(width: UIScreen.main.bounds.width * 0.40)
                        .shadow(
                            color: .black.opacity(0.05),
                            radius: 3,
                            x: 0,
                            y: 2
                        )
                    }
                }
                .padding(.horizontal, 16)
            }
            .overlay(
                HStack {
                    LinearGradient(
                        colors: [
                            Color(.systemBackground),
                            Color(.systemBackground).opacity(0),
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(width: 20)

                    Spacer()

                    LinearGradient(
                        colors: [
                            Color(.systemBackground).opacity(0),
                            Color(.systemBackground),
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(width: 20)
                }
            )
            .frame(height: 160)

            // Exercise note
            VStack(alignment: .leading, spacing: 8) {
                Text("Notas")
                    .font(.caption)
                    .foregroundColor(.secondary)

                TextEditor(text: $localNote)
                    .frame(height: 80)
                    .padding(8)
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(8)
            }
            
            // Save button
            Button(action: saveWeights) {
                HStack {
                    if isSaving {
                        ProgressView()
                    } else if isSaved {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                    }
                    Text(isSaved ? "Guardado" : "Guardar")
                        .fontWeight(.medium)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(isSaved ? Color.green.opacity(0.2) : Color.blue)
                .foregroundColor(isSaved ? .green : .white)
                .cornerRadius(10)
            }.keyboardShortcut(.defaultAction)
        }
        .padding()
        .onAppear {
            // Load the exercise note when view appears
            loadExerciseNote()
        }
    }

    // 🔧 ADD: Function to load exercise note from TrainingManager
    private func loadExerciseNote() {
        // Find the training day using exercise id
        guard let trainingDay = trainingManager.trainingData.first(where: { day in
            day.exercises.contains(where: { $0.id == exercise.id })
        }) else { return }
        
        // Find the real exercise by id to get the correct order index
        guard let realExercise = trainingDay.exercises.first(where: { $0.id == exercise.id }) else { return }
        
        // Generate note key with exercise name
        let noteKey = trainingManager.generateWeightKey(
            day: trainingDay.day,
            exerciseIndex: realExercise.orderIndex,
            exerciseName: exercise.name // 🔧 ADD: Include exercise name
        )
        
        // Load note from backend if available
        if let backendNote = trainingManager.backendExerciseNotes[noteKey] {
            localNote = backendNote
        }
    }

    private func saveWeights() {
        guard let user = authManager.user else { return }
        
        // Find the current training day using exercise id
        let trainingDay = trainingManager.trainingData.first { day in
            day.exercises.contains(where: { $0.id == exercise.id })
        }
        guard let dayModel = trainingDay else {
            trainingManager.errorMessage = "No se encontró el día de entrenamiento."
            return
        }
        
        // Find the real exercise by id to get the correct order index
        guard let realExercise = dayModel.exercises.first(where: { $0.id == exercise.id }) else {
            trainingManager.errorMessage = "No se encontró el ejercicio."
            return
        }
        let orderIndex = realExercise.orderIndex

        Task {
            // 🔧 UPDATE: The saveWeightsToDatabase method already expects exerciseName parameter
            // which was added in the TrainingManager fix
            await trainingManager.saveWeightsToDatabase(
                day: dayModel.day, // Use the exact value from the model
                exerciseIndex: orderIndex,
                exerciseName: exercise.name, // 🔧 ADD: Pass exercise name
                note: localNote,
                userId: user.id
            )
        }
    }
}
