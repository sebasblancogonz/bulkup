//
//  SubscriptionRequiredView.swift
//  bulkup
//
//  Created by sebastianblancogonz on 21/8/25.
//
import SwiftUI

struct SubscriptionRequiredView: View {
    let onSubscribe: () -> Void
    var title: LocalizedStringKey = "Funcion Premium"
    var subtitle: LocalizedStringKey = "Desbloquea el poder de subir y gestionar tus planes personalizados de entrenamiento y dieta"
    var features: [LocalizedStringKey] = [
        "Planes ilimitados",
        "Importacion con IA (PDF y fotos)",
        "Dashboard de progreso completo",
        "Records personales (RM)",
        "Medidas corporales y composicion",
        "Ranking con amigos",
        "Compartir e importar planes"
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
        VStack(spacing: Spacing.xxl) {
            Spacer()

            VStack(spacing: Spacing.lg) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [BulkUpColors.accent.opacity(0.2), BulkUpColors.accent.opacity(0.05)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 120, height: 120)

                    Image(systemName: "crown.fill")
                        .font(.system(size: 60))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [BulkUpColors.accent, BulkUpColors.accent.opacity(0.7)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
                .shadow(color: BulkUpColors.accent.opacity(0.2), radius: 20, x: 0, y: 10)
            }

            VStack(spacing: Spacing.lg) {
                Text(title)
                    .font(.title.weight(.bold))
                    .foregroundColor(BulkUpColors.textPrimary)

                Text(subtitle)
                    .font(BulkUpFont.body())
                    .foregroundColor(BulkUpColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            VStack(spacing: Spacing.lg) {
                // Beneficios
                VStack(alignment: .leading, spacing: Spacing.md) {
                    ForEach(features.indices, id: \.self) { index in
                        FeatureRow(icon: "checkmark.circle.fill", text: features[index], color: BulkUpColors.accent)
                    }
                }
                .padding(.horizontal, 40)
            }

            Spacer()

            VStack(spacing: Spacing.md) {
                Button(action: onSubscribe) {
                    HStack(spacing: Spacing.md) {
                        Image(systemName: "crown.fill")
                        Text("Desbloquear PRO")
                            .fontWeight(.semibold)
                    }
                }
                .primaryButtonStyle(color: BulkUpColors.accent)
                .padding(.horizontal, 32)

                Text("Cancela en cualquier momento")
                    .font(BulkUpFont.caption())
                    .foregroundColor(BulkUpColors.textSecondary)
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var compactContent: some View {
        VStack(spacing: Spacing.lg) {
            HStack(spacing: Spacing.md) {
                Image(systemName: "crown.fill")
                    .font(BulkUpFont.sectionHeader())
                    .foregroundStyle(
                        LinearGradient(
                            colors: [BulkUpColors.accent, BulkUpColors.accent.opacity(0.7)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text(title)
                        .font(BulkUpFont.cardTitle())
                        .fontWeight(.bold)
                        .foregroundColor(BulkUpColors.textPrimary)

                    Text(subtitle)
                        .font(BulkUpFont.caption())
                        .foregroundColor(BulkUpColors.textSecondary)
                        .lineLimit(2)
                }

                Spacer()
            }

            Button(action: onSubscribe) {
                HStack(spacing: Spacing.sm) {
                    Image(systemName: "lock.open.fill")
                        .font(BulkUpFont.caption())
                    Text("Desbloquear PRO")
                        .font(BulkUpFont.body())
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .background(
                    LinearGradient(
                        colors: [BulkUpColors.accent, BulkUpColors.accent.opacity(0.8)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .foregroundColor(.white)
                .cornerRadius(CornerRadius.medium)
            }
        }
        .padding(Spacing.lg)
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.large)
                .fill(BulkUpColors.accent.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: CornerRadius.large)
                        .stroke(BulkUpColors.accent.opacity(0.2), lineWidth: 1)
                )
        )
    }
}

// MARK: - Premium Overlay Modifier
struct PremiumOverlayModifier: ViewModifier {
    let isSubscribed: Bool
    let onSubscribe: () -> Void
    var title: LocalizedStringKey = "Funcion Premium"
    var subtitle: LocalizedStringKey = "Esta funcion requiere una suscripcion PRO"

    func body(content: Content) -> some View {
        content
            .overlay(
                Group {
                    if !isSubscribed {
                        ZStack {
                            // Blurred background
                            BulkUpColors.background
                                .opacity(0.85)

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
        title: LocalizedStringKey = "Funcion Premium",
        subtitle: LocalizedStringKey = "Esta funcion requiere una suscripcion PRO",
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
                .foregroundColor(color)
                .font(BulkUpFont.sectionHeader())

            Text(text)
                .font(BulkUpFont.body())
                .foregroundColor(BulkUpColors.textPrimary)

            Spacer()
        }
    }
}
