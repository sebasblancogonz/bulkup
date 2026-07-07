# Light Theme (warm, immersive) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** A fully working warm-off-white light theme selectable via Settings (System/Light/Dark), preserving the dark theme's immersive gradients/glows/shadows (recolored for light).

**Architecture:** Keep the `BulkUpColors` enum but make each base token a dynamic `Color(uiColor: UIColor { traits in dark ? darkHex : lightHex })`, so tokens + derived gradients/opacities resolve per appearance. Remove the forced-dark and drive `.preferredColorScheme` from the `theme` AppStorage. Then audit ~56 views to replace hardcoded color literals with tokens and tune gradients/glows/shadows for light.

**Tech Stack:** SwiftUI, UIKit dynamic `UIColor`, `@AppStorage`.

**Verification:** No XCTest target. Verify via `xcodebuild` build + a `#if DEBUG` self-check (a token resolves differently for light vs dark traits) + manual per-screen visual QA in both modes. Do NOT add a test target.

**Build command:**
```bash
cd /Users/sebastian.blanco/Documents/Sebas/bulkup
xcodebuild -scheme bulkup-Dev -destination 'generic/platform=iOS Simulator' build CODE_SIGNING_ALLOWED=NO 2>&1 | grep -E "error:|BUILD SUCCEEDED|BUILD FAILED"
```

---

## File Structure

- Modify `bulkup/Utils/DesignSystem.swift` — add `UIColor(hex:)`; make `BulkUpColors` tokens adaptive + warm-light values; add `accentText`, adaptive `shadow`/glow tokens.
- Modify `bulkup/Utils/ViewModifiers.swift` — adaptive shadow/glow/card modifiers.
- Modify `bulkup/ContentView.swift` — remove forced-dark; apply `.preferredColorScheme(theme)`.
- Modify `bulkup/Views/MainAppView.swift` — remove `.environment(\.colorScheme,.dark)`.
- Modify `bulkup/Views/SettingsView.swift` — reconcile picker → `theme` (single source).
- Modify ~56 `bulkup/Views/**.swift` — literal→token + light-tune gradients/shadows (per-area batches A–F).

---

## PHASE 1 — Adaptive tokens + warm palette + theme wiring

### Task 1: `UIColor(hex:)` initializer

**Files:** Modify `bulkup/Utils/DesignSystem.swift`.

- [ ] **Step 1: Add the initializer**

Near the existing `extension Color { init(hex:) … }`, add:
```swift
import UIKit

extension UIColor {
    convenience init(hex: String) {
        let s = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: s).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch s.count {
        case 6: (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default: (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(red: CGFloat(r) / 255, green: CGFloat(g) / 255,
                  blue: CGFloat(b) / 255, alpha: CGFloat(a) / 255)
    }
}
```

- [ ] **Step 2: Build + commit**

Run the build command. Expected `BUILD SUCCEEDED`.
```bash
git add bulkup/Utils/DesignSystem.swift
git commit -m "feat(theme): add UIColor(hex:) initializer"
```

### Task 2: Adaptive `BulkUpColors` with warm-light palette

**Files:** Modify `bulkup/Utils/DesignSystem.swift`.

- [ ] **Step 1: Add a dynamic-color helper and rewrite the base tokens**

