@Model
class MealOption {
    var optionDescription: String
    var ingredients: [String] = []
    var instructions: [String] = []
    
    init(description: String, ingredients: [String] = [], instructions: [String] = []) {
        self.optionDescription = description
        self.ingredients = ingredients
        self.instructions = instructions
    }
}