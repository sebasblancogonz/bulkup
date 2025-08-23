import SwiftUI

// MARK: - Form Data Model
struct RMFormData {
    var exerciseId: String = ""
    var weight: String = ""
    var reps: String = "1"
    var date: Date = Date()
    var notes: String = ""

    var isValid: Bool {
        !exerciseId.isEmpty && !weight.isEmpty && !reps.isEmpty
    }

    var asDictionary: [String: Any] {
        let formatter = ISO8601DateFormatter()
        return [
            "exerciseId": exerciseId,
            "weight": Double(weight) ?? 0,
            "reps": Int(reps) ?? 1,
            "date": formatter.string(from: date),
            "notes": notes,
        ]
    }
}

// MARK: - Main RM Tracker View
// MARK: - Main RM Tracker View
struct RMTrackerView: View {
    @EnvironmentObject var authManager: AuthManager
    @StateObject private var rmManager = RMManager.shared
    @StateObject private var notificationManager = RMNotificationManager.shared

    @State private var searchTerm = ""
    @State private var showAddForm = false
    @State private var formData = RMFormData()
    @State private var editingRecordId: String?

    var filteredExercises: [RMExercise] {
        rmManager.filteredExercises(searchTerm: searchTerm)
    }

    var body: some View {
        NavigationView {
            ZStack {
                if rmManager.isLoading {
                    loadingView
                } else {
                    mainContent
                }

                VStack {
                    if let notification = notificationManager
                        .currentNotification
                    {
                        RMNotificationView(notification: notification)
                            .padding(.horizontal)
                    }
                    Spacer()
                }
                .zIndex(1)
            }
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Tus PR")
                        .font(.headline)
                        .foregroundColor(.primary)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showAddRecord() }) {
                        Image(systemName: "plus")
                            .font(.title2)
                    }
                }
            }
            .sheet(isPresented: $showAddForm) {
                AddRecordFormView(
                    formData: $formData,
                    exercises: rmManager.exercises,
                    isEditing: editingRecordId != nil,
                    isSubmitting: rmManager.isSubmitting,
                    onSubmit: handleSubmit,
                    onCancel: resetForm
                )
            }
        }
        .task {
            if let token = authManager.user?.token {
                await rmManager.loadInitialData(token: token)
            }
        }
        .environmentObject(notificationManager)
    }

    // MARK: - Subviews

    private var loadingView: some View {
        VStack {
            ProgressView()
                .scaleEffect(1.5)
            Text("Cargando datos...")
                .font(.headline)
                .padding(.top)
        }
    }

    private var mainContent: some View {
        ScrollView {
            LazyVStack(spacing: 20) {
                // Stats Cards
                StatsCardsView(stats: rmManager.stats)
                    .padding(.horizontal)

                // Search Bar
                SearchBar(text: $searchTerm)
                    .padding(.horizontal)

                // Exercise Cards
                exerciseCardsGrid

                // IMPORTANTE: Añadir espacio extra al final para el tab bar
                Color.clear
                    .frame(height: 90)
            }
        }
        .refreshable {
            if let token = authManager.user?.token {
                await rmManager.loadInitialData(token: token)
            }
        }
    }

    private var exerciseCardsGrid: some View {
        LazyVGrid(columns: gridColumns, spacing: 16) {
            ForEach(filteredExercises) { exercise in
                RMExerciseCardView(
                    exercise: exercise,
                    rmManager: rmManager,
                    bestRecord: rmManager.getBestRecordForExercise(exercise.id),
                    totalRecords: rmManager.getRecordsForExercise(exercise.id)
                        .count,
                    onEdit: { record in editRecord(record) },
                    onDelete: { record in deleteRecord(record) }
                )
            }
        }
        .padding(.horizontal)
    }

    private var gridColumns: [GridItem] {
        [
            GridItem(.flexible(), spacing: 16),
            GridItem(.flexible(), spacing: 16),
        ]
    }

    // MARK: - Actions (sin cambios)

    private func showAddRecord() {
        formData = RMFormData()
        editingRecordId = nil
        showAddForm = true
    }

    private func editRecord(_ record: PersonalRecord) {
        let formatter = ISO8601DateFormatter()
        formData = RMFormData(
            exerciseId: record.exerciseId,
            weight: String(record.weight),
            reps: String(record.reps),
            date: formatter.date(from: record.date) ?? Date(),
            notes: record.notes ?? ""
        )
        editingRecordId = record.id
        showAddForm = true
    }

    private func deleteRecord(_ record: PersonalRecord) {
        guard let token = authManager.user?.token else { return }

        Task {
            let success = await rmManager.deleteRecord(
                recordId: record.id,
                token: token
            )

            await MainActor.run {
                if success {
                    notificationManager.showNotification(
                        .success,
                        message: "Récord eliminado"
                    )
                } else {
                    notificationManager.showNotification(
                        .error,
                        message: "Error al eliminar el récord"
                    )
                }
            }
        }
    }

    private func handleSubmit() {
        guard let token = authManager.user?.token else { return }

        Task {
            let success: Bool

            if let recordId = editingRecordId {
                success = await rmManager.updateRecord(
                    recordId: recordId,
                    recordData: formData.asDictionary,
                    token: token
                )
            } else {
                success = await rmManager.createRecord(
                    formData.asDictionary,
                    token: token
                )
            }

            await MainActor.run {
                if success {
                    resetForm()
                    let message =
                        editingRecordId != nil
                        ? "Récord actualizado" : "Récord creado"
                    notificationManager.showNotification(
                        .success,
                        message: message
                    )
                } else {
                    notificationManager.showNotification(
                        .error,
                        message: "Error al guardar el récord"
                    )
                }
            }
        }
    }

    private func resetForm() {
        formData = RMFormData()
        editingRecordId = nil
        showAddForm = false
    }
}

