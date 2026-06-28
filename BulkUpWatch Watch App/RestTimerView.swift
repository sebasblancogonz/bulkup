import SwiftUI
import WatchKit

struct RestTimerView: View {
    @EnvironmentObject var wc: WatchWCManager
    let end: Date
    @State private var firedHaptic = false
    private let lime = Color(red: 0.518, green: 0.800, blue: 0.086)

    var body: some View {
        VStack(spacing: 10) {
            Text("REST").font(.caption2).tracking(1.5).foregroundStyle(.secondary)
            // Wall-clock countdown; survives backgrounding because it's derived from `end`.
            Text(timerInterval: Date()...end, countsDown: true)
                .font(.system(size: 30, weight: .bold, design: .rounded)).monospacedDigit()
                .foregroundStyle(lime)
            HStack {
                Button("Skip") { wc.skipRest() }.buttonStyle(.bordered)
                Button("+30s") { wc.addRest(30) }.buttonStyle(.bordered)
            }
        }
        .padding()
        .onAppear { scheduleHaptic() }
    }

    private func scheduleHaptic() {
        guard !firedHaptic else { return }
        let remaining = end.timeIntervalSinceNow
        guard remaining > 0 else { WKInterfaceDevice.current().play(.notification); firedHaptic = true; return }
        DispatchQueue.main.asyncAfter(deadline: .now() + remaining) {
            // Only fire if rest hasn't been skipped/extended away from this end.
            if !firedHaptic && abs(Date().timeIntervalSince(end)) < 1.5 {
                WKInterfaceDevice.current().play(.notification)
                firedHaptic = true
            }
        }
    }
}
