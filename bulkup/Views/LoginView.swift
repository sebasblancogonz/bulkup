//
//  LoginView.swift
//  bulkup
//
//  Created by sebastian.blanco on 17/8/25.
//

import SwiftUI
import SwiftData

struct LoginView: View {
    @EnvironmentObject var authManager: AuthManager  // Changed from @StateObject
    @Environment(\.modelContext) private var modelContext  // Add this if you need the context
    @State private var email = ""
    @State private var password = ""
    @State private var name = ""
    @State private var isRegistering = false
    @State private var errorMessage: String?
    
    // Remove the init with modelContext parameter - no longer needed
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // Header
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
                
                // Form
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
                    
                    Button(action: handleAuthAction) {
                        if authManager.isLoading {
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
                    .disabled(authManager.isLoading || email.isEmpty || password.isEmpty || (isRegistering && name.isEmpty))
                    
                    Button(action: { isRegistering.toggle() }) {
                        Text(isRegistering ? "¿Ya tienes cuenta? Inicia sesión" : "¿No tienes cuenta? Regístrate")
                            .font(.footnote)
                            .foregroundColor(.green)
                    }
                }
                .padding(.horizontal, 32)
                
                Spacer()
            }
            .navigationBarHidden(true)
        }
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
                // The view will automatically switch because authManager.isAuthenticated
                // is now true and ContentView is watching this same instance
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
}
