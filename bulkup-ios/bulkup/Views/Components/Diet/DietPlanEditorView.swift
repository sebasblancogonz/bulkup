//
//  DietPlanEditorView.swift
//  bulkup
//
//  Created by sebastianblancogonz on 14/4/26.
//

import SwiftUI

// MARK: - Editable Models

struct EditableDietDay: Identifiable {
    let id = UUID()
    var dayName: String
    var meals: [EditableMeal]
    var supplements: [EditableSupplement]
}

struct EditableMeal: Identifiable {
    let id = UUID()
    var type: String
    var time: String
    var options: [EditableMealOption]
}

struct EditableMealOption: Identifiable {
    let id = UUID()
    var optionDescription: String
    var ingredients: [String]
    var instructions: String
}

struct EditableSupplement: Identifiable {
    let id = UUID()
    var name: String
    var dosage: String
    var timing: String
    var frequency: String
}

// MARK: - Diet Plan Editor View

struct DietPlanEditorView: View {
    // When set, the editor updates this plan instead of creating a new one.
    var planId: String? = nil
    var existingPlan: DietPlan? = nil

    @State private var planName: String = ""
    @State private var dietDays: [EditableDietDay] = []
    @State private var isSaving = false
    @State private var showingAddDay = false
    @State private var errorMessage: String?
    @State private var didLoad = false

    @EnvironmentObject var dietManager: DietManager
    @EnvironmentObject var authManager: AuthManager
    @Environment(\.dismiss) var dismiss

