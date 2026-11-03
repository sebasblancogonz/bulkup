import ActivityKit
import AppIntents
import SwiftUI
import WidgetKit

struct WorkoutLiveActivity: Widget {
    init() { BrandFonts.register() }

    var body: some WidgetConfiguration {
        ActivityConfiguration(for: WorkoutActivityAttributes.self) { context in
            WorkoutActivityCard(state: context.state)
                .activityBackgroundTint(Brand.ground)
                .activitySystemActionForegroundColor(Brand.lime)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) { IslandLeading(state: context.state) }
                DynamicIslandExpandedRegion(.trailing) { IslandTrailing(state: context.state) }
                DynamicIslandExpandedRegion(.bottom) { IslandBottom(state: context.state) }
            } compactLeading: {
                // The app's session dot, at rest.
                Circle().fill(context.state.isFinished ? Brand.sky : Brand.lime)
                    .frame(width: 8, height: 8).padding(.leading, 4)
            } compactTrailing: {
                IslandCompactTrailing(state: context.state)
            } minimal: {
                Circle().fill(context.state.isFinished ? Brand.sky : Brand.lime)
                    .frame(width: 10, height: 10)
            }
            .keylineTint(Brand.lime)
        }
    }
}
