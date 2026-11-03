//
//  ExerciseExplorerView.swift
//  bulkup
//
//  The exercise library: a search field, four filter chips that open native
//  menus, and one long slab of rows. The name is the element; the rest is a
//  quiet caption. Grows with "Mostrar más" instead of paging.
//

import SwiftUI

struct ExerciseExplorerView: View {
    @ObservedObject private var manager = ExerciseExplorerManager.shared
    @Environment(\.dismiss) private var dismiss
    @State private var selectedExercise: RMExerciseFull?

    var body: some View {
        ZStack {
            BulkUpGround()

            if manager.loading {
                loadingView
            } else {
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: Spacing.md) {
                        header
                        SearchBar(text: $manager.searchTerm)
                        filterChips
                        results
                    }
                    .padding(.horizontal, Spacing.screenH)
                    .padding(.top, Spacing.lg)
                    .padding(.bottom, Spacing.xxl)
                }
                .scrollDismissesKeyboard(.immediately)
            }
        }
        .presentationDragIndicator(.visible)
        .presentationBackground(BulkUpColors.background)
        .onChange(of: manager.searchTerm) { _, _ in manager.resetPage() }
        .sheet(item: $selectedExercise) { exercise in
            RMExerciseDetailSheet(exercise: exercise)
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Ejercicios")
                    .titleVoice(.title)
                    .foregroundColor(BulkUpColors.textPrimary)
                Text(String(format: NSLocalizedString("%lld en la biblioteca", comment: ""), manager.exercises.count))
                    .font(BulkUpFont.numeric(.subheadline, weight: .medium))
                    .foregroundColor(BulkUpColors.textSecondary)
            }
            Spacer(minLength: Spacing.md)
            Button {
                dismiss()
            } label: {
                Text("Cerrar")
                    .font(.system(.footnote, weight: .semibold))
                    .foregroundColor(BulkUpColors.textSecondary)
                    .frame(minHeight: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Filters

    private var filterChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Spacing.sm) {
                // Leading, so it is visible without scrolling the row.
                if manager.hasActiveFilters {
                    Button {
                        withAnimation(.easeOut(duration: 0.2)) { manager.resetFilters() }
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(.footnote, weight: .semibold))
                            .foregroundColor(BulkUpColors.accentText)
                            .frame(width: 36, height: 36)
                            .background(Capsule().fill(BulkUpColors.accent.opacity(0.14)))
                            .padding(.vertical, 4)
                            .contentShape(Capsule())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Limpiar filtros")
                    .transition(.opacity)
                }

                FilterChip(title: "Categoría", titleKey: "Categoría", options: manager.categories, selection: $manager.categoryFilter) { manager.resetPage() }
                FilterChip(title: "Equipo", titleKey: "Equipo", options: manager.equipments, selection: $manager.equipmentFilter) { manager.resetPage() }
                FilterChip(title: "Fuerza", titleKey: "Fuerza", options: manager.forces, selection: $manager.forceFilter) { manager.resetPage() }
                FilterChip(title: "Nivel", titleKey: "Nivel", options: manager.levels, selection: $manager.levelFilter) { manager.resetPage() }
            }
            .padding(.vertical, 2)
            .padding(.trailing, Spacing.screenH)
        }
        .padding(.horizontal, -Spacing.screenH)
        .padding(.leading, Spacing.screenH)
        .frame(minHeight: 44)
        .animation(.easeOut(duration: 0.2), value: manager.hasActiveFilters)
    }

    // MARK: - Results

    @ViewBuilder
    private var results: some View {
        let filtered = manager.filteredExercises
        let visible = manager.visibleExercises

        if filtered.isEmpty {
            emptyState
        } else {
            Text(String(format: NSLocalizedString("%lld ejercicios", comment: ""), filtered.count))
                .font(BulkUpFont.numeric(.footnote, weight: .medium))
                .foregroundColor(BulkUpColors.textSecondary)
                .contentTransition(.numericText())
                .padding(.top, Spacing.xs)

            LazyVStack(spacing: 0) {
                ForEach(Array(visible.enumerated()), id: \.element.id) { index, exercise in
                    ExerciseRow(exercise: exercise, showsSeparator: index < visible.count - 1) {
                        selectedExercise = exercise
                    }
                }
            }
            .slab()

            if manager.hasMoreExercises {
                VStack(spacing: Spacing.sm) {
                    Button {
                        withAnimation(.easeOut(duration: 0.25)) { manager.currentPage += 1 }
                    } label: {
                        Text("Mostrar más")
                            .font(.system(.headline, weight: .semibold))
                            .foregroundColor(BulkUpColors.textPrimary)
                            .frame(maxWidth: .infinity, minHeight: 50)
                            .background(BulkUpColors.surfaceElevated)
                            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.medium, style: .continuous))
                    }
                    .buttonStyle(.plain)
                    .pressable()

                    Text(String(format: NSLocalizedString("%lld de %lld", comment: ""), visible.count, filtered.count))
                        .font(BulkUpFont.numeric(.caption, weight: .medium))
                        .foregroundColor(BulkUpColors.textTertiary)
                }
                .padding(.top, Spacing.sm)
            }
        }
    }

    private var emptyState: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("Ningún ejercicio coincide")
                .font(.system(.headline, weight: .semibold))
                .foregroundColor(BulkUpColors.textPrimary)
            Text("Prueba con otro nombre o quita algún filtro.")
                .font(BulkUpFont.body())
                .foregroundColor(BulkUpColors.textSecondary)
            if manager.hasActiveFilters {
                Button {
                    withAnimation(.easeOut(duration: 0.2)) { manager.resetFilters() }
                } label: {
                    Text("Limpiar filtros")
                        .font(.system(.footnote, weight: .semibold))
                        .foregroundColor(BulkUpColors.accentText)
                        .frame(minHeight: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(Spacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .slab()
        .padding(.top, Spacing.xs)
    }

    private var loadingView: some View {
        VStack(spacing: Spacing.md) {
            ProgressView()
                .controlSize(.large)
                .tint(BulkUpColors.accent)
            Text("Cargando ejercicios")
                .font(BulkUpFont.body())
                .foregroundColor(BulkUpColors.textSecondary)
        }
    }
}

// MARK: - Filter chip (capsule that opens a native menu with check marks)

struct FilterChip: View {
    let title: LocalizedStringKey
    /// The same title as a catalog key, for the accessibility label.
    let titleKey: String
    let options: [String]
    @Binding var selection: Set<String>
    let onChange: () -> Void

    private var isActive: Bool { !selection.isEmpty }

    var body: some View {
        Menu {
            ForEach(options, id: \.self) { option in
                Toggle(isOn: Binding(
                    get: { selection.contains(option) },
                    set: { on in
                        if on { selection.insert(option) } else { selection.remove(option) }
                        onChange()
                    }
                )) {
                    Text(LocalizedStringKey(ExerciseVocabulary.catalogKey(for: option)))
                }
            }
            if isActive {
                Divider()
                Button {
                    selection = []
                    onChange()
                } label: {
                    Label("Quitar filtro", systemImage: "xmark")
                }
            }
        } label: {
            HStack(spacing: 4) {
                Text(title)
                if isActive {
                    Text("· \(selection.count)")
                        .monospacedDigit()
                }
                Image(systemName: "chevron.down")
                    .font(.system(.caption2, weight: .semibold))
                    .accessibilityHidden(true)
            }
            .font(.system(.footnote, weight: .semibold))
            .foregroundColor(isActive ? BulkUpColors.accentText : BulkUpColors.textPrimary)
            .padding(.horizontal, 12)
            .frame(minHeight: 36)
            .background(
                Capsule().fill(isActive ? BulkUpColors.accent.opacity(0.14) : BulkUpColors.surfaceElevated)
            )
            .padding(.vertical, 4)
            .contentShape(Capsule())
        }
        .menuOrder(.fixed)
        .accessibilityLabel(isActive
            ? Text(String(format: NSLocalizedString("%@, %lld seleccionados", comment: ""), String(localized: String.LocalizationValue(titleKey)), selection.count))
            : Text(title))
        .animation(.easeOut(duration: 0.2), value: isActive)
    }
}

// MARK: - Row

struct ExerciseRow: View {
    let exercise: RMExerciseFull
    var showsSeparator: Bool = true
    let action: () -> Void

    private var meta: String {
        [exercise.localizedPrimaryMuscles.first, exercise.localizedEquipment, exercise.localizedLevel]
            .compactMap { $0 }
            .joined(separator: " · ")
    }

    var body: some View {
        Button(action: action) {
            SlabRow(showsSeparator: showsSeparator, minHeight: 60) {
                HStack(spacing: Spacing.md) {
                    ExerciseThumbnail(exercise: exercise, size: 44)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(exercise.localizedName)
                            .font(.system(.subheadline, weight: .semibold))
                            .foregroundColor(BulkUpColors.textPrimary)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                        if !meta.isEmpty {
                            Text(meta)
                                .font(BulkUpFont.caption())
                                .foregroundColor(BulkUpColors.textSecondary)
                                .lineLimit(2)
                        }
                    }

                    Spacer(minLength: Spacing.sm)

                    Image(systemName: "chevron.right")
                        .font(.system(.caption, weight: .semibold))
                        .foregroundColor(BulkUpColors.textTertiary)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
    }
}

/// The exercise's first image on a raised square, or a quiet figure glyph.
struct ExerciseThumbnail: View {
    let exercise: RMExerciseFull
    var size: CGFloat = 44

    var body: some View {
        ZStack {
            BulkUpColors.surfaceElevated
            if let first = exercise.images?.first, let url = URL(string: first) {
                CachedAsyncImage(
                    url: url,
                    content: { image, _ in
                        image.resizable().scaledToFill()
                    },
                    placeholder: { glyph }
                )
            } else {
                glyph
            }
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.small, style: .continuous))
    }

    private var glyph: some View {
        Image(systemName: ExerciseVocabulary.glyph(forCategory: exercise.category))
            .font(.system(.body, weight: .medium))
            .foregroundColor(BulkUpColors.textTertiary)
    }
}
