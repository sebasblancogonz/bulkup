//
//  ProfileManager.swift
//  bulkup
//
//  Created by sebastian.blanco on 25/8/25.
//

import Foundation
import SwiftUI
import PhotosUI

@MainActor
class ProfileManager: ObservableObject {
    static let shared = ProfileManager()
    
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var profile: ProfileResponse?
    @Published var isUploadingImage = false
    
    private let apiService = APIService.shared
    
    // Zipline configuration - ajusta según tu configuración
    private var ziplineURL: String {
        // You'll need to configure this token in your app
        return Bundle.main.object(forInfoDictionaryKey: "ZIPLINE_URL") as? String ?? ""
    }
    
    private var ziplineToken: String {
        // You'll need to configure this token in your app
        return Bundle.main.object(forInfoDictionaryKey: "ZIPLINE_TOKEN") as? String ?? ""
    }
    
    init() {}
    
    // MARK: - Load Profile
    func loadProfile() async {
        isLoading = true
        errorMessage = nil
        
        do {
            profile = try await apiService.getProfile()
        } catch {
            errorMessage = "Error al cargar perfil: \(error.localizedDescription)"
            print("Error loading profile: \(error)")
        }
        
        isLoading = false
    }
    
    // MARK: - Update Profile
    func updateProfile(name: String? = nil, dateOfBirth: Date? = nil, profileImageURL: String? = nil) async -> Bool {
        isLoading = true
        errorMessage = nil
        
        // Log inicio de actualización
        AppLogger.shared.info("Iniciando actualización de perfil")
        
        // Usar valores actuales si no se proporcionan nuevos
        let currentProfile = profile
        
        let request = UpdateProfileRequest(
            name: name ?? currentProfile?.name,
            dateOfBirth: dateOfBirth ?? currentProfile?.dateOfBirth,
            profileImageURL: profileImageURL ?? currentProfile?.profileImageURL
        )
        
        do {
            // Log request details
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
            dateFormatter.locale = Locale(identifier: "en_US_POSIX")
            dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
            
            let dateString = request.dateOfBirth != nil ? dateFormatter.string(from: request.dateOfBirth!) : "nil"
            AppLogger.shared.info("UpdateProfile request - name: \(request.name ?? "nil"), dateOfBirth: \(dateString)")
            
            profile = try await apiService.updateProfile(request: request)
            
            AppLogger.shared.info("Perfil actualizado correctamente")
            
            // Notificar a AuthManager que actualice el usuario local
            if let profile = profile {
                AuthManager.shared.updateUserFromProfile(profile)
            }
            
            isLoading = false
            return true
        } catch {
            let errorMsg = "Error al actualizar perfil: \(error.localizedDescription)"
            errorMessage = errorMsg
            AppLogger.shared.error(errorMsg)
            
            // Log detalles adicionales del error
            if let apiError = error as? APIError {
                AppLogger.shared.error("APIError type: \(apiError)")
            }
            
            isLoading = false
            return false
        }
    }
    
    // MARK: - Upload Profile Image
    func uploadProfileImage(imageData: Data) async -> Bool {
        isUploadingImage = true
        errorMessage = nil
        
        do {
            
            // 1. Subir imagen a Zipline
            let imageUrl = try await apiService.uploadImageToZipline(
                imageData: imageData,
                ziplineURL: ziplineURL,
                token: ziplineToken,
                userId: profile?.userId
            )
            
            // 2. Actualizar perfil con la URL de la imagen
            let success = try await apiService.uploadProfileImage(imageUrl: imageUrl)
            
            if success {
                print("Profile image URL updated successfully")
                // Recargar perfil para obtener datos actualizados
                await loadProfile()
                
                // Notificar a AuthManager
                if let profile = profile {
                    AuthManager.shared.updateUserFromProfile(profile)
                }
                
                isUploadingImage = false
                return true
            }
            
            isUploadingImage = false
            return false
        } catch {
            errorMessage = "Error al subir imagen: \(error.localizedDescription)"
            print("Error uploading image: \(error)")
            isUploadingImage = false
            return false
        }
    }
    
    // MARK: - Delete Profile Image
    func deleteProfileImage() async -> Bool {
        isLoading = true
        errorMessage = nil
        
        do {
            let success = try await apiService.deleteProfileImage()
            
            if success {
                // Recargar perfil para obtener datos actualizados
                await loadProfile()
                
                // Notificar a AuthManager
                if let profile = profile {
                    AuthManager.shared.updateUserFromProfile(profile)
                }
            }
            
            isLoading = false
            return success
        } catch {
            errorMessage = "Error al eliminar imagen: \(error.localizedDescription)"
            print("Error deleting profile image: \(error)")
            isLoading = false
            return false
        }
    }
    
    // MARK: - Calculate Age
    func calculateAge(from dateOfBirth: Date) -> Int? {
        let calendar = Calendar.current
        let now = Date()
        let ageComponents = calendar.dateComponents([.year], from: dateOfBirth, to: now)
        return ageComponents.year
    }
    
    // MARK: - Clear Error
    func clearError() {
        errorMessage = nil
    }
}
