import Foundation

@MainActor
final class RecipeManager: ObservableObject {
    @Published var recipe: String = ""
    @Published var dish: String = ""
    @Published var imageData: Data?
    @Published var isLoadingRecipe = false
    @Published var isLoadingImage = false
    @Published var errorMessage: String?

    let mealType: String
    let ingredients: [String]
    private let api = APIService.shared

    init(mealType: String, ingredients: [String]) {
        self.mealType = mealType
        self.ingredients = ingredients
    }

    func load() async {
        guard !isLoadingRecipe else { return }
        errorMessage = nil
        isLoadingRecipe = true
        do {
            let result = try await api.generateRecipe(mealType: mealType, ingredients: ingredients)
            recipe = result.recipe
            dish = result.dish
            isLoadingRecipe = false
            await loadImage()
        } catch {
            isLoadingRecipe = false
            errorMessage = "No se pudo generar la receta. Inténtalo de nuevo."
        }
    }

    /// Best-effort: a failed image still leaves the recipe usable (no photo).
    private func loadImage() async {
        guard !dish.isEmpty else { return }
        isLoadingImage = true
        defer { isLoadingImage = false }
        imageData = try? await api.generateRecipeImage(dish: dish)
    }

    func regenerate() async {
        recipe = ""
        dish = ""
        imageData = nil
        await load()
    }
}
