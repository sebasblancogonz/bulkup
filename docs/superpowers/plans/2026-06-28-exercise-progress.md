# Exercise Progress (A) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development. Steps use checkbox (`- [ ]`) syntax. **Spans TWO repos** — Task 1 is in `weight-tracker-backend` (own branch/PR, lands first, `go build`-verifiable). Tasks 2–4 are in `bulkup` (iOS, NOT buildable here → code review + DEBUG `runSelfCheck()`; user builds in Xcode).

**Goal:** A per-exercise progress view (tap an exercise in the plan → its detail) charting top-set weight, volume, estimated 1RM, and detected PRs over the weeks the athlete has logged.

**Architecture:** A new backend read endpoint returns all weekly `WeightRecord`s for a `(userId, planId)`; the iOS app filters them to one exercise, computes per-week metrics with pure functions (reusing `RMManager.calculateHybridRM`), and renders SwiftUI `Charts`.

**Tech Stack:** Go + MongoDB (backend); SwiftUI + Charts (iOS).

## Global Constraints
- Two repos: backend `/Users/sebastian.blanco/Documents/Sebas/weight-tracker-backend` (build with `CGO_CFLAGS="-I/opt/homebrew/include" CGO_CXXFLAGS="-I/opt/homebrew/include" CGO_CPPFLAGS="-I/opt/homebrew/include" CGO_LDFLAGS="-L/opt/homebrew/lib" go build ./...`); app `/Users/sebastian.blanco/Documents/Sebas/bulkup` (iOS, NOT buildable here).
- Read-only feature: no new data capture; reuses existing `WeightRecord`s.
- Representative weekly weight = **top set** (max). Metrics: top-set weight, volume (Σ weight×reps), estimated 1RM (`RMManager.calculateHybridRM(weight:reps:)`), PR detection (a week beats all earlier weeks).
- Does NOT touch the manual 1RM tracker (`RMManager` PersonalRecords).
- `weekStart` is the progression key, formatted `"yyyy-MM-dd"` end-to-end.
- iOS test convention: DEBUG `static func runSelfCheck()` wired into `bulkup/App/BulkUp.swift`. SourceKit cross-file errors here are spurious.

---

## Task 1: [BACKEND] `/load-weight-history` endpoint

**Repo:** `weight-tracker-backend`. Own branch `feat/weight-history`, own PR (lands first).

**Files:**
- Modify: `internal/models/weight.go` (add request + item + response types)
- Modify: `internal/services/weight.go` (add `LoadWeightHistory`)
- Modify: `internal/handlers/weights.go` (add `LoadWeightHistory`)
- Modify: `internal/router/router.go:56` (register route)

**Interfaces:**
- Produces: `POST /load-weight-history` `{userId, planId}` → `APIResponse{ data: { records: [{weekStart, day, exerciseName, exerciseIndex, sets, planId}], totalRecords } }`

- [ ] **Step 1: Branch**
```bash
cd /Users/sebastian.blanco/Documents/Sebas/weight-tracker-backend && git checkout -b feat/weight-history
```

- [ ] **Step 2: Add model types** — in `internal/models/weight.go`, after `LoadWeightRequest` (line 62):
```go
type LoadWeightHistoryRequest struct {
	UserID string `json:"userId"`
	PlanID string `json:"planId,omitempty"`
}

type WeightHistoryItem struct {
	WeekStart     string `json:"weekStart"` // "2006-01-02"
	Day           string `json:"day"`
	ExerciseName  string `json:"exerciseName"`
	ExerciseIndex int    `json:"exerciseIndex"`
	Sets          []Set  `json:"sets"`
	PlanID        string `json:"planId,omitempty"`
}

type WeightHistoryResponse struct {
	Records      []WeightHistoryItem `json:"records"`
	TotalRecords int                 `json:"totalRecords"`
	Message      string              `json:"message"`
}
```

