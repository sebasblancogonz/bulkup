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
        NavigationStack {
            ZStack {
                BulkUpColors.background.ignoresSafeArea()

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
                                .font(BulkUpFont.sectionHeader())
                                .foregroundColor(BulkUpColors.accent)

                            let activeFilters = exerciseExplorerManager.categoryFilter.count +
                                              exerciseExplorerManager.equipmentFilter.count +
                                              exerciseExplorerManager.forceFilter.count +
                                              exerciseExplorerManager.levelFilter.count

                            if activeFilters > 0 {
                                Circle()
                                    .fill(BulkUpColors.error)
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
        VStack(spacing: Spacing.lg) {
            ProgressView()
                .scaleEffect(1.5)
                .tint(BulkUpColors.accent)

            Text("Cargando ejercicios...")
                .font(BulkUpFont.cardTitle())
                .foregroundColor(BulkUpColors.textSecondary)
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
                            GridItem(.flexible(), spacing: Spacing.md),
                            GridItem(.flexible(), spacing: Spacing.md)
                        ],
                        spacing: Spacing.md
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
                            .padding(.bottom, Spacing.sm)
                    }

                    // Paginación
                    if exerciseExplorerManager.totalPages > 1 {
                        paginationView
                            .padding(.bottom, Spacing.lg)
                    }
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

    private var emptyStateView: some View {
        EmptyStateView(
            icon: "magnifyingglass",
            title: "No se encontraron ejercicios",
            subtitle: "Prueba con otros términos de búsqueda o ajusta los filtros",
            color: BulkUpColors.training,
            actionTitle: hasActiveFilters ? "Limpiar filtros" : nil,
            actionIcon: hasActiveFilters ? "xmark.circle.fill" : nil,
            action: hasActiveFilters ? { exerciseExplorerManager.resetFilters() } : nil
        )
    }

    private var resultsInfoView: some View {
        HStack {
            Text("Mostrando \(exerciseExplorerManager.paginatedExercises.count) de \(exerciseExplorerManager.filteredExercises.count) ejercicios")
                .font(BulkUpFont.caption())
                .foregroundColor(BulkUpColors.textSecondary)

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
                .padding(.horizontal, Spacing.screenH)
                .padding(.vertical, Spacing.sm)
                .background(
                    exerciseExplorerManager.currentPage == 1
                        ? BulkUpColors.surfaceElevated
                        : BulkUpColors.training
                )
                .foregroundColor(
                    exerciseExplorerManager.currentPage == 1
                        ? BulkUpColors.textSecondary
                        : .white
                )
                .cornerRadius(CornerRadius.small)
                .contentShape(Rectangle())
            }
            .disabled(exerciseExplorerManager.currentPage == 1)

            Text("Página \(exerciseExplorerManager.currentPage) de \(exerciseExplorerManager.totalPages)")
                .font(BulkUpFont.body())
                .foregroundColor(BulkUpColors.textPrimary)

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
                .padding(.horizontal, Spacing.screenH)
                .padding(.vertical, Spacing.sm)
                .background(
                    exerciseExplorerManager.currentPage == exerciseExplorerManager.totalPages
                        ? BulkUpColors.surfaceElevated
                        : BulkUpColors.training
                )
                .foregroundColor(
                    exerciseExplorerManager.currentPage == exerciseExplorerManager.totalPages
                        ? BulkUpColors.textSecondary
                        : .white
                )
                .cornerRadius(CornerRadius.small)
                .contentShape(Rectangle())
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
        NavigationStack {
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

                    // Botón limpiar filtros
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
                            .foregroundColor(BulkUpColors.error)
                            .contentShape(Rectangle())
                        }
                        .padding(.top, 8)
                    }
                }
                .padding()
            }
            .background(BulkUpColors.background.ignoresSafeArea())
            .navigationTitle("Filtros")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Listo") {
                        isPresented = false
                    }
                    .fontWeight(.semibold)
                    .foregroundColor(BulkUpColors.accent)
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
