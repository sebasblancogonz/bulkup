# Plan-Screen UX Alignment Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Align the Training and Diet plan screens on Training's visual language with one shared control pattern (inline `Plan Activo | Mis Planes` tabs + a single contextual `⋯` menu), a full-width day/week navigator, and a unified diet-style AI-import screen.

**Architecture:** SwiftUI views. The training view mode (`Semanal/Diario`) is lifted out of the inline pill into shared `@AppStorage` so both `TrainingHubView`'s `⋯` menu and `TrainingView` read/write the same value with no binding threading. Diet's hub is restructured from a sheet-based library to inline tabs mirroring training. The diet AI-import upload UI is factored into one reusable subview that both the diet and the new training IA screen use.

**Tech Stack:** SwiftUI, SwiftData, `@AppStorage`, `BulkUpColors`/`BulkUpFont`/`Spacing` design tokens, `Localizable.xcstrings` string catalog.

## Global Constraints

- All user-facing strings use `LocalizedStringKey` (literal `Text("…")`/`Label("…")` or `Text(LocalizedStringKey(var))`), NEVER `Text(stringVar)` or `+` string concatenation. Every NEW Spanish string gets an `en` value in `bulkup/Localization/Localizable.xcstrings` (source language is `es`).
- Use design tokens only: `BulkUpColors.*`, `BulkUpFont.*`, `Spacing.*`, `CornerRadius.*`. Training tint = `BulkUpColors.accent`/`.training`; diet tint = `BulkUpColors.diet`.
- Diet stays day-based (training-day vs rest-day). NO weeks concept added.
- No backend changes. No data-model changes. Plan-card library menus stay as-is.
- Cannot compile in this environment; each task's verification is "builds in Xcode + visual check on the relevant screen." The implementer states this explicitly and does not claim a green build it didn't run.
- Branch: `feature/plan-screen-ux`. Commit after each task.

## File Structure

| File | Responsibility after this plan |
|---|---|
| `bulkup/Views/TrainingView.swift` | Reads `viewMode` from `@AppStorage`; no inline mode pill; full-bleed calendar strip |
| `bulkup/Views/Components/Training/TrainingHubView.swift` | Inline tabs + single contextual `⋯` menu (Cambiar vista on Plan Activo; create/import on both); IA opens the new diet-style training import |
| `bulkup/Views/DietView.swift` | Full-bleed `dayPillStrip` |
| `bulkup/Views/Components/Diet/DietHubView.swift` | Inline `Plan Activo | Mis Planes` tabs + single contextual `⋯`; library is an inline tab, not a sheet |
| `bulkup/Views/Components/Shared/AIImportUploadBoxes.swift` (new) | Reusable dashed PDF + Image upload boxes + AI-detection list, tint-parameterized |
| `bulkup/Views/Components/Training/CreateTrainingPlanView.swift` | IA path renders the diet-style upload (via shared subview) + optional date toggle |
| `bulkup/Views/Components/Diet/CreateDietPlanView.swift` | Uses the shared `AIImportUploadBoxes` subview |
| `bulkup/Localization/Localizable.xcstrings` | New strings + `en` values |

---

### Task 1: Lift training view-mode to shared AppStorage; remove inline mode pill

**Files:**
- Modify: `bulkup/Views/TrainingView.swift` (state decl near line 9; `ViewMode` enum lines 26–43; the `Semanal/Diario` pill inside `navigationHeader`, lines ~523–560)

**Interfaces:**
- Produces: `TrainingView.ViewMode` (unchanged `String`-raw, `CaseIterable`, internal — usable as `TrainingView.ViewMode` from the hub) and the shared key `@AppStorage("trainingViewMode")`.

- [ ] **Step 1: Make `ViewMode` usable from the hub and AppStorage-compatible**

Confirm `enum ViewMode: String, CaseIterable` is declared at TrainingView.swift:26 WITHOUT `private`. `String` raw value already makes it `RawRepresentable`, which `@AppStorage` supports. No change needed beyond ensuring it is not `private`.

- [ ] **Step 2: Change the view-mode state to AppStorage**