// MARK: - Search Bar
struct SearchBar: View {
    @Binding var text: String

    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)

            TextField("Buscar ejercicio...", text: $text)
                .textFieldStyle(PlainTextFieldStyle())

            if !text.isEmpty {
                Button(action: { text = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
}

// MARK: - Exercise Card View
struct RMExerciseCardView: View {
    let exercise: RMExercise
    let rmManager: RMManager
    let bestRecord: PersonalRecord?
    let totalRecords: Int
    let onEdit: (PersonalRecord) -> Void
    let onDelete: (PersonalRecord) -> Void

    @State private var showDeleteConfirmation = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(exercise.name)
                        .font(.headline)
                        .lineLimit(2)
                        .frame(minHeight: 44)  // Altura mínima para mantener consistencia

                    Text(exercise.category.capitalized)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color(.systemGray5))
                        .cornerRadius(8)
                }

                Spacer()

                if bestRecord != nil {
                    Image(systemName: "trophy.fill")
                        .foregroundColor(.yellow)
                        .font(.title3)
                }
            }

            // Content - añadir altura mínima
            Group {
                if let bestRecord = bestRecord {
                    bestRecordContent(bestRecord)
                } else {
                    noRecordsContent
                }
            }
            .frame(minHeight: 120)  // Altura mínima para el contenido

            // Navigation Button
            NavigationLink(
                destination: ExerciseDetailView(
                    exercise: exercise,
                    rmManager: rmManager
                )
            ) {
                HStack {
                    Image(systemName: "chart.bar.fill")
                        .font(.caption)
                    Text("Ver Detalle")
                        .font(.caption)
                        .fontWeight(.medium)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(8)
            }
        }
        .frame(height: 280)  // Altura fija para todas las tarjetas
        .padding(16)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }

    @ViewBuilder
    private func bestRecordContent(_ record: PersonalRecord) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            // Best RM Display
            VStack(alignment: .leading, spacing: 4) {
                Text("Mejor PR")
                    .font(.caption)
                    .foregroundColor(.secondary)

                HStack {
                    Text(
                        "\(record.weight, specifier: "%.1f") kg × \(record.reps)"
                    )
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)

                    Spacer()

                    HStack(spacing: 8) {
                        Button(action: { onEdit(record) }) {
                            Image(systemName: "pencil")
                                .font(.caption)
                                .foregroundColor(.blue)
                        }

                        Button(action: { showDeleteConfirmation = true }) {
                            Image(systemName: "trash")
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                    }
                }

                if let estimatedRM = RMCalculator.calculateHybridRM(
                    weight: record.weight,
                    reps: record.reps
                ) {
                    Text("RM Estimado: \(estimatedRM, specifier: "%.1f") kg")
                        .font(.caption)
                        .foregroundColor(.green)
                        .fontWeight(.medium)
                }

                Text(formatDate(record.date))
                    .font(.caption2)
                    .foregroundColor(.secondary)

                if let notes = record.notes, !notes.isEmpty {
                    Text("\"\(notes)\"")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .italic()
                        .lineLimit(2)
                }
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.yellow.opacity(0.1))
            )

            // Stats
            HStack {
                Text("Total registros:")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Spacer()

                Text("\(totalRecords)")
                    .font(.caption)
                    .fontWeight(.medium)
            }
        }
        .confirmationDialog(
            "¿Eliminar récord?",
            isPresented: $showDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Eliminar", role: .destructive) {
                onDelete(record)
            }
            Button("Cancelar", role: .cancel) {}
        } message: {
            Text("Esta acción no se puede deshacer")
        }
    }

    private var noRecordsContent: some View {
        VStack(spacing: 8) {
            Image(systemName: "dumbbell")
                .font(.largeTitle)
                .foregroundColor(.gray.opacity(0.5))

            Text("Sin récords registrados")
                .font(.caption)
                .foregroundColor(.secondary)

            Text("¡Registra tu primer RM!")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
    }

    private func formatDate(_ dateString: String) -> String {
        let formatter = ISO8601DateFormatter()
        guard let date = formatter.date(from: dateString) else {
            return dateString
        }

        let displayFormatter = DateFormatter()
        displayFormatter.dateStyle = .short
        return displayFormatter.string(from: date)
    }
}
// MARK: - Add Record Form View
struct AddRecordFormView: View {
    @Binding var formData: RMFormData
    let exercises: [RMExercise]
    let isEditing: Bool
    let isSubmitting: Bool
    let onSubmit: () -> Void
    let onCancel: () -> Void

