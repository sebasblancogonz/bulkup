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
    @State private var expandedDay = -1
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

    var body: some View {
        Group {
            if dietManager.isLoading {
                loadingView
            } else if dietManager.dietData.isEmpty {
                emptyStateView
            } else if dietManager.dietData.count == 1
                && dietManager.dietData[0].day == "Dieta Semanal"
            {
                weeklyPlanViewWithNavigation
            } else {
                multiDayPlanViewWithNavigation
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
    }

    // MARK: - Loading View
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

    // MARK: - Empty State View
    private var emptyStateView: some View {
        VStack(spacing: 32) {
            VStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    .green.opacity(0.2),
                                    .green.opacity(0.05),
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

    // MARK: - Navigation Title View
    @ViewBuilder
    private var navigationTitleView: some View {
        if dietManager.dietData.count == 1
            && dietManager.dietData[0].day == "Dieta Semanal"
        {
            VStack(spacing: 2) {
                Text("Plan Semanal")
                    .font(.headline)
                    .foregroundColor(.primary)

                Text("\(dietManager.dietData[0].meals.count) comidas")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        } else if viewMode == .day && !selectedDay.isEmpty {
            VStack(spacing: 2) {
                Text(formatDayName(selectedDay))
                    .font(.headline)
                    .foregroundColor(.primary)

                Text(
                    "Día \(currentDayIndex + 1) de \(dietManager.dietData.count)"
                )
                .font(.caption)
                .foregroundColor(.secondary)
            }
        } else {
            VStack(spacing: 2) {
                Text("Semana")
                    .font(.headline)
                    .foregroundColor(.primary)

                Text("\(dietManager.dietData.count) días")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }

    // MARK: - Weekly Plan View with Navigation
    private var weeklyPlanViewWithNavigation: some View {
        GeometryReader { geometry in
            ScrollView(.vertical, showsIndicators: true) {
                VStack(spacing: 20) {
                    // Header grande personalizado
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {

                            Text("Tu rutina nutricional completa")
                                .font(.title3)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                    }
                    .padding(.horizontal)
                    .padding(.bottom)

                    // Stats card
                    HStack {
                        VStack(alignment: .leading, spacing: 8) {
                            Label(
                                "\(dietManager.dietData[0].meals.count) comidas",
                                systemImage: "fork.knife"
                            )
                            .font(.subheadline)
                            .fontWeight(.medium)

                            if !dietManager.dietData[0].supplements.isEmpty {
                                Label(
                                    "\(dietManager.dietData[0].supplements.count) suplementos",
                                    systemImage: "pills.fill"
                                )
                                .font(.subheadline)
                                .fontWeight(.medium)
                            }
                        }
                        Spacer()
                    }
                    .padding()
                    .background(Color.green.opacity(0.1))
                    .cornerRadius(12)
                    .padding(.horizontal)

                    // Comidas
                    let sortedMeals = dietManager.dietData[0].meals.sorted(by: {
                        $0.orderIndex < $1.orderIndex
                    })
                    ForEach(sortedMeals.indices, id: \.self) { index in
                        MealCardView(meal: sortedMeals[index])
                            .padding(.horizontal)
                    }

                    // Suplementos
                    if !dietManager.dietData[0].supplements.isEmpty {
                        SupplementsView(
                            supplements: dietManager.dietData[0].supplements
                        )
                        .padding(.horizontal)
                    }

                    Color.clear
                        .frame(height: 50)
                }
                .padding(.top, 20)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    navigationTitleView
                }
            }
            .refreshable {
                if let user = authManager.user {
                    await dietManager.loadActiveDietPlan(userId: user.id)
                }
            }
        }
    }

    // MARK: - Multi-Day Plan View with Navigation
    private var multiDayPlanViewWithNavigation: some View {
        ScrollView(.vertical, showsIndicators: true) {
            VStack(spacing: 20) {
                // Header grande personalizado según el modo
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        if viewMode == .day {
                            if dietManager.dietData.count > 1 {
                                HStack(spacing: 12) {
                                    Text(
                                        "Día \(currentDayIndex + 1) de \(dietManager.dietData.count)"
                                    )
                                    .font(.title3)
                                    .foregroundColor(.secondary)

                                    // Indicador de progreso
                                    HStack(spacing: 2) {
                                        ForEach(
                                            0..<min(
                                                dietManager.dietData.count,
                                                7
                                            ),
                                            id: \.self
                                        ) { index in
                                            Circle()
                                                .fill(
                                                    index == currentDayIndex
                                                        ? Color.green
                                                        : Color.green.opacity(
                                                            0.3
                                                        )
                                                )
                                                .frame(width: 6, height: 6)
                                        }
                                    }
                                }
                            }
                        } else {
                            Text("Plan Semanal")
                                .font(.largeTitle)
                                .fontWeight(.bold)

                            Text(
                                "\(dietManager.dietData.count) días programados"
                            )
                            .font(.title3)
                            .foregroundColor(.secondary)
                        }
                    }
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.bottom)

                // Contenido según el modo de vista
                if viewMode == .week {
                    ForEach(0..<dietManager.dietData.count, id: \.self) {
                        dayIndex in
                        DayCardView(
                            day: dietManager.dietData[dayIndex],
                            dayIndex: dayIndex,
                            isExpanded: expandedDay == dayIndex,
                            onToggleExpand: {
                                withAnimation(
                                    .spring(
                                        response: 0.3,
                                        dampingFraction: 0.8
                                    )
                                ) {
                                    expandedDay =
                                        expandedDay == dayIndex
                                        ? -1 : dayIndex
                                }
                            }
                        )
                        .padding(.horizontal)
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
                                .padding(.horizontal)
                        }

                        if !selectedDayData.supplements.isEmpty {
                            SupplementsView(
                                supplements: selectedDayData.supplements
                            )
                            .padding(.horizontal)
                        }
                    }
                }

                Color.clear
                    .frame(height: 50)
            }
            .padding(.top, 20)
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                navigationTitleView
            }

            // Selector de vista (solo si hay múltiples días)
            if dietManager.dietData.count > 1 {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Picker("Vista", selection: $viewMode) {
                        ForEach(ViewMode.allCases, id: \.self) { mode in
                            Label(mode.displayName, systemImage: mode.icon)
                                .tag(mode)
                        }
                    }
                    .pickerStyle(.menu)
                }
            }

            // Navegación de días (solo en vista diaria)
            if viewMode == .day && dietManager.dietData.count > 1 {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        navigateToPreviousDay()
                    } label: {
                        Image(systemName: "chevron.left")
                    }
                    .disabled(currentDayIndex == 0)
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        navigateToNextDay()
                    } label: {
                        Image(systemName: "chevron.right")
                    }
                    .disabled(
                        currentDayIndex == dietManager.dietData.count - 1
                    )
                }
            }
        }
        .refreshable {
            if let user = authManager.user {
                await dietManager.loadActiveDietPlan(userId: user.id)
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

    // MARK: - Helper Functions
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