- [ ] **Step 3: Add the service** — in `internal/services/weight.go`, after `LoadWeights` (ends ~line 160), add:
```go
func (s *WeightService) LoadWeightHistory(req models.LoadWeightHistoryRequest) (*models.WeightHistoryResponse, error) {
	filter := bson.M{"userId": req.UserID}
	if req.PlanID != "" {
		filter["planId"] = req.PlanID
	}
	cursor, err := s.db.Collection("weight_records").Find(s.ctx, filter)
	if err != nil {
		return nil, fmt.Errorf("error buscando registros: %v", err)
	}
	defer cursor.Close(s.ctx)

	var records []models.WeightRecord
	if err = cursor.All(s.ctx, &records); err != nil {
		return nil, fmt.Errorf("error decodificando registros: %v", err)
	}

	// Keep the most recent record per (weekStart, day, exerciseName, exerciseIndex).
	latest := make(map[string]models.WeightRecord)
	for _, r := range records {
		key := fmt.Sprintf("%s-%s-%s-%d", r.WeekStart.Format("2006-01-02"), r.Day, r.ExerciseName, r.ExerciseIndex)
		if existing, ok := latest[key]; !ok || r.RecordDate.After(existing.RecordDate) {
			latest[key] = r
		}
	}

	items := make([]models.WeightHistoryItem, 0, len(latest))
	for _, r := range latest {
		sets := r.Sets
		sort.Slice(sets, func(i, j int) bool { return sets[i].SetNumber < sets[j].SetNumber })
		items = append(items, models.WeightHistoryItem{
			WeekStart:     r.WeekStart.Format("2006-01-02"),
			Day:           r.Day,
			ExerciseName:  r.ExerciseName,
			ExerciseIndex: r.ExerciseIndex,
			Sets:          sets,
			PlanID:        r.PlanID,
		})
	}
	sort.Slice(items, func(i, j int) bool { return items[i].WeekStart < items[j].WeekStart })

	msg := "Histórico cargado correctamente"
	if len(items) == 0 {
		msg = "No hay histórico para este plan"
	}
	return &models.WeightHistoryResponse{Records: items, TotalRecords: len(items), Message: msg}, nil
}
```

- [ ] **Step 4: Add the handler** — in `internal/handlers/weights.go`, after `LoadWeights`, add (mirrors it):
```go
func (h *WeightHandler) LoadWeightHistory(w http.ResponseWriter, r *http.Request) {
	if r.Method == "OPTIONS" {
		utils.SetCORSHeaders(w, r)
		w.WriteHeader(http.StatusOK)
		return
	}
	utils.SetCORSHeaders(w, r)

	var req models.LoadWeightHistoryRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		json.NewEncoder(w).Encode(utils.APIResponse{Success: false, Error: "Invalid request body"})
		return
	}
	if req.UserID == "" {
		json.NewEncoder(w).Encode(utils.APIResponse{Success: false, Error: "userId es requerido"})
		return
	}
	response, err := h.weightService.LoadWeightHistory(req)
	if err != nil {
		utils.RespondWithError(w, r, http.StatusInternalServerError, err.Error())
		return
	}
	json.NewEncoder(w).Encode(utils.APIResponse{Success: true, Data: response})
}
```

- [ ] **Step 5: Register the route** — in `internal/router/router.go`, after line 56 (`/load-weights`):
```go
	r.HandleFunc("/load-weight-history", weightHandler.LoadWeightHistory).Methods("POST", "OPTIONS")
```

- [ ] **Step 6: Build**
Run: `cd /Users/sebastian.blanco/Documents/Sebas/weight-tracker-backend && CGO_CFLAGS="-I/opt/homebrew/include" CGO_CXXFLAGS="-I/opt/homebrew/include" CGO_CPPFLAGS="-I/opt/homebrew/include" CGO_LDFLAGS="-L/opt/homebrew/lib" go build ./...`
Expected: no output (success).

- [ ] **Step 7: Commit**
```bash
git add internal/models/weight.go internal/services/weight.go internal/handlers/weights.go internal/router/router.go
git commit -m "feat(weights): /load-weight-history — all weekly records for a plan"
```

---

## Task 2: [iOS] history API types + `loadWeightHistory`

**Repo:** `bulkup` (branch `feat/exercise-progress`).

**Files:**
- Modify: `bulkup/Models/APIModels.swift` (after `ServerWeightRecord`, ~line 557)
- Modify: `bulkup/Services/APIService+Extensions.swift` (after `loadWeights`, ~line 185)

**Interfaces:**
- Consumes: backend `/load-weight-history` (Task 1)
- Produces: `ServerWeightHistoryItem`; `APIService.loadWeightHistory(userId:planId:) async throws -> [ServerWeightHistoryItem]`

- [ ] **Step 1: Add the response types** — in `bulkup/Models/APIModels.swift`, after `ServerWeightRecord` (before `LoadWeightsOuterResponse`):
```swift
struct ServerWeightHistoryItem: Codable {
    let weekStart: String          // "yyyy-MM-dd" — the progression key
    let day: String
    let exerciseName: String
    let exerciseIndex: Int
    let sets: [ServerWeightSet]?
    let planId: String?
}

struct WeightHistoryResponse: Codable {
    let records: [ServerWeightHistoryItem]?
}

struct WeightHistoryOuterResponse: Codable {
    let success: Bool
    let data: WeightHistoryResponse
}
```

