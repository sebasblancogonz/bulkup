//
//  MyFriendCodeView.swift
//  bulkup
//
//  Sheet showing user's friend code
//

import SwiftUI

struct MyFriendCodeView: View {
    @ObservedObject private var friendsManager = FriendsManager.shared
    @Environment(\.dismiss) private var dismiss

    @State private var copied = false

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

                        Image(systemName: "person.2.fill")
                            .font(.system(size: 36))
                            .foregroundColor(BulkUpColors.accent)
                    }

                    Text("Tu Código de Amigo")
                        .font(BulkUpFont.sectionHeader())
                        .foregroundColor(BulkUpColors.textPrimary)

                    Text("Comparte este código con tus amigos para que te agreguen")
                        .font(BulkUpFont.body())
                        .foregroundColor(BulkUpColors.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                }

                if let code = friendsManager.myFriendCode {
                    VStack(spacing: Spacing.lg) {
                        Text(code)
                            .font(.system(size: 36, weight: .bold, design: .monospaced))
                            .foregroundColor(BulkUpColors.textPrimary)
                            .tracking(6)
                            .padding(.vertical, 20)
                            .padding(.horizontal, 32)
                            .background(
                                RoundedRectangle(cornerRadius: CornerRadius.large)
                                    .fill(BulkUpColors.surface)
                            )

                        Button {
                            UIPasteboard.general.string = code
                            copied = true
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                copied = false
                            }
                        } label: {
                            HStack(spacing: Spacing.sm) {
                                Image(systemName: copied ? "checkmark" : "doc.on.doc")
                                Text(copied ? "Copiado" : "Copiar Código")
                                    .fontWeight(.semibold)
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 48)
                            .background(copied ? BulkUpColors.success : BulkUpColors.accent)
                            .foregroundColor(BulkUpColors.onAccent)
                            .cornerRadius(CornerRadius.medium)
                        }
                        .padding(.horizontal, 24)
                    }
                } else {
                    ProgressView()
                        .padding(.vertical, 40)
                }

                Spacer()
            }
            .padding()
            .background(BulkUpColors.background.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cerrar") {
                        dismiss()
                    }
                    .foregroundColor(BulkUpColors.accent)
                }
            }
        }
        .presentationDetents([.medium])
        .onAppear {
            Task {
                await friendsManager.loadFriendCode()
            }
        }
    }
}