    private var isEditing: Bool { planId != nil }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Spacing.xl) {
                    planInfoSection

                    dietDaysSection

                    if let errorMessage = errorMessage {
                        Text(errorMessage)
                            .font(BulkUpFont.body())
                            .foregroundColor(BulkUpColors.error)
                            .padding()
                            .background(BulkUpColors.error.opacity(0.1))
                            .cornerRadius(CornerRadius.small)
                    }

                    // Guardar Plan button
                    Button {
                        savePlan()
                    } label: {
                        HStack(spacing: Spacing.sm) {
                            if isSaving {
                                ProgressView()
                                    .tint(.white)
                            }
                            Text(isSaving ? "Guardando..." : "Guardar Plan")
                                .fontWeight(.semibold)
                        }
                        .primaryButtonStyle(color: BulkUpColors.diet)
                    }
                    .disabled(isSaving || planName.isEmpty || dietDays.isEmpty)
                    .opacity(planName.isEmpty || dietDays.isEmpty ? 0.5 : 1.0)
                }
                .padding()
            }
            .background(BulkUpColors.background)
            .navigationTitle(isEditing ? LocalizedStringKey("Editar Plan de Dieta") : LocalizedStringKey("Nuevo Plan de Dieta"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancelar") { dismiss() }
                }
            }
        }
        .sheet(isPresented: $showingAddDay) {
            AddDietDayView { newDay in
                dietDays.append(newDay)
            }
        }
        .onAppear(perform: loadExistingPlan)
    }

    // MARK: - Prefill (edit mode)

    private func loadExistingPlan() {
        guard !didLoad, let plan = existingPlan else { return }
        didLoad = true
        planName = plan.name
        dietDays = plan.serverDietData.map { day in
            EditableDietDay(
                dayName: day.day,
                meals: day.meals.map { meal in
                    EditableMeal(
                        type: meal.type,
                        time: meal.time,
                        options: (meal.options ?? []).map { option in
                            EditableMealOption(
                                optionDescription: option.description,
                                ingredients: option.ingredients,
                                instructions: option.instructions?.joined(separator: "\n") ?? ""
                            )
                        }
                    )
                },
                supplements: (day.supplements ?? []).map { supplement in
                    EditableSupplement(
                        name: supplement.name,
                        dosage: supplement.dosage,
                        timing: supplement.timing,
                        frequency: supplement.frequency
                    )
                }
            )
        }
    }

    // MARK: - Plan Info Section

    private var planInfoSection: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            Text("Informacion del Plan")
                .font(BulkUpFont.cardTitle())
                .foregroundColor(BulkUpColors.textPrimary)

            TextField("Nombre del plan", text: $planName)
                .textFieldStyle(.roundedBorder)
                .submitLabel(.done)
        }
        .flatCardStyle()
    }

    // MARK: - Diet Days Section

    private var dietDaysSection: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            HStack {
                Text("Dias")
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

            if dietDays.isEmpty {
                VStack(spacing: Spacing.md) {
                    Image(systemName: "calendar.badge.plus")
                        .font(.system(size: 40))
                        .foregroundColor(BulkUpColors.textTertiary)

                    Text("No hay dias agregados")
                        .font(BulkUpFont.cardTitle())
                        .foregroundColor(BulkUpColors.textSecondary)

                    Text("Anade tu primer dia para comenzar")
                        .font(BulkUpFont.body())
                        .foregroundColor(BulkUpColors.textSecondary)
                }
                .frame(maxWidth: .infinity)
                .padding(40)
                .background(BulkUpColors.surfaceElevated)
                .cornerRadius(CornerRadius.medium)
            } else {
                ForEach(Array(dietDays.enumerated()), id: \.element.id) { index, _ in
                    DietDayEditorCard(
                        day: $dietDays[index],
                        onDelete: {
                            dietDays.remove(at: index)
                        }
                    )
                }
            }
        }
    }

    // MARK: - Save Plan

    private func savePlan() {
        guard let userId = authManager.user?.id else { return }

        isSaving = true
        errorMessage = nil

        Task {
            do {
                let serverDietDays = dietDays.map { day in
                    ServerDietDay(
                        day: day.dayName,
                        meals: day.meals.map { meal in
                            ServerMeal(
                                type: meal.type,
                                time: meal.time,
                                date: nil,
                                notes: nil,
                                options: meal.options.map { option in
                                    ServerMeal.MealOptionData(
                                        description: option.optionDescription,
                                        ingredients: option.ingredients.filter { !$0.isEmpty },
                                        instructions: option.instructions.isEmpty ? nil : [option.instructions]
                                    )
                                },
                                conditions: nil
                            )
                        },
                        supplements: day.supplements.isEmpty ? nil : day.supplements.map { supplement in
                            ServerSupplement(
                                name: supplement.name,
                                dosage: supplement.dosage,
                                timing: supplement.timing,
                                frequency: supplement.frequency,
                                notes: nil
                            )
                        }
                    )
                }

                if let planId = planId {
                    try await APIService.shared.updateDietPlan(
                        planId: planId,
                        userId: userId,
                        filename: planName,
                        dietData: serverDietDays
                    )
                } else {
                    let _ = try await APIService.shared.createDietPlan(
                        userId: userId,
                        filename: planName,
                        dietData: serverDietDays
                    )
                }

                // Reload the active diet plan
                await dietManager.loadActiveDietPlan(userId: userId)

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

// MARK: - Diet Day Editor Card

struct DietDayEditorCard: View {
    @Binding var day: EditableDietDay
    let onDelete: () -> Void

    @State private var isExpanded = true
    @State private var showingAddMeal = false
    @State private var showingAddSupplement = false

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text(day.dayName)
                        .font(BulkUpFont.cardTitle())
                        .foregroundColor(BulkUpColors.textPrimary)

                    Text("\(day.meals.count) comidas")
                        .font(BulkUpFont.caption())
                        .foregroundColor(BulkUpColors.textSecondary)
                }

                Spacer()

                Menu {
                    Button("Agregar comida") {
                        showingAddMeal = true
                    }

                    Button("Agregar suplemento") {
                        showingAddSupplement = true
                    }

                    Divider()

                    Button("Eliminar dia", role: .destructive) {
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
                    // Meals
                    if day.meals.isEmpty {
                        Text("Sin comidas. Toca el menu para agregar.")
                            .font(BulkUpFont.caption())
                            .foregroundColor(BulkUpColors.textSecondary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, Spacing.sm)
                    } else {
                        ForEach(Array(day.meals.enumerated()), id: \.element.id) { index, _ in
                            MealEditorRow(
                                meal: $day.meals[index],
                                onDelete: {
                                    day.meals.remove(at: index)
                                }
                            )
                        }
                    }

                    // Add Meal Button
                    Button {
                        showingAddMeal = true
                    } label: {
                        HStack {
                            Image(systemName: "plus")
                            Text("Agregar Comida")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(BulkUpColors.diet.opacity(0.1))
                        .foregroundColor(BulkUpColors.diet)
                        .cornerRadius(CornerRadius.small)
                    }

                    // Supplements
                    if !day.supplements.isEmpty {
                        VStack(alignment: .leading, spacing: Spacing.sm) {
                            Text("Suplementos")
                                .font(BulkUpFont.body())
                                .foregroundColor(BulkUpColors.textSecondary)

                            ForEach(Array(day.supplements.enumerated()), id: \.element.id) { index, _ in
                                SupplementEditorRow(
                                    supplement: $day.supplements[index],
                                    onDelete: {
                                        day.supplements.remove(at: index)
                                    }
                                )
                            }
                        }
                    }
                }
                .padding(Spacing.lg)
                .transition(.opacity)
            }
        }
        .background(BulkUpColors.surface)
        .cornerRadius(CornerRadius.large)
        .overlay(RoundedRectangle(cornerRadius: CornerRadius.large).stroke(BulkUpColors.border, lineWidth: 0.5))
        .sheet(isPresented: $showingAddMeal) {
            AddMealView { newMeal in
                day.meals.append(newMeal)
            }
        }
        .sheet(isPresented: $showingAddSupplement) {
            AddSupplementView { newSupplement in
                day.supplements.append(newSupplement)
            }
        }
    }
}

// MARK: - Meal Editor Row

struct MealEditorRow: View {
    @Binding var meal: EditableMeal
    let onDelete: () -> Void

    @State private var isExpanded = false

    private let mealTypes = [
        "Desayuno", "Media Manana", "Almuerzo", "Merienda",
        "Cena", "Pre-entreno", "Post-entreno", "Snack"
    ]

    var body: some View {
        VStack(spacing: Spacing.sm) {
            // Header
            HStack {
                Image(systemName: mealIcon(for: meal.type))
                    .font(BulkUpFont.body())
                    .foregroundColor(BulkUpColors.diet)
                    .frame(width: 24)

                VStack(alignment: .leading, spacing: 2) {
                    Text(meal.type)
                        .font(BulkUpFont.body())
                        .foregroundColor(BulkUpColors.textPrimary)

                    if !meal.time.isEmpty {
                        Text(meal.time)
                            .font(BulkUpFont.caption())
                            .foregroundColor(BulkUpColors.textSecondary)
                    }
                }

                Spacer()

                Text("\(meal.options.count) opc.")
                    .font(BulkUpFont.caption())
                    .foregroundColor(BulkUpColors.textSecondary)

                Button {
                    withAnimation(.spring()) {
                        isExpanded.toggle()
                    }
                } label: {
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(BulkUpFont.caption())
                        .foregroundColor(BulkUpColors.diet)
                }
            }

            if isExpanded {
                VStack(spacing: Spacing.md) {
                    // Meal type picker
                    Picker("Tipo", selection: $meal.type) {
                        ForEach(mealTypes, id: \.self) { type in
                            Text(type).tag(type)
                        }
                    }
                    .pickerStyle(.menu)

                    // Time
                    TextField("Hora (ej: 08:00)", text: $meal.time)
                        .textFieldStyle(.roundedBorder)

                    // Options
                    ForEach(Array(meal.options.enumerated()), id: \.element.id) { index, _ in
                        MealOptionEditorRow(
                            option: $meal.options[index],
                            optionNumber: index + 1,
                            onDelete: {
                                meal.options.remove(at: index)
                            }
                        )
                    }

                    // Add Option
                    Button {
                        meal.options.append(
                            EditableMealOption(
                                optionDescription: "",
                                ingredients: [""],
                                instructions: ""
                            )
                        )
                    } label: {
                        HStack {
                            Image(systemName: "plus")
                            Text("Agregar opcion")
                        }
                        .font(BulkUpFont.caption())
                        .foregroundColor(BulkUpColors.accent)
                    }

                    // Delete meal
                    Button("Eliminar comida", role: .destructive, action: onDelete)
                        .font(BulkUpFont.caption())
                }
                .padding(.top, Spacing.sm)
            }
        }
        .padding(Spacing.lg)
        .background(BulkUpColors.surfaceElevated)
        .cornerRadius(CornerRadius.medium)
    }

    private func mealIcon(for type: String) -> String {
        let lowered = type.lowercased()
        if lowered.contains("desayuno") { return "sunrise" }
        if lowered.contains("almuerzo") || lowered.contains("comida") { return "sun.max" }
        if lowered.contains("cena") { return "moon" }
        if lowered.contains("merienda") || lowered.contains("snack") { return "cup.and.saucer" }
        if lowered.contains("media") { return "clock" }
        if lowered.contains("pre") { return "bolt" }
        if lowered.contains("post") { return "bolt.fill" }
        return "fork.knife"
    }
}

// MARK: - Meal Option Editor Row

struct MealOptionEditorRow: View {
    @Binding var option: EditableMealOption
    let optionNumber: Int
    let onDelete: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack {
                Text("Opcion \(optionNumber)")
                    .font(BulkUpFont.dataLabel())
                    .foregroundColor(BulkUpColors.diet)

                Spacer()

                if optionNumber > 1 {
                    Button {
                        onDelete()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(BulkUpFont.caption())
                            .foregroundColor(BulkUpColors.error.opacity(0.6))
                    }
                }
            }

            TextField("Descripcion (ej: Tortilla de claras con avena)", text: $option.optionDescription)
                .textFieldStyle(.roundedBorder)
                .font(BulkUpFont.body())

            // Ingredients
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text("Ingredientes")
                    .font(BulkUpFont.caption())
                    .foregroundColor(BulkUpColors.textSecondary)

                ForEach(Array(option.ingredients.enumerated()), id: \.offset) { index, _ in
                    HStack {
                        TextField("Ingrediente", text: $option.ingredients[index])
                            .textFieldStyle(.roundedBorder)
                            .font(BulkUpFont.caption())

                        if option.ingredients.count > 1 {
                            Button {
                                option.ingredients.remove(at: index)
                            } label: {
                                Image(systemName: "minus.circle")
                                    .font(BulkUpFont.caption())
                                    .foregroundColor(BulkUpColors.error.opacity(0.6))
                            }
                        }
                    }
                }

                Button {
                    option.ingredients.append("")
                } label: {
                    HStack(spacing: Spacing.xs) {
                        Image(systemName: "plus")
                        Text("Ingrediente")
                    }
                    .font(BulkUpFont.caption())
                    .foregroundColor(BulkUpColors.accent)
                }
            }

            // Instructions (optional)
            TextField("Instrucciones (opcional)", text: $option.instructions)
                .textFieldStyle(.roundedBorder)
                .font(BulkUpFont.caption())
        }
        .padding(10)
        .background(BulkUpColors.surface)
        .cornerRadius(CornerRadius.small)
    }
}

