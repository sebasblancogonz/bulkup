//
//  AddFriendView.swift
//  bulkup
//
//  Add a friend by their eight-character code.
//

import SwiftUI

struct AddFriendView: View {
    @EnvironmentObject var authManager: AuthManager
    @ObservedObject private var friendsManager = FriendsManager.shared
    @Environment(\.dismiss) private var dismiss

    @State private var code = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var success = false
    @State private var contentHeight: CGFloat = 0
    @FocusState private var codeFocused: Bool

    private var canAdd: Bool { code.count == 8 && !isLoading && !success }

    var body: some View {
        ZStack {
            BulkUpGround()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: Spacing.lg) {
                    HStack(alignment: .firstTextBaseline) {
                        Text("Añadir amigo")
                            .titleVoice(.title)
                            .foregroundColor(BulkUpColors.textPrimary)
                        Spacer(minLength: Spacing.md)
                        Button { dismiss() } label: {
                            Text("Cancelar")
                                .font(.system(.footnote, weight: .semibold))
                                .foregroundColor(BulkUpColors.textSecondary)
                                .frame(minHeight: 44)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }

                    Text("Pídele su código de ocho caracteres; lo tiene en su perfil, en Mi código.")
                        .font(BulkUpFont.body())
                        .foregroundColor(BulkUpColors.textSecondary)

                    TextField("ABCD2345", text: $code)
                        .font(BulkUpFont.mono(28, weight: .semibold, relativeTo: .largeTitle))
                        .foregroundColor(BulkUpColors.textPrimary)
                        .tint(BulkUpColors.accentText)
                        .tracking(4)
                        .multilineTextAlignment(.center)
                        .textInputAutocapitalization(.characters)
                        .autocorrectionDisabled()
                        .focused($codeFocused)
                        .frame(minHeight: 64)
                        .background(BulkUpColors.surfaceElevated)
                        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.small, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: CornerRadius.small, style: .continuous)
                                .strokeBorder(BulkUpColors.accent, lineWidth: codeFocused ? 1.5 : 0)
                        )
                        .accessibilityLabel("Código de amigo")
                        .onChange(of: code) { _, newValue in
                            let filtered = String(newValue.uppercased().filter { $0.isLetter || $0.isNumber }.prefix(8))
                            if filtered != newValue { code = filtered }
                            errorMessage = nil
                        }

                    if let errorMessage {
                        Text(errorMessage)
                            .font(BulkUpFont.caption())
                            .foregroundColor(BulkUpColors.warning)
                    }

                    if success {
                        HStack(spacing: Spacing.sm) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 6, style: .continuous)
                                    .fill(BulkUpColors.complete)
                                    .frame(width: 22, height: 22)
                                Image(systemName: "checkmark")
                                    .font(.system(.caption2, weight: .bold))
                                    .foregroundColor(Color.onFill(BulkUpColors.complete))
                            }
                            Text("Ya sois amigos.")
                                .font(BulkUpFont.body())
                                .foregroundColor(BulkUpColors.textPrimary)
                        }
                        .transition(.opacity)
                    }

                    Button { addFriend() } label: {
                        HStack(spacing: Spacing.sm) {
                            if isLoading { ProgressView().tint(BulkUpColors.onAccent) }
                            Text(isLoading ? "Añadiendo…" : "Añadir")
                                .font(.system(.headline, weight: .semibold))
                        }
                        .foregroundColor(BulkUpColors.onAccent)
                        .frame(maxWidth: .infinity, minHeight: 54)
                        .background(BulkUpColors.accent)
                        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.medium, style: .continuous))
                    }
                    .buttonStyle(.plain)
                    .pressable()
                    .disabled(!canAdd)
                    .opacity(canAdd ? 1 : 0.5)
                }
                .padding(.horizontal, Spacing.screenH)
                .padding(.top, Spacing.lg)
                .padding(.bottom, Spacing.sm)
                .measureHeight($contentHeight)
            }
            .scrollDismissesKeyboard(.interactively)
        }
        .presentationDetents(contentHeight > 0 ? [.height(contentHeight), .large] : [.medium, .large])
        .presentationDragIndicator(.visible)
        .presentationBackground(BulkUpColors.background)
        .onAppear { codeFocused = true }
    }

    private func addFriend() {
        guard let userId = authManager.user?.id else { return }
        isLoading = true
        errorMessage = nil
        codeFocused = false

        Task {
            let result = await friendsManager.addFriend(userId: userId, code: code)
            isLoading = false
            if result {
                withAnimation(.easeOut(duration: 0.2)) { success = true }
                UINotificationFeedbackGenerator().notificationOccurred(.success)
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                dismiss()
            } else {
                errorMessage = friendsManager.errorMessage ?? NSLocalizedString("Código inválido o ya sois amigos", comment: "")
            }
        }
    }
}
