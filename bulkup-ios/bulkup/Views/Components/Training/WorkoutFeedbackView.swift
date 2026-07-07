import PhotosUI
import SwiftUI

/// Sheet to record post-workout sensations: emoji rating, sensation tags, a note,
/// and optional local photos. Opened after finishing a workout and from a
/// completed day. All data is local (SwiftData + on-device photo files).
struct WorkoutFeedbackView: View {
    let dayName: String
    let planId: String?

    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var manager = WorkoutFeedbackManager.shared

    @State private var rating: Int = 0
    @State private var selectedTags: Set<String> = []
    @State private var note: String = ""
    @State private var originalFilenames: [String] = []
    @State private var keptFilenames: [String] = []
    @State private var newImages: [UIImage] = []
    @State private var photoItems: [PhotosPickerItem] = []

    private let maxPhotos = 6

    private var photoCount: Int { keptFilenames.count + newImages.count }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.lg) {
                    ratingSection
                    tagsSection
                    noteSection
                    photosSection
                    Color.clear.frame(height: 20)
                }
                .padding(.horizontal, Spacing.screenH)
                .padding(.top, Spacing.md)
            }
            .background(BulkUpColors.background)
            .navigationTitle("¿Cómo fue el entreno?")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancelar") { dismiss() }
                        .foregroundColor(BulkUpColors.textSecondary)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Guardar") { save() }
                        .foregroundColor(BulkUpColors.accent)
                        .disabled(rating == 0 && selectedTags.isEmpty && note.isEmpty && photoCount == 0)
                }
            }
            .onAppear(perform: load)
            .onChange(of: photoItems) { _, items in
                Task { await loadPicked(items) }
            }
        }
    }

    // MARK: - Sections

    private var ratingSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("Sensación")
                .font(BulkUpFont.cardTitle())
                .foregroundColor(BulkUpColors.textPrimary)
            HStack(spacing: Spacing.sm) {
                ForEach(1...WorkoutFeedbackManager.ratingEmojis.count, id: \.self) { value in
                    let emoji = WorkoutFeedbackManager.ratingEmojis[value - 1]
                    Button {
                        rating = value
                    } label: {
                        Text(emoji)
                            .font(.system(size: 30))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, Spacing.sm)
                            .background(rating == value ? BulkUpColors.accent.opacity(0.18) : BulkUpColors.surface)
                            .cornerRadius(CornerRadius.medium)
                            .overlay(
                                RoundedRectangle(cornerRadius: CornerRadius.medium)
                                    .stroke(rating == value ? BulkUpColors.accent : BulkUpColors.border, lineWidth: rating == value ? 1.5 : 0.5)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var tagsSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("Etiquetas")
                .font(BulkUpFont.cardTitle())
                .foregroundColor(BulkUpColors.textPrimary)
            FlowChips(items: WorkoutFeedbackManager.availableTags, selected: selectedTags) { tag in
                if selectedTags.contains(tag) { selectedTags.remove(tag) } else { selectedTags.insert(tag) }
            }
        }
    }

    private var noteSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("Nota")
                .font(BulkUpFont.cardTitle())
                .foregroundColor(BulkUpColors.textPrimary)
            TextField("¿Algo que destacar? (opcional)", text: $note, axis: .vertical)
                .lineLimit(2...5)
                .font(BulkUpFont.body())
                .foregroundColor(BulkUpColors.textPrimary)
                .padding(Spacing.md)
                .background(BulkUpColors.surface)
                .cornerRadius(CornerRadius.medium)
                .overlay(
                    RoundedRectangle(cornerRadius: CornerRadius.medium)
                        .stroke(BulkUpColors.border, lineWidth: 0.5)
                )
        }
    }

    private var photosSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack {
                Text("Fotos")
                    .font(BulkUpFont.cardTitle())
                    .foregroundColor(BulkUpColors.textPrimary)
                Spacer()
                if photoCount < maxPhotos {
                    PhotosPicker(
                        selection: $photoItems,
                        maxSelectionCount: maxPhotos - photoCount,
                        matching: .images
                    ) {
                        Label("Añadir", systemImage: "photo.badge.plus")
                            .font(BulkUpFont.caption())
                            .foregroundColor(BulkUpColors.accent)
                    }
                }
            }

            if photoCount == 0 {
                Text("Guardadas solo en este dispositivo.")
                    .font(BulkUpFont.caption())
                    .foregroundColor(BulkUpColors.textSecondary)
            } else {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 90), spacing: Spacing.sm)], spacing: Spacing.sm) {
                    ForEach(keptFilenames, id: \.self) { filename in
                        if let image = WorkoutPhotoStore.load(filename) {
                            thumbnail(image) { keptFilenames.removeAll { $0 == filename } }
                        }
                    }
                    ForEach(Array(newImages.enumerated()), id: \.offset) { index, image in
                        thumbnail(image) { newImages.remove(at: index) }
                    }
                }
            }
        }
    }

    private func thumbnail(_ image: UIImage, onDelete: @escaping () -> Void) -> some View {
        Image(uiImage: image)
            .resizable()
            .scaledToFill()
            .frame(width: 90, height: 90)
            .clipped()
            .cornerRadius(CornerRadius.medium)
            .overlay(alignment: .topTrailing) {
                Button(action: onDelete) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.white, .black.opacity(0.5))
                        .padding(4)
                }
            }
    }

    // MARK: - Actions

    private func load() {
        guard let existing = manager.feedback(planId: planId, dayName: dayName) else { return }
        rating = existing.rating
        selectedTags = Set(existing.tags)
        note = existing.note ?? ""
        originalFilenames = existing.photoFilenames
        keptFilenames = existing.photoFilenames
    }

    private func loadPicked(_ items: [PhotosPickerItem]) async {
        for item in items {
            if let data = try? await item.loadTransferable(type: Data.self),
               let image = UIImage(data: data) {
                newImages.append(image)
            }
        }
        photoItems = []
    }

    private func save() {
        // Delete files the user removed.
        for filename in originalFilenames where !keptFilenames.contains(filename) {
            WorkoutPhotoStore.delete(filename)
        }
        // Persist newly added images.
        let newFilenames = newImages.compactMap { WorkoutPhotoStore.save($0) }
        manager.save(
            planId: planId,
            dayName: dayName,
            rating: rating,
            tags: Array(selectedTags),
            note: note,
            photoFilenames: keptFilenames + newFilenames
        )
        dismiss()
    }
}

/// Simple wrapping chip row.
private struct FlowChips: View {
    let items: [String]
    let selected: Set<String>
    let onTap: (String) -> Void

    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 90), spacing: Spacing.sm)], alignment: .leading, spacing: Spacing.sm) {
            ForEach(items, id: \.self) { item in
                let isOn = selected.contains(item)
                Button { onTap(item) } label: {
                    Text(LocalizedStringKey(item))
                        .font(BulkUpFont.caption())
                        .foregroundColor(isOn ? BulkUpColors.onAccent : BulkUpColors.textPrimary)
                        .padding(.horizontal, Spacing.md)
                        .padding(.vertical, Spacing.sm)
                        .frame(maxWidth: .infinity)
                        .background(isOn ? BulkUpColors.accent : BulkUpColors.surface)
                        .cornerRadius(CornerRadius.medium)
                        .overlay(
                            RoundedRectangle(cornerRadius: CornerRadius.medium)
                                .stroke(isOn ? BulkUpColors.accent : BulkUpColors.border, lineWidth: 0.5)
                        )
                }
                .buttonStyle(.plain)
            }
        }
    }
}
