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
    @State private var dateOfBirth: Date?
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var profileImage: UIImage?
    @State private var showingImageOptions = false
    @State private var showingDeleteConfirmation = false

    private var hasChanges: Bool {
        guard let profile = profileManager.profile else { return false }

        let nameChanged = name != profile.name
        let dateChanged: Bool
        switch (dateOfBirth, profile.dateOfBirth) {
        case (nil, nil): dateChanged = false
        case (let a?, let b?): dateChanged = Calendar.current.compare(a, to: b, toGranularity: .day) != .orderedSame
        default: dateChanged = true
        }
        let imageChanged = profileImage != nil

        return nameChanged || dateChanged || imageChanged
    }

    @FocusState private var nameFocused: Bool

    var body: some View {
        ZStack {
            BulkUpGround()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: Spacing.lg) {
                    HStack(alignment: .firstTextBaseline) {
                        Text("Editar perfil")
                            .titleVoice(.title)
                            .foregroundColor(BulkUpColors.textPrimary)
                        Spacer(minLength: Spacing.md)
                        Button { dismiss() } label: {
                            Text("Cancelar")
                                .font(.system(.footnote, weight: .semibold))
                                .foregroundColor(BulkUpColors.textSecondary)
                                .frame(minHeight: 44)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }

                    // Photo
                    HStack(spacing: Spacing.md) {
                        Button { showingImageOptions = true } label: {
                            ZStack {
                                avatarContent
                                if profileManager.isUploadingImage {
                                    Circle().fill(BulkUpColors.background.opacity(0.5))
                                    ProgressView().tint(BulkUpColors.accent)
                                }
                            }
                            .frame(width: 72, height: 72)
                            .clipShape(Circle())
                        }
                        .buttonStyle(.plain)
                        .disabled(profileManager.isUploadingImage)
                        .accessibilityLabel("Cambiar foto")

                        VStack(alignment: .leading, spacing: 0) {
                            Button { showingImageOptions = true } label: {
                                Text("Cambiar foto")
                                    .font(.system(.footnote, weight: .semibold))
                                    .foregroundColor(BulkUpColors.accentText)
                                    .frame(minHeight: 44)
                                    .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                            if profileManager.profile?.profileImageURL != nil || profileImage != nil {
                                Button { showingDeleteConfirmation = true } label: {
                                    Text("Quitar foto")
                                        .font(BulkUpFont.caption())
                                        .foregroundColor(BulkUpColors.textTertiary)
                                        .frame(minHeight: 44)
                                        .contentShape(Rectangle())
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        Spacer()
                    }

                    // Fields
                    VStack(spacing: 0) {
                        SlabRow(minHeight: 56) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Nombre")
                                    .font(BulkUpFont.caption())
                                    .foregroundColor(BulkUpColors.textSecondary)
                                TextField("Tu nombre", text: $name)
                                    .font(.system(.subheadline, weight: .semibold))
                                    .foregroundColor(BulkUpColors.textPrimary)
                                    .tint(BulkUpColors.accentText)
                                    .submitLabel(.done)
                                    .focused($nameFocused)
                                    .accessibilityLabel("Nombre")
                            }
                        }
                        SlabRow(minHeight: 56) {
                            HStack(alignment: .center) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Fecha de nacimiento")
                                        .font(BulkUpFont.caption())
                                        .foregroundColor(BulkUpColors.textSecondary)
                                    if let dateOfBirth, let age = profileManager.calculateAge(from: dateOfBirth) {
                                        Text(String(format: NSLocalizedString("%lld años", comment: ""), age))
                                            .font(.system(.subheadline, weight: .semibold))
                                            .foregroundColor(BulkUpColors.textPrimary)
                                    } else if dateOfBirth == nil {
                                        Text("Sin fecha")
                                            .font(.system(.subheadline, weight: .semibold))
                                            .foregroundColor(BulkUpColors.textTertiary)
                                    }
                                }
                                Spacer()
                                if dateOfBirth != nil {
                                    DatePicker("", selection: Binding(
                                        get: { dateOfBirth ?? Date() },
                                        set: { dateOfBirth = $0 }
                                    ), in: ...Date(), displayedComponents: .date)
                                        .labelsHidden()
                                        .tint(BulkUpColors.accentText)
                                        .accessibilityLabel("Fecha de nacimiento")
                                } else {
                                    Button {
                                        // Twenty-five is a plausible first spin of the wheel.
                                        dateOfBirth = Calendar.current.date(byAdding: .year, value: -25, to: Date())
                                    } label: {
                                        Text("Añadir fecha")
                                            .font(.system(.footnote, weight: .semibold))
                                            .foregroundColor(BulkUpColors.accentText)
                                            .frame(minHeight: 44)
                                            .contentShape(Rectangle())
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                        SlabRow(showsSeparator: false, minHeight: 56) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Email")
                                    .font(BulkUpFont.caption())
                                    .foregroundColor(BulkUpColors.textSecondary)
                                Text(profileManager.profile?.email ?? authManager.user?.email ?? "")
                                    .font(.system(.subheadline, weight: .semibold))
                                    .foregroundColor(BulkUpColors.textTertiary)
                            }
                        }
                    }
                    .slab()

                    Text("El email no se puede cambiar desde la app.")
                        .font(BulkUpFont.caption())
                        .foregroundColor(BulkUpColors.textTertiary)

                    Button { saveProfile() } label: {
                        HStack(spacing: Spacing.sm) {
                            if profileManager.isLoading {
                                ProgressView().tint(BulkUpColors.onAccent)
                            }
                            Text(profileManager.isLoading ? "Guardando…" : "Guardar")
                                .font(.system(.headline, weight: .semibold))
                        }
                        .foregroundColor(BulkUpColors.onAccent)
                        .frame(maxWidth: .infinity, minHeight: 54)
                        .background(BulkUpColors.accent)
                        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.medium, style: .continuous))
                    }
                    .buttonStyle(.plain)
                    .pressable()
                    .disabled(profileManager.isLoading || !hasChanges)
                    .opacity(hasChanges ? 1 : 0.5)
                }
                .padding(.horizontal, Spacing.screenH)
                .padding(.top, Spacing.lg)
                .padding(.bottom, Spacing.xl)
            }
            .scrollDismissesKeyboard(.interactively)
        }
        .presentationDragIndicator(.visible)
        .presentationBackground(BulkUpColors.background)
        .photosPicker(isPresented: $showingImageOptions, selection: $selectedPhoto, matching: .images, photoLibrary: .shared())
        .alert("Quitar foto", isPresented: $showingDeleteConfirmation) {
            Button("Cancelar", role: .cancel) { }
            Button("Quitar", role: .destructive) { deleteProfileImage() }
        } message: {
            Text("Tu perfil volverá a mostrar la inicial de tu nombre.")
        }
        .onChange(of: selectedPhoto) { _, newValue in
            Task {
                if let data = try? await newValue?.loadTransferable(type: Data.self),
                   let uiImage = UIImage(data: data) {
                    profileImage = uiImage
                }
                selectedPhoto = nil
            }
        }
        .task {
            profileManager.clearError()
            await profileManager.loadProfile()
            loadProfileData()
        }
        .alert("Error", isPresented: Binding(
            get: { profileManager.errorMessage != nil },
            set: { if !$0 { profileManager.clearError() } }
        )) {
            Button("OK") { profileManager.clearError() }
        } message: {
            Text(profileManager.errorMessage ?? "")
        }
    }

    // MARK: - Helper Functions
    private func loadProfileData() {
        guard let profile = profileManager.profile else {
            name = authManager.user?.name ?? ""
            dateOfBirth = authManager.user?.dateOfBirth
            return
        }

        name = profile.name
        dateOfBirth = profile.dateOfBirth
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

    @ViewBuilder
    private var avatarContent: some View {
        if let profileImage {
            Image(uiImage: profileImage)
                .resizable()
                .scaledToFill()
        } else {
            ProfileAvatar(name: name.isEmpty ? (authManager.user?.name ?? "") : name,
                          url: profileManager.profile?.profileImageURL, size: 72)
        }
    }
}
