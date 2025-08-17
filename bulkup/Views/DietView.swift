//
//  DietView.swift
//  bulkup
//
//  Created by sebastian.blanco on 17/8/25.
//


// MARK: - Vista principal de Dietas (equivalente a DietView)
struct DietView: View {
    @StateObject private var dietManager: DietManager
    @EnvironmentObject var authManager: AuthManager
    @State private var viewMode: ViewMode = .day
    @State private var selectedDay = ""
    @State private var expandedDay = 0
    
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
        self._dietManager = StateObject(wrappedValue: DietManager(modelContext: modelContext))
    }
    
    var body: some View {
        NavigationView {
            Group {
                if dietManager.dietData.isEmpty {
                    emptyStateView
                } else if dietManager.dietData.count == 1 && dietManager.dietData[0].day == "Dieta Semanal" {
                    weeklyPlanView
                } else {
                    multiDayPlanView
                }
            }
            .navigationTitle("Plan de Dieta")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if !dietManager.dietData.isEmpty {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        viewModeToggle
                    }
                }
            }
            .task {
                if let user = authManager.user {
                    await dietManager.loadActiveDietPlan(userId: user.id)
                }
            }
            .refreshable {
                if let user = authManager.user {
                    await dietManager.loadActiveDietPlan(userId: user.id)
                }
            }
        }
        .environmentObject(dietManager)
    }
    
    // MARK: - Subvistas
    
    private var emptyStateView: some View {
        VStack(spacing: 24) {
            Image(systemName: "leaf.circle")
                .font(.system(size: 80))
                .foregroundColor(.green.opacity(0.6))
            
            VStack(spacing: 12) {
                Text("Sin plan de dieta")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("Sube tu plan de alimentación para comenzar a seguir tu dieta")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal)
            
            if dietManager.isLoading {
                ProgressView("Cargando plan...")
                    .padding()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
    }
    
    private var weeklyPlanView: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(dietManager.dietData[0].meals.indices, id: \.self) { index in
                    MealCardView(meal: dietManager.dietData[0].meals[index])
                }
                
                if !dietManager.dietData[0].supplements.isEmpty {
                    SupplementsView(supplements: dietManager.dietData[0].supplements)
                }
            }
            .padding()
        }
    }
    
    private var multiDayPlanView: some View {
        VStack(spacing: 0) {
            if viewMode == .day {
                dayNavigationView
            }
            
            ScrollView {
                LazyVStack(spacing: 16) {
                    if viewMode == .week {
                        ForEach(dietManager.dietData.indices, id: \.self) { dayIndex in
                            DayCardView(
                                day: dietManager.dietData[dayIndex],
                                dayIndex: dayIndex,
                                isExpanded: expandedDay == dayIndex,
                                onToggleExpand: { expandedDay = expandedDay == dayIndex ? -1 : dayIndex }
                            )
                        }
                    } else {
                        if let selectedDayData = dietManager.dietData.first(where: { $0.day == selectedDay }) {
                            ForEach(selectedDayData.meals.indices, id: \.self) { index in
                                MealCardView(meal: selectedDayData.meals[index])
                            }
                            
                            if !selectedDayData.supplements.isEmpty {
                                SupplementsView(supplements: selectedDayData.supplements)
                            }
                        }
                    }
                }
                .padding()
            }
        }
        .onAppear {
            if selectedDay.isEmpty && !dietManager.dietData.isEmpty {
                selectedDay = dietManager.dietData[0].day
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
    }
    
    private var dayNavigationView: some View {
        HStack {
            Button(action: navigateToPreviousDay) {
                Image(systemName: "chevron.left")
                    .font(.title2)
                    .foregroundColor(.primary)
            }
            
            Spacer()
            
            VStack {
                Text(selectedDay.capitalized.replacingOccurrences(of: "_", with: " "))
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Text("Plan del día")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Button(action: navigateToNextDay) {
                Image(systemName: "chevron.right")
                    .font(.title2)
                    .foregroundColor(.primary)
            }
        }
        .padding()
        .background(Color(.systemGray6))
    }
    
    private func navigateToPreviousDay() {
        guard let currentIndex = dietManager.dietData.firstIndex(where: { $0.day == selectedDay }) else { return }
        let newIndex = currentIndex > 0 ? currentIndex - 1 : dietManager.dietData.count - 1
        selectedDay = dietManager.dietData[newIndex].day
    }
    
    private func navigateToNextDay() {
        guard let currentIndex = dietManager.dietData.firstIndex(where: { $0.day == selectedDay }) else { return }
        let newIndex = currentIndex < dietManager.dietData.count - 1 ? currentIndex + 1 : 0
        selectedDay = dietManager.dietData[newIndex].day
    }
}