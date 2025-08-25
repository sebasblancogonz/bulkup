//
//  ExerciseCardView.swift
//  bulkup
//
//  Fixed version with correct weight display order
//

import SwiftUI
import SwiftData

struct ExerciseCardView: View {
    let exercise: Exercise
    let exerciseIndex: Int
    let dayName: String
    let currentDate: Date
    
    @StateObject var trainingManager = TrainingManager.shared
    @StateObject var authManager = AuthManager.shared
    
    @State private var isExpanded = false
    @State private var localNote: String = ""
    @State private var showingWeightTracking = false
    
    // Computed properties for UI state
    private var exerciseKey: String {
        trainingManager.generateWeightKey(
            day: normalizedDayName,
            exerciseIndex: exercise.orderIndex,
            exerciseName: exercise.name
        )
    }
    
    private var isSaving: Bool {
        trainingManager.savingWeights[exerciseKey] ?? false
    }
    
    private var isSaved: Bool {
        trainingManager.savedWeights[exerciseKey] ?? false
    }
    
    private var normalizedDayName: String {
        let dayMapping: [String: String] = [
            "lunes": "lunes",
            "martes": "martes",
            "miércoles": "miercoles",
            "jueves": "jueves",
            "viernes": "viernes",
            "sábado": "sabado",
            "domingo": "domingo"
        ]
        
        let lowercased = dayName.lowercased()
        return dayMapping[lowercased] ?? dayName.lowercased()
    }
    
    private var completedSets: Int {
        trainingManager.getCompletedSets(
            day: normalizedDayName,
            exerciseIndex: exercise.orderIndex,
            exerciseName: exercise.name,
            totalSets: exercise.sets
        )
    }
    
    private var completionPercentage: Double {
        guard exercise.sets > 0 else { return 0 }
        return Double(completedSets) / Double(exercise.sets) * 100
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Main card button
            Button(action: {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    isExpanded.toggle()
                    if isExpanded {
                        showingWeightTracking = exercise.weightTracking
                        loadExerciseNote()
                    }
                }
            }) {
                HStack(spacing: 16) {
                    // Exercise indicator with completion
                    ZStack {
                        Circle()
                            .stroke(Color.gray.opacity(0.2), lineWidth: 3)
                            .frame(width: 44, height: 44)
                        
                        Circle()
                            .trim(from: 0, to: completionPercentage / 100)
                            .stroke(
                                completionPercentage == 100 ? Color.green : Color.blue,
                                style: StrokeStyle(lineWidth: 3, lineCap: .round)
                            )
                            .frame(width: 44, height: 44)
                            .rotationEffect(.degrees(-90))
                            .animation(.easeInOut(duration: 0.3), value: completionPercentage)
                        
                        if completionPercentage == 100 {
                            Image(systemName: "checkmark")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.green)
                                .transition(.scale)
                        } else {
                            Text("\(completedSets)/\(exercise.sets)")
                                .font(.caption2)
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)
                        }
                    }
                    
                    // Exercise info
                    VStack(alignment: .leading, spacing: 6) {
                        Text(exercise.name)
                            .font(.headline)
                            .foregroundColor(.primary)
                            .lineLimit(2)
                        
                        HStack(spacing: 12) {
                            // Sets and reps
                            Label("\(exercise.sets) x \(exercise.reps)", systemImage: "arrow.trianglehead.2.counterclockwise")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            // Rest time
                            if exercise.restSeconds > 0 {
                                Label("\(exercise.restSeconds)s", systemImage: "clock")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    
                    Spacer()
                    
                    // Chevron indicator
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.blue)
                        .frame(width: 28, height: 28)
                        .background(Color.blue.opacity(0.1))
                        .clipShape(Circle())
                        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isExpanded)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .contentShape(Rectangle())
            }
            .buttonStyle(PlainButtonStyle())
            
