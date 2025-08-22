import SwiftData
import SwiftUI

struct TrainingView: View {
    @EnvironmentObject var authManager: AuthManager
    @StateObject var trainingManager = TrainingManager.shared
    @State private var viewMode: ViewMode = .day
    @State private var selectedDay = ""
    @State private var expandedDay: Int? = nil
    @State private var currentDayIndex = 0
    
    // Estado para navegación de fechas
    @State private var currentDate: Date = Date()

    // Estados para el scroll
    @State private var scrollOffset: CGFloat = 0
    @State private var lastScrollOffset: CGFloat = 0
    @State private var headerOffset: CGFloat = 0
    @State private var isDragging: Bool = false

    // Constantes para el comportamiento del header
    private let headerHeight: CGFloat = 180
    private let scrollThreshold: CGFloat = 20

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

    // Formateadores para fechas
    private var dayFormatter: DateFormatter {
        let f = DateFormatter()
        f.locale = Locale(identifier: "es_ES")
        f.dateFormat = "EEEE"
        f.calendar = Calendar(identifier: .gregorian)
        f.calendar?.firstWeekday = 2
        return f
    }

    private var dateFormatter: DateFormatter {
        let f = DateFormatter()
        f.locale = Locale(identifier: "es_ES")
        f.dateFormat = "dd/MM/yyyy"
        f.calendar = Calendar(identifier: .gregorian)
        f.calendar?.firstWeekday = 2
        return f
    }

    private var calendar: Calendar {
        var cal = Calendar(identifier: .gregorian)
        cal.locale = Locale(identifier: "es_ES")
        cal.firstWeekday = 2
        return cal
    }

    // Función para mapear fecha del calendario a día de entrenamiento
    private func getTrainingDayForDate(_ date: Date) -> String? {
        let dayName = dayFormatter.string(from: date).lowercased()

        let dayMapping: [String: String] = [
            "lunes": "lunes",
            "martes": "martes",
            "miércoles": "miercoles",
            "jueves": "jueves",
            "viernes": "viernes",
            "sábado": "sabado",
            "domingo": "domingo",
        ]

        let mappedDay = dayMapping[dayName]

        return trainingManager.trainingData.first { trainingDay in
            trainingDay.day.lowercased() == mappedDay?.lowercased()
                || trainingDay.day.lowercased().contains(
                    mappedDay?.lowercased() ?? ""
                )
        }?.day
    }

    // Computed property para el día de entrenamiento actual
    private var currentTrainingDay: String? {
        return getTrainingDayForDate(currentDate)
    }