In `TrainingView.swift`, replace the existing declaration:

```swift
@State private var viewMode: ViewMode = .day
```

with:

```swift
@AppStorage("trainingViewMode") private var viewMode: ViewMode = .day
```

- [ ] **Step 3: Remove the inline `Semanal/Diario` segmented pill**

In `navigationHeader` (TrainingView.swift ~523–560), delete the entire `HStack(spacing: 0) { ForEach(ViewMode.allCases…) … }` block that renders the mode buttons (the one ending with `.padding(3).background(BulkUpColors.surfaceElevated).cornerRadius(10)`). Leave the rest of `navigationHeader` (the day/week navigator) intact. The mode is now switched only from the hub's `⋯` menu (Task 2). Keep the `withAnimation` behavior by leaving `viewMode` reads as-is; switching happens via AppStorage writes elsewhere.

- [ ] **Step 4: Verify**

Build in Xcode. Open the Entreno tab with an active plan. Expected: the Semanal/Diario pill is gone; the navigator still renders; the plan defaults to the last-used mode (persisted). Note in the report that this was a manual Xcode build (no automated tests exist).

- [ ] **Step 5: Commit**

```bash
git add bulkup/Views/TrainingView.swift
git commit -m "refactor(training): lift view mode to AppStorage, remove inline mode pill"
```

---

### Task 2: Training hub — single contextual `⋯` menu (replaces `+`), with Cambiar vista

**Files:**
- Modify: `bulkup/Views/Components/Training/TrainingHubView.swift` (state block lines 11–20; `sectionPicker` lines 112–209; the `showingImageImport` sheet line 96–100)

**Interfaces:**
- Consumes: `@AppStorage("trainingViewMode")` + `TrainingView.ViewMode` from Task 1.
- Produces: the unified header used as the template for the diet hub (Task 5).

- [ ] **Step 1: Add the shared view-mode AppStorage to the hub**

In the `@State` block (TrainingHubView.swift:11–20) add:

```swift
@AppStorage("trainingViewMode") private var trainingViewMode: TrainingView.ViewMode = .day
```

- [ ] **Step 2: Replace the conditional `+` menu with an always-present contextual `⋯`**

In `sectionPicker` (TrainingHubView.swift), replace the whole `if selectedView == .library { Menu { … } label: { Image("plus.circle.fill") … } }` block (lines 149–203) with this always-present menu:

```swift
Menu {
    if selectedView == .active {
        // View-mode switch (only meaningful for an active training plan)
        Picker("Cambiar vista", selection: $trainingViewMode) {
            ForEach(TrainingView.ViewMode.allCases, id: \.self) { mode in
                Label(mode.displayName, systemImage: mode.icon).tag(mode)
            }
        }
        Divider()
    }
    // Create / import — available from both tabs
    Button {
        showingTemplateWizard = true
    } label: { Label("Usar plantilla", systemImage: "doc.on.doc") }

    Button {
        showingPlanEditor = true
    } label: { Label("Crear manualmente", systemImage: "square.and.pencil") }

    Button {
        if storeKit.isSubscribed { showingImageImport = true } else { showingSubscription = true }
    } label: { Label("Importar con IA", systemImage: "sparkles") }

    Divider()

    Button {
        if storeKit.isSubscribed { showingImportCode = true } else { showingSubscription = true }
    } label: { Label("Importar con codigo", systemImage: "qrcode") }
} label: {
    Image(systemName: "ellipsis")
        .font(.system(size: 16, weight: .medium))
        .foregroundStyle(BulkUpColors.textSecondary)
        .frame(width: 36, height: 36)
        .background(BulkUpColors.surfaceElevated)
        .clipShape(Circle())
}
.padding(.leading, Spacing.sm)
```

Notes: `Picker` inside a `Menu` renders as an inline submenu with a checkmark on the selected option — this is the "Cambiar vista → Semanal/Diario" affordance. `mode.displayName` is already `LocalizedStringKey`; `mode.icon` exists (Task 1). The `⋯` is now always visible (no `if selectedView == .library` wrapper), so the segmented pill no longer stretches full width — keep the pill's `HStack` as the leading element with the `⋯` trailing it inside the outer `HStack(spacing: 0)` at line 113.

