import SwiftUI

/// A selectable protein/carb option for the recipe (one of a meal's options).
struct RecipeOptionChoice: Identifiable {
    let id: String
    let label: String
    let ingredients: [String]
}

/// One-shot AI recipe for a meal. First the user picks which option(s) to use
/// (based on what they have / prefer) and the complexity/time, then it generates
/// a recipe (markdown) plus an AI image of the dish. PRO-gated.
struct RecipeView: View {
    @StateObject private var manager: RecipeManager
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var storeKit = StoreKitManager.shared

    private let options: [RecipeOptionChoice]

    @State private var selectedOptionIDs: Set<String>
    @State private var complexity: RecipeComplexity = .medium
    @State private var hasGenerated = false
    @State private var showingSubscription = false

    init(mealType: String, options: [RecipeOptionChoice]) {
        _manager = StateObject(wrappedValue: RecipeManager(mealType: mealType))
        self.options = options
        _selectedOptionIDs = State(initialValue: Set(options.map { $0.id }))
    }

    var body: some View {
        NavigationStack {
            Group {
                if storeKit.isSubscribed {
                    if hasGenerated {
                        recipeContent
                    } else {
                        configContent
                    }
                } else {
                    SubscriptionRequiredView(
                        onSubscribe: { showingSubscription = true },
                        title: "Recetas con IA",
                        subtitle: "Genera una receta con foto a partir de los ingredientes de tu dieta."
                    )
                    .sheet(isPresented: $showingSubscription) {
                        SubscriptionView()
                    }
                }
            }
            .navigationTitle("Receta con IA")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cerrar") { dismiss() }
                        .foregroundColor(BulkUpColors.accent)
                }
                if hasGenerated {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button {
                            Task { await manager.regenerate() }
                        } label: {
                            Image(systemName: "arrow.clockwise")
                                .foregroundColor(BulkUpColors.accent)
                        }
                        .disabled(manager.isLoadingRecipe)
                    }
                }
            }
        }
    }

    // MARK: - Config step

    private var selectedIngredients: [String] {
        let chosen = options.filter { selectedOptionIDs.contains($0.id) }
        let pool = chosen.isEmpty ? options : chosen
        return Array(Set(pool.flatMap { $0.ingredients })).sorted()
    }

    private var configContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.lg) {
                if options.count > 1 {
                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        Text("¿Qué quieres usar?")
                            .font(BulkUpFont.cardTitle())
                            .foregroundColor(BulkUpColors.textPrimary)
                        Text("Elige las opciones que tengas o te apetezcan.")
                            .font(BulkUpFont.caption())
                            .foregroundColor(BulkUpColors.textSecondary)
                        ForEach(options) { option in
                            optionRow(option)
                        }
                    }
                }

                VStack(alignment: .leading, spacing: Spacing.sm) {
                    Text("Complejidad")
                        .font(BulkUpFont.cardTitle())
                        .foregroundColor(BulkUpColors.textPrimary)
                    Picker("Complejidad", selection: $complexity) {
                        ForEach(RecipeComplexity.allCases) { c in
                            Text(c.label).tag(c)
                        }
                    }
                    .pickerStyle(.segmented)
                    Text(complexity.detail)
                        .font(BulkUpFont.caption())
                        .foregroundColor(BulkUpColors.textSecondary)
                }

                Button {
                    hasGenerated = true
                    Task { await manager.load(ingredients: selectedIngredients, complexity: complexity) }
                } label: {
                    Text("Generar receta")
                        .font(BulkUpFont.cardTitle())
                        .foregroundColor(BulkUpColors.onAccent)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Spacing.md)
                        .background(canGenerate ? BulkUpColors.accent : BulkUpColors.textTertiary)
                        .cornerRadius(CornerRadius.large)
                }
                .disabled(!canGenerate)

                Color.clear.frame(height: 20)
            }
            .padding(.horizontal, Spacing.screenH)
            .padding(.top, Spacing.md)
        }
        .background(BulkUpColors.background)
    }

    private var canGenerate: Bool {
        options.count <= 1 || !selectedOptionIDs.isEmpty
    }

    private func optionRow(_ option: RecipeOptionChoice) -> some View {
        let isSelected = selectedOptionIDs.contains(option.id)
        return Button {
            if isSelected { selectedOptionIDs.remove(option.id) } else { selectedOptionIDs.insert(option.id) }
        } label: {
            HStack(spacing: Spacing.sm) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? BulkUpColors.accent : BulkUpColors.textTertiary)
                Text(option.label)
                    .font(BulkUpFont.body())
                    .foregroundColor(BulkUpColors.textPrimary)
                    .multilineTextAlignment(.leading)
                Spacer()
            }
            .padding(Spacing.md)
            .background(BulkUpColors.surface)
            .cornerRadius(CornerRadius.large)
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadius.large)
                    .stroke(isSelected ? BulkUpColors.accent.opacity(0.5) : BulkUpColors.border, lineWidth: isSelected ? 1.5 : 0.5)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Recipe step

    private var recipeContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.md) {
                imageHeader

                if manager.isLoadingRecipe {
                    loadingRecipe
                } else if let error = manager.errorMessage {
                    errorState(error)
                } else if !manager.recipe.isEmpty {
                    MarkdownText(content: manager.recipe)
                        .font(BulkUpFont.body())
                        .foregroundColor(BulkUpColors.textPrimary)
                        .padding(Spacing.md)
                        .background(BulkUpColors.surface)
                        .cornerRadius(CornerRadius.large)
                        .overlay(
                            RoundedRectangle(cornerRadius: CornerRadius.large)
                                .stroke(BulkUpColors.border, lineWidth: 0.5)
                        )

                    Button {
                        hasGenerated = false
                    } label: {
                        Label("Cambiar opciones", systemImage: "slider.horizontal.3")
                            .font(BulkUpFont.caption())
                            .foregroundColor(BulkUpColors.accent)
                    }
                    .buttonStyle(.plain)
                }

                Color.clear.frame(height: 40)
            }
            .padding(.horizontal, Spacing.screenH)
            .padding(.top, Spacing.md)
        }
        .background(BulkUpColors.background)
    }

    @ViewBuilder
    private var imageHeader: some View {
        ZStack {
            if let data = manager.imageData, let uiImage = UIImage(data: data) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
            } else {
                LinearGradient(
                    colors: [BulkUpColors.accent.opacity(0.25), BulkUpColors.surface],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                if manager.isLoadingImage {
                    ProgressView()
                } else {
                    Image(systemName: "fork.knife")
                        .font(.system(size: 40))
                        .foregroundColor(BulkUpColors.accent)
                }
            }
        }
        .frame(height: 220)
        .frame(maxWidth: .infinity)
        .clipped()
        .cornerRadius(CornerRadius.large)
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.large)
                .stroke(BulkUpColors.border, lineWidth: 0.5)
        )
    }

    private var loadingRecipe: some View {
        HStack(spacing: Spacing.sm) {
            ProgressView()
            Text("Generando receta…")
                .font(BulkUpFont.body())
                .foregroundColor(BulkUpColors.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Spacing.xl)
    }

    private func errorState(_ message: String) -> some View {
        VStack(spacing: Spacing.md) {
            Text(message)
                .font(BulkUpFont.body())
                .foregroundColor(BulkUpColors.textSecondary)
                .multilineTextAlignment(.center)
            Button("Reintentar") {
                Task { await manager.load(ingredients: selectedIngredients, complexity: complexity) }
            }
            .foregroundColor(BulkUpColors.accent)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Spacing.xl)
    }
}
