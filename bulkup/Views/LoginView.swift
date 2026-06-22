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
    @FocusState private var focusedField: Field?

    private enum Field { case name, email, password }

    private var isFormValid: Bool {
        !email.isEmpty && !password.isEmpty && (!isRegistering || !name.isEmpty)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: Spacing.xl) {
                LoginHeaderView()
                    .padding(.top, Spacing.xl)

                VStack(spacing: Spacing.lg) {
                    if isRegistering {
                        CustomTextField(
                            placeholder: "Nombre",
                            text: $name,
                            icon: "person.fill"
                        )
                        .focused($focusedField, equals: .name)
                        .submitLabel(.next)
                        .onSubmit { focusedField = .email }
                    }

                    CustomTextField(
                        placeholder: "Email",
                        text: $email,
                        icon: "envelope.fill",
                        keyboardType: .emailAddress
                    )
                    .focused($focusedField, equals: .email)
                    .submitLabel(.next)
                    .onSubmit { focusedField = .password }

                    CustomSecureField(
                        placeholder: "Contraseña",
                        text: $password,
                        icon: "lock.fill"
                    )
                    .focused($focusedField, equals: .password)
                    .submitLabel(.go)
                    .onSubmit { if isFormValid { handleAuthAction() } }

                    if let errorMessage = errorMessage {
                        Text(LocalizedStringKey(errorMessage))
                            .font(BulkUpFont.caption())
                            .foregroundColor(BulkUpColors.error)
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: .infinity)
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
                    .disabled(authManager.isLoading || !isFormValid)
                    .opacity(isFormValid ? 1 : 0.6)

                    // Toggle mode
                    Button(action: { withAnimation { isRegistering.toggle() } }) {
                        Text(isRegistering ? LocalizedStringKey("¿Ya tienes cuenta? Inicia sesión") : LocalizedStringKey("¿No tienes cuenta? Regístrate"))
                            .font(.footnote)
                            .fontWeight(.medium)
                            .foregroundColor(BulkUpColors.accent)
                            .padding(.vertical, Spacing.xs)
                            .frame(maxWidth: .infinity)
                            .contentShape(Rectangle())
                    }

                    // Divider
                    HStack(spacing: Spacing.sm) {
                        line
                        Text("o")
                            .font(BulkUpFont.caption())
                            .foregroundColor(BulkUpColors.textTertiary)
                        line
                    }
                    .padding(.vertical, Spacing.xs)

                    // Sign in with Apple — native button (label localized by the system).
                    SignInWithAppleButton(.signIn) { request in
                        focusedField = nil
                        request.requestedScopes = [.fullName, .email]
                    } onCompletion: { result in
                        handleAppleSignIn(result: result)
                    }
                    .signInWithAppleButtonStyle(colorScheme == .dark ? .whiteOutline : .black)
                    .frame(height: 54)
                    .cornerRadius(CornerRadius.medium)
                }
                .padding(.horizontal, Spacing.xl)
            }
            .frame(maxWidth: .infinity)
            .padding(.bottom, Spacing.xl)
        }
        .scrollDismissesKeyboard(.interactively)
        .background(BulkUpColors.background.ignoresSafeArea())
        .navigationBarHidden(true)
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button(action: { focusedField = nil }) {
                    Image(systemName: "keyboard.chevron.compact.down")
                }
                .tint(BulkUpColors.accent)
            }
        }
    }

    private var line: some View {
        Rectangle()
            .frame(height: 1)
            .foregroundColor(BulkUpColors.textTertiary.opacity(0.5))
    }

    private func handleAuthAction() {
        errorMessage = nil
        focusedField = nil

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
        .padding(.horizontal, Spacing.md)
        .frame(height: 54)
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

            Group {
                if isSecure {
                    SecureField(placeholder, text: $text)
                } else {
                    TextField(placeholder, text: $text)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                }
            }
            .foregroundColor(BulkUpColors.textPrimary)
            .focused($isFocused)

            Button(action: { isSecure.toggle() }) {
                Image(systemName: isSecure ? "eye.slash.fill" : "eye.fill")
                    .foregroundColor(BulkUpColors.textTertiary)
                    .font(BulkUpFont.caption())
                    .frame(width: 24, height: 24)
                    .contentShape(Rectangle())
            }
        }
        .padding(.horizontal, Spacing.md)
        .frame(height: 54)
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
                .frame(width: 130, height: 130)

            Text("Come, entrena, crece, repite.")
                .font(BulkUpFont.body())
                .foregroundColor(BulkUpColors.textSecondary)
        }
    }
}