- [ ] **Step 3: Verify**

Build in Xcode. On **Plan Activo**: `⋯` shows `Cambiar vista` (Semanal/Diario, ✓ on current) + create/import items; switching mode updates the plan view. On **Mis Planes**: `⋯` shows just the create/import items. The old `+` is gone. Manual build (no tests).

- [ ] **Step 4: Commit**

```bash
git add bulkup/Views/Components/Training/TrainingHubView.swift
git commit -m "feat(training): single contextual ⋯ menu with Cambiar vista; drop + menu"
```

---

### Task 3: Full-width training calendar strip

**Files:**
- Modify: `bulkup/Views/TrainingView.swift` (the day-mode mini-calendar strip, lines ~657–705; the `navigationHeader` horizontal padding at the call site ~344–347)

**Interfaces:** none new.

- [ ] **Step 1: Make the 7-day strip span edge-to-edge**

The strip sits inside `navigationHeader`, which is padded `.padding(.horizontal, Spacing.screenH)` at its call site (~344). To make ONLY the strip full-bleed while keeping other header content padded, give the strip negative horizontal padding equal to `screenH` and re-apply zero inner padding. On the strip's outer container (the `HStack(spacing: 0)` ending at the `.background(BulkUpColors.surface).cornerRadius(...)`), append:

```swift
.padding(.horizontal, Spacing.screenH)   // inner breathing room for the end cells
.padding(.horizontal, -Spacing.screenH)  // cancel the parent screenH padding → full-bleed
```

Wait — that nets zero. Instead, use a single negative margin to break out of the parent padding and let the strip touch the screen edges, removing the card's side inset and corner radius so it reads as a full-width band:

```swift
// strip container
.padding(.vertical, Spacing.sm)
.background(BulkUpColors.surface)
.overlay(
    Rectangle().frame(height: 0.5).foregroundColor(BulkUpColors.border),
    alignment: .bottom
)
.padding(.horizontal, -Spacing.screenH)   // break out of navigationHeader's screenH padding
```

Replace the strip's previous `.cornerRadius(CornerRadius.medium)` + `RoundedRectangle` border overlay with the full-bleed `Rectangle` bottom hairline shown above (a rounded card can't be full-bleed). The inner `ForEach(0..<7)` cells already use `.frame(maxWidth: .infinity)`, so they redistribute across the wider width automatically.

- [ ] **Step 2: Verify**

Build in Xcode. Day-mode strip now spans the full screen width (touches both edges) with a thin bottom divider; the 7 day cells are evenly spread. Week-mode arrows row stays padded/centered. Manual build.

- [ ] **Step 3: Commit**

```bash
git add bulkup/Views/TrainingView.swift
git commit -m "feat(training): full-bleed week/day calendar strip"
```

---

### Task 4: Reusable diet-style AI-import upload subview

**Files:**
- Create: `bulkup/Views/Components/Shared/AIImportUploadBoxes.swift`
- Modify: `bulkup/Views/Components/Diet/CreateDietPlanView.swift` (the two dashed boxes, lines ~80–148, to use the new subview)

**Interfaces:**
- Produces: `AIImportUploadBoxes(tint:onPickPDF:onPickImage:disabled:)` — two dashed 160pt boxes (PDF + Image) side by side. Consumed by Task 6 (training IA screen) and this task (diet).

- [ ] **Step 1: Create the shared subview**

