//
//  WeightTrackingView.swift
//  bulkup
//
//  Created by sebastian.blanco on 18/8/25.
//

import SwiftData
import SwiftUI

struct WeightTrackingView: View {
    let exercise: Exercise
    let exerciseIndex: Int
    let currentDate: Date  // ✅ Fecha del calendario para guardar
    @Binding var localNote: String
    let isSaving: Bool
    let isSaved: Bool

    @EnvironmentObject var trainingManager: TrainingManager
    @EnvironmentObject var authManager: AuthManager

    // ✅ Formateador para convertir currentDate a día de la semana
    private var dayFormatter: DateFormatter {
        let f = DateFormatter()
        f.locale = Locale(identifier: "es_ES")
        f.dateFormat = "EEEE"
        f.calendar = Calendar(identifier: .gregorian)
        f.calendar?.firstWeekday = 2  // Lunes como primer día
        return f
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // ✅ Sin navegación de fechas - solo el contenido

            // Scroll horizontal de sets
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

            // Nota del ejercicio
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
            
            // Botón guardar
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
    }

    private func saveWeights() {
        guard let user = authManager.user else { return }
        // Buscar el día de entrenamiento actual usando el id del ejercicio
        let trainingDay = trainingManager.trainingData.first { day in
            day.exercises.contains(where: { $0.id == exercise.id })
        }
        guard let dayModel = trainingDay else {
            trainingManager.errorMessage = "No se encontró el día de entrenamiento."
            return
        }
        // Buscar el ejercicio real por id
        guard let realExercise = dayModel.exercises.first(where: { $0.id == exercise.id }) else {
            trainingManager.errorMessage = "No se encontró el ejercicio."
            return
        }
        let orderIndex = realExercise.orderIndex

        Task {
            await trainingManager.saveWeightsToDatabase(
                day: dayModel.day, // Usa el valor exacto del modelo
                exerciseIndex: orderIndex,
                exerciseName: exercise.name,
                note: localNote,
                userId: user.id
            )
        }
    }
}
