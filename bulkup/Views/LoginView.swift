//
//  LoginView.swift
//  bulkup
//
//  Created by sebastianblancogonz on 17/8/25.
//
import AuthenticationServices
import SwiftUI
import SwiftData

struct LoginContentView: View {
    @EnvironmentObject var authManager: AuthManager
    @Environment(\.colorScheme) private var colorScheme
    @State private var email = ""
    @State private var password = ""
    @State private var name = ""
    @State private var isRegistering = false
    @State private var errorMessage: String?

    var body: some View {
        VStack(spacing: 40) {
            // Header
            LoginHeaderView()
                .padding(.top, 60)

            // Form
            VStack(spacing: 20) {
                // Input fields
                VStack(spacing: Spacing.lg) {
                    if isRegistering {
                        CustomTextField(
                            placeholder: "Nombre",
                            text: $name,
                            icon: "person.fill"
                        )
                    }

                    CustomTextField(
                        placeholder: "Email",
                        text: $email,
                        icon: "envelope.fill",
                        keyboardType: .emailAddress
                    )

                    CustomSecureField(
                        placeholder: "Contraseña",
                        text: $password,
                        icon: "lock.fill"
                    )
                }
                .padding(.horizontal, 24)

                // Error message
                if let errorMessage = errorMessage {
                    Text(LocalizedStringKey(errorMessage))
                        .font(BulkUpFont.caption())
                        .foregroundColor(BulkUpColors.error)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                }

                // Primary button
                Button(action: handleAuthAction) {
                    HStack {
                        if authManager.isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: BulkUpColors.onAccent))
                                .scaleEffect(0.9)
                        } else {
                            Text(isRegistering ? LocalizedStringKey("Crear cuenta") : LocalizedStringKey("Iniciar sesión"))
                        }
                    }
                    .primaryButtonStyle(color: BulkUpColors.accent)
                    .contentShape(Rectangle())
                }
                .disabled(authManager.isLoading || email.isEmpty || password.isEmpty || (isRegistering && name.isEmpty))
                .opacity((email.isEmpty || password.isEmpty || (isRegistering && name.isEmpty)) ? 0.6 : 1)
                .padding(.horizontal, 24)

                // Toggle mode
                Button(action: { isRegistering.toggle() }) {
                    Text(isRegistering ? LocalizedStringKey("¿Ya tienes cuenta? Inicia sesión") : LocalizedStringKey("¿No tienes cuenta? Regístrate"))
                        .font(.footnote)
                        .fontWeight(.medium)
                        .foregroundColor(BulkUpColors.accent)
                        .padding(.vertical, 8)
                        .frame(maxWidth: .infinity)
                        .contentShape(Rectangle())
                }

                // Divider
                HStack {
                    Rectangle()
                        .frame(height: 1)
                        .foregroundColor(BulkUpColors.textTertiary.opacity(0.5))
                    Text("o")
                        .font(BulkUpFont.caption())
                        .foregroundColor(BulkUpColors.textTertiary)
                    Rectangle()
                        .frame(height: 1)
                        .foregroundColor(BulkUpColors.textTertiary.opacity(0.5))
                }
                .padding(.horizontal, 24)