```swift
//  AIImportUploadBoxes.swift
//  Reusable dashed PDF + Image upload boxes for AI plan import (diet + training).

import SwiftUI

struct AIImportUploadBoxes: View {
    let tint: Color
    let onPickPDF: () -> Void
    let onPickImage: () -> Void
    var disabled: Bool = false

    var body: some View {
        HStack(spacing: Spacing.md) {
            box(title: "Subir PDF", subtitle: "Archivo PDF", icon: "arrow.up.doc.fill", action: onPickPDF)
            box(title: "Subir Imagen", subtitle: "Foto de tu plan", icon: "photo.on.rectangle", action: onPickImage)
        }
    }

    private func box(title: LocalizedStringKey, subtitle: LocalizedStringKey, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            ZStack {
                RoundedRectangle(cornerRadius: CornerRadius.large)
                    .strokeBorder(style: StrokeStyle(lineWidth: 2, dash: [8]))
                    .foregroundColor(tint.opacity(0.4))
                    .frame(height: 160)
                    .background(
                        RoundedRectangle(cornerRadius: CornerRadius.large)
                            .fill(BulkUpColors.surfaceElevated)
                    )
                VStack(spacing: Spacing.sm) {
                    Image(systemName: icon)
                        .font(.system(size: 28))
                        .foregroundColor(tint)
                    Text(title)
                        .font(BulkUpFont.cardTitle())
                        .foregroundColor(BulkUpColors.textPrimary)
                    Text(subtitle)
                        .font(BulkUpFont.caption())
                        .foregroundColor(BulkUpColors.textSecondary)
                }
            }
        }
        .buttonStyle(.plain)
        .disabled(disabled)
        .opacity(disabled ? 0.5 : 1)
    }
}
```

- [ ] **Step 2: Use it in `CreateDietPlanView`**

In `CreateDietPlanView.swift`, replace the existing `HStack(spacing: Spacing.md) { /* PDF box */ … /* Image box */ … }` (≈ lines 80–148) with:

```swift
AIImportUploadBoxes(
    tint: BulkUpColors.diet,
    onPickPDF: { showingFilePicker = true },
    onPickImage: { showingPhotoPicker = true },
    disabled: planName.isEmpty
)
```

Leave the surrounding name field, hero header, the "la IA detectará…" feature list, and the `.fileImporter`/`PhotosPicker` handlers unchanged.

- [ ] **Step 3: Verify**

Build in Xcode. Diet "Importar con IA" looks identical to before (two dashed boxes), now backed by the shared subview; picking PDF/Image still opens the pickers; boxes disabled until a name is entered. Manual build.

- [ ] **Step 4: Commit**

```bash
git add bulkup/Views/Components/Shared/AIImportUploadBoxes.swift bulkup/Views/Components/Diet/CreateDietPlanView.swift
git commit -m "refactor(import): extract reusable AIImportUploadBoxes; use in diet import"
```

---

### Task 5: Training IA screen = diet-style upload (with optional dates)

**Files:**
- Modify: `bulkup/Views/Components/Training/CreateTrainingPlanView.swift` (render a diet-style AI-import layout when entered for IA)
- Modify: `bulkup/Views/Components/Training/TrainingHubView.swift` (the `showingImageImport` sheet, line 96–100)

**Interfaces:**
- Consumes: `AIImportUploadBoxes` (Task 4); the existing `processTrainingPlanImage(_:)` and the file-upload path already in `CreateTrainingPlanView`.

- [ ] **Step 1: Add an AI-import body to CreateTrainingPlanView**

`CreateTrainingPlanView` already has the plan-name field, the optional `Fechas específicas` date toggle, `processTrainingPlanImage(_:)`, the PDF `uploadFile` path, and `PhotosPicker`/`fileImporter` state. Add a computed `aiImportBody` that mirrors the diet layout:

```swift
private var aiImportBody: some View {
    ScrollView {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            // plan name field (reuse the existing name TextField subview/section)
            planNameField

            // optional dates — training only
            datesSection   // the existing "Fechas específicas" toggle + pickers

            AIImportUploadBoxes(
                tint: BulkUpColors.accent,
                onPickPDF: { showingFilePicker = true },
                onPickImage: { showingPhotoPicker = true },
                disabled: planName.isEmpty
            )

            aiDetectionList   // "la IA detectará…" feature list, training-flavored
        }
        .padding(.horizontal, Spacing.screenH)
        .padding(.top, Spacing.md)
    }
}
```

