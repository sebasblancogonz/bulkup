import SwiftUI

// MARK: - FoodTagInput Helper

enum FoodTagInput {
    static let maxPerList = 50

    /// Trims, rejects empties/case-insensitive dups, respects the cap. Returns the (possibly unchanged) list.
    static func add(_ raw: String, to list: [String]) -> [String] {
        let tag = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !tag.isEmpty, list.count < maxPerList,
              !list.contains(where: { $0.caseInsensitiveCompare(tag) == .orderedSame })
        else { return list }
        return list + [tag]
    }

    #if DEBUG
    static func runSelfCheck() {
        assert(add("  Nuez  ", to: []) == ["Nuez"], "trims whitespace")
        assert(add("nuez", to: ["Nuez"]) == ["Nuez"], "case-insensitive dedupe")
        assert(add("", to: ["Nuez"]) == ["Nuez"], "ignores empty")
        let full = (0..<maxPerList).map { "\($0)" }
        assert(add("new", to: full).count == maxPerList, "respects cap")
    }
    #endif
}

// MARK: - FoodPreferencesView

struct FoodPreferencesView: View {
    @ObservedObject private var profileManager = ProfileManager.shared
    @Environment(\.dismiss) private var dismiss

    @State private var allergies: [String] = []
    @State private var liked: [String] = []
    @State private var disliked: [String] = []

    var body: some View {
        NavigationStack {
            List {
                tagSection("Alergias", systemImage: "exclamationmark.triangle.fill",
                           color: BulkUpColors.error, tags: $allergies)
                tagSection("Me gusta", systemImage: "hand.thumbsup.fill",
                           color: BulkUpColors.success, tags: $liked)
                tagSection("No me gusta", systemImage: "hand.thumbsdown.fill",
                           color: BulkUpColors.textSecondary, tags: $disliked)
            }
            .navigationTitle("Preferencias y alergias")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Listo") { Task { await save(); dismiss() } }
                }
            }
            .task {
                if profileManager.profile == nil { await profileManager.loadProfile() }
                allergies = profileManager.profile?.allergies ?? []
                liked = profileManager.profile?.likedFoods ?? []
                disliked = profileManager.profile?.dislikedFoods ?? []
            }
        }
    }

    @ViewBuilder
    private func tagSection(_ title: LocalizedStringKey, systemImage: String,
                            color: Color, tags: Binding<[String]>) -> some View {
        Section {
            ForEach(tags.wrappedValue, id: \.self) { tag in
                Text(tag)
            }
            .onDelete { idx in tags.wrappedValue.remove(atOffsets: idx); Task { await save() } }
            AddTagField { newTag in
                tags.wrappedValue = FoodTagInput.add(newTag, to: tags.wrappedValue)
                Task { await save() }
            }
        } header: {
            Label(title, systemImage: systemImage).foregroundColor(color)
        }
    }

    private func save() async {
        _ = await profileManager.updateFoodPreferences(
            allergies: allergies, likedFoods: liked, dislikedFoods: disliked
        )
    }
}

// MARK: - AddTagField

private struct AddTagField: View {
    @State private var text = ""
    let onAdd: (String) -> Void
    var body: some View {
        HStack {
            TextField("Añadir…", text: $text)
                .submitLabel(.done)
                .onSubmit { commit() }
            Button { commit() } label: { Image(systemName: "plus.circle.fill") }
                .disabled(text.trimmingCharacters(in: .whitespaces).isEmpty)
        }
    }
    private func commit() {
        let t = text; text = ""; onAdd(t)
    }
}
