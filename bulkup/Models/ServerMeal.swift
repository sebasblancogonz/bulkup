struct ServerMeal: Codable {
    let type: String
    let time: String
    let date: String?
    let notes: String?
    let options: [Any]?
    let conditions: ServerMealConditions?
    
    // Custom decoding for mixed types in options
    enum CodingKeys: String, CodingKey {
        case type, time, date, notes, conditions
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        type = try container.decode(String.self, forKey: .type)
        time = try container.decode(String.self, forKey: .time)
        date = try container.decodeIfPresent(String.self, forKey: .date)
        notes = try container.decodeIfPresent(String.self, forKey: .notes)
        conditions = try container.decodeIfPresent(ServerMealConditions.self, forKey: .conditions)
        
        // Handle options manually since it can be mixed types
        if let optionsContainer = try? decoder.container(keyedBy: CodingKeys.self),
           let optionsData = try? optionsContainer.decode([String: Any].self, forKey: .options) {
            // This is simplified - you'd need proper JSON handling here
        }
        options = nil // Simplified for now
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(type, forKey: .type)
        try container.encode(time, forKey: .time)
        try container.encodeIfPresent(date, forKey: .date)
        try container.encodeIfPresent(notes, forKey: .notes)
        try container.encodeIfPresent(conditions, forKey: .conditions)
    }
}