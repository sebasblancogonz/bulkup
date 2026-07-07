# Plan-Screen UX Alignment — Design Spec

**Date:** 2026-06-21
**Branch:** `feature/plan-screen-ux`
**Status:** Approved (pending user review of this doc)

## Goal

Unify the Training and Diet plan screens around Training's visual language (which
the user prefers), with a single consistent control pattern, a full-width
day/week navigator, and a unified AI-import screen. Diet keeps its day-based
model (no weeks); it only adopts Training's *style and controls*.

## Decisions (locked)

| Topic | Decision |
|---|---|
| Hub shell | **Both** hubs use the inline `Plan Activo \| Mis Planes` segmented tabs. Diet's library stops being a sheet and becomes an inline tab. |
| Controls | **One contextual `⋯` menu** per hub holds everything — replaces Training's `Semanal/Diario` pill *and* the separate `+` menu, and Diet's header `⋯`. |
| View mode (training) | Moved out of the inline pill into `⋯ → Cambiar vista → Semanal / Diario` (✓ marks current). |
| Navigator | Week/day strip (training) and day-pill strip (diet) go **full-bleed** (edge to edge). |
| AI import | Training's "Importar con IA" opens a **diet-style** screen (name + dashed PDF box + dashed Image box + "AI detects…" list), not the 4-method picker. Template & manual remain their own menu items. |
| Diet model | Unchanged — day-based (training-day vs rest-day), no weeks. |

## Unified Hub Header

Header row for both `TrainingHubView` and `DietHubView`:

```
[ Plan Activo | Mis Planes ]            ⋯
```

- Segmented pill = existing Training style (`Capsule` segments, accent fill on
  active). Diet adopts the same control + a `selectedView` state.
- Trailing `⋯` is an `ellipsis` button (36pt circle, `surfaceElevated`), a
  context-aware `Menu`:

**Plan Activo tab:**
- Training: `Cambiar vista` ▸ `Vista semanal` / `Vista diaria` (checkmark on
  current) · `Divider` · `Editar plan` · `Compartir` · `Eliminar`
- Diet: `Editar plan` · `Preferencias y alergias` · `Divider` · `Eliminar`
  (no `Cambiar vista`)

**Mis Planes tab (both):**
- Training: `Usar plantilla` · `Crear manualmente` · `Importar con IA` ·
  `Divider` · `Importar con código`
- Diet: `Crear manualmente` · `Importar con IA`  (+ `Importar con código` if diet
  supports it today; otherwise omit)

The `⋯` menu's content is driven by `(selectedView, hubKind)`. View-mode state
(`Semanal/Diario`) is lifted so the hub's `⋯` can set it and `TrainingView`
reads it (shared `@State`/binding, or an `ObservableObject` — see plan).

## Full-Width Navigator

- Training: the 7-day mini-calendar strip and the week arrows row currently sit
  inside `navigationHeader`, which is padded by `Spacing.screenH`. Move the
  **strip** out of that horizontal padding so it spans edge-to-edge; keep inner
  cell layout. Week-arrows row may stay padded (it's centered text + arrows).
- Diet: the `dayPillStrip` (`DietView.swift`) drops its `Spacing.screenH`
  horizontal padding so the pills scroll edge-to-edge.
- Content below the navigator keeps normal `screenH` padding.

## Unified AI-Import Screen

- Extract the diet import UI (`CreateDietPlanView`: name field, two dashed
  160pt PDF/Image boxes, "la IA detectará…" feature list) into the shared
  visual pattern.
- Training's `Importar con IA` opens a Training variant with the **same layout**:
  name field, dashed **PDF** box, dashed **Image** box, AI-detection list.
  - Difference allowed: Training keeps an optional `Fechas específicas` toggle
    (start/end dates) because training plans are week-dated; diet has none.
  - Tint: Training uses `BulkUpColors.training`/accent; diet uses
    `BulkUpColors.diet`. Otherwise identical.
- The old 4-method `CreateTrainingPlanView` picker is no longer the IA entry.
  `Usar plantilla` and `Crear manualmente` are already separate hub-menu items,
  so the method-picker becomes redundant and is removed (or reduced to the
  AI-import screen). Existing template/manual sheets are reused.
- Both import screens continue to call `uploadManager.uploadImage` /
  `uploadFile` → `/process-file-smart` (unchanged backend). This routes Training
  image-import through the same proven path as Diet.

## Files Touched

- `bulkup/Views/Components/Training/TrainingHubView.swift` — header: fold
  `+` menu into contextual `⋯`; add `Cambiar vista`; lift view-mode state.
- `bulkup/Views/TrainingView.swift` — remove inline `Semanal/Diario` pill; read
  view-mode from hub; make the calendar strip full-bleed.
- `bulkup/Views/Components/Diet/DietHubView.swift` — restructure to inline
  `Plan Activo | Mis Planes` tabs (library becomes a tab, not a sheet); add the
  same contextual `⋯`.
- `bulkup/Views/DietView.swift` — full-bleed `dayPillStrip`.
- `bulkup/Views/Components/Training/CreateTrainingPlanView.swift` — replace the
  4-method picker entry for IA with the diet-style AI-import layout (keep
  optional dates).
- `bulkup/Views/Components/Diet/CreateDietPlanView.swift` — factor its dashed
  upload UI so Training can mirror it (shared subview or duplicated-but-aligned).
- `bulkup/Localization/Localizable.xcstrings` — any new strings (`Cambiar vista`,
  `Vista semanal`, `Vista diaria`, `Editar plan`, etc.) with EN values.

## Out of Scope (YAGNI)

- No new diet "weeks" concept.
- No backend changes (translation toggle is Stream 3, separate).
- No change to plan-card menus inside the library lists (already consistent).
- No change to the underlying managers' data models.

## Success Criteria

- Both hubs show identical `Plan Activo | Mis Planes` tabs + one `⋯` menu.
- Training `Semanal/Diario` switches via `⋯ → Cambiar vista`; the inline pill is gone.
- Week (training) and day (diet) navigators span full screen width.
- "Importar con IA" looks identical on both sides (dashed PDF + Image boxes).
- Diet still works day-based; training still week/day.
- All new UI strings localized (EN + ES); no Spanish hardcoded.
- Builds in Xcode (manual — cannot compile in this environment).
