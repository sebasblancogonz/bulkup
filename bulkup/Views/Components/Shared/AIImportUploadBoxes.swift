//  AIImportUploadBoxes.swift
//  Reusable dashed PDF + Image upload boxes for AI plan import (diet + training).

import SwiftUI

struct AIImportUploadBoxes: View {
    let tint: Color
    let onPickPDF: () -> Void
    let onPickImage: () -> Void
    var disabled: Bool = false

    var body: some View {
        HStack(spacing: Spacing.md) {
            box(title: "Subir PDF", subtitle: "Archivo PDF", icon: "arrow.up.doc.fill", action: onPickPDF)
            box(title: "Subir Imagen", subtitle: "Foto de tu plan", icon: "photo.on.rectangle", action: onPickImage)
        }
    }

    private func box(title: LocalizedStringKey, subtitle: LocalizedStringKey, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            ZStack {
                RoundedRectangle(cornerRadius: CornerRadius.large)
                    .strokeBorder(style: StrokeStyle(lineWidth: 2, dash: [8]))
                    .foregroundColor(tint.opacity(0.4))
                    .frame(height: 160)
                    .background(
                        RoundedRectangle(cornerRadius: CornerRadius.large)
                            .fill(BulkUpColors.surfaceElevated)
                    )
                VStack(spacing: Spacing.sm) {
                    Image(systemName: icon)
                        .font(.system(size: 28))
                        .foregroundColor(tint)
                    Text(title)
                        .font(BulkUpFont.cardTitle())
                        .foregroundColor(BulkUpColors.textPrimary)
                    Text(subtitle)
                        .font(BulkUpFont.caption())
                        .foregroundColor(BulkUpColors.textSecondary)
                }
            }
        }
        .buttonStyle(.plain)
        .disabled(disabled)
        .opacity(disabled ? 0.5 : 1)
    }
}
