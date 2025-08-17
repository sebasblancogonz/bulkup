struct ServerDietDay: Codable {
    let day: String
    let meals: [ServerMeal]
    let supplements: [ServerSupplement]?
}