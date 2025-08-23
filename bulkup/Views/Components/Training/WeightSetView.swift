//
//  WeightSetView.swift
//  bulkup
//
//  Fixed version with exercise name included in weight key generation
//

import SwiftData
import SwiftUI

struct WeightSetView: View {
    let setIndex: Int
    let exercise: Exercise
    let exerciseIndex: Int
    let dayName: String
    var onSubmit: (() -> Void)? = nil

    @EnvironmentObject var trainingManager: TrainingManager
    @State private var weightText: String = ""
    @FocusState private var isFocused: Bool

    // Computed property to normalize the day name
    private var normalizedDayName: String {
        // Normalize the day name to match what's stored in the database
        let dayMapping: [String: String] = [
            "lunes": "lunes",
            "martes": "martes",
            "miércoles": "miercoles",
            "jueves": "jueves",
            "viernes": "viernes",
            "sábado": "sabado",
            "domingo": "domingo",
        ]

        let lowercased = dayName.lowercased()
        return dayMapping[lowercased] ?? dayName.lowercased()
    }

    var body: some View {
        // 🔧 UPDATE: Include exercise name in weight key generation
        let weightKey = trainingManager.generateWeightKey(
            day: normalizedDayName,
            exerciseIndex: exerciseIndex,
            exerciseName: exercise.name,  // 🔧 ADD: Pass exercise name
            setIndex: setIndex
        )

        let hasWeight = (trainingManager.weights[weightKey] ?? 0) > 0

        VStack(spacing: 8) {
            // Header de la serie
            HStack {
                Circle()
                    .fill(hasWeight ? Color.green : Color.gray.opacity(0.3))
                    .frame(width: 8, height: 8)

                Text("Serie \(setIndex + 1)")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)

                Spacer()

                if hasWeight {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.caption)
                        .foregroundColor(.green)
                }
            }

            // Input de peso
            VStack(alignment: .leading, spacing: 4) {
                Text("Peso (kg)")
                    .font(.caption2)
                    .foregroundColor(.secondary)

                HStack {
                    TextField("0", text: $weightText)
                        .keyboardType(.decimalPad)
                        .focused($isFocused)
                        .onSubmit {
                            onSubmit?()
                        }
                        .submitLabel(.done)
                        .textFieldStyle(.roundedBorder)
                        .frame(height: 36)
                        .background(
                            hasWeight
                                ? Color.green.opacity(0.1)
                                : Color(.systemBackground)
                        )
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(
                                    hasWeight
                                        ? Color.green : Color.gray.opacity(0.3),
                                    lineWidth: 1
                                )
                        )

                    Text("kg")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(12)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(8)
        .onAppear {
            loadWeight()
        }
        .onChange(of: dayName) { _, _ in
            loadWeight()
        }
        .onChange(of: weightText) { _, newValue in
            if let weight = Double(newValue) {
                // 🔧 UPDATE: Pass exercise name to updateWeight
                trainingManager.updateWeight(
                    day: normalizedDayName,
                    exerciseIndex: exerciseIndex,
                    exerciseName: exercise.name,  // 🔧 ADD: Pass exercise name
                    setIndex: setIndex,
                    weight: weight
                )
            } else if newValue.isEmpty {
                // 🔧 UPDATE: Pass exercise name to updateWeight
                trainingManager.updateWeight(
                    day: normalizedDayName,
                    exerciseIndex: exerciseIndex,
                    exerciseName: exercise.name,  // 🔧 ADD: Pass exercise name
                    setIndex: setIndex,
                    weight: 0
                )
            }
        }
    }

    private func loadWeight() {
        // 🔧 UPDATE: Include exercise name in weight key generation
        let weightKey = trainingManager.generateWeightKey(
            day: normalizedDayName,
            exerciseIndex: exerciseIndex,
            exerciseName: exercise.name,  // 🔧 ADD: Pass exercise name
            setIndex: setIndex
        )

        if let weight = trainingManager.weights[weightKey], weight > 0 {
            weightText = String(format: "%.1f", weight).replacingOccurrences(
                of: ".0",
                with: ""
            )
        } else {
            // 🔧 UPDATE: Try alternative key formats for backwards compatibility
            // Include exercise name in alternative keys too
            let normalizedExerciseName = exercise.name
                .lowercased()
                .replacingOccurrences(of: " ", with: "_")
                .replacingOccurrences(of: "ñ", with: "n")
                .replacingOccurrences(of: "á", with: "a")
                .replacingOccurrences(of: "é", with: "e")
                .replacingOccurrences(of: "í", with: "i")
                .replacingOccurrences(of: "ó", with: "o")
                .replacingOccurrences(of: "ú", with: "u")

            let alternativeKeys = [
                // Legacy formats without exercise name (for backwards compatibility)
                "\(dayName.lowercased())_\(exerciseIndex)_\(setIndex)",
                "\(dayName)_\(exerciseIndex)_\(setIndex)",
                "\(normalizedDayName)_\(exerciseIndex)_\(setIndex)",
                // New formats with exercise name
                "\(normalizedDayName)-\(exerciseIndex)-\(normalizedExerciseName)-\(setIndex)",
                "\(dayName.lowercased())-\(exerciseIndex)-\(normalizedExerciseName)-\(setIndex)",
            ]

            for key in alternativeKeys {
                if let weight = trainingManager.weights[key], weight > 0 {
                    weightText = String(format: "%.1f", weight)
                        .replacingOccurrences(of: ".0", with: "")

                    // 🔧 ADD: Migrate old format to new format
                    trainingManager.updateWeight(
                        day: normalizedDayName,
                        exerciseIndex: exerciseIndex,
                        exerciseName: exercise.name,
                        setIndex: setIndex,
                        weight: weight
                    )
                    break
                }
            }
        }
    }
}
