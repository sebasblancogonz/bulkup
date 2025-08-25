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
    private let ziplineURL = "https://weight-tracker-zipline.tme3al.easypanel.host" // Cambia por tu URL de Zipline
    private let ziplineToken = "MTc1NjEzMzcxNTMyOA==.YTI4ZTUyMDIyMzUwNTE4MDRlMjg1ZmVkZDkxZjQ0OWUuNzY0NDRmMTNiNTVhOWIzOTMwMWYzYTM2OTRjNmQ4NWFkY2Y2ODBlZmNlYTk1ZThkN2JhNjZjN2I4Nzg5MjA2OTc5YTg5ZWI0NjI2ZGM4NDA3Njg0YzhlNWQ5NjBlMjU3NWIxZTAyZmJkMmJjYTVmNGY2MjhkNDEyZjkwOTc3YTY1ZTQzMGZjMjY2YzYwODJlODE3MzM3NWViZTJiNTZmMg==" // Cambia por tu token de Zipline
    
    init() {}
    
    // MARK: - Load Profile
    func loadProfile() async {
        isLoading = true
        errorMessage = nil
        
        do {
            profile = try await apiService.getProfile()
        } catch {
            errorMessage = "Error al cargar perfil: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    // MARK: - Update Profile
    func updateProfile(name: String? = nil, dateOfBirth: Date? = nil, profileImageURL: String? = nil) async -> Bool {
        isLoading = true
        errorMessage = nil
        
        let request = UpdateProfileRequest(
            name: name,
            dateOfBirth: dateOfBirth,
            profileImageURL: profileImageURL
        )
        
        do {
            profile = try await apiService.updateProfile(request: request)
            
            // Notificar a AuthManager que actualice el usuario local
            if let profile = profile {
                AuthManager.shared.updateUserFromProfile(profile)
            }
            
            return true
        } catch {
            errorMessage = "Error al actualizar perfil: \(error.localizedDescription)"
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
                token: ziplineToken
            )
            
            // 2. Actualizar perfil con la URL de la imagen
            let success = try await apiService.uploadProfileImage(imageUrl: imageUrl)
            
            if success {
                // Recargar perfil para obtener datos actualizados
                await loadProfile()
                
                // Notificar a AuthManager
                if let profile = profile {
                    AuthManager.shared.updateUserFromProfile(profile)
                }
                
                return true
            }
            
            isUploadingImage = false
            return false
        } catch {
            errorMessage = "Error al subir imagen: \(error.localizedDescription)"
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
