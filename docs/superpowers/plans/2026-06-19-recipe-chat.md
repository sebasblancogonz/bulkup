# AI Recipe Chat Implementation Plan (Diet sub-project B)

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** From a meal of the day, a PRO user opens a multi-turn AI chat that suggests recipes using that meal's ingredients, never using their allergens and respecting likes/dislikes (loaded server-side).

**Architecture:** New authenticated backend endpoint `POST /diet/recipe-chat` builds a system prompt from the server-side profile prefs + the client's meal ingredients and calls `AnthropicClient` (multi-turn, non-streaming). iOS `RecipeChatManager` + `RecipeChatView` (PRO-gated) drive it, entered from each meal card.

**Tech Stack:** Go (mux + MongoDB + Anthropic), SwiftUI, existing `APIService`/`StoreKitManager`.

**Verification:** Backend can't build locally (tesseract/leptonica cgo) → `gofmt`. iOS has no XCTest target → `xcodebuild` build + a `#if DEBUG` self-check for `RecipeChatManager` + manual. Do NOT add a test target.

**iOS build command:**
```bash
cd /Users/sebastian.blanco/Documents/Sebas/bulkup
xcodebuild -scheme bulkup-Dev -destination 'generic/platform=iOS Simulator' build CODE_SIGNING_ALLOWED=NO 2>&1 | grep -E "error:|BUILD SUCCEEDED|BUILD FAILED"
```

---

## File Structure

- Backend `internal/services/anthropic.go` — add `SendChat(...)`.
- Backend `internal/handlers/recipe_chat.go` (new) — `RecipeChatHandler` (auth + profile + Anthropic).
- Backend `internal/router/router.go` — construct the handler + register `POST /diet/recipe-chat`.
- iOS `bulkup/Services/APIService+Extensions.swift` — `recipeChat(...)` + request/response models.
- iOS `bulkup/ViewModels/RecipeChatManager.swift` (new) — `ChatMessage`, manager, DEBUG self-check.
- iOS `bulkup/Views/Components/Diet/RecipeChatView.swift` (new) — chat UI + PRO gate.
- iOS `bulkup/Views/Components/Diet/MealCardView.swift` — "Receta con IA" entry point.

---

## PHASE 1 — Backend

### Task 1: `SendChat` on AnthropicClient

**Files:** `internal/services/anthropic.go`. Repo: `/Users/sebastian.blanco/Documents/Sebas/weight-tracker-backend`.

- [ ] **Step 1: Read the existing request/response shapes**

READ `SendMessageWithModel` and the `AnthropicRequest`/`AnthropicResponse`/`Message`/`ContentBlock` types in `anthropic.go` to learn exactly how the request body is built (System field name, Messages, model, max_tokens) and how the reply text is read from the response.

- [ ] **Step 2: Add `SendChat`**

Mirror `SendMessageWithModel` but accept a full messages array. Add after `SendMessageWithModel`:
```go
// SendChat sends a multi-turn conversation with a system prompt.
func (c *AnthropicClient) SendChat(systemPrompt string, messages []Message, model string, maxTokens int) (*AnthropicResponse, error) {
	reqBody := AnthropicRequest{
		Model:     model,
		MaxTokens: maxTokens,
		System:    systemPrompt,
		Messages:  messages,
	}
	return c.doRequest(reqBody)
}
```
IMPORTANT: match reality — if `AnthropicRequest` has no `System` field, add it (`System string \`json:"system,omitempty"\``); if `SendMessageWithModel` does the HTTP inline rather than via a `doRequest` helper, either extract a small private `doRequest(reqBody AnthropicRequest) (*AnthropicResponse, error)` and have BOTH call it, or inline the same HTTP code in `SendChat`. Keep behavior identical (same URL, headers `x-api-key`/`anthropic-version`/content-type, decode into `AnthropicResponse`).

- [ ] **Step 3: Verify + commit**

