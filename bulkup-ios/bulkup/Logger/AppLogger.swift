// AppLogger.swift
import Foundation
import UIKit

class AppLogger {
    static let shared = AppLogger()
    private let apiService = APIService.shared
    private let appName = "bulkup-ios"
    
    enum LogLevel: String {
        case debug = "debug"
        case info = "info"
        case warning = "warning"
        case error = "error"
    }
    
    private init() {}
    
    // MARK: - Public Methods
    func info(_ message: String) {
        log(.info, message)
    }
    
    func error(_ message: String) {
        log(.error, message)
    }
    
    func warning(_ message: String) {
        log(.warning, message)
    }
    
    func debug(_ message: String) {
        #if DEBUG
        log(.debug, message)
        #endif
    }
    
    // MARK: - Private Methods
    private func log(_ level: LogLevel, _ message: String) {
        // Log localmente siempre
        print("[\(level.rawValue.uppercased())] \(message)")
        
        // Enviar al backend de forma completamente asíncrona
        Task.detached { [weak self] in
            guard let self = self else { return }
            await self.sendToBackend(level: level, message: message)
        }
    }
    
    private func sendToBackend(level: LogLevel, message: String) async {
        let userId: String = await MainActor.run {
                AuthManager.shared.user?.id ?? "anonymous"
            }
            
        
        let logEntry = LogEntry(
            level: level.rawValue,
            message: message,
            app: appName,
            userId: userId,
            timestamp: ISO8601DateFormatter().string(from: Date())
        )
        
        do {
            try await apiService.sendLog(logEntry)
        } catch {
            // Si falla el envío de logs, no queremos crashear la app
            print("[LOG ERROR] Failed to send log: \(error)")
        }
    }
}

// MARK: - Log Entry Model
struct LogEntry: Codable {
    let level: String
    let message: String
    let app: String
    let userId: String
    let timestamp: String
}

// MARK: - APIService Extension
extension APIService {
    func sendLog(_ entry: LogEntry) async throws {
        // No queremos que los logs bloqueen la app, así que usamos fire-and-forget
        do {
            let _: APIResponse<EmptyResponse> = try await requestWithBody(
                endpoint: "logs",
                method: .POST,
                body: entry
            )
        } catch {
            // Silenciosamente ignorar errores de logging para no afectar la app
            print("[LOG ERROR] Failed to send log: \(error)")
        }
    }
}
