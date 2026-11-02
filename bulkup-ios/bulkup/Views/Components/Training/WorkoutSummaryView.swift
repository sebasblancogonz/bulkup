//
//  WorkoutSummaryView.swift
//  bulkup
//
//  Full-screen close after a workout: the peak-end of the session. Leads with
//  the one number that moved (volume) and says, in a sentence, how it moved.
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
        ZStack(alignment: .top) {
            BulkUpColors.background
                .ignoresSafeArea()

            // The one screen where lime may own a region: a warm glow from the
            // top that fades into the ground before the actions.
            LinearGradient(
                colors: [BulkUpColors.accent.opacity(0.16), BulkUpColors.accent.opacity(0.0)],
                startPoint: .top, endPoint: .bottom
            )
            .frame(height: 420)
            .ignoresSafeArea()
            .opacity(showCard ? 1 : 0)

            VStack(alignment: .leading, spacing: Spacing.lg) {
                Spacer().frame(height: Spacing.xl)

                // Done mark
                ZStack {
                    RoundedRectangle(cornerRadius: CornerRadius.large, style: .continuous)
                        .fill(BulkUpColors.complete)
                        .frame(width: 56, height: 56)
                        .scaleEffect(showCheck ? 1.0 : 0.3)
                    Image(systemName: "checkmark")
                        .font(.system(.title2, weight: .bold))
                        .foregroundColor(Color.onFill(BulkUpColors.complete))
                        .scaleEffect(showCheck ? 1.0 : 0.0)
                }

                // Poster
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    Text("Entreno completado")
                        .displayVoice(40, weight: .extraBold, relativeTo: .largeTitle)
                        .foregroundColor(BulkUpColors.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)

                    if summary.isPartialCompletion {
                        Text("\(summary.exercisesCompleted) de \(summary.exercisesTotal) ejercicios completados")
                            .font(BulkUpFont.numeric(.subheadline))
                            .foregroundColor(BulkUpColors.textSecondary)
                    }
                }
                .opacity(showCard ? 1 : 0)
                .offset(y: showCard ? 0 : 16)

                // The number that moved
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text(volumeString)
                        .font(BulkUpFont.heroStat())
                        .foregroundColor(BulkUpColors.textPrimary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                    Text(volumeSentence)
                        .font(.system(.title3, weight: .semibold))
                        .foregroundColor(volumeImproved ? BulkUpColors.accentText : BulkUpColors.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .opacity(showCard ? 1 : 0)
                .offset(y: showCard ? 0 : 24)

                // The rest of the evidence, one strip
                statsStrip
                    .opacity(showCard ? 1 : 0)
                    .offset(y: showCard ? 0 : 30)

                Spacer(minLength: Spacing.lg)

                // Actions
                VStack(spacing: Spacing.sm + 2) {
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
                    .frame(height: Spacing.lg)
            }
            .padding(.horizontal, Spacing.screenH)
        }
        .task { await loadPreviousSession() }
        .onAppear {
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
                showCheck = true
            }
            withAnimation(.spring(response: 0.5, dampingFraction: 0.85).delay(0.35)) {
                showCard = true
            }
        }
    }

    // MARK: - Volume

    private static let volumeFormatter: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.maximumFractionDigits = 0
        f.usesGroupingSeparator = true
        return f
    }()

    private func kilos(_ value: Double) -> String {
        let n = Self.volumeFormatter.string(from: NSNumber(value: value.rounded())) ?? "\(Int(value.rounded()))"
        return "\(n) kg"
    }

    private var volumeString: String { kilos(summary.totalVolume) }

    private var volumeImproved: Bool {
        guard let previous else { return false }
        return summary.totalVolume - previous.totalVolume >= 0.5
    }

    private var volumeSentence: String {
        guard let previous else {
            return NSLocalizedString("Volumen total · primera sesión de este día", comment: "")
        }
        let diff = summary.totalVolume - previous.totalVolume
        if abs(diff) < 0.5 {
            return NSLocalizedString("Mismo volumen que la última vez", comment: "")
        }
        if diff > 0 {
            return String(format: NSLocalizedString("+%@ más que la última vez", comment: "volume delta up"), kilos(diff))
        }
        return String(format: NSLocalizedString("%@ menos que la última vez", comment: "volume delta down"), kilos(-diff))
    }

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

    private func countDelta(_ value: Int) -> (text: String, up: Bool)? {
        guard previous != nil else { return nil }
        if value == 0 { return (NSLocalizedString("igual", comment: "same as last time"), false) }
        return (value > 0 ? "+\(value)" : "−\(abs(value))", value > 0)
    }

    private func durationDelta() -> (text: String, up: Bool)? {
        guard let previous else { return nil }
        let diff = summary.duration - previous.durationSeconds
        if abs(diff) < 30 { return (NSLocalizedString("igual", comment: "same as last time"), false) }
        let t = WorkoutSummary.format(seconds: abs(diff))
        if diff < 0 {
            return (String(format: NSLocalizedString("%@ más rápido", comment: "faster by"), t), true)
        }
        return (String(format: NSLocalizedString("%@ más lento", comment: "slower by"), t), false)
    }

    // MARK: - Stats strip

    private var statsStrip: some View {
        HStack(alignment: .top, spacing: 0) {
            statCell(value: summary.formattedDuration, label: "Duración", delta: durationDelta())
            stripDivider
            statCell(value: "\(summary.totalSets)", label: "Series",
                     delta: previous.map { countDelta(summary.totalSets - $0.totalSets) } ?? nil)
            stripDivider
            statCell(value: "\(summary.exercisesCompleted)", label: "Ejercicios",
                     delta: previous.map { countDelta(summary.exercisesCompleted - $0.exercisesCompleted) } ?? nil)
        }
        .padding(.vertical, Spacing.md)
        .padding(.horizontal, Spacing.md)
        .background(BulkUpColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.large, style: .continuous))
        .lift()
    }

    private var stripDivider: some View {
        Rectangle()
            .fill(BulkUpColors.line)
            .frame(width: 1, height: 44)
            .padding(.trailing, Spacing.md)
    }

    private func statCell(value: String, label: LocalizedStringKey, delta: (text: String, up: Bool)?) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(value)
                .font(BulkUpFont.mono(22, weight: .semibold, relativeTo: .title2))
                .foregroundColor(BulkUpColors.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(label)
                .font(BulkUpFont.caption())
                .foregroundColor(BulkUpColors.textSecondary)
            if let delta {
                Text(delta.text)
                    .font(BulkUpFont.numeric(.caption2, weight: .semibold))
                    .foregroundColor(delta.up ? BulkUpColors.accentText : BulkUpColors.textTertiary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
