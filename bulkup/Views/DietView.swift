//
//  DietView.swift
//  bulkup
//
//  Created by sebastian.blanco on 17/8/25.
//

import SwiftUI
import SwiftData

// MARK: - Vista principal de Dietas (equivalente a DietView)
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
        // Use a placeholder, will be replaced in .onAppear
        self._dietManager = StateObject(wrappedValue: DietManager(modelContext: ModelContainer.dietAppContainer.mainContext))
    }
    
    var body: some View {
        NavigationView {
            Group {
                if dietManager.isLoading {
                    loadingView
                } else if dietManager.dietData.isEmpty {
                    emptyStateView
                } else if dietManager.dietData.count == 1 && dietManager.dietData[0].day == "Dieta Semanal" {
                    weeklyPlanView
                } else {
                    multiDayPlanView
                }
            }
            .navigationTitle("Mi Plan Nutricional")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    profileButton
                }
                
                if !dietManager.dietData.isEmpty && dietManager.dietData.count > 1 {
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
            .sheet(isPresented: $showingProfile) {
                ProfileView()
                    .environmentObject(authManager)
            }
        }
        .environmentObject(dietManager)
        .onAppear {
            // Re-initialize dietManager with the correct context if needed
            if dietManager.modelContext !== modelContext {
                dietManager.modelContext = modelContext
                dietManager.loadLocalDietData()
            }
        }
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
        .background(
            LinearGradient(
                colors: [Color(.systemGroupedBackground), Color.green.opacity(0.05)],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }
    
    private var profileButton: some View {
        Button(action: { showingProfile = true }) {
            HStack(spacing: 8) {
                // Avatar con iniciales
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.green, .green.opacity(0.7)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 32, height: 32)
                    .overlay(
                        Text(authManager.user?.name.prefix(1).uppercased() ?? "U")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white)
                    )
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Hola!")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(authManager.user?.name.split(separator: " ").first.map(String.init) ?? "Usuario")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .lineLimit(1)
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 32) {
            // Ilustración animada
            VStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [.green.opacity(0.2), .green.opacity(0.05)],
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
                
                Text("Sube tu plan de alimentación personalizado y comienza a alcanzar tus objetivos nutricionales")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 16)
            }
            
            // Botón de acción
            Button(action: {
                // Acción para subir plan
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
            
            if dietManager.isLoading {
                HStack(spacing: 12) {
                    ProgressView()
                        .scaleEffect(0.8)
                    
                    Text("Cargando plan...")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            LinearGradient(
                colors: [Color(.systemGroupedBackground), Color.green.opacity(0.02)],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }
    
    private var weeklyPlanView: some View {
        ScrollView {
            LazyVStack(spacing: 20) {
                // Header con estadísticas
                weeklyStatsHeader
                
                ForEach(dietManager.dietData[0].meals.indices, id: \.self) { index in
                    MealCardView(meal: dietManager.dietData[0].meals[index])
                        .transition(.asymmetric(
                            insertion: .move(edge: .trailing).combined(with: .opacity),
                            removal: .move(edge: .leading).combined(with: .opacity)
                        ))
                }
                
                if !dietManager.dietData[0].supplements.isEmpty {
                    SupplementsView(supplements: dietManager.dietData[0].supplements)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .padding()
            .animation(.spring(response: 0.6, dampingFraction: 0.8), value: dietManager.dietData)
        }
        .background(
            LinearGradient(
                colors: [Color(.systemGroupedBackground), Color.green.opacity(0.02)],
                startPoint: .top,
                endPoint: .bottom
            )
        )
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
    
    private var multiDayPlanView: some View {
        VStack(spacing: 0) {
            if viewMode == .day {
                enhancedDayNavigationView
            }
            
            ScrollView {
                LazyVStack(spacing: 20) {
                    if viewMode == .week {
                        ForEach(dietManager.dietData.indices, id: \.self) { dayIndex in
                            DayCardView(
                                day: dietManager.dietData[dayIndex],
                                dayIndex: dayIndex,
                                isExpanded: expandedDay == dayIndex,
                                onToggleExpand: { 
                                    withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                                        expandedDay = expandedDay == dayIndex ? -1 : dayIndex
                                    }
                                }
                            )
                            .transition(.asymmetric(
                                insertion: .move(edge: .trailing).combined(with: .opacity),
                                removal: .move(edge: .leading).combined(with: .opacity)
                            ))
                        }
                    } else {
                        if let selectedDayData = dietManager.dietData.first(where: { $0.day == selectedDay }) {
                            // Stats del día
                            
                            ForEach(selectedDayData.meals.sorted(by: { $0.orderIndex < $1.orderIndex }), id: \.id) { meal in
                                MealCardView(meal: meal)
                                    .transition(.asymmetric(
                                        insertion: .move(edge: .trailing).combined(with: .opacity),
                                        removal: .move(edge: .leading).combined(with: .opacity)
                                    ))
                            }
                            
                            if !selectedDayData.supplements.isEmpty {
                                SupplementsView(supplements: selectedDayData.supplements)
                                    .transition(.move(edge: .bottom).combined(with: .opacity))
                            }
                        }
                    }
                }
                .padding()
                .animation(.spring(response: 0.6, dampingFraction: 0.8), value: viewMode)
                .animation(.spring(response: 0.6, dampingFraction: 0.8), value: selectedDay)
            }
            .background(
                LinearGradient(
                    colors: [Color(.systemGroupedBackground), Color.green.opacity(0.02)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
        }
        .onAppear {
            if selectedDay.isEmpty && !dietManager.dietData.isEmpty {
                selectedDay = dietManager.dietData[0].day
                currentDayIndex = 0
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
    
    private var enhancedDayNavigationView: some View {
        VStack(spacing: 12) {
            // Navegación de días mejorada
            HStack(spacing: 16) {
                if dietManager.dietData.count > 1 {
                    Button(action: navigateToPreviousDay) {
                        Image(systemName: "chevron.left.circle.fill")
                            .font(.title)
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.green, .green.opacity(0.7)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .background(Color.white, in: Circle())
                            .shadow(color: .green.opacity(0.2), radius: 4, x: 0, y: 2)
                    }
                    .disabled(currentDayIndex == 0)
                }
                
                Spacer()
                
                VStack(spacing: 4) {
                    Text(formatDayName(selectedDay))
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Text("Día \(currentDayIndex + 1) de \(dietManager.dietData.count)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                        .background(Color.green.opacity(0.1))
                        .cornerRadius(12)
                        .shadow(color: .green.opacity(0.15), radius: 2, x: 0, y: 1)
                }
                
                Spacer()
                
                if dietManager.dietData.count > 1 {
                    Button(action: navigateToNextDay) {
                        Image(systemName: "chevron.right.circle.fill")
                            .font(.title)
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.green, .green.opacity(0.7)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .background(Color.white, in: Circle())
                            .shadow(color: .green.opacity(0.2), radius: 4, x: 0, y: 2)
                    }
                    .disabled(currentDayIndex == dietManager.dietData.count - 1)
                }
            }
            
            // Indicador de progreso
            if dietManager.dietData.count > 1 {
                HStack(spacing: 4) {
                    ForEach(0..<dietManager.dietData.count, id: \.self) { index in
                        Capsule()
                            .fill(index == currentDayIndex ? Color.green : Color.green.opacity(0.3))
                            .frame(width: index == currentDayIndex ? 20 : 8, height: 4)
                            .animation(.spring(response: 0.3), value: currentDayIndex)
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(
                    LinearGradient(
                        colors: [Color(.systemBackground), Color(.systemBackground).opacity(0.95)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: 6)
                .shadow(color: .black.opacity(0.04), radius: 4, x: 0, y: 2)
        )
        .padding(.horizontal)
        .overlay(
            // Sombra adicional en la parte inferior para crear separación visual
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [
                            Color.clear,
                            Color.black.opacity(0.03),
                            Color.black.opacity(0.06),
                            Color.clear
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(height: 8)
                .offset(y: 40)
                .blur(radius: 2)
        )
    }
    
    private func navigateToPreviousDay() {
        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
            guard let currentIndex = dietManager.dietData.firstIndex(where: { $0.day == selectedDay }) else { return }
            let newIndex = max(0, currentIndex - 1)
            selectedDay = dietManager.dietData[newIndex].day
            currentDayIndex = newIndex
        }
    }
    
    private func navigateToNextDay() {
        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
            guard let currentIndex = dietManager.dietData.firstIndex(where: { $0.day == selectedDay }) else { return }
            let newIndex = min(dietManager.dietData.count - 1, currentIndex + 1)
            selectedDay = dietManager.dietData[newIndex].day
            currentDayIndex = newIndex
        }
    }
    
    // MARK: - Funciones auxiliares
    
    private func formatDayName(_ day: String) -> String {
        return day.capitalized
            .replacingOccurrences(of: "_", with: " ")
            .replacingOccurrences(of: "dia", with: "Día")
    }
    
    private func getDayIcon(for day: String) -> String {
        let dayLower = day.lowercased()
        
        if dayLower.contains("lunes") || dayLower.contains("monday") { return "🌅" }
        if dayLower.contains("martes") || dayLower.contains("tuesday") { return "💪" }
        if dayLower.contains("miercoles") || dayLower.contains("wednesday") { return "⚡" }
        if dayLower.contains("jueves") || dayLower.contains("thursday") { return "🔥" }
        if dayLower.contains("viernes") || dayLower.contains("friday") { return "🎯" }
        if dayLower.contains("sabado") || dayLower.contains("saturday") { return "🌟" }
        if dayLower.contains("domingo") || dayLower.contains("sunday") { return "🧘" }
        
        return "📅"
    }
}

// MARK: - Componentes auxiliares

struct StatPill: View {
    let value: String
    let label: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 4) {
            Text(value)
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(color)
            
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(color.opacity(0.1))
        .cornerRadius(8)
    }
}

// MARK: - Vista de Perfil (placeholder)

struct ProfileView: View {
    @EnvironmentObject var authManager: AuthManager
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // Avatar grande
                VStack(spacing: 16) {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [.green, .green.opacity(0.7)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 100, height: 100)
                        .overlay(
                            Text(authManager.user?.name.prefix(2).uppercased() ?? "US")
                                .font(.system(size: 36, weight: .bold))
                                .foregroundColor(.white)
                        )
                        .shadow(color: .green.opacity(0.3), radius: 20, x: 0, y: 10)
                    
                    VStack(spacing: 4) {
                        Text(authManager.user?.name ?? "Usuario")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text(authManager.user?.email ?? "")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                
                // Opciones
                VStack(spacing: 12) {
                    ProfileMenuItem(icon: "person.crop.circle", title: "Editar Perfil", action: {})
                    ProfileMenuItem(icon: "bell", title: "Notificaciones", action: {})
                    ProfileMenuItem(icon: "gear", title: "Configuración", action: {})
                }
                .padding()
                
                Spacer()
                
                // Cerrar sesión
                Button(action: {
                    authManager.logout()
                    dismiss()
                }) {
                    Text("Cerrar Sesión")
                        .fontWeight(.semibold)
                        .foregroundColor(.red)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(12)
                }
                .padding()
            }
            .navigationTitle("Perfil")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cerrar") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct ProfileMenuItem: View {
    let icon: String
    let title: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(.green)
                    .frame(width: 30)
                
                Text(title)
                    .font(.body)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}
