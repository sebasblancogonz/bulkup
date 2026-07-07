# Exercise Progress (per-exercise progression) — Design

**Date:** 2026-06-28
**Scope:** A per-exercise progress view, reached by tapping an exercise in the training plan, that charts how the athlete is advancing on that exercise over time — **top-set weight, volume, estimated 1RM, and detected PRs** — derived from the weight records the app already logs week by week. Read-only; captures no new data.

**Spans two repos:** the Go backend `weight-tracker-backend` (one new read endpoint) and the iOS app `bulkup` (the view + aggregation). Two branches / two PRs; **backend lands first** (the history contract).

---

## Goals
- For any exercise in the active training plan, show its progression across the weeks the user has logged: a chart of the **top set** (heaviest weight that week) with a metric switcher to **Volume** (Σ weight×reps) and **estimated 1RM**.
- **Detect PRs** automatically from the logged sets (a week whose top set, or estimated 1RM, beats every prior week) and mark them.
- Headline stats: current top set, all-time PR, and **delta since the first logged week** ("+12.5 kg · +18% desde [fecha]").

## Non-goals
- No new data capture (purely reads existing `WeightRecord`s).
- Does not modify or feed the **manual 1RM tracker** (`RMManager` PersonalRecords) — the estimated-1RM here is auto-derived from plan logs and lives only in this view.
- No cross-exercise or whole-plan dashboard in this slice (that's the "Progreso tab" option we deferred). One exercise at a time.
- No body-composition / diet correlation.

## Decisions (locked)
- All four metrics (weight, volume, est-1RM, PRs). Representative weekly weight = **top set** (heaviest). Lives **inside the plan** (tap exercise → its progress).

---

## Data — already exists
`WeightRecord` is stored per week both locally (SwiftData) and in the backend (MongoDB), keyed by `(userId, planId, day, exerciseIndex, exerciseName, weekStart)` with `sets: [{setNumber, weight, reps}]`. The app already loads ~4 weeks back via `POST /load-weights` (`WeightService.LoadWeights`). For a real progression view we need **all weeks**, not a 4-week window.

## Backend (Go) — one new read endpoint (lands first)
- **Route:** `POST /load-weight-history` (mirrors `/load-weights`).
- **Request:** `{ userId, planId }` (planId optional → all plans; primary use passes planId).
- **Handler/service:** `WeightHandler.LoadWeightHistory` → `WeightService.LoadWeightHistory(userId, planId)` → Mongo `Find({userId, planId})` sorted by `weekStart` ascending. Returns the raw `WeightRecord`s (same shape the existing load returns), across all weeks.
- No new fields, no aggregation server-side (the client computes metrics). Verify with `go build ./...` (Homebrew leptonica/tesseract cgo flags per project memory).

## iOS — `ExerciseProgressView`
- **Entry point:** tapping an exercise row in `TrainingView`'s plan list pushes `ExerciseProgressView(exercise:, planId:, day:)`. (Reuse / extend the existing `ExerciseDetailSheet` affordance, or a `NavigationLink`.)
- **API:** new `APIService.loadWeightHistory(userId:planId:) async throws -> [ServerWeightRecord]` (mirror `loadWeights`).
- **Aggregation (pure functions, in a small `ExerciseProgress` helper, testable):** filter the history to this exercise (by folded `exerciseName` + `exerciseIndex`), group by `weekStart`, and per week compute:
  - `topSet` = max `set.weight`
  - `volume` = Σ `set.weight × set.reps`
  - `est1RM` = max over sets of `RMManager.calculateHybridRM(weight:reps:)` (reuses the existing hybrid Epley/Brzycki/Lander formula)
  - `bestReps` = max `set.reps`
- **PR detection:** a week is a **weight PR** if its `topSet` > all earlier weeks' `topSet`; an **est-1RM PR** likewise. Mark those points on the chart (lime) + a "🏆 nuevo PR" row.
- **UI (SwiftUI `Charts`, the pattern already used in `ExerciseDetailView`):**
  - A segmented switcher: **Peso / Volumen / 1RM** → changes the charted series.
  - Line + points over `weekStart`; PR points highlighted; the lime accent for the current value.
  - Header: current top set, all-time PR (weight + est-1RM), delta since first logged week.
  - Premium dark style consistent with the app (lime accent, the Progress tab look).
- **Non-weight exercises** (`weightTracking == false`): no weight history → show a **completion progress** fallback (sets/reps completed across weeks, from the session/completion data) or a clean "sin datos de peso todavía" empty state. (Keep this branch simple; the main value is the weight-tracking exercises.)
- **Empty state:** an exercise with zero logged weeks shows a friendly "registra tu primer peso para ver tu progreso aquí".

## Data flow
1. User taps an exercise in the plan → `ExerciseProgressView`.
2. View calls `loadWeightHistory(userId, planId)` once → `[ServerWeightRecord]`.
3. The `ExerciseProgress` helper filters to this exercise + computes per-week `{weekStart, topSet, volume, est1RM, bestReps, isWeightPR, isEst1RMPR}`.
4. The chart renders the selected metric; header derives current/PR/delta.

## Error handling
- Network failure → a retry state (don't crash; show "no se pudo cargar el progreso").
- Sparse weeks (skipped weeks) → gaps in the series (don't interpolate; plot only logged weeks).
- Exercise renamed/reordered across weeks → keyed by folded `exerciseName` (matches the existing weight-key convention); index drift tolerated by name match.
- Units: kg (the app's unit); no conversion in this slice.

## Testing
- **Backend:** `go build ./...` green; the new endpoint round-trips (add/verify in the existing handler test path if present, else a focused check).
- **iOS:** the `ExerciseProgress` aggregation is **pure functions** → a DEBUG `runSelfCheck()` (project convention, wired into `BulkUp.swift`) asserting: top-set/volume/est1RM computed correctly from a fixture of records; PR detection flags the right weeks; delta math. iOS not buildable here → code review + user builds in Xcode.

## Sequencing (two PRs)
1. **Backend PR** (`weight-tracker-backend`): `/load-weight-history`. Build-verified, merged first.
2. **iOS PR** (`bulkup`): `ExerciseProgressView` + aggregation + API + entry point. Built by the user.
