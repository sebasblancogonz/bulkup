//
//  GotifyWebSocketManager.swift
//  bulkup
//
//  Created by sebastian.blanco on 20/8/25.
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
}

// MARK: - WebSocket Manager
class GotifyWebSocketManager: ObservableObject {
    static let shared = GotifyWebSocketManager()
    
    @Published var isConnected = false
    @Published var lastNotification: GotifyNotification?
    
    private var webSocketTask: URLSessionWebSocketTask?
    private var urlSession: URLSession
    private let maxReconnectAttempts = 5
    private var reconnectAttempts = 0
    private var reconnectTimer: Timer?
    
    // Configuration
    private var gotifyURL: String {
        return APIConfig.baseURL.replacingOccurrences(of: "http", with: "ws")
    }
    
    private var gotifyToken: String {
        // You'll need to configure this token in your app
        return Bundle.main.object(forInfoDictionaryKey: "GOTIFY_CLIENT_TOKEN") as? String ?? ""
    }
    
    private init() {
        urlSession = URLSession(configuration: .default)
    }
    
    func connect(userId: String) {
        guard !gotifyToken.isEmpty else {
            print("Gotify token not configured")
            return
        }
        
        disconnect()
        
        let wsURLString = "\(gotifyURL)/ws/gotify?token=\(gotifyToken)"
        guard let wsURL = URL(string: wsURLString) else {
            print("Invalid WebSocket URL: \(wsURLString)")
            return
        }
        
        print("Connecting to Gotify WebSocket: \(wsURLString)")
        
        webSocketTask = urlSession.webSocketTask(with: wsURL)
        webSocketTask?.resume()
        
        receiveMessage()
        
        // Monitor connection state
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            if self.webSocketTask?.state == .running {
                self.isConnected = true
                self.reconnectAttempts = 0
                print("Connected to Gotify WebSocket")
            }
        }
    }
    
    func disconnect() {
        webSocketTask?.cancel(with: .goingAway, reason: nil)
        webSocketTask = nil
        isConnected = false
        reconnectTimer?.invalidate()
        reconnectTimer = nil
    }
    
    private func receiveMessage() {
        webSocketTask?.receive { [weak self] result in
            switch result {
            case .success(let message):
                switch message {
                case .string(let text):
                    self?.handleMessage(text)
                case .data(let data):
                    if let text = String(data: data, encoding: .utf8) {
                        self?.handleMessage(text)
                    }
                @unknown default:
                    break
                }
                
                // Continue receiving messages
                self?.receiveMessage()
                
            case .failure(let error):
                print("WebSocket receive error: \(error)")
                DispatchQueue.main.async {
                    self?.isConnected = false
                    self?.attemptReconnect()
                }
            }
        }
    }
    
    private func handleMessage(_ text: String) {
        guard let data = text.data(using: .utf8) else { return }
        
        do {
            let notification = try JSONDecoder().decode(GotifyNotification.self, from: data)
            
            DispatchQueue.main.async {
                self.lastNotification = notification
                print("Received Gotify notification: \(notification.title)")
                
                // Post local notification for processing updates
                self.postLocalNotification(for: notification)
            }
        } catch {
            print("Failed to decode Gotify notification: \(error)")
        }
    }
    
    private func postLocalNotification(for notification: GotifyNotification) {
        // You can integrate with your notification system here
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
        let delay = min(pow(2.0, Double(reconnectAttempts)), 30.0) // Exponential backoff, max 30s
        
        print("Attempting to reconnect in \(delay) seconds... (attempt \(reconnectAttempts))")
        
        reconnectTimer = Timer.scheduledTimer(withTimeInterval: delay, repeats: false) { [weak self] _ in
            // Note: You'll need to pass the userId somehow, perhaps store it as a property
            self?.connect(userId: "") // You'll need to manage userId properly
        }
    }
}
