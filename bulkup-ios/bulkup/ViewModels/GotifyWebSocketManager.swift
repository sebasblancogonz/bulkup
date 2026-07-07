//
//  GotifyWebSocketManager.swift
//  bulkup
//
//  Created by sebastianblancogonz on 20/8/25.
//

import Foundation
import Combine

// MARK: - Models
struct GotifyNotification: Codable {
    let id: Int
    let appid: Int
    let message: String
    let title: String
    let priority: Int
    let date: String
    let extras: GotifyExtras?
}

struct GotifyExtras: Codable {
    let processId: String?
    let status: String?
    let userId: String?
    let fileType: String?
    let filename: String?
    let error: String?
    let detectedType: String?

    private enum CodingKeys: String, CodingKey {
        case processId, status, userId, fileType, filename, error, detectedType
        case processIdSnake = "process_id"
        case userIdSnake = "user_id"
        case fileTypeSnake = "file_type"
        case detectedTypeSnake = "detected_type"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        processId = try container.decodeIfPresent(String.self, forKey: .processId)
            ?? container.decodeIfPresent(String.self, forKey: .processIdSnake)
        status = try container.decodeIfPresent(String.self, forKey: .status)
        userId = try container.decodeIfPresent(String.self, forKey: .userId)
            ?? container.decodeIfPresent(String.self, forKey: .userIdSnake)
        fileType = try container.decodeIfPresent(String.self, forKey: .fileType)
            ?? container.decodeIfPresent(String.self, forKey: .fileTypeSnake)
        filename = try container.decodeIfPresent(String.self, forKey: .filename)
        error = try container.decodeIfPresent(String.self, forKey: .error)
        detectedType = try container.decodeIfPresent(String.self, forKey: .detectedType)
            ?? container.decodeIfPresent(String.self, forKey: .detectedTypeSnake)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(processId, forKey: .processId)
        try container.encodeIfPresent(status, forKey: .status)
        try container.encodeIfPresent(userId, forKey: .userId)
        try container.encodeIfPresent(fileType, forKey: .fileType)
        try container.encodeIfPresent(filename, forKey: .filename)
        try container.encodeIfPresent(error, forKey: .error)
        try container.encodeIfPresent(detectedType, forKey: .detectedType)
    }

    static let empty = GotifyExtras(
        processId: nil, status: "completed", userId: nil,
        fileType: nil, filename: nil, error: nil, detectedType: nil
    )

    init(processId: String?, status: String?, userId: String?,
         fileType: String?, filename: String?, error: String?, detectedType: String?) {
        self.processId = processId
        self.status = status
        self.userId = userId
        self.fileType = fileType
        self.filename = filename
        self.error = error
        self.detectedType = detectedType
    }
}

// MARK: - WebSocket Manager
@MainActor
class GotifyWebSocketManager: ObservableObject {
    static let shared = GotifyWebSocketManager()

    @Published var isConnected = false
    @Published var lastNotification: GotifyNotification?

    private var webSocketTask: URLSessionWebSocketTask?
    private var urlSession: URLSession
    private let maxReconnectAttempts = 5
    private var reconnectAttempts = 0
    private var reconnectTimer: Timer?
    private var currentUserId: String = ""
    private var isIntentionalDisconnect = false

    // Configuration - conexión directa a Gotify (sin proxy por backend)
    private var gotifyWSURL: String {
        let base = APIConfig.gotifyURL
        if base.hasPrefix("https") {
            return base.replacingOccurrences(of: "https", with: "wss")
        }
        return base.replacingOccurrences(of: "http", with: "ws")
    }

    private var gotifyToken: String {
        return Bundle.main.object(forInfoDictionaryKey: "GOTIFY_CLIENT_TOKEN") as? String ?? ""
    }

    private init() {
        urlSession = URLSession(configuration: .default)
    }

    func connect(userId: String, isReconnect: Bool = false) {
        currentUserId = userId

        guard !gotifyToken.isEmpty else {
            print("Gotify token not configured")
            return
        }

        // Si ya estamos conectados, no reconectar
        if isConnected, webSocketTask?.state == .running {
            return
        }

        // Cerrar conexión previa sin disparar reconexión
        isIntentionalDisconnect = true
        webSocketTask?.cancel(with: .goingAway, reason: nil)
        webSocketTask = nil
        reconnectTimer?.invalidate()
        reconnectTimer = nil
        isIntentionalDisconnect = false
        if !isReconnect { reconnectAttempts = 0 }

        let wsURLString = "\(gotifyWSURL)/stream?token=\(gotifyToken)"
        guard let wsURL = URL(string: wsURLString) else {
            print("Invalid WebSocket URL: \(wsURLString)")
            return
        }

        print("Connecting to Gotify WebSocket: \(wsURLString)")

        webSocketTask = urlSession.webSocketTask(with: wsURL)
        webSocketTask?.resume()

        receiveMessage()

        // Monitor connection state
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
            guard let self = self else { return }
            if self.webSocketTask?.state == .running {
                self.isConnected = true
                self.reconnectAttempts = 0
                print("Connected to Gotify WebSocket")
            }
        }
    }

    func disconnect() {
        isIntentionalDisconnect = true
        webSocketTask?.cancel(with: .goingAway, reason: nil)
        webSocketTask = nil
        isConnected = false
        reconnectTimer?.invalidate()
        reconnectTimer = nil
        reconnectAttempts = 0
    }

    private func receiveMessage() {
        webSocketTask?.receive { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self else { return }

                switch result {
                case .success(let message):
                    switch message {
                    case .string(let text):
                        self.handleMessage(text)
                    case .data(let data):
                        if let text = String(data: data, encoding: .utf8) {
                            self.handleMessage(text)
                        }
                    @unknown default:
                        break
                    }

                    // Continue receiving messages
                    self.receiveMessage()

                case .failure(let error):
                    print("WebSocket receive error: \(error)")
                    self.isConnected = false

                    // Solo reconectar si no fue un cierre intencional
                    if !self.isIntentionalDisconnect {
                        self.attemptReconnect()
                    }
                }
            }
        }
    }

    private func handleMessage(_ text: String) {
        guard let data = text.data(using: .utf8) else { return }

        do {
            let notification = try JSONDecoder().decode(GotifyNotification.self, from: data)

            self.lastNotification = notification
            print("Received Gotify notification: \(notification.title)")

            // Post local notification for processing updates
            self.postLocalNotification(for: notification)
        } catch {
            print("Failed to decode Gotify notification: \(error)")
        }
    }

    private func postLocalNotification(for notification: GotifyNotification) {
        NotificationCenter.default.post(
            name: NSNotification.Name("GotifyNotificationReceived"),
            object: notification
        )
    }

    private func attemptReconnect() {
        guard reconnectAttempts < maxReconnectAttempts else {
            print("Max reconnection attempts reached")
            return
        }

        reconnectAttempts += 1
        let delay = min(pow(2.0, Double(reconnectAttempts)), 30.0)

        print("Attempting to reconnect in \(delay) seconds... (attempt \(reconnectAttempts))")

        reconnectTimer = Timer.scheduledTimer(withTimeInterval: delay, repeats: false) { [weak self] _ in
            guard let self = self else { return }
            Task { @MainActor in
                // Reset flag antes de reconectar
                self.isIntentionalDisconnect = false
                self.connect(userId: self.currentUserId, isReconnect: true)
            }
        }
    }
}
