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
            VStack(spacing: 32) {
                Spacer()

                VStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [.orange.opacity(0.2), .orange.opacity(0.05)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 80, height: 80)

                        Image(systemName: "person.badge.plus")
                            .font(.system(size: 36))
                            .foregroundColor(.orange)
                    }

                    Text("Agregar Amigo")
                        .font(.title2)
                        .fontWeight(.bold)

                    Text("Ingresa el código de 8 caracteres de tu amigo")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                }

                VStack(spacing: 16) {
                    TextField("CÓDIGO", text: $code)
                        .font(.system(size: 28, weight: .bold, design: .monospaced))
                        .tracking(4)
                        .multilineTextAlignment(.center)
                        .textInputAutocapitalization(.characters)
                        .autocorrectionDisabled()
                        .padding(.vertical, 16)
                        .padding(.horizontal, 24)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color(.systemGray6))
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
                            .font(.caption)
                            .foregroundColor(.red)
                    }

                    if success {
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                            Text("Amigo agregado exitosamente")
                        }
                        .font(.subheadline)
                        .foregroundColor(.green)
                    }

                    Button {
                        addFriend()
                    } label: {
                        HStack(spacing: 8) {
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
                        .background(code.count == 8 && !isLoading ? Color.orange : Color.gray)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    .disabled(code.count != 8 || isLoading)
                }
                .padding(.horizontal, 24)

                Spacer()
            }
            .padding()
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
                errorMessage = friendsManager.errorMessage ?? "Error al agregar amigo"
            }
        }
    }
}
