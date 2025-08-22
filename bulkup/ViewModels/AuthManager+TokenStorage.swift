import Foundation

extension AuthManager {
    
    private enum TokenKeys {
        static let authToken = "auth_token"
        static let userId = "user_id"
    }
    
    // MARK: - Token Storage
    
    /// Stores the authentication token securely
    func storeToken(_ token: String, userId: String) {
        UserDefaults.standard.set(token, forKey: TokenKeys.authToken)
        UserDefaults.standard.set(userId, forKey: TokenKeys.userId)
        UserDefaults.standard.synchronize()
    }
    
    /// Retrieves the stored authentication token
    static func getStoredToken() -> String? {
        return UserDefaults.standard.string(forKey: TokenKeys.authToken)
    }
    
    /// Retrieves the stored user ID
    static func getStoredUserId() -> String? {
        return UserDefaults.standard.string(forKey: TokenKeys.userId)
    }
    
    /// Clears the stored authentication data
    func clearStoredAuth() {
        UserDefaults.standard.removeObject(forKey: TokenKeys.authToken)
        UserDefaults.standard.removeObject(forKey: TokenKeys.userId)
        UserDefaults.standard.synchronize()
    }
    
    /// Validates if stored token exists
    static func hasStoredToken() -> Bool {
        return getStoredToken() != nil
    }
}
