# Diet Fidelity by Calories Implementation Plan (Diet sub-project C)

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** PRO users mark skipped diet days + describe what they ate; the AI estimates the day's kcal; the app shows a 30-day diet-fidelity % from how close each day's intake was to the plan's calorie target.

**Architecture:** New authenticated backend endpoints store skipped-day logs (Mongo) and estimate kcal via Anthropic. iOS fetches the logs and computes fidelity client-side from `DietManager`'s active-plan per-day `macroCalories`. PRO-gated client-side; independent of the existing compliance/projections.

**Tech Stack:** Go (mux + MongoDB + Anthropic), SwiftUI, existing `APIService`/`DietManager`/`StoreKitManager`.

**Verification:** Backend can't build locally (tesseract cgo) → `gofmt` **and** manual Go-semantics review (redeclared `:=`, unused vars/imports — a compile bug like that already broke a deploy). iOS no XCTest → build + a `#if DEBUG` self-check for the pure fidelity calc + manual. Do NOT add a test target.

**iOS build command:**
```bash
cd /Users/sebastian.blanco/Documents/Sebas/bulkup
xcodebuild -scheme bulkup-Dev -destination 'generic/platform=iOS Simulator' build CODE_SIGNING_ALLOWED=NO 2>&1 | grep -E "error:|BUILD SUCCEEDED|BUILD FAILED"
```

**Field contract:** `SkippedDay { date (yyyy-MM-dd string), description string, calories int }`.

---

## File Structure

- Backend `internal/models/diet_skipped_day.go` (new) — `SkippedDay` model.
- Backend `internal/services/diet_fidelity.go` (new) — `DietFidelityService` (Mongo CRUD + AI estimate).
- Backend `internal/handlers/diet_fidelity.go` (new) — `DietFidelityHandler` (auth + service).
- Backend `internal/services/container.go` — construct + expose `DietFidelityService`.
- Backend `internal/router/router.go` — 3 routes.
- iOS `bulkup/Services/APIService+Extensions.swift` — `SkippedDay` + 3 calls.
- iOS `bulkup/ViewModels/DietFidelityManager.swift` (new) — manager + pure `DietFidelity` calc + self-check.
- iOS `bulkup/Views/Components/Diet/DietFidelityView.swift` (new) — card + log sheet + list (PRO-gated).
- iOS `bulkup/Views/Components/Diet/DietHubView.swift` — entry point.

---

## PHASE 1 — Backend

### Task 1: SkippedDay model

**Files:** Create `internal/models/diet_skipped_day.go`. Repo: `/Users/sebastian.blanco/Documents/Sebas/weight-tracker-backend`.

- [ ] **Step 1: Write the model**
```go
package models

import "time"

type SkippedDay struct {
	UserID      string    `bson:"userId" json:"-"`
	Date        string    `bson:"date" json:"date"` // yyyy-MM-dd
	Description string    `bson:"description" json:"description"`
	Calories    int       `bson:"calories" json:"calories"`
	CreatedAt   time.Time `bson:"createdAt" json:"-"`
}
```

- [ ] **Step 2: gofmt + commit**
```bash
cd /Users/sebastian.blanco/Documents/Sebas/weight-tracker-backend
gofmt -l internal/models/diet_skipped_day.go   # expect no output
git add internal/models/diet_skipped_day.go
git commit -m "feat(diet): SkippedDay model"
```

### Task 2: DietFidelityService

**Files:** Create `internal/services/diet_fidelity.go`.

- [ ] **Step 1: Write the service**

