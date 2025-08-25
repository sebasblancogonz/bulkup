//
//  TrainingPlanEditorView.swift
//  bulkup
//
//  Created by sebastianblancogonz on 23/8/25.
//

import SwiftUI

// MARK: - Training Plan Editor View
struct TrainingPlanEditorView: View {
    let planId: String?
    let existingPlan: TrainingPlan?
    @State private var planName: String = ""
    @State private var trainingDays: [EditableTrainingDay] = []
    @State private var planStartDate: Date = Date()
    @State private var planEndDate: Date =
        Calendar.current.date(byAdding: .month, value: 3, to: Date()) ?? Date()
    @State private var useCustomDates = false
    @State private var isSaving = false
    @State private var showingAddDay = false
    @State private var errorMessage: String?

    @EnvironmentObject var trainingManager: TrainingManager
    @EnvironmentObject var authManager: AuthManager
    @Environment(\.dismiss) var dismiss

    // True if editing existing plan, false if creating new
    private var isEditing: Bool { planId != nil }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Plan Basic Info
                    planInfoSection

                    // Training Days Section
                    trainingDaysSection

                    // Error Message
                    if let errorMessage = errorMessage {
                        Text(errorMessage)
                            .font(.subheadline)
                            .foregroundColor(.red)
                            .padding()
                            .background(Color.red.opacity(0.1))
                            .cornerRadius(8)
                    }
                }
                .padding()
            }
            .navigationTitle(isEditing ? "Editar Plan" : "Nuevo Plan")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancelar") { dismiss() }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(isSaving ? "Guardando..." : "Guardar") {
                        savePlan()
                    }
                    .disabled(
                        isSaving || planName.isEmpty || trainingDays.isEmpty
                    )
                    .fontWeight(.semibold)
                }
            }
        }
        .sheet(isPresented: $showingAddDay) {
            AddTrainingDayView { newDay in
                trainingDays.append(newDay)
            }
        }
        .onAppear {
            loadPlanData()
        }
    }

    private var planInfoSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Información del Plan")
                .font(.headline)
                .fontWeight(.semibold)

            TextField("Nombre del plan", text: $planName)
                .textFieldStyle(.roundedBorder)

            Toggle("Fechas específicas", isOn: $useCustomDates)

            if useCustomDates {
                VStack(spacing: 12) {
                    DatePicker(
                        "Fecha inicio",
                        selection: $planStartDate,
                        displayedComponents: .date
                    )
                    DatePicker(
                        "Fecha fin",
                        selection: $planEndDate,
                        displayedComponents: .date
                    )
                }
                .padding(.leading)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }

    private var trainingDaysSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Días de Entrenamiento")
                    .font(.headline)
                    .fontWeight(.semibold)

                Spacer()

                Button {
                    showingAddDay = true
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                        .foregroundColor(.blue)
                }
            }

            if trainingDays.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "calendar.badge.plus")
                        .font(.system(size: 40))
                        .foregroundColor(.gray)

                    Text("No hay días de entrenamiento")
                        .font(.headline)
                        .foregroundColor(.secondary)

                    Text("Añade tu primer día para comenzar")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(40)
                .background(Color(.systemGray6))
                .cornerRadius(12)
            } else {
                ForEach(Array(trainingDays.enumerated()), id: \.element.id) {
                    index,
                    day in
                    TrainingDayEditorCard(
                        day: $trainingDays[index],
                        onDelete: {
                            trainingDays.remove(at: index)
                        }
                    )
                }
            }
        }
    }

    private func loadPlanData() {
        if let existingPlan = existingPlan {
            planName = existingPlan.name
            useCustomDates = existingPlan.startDate != nil || existingPlan.endDate != nil
            if let startDate = existingPlan.startDate {
                planStartDate = startDate
            }
            if let endDate = existingPlan.endDate {
                planEndDate = endDate
            }
            
            // Convertir TrainingDay completos a EditableTrainingDay
            trainingDays = existingPlan.trainingDays.map { trainingDay in
                EditableTrainingDay(
                    dayName: trainingDay.day,
                    workoutName: trainingDay.workoutName ?? "",
                    exercises: trainingDay.exercises.map { exercise in
                        EditableExercise(
                            name: exercise.name,
                            sets: exercise.sets,
                            reps: exercise.reps,
                            restSeconds: exercise.restSeconds,
                            notes: exercise.notes ?? "",
                            tempo: exercise.tempo ?? "2-1-1",
                            weightTracking: exercise.weightTracking
                        )
                    }
                )
            }
        } else {
            trainingDays = []
        }
    }

    private func savePlan() {
        guard let userId = authManager.user?.id else { return }

        isSaving = true
        errorMessage = nil

        Task {
            do {
                let serverTrainingDays = trainingDays.map { day in
                    ServerTrainingDay(
                        day: day.dayName,
                        workoutName: day.workoutName,
                        output: day.exercises.map { exercise in
                            ServerExercise(
                                name: exercise.name,
                                sets: exercise.sets,
                                reps: exercise.reps,
                                restSeconds: exercise.restSeconds,
                                notes: exercise.notes,
                                tempo: exercise.tempo,
                                weightTracking: exercise.weightTracking
                            )
                        }
                    )
                }

                if let planId = planId {
                    // Update existing plan
                    try await APIService.shared.updateTrainingPlan(
                        planId: planId,
                        userId: userId,
                        filename: planName,
                        trainingData: serverTrainingDays,
                        planStartDate: useCustomDates ? planStartDate : nil,
                        planEndDate: useCustomDates ? planEndDate : nil
                    )
                } else {
                    // Create new plan
                    let _ = try await APIService.shared.createTrainingPlan(
                        userId: userId,
                        filename: planName,
                        trainingData: serverTrainingDays,
                        planStartDate: useCustomDates ? planStartDate : nil,
                        planEndDate: useCustomDates ? planEndDate : nil
                    )
                }

                await MainActor.run {
                    isSaving = false
                    dismiss()
                }

            } catch {
                await MainActor.run {
                    isSaving = false
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
}

// MARK: - Training Day Editor Card
struct TrainingDayEditorCard: View {
    @Binding var day: EditableTrainingDay
    let onDelete: () -> Void

    @State private var isExpanded = false
    @State private var showingExerciseEditor = false

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(day.dayName)
                        .font(.headline)
                        .fontWeight(.semibold)

                    if !day.workoutName.isEmpty {
                        Text(day.workoutName)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                Text("\(day.exercises.count) ejercicios")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Menu {
                    Button("Editar") {
                        isExpanded.toggle()
                    }
                    Button("Añadir Ejercicio") {
                        showingExerciseEditor = true
                    }
                    Button("Eliminar", role: .destructive) {
                        onDelete()
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .font(.title3)
                        .foregroundColor(.gray)
                }
            }
            .padding()
            .contentShape(Rectangle())
            .onTapGesture {
                withAnimation(.spring()) {
                    isExpanded.toggle()
                }
            }

            // Expanded Content
            if isExpanded {
                Divider()

                VStack(spacing: 12) {
                    // Day name and workout name editors
                    VStack(spacing: 8) {
                        TextField("Nombre del día", text: $day.dayName)
                            .textFieldStyle(.roundedBorder)

                        TextField(
                            "Nombre del entrenamiento (opcional)",
                            text: $day.workoutName
                        )
                        .textFieldStyle(.roundedBorder)
                    }

                    // Exercises list
                    ForEach(Array(day.exercises.enumerated()), id: \.element.id)
                    { index, exercise in
                        ExerciseEditorRow(
                            exercise: $day.exercises[index],
                            onDelete: {
                                day.exercises.remove(at: index)
                            }
                        )
                    }

                    // Add Exercise Button
                    Button {
                        showingExerciseEditor = true
                    } label: {
                        HStack {
                            Image(systemName: "plus")
                            Text("Añadir Ejercicio")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue.opacity(0.1))
                        .foregroundColor(.blue)
                        .cornerRadius(8)
                    }
                }
                .padding()
                .transition(.opacity)
            }
        }
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
        .sheet(isPresented: $showingExerciseEditor) {
            ExerciseEditorView { newExercise in
                day.exercises.append(newExercise)
            }
        }
    }
}

// MARK: - Exercise Editor Row
struct ExerciseEditorRow: View {
    @Binding var exercise: EditableExercise
    let onDelete: () -> Void

    @State private var isExpanded = false

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Text(exercise.name)
                    .font(.subheadline)
                    .fontWeight(.medium)

                Spacer()

                Text("\(exercise.sets) × \(exercise.reps)")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Button {
                    withAnimation(.spring()) {
                        isExpanded.toggle()
                    }
                } label: {
                    Image(
                        systemName: isExpanded ? "chevron.up" : "chevron.down"
                    )
                    .font(.caption)
                    .foregroundColor(.blue)
                }
            }

            if isExpanded {
                VStack(spacing: 12) {
                    TextField("Nombre del ejercicio", text: $exercise.name)
                        .textFieldStyle(.roundedBorder)

                    HStack {
                        VStack(alignment: .leading) {
                            Text("Series")
                                .font(.caption)
                            TextField(
                                "3",
                                value: $exercise.sets,
                                format: .number
                            )
                            .textFieldStyle(.roundedBorder)
                            .keyboardType(.numberPad)
                        }

                        VStack(alignment: .leading) {
                            Text("Repeticiones")
                                .font(.caption)
                            TextField("12", text: $exercise.reps)
                                .textFieldStyle(.roundedBorder)
                        }

                        VStack(alignment: .leading) {
                            Text("Descanso (s)")
                                .font(.caption)
                            TextField(
                                "90",
                                value: $exercise.restSeconds,
                                format: .number
                            )
                            .textFieldStyle(.roundedBorder)
                            .keyboardType(.numberPad)
                        }
                    }

                    TextField("Notas (opcional)", text: $exercise.notes)
                        .textFieldStyle(.roundedBorder)

                    HStack {
                        VStack(alignment: .leading) {
                            Text("Tempo")
                                .font(.caption)
                            TextField("2-1-1", text: $exercise.tempo)
                                .textFieldStyle(.roundedBorder)
                        }

                        VStack(alignment: .leading) {
                            Text("Seguir peso")
                                .font(.caption)
                            Toggle("", isOn: $exercise.weightTracking)
                        }
                    }

                    Button(
                        "Eliminar ejercicio",
                        role: .destructive,
                        action: onDelete
                    )
                    .font(.caption)
                }
                .padding(.top, 8)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}

// MARK: - Supporting Views and Models

struct AddTrainingDayView: View {
    let onAdd: (EditableTrainingDay) -> Void
    @Environment(\.dismiss) var dismiss

    @State private var dayName = ""
    @State private var workoutName = ""

    private let weekDays = [
        "Lunes", "Martes", "Miércoles", "Jueves", "Viernes", "Sábado",
        "Domingo",
    ]

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("Añadir Día de Entrenamiento")
                    .font(.title2)
                    .fontWeight(.bold)

                VStack(alignment: .leading, spacing: 16) {
                    VStack(alignment: .leading) {
                        Text("Día de la semana")
                            .font(.headline)

                        Picker("Día", selection: $dayName) {
                            ForEach(weekDays, id: \.self) { day in
                                Text(day).tag(day)
                            }
                        }
                        .pickerStyle(.wheel)
                        .frame(height: 120)
                    }

                    VStack(alignment: .leading) {
                        Text("Nombre del entrenamiento")
                            .font(.headline)

                        TextField("Ej: Push (Empujes)", text: $workoutName)
                            .textFieldStyle(.roundedBorder)
                    }
                }

                Spacer()

                Button("Añadir Día") {
                    let newDay = EditableTrainingDay(
                        dayName: dayName.isEmpty ? weekDays[0] : dayName,
                        workoutName: workoutName,
                        exercises: []
                    )
                    onAdd(newDay)
                    dismiss()
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(12)
                .disabled(dayName.isEmpty)
            }
            .padding()
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancelar") { dismiss() }
                }
            }
        }
        .onAppear {
            if dayName.isEmpty {
                dayName = weekDays[0]
            }
        }
    }
}

