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

                        Image(systemName: "person.2.fill")
                            .font(.system(size: 36))
                            .foregroundColor(.orange)
                    }

                    Text("Tu Código de Amigo")
                        .font(.title2)
                        .fontWeight(.bold)

                    Text("Comparte este código con tus amigos para que te agreguen")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                }

                if let code = friendsManager.myFriendCode {
                    VStack(spacing: 16) {
                        Text(code)
                            .font(.system(size: 36, weight: .bold, design: .monospaced))
                            .tracking(6)
                            .padding(.vertical, 20)
                            .padding(.horizontal, 32)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color(.systemGray6))
                            )

                        Button {
                            UIPasteboard.general.string = code
                            copied = true
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                copied = false
                            }
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: copied ? "checkmark" : "doc.on.doc")
                                Text(copied ? "Copiado" : "Copiar Código")
                                    .fontWeight(.semibold)
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 48)
                            .background(copied ? Color.green : Color.orange)
                            .foregroundColor(.white)
                            .cornerRadius(12)
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
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cerrar") {
                        dismiss()
                    }
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
