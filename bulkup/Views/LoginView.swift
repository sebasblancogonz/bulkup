//
//  LoginView.swift
//  bulkup
//
//  Created by sebastianblancogonz on 17/8/25.
//
import SwiftUI
import SwiftData

struct LoginContentView: View {
    @EnvironmentObject var authManager: AuthManager
    @State private var email = ""
    @State private var password = ""
    @State private var name = ""
    @State private var isRegistering = false
    @State private var errorMessage: String?
    
    var body: some View {
        VStack(spacing: 40) {
            // Header mejorado
            LoginHeaderView()
                .padding(.top, 60)
            
            // Form con mejor diseño
            VStack(spacing: 20) {
                // Campos de entrada
                VStack(spacing: 16) {
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
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                }
                
                // Botón principal
                Button(action: handleAuthAction) {
                    HStack {
                        if authManager.isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.9)
                        } else {
                            Text(isRegistering ? "Crear cuenta" : "Iniciar sesión")
                                .fontWeight(.semibold)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(
                        LinearGradient(
                            colors: [Color.orange, Color.orange.opacity(0.8)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .foregroundColor(.white)
                    .cornerRadius(16)
                    .shadow(color: Color.orange.opacity(0.3), radius: 8, x: 0, y: 4)
                }
                .disabled(authManager.isLoading || email.isEmpty || password.isEmpty || (isRegistering && name.isEmpty))
                .opacity((email.isEmpty || password.isEmpty || (isRegistering && name.isEmpty)) ? 0.6 : 1)
                .padding(.horizontal, 24)
                
                // Toggle mode
                Button(action: { isRegistering.toggle() }) {
                    Text(isRegistering ? "¿Ya tienes cuenta? Inicia sesión" : "¿No tienes cuenta? Regístrate")
                        .font(.footnote)
                        .fontWeight(.medium)
                        .foregroundColor(.orange)
                }
                .padding(.top, 8)
            }
            
            Spacer()
        }
        .background(
            LinearGradient(
                colors: [Color(.systemBackground), Color.orange.opacity(0.05)],
                startPoint: .top,
                endPoint: .bottom
            )
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
}

// Campo de texto personalizado
struct CustomTextField: View {
    let placeholder: String
    @Binding var text: String
    let icon: String
    var keyboardType: UIKeyboardType = .default
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.gray)
                .frame(width: 20)
            
            TextField(placeholder, text: $text)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
                .keyboardType(keyboardType)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
        )
    }
}

// Campo seguro personalizado
struct CustomSecureField: View {
    let placeholder: String
    @Binding var text: String
    let icon: String
    @State private var isSecure = true
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.gray)
                .frame(width: 20)
            
            if isSecure {
                SecureField(placeholder, text: $text)
            } else {
                TextField(placeholder, text: $text)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
            }
            
            Button(action: { isSecure.toggle() }) {
                Image(systemName: isSecure ? "eye.slash.fill" : "eye.fill")
                    .foregroundColor(.gray)
                    .font(.caption)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
        )
    }
}

// Header actualizado
struct LoginHeaderView: View {
    var body: some View {
        VStack(spacing: 8) {
            // Logo con animación suave
            Image("BulkUp")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 200, height: 200)
            VStack(spacing: 0) {
                Text("Come, entrena, crece, repite.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
    }
}
