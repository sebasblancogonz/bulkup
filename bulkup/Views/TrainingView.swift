import SwiftData
import SwiftUI

struct TrainingView: View {
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var trainingManager: TrainingManager  // ✅ Cambiar a EnvironmentObject
    @State private var viewMode: ViewMode = .day
    @State private var selectedDay = ""
    @State private var expandedDay = -1
    @State private var currentDayIndex = 0  // ✅ Agregar como en DietView

    enum ViewMode: String, CaseIterable {
        case week = "week"
        case day = "day"

        var displayName: String {
            switch self {
            case .week: return "Semanal"
            case .day: return "Diario"
            }
        }

        var icon: String {
            switch self {
            case .week: return "calendar"
            case .day: return "calendar.day.timeline.left"
            }
        }
    }

    // ✅ Quitar el init personalizado

    var body: some View {
        let _ = print(
            "🎯 TrainingView body - isLoading: \(trainingManager.isLoading), isFullyLoaded: \(trainingManager.isFullyLoaded), trainingData.count: \(trainingManager.trainingData.count)"
        )

        Group {
            if trainingManager.isLoading {
                let _ = print("🔄 Mostrando loading view")
                loadingView
            } else if trainingManager.trainingData.isEmpty {
                let _ = print("📭 Mostrando empty state")
                emptyStateView
            } else if !trainingManager.isFullyLoaded {
                // ✅ Vista específica para cuando hay datos pero los pesos no están listos
                dataLoadedButWeightsLoadingView
            } else {
                mainContentView
            }
        }
        .onAppear {
            if trainingManager.trainingData.isEmpty
                && !trainingManager.isLoading
            {
                Task {
                    if let user = authManager.user {
                        await trainingManager.loadTrainingDataForTab(
                            userId: user.id
                        )
                    }
                }
            }

            // ✅ Configurar selectedDay como en DietView
            if selectedDay.isEmpty && !trainingManager.trainingData.isEmpty {
                selectedDay = trainingManager.trainingData[0].day
                currentDayIndex = 0
            }
        }
        .refreshable {
            if let user = authManager.user {
                await trainingManager.loadActiveTrainingPlan(userId: user.id)
            }
        }
        .onChange(of: trainingManager.selectedWeek) { _, newWeek in
            Task {
                await trainingManager.loadWeightsForWeek(newWeek)
            }
        }
        // ✅ Resetear estado cuando cambian los datos como en DietView
        .onChange(of: trainingManager.trainingData) { _, _ in
            expandedDay = -1
        }
    }