// MARK: - Supplement Editor Row

struct SupplementEditorRow: View {
    @Binding var supplement: EditableSupplement
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: "pills.fill")
                .font(BulkUpFont.caption())
                .foregroundColor(BulkUpColors.accent)

            VStack(alignment: .leading, spacing: 2) {
                Text(supplement.name.isEmpty ? "Suplemento" : supplement.name)
                    .font(BulkUpFont.dataLabel())
                    .foregroundColor(BulkUpColors.textPrimary)

                Text("\(supplement.dosage) - \(supplement.timing)")
                    .font(BulkUpFont.caption())
                    .foregroundColor(BulkUpColors.textSecondary)
            }

            Spacer()

            Button {
                onDelete()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(BulkUpFont.caption())
                    .foregroundColor(BulkUpColors.error.opacity(0.6))
            }
        }
        .padding(Spacing.sm)
        .background(BulkUpColors.surfaceElevated)
        .cornerRadius(CornerRadius.small)
    }
}

// MARK: - Add Diet Day View

struct AddDietDayView: View {
    let onAdd: (EditableDietDay) -> Void
    @Environment(\.dismiss) var dismiss

    @State private var dayName = ""

    private let weekDays = [
        "Lunes", "Martes", "Miercoles", "Jueves", "Viernes", "Sabado", "Domingo",
    ]

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("Agregar Dia")
                    .font(BulkUpFont.sectionHeader())
                    .foregroundColor(BulkUpColors.textPrimary)

