//
//  AuthManager.swift
//  bulkup
//
//  Created by sebastianblancogonz on 17/8/25.
//

import AuthenticationServices
import Foundation
import SwiftData

@MainActor
class AuthManager: ObservableObject {
    static let shared = AuthManager(
        modelContext: ModelContainer.bulkUpContainer.mainContext
    )
    @Published var user: User?
    @Published var isAuthenticated = false
    @Published var isLoading = false
    @Published var isLoadingUserData = false

    public var modelContext: ModelContext
    private let apiService = APIService.shared

    init(modelContext: ModelContext) {
        print("🏗️ AuthManager init")
        self.modelContext = modelContext
        self.isAuthenticated = false
        self.user = nil
        loadStoredUser()
    }

    func login(email: String, password: String) async throws {
        guard !isLoading else { return }
        
        isLoading = true
        defer { isLoading = false }
        
        let response = try await apiService.login(email: email, password: password)
        
        // Store token immediately after successful login
        storeToken(response.token, userId: response.userId)
        
        let descriptor = FetchDescriptor<User>()
        let existingUsers = try modelContext.fetch(descriptor)
        for user in existingUsers {
            modelContext.delete(user)
        }
        
        let newUser = User(
            id: response.userId,
            email: response.email,
            name: response.name,
            token: response.token
        )
        
        // Manejar campos que pueden ser null para usuarios legacy
        newUser.dateOfBirth = response.dateOfBirth // Ya es opcional
        newUser.profileImageURL = response.profileImageURL // Ya es opcional
        
        modelContext.insert(newUser)
        try modelContext.save()
        
        self.user = newUser
        self.isAuthenticated = true

        // Existing account → skip onboarding (only fresh register shows it)
        UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")

        if !isLoadingUserData {
            self.isLoadingUserData = true
            await loadAllUserData(userId: newUser.id)
            await updateUserSubscriptionStatus()
            self.isLoadingUserData = false
        }
        
        NotificationCenter.default.post(name: .userDidLogin, object: newUser)
    }

    func register(
        email: String,
        password: String,
        name: String,
        dateOfBirth: Date? = nil
    ) async throws {
        isLoading = true
        defer { isLoading = false }

        let response = try await apiService.register(
            email: email,
            password: password,
            name: name,
            dateOfBirth: dateOfBirth
        )

        // Store token immediately after successful registration
        storeToken(response.token, userId: response.userId)

        let newUser = User(
            id: response.userId,
            email: response.email,
            name: response.name,
            token: response.token
        )

        // Actualizar con datos completos del AuthResponse
        newUser.updateFromAuthResponse(response)

        modelContext.insert(newUser)
        try modelContext.save()

        self.user = newUser
        self.isAuthenticated = true

        await loadAllUserData(userId: newUser.id)

        NotificationCenter.default.post(name: .userDidLogin, object: newUser)
    }

    func signInWithApple(identityToken: String, firstName: String?, lastName: String?) async throws {
        guard !isLoading else { return }

        isLoading = true
        defer { isLoading = false }

        let response = try await apiService.appleSignIn(
            identityToken: identityToken,
            firstName: firstName,
            lastName: lastName
        )

        storeToken(response.token, userId: response.userId)

        let descriptor = FetchDescriptor<User>()
        let existingUsers = try modelContext.fetch(descriptor)
        for user in existingUsers {
            modelContext.delete(user)
        }

        let newUser = User(
            id: response.userId,
            email: response.email,
            name: response.name,
            token: response.token
        )

        newUser.dateOfBirth = response.dateOfBirth
        newUser.profileImageURL = response.profileImageURL

        modelContext.insert(newUser)
        try modelContext.save()

        self.user = newUser
        self.isAuthenticated = true

        // Existing account → skip onboarding (only fresh register shows it)
        UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")

        if !isLoadingUserData {
            self.isLoadingUserData = true
            await loadAllUserData(userId: newUser.id)
            await updateUserSubscriptionStatus()
            self.isLoadingUserData = false
        }

        NotificationCenter.default.post(name: .userDidLogin, object: newUser)
    }

    func logout() {
        print("🚪 Iniciando logout...")

        // Clear stored token and onboarding state
        clearStoredAuth()
        UserDefaults.standard.removeObject(forKey: "hasCompletedOnboarding")
        UserDefaults.standard.removeObject(forKey: "userGoal")

        let descriptor = FetchDescriptor<User>()
        do {
            let users = try modelContext.fetch(descriptor)
            for user in users {
                modelContext.delete(user)
                print("🗑️ Usuario eliminado: \(user.email)")
            }
            try modelContext.save()
            print("✅ Datos guardados después de eliminar usuarios")
        } catch {
            print("❌ Error clearing user data: \(error)")
        }

        DispatchQueue.main.async {
            self.user = nil
            self.isAuthenticated = false
            print(
                "🔄 Estado limpiado - isAuthenticated: \(self.isAuthenticated)"
            )
        }

        NotificationCenter.default.post(name: .userDidLogout, object: nil)
        print("📢 Notificación de logout enviada")
    }

