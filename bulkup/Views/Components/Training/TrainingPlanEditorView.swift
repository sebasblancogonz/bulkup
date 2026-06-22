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
                VStack(spacing: Spacing.xl) {
                    // Plan Basic Info
                    planInfoSection

                    // Training Days Section
                    trainingDaysSection

                    // Error Message
                    if let errorMessage = errorMessage {
                        Text(errorMessage)
                            .font(BulkUpFont.body())
                            .foregroundColor(BulkUpColors.error)
                            .padding()
                            .background(BulkUpColors.error.opacity(0.1))
                            .cornerRadius(CornerRadius.small)
                    }
                }
                .padding(Spacing.lg)
            }
            .background(BulkUpColors.background)
            .navigationTitle(isEditing ? LocalizedStringKey("Editar Plan") : LocalizedStringKey("Nuevo Plan"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancelar") { dismiss() }
                        .foregroundColor(BulkUpColors.training)
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(isSaving ? LocalizedStringKey("Guardando...") : LocalizedStringKey("Guardar")) {
                        savePlan()
                    }
                    .disabled(
                        isSaving || planName.isEmpty || trainingDays.isEmpty
                    )
                    .fontWeight(.semibold)
                    .foregroundColor(BulkUpColors.training)
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
        VStack(alignment: .leading, spacing: Spacing.lg) {
            Text("Información del Plan")
                .font(BulkUpFont.cardTitle())
                .foregroundColor(BulkUpColors.textPrimary)

            TextField("Nombre del plan", text: $planName)
                .padding(Spacing.md)
                .background(BulkUpColors.surface)
                .cornerRadius(CornerRadius.small)
                .foregroundColor(BulkUpColors.textPrimary)

            Toggle("Fechas específicas", isOn: $useCustomDates)
                .tint(BulkUpColors.training)
                .foregroundColor(BulkUpColors.textPrimary)

            if useCustomDates {
                VStack(spacing: Spacing.md) {
                    DatePicker(
                        "Fecha inicio",
                        selection: $planStartDate,
                        displayedComponents: .date
                    )
                    .foregroundColor(BulkUpColors.textPrimary)
                    DatePicker(
                        "Fecha fin",
                        selection: $planEndDate,
                        displayedComponents: .date
                    )
                    .foregroundColor(BulkUpColors.textPrimary)
                }
                .padding(.leading)
            }
        }
        .padding(Spacing.lg)
        .background(BulkUpColors.surfaceElevated)
        .cornerRadius(CornerRadius.medium)
    }

    private var trainingDaysSection: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            HStack {
                Text("Días de Entrenamiento")
                    .font(BulkUpFont.cardTitle())
                    .foregroundColor(BulkUpColors.textPrimary)

                Spacer()

                Button {
                    showingAddDay = true
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(BulkUpFont.sectionHeader())
                        .foregroundColor(BulkUpColors.accent)
                }
            }

            if trainingDays.isEmpty {
                VStack(spacing: Spacing.md) {
                    Image(systemName: "calendar.badge.plus")
                        .font(.system(size: 40))
                        .foregroundColor(BulkUpColors.textTertiary)

                    Text("No hay días de entrenamiento")
                        .font(BulkUpFont.cardTitle())
                        .foregroundColor(BulkUpColors.textSecondary)

                    Text("Añade tu primer día para comenzar")
                        .font(BulkUpFont.body())
                        .foregroundColor(BulkUpColors.textSecondary)
                }
                .frame(maxWidth: .infinity)
                .padding(40)
                .background(BulkUpColors.surfaceElevated)
                .cornerRadius(CornerRadius.medium)
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

                // Refresh the active plan so name/data changes show immediately.
                await trainingManager.loadActiveTrainingPlan(userId: userId)

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
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text(day.dayName)
                        .font(BulkUpFont.cardTitle())
                        .foregroundColor(BulkUpColors.textPrimary)

                    if !day.workoutName.isEmpty {
                        Text(day.workoutName)
                            .font(BulkUpFont.caption())
                            .foregroundColor(BulkUpColors.textSecondary)
                    }
                }

                Spacer()

                Text("\(day.exercises.count) ejercicios")
                    .font(BulkUpFont.caption())
                    .foregroundColor(BulkUpColors.textSecondary)

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
                        .font(BulkUpFont.sectionHeader())
                        .foregroundColor(BulkUpColors.textTertiary)
                }
            }
            .padding(Spacing.lg)
            .contentShape(Rectangle())
            .onTapGesture {
                withAnimation(.spring()) {
                    isExpanded.toggle()
                }
            }

            // Expanded Content
            if isExpanded {
                Divider()

                VStack(spacing: Spacing.md) {
                    // Day name and workout name editors
                    VStack(spacing: Spacing.sm) {
                        TextField("Nombre del día", text: $day.dayName)
                            .padding(Spacing.md)
                            .background(BulkUpColors.surfaceElevated)
                            .cornerRadius(CornerRadius.small)
                            .foregroundColor(BulkUpColors.textPrimary)

                        TextField(
                            "Nombre del entrenamiento (opcional)",
                            text: $day.workoutName
                        )
                        .padding(Spacing.md)
                        .background(BulkUpColors.surfaceElevated)
                        .cornerRadius(CornerRadius.small)
                        .foregroundColor(BulkUpColors.textPrimary)
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
                        .padding(Spacing.lg)
                        .background(BulkUpColors.training.opacity(0.1))
                        .foregroundColor(BulkUpColors.training)
                        .cornerRadius(CornerRadius.small)
                    }
                }
                .padding(Spacing.lg)
                .transition(.opacity)
            }
        }
        .background(BulkUpColors.surface)
        .cornerRadius(CornerRadius.medium)
        .overlay(RoundedRectangle(cornerRadius: CornerRadius.medium).stroke(BulkUpColors.border, lineWidth: 0.5))
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
        VStack(spacing: Spacing.sm) {
            HStack {
                Text(exercise.name)
                    .font(BulkUpFont.body())
                    .foregroundColor(BulkUpColors.textPrimary)

                Spacer()

                Text("\(exercise.sets) × \(exercise.reps)")
                    .font(BulkUpFont.caption())
                    .foregroundColor(BulkUpColors.textSecondary)

                Button {
                    withAnimation(.spring()) {
                        isExpanded.toggle()
                    }
                } label: {
                    Image(
                        systemName: isExpanded ? "chevron.up" : "chevron.down"
                    )
                    .font(BulkUpFont.caption())
                    .foregroundColor(BulkUpColors.training)
                }
            }

            if isExpanded {
                VStack(spacing: Spacing.md) {
                    TextField("Nombre del ejercicio", text: $exercise.name)
                        .padding(Spacing.md)
                        .background(BulkUpColors.surface)
                        .cornerRadius(CornerRadius.small)
                        .foregroundColor(BulkUpColors.textPrimary)

                    HStack {
                        VStack(alignment: .leading) {
                            Text("Series")
                                .font(BulkUpFont.caption())
                                .foregroundColor(BulkUpColors.textSecondary)
                            TextField(
                                "3",
                                value: $exercise.sets,
                                format: .number
                            )
                            .padding(Spacing.md)
                            .background(BulkUpColors.surface)
                            .cornerRadius(CornerRadius.small)
                            .keyboardType(.numberPad)
                            .foregroundColor(BulkUpColors.textPrimary)
                        }

                        VStack(alignment: .leading) {
                            Text("Repeticiones")
                                .font(BulkUpFont.caption())
                                .foregroundColor(BulkUpColors.textSecondary)
                            TextField("12", text: $exercise.reps)
                                .padding(Spacing.md)
                                .background(BulkUpColors.surface)
                                .cornerRadius(CornerRadius.small)
                                .foregroundColor(BulkUpColors.textPrimary)
                        }

                        VStack(alignment: .leading) {
                            Text("Descanso (s)")
                                .font(BulkUpFont.caption())
                                .foregroundColor(BulkUpColors.textSecondary)
                            TextField(
                                "90",
                                value: $exercise.restSeconds,
                                format: .number
                            )
                            .padding(Spacing.md)
                            .background(BulkUpColors.surface)
                            .cornerRadius(CornerRadius.small)
                            .keyboardType(.numberPad)
                            .foregroundColor(BulkUpColors.textPrimary)
                        }
                    }

                    TextField("Notas (opcional)", text: $exercise.notes)
                        .padding(Spacing.md)
                        .background(BulkUpColors.surface)
                        .cornerRadius(CornerRadius.small)
                        .foregroundColor(BulkUpColors.textPrimary)

                    HStack {
                        VStack(alignment: .leading) {
                            Text("Tempo")
                                .font(BulkUpFont.caption())
                                .foregroundColor(BulkUpColors.textSecondary)
                            TextField("2-1-1", text: $exercise.tempo)
                                .padding(Spacing.md)
                                .background(BulkUpColors.surface)
                                .cornerRadius(CornerRadius.small)
                                .foregroundColor(BulkUpColors.textPrimary)
                        }

                        VStack(alignment: .leading) {
                            Text("Seguir peso")
                                .font(BulkUpFont.caption())
                                .foregroundColor(BulkUpColors.textSecondary)
                            Toggle("", isOn: $exercise.weightTracking)
                                .tint(BulkUpColors.training)
                        }
                    }

                    Button(
                        "Eliminar ejercicio",
                        role: .destructive,
                        action: onDelete
                    )
                    .font(BulkUpFont.caption())
                    .foregroundColor(BulkUpColors.error)
                }
                .padding(.top, Spacing.sm)
            }
        }
        .padding(Spacing.lg)
        .background(BulkUpColors.surfaceElevated)
        .cornerRadius(CornerRadius.small)
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
                    .font(BulkUpFont.sectionHeader())
                    .foregroundColor(BulkUpColors.textPrimary)

                VStack(alignment: .leading, spacing: Spacing.lg) {
                    VStack(alignment: .leading) {
                        Text("Día de la semana")
                            .font(BulkUpFont.cardTitle())
                            .foregroundColor(BulkUpColors.textPrimary)

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
                            .font(BulkUpFont.cardTitle())
                            .foregroundColor(BulkUpColors.textPrimary)

                        TextField("Ej: Push (Empujes)", text: $workoutName)
                            .padding(Spacing.md)
                            .background(BulkUpColors.surfaceElevated)
                            .cornerRadius(CornerRadius.small)
                            .foregroundColor(BulkUpColors.textPrimary)
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
                .primaryButtonStyle(color: BulkUpColors.training)
                .disabled(dayName.isEmpty)
            }
            .padding(Spacing.lg)
            .background(BulkUpColors.background)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancelar") { dismiss() }
                        .foregroundColor(BulkUpColors.training)
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
                    VStack(alignment: .leading, spacing: Spacing.lg) {
                        TextField("Nombre del ejercicio", text: $exercise.name)
                            .padding(Spacing.md)
                            .background(BulkUpColors.surfaceElevated)
                            .cornerRadius(CornerRadius.small)
                            .foregroundColor(BulkUpColors.textPrimary)

                        HStack {
                            VStack(alignment: .leading) {
                                Text("Series")
                                    .font(BulkUpFont.body())
                                    .foregroundColor(BulkUpColors.textSecondary)
                                TextField(
                                    "3",
                                    value: $exercise.sets,
                                    format: .number
                                )
                                .padding(Spacing.md)
                                .background(BulkUpColors.surfaceElevated)
                                .cornerRadius(CornerRadius.small)
                                .keyboardType(.numberPad)
                                .foregroundColor(BulkUpColors.textPrimary)
                            }

                            VStack(alignment: .leading) {
                                Text("Repeticiones")
                                    .font(BulkUpFont.body())
                                    .foregroundColor(BulkUpColors.textSecondary)
                                TextField("12 o 8-12", text: $exercise.reps)
                                    .padding(Spacing.md)
                                    .background(BulkUpColors.surfaceElevated)
                                    .cornerRadius(CornerRadius.small)
                                    .foregroundColor(BulkUpColors.textPrimary)
                            }
                        }

                        HStack {
                            VStack(alignment: .leading) {
                                Text("Descanso (segundos)")
                                    .font(BulkUpFont.body())
                                    .foregroundColor(BulkUpColors.textSecondary)
                                TextField(
                                    "90",
                                    value: $exercise.restSeconds,
                                    format: .number
                                )
                                .padding(Spacing.md)
                                .background(BulkUpColors.surfaceElevated)
                                .cornerRadius(CornerRadius.small)
                                .keyboardType(.numberPad)
                                .foregroundColor(BulkUpColors.textPrimary)
                            }

                            VStack(alignment: .leading) {
                                Text("Tempo")
                                    .font(BulkUpFont.body())
                                    .foregroundColor(BulkUpColors.textSecondary)
                                TextField("2-1-1", text: $exercise.tempo)
                                    .padding(Spacing.md)
                                    .background(BulkUpColors.surfaceElevated)
                                    .cornerRadius(CornerRadius.small)
                                    .foregroundColor(BulkUpColors.textPrimary)
                            }
                        }

                        TextField("Notas (opcional)", text: $exercise.notes)
                            .padding(Spacing.md)
                            .background(BulkUpColors.surfaceElevated)
                            .cornerRadius(CornerRadius.small)
                            .foregroundColor(BulkUpColors.textPrimary)

                        Toggle(
                            "Seguimiento de peso",
                            isOn: $exercise.weightTracking
                        )
                        .tint(BulkUpColors.training)
                        .foregroundColor(BulkUpColors.textPrimary)
                    }
                }
                .padding(Spacing.lg)
            }
            .background(BulkUpColors.background)
            .navigationTitle("Nuevo Ejercicio")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancelar") { dismiss() }
                        .foregroundColor(BulkUpColors.training)
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Añadir") {
                        onAdd(exercise)
                        dismiss()
                    }
                    .disabled(exercise.name.isEmpty)
                    .foregroundColor(BulkUpColors.training)
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
