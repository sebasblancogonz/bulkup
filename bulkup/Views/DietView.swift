//
//  DietView.swift
//  bulkup
//
//  Created by sebastian.blanco on 17/8/25.
//

import SwiftData
import SwiftUI

struct DietView: View {
    @EnvironmentObject var authManager: AuthManager
    @Environment(\.modelContext) private var modelContext
    @StateObject private var dietManager: DietManager
    @State private var viewMode: ViewMode = .day
    @State private var selectedDay = ""
    @State private var expandedDay = 0
    @State private var showingProfile = false
    @State private var currentDayIndex = 0

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

    init() {
        self._dietManager = StateObject(
            wrappedValue: DietManager(
                modelContext: ModelContainer.bulkUpContainer.mainContext
            )
        )
    }

    var body: some View {
        // ✅ Quitar NavigationView para que ocupe toda la pantalla
        Group {
            if dietManager.isLoading {
                loadingView
            } else if dietManager.dietData.isEmpty {
                emptyStateView
            } else if dietManager.dietData.count == 1
                && dietManager.dietData[0].day == "Dieta Semanal"
            {
                weeklyPlanView
            } else {
                multiDayPlanView
            }
        }
        .onAppear {
            if dietManager.dietData.isEmpty && !dietManager.isLoading {
                Task {
                    if let user = authManager.user {
                        await dietManager.loadActiveDietPlan(userId: user.id)
                    }
                }
            }
        }
        .refreshable {
            if let user = authManager.user {
                await dietManager.loadActiveDietPlan(userId: user.id)
            }
        }
        .environmentObject(dietManager)
    }

    // MARK: - Subvistas