Add a helper inside (or above) `BulkUpColors`:
```swift
extension Color {
    /// Appearance-adaptive color from two hex values.
    static func adaptive(dark: String, light: String) -> Color {
        Color(uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark ? UIColor(hex: dark) : UIColor(hex: light)
        })
    }
}
```
Replace the base tokens in `BulkUpColors` (keep the derived ones — they recompute from these):
```swift
enum BulkUpColors {
    // Brand — Teal/Mint (accent stays vivid in both modes)
    static let accent = Color.adaptive(dark: "#00E6C3", light: "#00E6C3")
    static let accentGlow = Color.adaptive(dark: "#00FFD5", light: "#00D9BC")
    static let accentMuted = Color.adaptive(dark: "#00997F", light: "#00A88F")
    /// Teal for text/icons on light surfaces (bright teal fails contrast on white).
    static let accentText = Color.adaptive(dark: "#00E6C3", light: "#00A88F")
    static let accentGradient = LinearGradient(
        colors: [accent, accentGlow], startPoint: .leading, endPoint: .trailing
    )
    static let secondary = Color.adaptive(dark: "#7B61FF", light: "#6A4DF0")

    // Surfaces — true-black dark / warm off-white light
    static let background = Color.adaptive(dark: "#0A0A0A", light: "#FAF9F6")
    static let surface = Color.adaptive(dark: "#161616", light: "#FFFFFF")
    static let surfaceElevated = Color.adaptive(dark: "#1E1E1E", light: "#FFFFFF")
    static let border = Color.adaptive(dark: "#FFFFFF", light: "#000000").opacity(0.08)

    // Text
    static let textPrimary = Color.adaptive(dark: "#FFFFFF", light: "#1A1A1A")
    static let textSecondary = Color.adaptive(dark: "#8E8E93", light: "#6E6E73")
    static let textTertiary = Color.adaptive(dark: "#48484A", light: "#A0A0A5")
    static let onAccent = Color.adaptive(dark: "#000000", light: "#000000")

    // Semantic (deepened for light contrast)
    static let success = Color.adaptive(dark: "#30D158", light: "#28B14C")
    static let warning = Color.adaptive(dark: "#FFD60A", light: "#E6A700")
    static let error = Color.adaptive(dark: "#FF453A", light: "#E03B30")

    // Context
    static let training = Color.adaptive(dark: "#00D1FF", light: "#0094C9")
    static let diet = Color.adaptive(dark: "#30D158", light: "#28B14C")

    // Muscle map
    static let muscleDefault = Color.adaptive(dark: "#2A2A2A", light: "#E5E3DD")
    static let muscleActive = accent.opacity(0.9)

    // Elevation — adaptive shadow color (deep in dark, soft warm-gray in light)
    static let shadow = Color.adaptive(dark: "#000000", light: "#3A3733")
}
```
(`border` uses `.opacity(0.08)` on an adaptive black/white so it's a light hairline in light and the existing subtle white line in dark.)

- [ ] **Step 2: Build + commit**

Run the build command. Expected `BUILD SUCCEEDED`.
```bash
git add bulkup/Utils/DesignSystem.swift
git commit -m "feat(theme): adaptive BulkUpColors with warm-light palette"
```

### Task 3: Remove forced-dark + wire the picker

**Files:** Modify `bulkup/ContentView.swift`, `bulkup/Views/MainAppView.swift`, `bulkup/Views/SettingsView.swift`.

- [ ] **Step 1: ContentView — drive preferredColorScheme from the setting**

In `ContentView`, add:
```swift
    @AppStorage("theme") private var theme = "system"

    private var themeColorScheme: ColorScheme? {
        switch theme {
        case "light": return .light
        case "dark": return .dark
        default: return nil
        }
    }
```
Replace `.preferredColorScheme(.dark)` with `.preferredColorScheme(themeColorScheme)`. **Delete** the `.onAppear { … forceDarkMode() }` call and the entire `private func forceDarkMode()` (the `window.overrideUserInterfaceStyle = .dark`). Keep the rest of `onAppear`.

- [ ] **Step 2: MainAppView — remove the forced colorScheme**

In `bulkup/Views/MainAppView.swift`, delete the `.environment(\.colorScheme, .dark)` modifier (around line 287).

- [ ] **Step 3: SettingsView — make the picker apply the theme live**

`SettingsView` already writes `@AppStorage("theme")`. Ensure the theme picker's `set` also applies the override immediately so the change is instant without relying only on `preferredColorScheme` re-eval. Replace the existing `overrideUserInterfaceStyle` switch (~lines 389–393) with a helper applied on change of `theme`:
```swift
    private func applyTheme(_ value: String) {
        let style: UIUserInterfaceStyle = value == "light" ? .light : value == "dark" ? .dark : .unspecified
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .forEach { $0.overrideUserInterfaceStyle = style }
    }
```
Call `applyTheme(theme)` in `.onAppear` and in the theme picker's `set:` closure (or `.onChange(of: theme)`).

- [ ] **Step 4: Build + manual check**

Run the build command (Expected `BUILD SUCCEEDED`). Launch, open Settings → Personalización → Tema de Apariencia, switch to **Claro**: surfaces/text using `BulkUpColors` tokens flip to warm light immediately; switch back to Oscuro. (Ad-hoc literals/shadows will still look dark-assuming until Phase 3.)

- [ ] **Step 5: Commit**

```bash
git add bulkup/ContentView.swift bulkup/Views/MainAppView.swift bulkup/Views/SettingsView.swift
git commit -m "feat(theme): remove forced-dark; drive appearance from theme picker"
```

### Task 4: DEBUG self-check for adaptivity

**Files:** Modify `bulkup/Utils/DesignSystem.swift`, `bulkup/App/BulkUp.swift`.

- [ ] **Step 1: Add the self-check**

In `DesignSystem.swift`:
```swift
#if DEBUG
enum ThemeSelfCheck {
    static func run() {
        let dark = UIColor(BulkUpColors.background).resolvedColor(
            with: UITraitCollection(userInterfaceStyle: .dark))
        let light = UIColor(BulkUpColors.background).resolvedColor(
            with: UITraitCollection(userInterfaceStyle: .light))
        assert(dark != light, "theme: background must differ between light and dark")
        let tDark = UIColor(BulkUpColors.textPrimary).resolvedColor(
            with: UITraitCollection(userInterfaceStyle: .dark))
        let tLight = UIColor(BulkUpColors.textPrimary).resolvedColor(
            with: UITraitCollection(userInterfaceStyle: .light))
        assert(tDark != tLight, "theme: textPrimary must differ between light and dark")
    }
}
#endif
```

- [ ] **Step 2: Call it at launch**

In `bulkup/App/BulkUp.swift` `init()`, inside the existing `#if DEBUG` block, add `ThemeSelfCheck.run()`.

- [ ] **Step 3: Build + run (debug)**

Run the build command (Expected `BUILD SUCCEEDED`); launch in the simulator; confirm no assertion failure.

- [ ] **Step 4: Commit**

```bash
git add bulkup/Utils/DesignSystem.swift bulkup/App/BulkUp.swift
git commit -m "test(theme): debug self-check that tokens adapt to appearance"
```

---

## PHASE 2 — Adaptive elevation (shadows/glows)

### Task 5: Adaptive shadow/glow modifiers

**Files:** Modify `bulkup/Utils/ViewModifiers.swift`.

- [ ] **Step 1: Add adaptive elevation modifiers**

```swift
extension View {
    /// Soft adaptive card shadow (deep in dark, soft warm-gray in light).
    func cardShadow(radius: CGFloat = 12, y: CGFloat = 6) -> some View {
        shadow(color: BulkUpColors.shadow.opacity(0.18), radius: radius, x: 0, y: y)
    }
    /// Accent glow that softens in light mode.
    func accentGlowShadow(radius: CGFloat = 16) -> some View {
        shadow(color: BulkUpColors.accent.opacity(0.35), radius: radius, x: 0, y: 0)
    }
}
```
If `ViewModifiers.swift` already has card/elevation modifiers (e.g. `flatCardStyle`), update their `.shadow(color:)` to use `BulkUpColors.shadow.opacity(...)` instead of hardcoded `.black`.

- [ ] **Step 2: Build + commit**

Run the build command. Expected `BUILD SUCCEEDED`.
```bash
git add bulkup/Utils/ViewModifiers.swift
git commit -m "feat(theme): adaptive shadow/glow modifiers"
```

### Task 6: Replace ad-hoc black shadows with the adaptive modifier

**Files:** all of `bulkup/Views/**` containing `.shadow(color: .black` or `.shadow(color: Color.black`.

- [ ] **Step 1: Find them**

```bash
cd /Users/sebastian.blanco/Documents/Sebas/bulkup
grep -rn "\.shadow(color: *\.black\|\.shadow(color: *Color\.black" bulkup/Views --include="*.swift"
```

- [ ] **Step 2: Replace each**

Replace `.shadow(color: .black.opacity(x), radius: r, x: 0, y: y)` with `.cardShadow(radius: r, y: y)` (or, where the opacity/placement is intentional and specific, `.shadow(color: BulkUpColors.shadow.opacity(x), radius: r, x: 0, y: y)`). Leave shadows that are inside the widget extension (`BulkUpWidgets/`) — those render on the Lock Screen, not the app theme.

- [ ] **Step 3: Build + commit**

Run the build command. Expected `BUILD SUCCEEDED`.
```bash
git add bulkup/Views bulkup/Utils
git commit -m "feat(theme): route ad-hoc shadows through adaptive elevation"
```

---

## PHASE 3 — Per-area screen audit (batches A–F)

> Each batch audits one area's view files for dark-assuming color usage and tunes immersive treatments for light. Same procedure each time. After each batch, build and (ideally) visually QA the area in BOTH light and dark.

### Per-batch procedure (repeat for each batch)

**Files:** the area's `.swift` files under `bulkup/Views/`.

- [ ] **Step 1: Find dark-assuming literals in the batch's files**

```bash
cd /Users/sebastian.blanco/Documents/Sebas/bulkup
grep -rnE '\.white|Color\.white|\.black\b|Color\.black|Color\(hex:' <batch-paths>
grep -rnE 'LinearGradient|RadialGradient|\.shadow\(|ultraThinMaterial|\.blur\(' <batch-paths>
```

- [ ] **Step 2: Replace literals with adaptive tokens**

For each hit, classify and fix:
- `.foregroundColor(.white)` / `Color.white` used as **primary text/icon** → `BulkUpColors.textPrimary`.
- White used as a **surface/card fill** → `BulkUpColors.surface` / `.surfaceElevated`.
- `.black` used as **text** → `BulkUpColors.textPrimary`; as **text-on-accent** → `BulkUpColors.onAccent` (leave — it's correct in both).
- Ad-hoc `Color(hex: "#…")` that matches a token's intent → use the token; if it's a one-off shade, wrap it adaptive: `Color.adaptive(dark: "#…", light: "#…")`.
- Teal text/icons on a light surface → `BulkUpColors.accentText` (not `.accent`).
- **Leave** intentional always-dark/always-light cases (e.g. text over a fixed photographic hero, or `onAccent`); note them in the commit if non-obvious.

- [ ] **Step 3: Tune immersive treatments for light**

For each gradient/glow/shadow in the batch: ensure its colors are adaptive tokens (so they re-tint), and verify the look in light. Replace `.shadow(color: .black…)` with `.cardShadow()`/`BulkUpColors.shadow`. For glows, use `.accentGlowShadow()` or `BulkUpColors.accent.opacity(...)`. Gradients built from `BulkUpColors` tokens already adapt; gradients built from raw hex → make the hex adaptive.

- [ ] **Step 4: Build**

Run the build command. Expected `BUILD SUCCEEDED`.

- [ ] **Step 5: Visual QA (manual)**

Launch; for the batch's screens, toggle Settings → Tema de Apariencia between Claro and Oscuro. Confirm: no invisible text (white-on-white), readable contrast, surfaces/cards distinct, gradients/glows look intentional (not muddy) in light. Note any screen needing asset/light variants you can't fix in code (flag for the user).

- [ ] **Step 6: Commit the batch**

```bash
git add <batch paths>
git commit -m "feat(theme): light-tune <area> (literals→tokens, immersive treatments)"
```

### Batch list

- [ ] **Batch A — Onboarding & auth:** `bulkup/Views/OnboardingView.swift`, `bulkup/Views/LoginView.swift`.
- [ ] **Batch B — Shell & common:** `bulkup/ContentView.swift`, `bulkup/Views/MainAppView.swift`, `bulkup/Views/TodayView.swift`, `bulkup/Views/Components/Common/*.swift`, `bulkup/Utils/ViewModifiers.swift` (re-check after Phase 2).
- [ ] **Batch C — Training:** `bulkup/Views/TrainingView.swift`, `bulkup/Views/Components/Training/*.swift`.
- [ ] **Batch D — Diet:** `bulkup/Views/DietView.swift`, `bulkup/Views/Components/Diet/*.swift`, `bulkup/Views/Components/SimpleDayCardView.swift`.
- [ ] **Batch E — RM, measurements, progress:** `bulkup/Views/RMTrackerView.swift`, `bulkup/Views/Components/RM/*.swift`, `bulkup/Views/BodyMeasurementsView.swift`, `bulkup/Views/Components/Measurements/*.swift`, `bulkup/Views/ProgressDashboardView.swift`.
- [ ] **Batch F — Friends, profile, subscription, settings, explorer:** `bulkup/Views/Components/Friends/*.swift`, `bulkup/Views/Components/Profile/*.swift`, `bulkup/Views/ProfileView.swift`, `bulkup/Views/UserProfileView.swift`, `bulkup/Views/SubscriptionView.swift`, `bulkup/Views/SubscriptionRequiredView.swift`, `bulkup/Views/SettingsView.swift`, `bulkup/Views/ExerciseExplorerView.swift`.

### Phase 3 completion check

- [ ] **Final literal scan** — confirm no stray dark-assuming literals remain in app views:
```bash
cd /Users/sebastian.blanco/Documents/Sebas/bulkup
grep -rnE '\.foregroundColor\(\.white\)|Color\.white|\.foregroundColor\(\.black\)' bulkup/Views --include="*.swift" \
  | grep -v "onAccent"
```
Review each remaining hit; fix if it's UI chrome, leave (and note) if it's intentional over fixed media.
- [ ] **Full dual-mode QA** — one pass through all main screens in light, then dark, confirming parity.

---

## Self-Review (completed during planning)

- **Spec coverage:** adaptive mechanism (`UIColor(hex:)` + `Color.adaptive`) → Tasks 1–2; warm-light palette values → Task 2; `accentText` → Task 2; remove forced-dark + wire picker → Task 3; DEBUG self-check → Task 4; adaptive shadow/glow + replace ad-hoc → Tasks 5–6; per-screen literal/gradient audit batched A–F → Phase 3; testing (self-check + manual QA) → Task 4 + per-batch Step 5. All spec sections mapped.
- **Placeholder scan:** all code steps contain real code; the per-batch audit is a concrete procedure with grep commands + classification rules, not "fix the rest".
- **Type consistency:** `Color.adaptive(dark:light:)`, `UIColor(hex:)`, `BulkUpColors.accentText`/`.shadow`, `.cardShadow()`/`.accentGlowShadow()`, `themeColorScheme`, `applyTheme(_:)` used consistently across tasks. `theme` AppStorage key matches `SettingsView`'s existing key.
