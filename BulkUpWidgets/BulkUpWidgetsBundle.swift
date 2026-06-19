//
//  BulkUpWidgetsBundle.swift
//  BulkUpWidgets
//
//  Created by sebastian.blanco on 19/6/26.
//

import WidgetKit
import SwiftUI

@main
struct BulkUpWidgetsBundle: WidgetBundle {
    var body: some Widget {
        BulkUpWidgets()
        BulkUpWidgetsControl()
        BulkUpWidgetsLiveActivity()
    }
}
