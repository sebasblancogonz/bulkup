@Model
class MealConditions {
    var trainingDays: ConditionalMeal?
    var nonTrainingDays: ConditionalMeal?
    
    init(trainingDays: ConditionalMeal? = nil, nonTrainingDays: ConditionalMeal? = nil) {
        self.trainingDays = trainingDays
        self.nonTrainingDays = nonTrainingDays
    }
}