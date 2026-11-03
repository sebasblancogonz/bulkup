import SwiftUI
import WatchKit

/// The rest: the countdown in JetBrains Mono, a draining lime rule, the next
/// set in one tabular line, then "Saltar" and "+30 s".
struct RestTimerView: View {
    @EnvironmentObject var wc: WatchWCManager
    let end: Date
    var start: Date? = nil
    var next: LiveWorkout.LiveSet? = nil
    var unit: String = "kg"
    @State private var firedHaptic = false

    var body: some View {
        // Single `now` + clamp: the body can re-render after `end` has passed
        // (RootView's `restEnd > Date()` guard ran earlier), and a reversed
        // range in Text(timerInterval:) is a runtime crash.
        let now = Date()
        let clampedEnd = max(end, now)
        let clampedStart = min(start ?? now, now)
        VStack(spacing: 8) {
            Text("Descanso")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Brand.textSecondary)
            // Wall-clock countdown; survives backgrounding because it's derived from `end`.
            Text(timerInterval: now...clampedEnd, countsDown: true)
                .font(.brandMono(40))
                .foregroundStyle(Brand.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            WatchRestRule(start: clampedStart, end: clampedEnd)
            if let next {
                Text("Serie \(next.setIndex + 1) · \(BrandFormat.weight(next.weight)) \(unit) × \(next.reps)")
                    .font(.caption2.monospacedDigit())
                    .foregroundStyle(Brand.textSecondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            HStack(spacing: 8) {
                WatchSecondaryButton(title: "Saltar", style: .outline) { wc.skipRest() }
                WatchSecondaryButton(title: "+30 s", style: .raised) { wc.addRest(30) }
            }
            .padding(.top, 2)
        }
        .padding(.horizontal, 2)
        .onAppear { scheduleHaptic() }
    }

}

/// 4pt rule that drains lime over the rest, on the brand's line track. The
/// app can run a timeline, so it does not need the tinted system bar.
struct WatchRestRule: View {
    let start: Date
    let end: Date

    var body: some View {
        TimelineView(.periodic(from: start, by: 0.5)) { context in
            let total = max(end.timeIntervalSince(start), 1)
            let remaining = max(0, min(total, end.timeIntervalSince(context.date)))
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Brand.line)
                    Capsule().fill(Brand.lime).frame(width: geo.size.width * remaining / total)
                }
            }
            .frame(height: 4)
        }
    }
}

extension RestTimerView {
    private func scheduleHaptic() {
        guard !firedHaptic else { return }
        let remaining = end.timeIntervalSinceNow
        guard remaining > 0 else { WKInterfaceDevice.current().play(.notification); firedHaptic = true; return }
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(remaining))
            // Only fire if rest hasn't been skipped/extended away from this end.
            if !firedHaptic && abs(Date().timeIntervalSince(end)) < 1.5 {
                WKInterfaceDevice.current().play(.notification)
                firedHaptic = true
            }
        }
    }
}