- [ ] **Step 2: Add the API call** — in `bulkup/Services/APIService+Extensions.swift`, after `loadWeights(userId:weekStart:)`:
```swift
    func loadWeightHistory(userId: String, planId: String) async throws -> [ServerWeightHistoryItem] {
        let requestBody = ["userId": userId, "planId": planId]
        let outer: WeightHistoryOuterResponse = try await requestWithBody(
            endpoint: "load-weight-history",
            method: .POST,
            body: requestBody
        )
        return outer.data.records ?? []
    }
```

- [ ] **Step 3: Verify** — user builds the iOS app (compiles). Agent: confirm the types match the backend JSON (weekStart string; sets optional) and the call mirrors `loadWeights`. State in the report.

- [ ] **Step 4: Commit**
```bash
git add bulkup/Models/APIModels.swift bulkup/Services/APIService+Extensions.swift
git commit -m "feat(progress): loadWeightHistory API + history types"
```

---

## Task 3: [iOS] `ExerciseProgress` aggregation (pure functions + self-check)

**Files:**
- Create: `bulkup/ViewModels/ExerciseProgress.swift`
- Modify: `bulkup/App/BulkUp.swift` (wire the DEBUG self-check)

**Interfaces:**
- Consumes: `ServerWeightHistoryItem`, `ServerWeightSet` (Task 2); `RMManager.calculateHybridRM(weight:reps:)`
- Produces: `ExerciseWeekPoint`; `ExerciseProgress.points(from:exerciseName:exerciseIndex:) -> [ExerciseWeekPoint]`

- [ ] **Step 1: Create `ExerciseProgress.swift`**
```swift
import Foundation

/// One week's aggregated metrics for a single exercise.
struct ExerciseWeekPoint: Identifiable, Equatable {
    let weekStart: String       // "yyyy-MM-dd"
    let topSet: Double          // heaviest set that week
    let volume: Double          // Σ weight × reps
    let est1RM: Double          // max hybrid 1RM over the week's sets
    let bestReps: Int
    var isWeightPR: Bool = false
    var isEst1RMPR: Bool = false
    var id: String { weekStart }
}

enum ExerciseProgress {
    /// Diacritic-folded, lowercased — matches the app's weight-key convention.
    static func fold(_ s: String) -> String {
        s.folding(options: .diacriticInsensitive, locale: .current)
            .lowercased()
            .trimmingCharacters(in: .whitespaces)
    }

    /// Per-week points for ONE exercise, sorted by weekStart ascending, with PR flags
    /// (a week is a PR if it beats every earlier week on top set / est-1RM).
    static func points(from records: [ServerWeightHistoryItem],
                       exerciseName: String, exerciseIndex: Int) -> [ExerciseWeekPoint] {
        let target = fold(exerciseName)
        var byWeek: [String: ExerciseWeekPoint] = [:]
        for r in records where fold(r.exerciseName) == target {
            let sets = r.sets ?? []
            guard !sets.isEmpty else { continue }
            let top = sets.map(\.weight).max() ?? 0
            let vol = sets.reduce(0.0) { $0 + $1.weight * Double($1.reps) }
            let e1rm = sets.compactMap { RMManager.calculateHybridRM(weight: $0.weight, reps: $0.reps) }.max() ?? top
            let reps = sets.map(\.reps).max() ?? 0
            // server already dedupes per week+exercise; if duplicates slip through, keep the heavier
            if let ex = byWeek[r.weekStart], ex.topSet >= top { continue }
            byWeek[r.weekStart] = ExerciseWeekPoint(
                weekStart: r.weekStart, topSet: top, volume: vol, est1RM: e1rm, bestReps: reps)
        }
        var pts = byWeek.values.sorted { $0.weekStart < $1.weekStart }
        var maxTop = -1.0, max1RM = -1.0
        for i in pts.indices {
            if pts[i].topSet > maxTop { pts[i].isWeightPR = true; maxTop = pts[i].topSet }
            if pts[i].est1RM > max1RM { pts[i].isEst1RMPR = true; max1RM = pts[i].est1RM }
        }
        return pts
    }
}

#if DEBUG
extension ExerciseProgress {
    static func runSelfCheck() {
        func item(_ week: String, _ name: String, _ sets: [(Double, Int)]) -> ServerWeightHistoryItem {
            ServerWeightHistoryItem(
                weekStart: week, day: "lunes", exerciseName: name, exerciseIndex: 0,
                sets: sets.enumerated().map { ServerWeightSet(setNumber: $0.offset, weight: $0.element.0, reps: $0.element.1) },
                planId: "p1")
        }
        let recs = [
            item("2026-05-04", "Press Banca", [(60, 10), (62.5, 8)]),
            item("2026-05-11", "Press Banca", [(65, 8), (60, 10)]),
            item("2026-05-18", "Press Banca", [(62.5, 6)]),     // dip — not a PR
            item("2026-05-25", "Press Bánca", [(70, 5)]),        // accented name still matches; PR
            item("2026-05-11", "Sentadilla", [(100, 5)]),        // other exercise, ignored
        ]
        let p = points(from: recs, exerciseName: "press banca", exerciseIndex: 0)
        assert(p.count == 4, "4 weeks for Press Banca")
        assert(p.map(\.weekStart) == ["2026-05-04", "2026-05-11", "2026-05-18", "2026-05-25"], "sorted by week")
        assert(p[0].topSet == 62.5 && p[1].topSet == 65 && p[3].topSet == 70, "top set per week")
        assert(p[0].volume == 60*10 + 62.5*8, "volume Σ w×reps")
        assert(p[0].isWeightPR && p[1].isWeightPR && !p[2].isWeightPR && p[3].isWeightPR, "PR flags")
        assert(p[3].est1RM >= p[1].est1RM, "est-1RM rises into the PR week")
    }
}
#endif
```

