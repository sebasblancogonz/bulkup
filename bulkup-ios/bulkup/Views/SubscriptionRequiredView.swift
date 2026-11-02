//
//  SubscriptionRequiredView.swift
//  bulkup
//
//  PRO gate shown in place of a locked screen (full) or inline above locked
//  content (compact). Lists only what is actually locked.
//

import SwiftUI

struct SubscriptionRequiredView: View {
    let onSubscribe: () -> Void
    var title: LocalizedStringKey = "Función PRO"
    var subtitle: LocalizedStringKey = "Tu plan, tus medidas y tus récords, en un sitio donde se ve si avanzas."
    var features: [LocalizedStringKey] = [
        "Importación con IA (PDF y fotos)",
        "Planes ilimitados",
        "Progreso, medidas y composición",
        "Récords personales (RM)",
        "Compartir e importar planes",
        "Recetas con IA y fidelidad de dieta",
    ]
    var compact: Bool = false

    var body: some View {
        if compact {
            compactContent
        } else {
            fullContent
        }
    }

    private var fullContent: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            Spacer(minLength: 0)

            Text(title)
                .displayVoice(36, weight: .extraBold, relativeTo: .largeTitle)
                .foregroundColor(BulkUpColors.textPrimary)
                .fixedSize(horizontal: false, vertical: true)

            Text(subtitle)
                .font(BulkUpFont.body())
                .foregroundColor(BulkUpColors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)

            VStack(alignment: .leading, spacing: 0) {
                ForEach(features.indices, id: \.self) { index in
                    FeatureRow(icon: "checkmark", text: features[index], color: BulkUpColors.accentText)
                        .padding(.vertical, Spacing.sm + 2)
                        .overlay(alignment: .bottom) {
                            if index < features.count - 1 {
                                Rectangle().fill(BulkUpColors.line).frame(height: 1)
                            }
                        }
                }
            }

            Button(action: onSubscribe) {
                Text("Desbloquear PRO")
                    .primaryButtonStyle()
            }
            .pressable()

            Text("Cancela cuando quieras desde el App Store.")
                .font(.system(.caption2))
                .foregroundColor(BulkUpColors.textSecondary)

            Spacer(minLength: 0)
        }
        .padding(.horizontal, Spacing.screenH)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    }

    private var compactContent: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack(alignment: .top, spacing: Spacing.md) {
                Image(systemName: "lock.fill")
                    .font(.system(.body, weight: .semibold))
                    .foregroundColor(BulkUpColors.accentText)
                    .frame(width: 24)
                    .padding(.top, 2)

                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(BulkUpFont.cardTitle())
                        .foregroundColor(BulkUpColors.textPrimary)
                    Text(subtitle)
                        .font(BulkUpFont.caption())
                        .foregroundColor(BulkUpColors.textSecondary)
                        .lineLimit(3)
                }
                Spacer(minLength: 0)
            }

            Button(action: onSubscribe) {
                Text("Desbloquear PRO")
                    .primaryButtonStyle()
            }
            .pressable()
        }
        .padding(Spacing.md)
        .background(BulkUpColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.large, style: .continuous))
        .hairline(color: BulkUpColors.accent.opacity(0.5))
    }
}

// MARK: - Premium Overlay Modifier
struct PremiumOverlayModifier: ViewModifier {
    let isSubscribed: Bool
    let onSubscribe: () -> Void
    var title: LocalizedStringKey = "Función PRO"
    var subtitle: LocalizedStringKey = "Esta función requiere una suscripción PRO"

    func body(content: Content) -> some View {
        content
            .overlay(
                Group {
                    if !isSubscribed {
                        ZStack {
                            BulkUpColors.background.opacity(0.92)
                            SubscriptionRequiredView(
                                onSubscribe: onSubscribe,
                                title: title,
                                subtitle: subtitle,
                                compact: false
                            )
                        }
                    }
                }
            )
    }
}

extension View {
    func premiumOverlay(
        isSubscribed: Bool,
        title: LocalizedStringKey = "Función PRO",
        subtitle: LocalizedStringKey = "Esta función requiere una suscripción PRO",
        onSubscribe: @escaping () -> Void
    ) -> some View {
        modifier(PremiumOverlayModifier(
            isSubscribed: isSubscribed,
            onSubscribe: onSubscribe,
            title: title,
            subtitle: subtitle
        ))
    }
}

struct FeatureRow: View {
    let icon: String
    let text: LocalizedStringKey
    let color: Color

    var body: some View {
        HStack(spacing: Spacing.md) {
            Image(systemName: icon)
                .font(.system(.footnote, weight: .bold))
                .foregroundColor(color)
                .frame(width: 24)

            Text(text)
                .font(BulkUpFont.body())
                .foregroundColor(BulkUpColors.textPrimary)

            Spacer(minLength: 0)
        }
    }
}