    func loadStoredUser() {
        print("🔍 Cargando usuario almacenado...")

        let descriptor = FetchDescriptor<User>()
        do {
            let users = try modelContext.fetch(descriptor)
            print("🔍 Usuarios encontrados: \(users.count)")

            if let storedUser = users.first {
                print("✅ Usuario encontrado: \(storedUser.email)")

                // Verify token exists in UserDefaults
                if let storedToken = Self.getStoredToken() {
                    // Update user token if needed
                    if storedUser.token != storedToken {
                        storedUser.token = storedToken
                        try? modelContext.save()
                    }

                    self.user = storedUser
                    self.isAuthenticated = true

                    // Existing users skip onboarding
                    if !UserDefaults.standard.bool(forKey: "hasCompletedOnboarding") {
                        UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
                    }

                    checkAppleCredentialState()

                    // Intentar sincronizar con el perfil del servidor
                    Task {
                        await syncUserProfile()
                    }
                } else {
                    // Token missing, require re-login
                    print("⚠️ Token no encontrado en UserDefaults")
                    self.user = nil
                    self.isAuthenticated = false
                }
            } else {
                print("❌ No se encontró usuario almacenado")
                self.user = nil
                self.isAuthenticated = false
            }
        } catch {
            print("❌ Error loading stored user: \(error)")
            self.user = nil
            self.isAuthenticated = false
        }
    }

    // Función para cargar todos los datos
    private func loadAllUserData(userId: String) async {
        print("🔄 Cargando todos los datos del usuario...")

        await withTaskGroup(of: Void.self) { group in
            group.addTask {
                await DietManager.shared.loadActiveDietPlan(userId: userId)
                print("✅ Datos de dieta cargados")
            }

            group.addTask {
                await TrainingManager.shared.loadActiveTrainingPlan(
                    userId: userId
                )
                print("✅ Datos de entrenamiento cargados")
            }

            // Agregar carga de medidas corporales si existe
            group.addTask {
                await BodyMeasurementsManager.shared.loadLatestMeasurements(
                    userId: userId
                )
                print("✅ Datos de medidas corporales cargados")
            }
        }

        print("🎉 Todos los datos del usuario cargados")
    }

    // MARK: - Apple Credential State

    func checkAppleCredentialState() {
        guard let appleUserID = UserDefaults.standard.string(forKey: "apple_user_id") else {
            return
        }

        let provider = ASAuthorizationAppleIDProvider()
        provider.getCredentialState(forUserID: appleUserID) { state, _ in
            DispatchQueue.main.async {
                switch state {
                case .revoked, .notFound:
                    print("Apple credential invalid - logging out")
                    self.logout()
                case .authorized:
                    break
                case .transferred:
                    break
                @unknown default:
                    break
                }
            }
        }
    }

    // MARK: - Profile Management

    /// Sincroniza el perfil local con el servidor
    func syncUserProfile() async {
        guard user != nil else { return }

        let profileManager = ProfileManager.shared
        await profileManager.loadProfile()

        if let serverProfile = profileManager.profile {
            updateUserFromProfile(serverProfile)
        }
    }

    /// Actualiza el usuario local con datos del perfil del servidor
    func updateUserFromProfile(_ profile: ProfileResponse) {
        guard let user = user else { return }

        user.updateFromProfile(profile)

        do {
            try modelContext.save()
            // Trigger UI update
            objectWillChange.send()
            print("✅ Perfil de usuario actualizado localmente")
        } catch {
            print("❌ Error guardando perfil actualizado: \(error)")
        }
    }

    /// Método público para que ProfileManager actualice el usuario
    func refreshUserData() {
        Task {
            await syncUserProfile()
        }
    }
}

extension AuthManager {
    // MARK: - Subscription Management

    /// Actualiza el estado de suscripción del usuario actual
    func updateUserSubscriptionStatus() async {
        guard let currentUser = user else { return }

        // Obtener el estado del StoreKitManager
        let storeManager = StoreKitManager.shared
        await storeManager.updateSubscriptionStatus()

        // Actualizar el usuario
        await MainActor.run {
            currentUser.hasActiveSubscription =
                storeManager.hasActiveSubscription
            currentUser.subscriptionExpiryDate = storeManager.expirationDate

            // Forzar actualización de la UI
            self.objectWillChange.send()
        }
    }

    /// Verifica si el usuario tiene suscripción activa
    func checkSubscriptionStatus() -> Bool {
        return user?.hasActiveSubscription ?? false
    }

    /// Obtiene la fecha de expiración de la suscripción
    func getSubscriptionExpiryDate() -> Date? {
        return user?.subscriptionExpiryDate
    }
}