                VStack(alignment: .leading, spacing: Spacing.lg) {
                    VStack(alignment: .leading) {
                        Text("Dia de la semana")
                            .font(BulkUpFont.cardTitle())
                            .foregroundColor(BulkUpColors.textPrimary)

                        Picker("Dia", selection: $dayName) {
                            ForEach(weekDays, id: \.self) { day in
                                Text(day).tag(day)
                            }
                        }
                        .pickerStyle(.wheel)
                        .frame(height: 120)
                    }
                }

                Spacer()

                Button("Agregar Dia") {
                    let newDay = EditableDietDay(
                        dayName: dayName.isEmpty ? weekDays[0] : dayName,
                        meals: [],
                        supplements: []
                    )
                    onAdd(newDay)
                    dismiss()
                }
                .primaryButtonStyle(color: BulkUpColors.diet)
            }
            .padding()
            .background(BulkUpColors.background)
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

// MARK: - Add Meal View

struct AddMealView: View {
    let onAdd: (EditableMeal) -> Void
    @Environment(\.dismiss) var dismiss

    @State private var mealType = "Desayuno"
    @State private var mealTime = ""
    @State private var optionDescription = ""
    @State private var ingredients: [String] = [""]

    private let mealTypes = [
        "Desayuno", "Media Manana", "Almuerzo", "Merienda",
        "Cena", "Pre-entreno", "Post-entreno", "Snack"
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: Spacing.lg) {
                        // Meal type
                        VStack(alignment: .leading, spacing: Spacing.sm) {
                            Text("Tipo de comida")
                                .font(BulkUpFont.cardTitle())
                                .foregroundColor(BulkUpColors.textPrimary)

                            Picker("Tipo", selection: $mealType) {
                                ForEach(mealTypes, id: \.self) { type in
                                    Text(type).tag(type)
                                }
                            }
                            .pickerStyle(.segmented)
                        }

                        // Time
                        VStack(alignment: .leading, spacing: Spacing.sm) {
                            Text("Hora")
                                .font(BulkUpFont.cardTitle())
                                .foregroundColor(BulkUpColors.textPrimary)

                            TextField("Ej: 08:00", text: $mealTime)
                                .textFieldStyle(.roundedBorder)
                                .keyboardType(.numbersAndPunctuation)
                        }

                        // Description
                        VStack(alignment: .leading, spacing: Spacing.sm) {
                            Text("Descripcion")
                                .font(BulkUpFont.cardTitle())
                                .foregroundColor(BulkUpColors.textPrimary)

                            TextField("Ej: Tortilla de claras con avena", text: $optionDescription)
                                .textFieldStyle(.roundedBorder)
                        }

                        // Ingredients
                        VStack(alignment: .leading, spacing: Spacing.sm) {
                            Text("Ingredientes")
                                .font(BulkUpFont.cardTitle())
                                .foregroundColor(BulkUpColors.textPrimary)

                            ForEach(Array(ingredients.enumerated()), id: \.offset) { index, _ in
                                HStack {
                                    TextField("Ingrediente", text: $ingredients[index])
                                        .textFieldStyle(.roundedBorder)

                                    if ingredients.count > 1 {
                                        Button {
                                            ingredients.remove(at: index)
                                        } label: {
                                            Image(systemName: "minus.circle.fill")
                                                .foregroundColor(BulkUpColors.error.opacity(0.6))
                                        }
                                    }
                                }
                            }

                            Button {
                                ingredients.append("")
                            } label: {
                                HStack(spacing: Spacing.xs) {
                                    Image(systemName: "plus.circle")
                                    Text("Agregar ingrediente")
                                }
                                .font(BulkUpFont.body())
                                .foregroundColor(BulkUpColors.accent)
                            }
                        }
                    }
                }
                .padding()
            }
            .background(BulkUpColors.background)
            .navigationTitle("Nueva Comida")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancelar") { dismiss() }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Agregar") {
                        let option = EditableMealOption(
                            optionDescription: optionDescription,
                            ingredients: ingredients.filter { !$0.isEmpty },
                            instructions: ""
                        )
                        let meal = EditableMeal(
                            type: mealType,
                            time: mealTime,
                            options: [option]
                        )
                        onAdd(meal)
                        dismiss()
                    }
                    .disabled(optionDescription.isEmpty)
                    .fontWeight(.semibold)
                }
            }
        }
    }
}