Mirror `MealTrackingService` for the Mongo collection style (`db.Collection(...)`, `context.Background()`).
```go
package services

import (
	"context"
	"fmt"
	"regexp"
	"strconv"
	"time"

	"fitness-api/internal/models"

	"go.mongodb.org/mongo-driver/bson"
	"go.mongodb.org/mongo-driver/mongo"
	"go.mongodb.org/mongo-driver/mongo/options"
)

type DietFidelityService struct {
	db        *mongo.Database
	anthropic *AnthropicClient
}

func NewDietFidelityService(db *mongo.Database, anthropic *AnthropicClient) *DietFidelityService {
	return &DietFidelityService{db: db, anthropic: anthropic}
}

func (s *DietFidelityService) collection() *mongo.Collection {
	return s.db.Collection("diet_skipped_days")
}

var caloriesRe = regexp.MustCompile(`\d+`)

// estimateCalories asks the model for an integer kcal total for the description.
func (s *DietFidelityService) estimateCalories(description string) (int, error) {
	if s.anthropic == nil || !s.anthropic.IsConfigured() {
		return 0, fmt.Errorf("servicio de IA no disponible")
	}
	system := "Eres un nutricionista. Estima el total de kilocalorías (kcal) de lo que describe el usuario que comió en un día. Responde SOLO con un número entero, sin texto ni unidades."
	resp, err := s.anthropic.SendChat(system, []Message{{Role: "user", Content: description}}, ModelHaiku, 64)
	if err != nil {
		return 0, err
	}
	if len(resp.Content) == 0 {
		return 0, fmt.Errorf("respuesta vacía")
	}
	match := caloriesRe.FindString(resp.Content[0].Text)
	if match == "" {
		return 0, fmt.Errorf("no se pudo estimar las calorías")
	}
	return strconv.Atoi(match)
}

func (s *DietFidelityService) LogSkippedDay(userID, date, description string) (*models.SkippedDay, error) {
	calories, err := s.estimateCalories(description)
	if err != nil {
		return nil, err
	}
	entry := models.SkippedDay{
		UserID: userID, Date: date, Description: description,
		Calories: calories, CreatedAt: time.Now(),
	}
	_, err = s.collection().UpdateOne(
		context.Background(),
		bson.M{"userId": userID, "date": date},
		bson.M{"$set": entry},
		options.Update().SetUpsert(true),
	)
	if err != nil {
		return nil, err
	}
	return &entry, nil
}

func (s *DietFidelityService) GetSkippedDays(userID string, days int) ([]models.SkippedDay, error) {
	cutoff := time.Now().AddDate(0, 0, -days).Format("2006-01-02")
	cur, err := s.collection().Find(
		context.Background(),
		bson.M{"userId": userID, "date": bson.M{"$gte": cutoff}},
		options.Find().SetSort(bson.M{"date": -1}),
	)
	if err != nil {
		return nil, err
	}
	defer cur.Close(context.Background())
	out := []models.SkippedDay{}
	if err := cur.All(context.Background(), &out); err != nil {
		return nil, err
	}
	return out, nil
}

func (s *DietFidelityService) DeleteSkippedDay(userID, date string) error {
	_, err := s.collection().DeleteOne(context.Background(), bson.M{"userId": userID, "date": date})
	return err
}
```
NOTE: confirm `ModelHaiku`, `Message{Role,Content}`, `SendChat`, `AnthropicResponse.Content[].Text` names match `anthropic.go` (they were added in sub-project B). Check the mongo driver import paths match what other services use.

- [ ] **Step 2: gofmt + Go-semantics review + commit**

`gofmt -l internal/services/diet_fidelity.go` (expect clean). Re-read for `:=`/unused-import issues (`regexp`, `strconv`, `options` all used). Commit:
```bash
git add internal/services/diet_fidelity.go
git commit -m "feat(diet): DietFidelityService (skipped-day CRUD + AI kcal estimate)"
```

### Task 3: Handler + container + routes

**Files:** Create `internal/handlers/diet_fidelity.go`; modify `internal/services/container.go`, `internal/router/router.go`.

- [ ] **Step 1: Handler**
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

type DietFidelityHandler struct {
	authService *services.AuthService
	service     *services.DietFidelityService
}

func NewDietFidelityHandler(a *services.AuthService, s *services.DietFidelityService) *DietFidelityHandler {
	return &DietFidelityHandler{authService: a, service: s}
}