struct ExerciseEditorView: View {
    let onAdd: (EditableExercise) -> Void
    @Environment(\.dismiss) var dismiss

    @State private var exercise = EditableExercise(
        name: "",
        sets: 3,
        reps: "12",
        restSeconds: 90,
        notes: "",
        tempo: "2-1-1",
        weightTracking: true
    )

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 16) {
                        TextField("Nombre del ejercicio", text: $exercise.name)
                            .textFieldStyle(.roundedBorder)

                        HStack {
                            VStack(alignment: .leading) {
                                Text("Series")
                                    .font(.subheadline)
                                TextField(
                                    "3",
                                    value: $exercise.sets,
                                    format: .number
                                )
                                .textFieldStyle(.roundedBorder)
                                .keyboardType(.numberPad)
                            }

                            VStack(alignment: .leading) {
                                Text("Repeticiones")
                                    .font(.subheadline)
                                TextField("12 o 8-12", text: $exercise.reps)
                                    .textFieldStyle(.roundedBorder)
                            }
                        }

                        HStack {
                            VStack(alignment: .leading) {
                                Text("Descanso (segundos)")
                                    .font(.subheadline)
                                TextField(
                                    "90",
                                    value: $exercise.restSeconds,
                                    format: .number
                                )
                                .textFieldStyle(.roundedBorder)
                                .keyboardType(.numberPad)
                            }

                            VStack(alignment: .leading) {
                                Text("Tempo")
                                    .font(.subheadline)
                                TextField("2-1-1", text: $exercise.tempo)
                                    .textFieldStyle(.roundedBorder)
                            }
                        }

                        TextField("Notas (opcional)", text: $exercise.notes)
                            .textFieldStyle(.roundedBorder)

                        Toggle(
                            "Seguimiento de peso",
                            isOn: $exercise.weightTracking
                        )
                    }
                }
                .padding()
            }
            .navigationTitle("Nuevo Ejercicio")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancelar") { dismiss() }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Añadir") {
                        onAdd(exercise)
                        dismiss()
                    }
                    .disabled(exercise.name.isEmpty)
                }
            }
        }
    }
}

// MARK: - Editable Models
struct EditableTrainingDay: Identifiable {
    let id = UUID()
    var dayName: String
    var workoutName: String
    var exercises: [EditableExercise]
}

struct EditableExercise: Identifiable {
    let id = UUID()
    var name: String
    var sets: Int
    var reps: String
    var restSeconds: Int
    var notes: String
    var tempo: String
    var weightTracking: Bool
}
