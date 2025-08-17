//
//  LoginView.swift
//  bulkup
//
//  Created by sebastian.blanco on 17/8/25.
//


struct LoginView: View {
    @StateObject private var authManager: AuthManager
    @State private var email = ""
    @State private var password = ""
    @State private var name = ""
    @State private var isRegistering = false
    @State private var errorMessage: String?
    
    init(modelContext: ModelContext) {
        self._authManager = StateObject(wrappedValue: AuthManager(modelContext: modelContext))
    }
    
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
        .environmentObject(authManager)
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