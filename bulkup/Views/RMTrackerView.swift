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
            "weight": weight.decimalValue ?? 0,
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
            .navigationBarTitleDisplayMode(.inline)
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
                LazyVStack(spacing: Spacing.lg) {
                    // Stats Cards
                    StatsCardsView(stats: rmManager.stats)
                        .padding(.horizontal, Spacing.screenH)

                    // Search Bar
                    SearchBar(text: $searchTerm)
                        .padding(.horizontal, Spacing.screenH)

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
                            .cornerRadius(CornerRadius.medium)
                            .overlay(RoundedRectangle(cornerRadius: CornerRadius.medium).stroke(BulkUpColors.border, lineWidth: 0.5))

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
                        let message = editingRecordId != nil ? NSLocalizedString("Récord actualizado", comment: "") : NSLocalizedString("Récord creado", comment: "")
                        notificationManager.showNotification(.success, message: message)
                    } else {
                        notificationManager.showNotification(.error, message: NSLocalizedString("Error al guardar el récord", comment: ""))
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
                        notificationManager.showNotification(.success, message: NSLocalizedString("Récord eliminado", comment: ""))
                    } else {
                        notificationManager.showNotification(.error, message: NSLocalizedString("Error al eliminar el récord", comment: ""))
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
        LazyVStack(spacing: Spacing.sm) {
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
        .padding(.horizontal, Spacing.screenH)
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
                        message: NSLocalizedString("Récord eliminado", comment: "")
                    )
                } else {
                    notificationManager.showNotification(
                        .error,
                        message: NSLocalizedString("Error al eliminar el récord", comment: "")
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
        HStack(spacing: Spacing.md) {
            // Main row — tap to open the exercise history/detail.
            NavigationLink(
                destination: ExerciseDetailView(exercise: exercise, rmManager: rmManager)
            ) {
                HStack(spacing: Spacing.md) {
                    ZStack {
                        Circle()
                            .fill(bestRecord != nil ? BulkUpColors.accent.opacity(0.15) : BulkUpColors.surfaceElevated)
                            .frame(width: 44, height: 44)
                        Image(systemName: bestRecord != nil ? "trophy.fill" : "dumbbell")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(bestRecord != nil ? BulkUpColors.accent : BulkUpColors.textTertiary)
                    }

                    VStack(alignment: .leading, spacing: 3) {
                        Text(exercise.nameEs)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(BulkUpColors.textPrimary)
                            .lineLimit(1)
                        Text(metaLine)
                            .font(BulkUpFont.caption())
                            .foregroundColor(BulkUpColors.textSecondary)
                            .lineLimit(1)
                    }

                    Spacer(minLength: Spacing.sm)

                    if let record = bestRecord {
                        VStack(alignment: .trailing, spacing: 2) {
                            Text("\(record.weight, specifier: "%g") kg × \(record.reps)")
                                .font(.system(size: 16, weight: .bold, design: .rounded))
                                .foregroundColor(BulkUpColors.textPrimary)
                                .lineLimit(1)
                            if let rm = RMCalculator.calculateHybridRM(weight: record.weight, reps: record.reps) {
                                Text("1RM \(rm, specifier: "%g") kg")
                                    .font(BulkUpFont.caption())
                                    .foregroundColor(BulkUpColors.success)
                            }
                        }
                    } else {
                        Text("Añadir")
                            .font(BulkUpFont.caption())
                            .fontWeight(.medium)
                            .foregroundColor(BulkUpColors.accent)
                    }
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            // Edit / delete live in a menu so the row stays clean.
            if let record = bestRecord {
                Menu {
                    Button { onEdit(record) } label: { Label("Editar", systemImage: "pencil") }
                    Button(role: .destructive) { showDeleteConfirmation = true } label: {
                        Label("Eliminar", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(BulkUpColors.textTertiary)
                        .frame(width: 32, height: 44)
                        .contentShape(Rectangle())
                }
            } else {
                Image(systemName: "chevron.right")
                    .font(BulkUpFont.caption())
                    .foregroundColor(BulkUpColors.textTertiary)
                    .frame(width: 32, height: 44)
            }
        }
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.sm)
        .background(BulkUpColors.surface)
        .cornerRadius(CornerRadius.large)
        .overlay(RoundedRectangle(cornerRadius: CornerRadius.large).stroke(BulkUpColors.border, lineWidth: 0.5))
        .confirmationDialog(
            "¿Eliminar récord?",
            isPresented: $showDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Eliminar", role: .destructive) {
                if let record = bestRecord { onDelete(record) }
            }
            Button("Cancelar", role: .cancel) {}
        } message: {
            Text("Esta acción no se puede deshacer")
        }
    }

    private var metaLine: String {
        let category = exercise.category.capitalized
        if let record = bestRecord {
            return "\(category) · \(formatDate(record.date))"
        }
        return category
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
        guard let weight = formData.weight.decimalValue,
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
