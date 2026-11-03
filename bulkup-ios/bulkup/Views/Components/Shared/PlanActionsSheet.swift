//
//  PlanActionsSheet.swift
//  bulkup
//
//  The hub's "more" sheet: one slab of ways a new plan comes in (file, template,
//  by hand, by code) and one slab for what belongs to the plan you already have.
//  Both hubs (Entreno and Dieta) and both empty states share these rows.
//

import SwiftUI

enum PlanHubKind {
    case training
    case diet
}

enum PlanAction: Hashable {
    case importFile
    case template
    case manual
    case code
    case exerciseLibrary
    case foodPreferences
}

// MARK: - Row

/// A row inside a lifted slab: glyph, title, one-line reason, PRO tag when
/// the tier does not include it, chevron. 60pt tall.
struct PlanActionRow: View {
    let glyph: String
    let title: LocalizedStringKey
    let subtitle: LocalizedStringKey
    var locked: Bool = false
    var showsSeparator: Bool = true
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            SlabRow(showsSeparator: showsSeparator, minHeight: 60) {
                HStack(spacing: Spacing.md) {
                    Image(systemName: glyph)
                        .font(.system(.body, weight: .medium))
                        .foregroundColor(BulkUpColors.textSecondary)
                        .frame(width: 28)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(title)
                            .font(.system(.headline, weight: .semibold))
                            .foregroundColor(BulkUpColors.textPrimary)
                        Text(subtitle)
                            .font(BulkUpFont.caption())
                            .foregroundColor(BulkUpColors.textSecondary)
                            .lineLimit(2)
                    }

                    Spacer(minLength: Spacing.sm)

                    if locked {
                        ProTag()
                    }

                    Image(systemName: "chevron.right")
                        .font(.system(.caption, weight: .semibold))
                        .foregroundColor(BulkUpColors.textTertiary)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityHint(locked ? Text("Requiere PRO") : Text(""))
    }
}

/// Solid lime "PRO" tag: the one place a feature says it is paid.
struct ProTag: View {
    var body: some View {
        Text("PRO")
            .font(.system(.caption2, weight: .semibold))
            .foregroundColor(BulkUpColors.onAccent)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(BulkUpColors.accent)
            .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
    }
}

// MARK: - "Nuevo plan" slab (shared by the sheet and the empty hubs)

struct NewPlanRows: View {
    let kind: PlanHubKind
    let isSubscribed: Bool
    /// Free tier keeps one plan per kind; a second one asks for PRO.
    let canCreateAnother: Bool
    let onAction: (PlanAction) -> Void

    var body: some View {
        VStack(spacing: 0) {
            PlanActionRow(
                glyph: "doc.viewfinder",
                title: "Importar PDF o foto",
                subtitle: "La rutina o la dieta, da igual: la detectamos",
                locked: !isSubscribed
            ) { onAction(.importFile) }

            if kind == .training {
                PlanActionRow(
                    glyph: "square.grid.2x2",
                    title: "Usar plantilla",
                    subtitle: "Empieza con una rutina hecha",
                    locked: !canCreateAnother
                ) { onAction(.template) }
            }

            PlanActionRow(
                glyph: "square.and.pencil",
                title: "Crear a mano",
                subtitle: kind == .training ? "Ejercicio a ejercicio, serie a serie" : "Comida a comida",
                locked: !canCreateAnother,
                showsSeparator: kind == .training
            ) { onAction(.manual) }

            if kind == .training {
                PlanActionRow(
                    glyph: "number",
                    title: "Tengo un código",
                    subtitle: "Un plan que te han compartido",
                    locked: !isSubscribed,
                    showsSeparator: false
                ) { onAction(.code) }
            }
        }
        .slab()
    }
}

// MARK: - Sheet

struct PlanActionsSheet: View {
    let kind: PlanHubKind
    let isSubscribed: Bool
    let canCreateAnother: Bool
    /// The hub is showing a plan (not the library, not empty).
    let hasActivePlan: Bool
    /// Training only: the day/week switch for the active plan.
    var viewMode: Binding<TrainingView.ViewMode>? = nil
    let onAction: (PlanAction) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var contentHeight: CGFloat = 0

    private var showsContextSlab: Bool {
        switch kind {
        case .training: return true
        case .diet: return hasActivePlan
        }
    }

