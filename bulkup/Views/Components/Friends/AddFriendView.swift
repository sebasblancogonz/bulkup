//
//  AddFriendView.swift
//  bulkup
//
//  Sheet to add a friend by code
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

    var body: some View {
        NavigationStack {
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
                            .frame(width: 80, height: 80)

                        Image(systemName: "person.badge.plus")
                            .font(.system(size: 36))
                            .foregroundColor(BulkUpColors.accent)
                    }

                    Text("Agregar Amigo")
                        .font(BulkUpFont.sectionHeader())
                        .foregroundColor(BulkUpColors.textPrimary)

                    Text("Ingresa el código de 8 caracteres de tu amigo")
                        .font(BulkUpFont.body())
                        .foregroundColor(BulkUpColors.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                }

                VStack(spacing: Spacing.lg) {
                    TextField("CÓDIGO", text: $code)
                        .font(.system(size: 28, weight: .bold, design: .monospaced))
                        .tracking(4)
                        .multilineTextAlignment(.center)
                        .textInputAutocapitalization(.characters)
                        .autocorrectionDisabled()
                        .padding(.vertical, Spacing.lg)
                        .padding(.horizontal, Spacing.xl)
                        .background(
                            RoundedRectangle(cornerRadius: CornerRadius.large)
                                .fill(BulkUpColors.surfaceElevated)
                        )
                        .onChange(of: code) { _, newValue in
                            let filtered = String(newValue.uppercased().prefix(8))
                            if filtered != newValue {
                                code = filtered
                            }
                            errorMessage = nil
                        }

                    if let error = errorMessage {
                        Text(error)
                            .font(BulkUpFont.caption())
                            .foregroundColor(BulkUpColors.error)
                    }

                    if success {
                        HStack(spacing: Spacing.sm) {
                            Image(systemName: "checkmark.circle.fill")
                            Text("Amigo agregado exitosamente")
                        }
                        .font(BulkUpFont.body())
                        .foregroundColor(BulkUpColors.success)
                    }

                    Button {
                        addFriend()
                    } label: {
                        HStack(spacing: Spacing.sm) {
                            if isLoading {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Image(systemName: "person.badge.plus")
                            }
                            Text(isLoading ? "Agregando..." : "Agregar Amigo")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(code.count == 8 && !isLoading ? BulkUpColors.accent : BulkUpColors.textTertiary)
                        .foregroundColor(Color.onFill(code.count == 8 && !isLoading ? BulkUpColors.accent : BulkUpColors.textTertiary))
                        .cornerRadius(CornerRadius.medium)
                    }
                    .disabled(code.count != 8 || isLoading)
                }
                .padding(.horizontal, 24)

                Spacer()
            }
            .padding()
            .background(BulkUpColors.background.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancelar") {
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.medium])
    }

    private func addFriend() {
        guard let userId = authManager.user?.id else { return }
        isLoading = true
        errorMessage = nil

        Task {
            let result = await friendsManager.addFriend(userId: userId, code: code)
            isLoading = false
            if result {
                success = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    dismiss()
                }
            } else {
                errorMessage = friendsManager.errorMessage ?? String(localized: "Error al agregar amigo")
            }
        }
    }
}