    private var loadingView: some View {
        VStack(spacing: 24) {
            ProgressView()
                .scaleEffect(1.5)
                .tint(.green)

            VStack(spacing: 8) {
                Text("Cargando tu plan...")
                    .font(.headline)
                    .fontWeight(.medium)

                Text("Preparando tu alimentación perfecta")
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
                                    .green.opacity(0.2), .green.opacity(0.05),
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 120, height: 120)

                    Image(systemName: "leaf.circle.fill")
                        .font(.system(size: 60))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.green, .green.opacity(0.7)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
                .shadow(color: .green.opacity(0.2), radius: 20, x: 0, y: 10)
            }

            VStack(spacing: 16) {
                Text("¡Empecemos tu viaje!")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)

                Text(
                    "Sube tu plan de alimentación personalizado y comienza a alcanzar tus objetivos nutricionales"
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

                    Text("Subir Plan de Dieta")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(
                    LinearGradient(
                        colors: [.green, .green.opacity(0.8)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .foregroundColor(.white)
                .cornerRadius(16)
                .shadow(color: .green.opacity(0.3), radius: 10, x: 0, y: 5)
            }
            .padding(.horizontal, 32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var weeklyPlanView: some View {
        VStack(spacing: 0) {
            // Header con toggle para vista semanal si hay múltiples días
            if dietManager.dietData.count > 1 {
                viewModeHeader
            }

            ScrollView {
                LazyVStack(spacing: 20) {
                    // Header con estadísticas
                    weeklyStatsHeader

                    // ✅ Ordenar comidas correctamente
                    let sortedMeals = dietManager.dietData[0].meals.sorted(by: {
                        $0.orderIndex < $1.orderIndex
                    })
                    ForEach(sortedMeals.indices, id: \.self) { index in
                        MealCardView(meal: sortedMeals[index])
                            .transition(
                                .asymmetric(
                                    insertion: .move(edge: .trailing).combined(
                                        with: .opacity
                                    ),
                                    removal: .move(edge: .leading).combined(
                                        with: .opacity
                                    )
                                )
                            )
                    }

                    if !dietManager.dietData[0].supplements.isEmpty {
                        SupplementsView(
                            supplements: dietManager.dietData[0].supplements
                        )
                        .transition(
                            .move(edge: .bottom).combined(with: .opacity)
                        )
                    }
                }
                .padding()
                .animation(
                    .spring(response: 0.6, dampingFraction: 0.8),
                    value: dietManager.dietData
                )
            }
        }
    }

    private var multiDayPlanView: some View {
        VStack(spacing: 0) {
            // Header con controles de vista
            viewModeHeader

            if viewMode == .day {
                enhancedDayNavigationView
            }

            ScrollView {
                LazyVStack(spacing: 20) {
                    if viewMode == .week {
                        // ✅ Arreglar problema de expansión/contracción
                        ForEach(0..<dietManager.dietData.count, id: \.self) {
                            dayIndex in
                            DayCardView(
                                day: dietManager.dietData[dayIndex],
                                dayIndex: dayIndex,
                                isExpanded: expandedDay == dayIndex,
                                onToggleExpand: {
                                    // ✅ Toggle directo SIN withAnimation
                                    expandedDay =
                                        expandedDay == dayIndex ? -1 : dayIndex
                                }
                            )
                        }
                    } else {
                        if let selectedDayData = dietManager.dietData.first(
                            where: { $0.day == selectedDay })
                        {
                            let sortedMeals = selectedDayData.meals.sorted(by: {
                                $0.orderIndex < $1.orderIndex
                            })
                            ForEach(sortedMeals, id: \.id) { meal in
                                MealCardView(meal: meal)
                                    .transition(
                                        .asymmetric(
                                            insertion: .move(edge: .trailing)
                                                .combined(with: .opacity),
                                            removal: .move(edge: .leading)
                                                .combined(with: .opacity)
                                        )
                                    )
                            }

                            if !selectedDayData.supplements.isEmpty {
                                SupplementsView(
                                    supplements: selectedDayData.supplements
                                )
                                .transition(
                                    .move(edge: .bottom).combined(
                                        with: .opacity
                                    )
                                )
                            }
                        }
                    }
                }
                .padding()
                // ✅ Remover animaciones que pueden causar conflictos
            }
        }
        .onAppear {
            if selectedDay.isEmpty && !dietManager.dietData.isEmpty {
                selectedDay = dietManager.dietData[0].day
                currentDayIndex = 0
            }
        }
        // ✅ Resetear estado cuando cambian los datos
        .onChange(of: dietManager.dietData) { _, _ in
            expandedDay = -1  // Contraer todo cuando cambien los datos
        }
    }

    // ✅ Nuevo header compacto para controles de vista
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

    private var weeklyStatsHeader: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Plan Semanal")
                        .font(.title2)
                        .fontWeight(.bold)

                    Text("Tu rutina nutricional completa")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                Spacer()

                VStack(spacing: 4) {
                    Text("\(dietManager.dietData[0].meals.count)")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.green)

                    Text("comidas")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            // Barra de progreso del día (simulada)
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Progreso de hoy")
                        .font(.subheadline)
                        .fontWeight(.medium)

                    Spacer()

                    Text("2 de 5 comidas")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                ProgressView(value: 0.4)
                    .tint(.green)
                    .background(Color.green.opacity(0.2))
                    .scaleEffect(x: 1, y: 1.5, anchor: .center)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
    }

    private var enhancedDayNavigationView: some View {
        VStack(spacing: 12) {
            HStack(spacing: 16) {
                if dietManager.dietData.count > 1 {
                    Button(action: navigateToPreviousDay) {
                        Image(systemName: "chevron.left.circle.fill")
                            .font(.title2)
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.green, .green.opacity(0.7)],
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

                    Text(
                        "Día \(currentDayIndex + 1) de \(dietManager.dietData.count)"
                    )
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(Color.green.opacity(0.1))
                    .cornerRadius(8)
                }

                Spacer()

                if dietManager.dietData.count > 1 {
                    Button(action: navigateToNextDay) {
                        Image(systemName: "chevron.right.circle.fill")
                            .font(.title2)
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.green, .green.opacity(0.7)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    }
                    .disabled(currentDayIndex == dietManager.dietData.count - 1)
                }
            }

            // Indicador de progreso más compacto
            if dietManager.dietData.count > 1 {
                HStack(spacing: 4) {
                    ForEach(0..<dietManager.dietData.count, id: \.self) {
                        index in
                        Capsule()
                            .fill(
                                index == currentDayIndex
                                    ? Color.green : Color.green.opacity(0.3)
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

    private func navigateToPreviousDay() {
        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
            guard
                let currentIndex = dietManager.dietData.firstIndex(where: {
                    $0.day == selectedDay
                })
            else { return }
            let newIndex = max(0, currentIndex - 1)
            selectedDay = dietManager.dietData[newIndex].day
            currentDayIndex = newIndex
        }
    }

    private func navigateToNextDay() {
        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
            guard
                let currentIndex = dietManager.dietData.firstIndex(where: {
                    $0.day == selectedDay
                })
            else { return }
            let newIndex = min(dietManager.dietData.count - 1, currentIndex + 1)
            selectedDay = dietManager.dietData[newIndex].day
            currentDayIndex = newIndex
        }
    }

    private func formatDayName(_ day: String) -> String {
        return day.capitalized
            .replacingOccurrences(of: "_", with: " ")
            .replacingOccurrences(of: "dia", with: "Día")
    }
}
