//
//  RecipeChatManager.swift
//  bulkup
//
//  Created by sebastianblancogonz on 19/6/26.
//

import Foundation

struct ChatMessage: Identifiable, Equatable {
    let id = UUID()
    let role: String
    let content: String
    var isError = false
}

@MainActor
final class RecipeChatManager: ObservableObject {
    @Published var messages: [ChatMessage] = []
    @Published var isLoading = false
    let mealType: String
    let ingredients: [String]
    private let api = APIService.shared

    init(mealType: String, ingredients: [String]) {
        self.mealType = mealType
        self.ingredients = ingredients
    }

    func send(_ text: String) async {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !isLoading else { return }
        messages.append(ChatMessage(role: "user", content: trimmed))
        isLoading = true
        defer { isLoading = false }
        let dtos = messages.map { RecipeChatMessageDTO(role: $0.role, content: $0.content) }
        do {
            let reply = try await api.recipeChat(mealType: mealType, ingredients: ingredients, messages: dtos)
            messages.append(ChatMessage(role: "assistant", content: reply))
        } catch {
            messages.append(ChatMessage(role: "assistant", content: "No pude generar una respuesta. Inténtalo de nuevo.", isError: true))
        }
    }

    #if DEBUG
    func appendForTest(role: String, content: String) {
        messages.append(ChatMessage(role: role, content: content))
    }

    static func runSelfCheck() {
        let m = RecipeChatManager(mealType: "Desayuno", ingredients: ["avena"])
        m.appendForTest(role: "user", content: "hola")
        m.appendForTest(role: "assistant", content: "ok")
        assert(m.messages.count == 2 && m.messages[0].role == "user" && m.messages[1].role == "assistant", "order/roles")
    }
    #endif
}
