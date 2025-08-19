//
//  LoginView.swift
//  bulkup
//
//  Created by sebastian.blanco on 17/8/25.
//
import SwiftUI
import SwiftData

struct LoginView: View {
    @EnvironmentObject var authManager: AuthManager
    
    var body: some View {
        let _ = print("🔑 LOGIN VIEW IS RENDERING")
        
        NavigationView {
            LoginContentView()
                .environmentObject(authManager)
        }
    }
}

// ✅ Separar el contenido en una vista independiente
struct LoginContentView: View {
    @EnvironmentObject var authManager: AuthManager
    @State private var email = ""
    @State private var password = ""
    @State private var name = ""
    @State private var isRegistering = false
    @State private var errorMessage: String?
    
    var body: some View {
        VStack(spacing: 24) {
            // Header - Extraer a subvista estática
            LoginHeaderView()
            
            // Form - Mantener aquí porque depende del estado local
            LoginFormView(
                email: $email,
                password: $password,
                name: $name,
                isRegistering: $isRegistering,
                errorMessage: $errorMessage,
                onAuthAction: handleAuthAction,
                onToggleMode: { isRegistering.toggle() }
            )
            
            Spacer()
        }
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

// ✅ Header estático que no se re-renderiza
struct LoginHeaderView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "leaf.fill")
                .font(.system(size: 60))
                .foregroundColor(.green)
            
            VStack(spacing: 8) {
                Text("Diet App")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Tu plan nutricional personalizado")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.top, 40)
    }
}

// ✅ Form optimizado
struct LoginFormView: View {
    @EnvironmentObject var authManager: AuthManager
    @Binding var email: String
    @Binding var password: String
    @Binding var name: String
    @Binding var isRegistering: Bool
    @Binding var errorMessage: String?
    let onAuthAction: () -> Void
    let onToggleMode: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            if isRegistering {
                TextField("Nombre", text: $name)
                    .textFieldStyle(.roundedBorder)
                    .autocorrectionDisabled()
            }
            
            TextField("Email", text: $email)
                .textFieldStyle(.roundedBorder)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
                .keyboardType(.emailAddress)
            
            SecureField("Contraseña", text: $password)
                .textFieldStyle(.roundedBorder)
            
            if let errorMessage = errorMessage {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
            }
            
            // ✅ Botón optimizado
            LoginButton(
                isRegistering: isRegistering,
                isLoading: authManager.isLoading,
                isDisabled: email.isEmpty || password.isEmpty || (isRegistering && name.isEmpty),
                action: onAuthAction
            )
            
            Button(action: onToggleMode) {
                Text(isRegistering ? "¿Ya tienes cuenta? Inicia sesión" : "¿No tienes cuenta? Regístrate")
                    .font(.footnote)
                    .foregroundColor(.green)
            }
        }
        .padding(.horizontal, 32)
    }
}

// ✅ Botón separado para evitar re-renders innecesarios
struct LoginButton: View {
    let isRegistering: Bool
    let isLoading: Bool
    let isDisabled: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            if isLoading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
            } else {
                Text(isRegistering ? "Crear cuenta" : "Iniciar sesión")
                    .fontWeight(.semibold)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 48)
        .background(Color.green)
        .foregroundColor(.white)
        .cornerRadius(12)
        .disabled(isLoading || isDisabled)
    }
}