```bash
cd /Users/sebastian.blanco/Documents/Sebas/weight-tracker-backend
gofmt -l internal/services/anthropic.go   # expect no output
git add internal/services/anthropic.go
git commit -m "feat(ai): AnthropicClient.SendChat for multi-turn conversations"
```

### Task 2: RecipeChatHandler + route

**Files:** Create `internal/handlers/recipe_chat.go`; modify `internal/router/router.go`.

- [ ] **Step 1: Write the handler**

Create `internal/handlers/recipe_chat.go`. Mirror the auth-helper pattern used by `ProfileHandler.getUserFromRequest` (Bearer token → `authService.ValidateToken` → `user.UserID`). Use `ProfileService.GetProfile(userId)` to load `allergies`/`likedFoods`/`dislikedFoods`.
```go
package handlers

import (
	"encoding/json"
	"fmt"
	"net/http"
	"strings"

	"fitness-api/internal/services"
	"fitness-api/internal/utils"
)

type RecipeChatHandler struct {
	authService    *services.AuthService
	profileService *services.ProfileService
	anthropic      *services.AnthropicClient
}

func NewRecipeChatHandler(a *services.AuthService, p *services.ProfileService, c *services.AnthropicClient) *RecipeChatHandler {
	return &RecipeChatHandler{authService: a, profileService: p, anthropic: c}
}

func (h *RecipeChatHandler) getUserFromRequest(r *http.Request) (string, error) {
	authHeader := r.Header.Get("Authorization")
	if authHeader == "" {
		return "", fmt.Errorf("token de autorización requerido")
	}
	parts := strings.Split(authHeader, " ")
	if len(parts) != 2 || parts[0] != "Bearer" {
		return "", fmt.Errorf("formato de autorización inválido")
	}
	user, err := h.authService.ValidateToken(parts[1])
	if err != nil {
		return "", fmt.Errorf("token inválido: %v", err)
	}
	return user.UserID, nil
}

type recipeChatRequest struct {
	MealType    string             `json:"mealType"`
	Ingredients []string           `json:"ingredients"`
	Messages    []services.Message `json:"messages"`
}

func (h *RecipeChatHandler) RecipeChat(w http.ResponseWriter, r *http.Request) {
	utils.SetCORSHeaders(w, r)
	if r.Method == "OPTIONS" {
		w.WriteHeader(http.StatusOK)
		return
	}
	if h.anthropic == nil || !h.anthropic.IsConfigured() {
		utils.RespondWithError(w, r, http.StatusServiceUnavailable, "Servicio de IA no disponible")
		return
	}

	userID, err := h.getUserFromRequest(r)
	if err != nil {
		utils.RespondWithError(w, r, http.StatusUnauthorized, err.Error())
		return
	}

	var req recipeChatRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		utils.RespondWithError(w, r, http.StatusBadRequest, "JSON inválido")
		return
	}
	if len(req.Messages) == 0 {
		utils.RespondWithError(w, r, http.StatusBadRequest, "messages requerido")
		return
	}

	var allergies, liked, disliked []string
	if user, err := h.profileService.GetProfile(userID); err == nil && user != nil {
		allergies, liked, disliked = user.Allergies, user.LikedFoods, user.DislikedFoods
	}

	system := buildRecipeSystemPrompt(req.MealType, req.Ingredients, allergies, liked, disliked)

	// Recipe chat is short text → Haiku-class is enough; keep tokens modest.
	resp, err := h.anthropic.SendChat(system, req.Messages, services.ModelHaiku, 1024)
	if err != nil {
		utils.RespondWithError(w, r, http.StatusInternalServerError, "Error generando la respuesta")
		return
	}
	reply := ""
	if len(resp.Content) > 0 {
		reply = resp.Content[0].Text
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]string{"reply": reply})
}

func joinOrNone(items []string) string {
	if len(items) == 0 {
		return "ninguno"
	}
	return strings.Join(items, ", ")
}

func buildRecipeSystemPrompt(mealType string, ingredients, allergies, liked, disliked []string) string {
	return fmt.Sprintf(`Eres un asistente de cocina y nutrición dentro de una app de fitness.