    @State private var exerciseSearch = ""
    @State private var showExercisePicker = false

    private var filteredExercises: [RMExercise] {
        if exerciseSearch.isEmpty {
            return exercises
        }
        return exercises.filter {
            $0.name.lowercased().contains(exerciseSearch.lowercased())
        }
    }

    private var selectedExercise: RMExercise? {
        exercises.first { $0.id == formData.exerciseId }
    }

    private var estimatedRM: Double? {
        guard let weight = Double(formData.weight),
            let reps = Int(formData.reps),
            weight > 0 && reps > 0
        else { return nil }

        return RMCalculator.calculateHybridRM(weight: weight, reps: reps)
    }

    var body: some View {
        NavigationView {
            Form {
                Section("Detalles del Ejercicio") {
                    // Exercise Selection
                    if isEditing {
                        HStack {
                            Text("Ejercicio")
                            Spacer()
                            Text(selectedExercise?.name ?? "No seleccionado")
                                .foregroundColor(.secondary)
                        }
                    } else {
                        Button(action: { showExercisePicker = true }) {
                            HStack {
                                Text("Ejercicio")
                                Spacer()
                                Text(
                                    selectedExercise?.name
                                        ?? "Seleccionar ejercicio"
                                )
                                .foregroundColor(
                                    selectedExercise == nil ? .blue : .secondary
                                )
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }

                    // Weight
                    HStack {
                        Text("Peso (kg)")
                        Spacer()
                        TextField("0.0", text: $formData.weight)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                    }

                    // Reps
                    HStack {
                        Text("Repeticiones")
                        Spacer()
                        TextField("1", text: $formData.reps)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                    }

                    // Date
                    DatePicker(
                        "Fecha",
                        selection: $formData.date,
                        displayedComponents: .date
                    )
                }

                Section("Información Adicional") {
                    TextField(
                        "Notas (opcional)",
                        text: $formData.notes,
                        axis: .vertical
                    )
                    .lineLimit(3...6)
                }

                if let rm = estimatedRM {
                    Section {
                        HStack {
                            Text("RM Estimado")
                                .fontWeight(.medium)
                            Spacer()
                            Text("\(rm, specifier: "%.1f") kg")
                                .fontWeight(.bold)
                                .foregroundColor(.green)
                        }
                    } header: {
                        Text("Cálculo Automático")
                    } footer: {
                        Text("Basado en fórmula híbrida")
                    }
                }
            }
            .navigationTitle(isEditing ? "Editar RM" : "Nuevo RM")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancelar") { onCancel() }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(isEditing ? "Actualizar" : "Guardar") { onSubmit() }
                        .disabled(!formData.isValid || isSubmitting)
                }
            }
            .sheet(isPresented: $showExercisePicker) {
                ExercisePickerView(
                    exercises: exercises,
                    selectedExerciseId: $formData.exerciseId,
                    searchText: $exerciseSearch
                )
            }
        }
    }
}

// MARK: - Exercise Picker View
struct ExercisePickerView: View {
    let exercises: [RMExercise]
    @Binding var selectedExerciseId: String
    @Binding var searchText: String
    @Environment(\.dismiss) private var dismiss

    private var filteredExercises: [RMExercise] {
        let allowedCategories = [
            "powerlifting", "olympic weightlifting", "strength",
        ]
        let filtered = exercises.filter {
            allowedCategories.contains($0.category.lowercased())
        }

        if searchText.isEmpty {
            return filtered
        }
        return filtered.filter {
            $0.name.lowercased().contains(searchText.lowercased())
        }
    }

    var body: some View {
        NavigationView {
            List {
                ForEach(filteredExercises) { exercise in
                    Button(action: {
                        selectedExerciseId = exercise.id
                        dismiss()
                    }) {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(exercise.name)
                                    .foregroundColor(.primary)

                                Text(exercise.category.capitalized)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }

                            Spacer()

                            if selectedExerciseId == exercise.id {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Buscar ejercicio...")
            .navigationTitle("Seleccionar Ejercicio")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cerrar") { dismiss() }
                }
            }
        }
    }
}
