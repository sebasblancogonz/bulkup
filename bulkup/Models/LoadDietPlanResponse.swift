struct LoadDietPlanResponse: Codable {
    let success: Bool
    let dietData: [ServerDietDay]?
    let planId: String?
}