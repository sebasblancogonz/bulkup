//
//  TagView.swift
//  bulkup
//
//  Created by sebastianblancogonz on 20/8/25.
//
import SwiftUI

struct TagView: View {
    let text: String
    let color: Color
    var icon: String? = nil
    /// Optional localized prefix label (e.g. "Nivel"). When set, the rendered
    /// text becomes the localized "<prefix>: <value>" with both parts localized live.
    var prefixKey: String? = nil

    private var label: Text {
        if let prefixKey = prefixKey {
            // Both the prefix and the value are raw catalog keys, localized live.
            return Text(LocalizedStringKey(prefixKey)) + Text(": ") + Text(LocalizedStringKey(text))
        }
        return Text(LocalizedStringKey(text))
    }

    var body: some View {
        HStack(spacing: Spacing.xs) {
            if let icon = icon {
                Image(systemName: icon)
                    .font(BulkUpFont.caption())
            }
            label
                .font(BulkUpFont.dataLabel())
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(color.opacity(0.15))
        .foregroundColor(color)
        .cornerRadius(CornerRadius.small)
    }
}