Drive the screen to render `aiImportBody` when the view is opened for IA. The hub opens it via `initialMethod: .imageUpload`; treat `.imageUpload` (and a PDF pick) as "AI import". Concretely: in `CreateTrainingPlanView.body`, when `creationMethod == .imageUpload` OR the view was opened specifically for IA, show `aiImportBody` instead of the 4-`CreationMethodCard` list. Keep `.manual`/`.template`/`.upload` reachable only if still used elsewhere; the hub now routes template→`showingTemplateWizard` and manual→`showingPlanEditor` directly, so the 4-method picker is no longer the IA entry.

Reuse the existing handlers: the Image box calls the same `PhotosPicker` flow that already calls `processTrainingPlanImage(jpeg)`; the PDF box uses the existing `.fileImporter` → `uploadFile` path. Do NOT change the upload/networking code (it already targets `/process-file-smart`).

- [ ] **Step 2: Point the hub's IA sheet at the AI body**

In `TrainingHubView.swift` the `showingImageImport` sheet (line 96–100) already presents `CreateTrainingPlanView(initialMethod: .imageUpload)`. With Step 1, that now renders `aiImportBody`. No change needed unless `CreateTrainingPlanView` requires an explicit "IA mode" flag — if so, add an `aiImportOnly: Bool = false` init param and pass `aiImportOnly: true` here, and gate `aiImportBody` on it.

- [ ] **Step 3: Verify**

Build in Xcode. From Entreno → `⋯` → Importar con IA: the screen now shows the diet-style layout (name + dashed PDF box + dashed Image box + detection list + optional dates), NOT the 4-method card list. Importing a PDF and an image both kick off processing through the existing path. Manual build.

- [ ] **Step 4: Commit**

```bash
git add bulkup/Views/Components/Training/CreateTrainingPlanView.swift bulkup/Views/Components/Training/TrainingHubView.swift
git commit -m "feat(training): IA import uses the diet-style upload screen"
```

---

### Task 6: Diet hub — inline tabs + single contextual `⋯`

**Files:**
- Modify: `bulkup/Views/Components/Diet/DietHubView.swift` (add tabs + content switch; convert library sheet → inline tab; fold `planHeader` ⋯ into the header ⋯)

**Interfaces:**
- Consumes: the unified header pattern from Task 2 (mirror it with diet tint).
- Produces: `DietHubSection` enum (`active`/`library`).

- [ ] **Step 1: Add the section enum + state**

In `DietHubView` add:

```swift
@State private var selectedView: DietHubSection = .active

enum DietHubSection: String, CaseIterable {
    case active = "active"
    case library = "library"
    var displayName: LocalizedStringKey {
        switch self { case .active: return "Plan Activo"; case .library: return "Mis Planes" }
    }
    var icon: String {
        switch self { case .active: return "leaf.fill"; case .library: return "folder.fill" }
    }
}
```

- [ ] **Step 2: Add a `sectionPicker` header (mirror training, diet tint)**

Add a `sectionPicker` view modeled on `TrainingHubView.sectionPicker` but with `BulkUpColors.diet` as the active fill and the contextual `⋯`:

```swift
private var sectionPicker: some View {
    HStack(spacing: 0) {
        HStack(spacing: 0) {
            ForEach(DietHubSection.allCases, id: \.self) { section in
                let isActive = selectedView == section
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) { selectedView = section }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: section.icon).font(.system(size: 13, weight: .semibold))
                        Text(section.displayName).font(.system(size: 14, weight: .bold))
                    }
                    .foregroundColor(isActive ? BulkUpColors.onAccent : BulkUpColors.textSecondary)
                    .frame(maxWidth: .infinity).padding(.vertical, 10)
                    .background(isActive ? Capsule().fill(BulkUpColors.diet) : Capsule().fill(.clear))
                    .contentShape(Capsule())
                }
            }
        }
        .padding(3)
        .background(Capsule().fill(BulkUpColors.surface))

        Menu {
            if selectedView == .active {
                Button { showingFoodPreferences = true } label: {
                    Label("Preferencias y alergias", systemImage: "fork.knife.circle")
                }
                Divider()
            }
            Button {
                if storeKit.isSubscribed { showingCreateDietPlan = true } else { showingSubscription = true }
            } label: { Label("Importar con IA", systemImage: "sparkles") }
            Button { showingDietPlanEditor = true } label: {
                Label("Crear manualmente", systemImage: "square.and.pencil")
            }
        } label: {
            Image(systemName: "ellipsis")
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(BulkUpColors.textSecondary)
                .frame(width: 36, height: 36)
                .background(BulkUpColors.surfaceElevated)
                .clipShape(Circle())
        }
        .padding(.leading, Spacing.sm)
    }
    .padding(.horizontal, Spacing.screenH)
    .padding(.bottom, Spacing.sm)
    .padding(.top, Spacing.md)
    .background(BulkUpColors.background)
}
```

