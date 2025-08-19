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
    @EnvironmentObject var dietManager: DietManager
    @State private var viewMode: ViewMode = .day
    @State private var selectedDay = ""
    @State private var expandedDay = 0
    @State private var currentDayIndex = 0

    // ✅ Estados mejorados para el scroll
    @State private var scrollOffset: CGFloat = 0
    @State private var lastScrollOffset: CGFloat = 0
    @State private var headerOffset: CGFloat = 0

    // Constantes para el comportamiento del header
    private let headerHeight: CGFloat = 100
    private let scrollThreshold: CGFloat = 5

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

    var body: some View {
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
    }

    // ✅ Función mejorada para actualizar el header basado en el scroll
    private func updateHeaderOffset() {
        let scrollDelta = scrollOffset - lastScrollOffset

        // Solo actualizar si el cambio es significativo
        guard abs(scrollDelta) > scrollThreshold else { return }

        withAnimation(
            .interactiveSpring(
                response: 0.25,
                dampingFraction: 0.86,
                blendDuration: 0.25
            )
        ) {
            if scrollDelta < 0 {
                // Scrolling down (content going up) - hide header
                headerOffset = max(
                    headerOffset + (scrollDelta * 1.5),
                    -headerHeight
                )
            } else {
                // Scrolling up (content going down) - show header
                headerOffset = min(headerOffset + (scrollDelta * 1.5), 0)
            }

            // Asegurar que el header esté visible cuando estamos en el top
            if scrollOffset >= -10 {
                headerOffset = 0
            }
        }

        lastScrollOffset = scrollOffset
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

    // ✅ Vista semanal con scroll mejorado
    private var weeklyPlanView: some View {
        VStack(spacing: 0) {
            // Header fijo que no se mueve
            if dietManager.dietData.count > 1 {
                viewModeHeader
            }

            // Header colapsable con altura dinámica
            weeklyStatsHeader
                .frame(height: max(0, headerHeight + headerOffset))
                .clipped()
                .opacity(headerOffset < -headerHeight * 0.8 ? 0 : 1)

            // Contenido principal con mejor detección de scroll
            ScrollView {
                VStack(spacing: 20) {
                    // Detector de scroll al inicio del contenido
                    Color.clear
                        .frame(height: 1)
                        .scrollOffset($scrollOffset)

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
            }
            .coordinateSpace(name: "scroll")
            .onChange(of: scrollOffset) { _, _ in
                updateHeaderOffset()
            }
        }
    }

    // ✅ Vista multi-día con scroll mejorado
    private var multiDayPlanView: some View {
        VStack(spacing: 0) {
            // Header fijo que no se mueve
            viewModeHeader

            // Header colapsable con altura dinámica (solo en vista diaria)
            if viewMode == .day {
                enhancedDayNavigationView
                    .frame(height: max(0, headerHeight + headerOffset))
                    .clipped()
                    .opacity(headerOffset < -headerHeight * 0.8 ? 0 : 1)
            }

            // Contenido principal
            ScrollView {
                VStack(spacing: 20) {
                    // Detector de scroll al inicio del contenido
                    Color.clear
                        .frame(height: 1)
                        .scrollOffset($scrollOffset)

                    if viewMode == .week {
                        ForEach(0..<dietManager.dietData.count, id: \.self) {
                            dayIndex in
                            DayCardView(
                                day: dietManager.dietData[dayIndex],
                                dayIndex: dayIndex,
                                isExpanded: expandedDay == dayIndex,
                                onToggleExpand: {
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
            }
            .coordinateSpace(name: "scroll")
            .onChange(of: scrollOffset) { _, _ in
                updateHeaderOffset()
            }
        }
        .onAppear {
            if selectedDay.isEmpty && !dietManager.dietData.isEmpty {
                selectedDay = dietManager.dietData[0].day
                currentDayIndex = 0
            }
        }
        .onChange(of: dietManager.dietData) { _, _ in
            expandedDay = -1
        }
    }

    // ✅ Header compacto para controles de vista
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

    // MARK: - Funciones auxiliares
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
