# AI Recipe Chat — Design (Diet sub-project B)

**Date:** 2026-06-19
**Status:** Approved (design), pending implementation plan

## Context

Sub-project **B** of the diet effort. **A** (food preferences & allergies — shipped)
stores `allergies`/`likedFoods`/`dislikedFoods` on the user profile; B consumes them.
**C** (calorie-based fidelity) is later and independent.

## Goal

From a meal of the day, the user opens an AI chat that suggests recipes using that
meal's ingredients, **never** using their allergens, avoiding disliked foods and
preferring liked foods. Multi-turn, ephemeral, PRO-only.

## Decisions (from brainstorming)

- **Context:** the selected meal's ingredients (union of its options' ingredients)
  + the meal type. Preferences/allergies are loaded **server-side** from the
  profile (not trusted from the client).
- **Conversation:** multi-turn, **ephemeral** (not persisted anywhere).
- **Responses:** **non-streaming** (request → reply, with a "thinking" indicator).
  Streaming/SSE is a later enhancement.
- **Access:** **PRO-only** — gated client-side via `StoreKitManager.isSubscribed`
  (show `SubscriptionRequiredView` otherwise). Backend requires auth only.

## Architecture

### Backend — `POST /diet/recipe-chat` (authenticated)
- New handler with `AuthService` injected; validates `Authorization: Bearer <token>`
  (same pattern as the file/profile handlers) and derives the userId from the token.
- Request body: `{ "mealType": string, "ingredients": [string], "messages": [{"role": "user"|"assistant", "content": string}] }`.
- The handler **loads the user's profile** (`allergies`, `likedFoods`, `dislikedFoods`)
  from Mongo by the token's userId — the client never sends the allergy list (medical
  exclusion must be authoritative server-side).
- Builds a Spanish **system prompt**: a concise recipe/nutrition assistant that
  suggests recipes for `mealType` using primarily the provided `ingredients`; that
  **must never include** any of the user's allergens; avoids disliked foods; prefers
  liked foods; keeps replies concise; answers in the user's language.
- Calls `AnthropicClient` with the `messages` array (multi-turn) via a `SendChat`
  method (system prompt + messages + a chosen model/maxTokens) — add it alongside the
  existing `SendMessageWithModel` (which the request struct's `Messages []Message`
  already supports). Returns `{ "reply": string }`.
- Route registered in `internal/router/router.go`, handler built with
  `serviceContainer.AuthService` + the diet/profile service (whichever exposes the
  user lookup) + the `AnthropicClient`.

### iOS
- `APIService.recipeChat(mealType:ingredients:messages:) async throws -> String` —
  POSTs to `/diet/recipe-chat` with the Bearer token (existing auth header path),
  returns the assistant reply.
- `RecipeChatManager: ObservableObject` — `@Published var messages: [ChatMessage]`,
  `@Published var isLoading`, `func send(_ text:, mealType:, ingredients:)` that
  appends the user message, calls `recipeChat`, appends the assistant reply (or an
  error message). `ChatMessage { id, role, content }`. Ephemeral (a fresh manager per
  presentation; nothing persisted).
- `RecipeChatView` — chat UI: scrollable message bubbles (user vs assistant styled
  with the app palette `BulkUpColors`), a text input + send button, a "Pensando…"
  indicator while `isLoading`. Header names the meal. **PRO gate:** if
  `!StoreKitManager.isSubscribed`, render `SubscriptionRequiredView` (or the
  `premiumOverlay`) instead of the chat.
- **Entry point:** a "Receta con IA" button on each meal — in `MealCardView` (the
  per-meal card in the diet day view) — that presents `RecipeChatView` seeded with
  the meal's `type` and ingredients (union of `meal.options.flatMap(\.ingredients)`,
  deduped).

## Data Flow

1. User taps "Receta con IA" on a meal → if subscribed, present `RecipeChatView`
   with `mealType` + the meal's ingredients; else show the PRO gate.
2. User sends a message → `RecipeChatManager` appends it, POSTs `{ mealType,
   ingredients, messages }` → backend loads profile prefs, builds the system prompt,
   calls Anthropic with the full `messages` array → returns `reply`.
3. `RecipeChatManager` appends the assistant reply. Repeat for multi-turn.
4. On close, the manager (and its messages) are discarded — nothing saved.

## Error Handling / Edge Cases

- API/Anthropic failure → append a non-blocking assistant-style error bubble with a
  retry affordance; keep the conversation.
- Empty ingredients (meal has none) → allowed; the prompt falls back to suggesting
  by meal type within the dietary constraints.
- Missing profile prefs → treated as empty lists (no exclusions beyond the obvious).
- Allergens are a **hard** constraint in the prompt; we also state it explicitly so
  the model excludes them even if they appear in the meal's ingredients.
- Backend requires auth; cost is mitigated by the client PRO gate. (A server-side
  per-day message cap can be added later if direct-API abuse becomes a concern —
  noted, not in v1.)

## Testing

- Backend: can't build locally (tesseract/leptonica cgo) → `gofmt` the changed Go
  files. The prompt-assembly is the critical bit (allergens must appear as
  exclusions) — verify by reading + manual.
- iOS: no XCTest target → a `#if DEBUG` self-check for `RecipeChatManager`'s
  append/ordering logic (user message then assistant reply land in order; error path
  appends an error message). Manual: PRO user opens chat from a meal, asks for a
  recipe, gets a reply that respects allergies/dislikes; non-PRO sees the gate.

## Risks / Notes

- **Prompt quality** drives usefulness; the allergen-exclusion instruction must be
  unambiguous and server-authoritative.
- Spans both repos (backend endpoint + iOS); independently buildable but the iOS
  side needs the endpoint live to function end-to-end.
- Non-streaming means a visible wait per reply; acceptable for v1 (thinking
  indicator). Streaming is a future enhancement.
