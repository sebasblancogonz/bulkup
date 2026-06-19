//
//  BulkUpWidgetsLiveActivity.swift
//  BulkUpWidgets
//
//  Created by sebastian.blanco on 19/6/26.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct BulkUpWidgetsAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic stateful properties about your activity go here!
        var emoji: String
    }

    // Fixed non-changing properties about your activity go here!
    var name: String
}

struct BulkUpWidgetsLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: BulkUpWidgetsAttributes.self) { context in
            // Lock screen/banner UI goes here
            VStack {
                Text("Hello \(context.state.emoji)")
            }
            .activityBackgroundTint(Color.cyan)
            .activitySystemActionForegroundColor(Color.black)

        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded UI goes here.  Compose the expanded UI through
                // various regions, like leading/trailing/center/bottom
                DynamicIslandExpandedRegion(.leading) {
                    Text("Leading")
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text("Trailing")
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text("Bottom \(context.state.emoji)")
                    // more content
                }
            } compactLeading: {
                Text("L")
            } compactTrailing: {
                Text("T \(context.state.emoji)")
            } minimal: {
                Text(context.state.emoji)
            }
            .widgetURL(URL(string: "http://www.apple.com"))
            .keylineTint(Color.red)
        }
    }
}

extension BulkUpWidgetsAttributes {
    fileprivate static var preview: BulkUpWidgetsAttributes {
        BulkUpWidgetsAttributes(name: "World")
    }
}

extension BulkUpWidgetsAttributes.ContentState {
    fileprivate static var smiley: BulkUpWidgetsAttributes.ContentState {
        BulkUpWidgetsAttributes.ContentState(emoji: "😀")
     }
     
     fileprivate static var starEyes: BulkUpWidgetsAttributes.ContentState {
         BulkUpWidgetsAttributes.ContentState(emoji: "🤩")
     }
}

#Preview("Notification", as: .content, using: BulkUpWidgetsAttributes.preview) {
   BulkUpWidgetsLiveActivity()
} contentStates: {
    BulkUpWidgetsAttributes.ContentState.smiley
    BulkUpWidgetsAttributes.ContentState.starEyes
}
