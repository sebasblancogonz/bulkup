//
//  WeightTrackingView.swift
//  bulkup
//
//  Created by sebastian.blanco on 18/8/25.
//
import SwiftUI
import SwiftData

struct WeightTrackingView: View {
    let exercise: Exercise
    let exerciseIndex: Int
    let dayName: String
    @Binding var localNote: String
    let isSaving: Bool
    let isSaved: Bool
    
    @EnvironmentObject var trainingManager: TrainingManager
    @EnvironmentObject var authManager: AuthManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "dumbbell.fill")
                    .foregroundColor(.blue)
                
                Text("Registro de Pesos")
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            
            // Grid de series
            LazyVGrid(columns: createColumns(), spacing: 12) {
                ForEach(0..<exercise.sets, id: \.self) { setIndex in
                    WeightSetView(
                        setIndex: setIndex,
                        exercise: exercise,
                        exerciseIndex: exerciseIndex,
                        dayName: dayName
                    )
                    .environmentObject(trainingManager)
                }
            }
            
            // Campo de notas
            VStack(alignment: .leading, spacing: 8) {
                Text("Notas del ejercicio")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                TextField("Agregar notas sobre técnica, sensaciones, etc.", text: $localNote, axis: .vertical)
                    .textFieldStyle(.roundedBorder)
                    .lineLimit(2...4)
            }
            
            // Botón de guardar
            HStack {
                Spacer()
                
                Button(action: saveWeights) {
                    HStack(spacing: 8) {
                        if isSaving {
                            ProgressView()
                                .scaleEffect(0.8)
                        } else if isSaved {
                            Image(systemName: "checkmark.circle.fill")
                        } else {
                            Image(systemName: "square.and.arrow.down")
                        }
                        
                        Text(isSaving ? "Guardando..." : isSaved ? "¡Guardado!" : "Guardar")
                            .fontWeight(.semibold)
                    }
                    .frame(minWidth: 120)
                    .frame(height: 44)
                    .background(
                        isSaved ? Color.green : Color.blue
                    )
                    .foregroundColor(.white)
                    .cornerRadius(12)
                    .disabled(isSaving)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6).opacity(0.5))
        .cornerRadius(12)
    }
    
    private func createColumns() -> [GridItem] {
        let columnCount = min(exercise.sets, 4) // Máximo 4 columnas
        return Array(repeating: GridItem(.flexible()), count: columnCount)
    }
    
    private func saveWeights() {
        guard let user = authManager.user else { return }
        
        Task {
            await trainingManager.saveWeightsToDatabase(
                day: dayName,
                exerciseIndex: exerciseIndex,
                exerciseName: exercise.name,
                note: localNote,
                userId: user.id
            )
        }
    }
}
