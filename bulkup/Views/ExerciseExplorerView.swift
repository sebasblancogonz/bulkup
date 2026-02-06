//
//  ExerciseExplorerView.swift
//  bulkup
//
//  Vista con buscador y filtros en el toolbar
//

import SwiftData
import SwiftUI

struct ExerciseExplorerView: View {
    @ObservedObject private var exerciseExplorerManager = ExerciseExplorerManager.shared
    @State private var showFilters = false
    
    var body: some View {
        NavigationView {
            ZStack {
                if exerciseExplorerManager.loading {
                    loadingView
                } else {
                    contentView
                }
            }
            .navigationTitle("Ejercicios")
            .navigationBarTitleDisplayMode(.large)
            .searchable(
                text: $exerciseExplorerManager.searchTerm,
                placement: .navigationBarDrawer(displayMode: .always),
                prompt: "Buscar ejercicio..."
            )
            .onChange(of: exerciseExplorerManager.searchTerm) { _, _ in
                exerciseExplorerManager.resetPage()
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showFilters.toggle()
                    }) {
                        ZStack(alignment: .topTrailing) {
                            Image(systemName: "line.3.horizontal.decrease.circle")
                                .font(.title3)
                            
                            let activeFilters = exerciseExplorerManager.categoryFilter.count +
                                              exerciseExplorerManager.equipmentFilter.count +
                                              exerciseExplorerManager.forceFilter.count +
                                              exerciseExplorerManager.levelFilter.count
                            
                            if activeFilters > 0 {
                                Circle()
                                    .fill(Color.red)
                                    .frame(width: 18, height: 18)
                                    .overlay(
                                        Text("\(activeFilters)")
                                            .font(.system(size: 10, weight: .bold))
                                            .foregroundColor(.white)
                                    )
                                    .offset(x: 8, y: -8)
                            }
                        }
                    }
                }
            }
            .sheet(isPresented: $showFilters) {
                FilterSheet(
                    exerciseExplorerManager: exerciseExplorerManager,
                    isPresented: $showFilters
                )
            }
        }
    }
    
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
                .tint(.blue)
            
            Text("Cargando ejercicios...")
                .font(.headline)
                .foregroundColor(.secondary)
        }
    }
    
    private var contentView: some View {
        Group {
            if exerciseExplorerManager.filteredExercises.isEmpty {
                emptyStateView
            } else {
                ScrollView {
                    // Grid de tarjetas compactas
                    LazyVGrid(
                        columns: [
                            GridItem(.flexible(), spacing: 12),
                            GridItem(.flexible(), spacing: 12)
                        ],
                        spacing: 12
                    ) {
                        ForEach(exerciseExplorerManager.paginatedExercises) { exercise in
                            CompactExerciseCard(exercise: exercise)
                        }
                    }
                    .padding()
                    
                    // Información de resultados
                    if exerciseExplorerManager.filteredExercises.count > 0 {
                        resultsInfoView
                            .padding(.horizontal)
                            .padding(.bottom, 8)
                    }
                    
                    // Paginación
                    if exerciseExplorerManager.totalPages > 1 {
                        paginationView
                            .padding(.bottom, 80)
                    }
                }
            }
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            Text("No se encontraron ejercicios")
                .font(.headline)
            
            Text("Prueba con otros términos de búsqueda o ajusta los filtros")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            if !exerciseExplorerManager.categoryFilter.isEmpty ||
               !exerciseExplorerManager.equipmentFilter.isEmpty ||
               !exerciseExplorerManager.forceFilter.isEmpty ||
               !exerciseExplorerManager.levelFilter.isEmpty {
                Button(action: exerciseExplorerManager.resetFilters) {
                    Text("Limpiar filtros")
                        .font(.callout)
                        .fontWeight(.medium)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
    
    private var resultsInfoView: some View {
        HStack {
            Text("Mostrando \(exerciseExplorerManager.paginatedExercises.count) de \(exerciseExplorerManager.filteredExercises.count) ejercicios")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Spacer()
        }
    }
    
    private var paginationView: some View {
        HStack(spacing: 20) {
            Button(action: {
                exerciseExplorerManager.currentPage = max(1, exerciseExplorerManager.currentPage - 1)
            }) {
                HStack(spacing: 4) {
                    Image(systemName: "chevron.left")
                    Text("Anterior")
                }
                .font(.callout)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    exerciseExplorerManager.currentPage == 1
                        ? Color(.systemGray5)
                        : Color.blue
                )
                .foregroundColor(
                    exerciseExplorerManager.currentPage == 1
                        ? .secondary
                        : .white
                )
                .cornerRadius(8)
            }
            .disabled(exerciseExplorerManager.currentPage == 1)
            
            Text("Página \(exerciseExplorerManager.currentPage) de \(exerciseExplorerManager.totalPages)")
                .font(.subheadline)
                .fontWeight(.medium)
            
            Button(action: {
                exerciseExplorerManager.currentPage = min(
                    exerciseExplorerManager.totalPages,
                    exerciseExplorerManager.currentPage + 1
                )
            }) {
                HStack(spacing: 4) {
                    Text("Siguiente")
                    Image(systemName: "chevron.right")
                }
                .font(.callout)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    exerciseExplorerManager.currentPage == exerciseExplorerManager.totalPages
                        ? Color(.systemGray5)
                        : Color.blue
                )
                .foregroundColor(
                    exerciseExplorerManager.currentPage == exerciseExplorerManager.totalPages
                        ? .secondary
                        : .white
                )
                .cornerRadius(8)
            }
            .disabled(exerciseExplorerManager.currentPage == exerciseExplorerManager.totalPages)
        }
    }
}

// MARK: - Filter Sheet

struct FilterSheet: View {
    @ObservedObject var exerciseExplorerManager: ExerciseExplorerManager
    @Binding var isPresented: Bool
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Categoría
                    FilterSection(
                        title: "Categoría",
                        options: exerciseExplorerManager.categories,
                        selected: exerciseExplorerManager.categoryFilter,
                        onSelectionChange: { newSelection in
                            exerciseExplorerManager.categoryFilter = newSelection
                            exerciseExplorerManager.resetPage()
                        },
                    )
                    
                    Divider()
                    
                    // Equipo
                    FilterSection(
                        title: "Equipo",
                        options: exerciseExplorerManager.equipments,
                        selected: exerciseExplorerManager.equipmentFilter,
                        onSelectionChange: { newSelection in
                            exerciseExplorerManager.equipmentFilter = newSelection
                            exerciseExplorerManager.resetPage()
                        },
                    )
                    
                    Divider()
                    
                    // Fuerza
                    FilterSection(
                        title: "Fuerza",
                        options: exerciseExplorerManager.forces,
                        selected: exerciseExplorerManager.forceFilter,
                        onSelectionChange: { newSelection in
                            exerciseExplorerManager.forceFilter = newSelection
                            exerciseExplorerManager.resetPage()
                        },
                    )
                    
                    Divider()
                    
                    // Nivel
                    FilterSection(
                        title: "Nivel",
                        options: exerciseExplorerManager.levels,
                        selected: exerciseExplorerManager.levelFilter,
                        onSelectionChange: { newSelection in
                            exerciseExplorerManager.levelFilter = newSelection
                            exerciseExplorerManager.resetPage()
                        },
                    )
                    
                    // Botón limpiar filtros (si hay filtros activos)
                    if hasActiveFilters {
                        Divider()
                        
                        Button(action: {
                            exerciseExplorerManager.resetFilters()
                        }) {
                            HStack {
                                Image(systemName: "trash")
                                Text("Limpiar todos los filtros")
                                Spacer()
                            }
                            .foregroundColor(.red)
                        }
                        .padding(.top, 8)
                    }
                }
                .padding()
            }
            .navigationTitle("Filtros")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Listo") {
                        isPresented = false
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
    
    private var hasActiveFilters: Bool {
        !exerciseExplorerManager.categoryFilter.isEmpty ||
        !exerciseExplorerManager.equipmentFilter.isEmpty ||
        !exerciseExplorerManager.forceFilter.isEmpty ||
        !exerciseExplorerManager.levelFilter.isEmpty
    }
    
    // Translation functions
    private func translateCategory(_ category: String) -> String {
        let translations: [String: String] = [
            "strength": "Fuerza",
            "stretching": "Estiramiento",
            "plyometrics": "Pliometría",
            "strongman": "Strongman",
            "powerlifting": "Powerlifting",
            "cardio": "Cardio",
            "olympic weightlifting": "Halterofilia"
        ]
        return translations[category.lowercased()] ?? category.capitalized
    }
    
    private func translateLevel(_ level: String) -> String {
        let translations: [String: String] = [
            "beginner": "Principiante",
            "intermediate": "Intermedio",
            "expert": "Experto"
        ]
        return translations[level.lowercased()] ?? level.capitalized
    }
    
    private func translateForce(_ force: String) -> String {
        let translations: [String: String] = [
            "push": "Empuje",
            "pull": "Jalón",
            "static": "Estático"
        ]
        return translations[force.lowercased()] ?? force.capitalized
    }
    
    private func translateEquipment(_ equipment: String) -> String {
        let translations: [String: String] = [
            "barbell": "Barra",
            "dumbbell": "Mancuerna",
            "body only": "Peso corporal",
            "machine": "Máquina",
            "cable": "Cable",
            "kettlebells": "Pesas rusas",
            "bands": "Bandas",
            "medicine ball": "Balón medicinal",
            "exercise ball": "Pelota de ejercicio",
            "e-z curl bar": "Barra Z",
            "foam roll": "Rodillo de espuma",
            "other": "Otro"
        ]
        return translations[equipment.lowercased()] ?? equipment.capitalized
    }
}

