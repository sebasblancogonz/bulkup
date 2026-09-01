//
//  RootView.swift
//  BulkUpWatch Watch App
//

import SwiftUI

struct RootView: View {
    @EnvironmentObject var wc: WatchWCManager
    var body: some View {
        if let live = wc.live, !live.isFinished {
            ActiveWorkoutView(live: live)
        } else if wc.ctx?.todaysPlan?.exercises.isEmpty == false || wc.ctx?.meals?.isEmpty == false {
            // Rest days with meals still get the meal list.
            TodayView(plan: wc.ctx?.todaysPlan, meals: wc.ctx?.meals ?? [])
        } else {
            VStack(spacing: 10) {
                Image(systemName: "dumbbell.fill").font(.title2).foregroundStyle(Color.lime)
                Text("Open BulkUp on your iPhone")
                    .font(.footnote).multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
            }.padding()
        }
    }
}
