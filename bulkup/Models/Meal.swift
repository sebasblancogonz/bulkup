@Model
class Meal {
    var type: String
    var time: String
    var date: String?
    var notes: String?
    var options: [MealOption] = []
    var conditions: MealConditions?
    
    init(type: String, time: String, date: String? = nil, notes: String? = nil) {
        self.type = type
        self.time = time
        self.date = date
        self.notes = notes
    }
}