    var body: some View {
        ZStack {
            BulkUpGround()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: Spacing.md) {
                    Text("Nuevo plan")
                        .titleVoice(.title2)
                        .foregroundColor(BulkUpColors.textPrimary)
                        .padding(.top, Spacing.sm)

                    NewPlanRows(kind: kind, isSubscribed: isSubscribed, canCreateAnother: canCreateAnother) { action in
                        dismiss()
                        onAction(action)
                    }

                    if showsContextSlab {
                        contextSlab
                    }
                }
                .padding(.horizontal, Spacing.screenH)
                .padding(.top, Spacing.lg)
                .padding(.bottom, Spacing.xs)
                .measureHeight($contentHeight)
            }
        }
        // The sheet fits its rows at the current text size; .large stays as the fallback.
        .presentationDetents(contentHeight > 0 ? [.height(contentHeight), .large] : [.medium, .large])
        .presentationDragIndicator(.visible)
        .presentationBackground(BulkUpColors.background)
    }

    private var contextSlab: some View {
        VStack(spacing: 0) {
            switch kind {
            case .training:
                if hasActivePlan, let viewMode {
                    SlabRow(minHeight: 56) {
                        HStack(spacing: Spacing.md) {
                            Image(systemName: "calendar")
                                .font(.system(.body, weight: .medium))
                                .foregroundColor(BulkUpColors.textSecondary)
                                .frame(width: 28)
                            Text("Vista")
                                .font(.system(.headline, weight: .semibold))
                                .foregroundColor(BulkUpColors.textPrimary)
                            Spacer(minLength: Spacing.sm)
                            Picker("Vista", selection: viewMode) {
                                Text("Diario").tag(TrainingView.ViewMode.day)
                                Text("Semanal").tag(TrainingView.ViewMode.week)
                            }
                            .pickerStyle(.segmented)
                            .frame(maxWidth: 190)
                        }
                    }
                }
                PlanActionRow(
                    glyph: "books.vertical",
                    title: "Explorar ejercicios",
                    subtitle: "Más de 1.000 ejercicios con imágenes",
                    showsSeparator: false
                ) {
                    dismiss()
                    onAction(.exerciseLibrary)
                }
            case .diet:
                PlanActionRow(
                    glyph: "fork.knife",
                    title: "Preferencias y alergias",
                    subtitle: "Lo que no comes y lo que prefieres",
                    showsSeparator: false
                ) {
                    dismiss()
                    onAction(.foodPreferences)
                }
            }
        }
        .slab()
    }
}

// MARK: - Empty hub

/// "Sin plan activo" plus the same slab of rows the sheet shows.
struct EmptyHubView: View {
    let kind: PlanHubKind
    let isSubscribed: Bool
    let canCreateAnother: Bool
    let onAction: (PlanAction) -> Void
    let onShowLibrary: () -> Void

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: Spacing.md) {
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text("Sin plan activo")
                        .titleVoice(.largeTitle)
                        .foregroundColor(BulkUpColors.textPrimary)
                    Text(kind == .training
                         ? "Sube la rutina que ya tienes o empieza una. Lo que tengas guardado está en Mis planes."
                         : "Sube la dieta que ya tienes o escríbela a mano. Lo que tengas guardado está en Mis planes.")
                        .font(BulkUpFont.body())
                        .foregroundColor(BulkUpColors.textSecondary)
                }
                .padding(.top, Spacing.sm)
                .padding(.bottom, Spacing.sm)

                NewPlanRows(kind: kind, isSubscribed: isSubscribed, canCreateAnother: canCreateAnother, onAction: onAction)

                Button(action: onShowLibrary) {
                    Text("Ver mis planes")
                        .font(.system(.footnote, weight: .semibold))
                        .foregroundColor(BulkUpColors.accentText)
                        .frame(minHeight: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, Spacing.screenH)
            .padding(.bottom, Spacing.xxl)
        }
    }
}

// MARK: - Measured sheets

private struct ContentHeightKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) { value = max(value, nextValue()) }
}

extension View {
    /// Reports the view's laid-out height, so a sheet can size its detent to its content.
    func measureHeight(_ height: Binding<CGFloat>) -> some View {
        background(
            GeometryReader { geo in
                Color.clear.preference(key: ContentHeightKey.self, value: geo.size.height)
            }
        )
        .onPreferenceChange(ContentHeightKey.self) { height.wrappedValue = $0 }
    }
}
