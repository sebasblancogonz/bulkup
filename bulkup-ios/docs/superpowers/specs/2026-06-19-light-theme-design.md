# Light Theme (warm, immersive) — Design

**Date:** 2026-06-19
**Status:** Approved (design), pending implementation plan

## Goal

Add a fully working **light theme** alongside the existing dark theme, selectable
via the existing Settings picker (System / Light / Dark, defaulting to System).
The light palette is **warm off-white**, and the dark theme's **immersive
aesthetic** (gradients, glows, strong shadows) is preserved — recolored/tuned for
light, not flattened.

## Background / current state

- `BulkUpColors` (in `bulkup/Utils/DesignSystem.swift`) is an `enum` of 32
  `static let` tokens with **fixed dark hex** values (e.g. `background #0A0A0A`,
  `textPrimary .white`). A few are derived: `accentGradient` (LinearGradient from
  `accent`/`accentGlow`), `border` (`white.opacity(0.06)`), `muscleActive`
  (`accent.opacity`).
- The app is **hardcoded dark**: `ContentView` applies `.preferredColorScheme(.dark)`
  + `forceDarkMode()` (`window.overrideUserInterfaceStyle = .dark`); `MainAppView`
  forces `.environment(\.colorScheme, .dark)`. The Settings "Tema de Apariencia"
  picker writes `@AppStorage("theme")` (system/light/dark) and has
  `overrideUserInterfaceStyle` logic (`SettingsView` ~389–393) but it's overridden
  by the forced-dark, so it's currently a dead control.
- Dark-baked surface to retrofit: **~64** hardcoded `.white`/`.black`/ad-hoc
  `Color(hex:)` literals and **~62** gradient/shadow/material sites across **~56**
  view files.

## Scope

**In scope (full polish, one cohesive effort):**
- Make all 32 `BulkUpColors` tokens adaptive (light + dark).
- A warm off-white light palette.
- Remove the forced-dark; wire `.preferredColorScheme` to the `theme` setting.
- Adaptive elevation: light-tuned shadow/glow so the immersive look holds in light.
- Audit every view: replace hardcoded color literals with adaptive tokens; give
  each gradient/glow/shadow a light-tuned variant.

**Out of scope:**
- Redesigning layouts or changing the dark theme's appearance.
- New theming features beyond System/Light/Dark.

## Architecture

### Adaptive color mechanism
Keep the `BulkUpColors` enum; change each base token to a **dynamic color**:
```swift
static let background = Color(uiColor: UIColor { traits in
    traits.userInterfaceStyle == .dark ? UIColor(hex: "#0A0A0A") : UIColor(hex: "#FAF9F6")
})
```
(Requires a `UIColor(hex:)` initializer alongside the existing `Color(hex:)`.)
Tokens resolve per appearance automatically; `accentGradient`, `border`,
`muscleActive` inherit because they derive from the adaptive base tokens. This is
chosen over asset-catalog color sets (32 files of churn) and a `ThemeManager`
(env-injection plumbing) because dynamic `UIColor` gives appearance adaptation for
free with minimal structural change.

### Warm-light palette (initial values; tunable during implementation)
- background `#FAF9F6`, surface `#FFFFFF`, surfaceElevated `#FFFFFF`
- border `Color.black.opacity(0.08)`
- textPrimary `#1A1A1A`, textSecondary `#6E6E73`, textTertiary `#A0A0A5`
- onAccent `#000000` (black text on bright teal works in both modes)
- accent `#00E6C3` (unchanged); **add `accentText` = darker teal `#00A88F`** for
  teal text/icons on light where the bright teal fails contrast
- accentGlow/accentMuted: keep, light-tuned where used for glows
- success `#28B14C`, warning `#E6A700`, error `#E03B30` (deepened for light
  contrast; dark keeps current brighter values)
- training `#0094C9`, diet `#28B14C` (deepened for light)
- muscleDefault `#E5E3DD` (light) / current dark value

### Immersive elevation (recolored, not dropped)
- Add an adaptive `BulkUpColors.shadow` token (deep near-black low-opacity in dark;
  soft warm-gray low-opacity in light) and adaptive glow color.
