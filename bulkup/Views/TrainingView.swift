//
//  TrainingView.swift
//  bulkup
//
//  Created by sebastian.blanco on 18/8/25.
//
import SwiftData
import SwiftUI

struct TrainingView: View {
    @StateObject private var trainingManager: TrainingManager
    @EnvironmentObject var authManager: AuthManager
    @State private var viewMode: ViewMode = .day
    @State private var selectedDay = ""
    @State private var expandedDay = -1
    @State private var showingProfile = false

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

    init(modelContext: ModelContext) {
        self._trainingManager = StateObject(
            wrappedValue: TrainingManager(modelContext: modelContext)
        )
    }

    var body: some View {
        NavigationView {
            Group {
                if trainingManager.isLoading {
                    loadingView
                } else if trainingManager.trainingData.isEmpty {
                    emptyStateView
                } else {
                    mainContentView
                }
            }
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                if !trainingManager.trainingData.isEmpty {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        viewModeToggle
                    }
                }
            }
            .onAppear {
                if trainingManager.trainingData.isEmpty
                    && !trainingManager.isLoading
                {
                    Task {
                        if let user = authManager.user {
                            await trainingManager.loadActiveTrainingPlan(
                                userId: user.id
                            )
                        }
                    }
                }
            }
            .refreshable {
                if let user = authManager.user {
                    await trainingManager.loadActiveTrainingPlan(
                        userId: user.id
                    )
                }
            }
            .onChange(of: trainingManager.selectedWeek) { _, newWeek in
                trainingManager.loadWeightsForWeek(newWeek)
            }
        }
        .environmentObject(trainingManager)
    }

    // MARK: - Subvistas

    private var loadingView: some View {
        VStack(spacing: 24) {
            ProgressView()
                .scaleEffect(1.5)
                .tint(.blue)

            VStack(spacing: 8) {
                Text("Cargando tu rutina...")
                    .font(.headline)
                    .fontWeight(.medium)

                Text("Preparando tus ejercicios")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            LinearGradient(
                colors: [
                    Color(.systemGroupedBackground),
                    Color.blue.opacity(0.05),
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        )
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
                    "Sube tu plan de entrenamiento y comienza a registrar tu progreso con cada ejercicio"
                )
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 16)
            }

            Button(action: {
                // Acción para subir plan
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
        .background(
            LinearGradient(
                colors: [
                    Color(.systemGroupedBackground),
                    Color.blue.opacity(0.02),
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }

    private var mainContentView: some View {
        VStack(spacing: 0) {
            // Navegación condicional basada en viewMode
            if viewMode == .week {
                weekNavigationView
            } else {
                dayNavigationView
            }

            // Contenido condicional basado en viewMode
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
            .background(
                LinearGradient(
                    colors: [
                        Color(.systemGroupedBackground),
                        Color.blue.opacity(0.02),
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
        }
        .onAppear {
            if selectedDay.isEmpty && !trainingManager.trainingData.isEmpty {
                selectedDay = trainingManager.trainingData[0].day
            }
        }
    }

    private var viewModeToggle: some View {
        Picker("Vista", selection: $viewMode) {
            ForEach(ViewMode.allCases, id: \.self) { mode in
                Label(mode.displayName, systemImage: mode.icon)
                    .tag(mode)
            }
        }
        .pickerStyle(.segmented)
        .frame(width: 200)
        .onChange(of: viewMode) { _, newMode in
            withAnimation(.easeInOut(duration: 0.2)) {
                // Reset del estado expandido al cambiar de vista
                expandedDay = -1
                
                // Asegurar que selectedDay tenga un valor válido para la vista de día
                if newMode == .day && selectedDay.isEmpty && !trainingManager.trainingData.isEmpty {
                    selectedDay = trainingManager.trainingData[0].day
                }
            }
        }
    }

    private var dayNavigationView: some View {
        HStack {
            Button(action: { navigateToPreviousDay() }) {
                Image(systemName: "chevron.left.circle.fill")
                    .font(.title)
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
                Text(selectedDay.capitalized)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)

                if let workout = trainingManager.trainingData.first(where: {
                    $0.day == selectedDay
                })?.workoutName {
                    Text(workout)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(12)
                }
            }

            Spacer()

            Button(action: { navigateToNextDay() }) {
                Image(systemName: "chevron.right.circle.fill")
                    .font(.title)
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
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
        .padding(.horizontal)
    }

    private var weekNavigationView: some View {
        HStack {
            Button(action: {
                Task { await trainingManager.changeWeek(direction: .previous) }
            }) {
                Image(systemName: "chevron.left.circle.fill")
                    .font(.title)
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
                    .font(.title2)
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
                    .font(.title)
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
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
        .padding(.horizontal)
    }

    @ViewBuilder
    private var weekView: some View {
        ForEach(Array(trainingManager.trainingData.enumerated()), id: \.offset) { index, day in
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
    private func weekDayHeader(for day: TrainingDay, at index: Int) -> some View {
        Button(action: {
            withAnimation(.easeInOut(duration: 0.25)) {
                if expandedDay == index {
                    expandedDay = -1
                } else {
                    expandedDay = index
                }
            }
        }) {
            HStack {
                Circle()
                    .fill(Color.blue)
                    .frame(width: 8, height: 8)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(day.day.capitalized)
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
                    
                    Image(systemName: expandedDay == index ? "chevron.up" : "chevron.down")
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
                let sortedExercises = day.exercises.sorted(by: { $0.orderIndex < $1.orderIndex })
                ForEach(Array(sortedExercises.enumerated()), id: \.element.id) { exerciseIndex, exercise in
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

            ForEach(Array(sortedExercises.enumerated()), id: \.element.id) { index, exercise in
                ExerciseCardView(
                    exercise: exercise,
                    exerciseIndex: index,
                    dayName: selectedDay
                )
                .environmentObject(trainingManager)
                .environmentObject(authManager)
            }
        } else {
            // Vista de fallback si no hay datos para el día seleccionado
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

    private func navigateToPreviousDay() {
        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
            guard
                let currentIndex = trainingManager.trainingData.firstIndex(
                    where: { $0.day == selectedDay })
            else { return }
            let newIndex =
                currentIndex > 0
                ? currentIndex - 1 : trainingManager.trainingData.count - 1
            selectedDay = trainingManager.trainingData[newIndex].day
        }
    }

    private func navigateToNextDay() {
        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
            guard
                let currentIndex = trainingManager.trainingData.firstIndex(
                    where: { $0.day == selectedDay })
            else { return }
            let newIndex =
                currentIndex < trainingManager.trainingData.count - 1
                ? currentIndex + 1 : 0
            selectedDay = trainingManager.trainingData[newIndex].day
        }
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