- [ ] **Step 3: Restructure `body` to tabs + content switch**

Replace the current `body`'s top `VStack` (lines 21–29) so the picker is always shown and the content switches by tab:

```swift
var body: some View {
    VStack(spacing: 0) {
        sectionPicker
        Group {
            switch selectedView {
            case .active:
                if dietManager.isLoading { loadingView }
                else if dietManager.dietData.isEmpty { activePlanEmptyState }
                else { activePlanContent }
            case .library:
                DietPlanLibraryView()
                    .environmentObject(dietManager)
                    .environmentObject(authManager)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    .background(BulkUpColors.background)
    .toolbar(.hidden, for: .navigationBar)
    // keep the existing .sheet(...) for showingCreateDietPlan, showingDietPlanEditor,
    // showingSubscription, showingFoodPreferences. DELETE the showingLibrarySheet sheet.
    .onAppear { /* unchanged */ }
    .onReceive(NotificationCenter.default.publisher(for: .navigateToDietLibrary)) { _ in
        withAnimation(.easeInOut(duration: 0.2)) { selectedView = .library }
    }
}
```

- [ ] **Step 4: Simplify `planHeader` (the per-plan ⋯ is now redundant)**

The header `⋯` menu (lines 127–166) duplicated create/import + "Mis Planes". Since those now live in `sectionPicker`'s `⋯` and the inline tab, reduce `planHeader` to just the plan name + day/meal count (drop its trailing `Menu`). Keep `activePlanContent` rendering `planHeader` → `DietFidelityView` → `DietView`. Remove now-unused `@State private var showingLibrarySheet`.

- [ ] **Step 5: Verify**

Build in Xcode. Diet tab now shows `Plan Activo | Mis Planes` tabs identical in style to training (diet tint). `Mis Planes` shows the library inline (no sheet). `⋯` shows Preferencias (active) + create/import. `navigateToDietLibrary` switches to the library tab. Manual build.

- [ ] **Step 6: Commit**

```bash
git add bulkup/Views/Components/Diet/DietHubView.swift
git commit -m "feat(diet): inline Plan Activo|Mis Planes tabs + contextual ⋯ (match training)"
```

---

### Task 7: Full-width diet day-pill strip

**Files:**
- Modify: `bulkup/Views/DietView.swift` (`dayPillStrip`, lines ~125–161)

**Interfaces:** none new.

- [ ] **Step 1: Make the day-pill strip edge-to-edge**

The `dayPillStrip`'s inner `HStack` currently has `.padding(.horizontal, Spacing.screenH)`. Keep that inner padding (so the first/last pill aren't flush to the edge) but ensure the `ScrollView(.horizontal)` itself is not constrained by an outer padded container — the strip should scroll from screen edge to screen edge. If `DietView`'s body wraps content in a padded `VStack`, lift the `dayPillStrip` out of that horizontal padding (apply `.padding(.horizontal, -Spacing.screenH)` to the `ScrollView` if it is inside a `screenH`-padded parent, or move it above the padded content). Verify the scroll content starts at `x = screenH` and can scroll fully to the last pill with no clipped right edge.

- [ ] **Step 2: Verify**