- [ ] **Step 2: Wire the self-check** — in `bulkup/App/BulkUp.swift`, in the DEBUG init block where other `runSelfCheck()` calls live, add:
```swift
        ExerciseProgress.runSelfCheck()
```

- [ ] **Step 3: Verify** — agent hand-traces the asserts (top-set/volume/PR/fold); user builds → no assertion crash. State the trace in the report.

- [ ] **Step 4: Commit**
```bash
git add bulkup/ViewModels/ExerciseProgress.swift bulkup/App/BulkUp.swift
git commit -m "feat(progress): ExerciseProgress per-week aggregation + PR detection"
```

---

## Task 4: [iOS] `ExerciseProgressView` + entry point from the plan

**Files:**
- Create: `bulkup/Views/Components/Training/ExerciseProgressView.swift`
- Modify: `bulkup/Views/TrainingView.swift` (the exercise `ForEach`, ~line 741–745: add a tap → push)

**Interfaces:**
- Consumes: `ExerciseProgress.points(...)` (Task 3); `APIService.loadWeightHistory(...)` (Task 2); `RMManager.calculateHybridRM`

- [ ] **Step 1: Create `ExerciseProgressView.swift`**
```swift
import SwiftUI
import Charts

struct ExerciseProgressView: View {
    let exerciseName: String
    let exerciseIndex: Int
    let planId: String
    let weightTracking: Bool

    @State private var points: [ExerciseWeekPoint] = []
    @State private var loading = true
    @State private var metric: Metric = .weight
    private let lime = Color(red: 0.518, green: 0.800, blue: 0.086)

    enum Metric: String, CaseIterable { case weight = "Peso", volume = "Volumen", rm = "1RM" }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                Text(exerciseName).font(.title2.bold())

                if loading {
                    ProgressView().frame(maxWidth: .infinity).padding(.top, 40)
                } else if !weightTracking {
                    empty("Este ejercicio no registra peso.")
                } else if points.isEmpty {
                    empty("Registra tu primer peso para ver tu progreso aquí.")
                } else {
                    header
                    Picker("Métrica", selection: $metric) {
                        ForEach(Metric.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                    }.pickerStyle(.segmented)
                    chart
                    prList
                }
            }.padding()
        }
        .navigationTitle("Progreso")
        .navigationBarTitleDisplayMode(.inline)
        .task { await load() }
    }

    private func empty(_ msg: String) -> some View {
        Text(msg).foregroundStyle(.secondary).frame(maxWidth: .infinity).padding(.top, 30)
    }

    @ViewBuilder private var header: some View {
        let last = points.last!
        let first = points.first!
        let delta = last.topSet - first.topSet
        let pct = first.topSet > 0 ? delta / first.topSet * 100 : 0
        HStack(spacing: 20) {
            stat("Serie tope", "\(fmt(last.topSet)) kg")
            stat("Récord", "\(fmt(points.map(\.topSet).max() ?? 0)) kg")
            stat("Desde el inicio", "\(delta >= 0 ? "+" : "")\(fmt(delta)) kg · \(Int(pct))%")
        }
    }
    private func stat(_ label: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label).font(.caption).foregroundStyle(.secondary)
            Text(value).font(.headline).foregroundStyle(lime)
        }
    }

    private var chart: some View {
        Chart(points) { p in
            LineMark(x: .value("Semana", p.weekStart), y: .value(metric.rawValue, value(p)))
                .foregroundStyle(lime)
            PointMark(x: .value("Semana", p.weekStart), y: .value(metric.rawValue, value(p)))
                .foregroundStyle(isPR(p) ? lime : Color.secondary)
                .symbolSize(isPR(p) ? 110 : 50)
        }
        .frame(height: 240)
        .chartXAxisLabel("Semana")
    }
    private func value(_ p: ExerciseWeekPoint) -> Double {
        switch metric { case .weight: p.topSet; case .volume: p.volume; case .rm: p.est1RM }
    }
    private func isPR(_ p: ExerciseWeekPoint) -> Bool {
        metric == .rm ? p.isEst1RMPR : p.isWeightPR
    }

    @ViewBuilder private var prList: some View {
        let prs = points.filter(\.isWeightPR)
        if !prs.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                Text("PRs").font(.headline)
                ForEach(prs.reversed()) { p in
                    HStack { Text("🏆 \(fmt(p.topSet)) kg × \(p.bestReps)"); Spacer()
                        Text(p.weekStart).foregroundStyle(.secondary).font(.caption) }
                }
            }
        }
    }

    private func load() async {
        loading = true
        defer { loading = false }
        guard weightTracking, let userId = AuthManager.shared.user?.id else { return }
        let recs = (try? await APIService.shared.loadWeightHistory(userId: userId, planId: planId)) ?? []
        points = ExerciseProgress.points(from: recs, exerciseName: exerciseName, exerciseIndex: exerciseIndex)
    }
    private func fmt(_ w: Double) -> String { w == w.rounded() ? String(format: "%.0f", w) : String(format: "%.1f", w) }
}
```

