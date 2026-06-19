//
//  EditProfileView.swift
//  bulkup
//
//  Created by sebastian.blanco on 25/8/25.
//

import SwiftUI
import PhotosUI

struct EditProfileView: View {
    @EnvironmentObject var authManager: AuthManager
    @ObservedObject private var profileManager = ProfileManager.shared
    @Environment(\.dismiss) private var dismiss

    @State private var name: String = ""
    @State private var dateOfBirth: Date = Date()
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var profileImage: UIImage?
    @State private var showingDatePicker = false
    @State private var showingImageOptions = false
    @State private var showingDeleteConfirmation = false

    private var hasChanges: Bool {
        guard let profile = profileManager.profile else { return false }

        let nameChanged = name != profile.name
        let dateChanged = Calendar.current.compare(dateOfBirth, to: profile.dateOfBirth ?? Date(), toGranularity: .day) != .orderedSame
        let imageChanged = profileImage != nil

        return nameChanged || dateChanged || imageChanged
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Spacing.xl) {
                    // Profile Image Section
                    VStack(spacing: Spacing.lg) {
                        // Clickable Profile Image
                        Button {
                            showingImageOptions = true
                        } label: {
                            profileAvatar
                        }
                        .disabled(profileManager.isUploadingImage)
                        .shadow(color: BulkUpColors.accent.opacity(0.3), radius: 20, x: 0, y: 10)

                        Text("Toca para cambiar foto")
                            .font(BulkUpFont.caption())
                            .foregroundColor(BulkUpColors.textSecondary)
                    }
                    .padding(.top)

                    // Form Fields
                    VStack(spacing: 20) {
                        // Name Field
                        VStack(alignment: .leading, spacing: Spacing.sm) {
                            Text("Nombre")
                                .font(BulkUpFont.cardTitle())
                                .foregroundColor(BulkUpColors.textPrimary)

                            TextField("Tu nombre", text: $name)
                                .padding(Spacing.md)
                                .background(BulkUpColors.surfaceElevated)
                                .cornerRadius(CornerRadius.small)
                                .font(BulkUpFont.body())
                        }

                        // Date of Birth Field
                        VStack(alignment: .leading, spacing: Spacing.sm) {
                            Text("Fecha de Nacimiento")
                                .font(BulkUpFont.cardTitle())
                                .foregroundColor(BulkUpColors.textPrimary)

                            Button {
                                showingDatePicker = true
                            } label: {
                                HStack {
                                    Text(dateOfBirth.formatted(date: .long, time: .omitted))
                                        .foregroundColor(BulkUpColors.textPrimary)

                                    Spacer()

                                    Image(systemName: "calendar")
                                        .foregroundColor(BulkUpColors.accent)
                                }
                                .padding()
                                .background(BulkUpColors.surfaceElevated)
                                .cornerRadius(CornerRadius.small)
                                .contentShape(Rectangle())
                            }

                            if let age = profileManager.calculateAge(from: dateOfBirth) {
                                Text("\(age) años")
                                    .font(BulkUpFont.caption())
                                    .foregroundColor(BulkUpColors.textSecondary)
                            }
                        }

                        // Email Field (Read-only)
                        VStack(alignment: .leading, spacing: Spacing.sm) {
                            Text("Email")
                                .font(BulkUpFont.cardTitle())
                                .foregroundColor(BulkUpColors.textPrimary)

                            Text(profileManager.profile?.email ?? "")
                                .font(BulkUpFont.body())
                                .foregroundColor(BulkUpColors.textSecondary)
                                .padding()
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(BulkUpColors.surfaceElevated)
                                .cornerRadius(CornerRadius.small)
                        }
                    }
                    .padding(.horizontal)

                    // Save Button
                    Button {
                        saveProfile()
                    } label: {
                        HStack {
                            if profileManager.isLoading {
                                ProgressView()
                                    .scaleEffect(0.8)
                                    .tint(.white)
                            } else {
                                Image(systemName: "checkmark.circle.fill")
                            }

                            Text(profileManager.isLoading ? "Guardando..." : "Guardar Cambios")
                        }
                    }
                    .buttonStyle(PrimaryButtonStyle(color: BulkUpColors.accent))
                    .disabled(profileManager.isLoading || !hasChanges)
                    .opacity(hasChanges ? 1.0 : 0.6)
                    .padding(.horizontal)

                    Color.clear
                        .frame(height: 20)
                }
            }
            .background(BulkUpColors.background.ignoresSafeArea())
            .navigationTitle("Editar Perfil")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancelar") {
                        dismiss()
                    }
                }
            }
            // PhotosPicker as an overlay (invisible but functional)
            .overlay(alignment: .top) {
                if showingImageOptions {
                    Color.clear
                        .frame(width: 0, height: 0)
                        .photosPicker(
                            isPresented: $showingImageOptions,
                            selection: $selectedPhoto,
                            matching: .images,
                            photoLibrary: .shared()
                        )
                }
            }
        }
        .sheet(isPresented: $showingDatePicker) {
            DatePickerView(selectedDate: $dateOfBirth)
        }
        .alert("Eliminar Foto", isPresented: $showingDeleteConfirmation) {
            Button("Cancelar", role: .cancel) { }
            Button("Eliminar", role: .destructive) {
                deleteProfileImage()
            }
        } message: {
            Text("¿Estás seguro de que quieres eliminar tu foto de perfil?")
        }
        .onChange(of: selectedPhoto) { _, newValue in
            Task {
                if let data = try? await newValue?.loadTransferable(type: Data.self),
                   let uiImage = UIImage(data: data) {
                    profileImage = uiImage
                    showingImageOptions = false
                }
            }
        }
        .task {
            await profileManager.loadProfile()
            loadProfileData()
        }
        .alert("Error", isPresented: .constant(profileManager.errorMessage != nil)) {
            Button("OK") {
                profileManager.clearError()
            }
        } message: {
            Text(profileManager.errorMessage ?? "")
        }
    }

    // MARK: - Helper Functions
    private func loadProfileData() {
        guard let profile = profileManager.profile else { return }

        name = profile.name
        dateOfBirth = profile.dateOfBirth ?? Date()
    }

    private func saveProfile() {
        Task {
            var success = false

            // Upload image first if there's a new one
            if let imageData = profileImage?.jpegData(compressionQuality: 0.8) {
                success = await profileManager.uploadProfileImage(imageData: imageData)
                if !success {
                    return // Error handled by ProfileManager
                }
                profileImage = nil // Reset after upload
            }

            // Update profile data
            success = await profileManager.updateProfile(
                name: name.isEmpty ? nil : name,
                dateOfBirth: dateOfBirth
            )

            if success {
                // AuthManager is automatically updated via ProfileManager
                dismiss()
            }
        }
    }

    private func deleteProfileImage() {
        Task {
            let success = await profileManager.deleteProfileImage()
            if success {
                profileImage = nil
            }
        }
    }

    private var profileAvatar: some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [BulkUpColors.accent, BulkUpColors.accent.opacity(0.7)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 120, height: 120)

            avatarContent

            if profileManager.isUploadingImage {
                Color.black.opacity(0.5)
                    .clipShape(Circle())
                ProgressView()
                    .tint(.white)
            }

            Circle()
                .fill(Color.black.opacity(0.0001))
                .frame(width: 120, height: 120)
        }
    }

    @ViewBuilder
    private var avatarContent: some View {
        if let profileImage = profileImage {
            Image(uiImage: profileImage)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 120, height: 120)
                .clipShape(Circle())
        } else if let imageURL = profileManager.profile?.profileImageURL?.replacingOccurrences(of: "http://", with: "https://"),
                  let url = URL(string: imageURL) {
            CachedAsyncImage(
                url: url,
                content: { image, colors in
                    image
                        .resizable()
                        .scaledToFill()
                        .frame(width: 120, height: 120)
                        .clipShape(Circle())
                },
                placeholder: {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [BulkUpColors.accent, BulkUpColors.accent.opacity(0.7)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 120, height: 120)
                        .overlay(
                            Text(authManager.user?.name.prefix(1).uppercased() ?? "U")
                                .font(.system(size: 40, weight: .bold))
                                .foregroundColor(.white)
                        )
                }
            )
        } else {
            Text(name.prefix(2).uppercased())
                .font(.system(size: 48, weight: .bold))
                .foregroundColor(.white)
        }
    }
}

// MARK: - Date Picker View
struct DatePickerView: View {
    @Binding var selectedDate: Date
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                DatePicker(
                    "Fecha de Nacimiento",
                    selection: $selectedDate,
                    in: ...Date(),
                    displayedComponents: .date
                )
                .datePickerStyle(.wheel)
                .labelsHidden()

                Spacer()
            }
            .padding()
            .background(BulkUpColors.background.ignoresSafeArea())
            .navigationTitle("Fecha de Nacimiento")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancelar") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Listo") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .foregroundColor(BulkUpColors.accent)
                }
            }
        }
    }
}
