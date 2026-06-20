import SwiftUI

/// One-shot AI recipe for a meal: shows a generated recipe (markdown) plus an
/// AI-generated dish image. Replaces the old recipe chat. PRO-gated.
struct RecipeView: View {
    @StateObject private var manager: RecipeManager
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var storeKit = StoreKitManager.shared

    @State private var showingSubscription = false

    init(mealType: String, ingredients: [String]) {
        _manager = StateObject(wrappedValue: RecipeManager(mealType: mealType, ingredients: ingredients))
    }

    var body: some View {
        NavigationStack {
            Group {
                if storeKit.isSubscribed {
                    content
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
            .task {
                if storeKit.isSubscribed, manager.recipe.isEmpty {
                    await manager.load()
                }
            }
        }
    }

    private var content: some View {
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
                Task { await manager.load() }
            }
            .foregroundColor(BulkUpColors.accent)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Spacing.xl)
    }
}
