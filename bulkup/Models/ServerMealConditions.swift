struct ServerMealConditions: Codable {
    let trainingDays: ServerConditionalMeal?
    let nonTrainingDays: ServerConditionalMeal?
    
    enum CodingKeys: String, CodingKey {
        case trainingDays = "training_days"
        case nonTrainingDays = "non_training_days"
    }
}