Build in Xcode. The diet day pills scroll edge-to-edge (the strip's scrollable area reaches both screen edges); selecting a pill still switches the day `TabView`. Manual build.

- [ ] **Step 3: Commit**

```bash
git add bulkup/Views/DietView.swift
git commit -m "feat(diet): full-bleed day-pill strip"
```

---

### Task 8: Localize new strings

**Files:**
- Modify: `bulkup/Localization/Localizable.xcstrings`

**Interfaces:** none.

- [ ] **Step 1: Add `en` values for every new string introduced by Tasks 1–7**

For each key below, if it already exists in the catalog with an `en` value, skip it; if it exists without `en`, add the `en`; if missing, add the full entry (source language is `es`, so the key IS the Spanish). Use this exact JSON shape per key (insert surgically; do NOT reformat the whole file):

```json
"<spanish key>" : {
  "localizations" : {
    "en" : { "stringUnit" : { "state" : "translated", "value" : "<english>" } }
  }
}
```

Keys → English:
- `Cambiar vista` → `Change view`
- `Semanal` → `Weekly`  (verify; add if missing)
- `Diario` → `Daily`  (verify; add if missing)
- `Plan Activo` → `Active plan`  (verify)
- `Mis Planes` → `My plans`  (verify; likely exists)
- `Subir Imagen` → `Upload image`
- `Foto de tu plan` → `Photo of your plan`
- `Subir PDF` → `Upload PDF`  (verify)
- `Archivo PDF` → `PDF file`  (verify)
- `Usar plantilla` → `Use template`  (verify)
- `Crear manualmente` → `Create manually`  (verify)
- `Importar con IA` → `Import with AI`  (verify)
- `Importar con codigo` → `Import with code`  (verify)
- `Preferencias y alergias` → `Preferences & allergies`  (verify)

Run a quick Python NFC-normalized check (like the existing catalog tooling) to confirm which already have `en`, then add only the gaps. Validate the file parses as JSON after editing.

- [ ] **Step 2: Verify**

```bash
python3 -c "import json; json.load(open('bulkup/Localization/Localizable.xcstrings')); print('valid')"
```
Expected: `valid`. Build in Xcode; switch app language to English and confirm `⋯ → Change view`, `Weekly/Daily`, the import boxes, and the menus render in English.

- [ ] **Step 3: Commit**

```bash
git add bulkup/Localization/Localizable.xcstrings
git commit -m "i18n: english values for plan-screen alignment strings"
```

---

## Self-Review

**Spec coverage:**
- Both hubs → inline tabs → Task 2 (training already had them), Task 6 (diet gains them). ✓
- One contextual `⋯` menu → Task 2 (training), Task 6 (diet). ✓
- View mode → `⋯ → Cambiar vista`; inline pill removed → Tasks 1 + 2. ✓
- Full-width navigator → Task 3 (training strip), Task 7 (diet strip). ✓
- Training IA = diet-style screen → Tasks 4 (shared subview) + 5 (training IA body). ✓
- Diet keeps day model → no week logic added anywhere. ✓
- Localization → Task 8. ✓

**Placeholder scan:** Task 5 references existing subviews (`planNameField`, `datesSection`, `aiDetectionList`) "as they exist in CreateTrainingPlanView" — the implementer reuses the file's current name field / date toggle / feature list rather than inventing them; this is reuse of present code, not a placeholder. Task 3 and Task 7 give the exact full-bleed technique (negative `screenH` padding) with the reason. No "TBD"/"add error handling"/etc.

**Type consistency:** `TrainingView.ViewMode` (Task 1) is referenced as `TrainingView.ViewMode` in Task 2; `@AppStorage("trainingViewMode")` key string is identical in Tasks 1 and 2; `AIImportUploadBoxes(tint:onPickPDF:onPickImage:disabled:)` signature defined in Task 4 matches its use in Tasks 4 and 5; `DietHubSection`/`selectedView` defined and used within Task 6.

## Notes / Deliberate scope decisions (flag to user)

- The active-plan `⋯` does NOT include per-plan Editar/Compartir/Eliminar — those already live on each plan card in the library list, and adding active-plan wiring would expand scope/risk. The `⋯` focuses on `Cambiar vista` + create/import, which is the user's stated ask. Easy follow-up if wanted.
- `Importar con código` is intentionally omitted from the diet `⋯` (diet has no code-import today; cross-screen code import is a feature beyond alignment).
- Training keeps an optional date toggle on its IA screen (diet has none) because training plans are week-dated — the one allowed divergence from "identical."
