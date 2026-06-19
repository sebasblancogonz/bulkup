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

    var body: some View {
        HStack(spacing: Spacing.xs) {
            if let icon = icon {
                Image(systemName: icon)
                    .font(BulkUpFont.caption())
            }
            Text(text)
                .font(BulkUpFont.dataLabel())
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(color.opacity(0.15))
        .foregroundColor(color)
        .cornerRadius(CornerRadius.small)
    }
}