                // Sign in with Apple
                SignInWithAppleButton(.signIn) { request in
                    request.requestedScopes = [.fullName, .email]
                } onCompletion: { result in
                    handleAppleSignIn(result: result)
                }
                .signInWithAppleButtonStyle(colorScheme == .dark ? .whiteOutline : .black)
                .frame(height: 56)
                .cornerRadius(CornerRadius.medium)
                .padding(.horizontal, 24)
            }

            Spacer()
        }
        .background(
            BulkUpColors.background
                .ignoresSafeArea()
        )
        .navigationBarHidden(true)
    }

    private func handleAuthAction() {
        errorMessage = nil

        Task {
            do {
                if isRegistering {
                    try await authManager.register(email: email, password: password, name: name)
                } else {
                    try await authManager.login(email: email, password: password)
                }
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    private func handleAppleSignIn(result: Result<ASAuthorization, Error>) {
        errorMessage = nil

        switch result {
        case .success(let authorization):
            guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential else {
                errorMessage = String(localized: "Error: credencial inválida")
                return
            }

            guard let identityTokenData = credential.identityToken,
                  let identityToken = String(data: identityTokenData, encoding: .utf8) else {
                errorMessage = String(localized: "Error: no se pudo obtener el token de identidad")
                return
            }

            let firstName = credential.fullName?.givenName
            let lastName = credential.fullName?.familyName
            let appleUserID = credential.user

            Task {
                do {
                    try await authManager.signInWithApple(
                        identityToken: identityToken,
                        firstName: firstName,
                        lastName: lastName
                    )
                    authManager.storeAppleUserId(appleUserID)
                } catch {
                    errorMessage = error.localizedDescription
                }
            }

        case .failure(let error):
            if let authError = error as? ASAuthorizationError,
               authError.code == .canceled {
                return
            }
            errorMessage = String(localized: "Error al iniciar sesión con Apple: \(error.localizedDescription)")
        }
    }
}

// Custom text field with design system tokens
struct CustomTextField: View {
    let placeholder: LocalizedStringKey
    @Binding var text: String
    let icon: String
    var keyboardType: UIKeyboardType = .default
    @FocusState private var isFocused: Bool

    var body: some View {
        HStack(spacing: Spacing.md) {
            Image(systemName: icon)
                .foregroundColor(BulkUpColors.textTertiary)
                .frame(width: 20)

            TextField(placeholder, text: $text)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
                .keyboardType(keyboardType)
                .foregroundColor(BulkUpColors.textPrimary)
                .focused($isFocused)
        }
        .padding()
        .background(BulkUpColors.surfaceElevated)
        .cornerRadius(CornerRadius.medium)
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.medium)
                .stroke(isFocused ? BulkUpColors.accent.opacity(0.6) : Color.clear, lineWidth: 1.5)
        )
        .animation(.easeInOut(duration: 0.2), value: isFocused)
    }
}

// Custom secure field with design system tokens
struct CustomSecureField: View {
    let placeholder: LocalizedStringKey
    @Binding var text: String
    let icon: String
    @State private var isSecure = true
    @FocusState private var isFocused: Bool

    var body: some View {
        HStack(spacing: Spacing.md) {
            Image(systemName: icon)
                .foregroundColor(BulkUpColors.textTertiary)
                .frame(width: 20)

            if isSecure {
                SecureField(placeholder, text: $text)
                    .foregroundColor(BulkUpColors.textPrimary)
                    .focused($isFocused)
            } else {
                TextField(placeholder, text: $text)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    .foregroundColor(BulkUpColors.textPrimary)
                    .focused($isFocused)
            }

            Button(action: { isSecure.toggle() }) {
                Image(systemName: isSecure ? "eye.slash.fill" : "eye.fill")
                    .foregroundColor(BulkUpColors.textTertiary)
                    .font(BulkUpFont.caption())
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
        }
        .padding()
        .background(BulkUpColors.surfaceElevated)
        .cornerRadius(CornerRadius.medium)
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.medium)
                .stroke(isFocused ? BulkUpColors.accent.opacity(0.6) : Color.clear, lineWidth: 1.5)
        )
        .animation(.easeInOut(duration: 0.2), value: isFocused)
    }
}

// Header with design system tokens
struct LoginHeaderView: View {
    var body: some View {
        VStack(spacing: Spacing.sm) {
            Image("BulkUp")
                .resizable()
                .scaledToFit()
                .frame(width: 200, height: 200)

            Text("Come, entrena, crece, repite.")
                .font(BulkUpFont.body())
                .foregroundColor(BulkUpColors.textSecondary)
        }
    }
}