    var body: some View {
        Group {
            if trainingManager.isLoading {
                loadingView
            } else if trainingManager.trainingData.isEmpty {
                emptyStateView
            } else if !trainingManager.isFullyLoaded {
                dataLoadedButWeightsLoadingView
            } else {
                mainContentViewWithNavigation
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
        .onChange(of: trainingManager.trainingData) { _, _ in
            expandedDay = nil
        }
    }

    // Función para actualizar el header basado en el scroll
    private func updateHeaderOffset() {
        guard !isDragging else { return }
        let scrollDelta = scrollOffset - lastScrollOffset
        guard abs(scrollDelta) > scrollThreshold else { return }
        let clampedDelta = min(max(scrollDelta, -20), 20)

        withAnimation(
            .interactiveSpring(
                response: 0.35,
                dampingFraction: 0.86,
                blendDuration: 0.25
            )
        ) {
            if clampedDelta < 0 {
                headerOffset = max(
                    headerOffset + (clampedDelta * 1.2),
                    -headerHeight
                )
            } else {
                headerOffset = min(headerOffset + (clampedDelta * 1.2), 0)
            }

            if scrollOffset >= -10 {
                headerOffset = 0
            }
        }

        lastScrollOffset = scrollOffset
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
    }

    private var mainContentViewWithNavigation: some View {
        ScrollView(.vertical, showsIndicators: true) {
            VStack(spacing: 20) {

                // Contenido según el modo de vista
                if viewMode == .week {
                    weekView
                } else {
                    dayView
                }

                // Espacio inferior
                Color.clear
                    .frame(height: 50)
            }
            .padding(.top, 20)
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            // Título personalizado en el centro
            ToolbarItem(placement: .principal) {
                navigationTitleView
            }

            // Selector de vista
            ToolbarItem(placement: .navigationBarTrailing) {
                Picker("Vista", selection: $viewMode) {
                    ForEach(ViewMode.allCases, id: \.self) { mode in
                        Label(mode.displayName, systemImage: mode.icon)
                            .tag(mode)
                    }
                }
                .pickerStyle(.menu)
            }

            // Navegación de fechas en el toolbar para vista diaria
            if viewMode == .day {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        withAnimation {
                            currentDate =
                                calendar.date(
                                    byAdding: .day,
                                    value: -1,
                                    to: currentDate
                                ) ?? currentDate
                        }
                    } label: {
                        Image(systemName: "chevron.left")
                    }
                    .disabled(
                        calendar.isDate(
                            currentDate,
                            inSameDayAs: calendar.date(
                                byAdding: .year,
                                value: -1,
                                to: Date()
                            ) ?? Date()
                        )
                    )
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        withAnimation {
                            currentDate =
                                calendar.date(
                                    byAdding: .day,
                                    value: 1,
                                    to: currentDate
                                ) ?? currentDate
                        }
                    } label: {
                        Image(systemName: "chevron.right")
                    }
                    .disabled(
                        calendar.isDate(
                            currentDate,
                            inSameDayAs: calendar.date(
                                byAdding: .month,
                                value: 1,
                                to: Date()
                            ) ?? Date()
                        )
                    )
                }
            }

            // Navegación de semanas en el toolbar para vista semanal
            if viewMode == .week {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        Task {
                            await trainingManager.changeWeek(
                                direction: .previous
                            )
                        }
                    } label: {
                        Image(systemName: "chevron.left")
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        Task {
                            await trainingManager.changeWeek(direction: .next)
                        }
                    } label: {
                        Image(systemName: "chevron.right")
                    }
                }
            }
        }
        .refreshable {
            if let user = authManager.user {
                await trainingManager.loadActiveTrainingPlan(userId: user.id)
            }
        }
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
            // Header siempre visible
            weekDayHeader(for: day, at: index)
            
            // Contenedor del contenido expandible
            VStack(spacing: 0) {
                if expandedDay == index {
                    Divider()
                        .padding(.horizontal)
                    
                    weekDayExpandedContent(for: day, at: index)
                        .transition(.asymmetric(
                            insertion: .move(edge: .top).combined(with: .opacity),
                            removal: .move(edge: .top).combined(with: .opacity)
                        ))
                }
            }
            .clipped()
            .animation(.spring(response: 0.35, dampingFraction: 0.85), value: expandedDay)
        }
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
        .padding(.horizontal)
    }

    @ViewBuilder
    private func weekDayHeader(for day: TrainingDay, at index: Int) -> some View {
        Button(action: {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                if expandedDay == index {
                    expandedDay = nil
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
                    .animation(.spring(response: 0.3, dampingFraction: 0.8), value: expandedDay)
                }
            }
            .padding()
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }

    @ViewBuilder
    private func weekDayExpandedContent(for day: TrainingDay, at index: Int) -> some View {
        VStack(spacing: 12) {
            let sortedExercises = day.exercises.sorted(by: {
                $0.orderIndex < $1.orderIndex
            })

            let dateForThisDay = getDateForTrainingDay(day.day)

            ForEach(sortedExercises, id: \.id) { exercise in
                let exerciseIndex = exercise.orderIndex
                VStack(spacing: 12) {
                    ExerciseCardView(
                        exercise: exercise,
                        exerciseIndex: exerciseIndex,
                        dayName: day.day,
                        currentDate: dateForThisDay
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

    // Función helper para obtener la fecha de un día específico
    private func getDateForTrainingDay(_ dayName: String) -> Date {
        let dayMapping: [String: Int] = [
            "lunes": 1,
            "martes": 2,
            "miercoles": 3,
            "jueves": 4,
            "viernes": 5,
            "sábado": 6,
            "domingo": 7,
        ]

        let today = Date()
        let calendar = Calendar.current

        guard let targetWeekday = dayMapping[dayName.lowercased()] else {
            return today
        }

        let weekStart = trainingManager.getWeekStart(trainingManager.selectedWeek)
        let daysFromMonday = (targetWeekday == 1) ? 6 : targetWeekday - 2
        let targetDate = calendar.date(byAdding: .day, value: daysFromMonday, to: weekStart) ?? today

        return targetDate
    }

    @ViewBuilder
    private var navigationTitleView: some View {
        if viewMode == .day {
            VStack(spacing: 2) {
                Text(dayFormatter.string(from: currentDate).capitalized)
                    .font(.headline)
                    .foregroundColor(.primary)

                if let trainingDay = currentTrainingDay,
                    let dayData = trainingManager.trainingData.first(where: {
                        $0.day == trainingDay
                    }),
                    let workoutName = dayData.workoutName
                {
                    Text(workoutName)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        } else {
            VStack(spacing: 2) {
                Text("Semana")
                    .font(.headline)
                    .foregroundColor(.primary)

                Text(formatWeekRange(trainingManager.selectedWeek))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }

    @ViewBuilder
    private var dayView: some View {
        if let trainingDay = currentTrainingDay,
            let selectedDayData = trainingManager.trainingData.first(where: {
                $0.day == trainingDay
            })
        {
            let sortedExercises = selectedDayData.exercises.sorted(by: {
                $0.orderIndex < $1.orderIndex
            })

            ForEach(Array(sortedExercises.enumerated()), id: \.element.id) {
                index, exercise in
                ExerciseCardView(
                    exercise: exercise,
                    exerciseIndex: index,
                    dayName: trainingDay,
                    currentDate: currentDate
                )
                .environmentObject(trainingManager)
                .environmentObject(authManager)
            }
        } else {
            VStack(spacing: 16) {
                Image(
                    systemName: currentTrainingDay == nil
                        ? "bed.double.fill" : "calendar.badge.exclamationmark"
                )
                .font(.system(size: 60))
                .foregroundColor(.secondary)

                Text(
                    currentTrainingDay == nil
                        ? "Día de descanso" : "No hay ejercicios para este día"
                )
                .font(.headline)
                .foregroundColor(.secondary)

                if currentTrainingDay == nil {
                    Text("Disfruta tu día libre")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.top, 100)
        }
    }

    // MARK: - Funciones auxiliares
    private func formatDayName(_ day: String) -> String {
        return day.capitalized
            .replacingOccurrences(of: "_", with: " ")
            .replacingOccurrences(of: "dia", with: "Día")
    }

    private func formatWeekRange(_ date: Date) -> String {
        let start = trainingManager.getWeekStart(date)
        let end = Calendar.current.date(byAdding: .day, value: 6, to: start) ?? start

        let formatter = DateFormatter()
        formatter.dateFormat = "dd MMM"
        formatter.locale = Locale(identifier: "es_ES")

        return "\(formatter.string(from: start)) - \(formatter.string(from: end))"
    }
}

// Extension helper para clamp
extension Comparable {
    func clamped(to limits: ClosedRange<Self>) -> Self {
        return min(max(self, limits.lowerBound), limits.upperBound)
    }
}
