//
//  Item.swift
//  bulkup
//
//  Created by sebastianblancogonz on 17/8/25.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