            // Expanded content
            if isExpanded {
                VStack(spacing: 0) {
                    Divider()
                        .padding(.horizontal, 16)
                    
                    VStack(spacing: 16) {
                        // Exercise notes if available
                        if let notes = exercise.notes, !notes.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Label("Notas del ejercicio", systemImage: "note.text")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                Text(notes)
                                    .font(.caption)
                                    .foregroundColor(.primary)
                                    .padding(12)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(Color(.tertiarySystemBackground))
                                    .cornerRadius(8)
                            }
                        }
                        
                        // Weight tracking section
                        if exercise.weightTracking {
                            VStack(spacing: 16) {
                                // Section header
                                HStack {
                                    Label("Registro de Peso", systemImage: "scalemass")
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                    
                                    Spacer()
                                    
                                    Text("\(Int(completionPercentage))%")
                                        .font(.caption)
                                        .fontWeight(.semibold)
                                        .foregroundColor(completionPercentage == 100 ? .green : .blue)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(
                                            completionPercentage == 100
                                                ? Color.green.opacity(0.1)
                                                : Color.blue.opacity(0.1)
                                        )
                                        .cornerRadius(12)
                                }
                                
                                // Weight sets - FIXED ORDER
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 12) {
                                        // Sort sets in correct order (0, 1, 2, etc.)
                                        ForEach(0..<exercise.sets, id: \.self) { setIndex in
                                            CompactWeightSetView(
                                                setIndex: setIndex,
                                                exercise: exercise,
                                                exerciseIndex: exercise.orderIndex,
                                                dayName: dayName
                                            )
                                            .frame(width: 100)
                                        }
                                    }
                                    .padding(.horizontal, 4)
                                }
                                .frame(height: 100)
                                
                                // Exercise note input
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Notas de hoy")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    
                                    TextEditor(text: $localNote)
                                        .frame(height: 60)
                                        .padding(8)
                                        .background(Color(.secondarySystemBackground))
                                        .cornerRadius(8)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 8)
                                                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                                        )
                                }
                                
                                // Save button
                                Button(action: saveWeights) {
                                    HStack {
                                        if isSaving {
                                            ProgressView()
                                                .scaleEffect(0.8)
                                        } else if isSaved {
                                            Image(systemName: "checkmark.circle.fill")
                                                .foregroundColor(.green)
                                        } else {
                                            Image(systemName: "square.and.arrow.down")
                                        }
                                        
                                        Text(isSaved ? "Guardado" : "Guardar")
                                            .fontWeight(.medium)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background(isSaved ? Color.green.opacity(0.2) : Color.blue)
                                    .foregroundColor(isSaved ? .green : .white)
                                    .cornerRadius(10)
                                }
                                .disabled(isSaving)
                            }
                        }
                    }
                    .padding(16)
                }
                .transition(.asymmetric(
                    insertion: .move(edge: .top).combined(with: .opacity),
                    removal: .move(edge: .top).combined(with: .opacity)
                ))
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
        .padding(.horizontal)
    }
    
    private func loadExerciseNote() {
        let noteKey = trainingManager.generateWeightKey(
            day: normalizedDayName,
            exerciseIndex: exercise.orderIndex,
            exerciseName: exercise.name
        )
        
        if let backendNote = trainingManager.backendExerciseNotes[noteKey] {
            localNote = backendNote
        } else {
            localNote = ""
        }
    }
    
    private func saveWeights() {
        guard let user = authManager.user else { return }
        
        Task {
            await trainingManager.saveWeightsToDatabase(
                day: normalizedDayName,
                exerciseIndex: exercise.orderIndex,
                exerciseName: exercise.name,
                note: localNote,
                userId: user.id
            )
        }
    }
}

// Compact weight set view for the horizontal scroll
struct CompactWeightSetView: View {
    let setIndex: Int
    let exercise: Exercise
    let exerciseIndex: Int
    let dayName: String
    
    @EnvironmentObject var trainingManager: TrainingManager
    @State private var weightText: String = ""
    @FocusState private var isFocused: Bool
    
    private var normalizedDayName: String {
        let dayMapping: [String: String] = [
            "lunes": "lunes",
            "martes": "martes",
            "miércoles": "miercoles",
            "jueves": "jueves",
            "viernes": "viernes",
            "sábado": "sabado",
            "domingo": "domingo"
        ]
        
        let lowercased = dayName.lowercased()
        return dayMapping[lowercased] ?? dayName.lowercased()
    }
    
    var body: some View {
        let weightKey = trainingManager.generateWeightKey(
            day: normalizedDayName,
            exerciseIndex: exercise.orderIndex,
            exerciseName: exercise.name,
            setIndex: setIndex
        )
        
        let hasWeight = (trainingManager.weights[weightKey] ?? 0) > 0
        
        VStack(spacing: 6) {
            // Serie header with completion indicator
            HStack(spacing: 4) {
                Circle()
                    .fill(hasWeight ? Color.green : Color.gray.opacity(0.3))
                    .frame(width: 6, height: 6)
                
                Text("Serie \(setIndex + 1)")
                    .font(.caption2)
                    .fontWeight(.medium)
                
                if hasWeight {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 10))
                        .foregroundColor(.green)
                }
            }
            
            // Weight input
            VStack(spacing: 2) {
                Text("Peso (kg)")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
                
                TextField("0", text: $weightText)
                    .keyboardType(.decimalPad)
                    .focused($isFocused)
                    .multilineTextAlignment(.center)
                    .font(.system(size: 14, weight: .medium))
                    .frame(height: 32)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(hasWeight ? Color.green.opacity(0.1) : Color(.tertiarySystemBackground))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(
                                hasWeight ? Color.green.opacity(0.5) : Color.gray.opacity(0.2),
                                lineWidth: 1
                            )
                    )
            }
        }
        .padding(8)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(8)
        .onAppear {
            loadWeight()
        }
        .onChange(of: weightText) { _, newValue in
            if let weight = Double(newValue) {
                trainingManager.updateWeight(
                    day: normalizedDayName,
                    exerciseIndex: exercise.orderIndex,
                    exerciseName: exercise.name,
                    setIndex: setIndex,
                    weight: weight
                )
            } else if newValue.isEmpty {
                trainingManager.updateWeight(
                    day: normalizedDayName,
                    exerciseIndex: exercise.orderIndex,
                    exerciseName: exercise.name,
                    setIndex: setIndex,
                    weight: 0
                )
            }
        }
    }
    
    private func loadWeight() {
        let weightKey = trainingManager.generateWeightKey(
            day: normalizedDayName,
            exerciseIndex: exercise.orderIndex,
            exerciseName: exercise.name,
            setIndex: setIndex
        )
        
        if let weight = trainingManager.weights[weightKey], weight > 0 {
            weightText = String(format: "%.1f", weight).replacingOccurrences(of: ".0", with: "")
        } else {
            weightText = ""
        }
    }
}
