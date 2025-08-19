//
//  WeightSetView.swift
//  bulkup
//
//  Created by sebastian.blanco on 18/8/25.
//
import SwiftUI
import SwiftData

struct WeightSetView: View {
    let setIndex: Int
    let exercise: Exercise
    let exerciseIndex: Int
    let dayName: String
    
    @EnvironmentObject var trainingManager: TrainingManager
    @State private var weightText: String = ""
    @FocusState private var isFocused: Bool
    
    var body: some View {
        let weightKey = trainingManager.generateWeightKey(
            day: dayName,
            exerciseIndex: exerciseIndex,
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
                        .textFieldStyle(.roundedBorder)
                        .frame(height: 36)
                        .background(
                            hasWeight ? Color.green.opacity(0.1) : Color(.systemBackground)
                        )
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(
                                    hasWeight ? Color.green : Color.gray.opacity(0.3),
                                    lineWidth: 1
                                )
                        )
                    
                    Text("kg")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(8)
        .background(Color(.systemBackground))
        .cornerRadius(8)
        .onAppear {
            if let weight = trainingManager.weights[weightKey], weight > 0 {
                weightText = String(format: "%.1f", weight).replacingOccurrences(of: ".0", with: "")
            }
        }
        .onChange(of: weightText) { _, newValue in
            if let weight = Double(newValue) {
                trainingManager.updateWeight(
                    day: dayName,
                    exerciseIndex: exerciseIndex,
                    setIndex: setIndex,
                    weight: weight
                )
            } else if newValue.isEmpty {
                trainingManager.updateWeight(
                    day: dayName,
                    exerciseIndex: exerciseIndex,
                    setIndex: setIndex,
                    weight: 0
                )
            }
        }
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Listo") {
                    isFocused = false
                }
            }
        }
    }
}