func (h *DietFidelityHandler) getUserFromRequest(r *http.Request) (string, error) {
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

func (h *DietFidelityHandler) SkippedDays(w http.ResponseWriter, r *http.Request) {
	utils.SetCORSHeaders(w, r)
	if r.Method == "OPTIONS" {
		w.WriteHeader(http.StatusOK)
		return
	}
	userID, err := h.getUserFromRequest(r)
	if err != nil {
		utils.RespondWithError(w, r, http.StatusUnauthorized, err.Error())
		return
	}

	switch r.Method {
	case http.MethodPost:
		var body struct {
			Date        string `json:"date"`
			Description string `json:"description"`
		}
		if err := json.NewDecoder(r.Body).Decode(&body); err != nil || body.Date == "" || body.Description == "" {
			utils.RespondWithError(w, r, http.StatusBadRequest, "date y description requeridos")
			return
		}
		entry, err := h.service.LogSkippedDay(userID, body.Date, body.Description)
		if err != nil {
			utils.RespondWithError(w, r, http.StatusInternalServerError, err.Error())
			return
		}
		w.Header().Set("Content-Type", "application/json")
		json.NewEncoder(w).Encode(entry)

	case http.MethodGet:
		days := 30
		entries, err := h.service.GetSkippedDays(userID, days)
		if err != nil {
			utils.RespondWithError(w, r, http.StatusInternalServerError, err.Error())
			return
		}
		w.Header().Set("Content-Type", "application/json")
		json.NewEncoder(w).Encode(map[string]interface{}{"skippedDays": entries})

	case http.MethodDelete:
		date := r.URL.Query().Get("date")
		if date == "" {
			utils.RespondWithError(w, r, http.StatusBadRequest, "date requerido")
			return
		}
		if err := h.service.DeleteSkippedDay(userID, date); err != nil {
			utils.RespondWithError(w, r, http.StatusInternalServerError, err.Error())
			return
		}
		w.WriteHeader(http.StatusOK)
		json.NewEncoder(w).Encode(map[string]bool{"success": true})

	default:
		utils.RespondWithError(w, r, http.StatusMethodNotAllowed, "Método no permitido")
	}
}
```

- [ ] **Step 2: Container**

In `internal/services/container.go`: add field `DietFidelityService *DietFidelityService`; in the constructor (where `anthropicClient` and `db` exist) add `dietFidelityService := NewDietFidelityService(db, anthropicClient)` and set it in the returned `&Container{... DietFidelityService: dietFidelityService}`.

- [ ] **Step 3: Routes**

In `internal/router/router.go`, near the diet routes:
```go
	dietFidelityHandler := handlers.NewDietFidelityHandler(serviceContainer.AuthService, serviceContainer.DietFidelityService)
	r.HandleFunc("/diet/skipped-day", dietFidelityHandler.SkippedDays).Methods("POST", "DELETE", "OPTIONS")
	r.HandleFunc("/diet/skipped-days", dietFidelityHandler.SkippedDays).Methods("GET", "OPTIONS")
```
(Both paths route to the one method-switching handler.)

- [ ] **Step 4: gofmt + review + commit**
```bash
gofmt -l internal/handlers/diet_fidelity.go internal/services/container.go internal/router/router.go   # expect clean
```
Review Go semantics (no redeclared `:=`, all imports used). Commit:
```bash
git add internal/handlers/diet_fidelity.go internal/services/container.go internal/router/router.go
git commit -m "feat(diet): skipped-day endpoints (POST/GET/DELETE) + container wiring"
```

---

## PHASE 2 — iOS

### Task 4: APIService methods

**Files:** `bulkup/Services/APIService+Extensions.swift`.

- [ ] **Step 1: Add model + calls**

READ an existing GET+POST+DELETE in the file to match style/auth. Add:
```swift
struct SkippedDay: Codable, Identifiable {
    var id: String { date }
    let date: String
    let description: String
    let calories: Int
}
private struct SkippedDaysResponse: Codable { let skippedDays: [SkippedDay] }
private struct LogSkippedDayBody: Codable { let date: String; let description: String }

extension APIService {
    private func authedRequest(_ path: String, method: String) -> URLRequest? {
        guard let url = URL(string: "\(APIConfig.baseURL)\(path)") else { return nil }
        var r = URLRequest(url: url)
        r.httpMethod = method
        r.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let token = UserDefaults.standard.string(forKey: "auth_token") {
            r.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        return r
    }

    func logSkippedDay(date: String, description: String) async throws -> SkippedDay {
        guard var req = authedRequest("/diet/skipped-day", method: "POST") else { throw APIError.invalidURL }
        req.httpBody = try JSONEncoder().encode(LogSkippedDayBody(date: date, description: description))
        let (data, resp) = try await URLSession.shared.data(for: req)
        guard let h = resp as? HTTPURLResponse, h.statusCode == 200 else {
            throw APIError.serverError((resp as? HTTPURLResponse)?.statusCode ?? 0)
        }
        return try JSONDecoder().decode(SkippedDay.self, from: data)
    }

    func getSkippedDays() async throws -> [SkippedDay] {
        guard let req = authedRequest("/diet/skipped-days", method: "GET") else { throw APIError.invalidURL }
        let (data, resp) = try await URLSession.shared.data(for: req)
        guard let h = resp as? HTTPURLResponse, h.statusCode == 200 else {
            throw APIError.serverError((resp as? HTTPURLResponse)?.statusCode ?? 0)
        }
        return try JSONDecoder().decode(SkippedDaysResponse.self, from: data).skippedDays
    }

    func deleteSkippedDay(date: String) async throws {
        guard let req = authedRequest("/diet/skipped-day?date=\(date)", method: "DELETE") else { throw APIError.invalidURL }
        let (_, resp) = try await URLSession.shared.data(for: req)
        guard let h = resp as? HTTPURLResponse, h.statusCode == 200 else {
            throw APIError.serverError((resp as? HTTPURLResponse)?.statusCode ?? 0)
        }
    }
}
```
Use the ACTUAL `APIError` cases that exist (match `recipeChat`'s usage of `invalidURL`/`serverError`). If an `authedRequest`-like helper already exists in the file, reuse it instead of adding a private one.

- [ ] **Step 2: Build + commit**

iOS build command → `BUILD SUCCEEDED`.
```bash
git add bulkup/Services/APIService+Extensions.swift
git commit -m "feat(diet): APIService skipped-day calls"
```

### Task 5: DietFidelityManager + pure calc + self-check

**Files:** Create `bulkup/ViewModels/DietFidelityManager.swift`. Modify `bulkup/App/BulkUp.swift`.

- [ ] **Step 1: Pure calc + manager**
```swift
import Foundation

enum DietFidelity {
    /// window: the calendar days to average. consumed[day] = logged kcal for skipped days.
    /// target(day) = plan kcal target for that day (nil/0 → can't score a *logged* day → excluded).
    /// A day with no log counts as 1.0 (followed). Returns percent 0–100, or nil if no includable day.
    static func percent(window: [Date], consumed: [Date: Int], target: (Date) -> Int?) -> Double? {
        var sum = 0.0
        var n = 0
        for day in window {
            if let c = consumed[day] {
                guard let t = target(day), t > 0 else { continue } // logged day, unknown target → exclude
                sum += max(0.0, 1.0 - abs(Double(c) - Double(t)) / Double(t))
                n += 1
            } else {
                sum += 1.0   // no log → followed
                n += 1
            }
        }
        return n == 0 ? nil : (sum / Double(n)) * 100.0
    }

    #if DEBUG
    static func runSelfCheck() {
        let cal = Calendar(identifier: .gregorian)
        let d0 = cal.startOfDay(for: Date())
        let d1 = cal.date(byAdding: .day, value: -1, to: d0)!
        // no logs → 100
        assert(percent(window: [d0, d1], consumed: [:], target: { _ in 2000 }) == 100)
        // exact target on a logged day → 100
        assert(percent(window: [d0], consumed: [d0: 2000], target: { _ in 2000 }) == 100)
        // double target → 0
        assert(percent(window: [d0], consumed: [d0: 4000], target: { _ in 2000 }) == 0)
        // logged day, unknown target → excluded; only day → nil
        assert(percent(window: [d0], consumed: [d0: 4000], target: { _ in nil }) == nil)
    }
    #endif
}

@MainActor
final class DietFidelityManager: ObservableObject {
    static let shared = DietFidelityManager()
    @Published var skippedDays: [SkippedDay] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let api = APIService.shared

    private static let ymd: DateFormatter = {
        let f = DateFormatter(); f.locale = Locale(identifier: "en_US_POSIX"); f.dateFormat = "yyyy-MM-dd"; return f
    }()
    // Spanish weekday for matching the plan day (fixed es locale — NOT the app locale).
    private static let weekday: DateFormatter = {
        let f = DateFormatter(); f.locale = Locale(identifier: "es_ES"); f.dateFormat = "EEEE"; return f
    }()

    func load() async {
        isLoading = true; defer { isLoading = false }
        do { skippedDays = try await api.getSkippedDays() }
        catch { errorMessage = "No se pudieron cargar los días" }
    }

    func logSkippedDay(date: Date, description: String) async -> Bool {
        do {
            let entry = try await api.logSkippedDay(date: Self.ymd.string(from: date), description: description)
            skippedDays.removeAll { $0.date == entry.date }
            skippedDays.insert(entry, at: 0)
            return true
        } catch { errorMessage = "No se pudo estimar las calorías"; return false }
    }

    func deleteSkippedDay(_ day: SkippedDay) async {
        do { try await api.deleteSkippedDay(date: day.date); skippedDays.removeAll { $0.date == day.date } }
        catch { errorMessage = "No se pudo eliminar" }
    }

    /// 30-day fidelity using the active plan (DietManager) day targets.
    func fidelityPercent(dietData: [DietDay]) -> Double? {
        let cal = Calendar(identifier: .gregorian)
        let today = cal.startOfDay(for: Date())
        let window = (0..<30).compactMap { cal.date(byAdding: .day, value: -$0, to: today) }
        var consumed: [Date: Int] = [:]
        for s in skippedDays {
            if let d = Self.ymd.date(from: s.date) { consumed[cal.startOfDay(for: d)] = s.calories }
        }
        func norm(_ s: String) -> String { s.lowercased().folding(options: .diacriticInsensitive, locale: .current) }
        return DietFidelity.percent(window: window, consumed: consumed) { day in
            let wd = norm(Self.weekday.string(from: day))
            guard let match = dietData.first(where: { norm($0.day) == wd }) else { return nil }
            return match.macroCalories
        }
    }
}
```

- [ ] **Step 2: Self-check at launch**

In `bulkup/App/BulkUp.swift` `init()`, inside the existing `#if DEBUG` block, add `DietFidelity.runSelfCheck()`.

- [ ] **Step 3: Build + run (debug) + commit**

iOS build → `BUILD SUCCEEDED`; launch in sim → no assertion failure. Commit:
```bash
git add bulkup/ViewModels/DietFidelityManager.swift bulkup/App/BulkUp.swift
git commit -m "feat(diet): DietFidelityManager + pure fidelity calc + self-check"
```

### Task 6: DietFidelityView (card + log sheet + list, PRO-gated)

**Files:** Create `bulkup/Views/Components/Diet/DietFidelityView.swift`.

- [ ] **Step 1: Implement the view**
```swift
import SwiftUI

struct DietFidelityView: View {
    @ObservedObject private var manager = DietFidelityManager.shared
    @ObservedObject private var dietManager = DietManager.shared
    @ObservedObject private var store = StoreKitManager.shared
    @State private var showingLog = false
    @State private var showingSubscription = false

    var body: some View {
        Group {
            if store.isSubscribed {
                content
            } else {
                Button { showingSubscription = true } label: {
                    Label("Fidelidad a la dieta (PRO)", systemImage: "chart.pie.fill")
                        .font(BulkUpFont.cardTitle()).foregroundColor(BulkUpColors.textPrimary)
                        .frame(maxWidth: .infinity).padding().background(BulkUpColors.surface)
                        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.large))
                }
                .sheet(isPresented: $showingSubscription) { SubscriptionView() }
            }
        }
        .task { if store.isSubscribed { await manager.load() } }
    }

    private var content: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack {
                Text("Fidelidad a la dieta").font(BulkUpFont.cardTitle()).foregroundColor(BulkUpColors.textPrimary)
                Spacer()
                Button { showingLog = true } label: { Image(systemName: "plus.circle.fill").foregroundColor(BulkUpColors.accent) }
            }
            if let pct = manager.fidelityPercent(dietData: dietManager.dietData) {
                Text("\(Int(pct.rounded()))%").font(BulkUpFont.heroStat()).foregroundColor(BulkUpColors.accent)
                Text("últimos 30 días").font(BulkUpFont.caption()).foregroundColor(BulkUpColors.textSecondary)
            } else {
                Text("—").font(BulkUpFont.heroStat()).foregroundColor(BulkUpColors.textSecondary)
                Text("Registra días o añade calorías al plan").font(BulkUpFont.caption()).foregroundColor(BulkUpColors.textSecondary)
            }
            if !manager.skippedDays.isEmpty {
                ForEach(manager.skippedDays) { day in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(day.date).font(BulkUpFont.body()).foregroundColor(BulkUpColors.textPrimary)
                            Text(day.description).font(BulkUpFont.caption()).foregroundColor(BulkUpColors.textSecondary).lineLimit(1)
                        }
                        Spacer()
                        Text("\(day.calories) kcal").font(BulkUpFont.caption()).foregroundColor(BulkUpColors.textSecondary)
                        Button { Task { await manager.deleteSkippedDay(day) } } label: {
                            Image(systemName: "trash").foregroundColor(BulkUpColors.error)
                        }
                    }
                }
            }
        }
        .padding().background(BulkUpColors.surface).clipShape(RoundedRectangle(cornerRadius: CornerRadius.large))
        .sheet(isPresented: $showingLog) { LogSkippedDayView() }
    }
}

private struct LogSkippedDayView: View {
    @ObservedObject private var manager = DietFidelityManager.shared
    @Environment(\.dismiss) private var dismiss
    @State private var date = Date()
    @State private var description = ""
    @State private var saving = false

    var body: some View {
        NavigationStack {
            Form {
                DatePicker("Día", selection: $date, in: ...Date(), displayedComponents: .date)
                Section("¿Qué comiste?") {
                    TextField("Ej: pizza familiar y 2 cervezas", text: $description, axis: .vertical).lineLimit(2...5)
                }
            }
            .navigationTitle("Día saltado")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancelar") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button(saving ? "Estimando…" : "Guardar") {
                        saving = true
                        Task { let ok = await manager.logSkippedDay(date: date, description: description); saving = false; if ok { dismiss() } }
                    }.disabled(description.trimmingCharacters(in: .whitespaces).isEmpty || saving)
                }
            }
        }
    }
}
```
Match real APIs: `SubscriptionView()` exists; `BulkUpFont.heroStat()`/`cardTitle()`/`body()`/`caption()`, `Spacing`, `CornerRadius`, `BulkUpColors` exist. If `TextField(_:text:axis:)` isn't available, drop `axis:`/`lineLimit`.

- [ ] **Step 2: Build + commit**

iOS build → `BUILD SUCCEEDED`.
```bash
git add bulkup/Views/Components/Diet/DietFidelityView.swift
git commit -m "feat(diet): DietFidelityView (card + skipped-day log + list, PRO-gated)"
```

### Task 7: Entry point in the diet section

**Files:** `bulkup/Views/Components/Diet/DietHubView.swift`.

- [ ] **Step 1: Place the card**

READ `DietHubView.swift`. In the active-plan content (where the diet day content renders), insert `DietFidelityView()` as a section/card (match surrounding padding/layout — e.g. above or below the plan header). It self-gates on PRO and self-loads, so just place it.

- [ ] **Step 2: Build + manual check**

iOS build → `BUILD SUCCEEDED`. As a PRO user: the card shows a % (or "—"); tap + → log a skipped day (date + description) → see kcal estimate → % updates; delete updates it. Non-PRO sees the locked card → SubscriptionView.

- [ ] **Step 3: Commit**
```bash
git add bulkup/Views/Components/Diet/DietHubView.swift
git commit -m "feat(diet): surface diet-fidelity card in the diet hub"
```

---

## Self-Review (completed during planning)

- **Spec coverage:** skipped-day storage + AI estimate → Tasks 1–3; 30-day formula (no-log=1.0, closeness, unknown-target excluded, nil when none) → Task 5 `DietFidelity.percent` + self-check; PRO gate → Task 6; card + log + delete UI → Tasks 6–7; independent of compliance/projections (nothing touches them) ✓; day target = `DietDay.macroCalories` matched by Spanish weekday (fixed es locale, not app locale) → Task 5. All spec sections mapped.
- **Placeholder scan:** real code in every step; "match existing names" notes are concrete verification instructions with fallbacks.
- **Type consistency:** `SkippedDay{date,description,calories}` matches Go `models.SkippedDay` json tags and the iOS Codable; `DietFidelity.percent(window:consumed:target:)`, `DietFidelityManager.fidelityPercent(dietData:)`/`logSkippedDay(date:description:)`/`deleteSkippedDay(_:)`, and the endpoints (`POST/DELETE /diet/skipped-day`, `GET /diet/skipped-days`) line up across backend + iOS. `DietDay.macroCalories` and `DietManager.dietData` are the real names.
