import SwiftUI
import WatchKit

struct RestTimerView: View {
    @EnvironmentObject var wc: WatchWCManager
    let end: Date
    @State private var firedHaptic = false

    var body: some View {
        VStack(spacing: 12) {
            Text("REST").font(.caption2).fontWeight(.semibold).tracking(2)
                .foregroundStyle(Color.lime)
            // Wall-clock countdown; survives backgrounding because it's derived from `end`.
            Text(timerInterval: Date()...end, countsDown: true)
                .font(.system(size: 34, weight: .bold, design: .rounded)).monospacedDigit()
                .foregroundStyle(.white)
            HStack(spacing: 8) {
                Button("Skip") { wc.skipRest() }.buttonStyle(.bordered)
                Button("+30s") { wc.addRest(30) }.buttonStyle(.bordered).tint(Color.lime)
            }
        }
        .padding()
        .onAppear { scheduleHaptic() }
    }

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
