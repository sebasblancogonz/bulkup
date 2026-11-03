//
//  MyFriendCodeView.swift
//  bulkup
//
//  Your friend code, big enough to read across a table, with copy and share.
//

import SwiftUI

struct MyFriendCodeView: View {
    @ObservedObject private var friendsManager = FriendsManager.shared
    @Environment(\.dismiss) private var dismiss

    @State private var copied = false
    @State private var contentHeight: CGFloat = 0

    var body: some View {
        ZStack {
            BulkUpGround()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: Spacing.lg) {
                    HStack(alignment: .firstTextBaseline) {
                        Text("Mi código")
                            .titleVoice(.title)
                            .foregroundColor(BulkUpColors.textPrimary)
                        Spacer(minLength: Spacing.md)
                        Button { dismiss() } label: {
                            Text("Cerrar")
                                .font(.system(.footnote, weight: .semibold))
                                .foregroundColor(BulkUpColors.textSecondary)
                                .frame(minHeight: 44)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }

                    Text("Quien lo meta en Añadir amigo verá tu racha y tus entrenos, y tú los suyos.")
                        .font(BulkUpFont.body())
                        .foregroundColor(BulkUpColors.textSecondary)

                    if let code = friendsManager.myFriendCode {
                        Text(code)
                            .font(BulkUpFont.mono(32, weight: .semibold, relativeTo: .largeTitle))
                            .foregroundColor(BulkUpColors.textPrimary)
                            .tracking(6)
                            .lineLimit(1)
                            .minimumScaleFactor(0.6)
                            .frame(maxWidth: .infinity, minHeight: 72)
                            .background(BulkUpColors.surface)
                            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.large, style: .continuous))
                            .lift()
                            .accessibilityLabel(Text(String(format: NSLocalizedString("Tu código es %@", comment: ""), code)))

                        HStack(spacing: Spacing.sm) {
                            Button {
                                UIPasteboard.general.string = code
                                UINotificationFeedbackGenerator().notificationOccurred(.success)
                                withAnimation(.easeOut(duration: 0.2)) { copied = true }
                                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                    withAnimation(.easeOut(duration: 0.2)) { copied = false }
                                }
                            } label: {
                                Text(copied ? "Copiado" : "Copiar")
                                    .font(.system(.headline, weight: .semibold))
                                    .foregroundColor(copied ? Color.onFill(BulkUpColors.complete) : BulkUpColors.onAccent)
                                    .frame(maxWidth: .infinity, minHeight: 54)
                                    .background(copied ? BulkUpColors.complete : BulkUpColors.accent)
                                    .clipShape(RoundedRectangle(cornerRadius: CornerRadius.medium, style: .continuous))
                            }
                            .buttonStyle(.plain)
                            .pressable()

                            ShareLink(item: String(format: NSLocalizedString("Añádeme en BulkUp con mi código: %@", comment: ""), code)) {
                                Text("Compartir")
                                    .font(.system(.headline, weight: .semibold))
                                    .foregroundColor(BulkUpColors.textPrimary)
                                    .frame(maxWidth: .infinity, minHeight: 54)
                                    .background(BulkUpColors.surfaceElevated)
                                    .clipShape(RoundedRectangle(cornerRadius: CornerRadius.medium, style: .continuous))
                            }
                            .buttonStyle(.plain)
                        }
                    } else {
                        ProgressView()
                            .tint(BulkUpColors.accent)
                            .frame(maxWidth: .infinity, minHeight: 72)
                    }
                }
                .padding(.horizontal, Spacing.screenH)
                .padding(.top, Spacing.lg)
                .padding(.bottom, Spacing.sm)
                .measureHeight($contentHeight)
            }
        }
        .presentationDetents(contentHeight > 0 ? [.height(contentHeight), .large] : [.medium, .large])
        .presentationDragIndicator(.visible)
        .presentationBackground(BulkUpColors.background)
        .task { await friendsManager.loadFriendCode() }
    }
}