El usuario quiere ideas de receta para: %s.
Ingredientes disponibles de esa comida: %s.

REGLAS ESTRICTAS:
- NUNCA incluyas ni sugieras estos alérgenos (es médico): %s.
- Evita estos alimentos que no le gustan: %s.
- Prioriza estos que le gustan: %s.
- Usa principalmente los ingredientes disponibles; puedes sugerir 1-2 extras comunes si hacen falta.
- Sé conciso y práctico: nombre del plato, ingredientes y pasos breves.
- Responde en el mismo idioma que use el usuario en el chat.`,
		mealType,
		joinOrNone(ingredients),
		joinOrNone(allergies),
		joinOrNone(disliked),
		joinOrNone(liked),
	)
}
```
Verify the actual names: `ModelHaiku` constant (exists in anthropic.go — confirm exact name; if it's `ModelHaiku`/`ModelSonnet`, use it), `AnthropicResponse.Content[].Text`, `services.Message` (Role/Content), `utils.RespondWithError`/`utils.SetCORSHeaders`. Adjust to match.

- [ ] **Step 2: Register the route**

In `internal/router/router.go`, near the other diet routes, add:
```go
	recipeChatHandler := handlers.NewRecipeChatHandler(serviceContainer.AuthService, serviceContainer.ProfileService, serviceContainer.AnthropicClient)
	r.HandleFunc("/diet/recipe-chat", recipeChatHandler.RecipeChat).Methods("POST", "OPTIONS")
```

- [ ] **Step 3: Verify + commit**

```bash
cd /Users/sebastian.blanco/Documents/Sebas/weight-tracker-backend
gofmt -l internal/handlers/recipe_chat.go internal/router/router.go   # expect no output
git add internal/handlers/recipe_chat.go internal/router/router.go
git commit -m "feat(ai): POST /diet/recipe-chat endpoint (auth + profile prefs + Anthropic)"
```

---

## PHASE 2 — iOS

### Task 3: APIService.recipeChat

**Files:** `bulkup/Services/APIService+Extensions.swift`.

- [ ] **Step 1: Add request/response models + the call**

READ an existing POST method in this file (e.g. `saveMealTracking`) to match how it builds the `URLRequest`, attaches the Bearer token, and decodes. Then add:
```swift
struct RecipeChatMessageDTO: Codable {
    let role: String
    let content: String
}

private struct RecipeChatRequest: Codable {
    let mealType: String
    let ingredients: [String]
    let messages: [RecipeChatMessageDTO]
}

private struct RecipeChatResponse: Codable {
    let reply: String
}

extension APIService {
    func recipeChat(mealType: String, ingredients: [String], messages: [RecipeChatMessageDTO]) async throws -> String {
        guard let url = URL(string: "\(APIConfig.baseURL)/diet/recipe-chat") else {
            throw APIError.invalidClientRequest
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let token = UserDefaults.standard.string(forKey: "auth_token") {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        request.httpBody = try JSONEncoder().encode(
            RecipeChatRequest(mealType: mealType, ingredients: ingredients, messages: messages)
        )
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw APIError.serverError((response as? HTTPURLResponse)?.statusCode ?? 0)
        }
        return try JSONDecoder().decode(RecipeChatResponse.self, from: data).reply
    }
}
```
Match the EXACT `APIError` cases that exist (use whatever the file already uses for invalid-request/server-error; adjust the two `throw`s accordingly). The `auth_token` UserDefaults key is the same one the upload/profile calls use.

- [ ] **Step 2: Build + commit**

Run the iOS build command. Expected `BUILD SUCCEEDED`.
```bash
git add bulkup/Services/APIService+Extensions.swift
git commit -m "feat(diet): APIService.recipeChat"
```

### Task 4: RecipeChatManager + ChatMessage + self-check

**Files:** Create `bulkup/ViewModels/RecipeChatManager.swift`. Modify `bulkup/App/BulkUp.swift`.

- [ ] **Step 1: Write the manager**

```swift
import Foundation

struct ChatMessage: Identifiable, Equatable {
    let id = UUID()
    let role: String        // "user" | "assistant"
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
            messages.append(ChatMessage(role: "assistant",
                content: "No pude generar una respuesta. Inténtalo de nuevo.", isError: true))
        }
    }

    #if DEBUG
    func appendForTest(role: String, content: String) { messages.append(ChatMessage(role: role, content: content)) }
    static func runSelfCheck() {
        let m = RecipeChatManager(mealType: "Desayuno", ingredients: ["avena"])
        m.appendForTest(role: "user", content: "hola")
        m.appendForTest(role: "assistant", content: "respuesta")
        assert(m.messages.count == 2 && m.messages[0].role == "user" && m.messages[1].role == "assistant",
               "messages keep insertion order with correct roles")
    }
    #endif
}
```

- [ ] **Step 2: Self-check at launch**

In `bulkup/App/BulkUp.swift` `init()`, inside the existing `#if DEBUG` block, add `RecipeChatManager.runSelfCheck()`.

- [ ] **Step 3: Build + commit**

Run the iOS build command. Expected `BUILD SUCCEEDED`.
```bash
git add bulkup/ViewModels/RecipeChatManager.swift bulkup/App/BulkUp.swift
git commit -m "feat(diet): RecipeChatManager (ephemeral multi-turn) + self-check"
```

### Task 5: RecipeChatView (chat UI + PRO gate)

**Files:** Create `bulkup/Views/Components/Diet/RecipeChatView.swift`.

- [ ] **Step 1: Write the view**

```swift
import SwiftUI

struct RecipeChatView: View {
    let mealType: String
    let ingredients: [String]

    @StateObject private var manager: RecipeChatManager
    @ObservedObject private var store = StoreKitManager.shared
    @Environment(\.dismiss) private var dismiss
    @State private var input = ""

    init(mealType: String, ingredients: [String]) {
        self.mealType = mealType
        self.ingredients = ingredients
        _manager = StateObject(wrappedValue: RecipeChatManager(mealType: mealType, ingredients: ingredients))
    }

    var body: some View {
        NavigationStack {
            Group {
                if store.isSubscribed {
                    chat
                } else {
                    SubscriptionRequiredView(
                        title: "Recetas con IA",
                        subtitle: "Sugerencias de recetas con los ingredientes de tu dieta."
                    )
                }
            }
            .navigationTitle("Receta con IA")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Cerrar") { dismiss() } } }
            .background(BulkUpColors.background.ignoresSafeArea())
        }
    }

    private var chat: some View {
        VStack(spacing: 0) {
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 10) {
                        if manager.messages.isEmpty {
                            Text("Pídeme una receta para tu \(mealType.lowercased()) con: \(ingredients.joined(separator: ", "))")
                                .font(BulkUpFont.body())
                                .foregroundColor(BulkUpColors.textSecondary)
                                .padding()
                        }
                        ForEach(manager.messages) { msg in
                            bubble(msg).id(msg.id)
                        }
                        if manager.isLoading {
                            Text("Pensando…").font(BulkUpFont.caption())
                                .foregroundColor(BulkUpColors.textSecondary)
                        }
                    }
                    .padding(.horizontal, Spacing.md)
                    .padding(.vertical, Spacing.sm)
                }
                .onChange(of: manager.messages.count) { _, _ in
                    if let last = manager.messages.last { withAnimation { proxy.scrollTo(last.id, anchor: .bottom) } }
                }
            }
            inputBar
        }
    }

    private func bubble(_ msg: ChatMessage) -> some View {
        HStack {
            if msg.role == "user" { Spacer(minLength: 40) }
            Text(msg.content)
                .font(BulkUpFont.body())
                .foregroundColor(msg.role == "user" ? BulkUpColors.onAccent : BulkUpColors.textPrimary)
                .padding(10)
                .background(msg.role == "user" ? BulkUpColors.accent
                            : (msg.isError ? BulkUpColors.error.opacity(0.15) : BulkUpColors.surface))
                .clipShape(RoundedRectangle(cornerRadius: CornerRadius.medium))
            if msg.role == "assistant" { Spacer(minLength: 40) }
        }
    }

    private var inputBar: some View {
        HStack(spacing: Spacing.sm) {
            TextField("Escribe…", text: $input, axis: .vertical)
                .lineLimit(1...4)
                .padding(8)
                .background(BulkUpColors.surface)
                .clipShape(RoundedRectangle(cornerRadius: CornerRadius.medium))
            Button {
                let text = input; input = ""
                Task { await manager.send(text) }
            } label: {
                Image(systemName: "arrow.up.circle.fill").font(.title2)
                    .foregroundColor(BulkUpColors.accent)
            }
            .disabled(input.trimmingCharacters(in: .whitespaces).isEmpty || manager.isLoading)
        }
        .padding(Spacing.md)
        .background(BulkUpColors.background)
    }
}
```
If `SubscriptionRequiredView(title:subtitle:)` has a different init signature, match it (it was made with `LocalizedStringKey` params during the light-theme work — pass string literals, which coerce). If `TextField(_:text:axis:)` isn't available on the target, drop `axis:` and `.lineLimit`.

- [ ] **Step 2: Build + commit**

Run the iOS build command. Expected `BUILD SUCCEEDED`.
```bash
git add bulkup/Views/Components/Diet/RecipeChatView.swift
git commit -m "feat(diet): RecipeChatView chat UI with PRO gate"
```

### Task 6: Entry point on the meal card

**Files:** `bulkup/Views/Components/Diet/MealCardView.swift`.

- [ ] **Step 1: Add the button + sheet**

READ `MealCardView.swift` to find the `Meal` it renders and its options. Add `@State private var showingRecipeChat = false`. Add a small action (button) labeled `Label("Receta con IA", systemImage: "sparkles")` in the card (match existing button/row styling), and attach to a stable container:
```swift
            .sheet(isPresented: $showingRecipeChat) {
                RecipeChatView(
                    mealType: meal.type,
                    ingredients: Array(Set(meal.options.flatMap { $0.ingredients })).sorted()
                )
            }
```
Use the exact property name the view uses for the meal (likely `meal`) and `MealOption.ingredients` (a `[String]` computed property that already exists). If the card doesn't currently hold the full `Meal`, pass `meal.type` and the deduped ingredients from whatever meal data it has.

- [ ] **Step 2: Build + manual check**

Run the iOS build command (Expected `BUILD SUCCEEDED`). As a PRO user: open a meal → "Receta con IA" → ask for a recipe → get a reply respecting allergies/dislikes. As non-PRO: see the subscription gate.

- [ ] **Step 3: Commit**

```bash
git add bulkup/Views/Components/Diet/MealCardView.swift
git commit -m "feat(diet): 'Receta con IA' entry point on meal cards"
```

---

## Self-Review (completed during planning)

- **Spec coverage:** authenticated endpoint + server-side prefs + system prompt + Anthropic multi-turn → Tasks 1–2; iOS API call → Task 3; ephemeral multi-turn manager → Task 4; chat UI + PRO gate → Task 5; per-meal entry with selected-meal ingredients → Task 6; non-streaming (reply-at-once + "Pensando…") → Tasks 2/5; testing (gofmt + DEBUG self-check + manual) → Tasks 1/4/6. All spec sections mapped.
- **Placeholder scan:** real code in every code step; the "match existing names/init" notes are concrete verification instructions with fallbacks, not vague TODOs.
- **Type consistency:** `SendChat(systemPrompt, messages, model, maxTokens)`, `recipeChatRequest{mealType,ingredients,messages}`/`{reply}`, iOS `RecipeChatMessageDTO`/`recipeChat(mealType:ingredients:messages:)`, `RecipeChatManager(mealType:ingredients:)`/`send(_:)`/`ChatMessage{role,content,isError}`, and `RecipeChatView(mealType:ingredients:)` are consistent across tasks. Field names (`mealType`/`ingredients`/`messages`/`reply`) match between the Go request/response and the iOS Codables.
```
