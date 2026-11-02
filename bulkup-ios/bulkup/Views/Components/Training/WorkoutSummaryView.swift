//
//  WorkoutSummaryView.swift
//  bulkup
//
//  Full-screen celebration overlay after finishing a workout session.
//

import SwiftUI

struct WorkoutSummaryView: View {
    let summary: WorkoutSummary
    var saveState: WorkoutSessionManager.SaveState
    var onRetry: () -> Void
    /// Save and open the recap (sensations, notes, photos, editable sets).
    var onReview: (() -> Void)? = nil
    var onSave: () -> Void
    /// Needed to look up the last session of this same day for the deltas.
    var userId: String? = nil
    var dayName: String? = nil
    /// Injected by the design preview; fetched from the backend otherwise.
    var previousSession: WorkoutSessionRecord? = nil

    @State private var showCheck = false
    @State private var showCard = false
    @State private var previous: WorkoutSessionRecord?

    var body: some View {
        ZStack {
            BulkUpColors.background
                .ignoresSafeArea()

            VStack(alignment: .leading, spacing: Spacing.xl) {
                Spacer()

                // Done mark
                ZStack {
                    RoundedRectangle(cornerRadius: CornerRadius.large, style: .continuous)
                        .fill(BulkUpColors.complete)
                        .frame(width: 64, height: 64)
                        .scaleEffect(showCheck ? 1.0 : 0.3)
                    Image(systemName: "checkmark")
                        .font(.system(.title, weight: .bold))
                        .foregroundColor(Color.onFill(BulkUpColors.complete))
                        .scaleEffect(showCheck ? 1.0 : 0.0)
                }

                // Title
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    Text("Entreno completado")
                        .displayVoice(40, weight: .extraBold, relativeTo: .largeTitle)
                        .foregroundColor(BulkUpColors.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)

                    if summary.isPartialCompletion {
                        HStack(spacing: Spacing.xs) {
                            Text("\(summary.exercisesCompleted)/\(summary.exercisesTotal)")
                                .font(BulkUpFont.mono(15, weight: .semibold, relativeTo: .subheadline))
                                .foregroundColor(BulkUpColors.textPrimary)
                            Text("ejercicios completados")
                                .font(BulkUpFont.body())
                                .foregroundColor(BulkUpColors.textSecondary)
                        }
                    }
                }
                .opacity(showCard ? 1 : 0)
                .offset(y: showCard ? 0 : 20)

                // Stats grid
                statsGrid
                    .opacity(showCard ? 1 : 0)
                    .offset(y: showCard ? 0 : 30)

                Spacer()

                // Actions
                VStack(spacing: Spacing.md) {
                    if saveState == .saving {
                        Text("Guardando...")
                            .font(BulkUpFont.caption())
                            .foregroundColor(BulkUpColors.textSecondary)
                    } else if saveState == .failed {
                        VStack(spacing: Spacing.sm) {
                            HStack(spacing: Spacing.xs) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                Text("No se pudo guardar tu entreno")
                            }
                            .font(BulkUpFont.caption())
                            .foregroundColor(BulkUpColors.warning)

                            Button {
                                onRetry()
                            } label: {
                                Label("Reintentar", systemImage: "arrow.clockwise")
                                    .secondaryButtonStyle()
                            }
                        }
                    }
                    Button {
                        onSave()
                    } label: {
                        Text("Guardar y salir")
                            .primaryButtonStyle()
                    }
                    .pressable()

                    if let onReview {
                        Button {
                            onReview()
                        } label: {
                            Label("Sensaciones, notas y fotos", systemImage: "square.and.pencil")
                                .secondaryButtonStyle()
                        }
                    }
                }
                .opacity(showCard ? 1 : 0)

                Spacer()
                    .frame(height: 40)
            }
            .padding(.horizontal, Spacing.screenH)
        }
        .task { await loadPreviousSession() }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                showCheck = true
            }
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.6)) {
                showCard = true
            }
        }
    }

    // MARK: - Stats Grid

    // MARK: - Previous session (the numbers as proof)

    /// Most recent saved session for the same training day, so every stat can
    /// say how it moved. Nothing is shown when there is no history.
    private func loadPreviousSession() async {
        if let previousSession { previous = previousSession; return }
        guard let userId, let dayName else { return }
        let folded = dayName.lowercased().folding(options: .diacriticInsensitive, locale: .current)
        let today = DateFormatter()
        today.locale = Locale(identifier: "en_US_POSIX")
        today.dateFormat = "yyyy-MM-dd"
        let todayString = today.string(from: summary.date)
        guard let sessions = try? await APIService.shared.getWorkoutSessions(userId: userId, limit: 40) else { return }
        previous = sessions
            .filter { $0.dayName.lowercased().folding(options: .diacriticInsensitive, locale: .current) == folded
                      && $0.date < todayString }
            .sorted { $0.date > $1.date }
            .first
    }

    private func delta(_ value: Double, unit: String, fraction: Int = 0) -> String? {
        guard abs(value) >= 0.5 else { return NSLocalizedString("igual que el último", comment: "") }
        let sign = value > 0 ? "+" : "−"
        let number = String(format: "%.\(fraction)f", abs(value))
        return String(format: NSLocalizedString("%@%@ %@ vs último", comment: "delta vs last session"), sign, number, unit)
    }

    private func durationDelta() -> String? {
        guard let previous else { return nil }
        let diff = summary.duration - previous.durationSeconds
        guard abs(diff) >= 30 else { return NSLocalizedString("igual que el último", comment: "") }
        let sign = diff > 0 ? "+" : "−"
        return String(format: NSLocalizedString("%@%@ vs último", comment: "delta vs last session"),
                      sign, WorkoutSummary.format(seconds: abs(diff)))
    }

    private var statsGrid: some View {
        LazyVGrid(columns: [
            GridItem(.flexible(), spacing: 0),
            GridItem(.flexible(), spacing: 0),
        ], spacing: 0) {
            statCell(
                value: summary.formattedDuration,
                label: "Duración",
                icon: "clock.fill",
                delta: durationDelta()
            )
            statCell(
                value: "\(summary.formattedVolume) kg",
                label: "Volumen",
                icon: "scalemass.fill",
                delta: previous.map { delta(summary.totalVolume - $0.totalVolume, unit: "kg") } ?? nil
            )
            statCell(
                value: "\(summary.totalSets)",
                label: "Series",
                icon: "number",
                delta: previous.map { delta(Double(summary.totalSets - $0.totalSets), unit: NSLocalizedString("series", comment: "")) } ?? nil
            )
            statCell(
                value: "\(summary.exercisesCompleted)",
                label: "Ejercicios",
                icon: "figure.strengthtraining.traditional",
                delta: previous.map { delta(Double(summary.exercisesCompleted - $0.exercisesCompleted), unit: NSLocalizedString("ej.", comment: "")) } ?? nil
            )
        }
        .background(BulkUpColors.line)   // 1pt gutters read as hairlines
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.large, style: .continuous))
        .hairline()
    }

    private func statCell(value: String, label: LocalizedStringKey, icon: String, delta: String? = nil) -> some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text(label)
                .microLabel()
            Text(value)
                .font(BulkUpFont.mono(26, weight: .semibold, relativeTo: .title2))
                .foregroundColor(BulkUpColors.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            if let delta {
                Text(delta)
                    .font(BulkUpFont.mono(11, relativeTo: .caption2))
                    .foregroundColor(delta.hasPrefix("+") ? BulkUpColors.accentText : BulkUpColors.textSecondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Spacing.md)
        .background(BulkUpColors.surface)
        .padding(0.5)
    }
}
