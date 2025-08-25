//
//  ExerciseExplorerView.swift
//  bulkup
//
//  Created by sebastianblancogonz on 18/8/25.
//
import SwiftData
import SwiftUI

struct ExerciseExplorerView: View {
    @StateObject private var exerciseExplorerManager = ExerciseExplorerManager.shared
    @State private var showFilters = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(.systemBackground)
                    .ignoresSafeArea()
                
                if exerciseExplorerManager.loading {
                    loadingView
                } else {
                    contentView
                }
            }
            .navigationBarTitleDisplayMode(.large)
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
        VStack(spacing: 0) {
            // Header con búsqueda y filtros
            VStack(spacing: 12) {
                // Búsqueda
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    
                    TextField("Buscar ejercicio...", text: $exerciseExplorerManager.searchTerm)
                        .textFieldStyle(PlainTextFieldStyle())
                        .onChange(of: exerciseExplorerManager.searchTerm) {
                            exerciseExplorerManager.resetPage()
                        }
                    
                    if !exerciseExplorerManager.searchTerm.isEmpty {
                        Button(action: { exerciseExplorerManager.searchTerm = "" }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding(12)
                .background(Color(.systemGray6))
                .cornerRadius(10)
                
                // Botón de filtros
                Button(action: { showFilters.toggle() }) {
                    HStack {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                        Text("Filtros")
                        
                        let activeFilters = exerciseExplorerManager.categoryFilter.count +
                                          exerciseExplorerManager.equipmentFilter.count +
                                          exerciseExplorerManager.forceFilter.count +
                                          exerciseExplorerManager.levelFilter.count
                        
                        if activeFilters > 0 {
                            Text("(\(activeFilters))")
                                .font(.caption)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                }
                .foregroundColor(.primary)
                
                // Panel de filtros expandible
                if showFilters {
                    filtersPanel
                        .transition(.asymmetric(
                            insertion: .move(edge: .top).combined(with: .opacity),
                            removal: .move(edge: .top).combined(with: .opacity)
                        ))
                }
            }
            .padding()
            .background(Color(.systemBackground))
            
            Divider()
            
            // Lista de ejercicios o estado vacío
            if exerciseExplorerManager.filteredExercises.isEmpty {
                emptyStateView
            } else {
                ScrollView {
                    LazyVGrid(columns: [
                        GridItem(.flexible(), spacing: 16),
                        GridItem(.flexible(), spacing: 16)
                    ], spacing: 16) {
                        ForEach(exerciseExplorerManager.paginatedExercises) { exercise in
                            ExerciseExplorerCardView(exercise: exercise)
                        }
                    }
                    .padding()
                    
                    // Paginación
                    if exerciseExplorerManager.totalPages > 1 {
                        paginationView
                            .padding(.bottom, 80)
                    }
                }
            }
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: showFilters)
    }
    
    private var filtersPanel: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Categoría
            FilterSection(
                title: "Categoría",
                options: exerciseExplorerManager.categories,
                selected: exerciseExplorerManager.categoryFilter,
                onSelectionChange: { newSelection in
                    exerciseExplorerManager.categoryFilter = newSelection
                    exerciseExplorerManager.resetPage()
                }
            )
            
            // Equipo
            FilterSection(
                title: "Equipo",
                options: exerciseExplorerManager.equipments,
                selected: exerciseExplorerManager.equipmentFilter,
                onSelectionChange: { newSelection in
                    exerciseExplorerManager.equipmentFilter = newSelection
                    exerciseExplorerManager.resetPage()
                }
            )
            
            // Fuerza
            FilterSection(
                title: "Fuerza",
                options: exerciseExplorerManager.forces,
                selected: exerciseExplorerManager.forceFilter,
                onSelectionChange: { newSelection in
                    exerciseExplorerManager.forceFilter = newSelection
                    exerciseExplorerManager.resetPage()
                }
            )
            
            // Nivel
            FilterSection(
                title: "Nivel",
                options: exerciseExplorerManager.levels,
                selected: exerciseExplorerManager.levelFilter,
                onSelectionChange: { newSelection in
                    exerciseExplorerManager.levelFilter = newSelection
                    exerciseExplorerManager.resetPage()
                }
            )
            
            // Botón limpiar filtros
            if !exerciseExplorerManager.categoryFilter.isEmpty ||
               !exerciseExplorerManager.equipmentFilter.isEmpty ||
               !exerciseExplorerManager.forceFilter.isEmpty ||
               !exerciseExplorerManager.levelFilter.isEmpty {
                Button(action: exerciseExplorerManager.resetFilters) {
                    HStack {
                        Image(systemName: "trash")
                        Text("Limpiar todos los filtros")
                    }
                    .foregroundColor(.red)
                    .font(.footnote)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            Text("No se encontraron ejercicios")
                .font(.headline)
            
            Text("Prueba con otros términos de búsqueda")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
    
    private var paginationView: some View {
        HStack(spacing: 20) {
            Button(action: {
                exerciseExplorerManager.currentPage = max(1, exerciseExplorerManager.currentPage - 1)
            }) {
                HStack {
                    Image(systemName: "chevron.left")
                    Text("Anterior")
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color(.systemGray5))
                .cornerRadius(8)
            }
            .disabled(exerciseExplorerManager.currentPage == 1)
            
            Text("Página \(exerciseExplorerManager.currentPage) de \(exerciseExplorerManager.totalPages)")
                .font(.subheadline)
                .fontWeight(.medium)
            
            Button(action: {
                exerciseExplorerManager.currentPage = min(exerciseExplorerManager.totalPages, exerciseExplorerManager.currentPage + 1)
            }) {
                HStack {
                    Text("Siguiente")
                    Image(systemName: "chevron.right")
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color(.systemGray5))
                .cornerRadius(8)
            }
            .disabled(exerciseExplorerManager.currentPage == exerciseExplorerManager.totalPages)
        }
        .foregroundColor(.primary)
    }
}
