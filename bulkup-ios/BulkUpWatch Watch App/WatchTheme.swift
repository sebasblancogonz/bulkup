//
//  WatchTheme.swift
//  BulkUpWatch Watch App
//
//  Watch-only component grammar on top of the shared `Brand` palette: the
//  lifted slab, the lime CTA, the raised stepper square. Black ground by
//  platform convention; everything else is Graphite & Voltage.
//

import SwiftUI

/// One lifted graphite slab holding rows separated by 1pt lines.
struct WatchSlab<Content: View>: View {
    @ViewBuilder var content: Content
    var body: some View {
        VStack(spacing: 0) { content }
            .background(Brand.surface, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            .brandLift(12)
    }
}

struct WatchSeparator: View {
    var body: some View {
        Rectangle().fill(Brand.line).frame(height: 1).padding(.leading, 10)
    }
}

/// The primary action: a 44pt lime slab, graphite label, sentence case.
struct WatchPrimaryButton: View {
    let title: LocalizedStringKey
    var enabled: Bool = true
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.headline)
                .foregroundStyle(enabled ? Brand.onLime : Brand.textSecondary)
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .background(enabled ? Brand.lime : Brand.raised,
                            in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
    }
}

/// Secondary actions: raised slab, or the outline when it sits next to a raised one.
struct WatchSecondaryButton: View {
    enum Style { case raised, outline }
    let title: LocalizedStringKey
    var style: Style = .raised
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.headline)
                .foregroundStyle(style == .outline ? Brand.lime : Brand.textPrimary)
                .frame(maxWidth: .infinity)
                .frame(height: 40)
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

/// A 40×44 raised square with a bare SF glyph: the stepper.
struct WatchStepButton: View {
    let symbol: String
    var height: CGFloat = 44
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(Brand.textPrimary)
                .frame(width: 40, height: height)
                .background(Brand.raised, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

/// Kilos or reps: raised field with the value in JetBrains Mono and the unit
/// beneath, a stepper square on each side.
struct WatchValueField: View {
    let value: String
    let unit: LocalizedStringKey
    var size: CGFloat = 22
    var height: CGFloat = 44
    let minus: () -> Void
    let plus: () -> Void

    var body: some View {
        HStack(spacing: 6) {
            WatchStepButton(symbol: "minus", height: height, action: minus)
            VStack(spacing: 0) {
                Text(value)
                    .font(.brandMono(size))
                    .foregroundStyle(Brand.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                Text(unit)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(Brand.textSecondary)
            }
            .frame(maxWidth: .infinity)
            .frame(height: height)
            .background(Brand.raised, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            WatchStepButton(symbol: "plus", height: height, action: plus)
        }
    }
}

/// 22pt square check: sky with a graphite tick when done, a tertiary stroke otherwise.
struct WatchCheck: View {
    let done: Bool
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(done ? Brand.sky : Color.clear)
            if done {
                Image(systemName: "checkmark")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(Brand.onLime)
            } else {
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .strokeBorder(Brand.textTertiary.opacity(0.6), lineWidth: 1.5)
            }
        }
        .frame(width: 22, height: 22)
    }
}

/// The session clock: lime dot and elapsed time in tabular SF (12pt sits
/// under the mono floor).
struct WatchElapsed: View {
    let start: Date
    var body: some View {
        HStack(spacing: 5) {
            Circle().fill(Brand.lime).frame(width: 6, height: 6)
            Text(timerInterval: min(start, Date())...Date.distantFuture, countsDown: false)
                .font(.footnote.monospacedDigit())
                .foregroundStyle(Brand.textSecondary)
        }
    }
}