    // MARK: - Subvistas
    private var dataLoadedButWeightsLoadingView: some View {
        VStack(spacing: 24) {
            ProgressView()
                .scaleEffect(1.2)
                .tint(.blue)

            VStack(spacing: 8) {
                Text("Cargando historial de pesos...")
                    .font(.headline)
                    .fontWeight(.medium)

                Text("Tu rutina está lista, preparando el progreso")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var loadingView: some View {
        VStack(spacing: 24) {
            ProgressView()
                .scaleEffect(1.5)
                .tint(.blue)

            VStack(spacing: 8) {
                Text("Cargando tu rutina...")
                    .font(.headline)
                    .fontWeight(.medium)

                Text("Preparando ejercicios y pesos...")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var emptyStateView: some View {
        VStack(spacing: 32) {
            VStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    .blue.opacity(0.2),
                                    .blue.opacity(0.05),
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 120, height: 120)

                    Image(systemName: "dumbbell.fill")
                        .font(.system(size: 60))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.blue, .blue.opacity(0.7)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
                .shadow(color: .blue.opacity(0.2), radius: 20, x: 0, y: 10)
            }

            VStack(spacing: 16) {
                Text("¡Hora de entrenar!")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)

                Text(
                    "Sube tu plan de entrenamiento y comienza a registrar tu progreso"
                )
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 16)
            }

            Button(action: {
                // Acción para subir plan - se manejará desde MainAppView
            }) {
                HStack(spacing: 12) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title3)

                    Text("Subir Plan de Entrenamiento")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(
                    LinearGradient(
                        colors: [.blue, .blue.opacity(0.8)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .foregroundColor(.white)
                .cornerRadius(16)
                .shadow(color: .blue.opacity(0.3), radius: 10, x: 0, y: 5)
            }
            .padding(.horizontal, 32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var mainContentView: some View {
        VStack(spacing: 0) {
            // ✅ Header con controles de vista igual que DietView
            viewModeHeader

            // ✅ Navegación condicional igual que DietView
            if viewMode == .day {
                enhancedDayNavigationView
            } else {
                weekNavigationView
            }

            // Contenido
            ScrollView {
                LazyVStack(spacing: 20) {
                    if viewMode == .week {
                        weekView
                    } else {
                        dayView
                    }
                }
                .padding()
            }
        }
    }

    // ✅ Header compacto igual que DietView
    private var viewModeHeader: some View {
        HStack {
            Text("Vista:")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.secondary)

            Picker("Vista", selection: $viewMode) {
                ForEach(ViewMode.allCases, id: \.self) { mode in
                    Text(mode.displayName).tag(mode)
                }
            }
            .pickerStyle(.segmented)
            .frame(width: 180)

            Spacer()
        }
        .padding()
        .background(Color(.systemGray6).opacity(0.5))
    }

    // ✅ Navegación de día mejorada igual que DietView
    private var enhancedDayNavigationView: some View {
        VStack(spacing: 12) {
            HStack(spacing: 16) {
                if trainingManager.trainingData.count > 1 {
                    Button(action: navigateToPreviousDay) {
                        Image(systemName: "chevron.left.circle.fill")
                            .font(.title2)
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.blue, .blue.opacity(0.7)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    }
                    .disabled(currentDayIndex == 0)
                }

                Spacer()

                VStack(spacing: 4) {
                    Text(formatDayName(selectedDay))
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)

                    if let workout = trainingManager.trainingData.first(where: {
                        $0.day == selectedDay
                    })?.workoutName {
                        Text(workout)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(8)
                    }

                    Text(
                        "Día \(currentDayIndex + 1) de \(trainingManager.trainingData.count)"
                    )
                    .font(.caption)
                    .foregroundColor(.secondary)
                }

                Spacer()

                if trainingManager.trainingData.count > 1 {
                    Button(action: navigateToNextDay) {
                        Image(systemName: "chevron.right.circle.fill")
                            .font(.title2)
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.blue, .blue.opacity(0.7)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    }
                    .disabled(
                        currentDayIndex == trainingManager.trainingData.count
                            - 1
                    )
                }
            }

            // ✅ Indicador de progreso igual que DietView
            if trainingManager.trainingData.count > 1 {
                HStack(spacing: 4) {
                    ForEach(0..<trainingManager.trainingData.count, id: \.self)
                    { index in
                        Capsule()
                            .fill(
                                index == currentDayIndex
                                    ? Color.blue : Color.blue.opacity(0.3)
                            )
                            .frame(
                                width: index == currentDayIndex ? 16 : 6,
                                height: 3
                            )
                            .animation(
                                .spring(response: 0.3),
                                value: currentDayIndex
                            )
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
        )
        .padding(.horizontal)
    }

    private var weekNavigationView: some View {
        HStack {
            Button(action: {
                Task { await trainingManager.changeWeek(direction: .previous) }
            }) {
                Image(systemName: "chevron.left.circle.fill")
                    .font(.title2)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.blue, .blue.opacity(0.7)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }

            Spacer()

            VStack(spacing: 4) {
                Text(formatWeekRange(trainingManager.selectedWeek))
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)

                Text("\(trainingManager.weights.count) registros esta semana")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Button(action: {
                Task { await trainingManager.changeWeek(direction: .next) }
            }) {
                Image(systemName: "chevron.right.circle.fill")
                    .font(.title2)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.blue, .blue.opacity(0.7)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
        )
        .padding(.horizontal)
    }

    @ViewBuilder
    private var weekView: some View {
        ForEach(Array(trainingManager.trainingData.enumerated()), id: \.offset)
        { index, day in
            weekDayCard(for: day, at: index)
        }
    }

    @ViewBuilder
    private func weekDayCard(for day: TrainingDay, at index: Int) -> some View {
        VStack(spacing: 0) {
            weekDayHeader(for: day, at: index)

            if expandedDay == index {
                weekDayExpandedContent(for: day)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
        .padding(.horizontal)
        .id("\(viewMode.rawValue)-\(index)")
    }

    @ViewBuilder
    private func weekDayHeader(for day: TrainingDay, at index: Int) -> some View
    {
        Button(action: {
            // ✅ Toggle directo SIN withAnimation como en DietView
            expandedDay = expandedDay == index ? -1 : index
        }) {
            HStack {
                Circle()
                    .fill(Color.blue)
                    .frame(width: 8, height: 8)

                VStack(alignment: .leading, spacing: 4) {
                    Text(formatDayName(day.day))
                        .font(.headline)
                        .foregroundColor(.primary)

                    if let workoutName = day.workoutName {
                        Text(workoutName)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                HStack(spacing: 16) {
                    Text("\(day.exercises.count) ejercicios")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Image(
                        systemName: expandedDay == index
                            ? "chevron.up" : "chevron.down"
                    )
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.blue)
                    .frame(width: 24, height: 24)
                    .background(Color.blue.opacity(0.1))
                    .clipShape(Circle())
                }
            }
            .padding()
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }

    @ViewBuilder
    private func weekDayExpandedContent(for day: TrainingDay) -> some View {
        VStack(spacing: 0) {
            Divider()
                .padding(.horizontal)

            VStack(spacing: 16) {
                let sortedExercises = day.exercises.sorted(by: {
                    $0.orderIndex < $1.orderIndex
                })
                ForEach(Array(sortedExercises.enumerated()), id: \.element.id) {
                    exerciseIndex,
                    exercise in
                    Group {
                        ExerciseCardView(
                            exercise: exercise,
                            exerciseIndex: exerciseIndex,
                            dayName: day.day
                        )
                        .environmentObject(trainingManager)
                        .environmentObject(authManager)

                        if exerciseIndex < sortedExercises.count - 1 {
                            Divider()
                                .padding(.horizontal)
                        }
                    }
                }
            }
            .padding()
        }
    }

    @ViewBuilder
    private var dayView: some View {
        if let selectedDayData = trainingManager.trainingData.first(where: {
            $0.day == selectedDay
        }) {
            let sortedExercises = selectedDayData.exercises.sorted(by: {
                $0.orderIndex < $1.orderIndex
            })

            ForEach(Array(sortedExercises.enumerated()), id: \.element.id) {
                index,
                exercise in
                ExerciseCardView(
                    exercise: exercise,
                    exerciseIndex: index,
                    dayName: selectedDay
                )
                .environmentObject(trainingManager)
                .environmentObject(authManager)
            }
        } else {
            VStack(spacing: 16) {
                Image(systemName: "calendar.badge.exclamationmark")
                    .font(.system(size: 60))
                    .foregroundColor(.secondary)

                Text("No hay ejercicios para este día")
                    .font(.headline)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.top, 100)
        }
    }

    // MARK: - Funciones auxiliares

    // ✅ Funciones de navegación igual que DietView
    private func navigateToPreviousDay() {
        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
            guard
                let currentIndex = trainingManager.trainingData.firstIndex(
                    where: { $0.day == selectedDay })
            else { return }
            let newIndex = max(0, currentIndex - 1)
            selectedDay = trainingManager.trainingData[newIndex].day
            currentDayIndex = newIndex
        }
    }

    private func navigateToNextDay() {
        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
            guard
                let currentIndex = trainingManager.trainingData.firstIndex(
                    where: { $0.day == selectedDay })
            else { return }
            let newIndex = min(
                trainingManager.trainingData.count - 1,
                currentIndex + 1
            )
            selectedDay = trainingManager.trainingData[newIndex].day
            currentDayIndex = newIndex
        }
    }

    private func formatDayName(_ day: String) -> String {
        return day.capitalized
            .replacingOccurrences(of: "_", with: " ")
            .replacingOccurrences(of: "dia", with: "Día")
    }

    private func formatWeekRange(_ date: Date) -> String {
        let start = trainingManager.getWeekStart(date)
        let end =
            Calendar.current.date(byAdding: .day, value: 6, to: start) ?? start

        let formatter = DateFormatter()
        formatter.dateFormat = "dd MMM"
        formatter.locale = Locale(identifier: "es_ES")

        return
            "\(formatter.string(from: start)) - \(formatter.string(from: end))"
    }
}
