//
//  WorkoutActivityViews.swift
//  bulkup
//
//  The Live Activity's views: the set table's active row lifted out of the
//  app and dropped on the bench. Shared between the widget extension (which
//  presents them) and the app (which renders them in the DEBUG design-preview
//  harness, since the simulator's lock screen cannot be driven from a script).
//
//  Graphite slab in both appearances, the exercise in SF headline, kilos and
//  reps as two raised mono fields with bare −/+ glyphs, one lime CTA, a 3pt
//  lime rule along the bottom edge for progress. Resting: the countdown in
//  mono 34, a draining system progress bar, outline "Saltar" and raised
//  "+30 s". Finished: a sky square check.
//

import AppIntents
import SwiftUI

// MARK: - Lock screen card

/// The lock-screen card exactly as the widget presents it: content, padding,
/// ground and the progress rule. The widget wraps this in `ActivityConfiguration`.
struct WorkoutActivityCard: View {
    let state: WorkoutActivityAttributes.ContentState

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            WorkoutLockScreenView(state: state)
            // While resting the draining bar is the live rule; two lime rules would compete.
            if !state.isResting || state.isFinished {
                ActivityProgressRule(state: state)
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .padding(.bottom, 8)
        .background(
            LinearGradient(stops: [
                .init(color: Brand.glow, location: 0),
                .init(color: Brand.ground, location: 0.6),
            ], startPoint: .top, endPoint: .bottom)
        )
    }
}

struct WorkoutLockScreenView: View {
    let state: WorkoutActivityAttributes.ContentState

    var body: some View {
        Group {
            if state.isFinished {
                finished
            } else if state.isResting, let end = state.restEndDate {
                resting(end: end)
            } else {
                working
            }
        }
        .tint(Brand.lime)
    }

    // MARK: Mid-set
    private var working: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(state.exerciseName)
                        .font(.headline)
                        .foregroundStyle(Brand.textPrimary)
                        .lineLimit(1)
                    Text("Serie \(state.setIndex + 1) de \(state.setsTotal) · \(state.workoutName)")
                        .font(.footnote.monospacedDigit())
                        .foregroundStyle(Brand.textSecondary)
                        .lineLimit(1)
                }
                Spacer(minLength: 8)
                VStack(alignment: .trailing, spacing: 2) {
                    ElapsedTimer(start: state.startDate, size: 17)
                    Text("\(state.completedSets)/\(state.totalSets) series")
                        .font(.footnote.monospacedDigit())
                        .foregroundStyle(Brand.textSecondary)
                }
                .fixedSize()
            }

            HStack(spacing: 10) {
                ValueField(value: BrandFormat.weight(state.weight), unit: state.weightUnit,
                           minus: AdjustWeightIntent(delta: -weightStep),
                           plus: AdjustWeightIntent(delta: weightStep))
                ValueField(value: "\(state.reps)", unit: String(localized: "reps"),
                           minus: AdjustRepsIntent(delta: -1),
                           plus: AdjustRepsIntent(delta: 1))
            }

            CompleteSetButton(needsWeight: state.needsWeight)
        }
    }

    private var weightStep: Double { state.weightUnit == "lb" ? 5.0 : 2.5 }

    // MARK: Resting
    private func resting(end: Date) -> some View {
        // Single `now` + clamp: the widget can re-render after `end` has passed
        // (isResting was computed at the last activity update) and a reversed
        // range in Text(timerInterval:) is a runtime crash.
        let now = Date()
        let clampedEnd = max(end, now)
        let start = min(state.restStartDate ?? now, now)
        return VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Descanso")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Brand.textSecondary)
                    Text(state.exerciseName)
                        .font(.footnote)
                        .foregroundStyle(Brand.textSecondary)
                        .lineLimit(1)
                    Text("Serie \(state.setIndex + 1) · \(BrandFormat.weight(state.weight)) \(state.weightUnit) × \(state.reps)")
                        .font(.footnote.monospacedDigit())
                        .foregroundStyle(Brand.textPrimary)
                        .lineLimit(1)
                }
                Spacer(minLength: 8)
                Text(timerInterval: now...clampedEnd, countsDown: true)
                    .font(.brandMono(32))
                    .foregroundStyle(Brand.textPrimary)
                    .multilineTextAlignment(.trailing)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                    .frame(maxWidth: 104, alignment: .trailing)
            }
            ProgressView(timerInterval: start...clampedEnd, countsDown: true,
                         label: { EmptyView() }, currentValueLabel: { EmptyView() })
                .progressViewStyle(.linear)
                .tint(Brand.lime)
            HStack(spacing: 10) {
                RestButton(title: "Saltar", style: .outline, intent: SkipRestIntent())
                RestButton(title: "+30 s", style: .raised, intent: AddRestIntent(seconds: 30))
            }
        }
    }

    // MARK: Finished
    private var finished: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 8, style: .continuous).fill(Brand.sky)
                Image(systemName: "checkmark")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(Brand.onLime)
            }
            .frame(width: 32, height: 32)
            VStack(alignment: .leading, spacing: 2) {
                Text("Entreno completado")
                    .font(.headline)
                    .foregroundStyle(Brand.textPrimary)
                Text("\(state.totalSets) series · \(state.workoutName)")
                    .font(.footnote.monospacedDigit())
                    .foregroundStyle(Brand.textSecondary)
                    .lineLimit(1)
            }
            Spacer(minLength: 8)
            // Frozen total: the finished content renders once and ends 4 s later.
            HStack(spacing: 6) {
                Circle().fill(Brand.sky).frame(width: 6, height: 6)
                Text(Duration.seconds(max(0, Date().timeIntervalSince(state.startDate))),
                     format: .time(pattern: Date().timeIntervalSince(state.startDate) >= 3600 ? .hourMinuteSecond : .minuteSecond))
                    .font(.brandMono(17))
                    .foregroundStyle(Brand.textPrimary)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Pieces

/// The session clock: a lime dot (the app's pulsing session dot, at rest here)
/// and the elapsed time in JetBrains Mono.
struct ElapsedTimer: View {
    let start: Date
    var size: CGFloat = 17
    var live: Bool = true

    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(live ? Brand.lime : Brand.sky)
                .frame(width: 6, height: 6)
            // Clamp: a start later than this clock (phone→widget skew) would reverse the range and crash.
            Text(timerInterval: min(start, Date())...Date.distantFuture, countsDown: false)
                .font(.brandMono(size))
                .foregroundStyle(Brand.textPrimary)
                .multilineTextAlignment(.trailing)
                .lineLimit(1)
        }
    }
}