// MARK: - Add Supplement View

struct AddSupplementView: View {
    let onAdd: (EditableSupplement) -> Void
    @Environment(\.dismiss) var dismiss

    @State private var name = ""
    @State private var dosage = ""
    @State private var timing = ""
    @State private var frequency = ""

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: Spacing.lg) {
                        VStack(alignment: .leading) {
                            Text("Nombre")
                                .font(BulkUpFont.cardTitle())
                                .foregroundColor(BulkUpColors.textPrimary)
                            TextField("Ej: Creatina", text: $name)
                                .textFieldStyle(.roundedBorder)
                        }

                        VStack(alignment: .leading) {
                            Text("Dosis")
                                .font(BulkUpFont.cardTitle())
                                .foregroundColor(BulkUpColors.textPrimary)
                            TextField("Ej: 5g", text: $dosage)
                                .textFieldStyle(.roundedBorder)
                        }

                        VStack(alignment: .leading) {
                            Text("Momento")
                                .font(BulkUpFont.cardTitle())
                                .foregroundColor(BulkUpColors.textPrimary)
                            TextField("Ej: Post-entreno", text: $timing)
                                .textFieldStyle(.roundedBorder)
                        }

                        VStack(alignment: .leading) {
                            Text("Frecuencia")
                                .font(BulkUpFont.cardTitle())
                                .foregroundColor(BulkUpColors.textPrimary)
                            TextField("Ej: Diario", text: $frequency)
                                .textFieldStyle(.roundedBorder)
                        }
                    }
                }
                .padding()
            }
            .background(BulkUpColors.background)
            .navigationTitle("Nuevo Suplemento")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancelar") { dismiss() }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Agregar") {
                        let supplement = EditableSupplement(
                            name: name,
                            dosage: dosage,
                            timing: timing,
                            frequency: frequency
                        )
                        onAdd(supplement)
                        dismiss()
                    }
                    .disabled(name.isEmpty)
                    .fontWeight(.semibold)
                }
            }
        }
    }
}
