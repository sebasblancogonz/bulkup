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
struct RMTrackerView: View {
    @EnvironmentObject var authManager: AuthManager
    @ObservedObject private var rmManager = RMManager.shared
    @ObservedObject private var notificationManager = RMNotificationManager.shared
    @ObservedObject private var storeKit = StoreKitManager.shared

    @State private var searchTerm = ""
    @State private var showAddForm = false
    @State private var showingSubscription = false
    @State private var formData = RMFormData()
    @State private var editingRecordId: String?

    var filteredExercises: [RMExercise] {
        rmManager.filteredExercises(searchTerm: searchTerm)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                BulkUpColors.background.ignoresSafeArea()

                if !storeKit.isSubscribed {
                    SubscriptionRequiredView(
                        onSubscribe: { showingSubscription = true },
                        title: "Records Personales",
                        subtitle: "Registra y sigue tus PR en los ejercicios principales",
                        features: [
                            "Registra peso y repeticiones",
                            "Calculo automatico de RM estimado",
                            "Historial y progresion por ejercicio",
                            "Estadisticas de tus levantamientos"
                        ]
                    )
                } else if rmManager.isLoading && rmManager.records.isEmpty {
                    loadingView
                } else {
                    mainContentWithRefresh
                }

                VStack {
                    if storeKit.isSubscribed,
                       let notification = notificationManager.currentNotification {
                        RMNotificationView(notification: notification)
                            .padding(.horizontal)
                    }
                    Spacer()
                }
                .zIndex(1)
            }
            .toolbar {
                if storeKit.isSubscribed {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: { showAddRecord() }) {
                            Image(systemName: "plus")
                                .font(BulkUpFont.sectionHeader())
                                .foregroundColor(BulkUpColors.accent)
                        }
                    }
                }
            }
            .navigationTitle("Tus PR")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showAddForm) {
                AddRecordFormView(
                    formData: $formData,
                    exercises: rmManager.exercises,
                    isEditing: editingRecordId != nil,
                    isSubmitting: rmManager.isSubmitting,
                    onSubmit: handleSubmitWithCache,
                    onCancel: resetForm
                )
            }
            .sheet(isPresented: $showingSubscription) {
                SubscriptionView()
                    .environmentObject(authManager)
            }
        }
        .task {
            if storeKit.isSubscribed, let token = authManager.user?.token {
                await rmManager.loadInitialDataWithCache(token: token)
            }
        }
        .environmentObject(notificationManager)
    }

    private var mainContentWithRefresh: some View {
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

                    // Espacio extra para el tab bar
                    Color.clear
                        .frame(height: 80)
                }
            }
            .refreshable {
                if let token = authManager.user?.token {
                    await rmManager.refreshData(token: token, forceRefresh: true)
                }
            }
            .overlay(
                Group {
                    if rmManager.isLoading && !rmManager.records.isEmpty {
                        VStack {
                            HStack {
                                ProgressView()
                                    .scaleEffect(0.8)
                                Text("Actualizando...")
                                    .font(BulkUpFont.caption())
                                    .foregroundColor(BulkUpColors.textSecondary)
                            }
                            .padding(8)
                            .background(BulkUpColors.surface)
                            .cornerRadius(20)
                            .overlay(RoundedRectangle(cornerRadius: 20).stroke(BulkUpColors.border, lineWidth: 0.5))

                            Spacer()
                        }
                        .padding(.top, 8)
                    }
                }
            )
        }

        private func handleSubmitWithCache() {
            guard let token = authManager.user?.token else { return }

            Task {
                let success: Bool

                if let recordId = editingRecordId {
                    success = await rmManager.updateRecordWithCache(
                        recordId: recordId,
                        recordData: formData.asDictionary,
                        token: token
                    )
                } else {
                    success = await rmManager.createRecordWithCache(
                        formData.asDictionary,
                        token: token
                    )
                }

                await MainActor.run {
                    if success {
                        resetForm()
                        let message = editingRecordId != nil ? String(localized: "Récord actualizado") : String(localized: "Récord creado")
                        notificationManager.showNotification(.success, message: message)
                    } else {
                        notificationManager.showNotification(.error, message: String(localized: "Error al guardar el récord"))
                    }
                }
            }
        }

        private func deleteRecordWithCache(_ record: PersonalRecord) {
            guard let token = authManager.user?.token else { return }

            Task {
                let success = await rmManager.deleteRecordWithCache(
                    recordId: record.id,
                    token: token
                )

                await MainActor.run {
                    if success {
                        notificationManager.showNotification(.success, message: String(localized: "Récord eliminado"))
                    } else {
                        notificationManager.showNotification(.error, message: String(localized: "Error al eliminar el récord"))
                    }
                }
            }
        }

    // MARK: - Subviews

    private var loadingView: some View {
        VStack {
            ProgressView()
                .scaleEffect(1.5)
            Text("Cargando datos...")
                .font(BulkUpFont.cardTitle())
                .foregroundColor(BulkUpColors.textSecondary)
                .padding(.top)
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

    // MARK: - Actions

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
                        message: String(localized: "Récord eliminado")
                    )
                } else {
                    notificationManager.showNotification(
                        .error,
                        message: String(localized: "Error al eliminar el récord")
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
                .foregroundColor(BulkUpColors.textTertiary)

            TextField("Buscar ejercicio...", text: $text)
                .textFieldStyle(PlainTextFieldStyle())

            if !text.isEmpty {
                Button(action: { text = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(BulkUpColors.textTertiary)
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(BulkUpColors.surfaceElevated)
        .cornerRadius(CornerRadius.medium)
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
        VStack(alignment: .leading, spacing: Spacing.md) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(exercise.nameEs)
                        .font(BulkUpFont.cardTitle())
                        .foregroundColor(BulkUpColors.textPrimary)
                        .lineLimit(2)
                        .frame(minHeight: 44)

                    Text(exercise.category.capitalized)
                        .font(BulkUpFont.caption())
                        .foregroundColor(BulkUpColors.textSecondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(BulkUpColors.surfaceElevated)
                        .cornerRadius(CornerRadius.small)
                }

                Spacer()

                if bestRecord != nil {
                    Image(systemName: "trophy.fill")
                        .foregroundColor(BulkUpColors.accent)
                        .font(BulkUpFont.sectionHeader())
                }
            }

            // Content
            Group {
                if let bestRecord = bestRecord {
                    bestRecordContent(bestRecord)
                } else {
                    noRecordsContent
                }
            }
            .frame(minHeight: 120)

            // Navigation Button
            NavigationLink(
                destination: ExerciseDetailView(
                    exercise: exercise,
                    rmManager: rmManager
                )
            ) {
                HStack {
                    Image(systemName: "chart.bar.fill")
                        .font(BulkUpFont.caption())
                    Text("Ver Detalle")
                        .font(BulkUpFont.dataLabel())
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(BulkUpColors.training)
                .foregroundColor(BulkUpColors.onAccent)
                .cornerRadius(CornerRadius.small)
            }
        }
        .frame(height: 280)
        .padding(Spacing.lg)
        .background(BulkUpColors.surface)
        .cornerRadius(CornerRadius.large)
        .overlay(RoundedRectangle(cornerRadius: CornerRadius.medium).stroke(BulkUpColors.border, lineWidth: 0.5))
    }

    @ViewBuilder
    private func bestRecordContent(_ record: PersonalRecord) -> some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            // Best RM Display
            VStack(alignment: .leading, spacing: 4) {
                Text("Mejor PR")
                    .font(BulkUpFont.caption())
                    .foregroundColor(BulkUpColors.textSecondary)

                HStack {
                    Text(
                        "\(record.weight, specifier: "%.1f") kg × \(record.reps)"
                    )
                    .font(BulkUpFont.heroStat())
                    .foregroundColor(BulkUpColors.textPrimary)

                    Spacer()

                    HStack(spacing: 0) {
                        Button(action: { onEdit(record) }) {
                            Image(systemName: "pencil")
                                .font(BulkUpFont.caption())
                                .foregroundColor(BulkUpColors.training)
                                .frame(width: 44, height: 44)
                                .contentShape(Rectangle())
                        }

                        Button(action: { showDeleteConfirmation = true }) {
                            Image(systemName: "trash")
                                .font(BulkUpFont.caption())
                                .foregroundColor(BulkUpColors.error)
                                .frame(width: 44, height: 44)
                                .contentShape(Rectangle())
                        }
                    }
                }

                if let estimatedRM = RMCalculator.calculateHybridRM(
                    weight: record.weight,
                    reps: record.reps
                ) {
                    Text("RM Estimado: \(estimatedRM, specifier: "%.1f") kg")
                        .font(BulkUpFont.caption())
                        .foregroundColor(BulkUpColors.success)
                        .fontWeight(.medium)
                }

                Text(formatDate(record.date))
                    .font(BulkUpFont.caption())
                    .foregroundColor(BulkUpColors.textSecondary)

                if let notes = record.notes, !notes.isEmpty {
                    Text("\"\(notes)\"")
                        .font(BulkUpFont.caption())
                        .foregroundColor(BulkUpColors.textSecondary)
                        .italic()
                        .lineLimit(2)
                }
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(
                RoundedRectangle(cornerRadius: CornerRadius.small)
                    .fill(BulkUpColors.accent.opacity(0.1))
            )

            // Stats
            HStack {
                Text("Total registros:")
                    .font(BulkUpFont.caption())
                    .foregroundColor(BulkUpColors.textSecondary)

                Spacer()

                Text("\(totalRecords)")
                    .font(BulkUpFont.dataLabel())
                    .foregroundColor(BulkUpColors.textPrimary)
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
        VStack(spacing: Spacing.sm) {
            Image(systemName: "dumbbell")
                .font(BulkUpFont.screenTitle())
                .foregroundColor(BulkUpColors.textTertiary)

            Text("Sin récords registrados")
                .font(BulkUpFont.caption())
                .foregroundColor(BulkUpColors.textSecondary)

            Text("¡Registra tu primer RM!")
                .font(BulkUpFont.caption())
                .foregroundColor(BulkUpColors.textSecondary)
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
        NavigationStack {
            Form {
                Section("Detalles del Ejercicio") {
                    // Exercise Selection
                    if isEditing {
                        HStack {
                            Text("Ejercicio")
                            Spacer()
                            Text(selectedExercise?.name ?? "No seleccionado")
                                .foregroundColor(BulkUpColors.textSecondary)
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
                                    selectedExercise == nil ? BulkUpColors.accent : BulkUpColors.textSecondary
                                )
                                Image(systemName: "chevron.right")
                                    .font(BulkUpFont.caption())
                                    .foregroundColor(BulkUpColors.textSecondary)
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
                                .foregroundColor(BulkUpColors.success)
                        }
                    } header: {
                        Text("Cálculo Automático")
                    } footer: {
                        Text("Basado en fórmula híbrida")
                    }
                }
            }
            .navigationTitle(isEditing ? LocalizedStringKey("Editar RM") : LocalizedStringKey("Nuevo RM"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancelar") { onCancel() }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(isEditing ? "Actualizar" : "Guardar") { onSubmit() }
                        .disabled(!formData.isValid || isSubmitting)
                        .foregroundColor(BulkUpColors.accent)
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
        NavigationStack {
            List {
                ForEach(filteredExercises) { exercise in
                    Button(action: {
                        selectedExerciseId = exercise.id
                        dismiss()
                    }) {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(exercise.nameEs)
                                    .foregroundColor(BulkUpColors.textPrimary)

                                Text(exercise.category.capitalized)
                                    .font(BulkUpFont.caption())
                                    .foregroundColor(BulkUpColors.textSecondary)
                            }

                            Spacer()

                            if selectedExerciseId == exercise.id {
                                Image(systemName: "checkmark")
                                    .foregroundColor(BulkUpColors.accent)
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
                        .foregroundColor(BulkUpColors.accent)
                }
            }
        }
    }
}