- [ ] **Step 2: Wire the entry point** — in `bulkup/Views/TrainingView.swift`, in the exercise `ForEach` (`ForEach(sortedExercises, id: \.id) { exercise in` around line 741), wrap the `ExerciseCardView(...)` in a `NavigationLink` to the progress view (or add a "Ver progreso" affordance). Minimal: add a chevron/long-press → push. Read the surrounding view to choose the cleanest insertion (it's already inside a `NavigationStack` for the tab). Example wrapping:
```swift
                ForEach(sortedExercises, id: \.id) { exercise in
                    ExerciseCardView(/* …existing args… */)
                        .contextMenu {
                            NavigationLink {
                                ExerciseProgressView(
                                    exerciseName: exercise.name,
                                    exerciseIndex: exercise.orderIndex,
                                    planId: trainingManager.trainingPlanId ?? "",
                                    weightTracking: exercise.weightTracking)
                            } label: { Label("Ver progreso", systemImage: "chart.line.uptrend.xyaxis") }
                        }
                }
```
(Read the file first; if `TrainingView` isn't already in a `NavigationStack`, use a `.sheet` instead of `NavigationLink`. Prefer a visible tap target over context-menu-only if the layout allows — confirm against the actual view.)

- [ ] **Step 3: Verify** — user builds + runs. Manual: tap an exercise with logged weights → chart shows top-set progression; switch to Volumen/1RM; PRs highlighted. Agent: read-through that the metric switch, PR highlight, header delta, and empty/non-weight states are correct.

- [ ] **Step 4: Commit**
```bash
git add "bulkup/Views/Components/Training/ExerciseProgressView.swift" bulkup/Views/TrainingView.swift
git commit -m "feat(progress): ExerciseProgressView (charts + PRs) + plan entry point"
```

---

## Self-Review
**Spec coverage:** backend history endpoint (Task 1) · iOS API + types (Task 2) · per-week aggregation top-set/volume/est-1RM/PR + self-check (Task 3) · charts view with metric switcher + PR markers + header delta + entry point + empty/non-weight states (Task 4). All four metrics + top-set + in-plan location covered.

**Placeholder scan:** No TBD/TODO. Task 4 Step 2 says "read the file + choose NavigationLink vs sheet" — that's a real conditional instruction (the insertion depends on whether `TrainingView` is in a NavigationStack), not a placeholder; both options are spelled out.

**Type consistency:** `ServerWeightHistoryItem{weekStart,day,exerciseName,exerciseIndex,sets,planId}` identical in Task 2 (def), Task 3 (consumed), Task 4 (via the API). `ExerciseWeekPoint` + `ExerciseProgress.points(from:exerciseName:exerciseIndex:)` identical in Tasks 3→4. Backend `WeightHistoryItem` JSON (`weekStart` string, `sets`) matches the iOS `ServerWeightHistoryItem`. `RMManager.calculateHybridRM(weight: Double, reps: Int)` used with `ServerWeightSet.weight: Double`/`reps: Int`.