- Add/extend modifiers in `bulkup/Utils/ViewModifiers.swift`
  (`flatCardStyle`/card/shadow helpers) to use the adaptive shadow/glow.
- Replace ad-hoc `.shadow(color: .black…)` sites with the adaptive modifier.
- Keep gradients (e.g. accent CTA gradient); ensure their colors are adaptive
  tokens so they re-tint for light.

### Theme application
- Remove `ContentView`'s `.preferredColorScheme(.dark)`, `forceDarkMode()`, and the
  window `overrideUserInterfaceStyle = .dark`; remove `MainAppView`'s
  `.environment(\.colorScheme, .dark)`.
- At the root, apply `.preferredColorScheme(themeColorScheme)` where
  `@AppStorage("theme")` maps `system → nil`, `light → .light`, `dark → .dark`.
- Reconcile `SettingsView`'s existing `overrideUserInterfaceStyle` logic so the
  picker drives the same setting (single source: the `theme` AppStorage).

### Per-screen audit (the bulk)
Across ~56 view files: replace hardcoded `.white`/`.black`/ad-hoc `Color(hex:)`
with the adaptive tokens (e.g. `.white` body text → `BulkUpColors.textPrimary`);
and give each gradient/glow/shadow a light-tuned variant (recolored). Batched by
area.

## Components / files

- `bulkup/Utils/DesignSystem.swift` — adaptive `BulkUpColors` + light palette +
  `UIColor(hex:)`; new `shadow`/glow tokens.
- `bulkup/Utils/ViewModifiers.swift` — adaptive shadow/glow/card modifiers.
- `bulkup/ContentView.swift`, `bulkup/Views/MainAppView.swift` — remove forced-dark;
  apply theme.
- `bulkup/Views/SettingsView.swift` — picker drives `theme`; reconcile override
  logic.
- ~56 `bulkup/Views/**.swift` — literal → token + gradient/shadow light tuning
  (per-area batches).

## Data flow

`theme` (`@AppStorage`) → root `.preferredColorScheme` → system resolves
`userInterfaceStyle` → dynamic `UIColor` closures pick light/dark hex → all tokens
+ derived gradients/shadows render for the active appearance. No app restart.

## Error handling / edge cases

- `system` follows the device; light/dark force regardless of device.
- Bright teal text on white → use `accentText` (darker teal) for legibility.
- Any `.white` text not migrated would be invisible on light → audit must be
  exhaustive (see testing).
- Dark-tuned image assets / overlays (logo lockups, hero gradients over images)
  may need light variants — flag any found during the audit; out-of-band assets
  noted for the user to supply if needed.

## Testing

No XCTest target. Therefore:
- A `#if DEBUG` self-check asserting a sample dynamic token resolves to **different**
  values under light vs dark traits (e.g. `BulkUpColors.background` resolved with a
  `.light` trait ≠ resolved with `.dark`), proving adaptivity is wired.
- Manual, per-screen visual QA in **light and dark** and via the **picker**, on a
  device/simulator. This is the gating step and is largely manual/behind login.

## Phasing (informs the plan)

1. **Adaptive infra + palette + theme wiring:** `UIColor(hex:)`, adaptive tokens
   with warm-light values, remove forced-dark, wire the picker, DEBUG self-check.
   Result: app switches light/dark live; tokens adapt (ad-hoc literals/shadows
   still dark-assuming).
2. **Adaptive elevation:** shadow/glow tokens + modifiers; replace ad-hoc shadow
   sites.
3. **Per-area screen audits (A–F):** onboarding/auth → shell/common → training →
   diet → RM/measurements/progress → friends/profile/subscription/settings.
   Replace literals with tokens; tune gradients/glows/shadows for light; visual QA
   each area in both modes.

## Risks

- **Taste-gated bulk:** preserving the immersive look means every gradient/glow/
  shadow gets a hand-tuned light variant; quality depends on visual review, which
  is manual and mostly behind login (user-driven QA).
- **Invisible-text risk:** missed `.white` literals vanish on light — thorough
  audit + per-screen QA required.
- **Largest visual change to date** across ~56 screens; multi-session, paced by
  review.
