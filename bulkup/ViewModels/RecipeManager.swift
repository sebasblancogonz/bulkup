import Foundation

enum RecipeComplexity: String, CaseIterable, Identifiable {
    case quick, medium, elaborate
    var id: String { rawValue }

    var label: String {
        switch self {
        case .quick: return "Rápida"
        case .medium: return "Media"
        case .elaborate: return "Elaborada"
        }
    }

    var detail: String {
        switch self {
        case .quick: return "< 15 min"
        case .medium: return "~30 min"
        case .elaborate: return "45+ min"
        }
    }
}

@MainActor
final class RecipeManager: ObservableObject {
    @Published var recipe: String = ""
    @Published var dish: String = ""
    @Published var imageData: Data?
    @Published var isLoadingRecipe = false
    @Published var isLoadingImage = false
    @Published var errorMessage: String?

    let mealType: String
    private let api = APIService.shared
    private var lastIngredients: [String] = []
    private var lastComplexity: RecipeComplexity = .medium

    init(mealType: String) {
        self.mealType = mealType
    }

    func load(ingredients: [String], complexity: RecipeComplexity) async {
        guard !isLoadingRecipe else { return }
        lastIngredients = ingredients
        lastComplexity = complexity
        errorMessage = nil
        isLoadingRecipe = true
        do {
            let result = try await api.generateRecipe(
                mealType: mealType,
                ingredients: ingredients,
                complexity: complexity.rawValue
            )
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
        await load(ingredients: lastIngredients, complexity: lastComplexity)
    }
}
