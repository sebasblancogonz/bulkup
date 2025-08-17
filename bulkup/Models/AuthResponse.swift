struct AuthResponse: Codable {
    let userId: String
    let email: String
    let name: String
    let token: String
    let createdAt: String?
}