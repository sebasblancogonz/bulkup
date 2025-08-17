@Model
class Supplement {
    var name: String
    var dosage: String
    var timing: String
    var frequency: String
    var notes: String?
    
    init(name: String, dosage: String, timing: String, frequency: String, notes: String? = nil) {
        self.name = name
        self.dosage = dosage
        self.timing = timing
        self.frequency = frequency
        self.notes = notes
    }
}