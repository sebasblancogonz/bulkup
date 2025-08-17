@Model
class ConditionalMeal {
    var mealDescription: String
    var ingredients: [String] = []
    
    init(description: String, ingredients: [String] = []) {
        self.mealDescription = description
        self.ingredients = ingredients
    }
}