/// A raised field with bare −/+ glyphs as 36pt targets and the value in mono.
struct ValueField<Minus: AppIntent, Plus: AppIntent>: View {
    let value: String
    let unit: String
    let minus: Minus
    let plus: Plus

    var body: some View {
        HStack(spacing: 0) {
            StepButton(symbol: "minus", intent: minus)
            HStack(alignment: .firstTextBaseline, spacing: 3) {
                Text(value)
                    .font(.brandMono(17))
                    .foregroundStyle(Brand.textPrimary)
                Text(unit)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(Brand.textSecondary)
            }
            .lineLimit(1)
            .minimumScaleFactor(0.7)
            .frame(maxWidth: .infinity)
            StepButton(symbol: "plus", intent: plus)
        }
        .frame(height: 34)
        .background(Brand.raised, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

struct StepButton<I: AppIntent>: View {
    let symbol: String
    let intent: I

    var body: some View {
        Button(intent: intent) {
            Image(systemName: symbol)
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(Brand.textSecondary)
                .frame(width: 36, height: 34)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

/// The one lime object on the card. Dims to a raised slab while the set has no
/// kilos (the intent refuses 0-weight completions too; this makes it visible).
struct CompleteSetButton: View {
    let needsWeight: Bool
    var height: CGFloat = 44

    var body: some View {
        Button(intent: CompleteCurrentSetIntent()) {
            Text(needsWeight ? "Ajusta el peso" : "Completar serie")
                .font(.headline)
                .foregroundStyle(needsWeight ? Brand.textSecondary : Brand.onLime)
                .frame(maxWidth: .infinity)
                .frame(height: height)
                .background(needsWeight ? Brand.raised : Brand.lime,
                            in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .buttonStyle(.plain)
        .disabled(needsWeight)
    }
}

struct RestButton<I: AppIntent>: View {
    enum Style { case outline, raised }
    let title: LocalizedStringKey
    let style: Style
    let intent: I
    var height: CGFloat = 40

    var body: some View {
        Button(intent: intent) {
            Text(title)
                .font(.headline)
                .foregroundStyle(style == .outline ? Brand.lime : Brand.textPrimary)
                .frame(maxWidth: .infinity)
                .frame(height: height)
                .background(style == .raised ? Brand.raised : Color.clear,
                            in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay {
                    if style == .outline {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .strokeBorder(Brand.lime.opacity(0.6), lineWidth: 1)
                    }
                }
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

/// 3pt session-progress rule under the controls: lime while the session runs, sky once done.
struct ActivityProgressRule: View {
    let state: WorkoutActivityAttributes.ContentState

    var body: some View {
        GeometryReader { geo in
            let fraction = state.totalSets > 0 ? Double(state.completedSets) / Double(state.totalSets) : 0
            ZStack(alignment: .leading) {
                Capsule().fill(Brand.line)
                Capsule()
                    .fill(state.isFinished ? Brand.sky : Brand.lime)
                    .frame(width: max(0, geo.size.width * (state.isFinished ? 1 : fraction)))
            }
        }
        .frame(height: 3)
    }
}

// MARK: - Dynamic Island pieces

struct IslandLeading: View {
    let state: WorkoutActivityAttributes.ContentState
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            if state.isFinished {
                Text("Entreno completado").font(.headline).foregroundStyle(Brand.textPrimary)
            } else if state.isResting {
                Text("Descanso").font(.subheadline.weight(.semibold)).foregroundStyle(Brand.textSecondary)
                Text("Siguiente · Serie \(state.setIndex + 1)")
                    .font(.footnote.monospacedDigit()).foregroundStyle(Brand.textSecondary)
            } else {
                Text(state.exerciseName).font(.headline).foregroundStyle(Brand.textPrimary).lineLimit(1)
                Text("Serie \(state.setIndex + 1) de \(state.setsTotal)")
                    .font(.footnote.monospacedDigit()).foregroundStyle(Brand.textSecondary)
            }
        }
        .padding(.leading, 4)
    }
}

struct IslandTrailing: View {
    let state: WorkoutActivityAttributes.ContentState
    var body: some View {
        VStack(alignment: .trailing, spacing: 2) {
            ElapsedTimer(start: state.startDate, size: 17, live: !state.isFinished)
            Text("\(state.completedSets)/\(state.totalSets) series")
                .font(.footnote.monospacedDigit()).foregroundStyle(Brand.textSecondary)
        }
        .padding(.trailing, 4)
    }
}

struct IslandBottom: View {
    let state: WorkoutActivityAttributes.ContentState
    private var weightStep: Double { state.weightUnit == "lb" ? 5.0 : 2.5 }

    var body: some View {
        Group {
            if state.isFinished {
                EmptyView()
            } else if state.isResting, let end = state.restEndDate {
                let now = Date()
                let clampedEnd = max(end, now)
                let start = min(state.restStartDate ?? now, now)
                HStack(spacing: 10) {
                    Text(timerInterval: now...clampedEnd, countsDown: true)
                        .font(.brandMono(28)).foregroundStyle(Brand.textPrimary)
                        .lineLimit(1).minimumScaleFactor(0.6)
                        .frame(width: 92, alignment: .leading)
                    RestButton(title: "Saltar", style: .outline, intent: SkipRestIntent())
                    RestButton(title: "+30 s", style: .raised, intent: AddRestIntent(seconds: 30))
                }
                .overlay(alignment: .top) {
                    ProgressView(timerInterval: start...clampedEnd, countsDown: true,
                                 label: { EmptyView() }, currentValueLabel: { EmptyView() })
                        .progressViewStyle(.linear)
                        .tint(Brand.lime)
                        .offset(y: -10)
                }
                .padding(.top, 8)
            } else {
                VStack(spacing: 8) {
                    HStack(spacing: 10) {
                        ValueField(value: BrandFormat.weight(state.weight), unit: state.weightUnit,
                                   minus: AdjustWeightIntent(delta: -weightStep),
                                   plus: AdjustWeightIntent(delta: weightStep))
                        ValueField(value: "\(state.reps)", unit: String(localized: "reps"),
                                   minus: AdjustRepsIntent(delta: -1),
                                   plus: AdjustRepsIntent(delta: 1))
                    }
                    CompleteSetButton(needsWeight: state.needsWeight)
                }
                .padding(.top, 6)
            }
        }
        .padding(.horizontal, 4)
    }
}

/// Compact trailing: the live number. The rest countdown in lime while it runs,
/// otherwise the set count.
struct IslandCompactTrailing: View {
    let state: WorkoutActivityAttributes.ContentState
    var body: some View {
        if state.isResting, let end = state.restEndDate {
            let now = Date()
            Text(timerInterval: now...max(end, now), countsDown: true)
                .font(.system(size: 13, weight: .semibold).monospacedDigit())
                .foregroundStyle(Brand.lime)
                .frame(maxWidth: 44)
                .multilineTextAlignment(.trailing)
        } else {
            Text("\(state.completedSets)/\(state.totalSets)")
                .font(.system(size: 13, weight: .semibold).monospacedDigit())
                .foregroundStyle(Brand.textPrimary)
        }
    }
}
