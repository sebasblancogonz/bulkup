@Model
class DietDay {
    @Attribute(.unique) var id: String = UUID().uuidString
    var day: String
    var meals: [Meal] = []
    var supplements: [Supplement] = []
    
    // Para sincronización
    var planId: String?
    var needsSync: Bool = false
    var lastSynced: Date?
    
    init(day: String, meals: [Meal] = [], supplements: [Supplement] = []) {
        self.day = day
        self.meals = meals
        self.supplements = supplements
        self.needsSync = true
    }
}