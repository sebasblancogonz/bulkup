# English Localization — Design

**Date:** 2026-06-19
**Status:** Approved (design), pending implementation plan

## Goal

Offer the BulkUp iOS app in **English** in addition to its current Spanish, so a
user can run the app's interface in either language. Switching applies live via
an in‑app picker, and defaults to the device language.

## Scope

**In scope — UI chrome only:**
- All of the app's own user‑facing text: buttons, labels, titles, tab names,
  settings, onboarding, alerts, error messages, empty states, validation copy.
- User‑facing date/number formatting that should follow the chosen language.
- An in‑app language picker plus device‑language default.

**Explicitly out of scope:**
- AI‑parsed / backend‑generated plan content (diet & training plan bodies, meal
  descriptions, supplement notes) — stays in whatever language it was authored.
- The Spanish weekday **data** keys ("Lunes", "Miércoles", …) used for weight
  storage and plan‑day matching. These are data, not UI, and the day‑name
  normalization logic is unaffected.
- Backend/API changes. This is a client‑only change.

**Accepted consequence:** an English user sees English UI chrome wrapping
Spanish‑authored plan content. That is expected and acceptable for this phase.

## Languages

- **Source language: Spanish.** Existing string literals are Spanish and become
  the String Catalog keys — least churn.
- **Added language: English.**
- Project `knownRegions` includes `es` and `en`; the String Catalog source
  language is set to Spanish so extraction keys match the literals.

## Architecture & Components

### 1. String Catalog (`Localizable.xcstrings`)
A single String Catalog is the translation store.
- `Text("…")` and other `LocalizedStringKey` literals **auto‑extract** at build
  time — no code change for those.
- Non‑auto cases are wrapped manually with `String(localized:)`:
  - `errorMessage = "…"` and other plain‑`String` assignments shown to the user.
  - `.alert` titles/messages constructed from `String`.
  - `Text(someStringVariable)` (a `String`, not a literal — does not extract).
  - String interpolations and concatenations (use `String(localized:)` with
    interpolation arguments, or `AttributedString`/format args as needed).
- Every catalog entry gets an English translation.

### 2. `LanguageManager` (live‑switch core)
A `@MainActor ObservableObject` singleton:
- Holds `enum AppLanguage { case system, spanish, english }`, persisted in
  `UserDefaults`.
- Default is `.system` → follows the device language.
- On change: installs the selected `.lproj` by setting a custom `Bundle`
  subclass on `Bundle.main` (the standard localization‑override technique) and
  publishes a change so the root view re‑renders with
  `.environment(\.locale, <selected locale>)`.
- Result: both `Text` and `String(localized:)` resolve to the chosen language
  **immediately**, with no app relaunch.

### 3. Settings picker
A "Language / Idioma" picker in `SettingsView` (System / Español / English)
bound to `LanguageManager`.

### 4. Formatters
- Repoint **user‑facing** `es_ES`‑pinned `DateFormatter`s (e.g. `TrainingView`
  weekday/month labels, `ProgressDashboardView` display formatters) at the
  active locale so dates localize with the UI.
- **Leave `en_US_POSIX` formatters untouched** — those produce stable
  API/date‑key strings (e.g. `yyyy-MM-dd` week keys) and must not localize;
  changing them would break the weekday‑key matching logic.

## Data Flow

1. App launch → `LanguageManager` reads persisted `AppLanguage` (default
   `.system`) → installs the matching bundle/locale before the first view renders.
2. View hierarchy renders; `Text`/`String(localized:)` resolve against the
   installed localization; the root carries `.environment(\.locale,…)`.
3. User opens Settings → picks a language → `LanguageManager` updates
   `UserDefaults`, swaps the bundle/locale, publishes → UI re‑renders live.

## Error Handling / Edge Cases

- **Missing English translation:** falls back to the Spanish source string
  (String Catalog default), so the UI is never blank.
- **Swizzle failure / unexpected behavior:** fallback is Approach B
  (`AppleLanguages` + relaunch prompt). Documented as the contingency.
- **`.system` with an unsupported device language:** resolves to the base
  (Spanish) per standard iOS fallback.

## Testing

- **Self‑check (automated, lightweight):**
  - Assert a sample set of known keys have non‑empty English values in the
    catalog (catches missing translations).
  - Assert `LanguageManager` override changes the bundle's resolved
    `localizedString(forKey:)` for a sample key (es vs en differ).
- **Manual:** launch with device set to English and to Spanish; toggle the
  in‑app picker through System/Español/English and confirm live switching across
  a few representative screens (onboarding, tabs, settings, an alert/error).

## Phasing

All within "translate everything":
1. **Infrastructure:** add the catalog, `LanguageManager`, Settings picker, and
   formatter repointing; wire a handful of keys end‑to‑end so the app builds and
   switches live.
2. **Full sweep + translations, batched by area** (~1,700 strings across ~60
   files is too large for one pass): onboarding/auth → tabs/shell → training →
   diet → RM/measurements/friends/profile/subscription → common components.
   Auto‑extraction handles most literals; the manual `String(localized:)`
   wrapping of non‑`Text` strings is the careful part. Each batch builds.

## Risks

- **Bundle swizzle** is a well‑worn but non‑Apple‑blessed technique; contingency
  is the relaunch approach.
- **Sweep size:** ~1,700 strings / ~60 files. Auto‑extraction reduces the code
  edits, but the non‑`Text` wrapping and translation volume are substantial and
  will land in batches.
- **Interpolated/concatenated strings** are the most error‑prone to externalize
  (word order differs across languages); these need format arguments, not naive
  concatenation.
