# Diet Fidelity by Calories — Design (Diet sub-project C)

**Date:** 2026-06-19
**Status:** Approved (design), pending implementation plan

## Context

Sub-project **C** of the diet effort (A = food preferences ✅, B = AI recipe chat ✅,
both shipped). C is independent of A/B.

## Goal

Let a PRO user mark days they skipped the diet and describe what they ate; the AI
estimates the day's total calories; the app computes a **diet fidelity %** over the
last 30 days from how close each day's intake was to the plan's calorie target.

## Decisions (from brainstorming)

- **Calorie capture:** AI estimates total kcal from a free-text description of what
  was eaten (server-side Anthropic). No manual override.
- **Independent metric:** a NEW "Fidelidad por calorías" indicator; does NOT touch
  the existing completion-based compliance or `ProjectionCalculator`.
- **Window:** rolling **30 days**. Days with no skip-log count as **100%** (followed);
  skipped days score by kcal closeness; the average is the fidelity %.
- **Access:** **PRO-only** (client-side gate via `StoreKitManager.isSubscribed` →
  `SubscriptionRequiredView`). Backend requires auth.
- **Fidelity computed client-side** (iOS has the active plan's per-day `macroCalories`
  + the skipped-day logs); the backend stores logs + does the AI estimate.

## Fidelity formula

Day target kcal = sum of the active plan day's meals' `macroCalories` (match the
calendar date's weekday to the plan day using the Spanish-day-name folding used
elsewhere). For each of the last 30 calendar days:
- **No skip-log** → `dayFidelity = 1.0`.
- **Skip-log present** → `dayFidelity = max(0, 1 − |consumed − target| / target)`.
- **Target unknown or 0** (no plan that weekday / no calorie data) → the day is
  **excluded** from the average (closeness is unmeasurable).

`fidelityPercent = average(dayFidelity over included days) × 100`. If no day is
includable (e.g. no plan calories at all), fidelity is **unavailable** (UI shows
"—" / a hint to add calorie data), not 0.

## Architecture

### Backend — one new service + handler (authenticated)
- Mongo collection `diet_skipped_days`: `{ userId, date (yyyy-MM-dd), description,
  calories int, createdAt }`, unique on `(userId, date)`.
- `DietFidelityService` (or extend `MealTrackingService`): `LogSkippedDay`,
  `GetSkippedDays`, `DeleteSkippedDay`; uses `AnthropicClient` for the estimate.
- Handler `DietFidelityHandler` with `AuthService` (userId from token) + the service.
  Routes (in `router.go`):
  - `POST /diet/skipped-day` — body `{ date, description }`; estimates kcal via
    Anthropic (a strict prompt: "estima el total de kcal del día descrito; responde
    SOLO con un entero"), parses the integer, upserts, returns `{ date, description,
    calories }`.
  - `GET /diet/skipped-days?days=30` — list recent entries for the user.
  - `DELETE /diet/skipped-day?date=yyyy-MM-dd` — remove that day's entry.
- Calorie parsing: extract the first integer from the model's reply; if none, return
  an error (the client surfaces "no se pudo estimar").

### iOS
- `APIService`: `logSkippedDay(date:description:) async throws -> SkippedDay`,
  `getSkippedDays(days:) async throws -> [SkippedDay]`,
  `deleteSkippedDay(date:) async throws`. (`SkippedDay { date, description, calories }`.)
- `DietFidelityManager: ObservableObject` — `@Published skippedDays: [SkippedDay]`,
  `@Published isLoading`; `loadSkippedDays()`, `logSkippedDay(date:description:)`,
  `deleteSkippedDay(date:)`; a pure `fidelityPercent(plan:)` (or a computed using
  `DietManager.shared`) implementing the formula above.
- A pure helper `DietFidelity.percent(targetsByDate:[Date:Int?], skipped:[Date:Int], window:[Date]) -> Double?` so the formula is unit-checkable.
- UI (app style, **PRO-gated**):
  - "Fidelidad a la dieta" card (ring/number + last-30-days label) in the Diet
    section; if `!isSubscribed` → `SubscriptionRequiredView`.
  - "Registrar día saltado" sheet: `DatePicker` (default today, limited to the last
    30 days) + a description `TextField` + Save → calls `logSkippedDay` (shows the
    estimated kcal on return). A list of recent skipped days with swipe-to-delete.

## Data Flow

1. PRO user opens the diet fidelity card → `DietFidelityManager.loadSkippedDays()`
   fetches the last 30 days; fidelity % is computed from the active plan's per-day
   targets + the logs.
2. User logs a skipped day (date + description) → `POST /diet/skipped-day` →
   backend AI-estimates kcal, upserts → returns the entry → manager refreshes →
   fidelity recomputes.
3. Delete a day → `DELETE` → refresh → recompute.

## Error Handling / Edge Cases

- AI/network failure → non-blocking error + retry; the log isn't saved.
- AI returns no parseable integer → backend 422-ish error; client shows "no se pudo
  estimar las calorías".
- Plan target unknown for a day → that day excluded from the average (UI may note
  "algunos días sin datos de calorías del plan").
- No includable days → fidelity unavailable ("—"), not 0%.
- Division-by-zero avoided (target 0 ⇒ excluded).
- Re-logging the same date upserts (replaces).

## Testing

- Backend: can't build locally (tesseract cgo) → `gofmt`, AND carefully review Go
  semantics gofmt misses (redeclared `:=`, unused vars/imports) — a compile bug like
  that already broke a deploy once.
- iOS: no XCTest target → `#if DEBUG` self-check for `DietFidelity.percent(...)`:
  no-log day = 1.0; exact target = 1.0; double target = 0.0; unknown target excluded;
  empty window / all-unknown ⇒ nil. Manual: PRO user logs a skipped day, sees an
  estimate, the fidelity % updates; delete updates it; non-PRO sees the gate.

## Risks / Notes

- **AI estimate accuracy** is approximate; the % is indicative, not precise. The UI
  should frame it as an estimate.
- Reuses the day-name matching logic — keep using the Spanish-folded weekday match
  (don't reintroduce the locale-formatter bug fixed earlier).
- Spans both repos; iOS needs the endpoint live + `ANTHROPIC_API_KEY` to estimate.
- Backend cost mitigated by the client PRO gate; a per-day server cap is a noted
  follow-up.
