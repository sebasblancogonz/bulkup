# English Localization Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Offer the app's UI in English alongside Spanish, with a live in-app language picker that defaults to the device language.

**Architecture:** A single `Localizable.xcstrings` String Catalog (source language Spanish, English added). A `LanguageManager` persists the choice and installs the selected `.lproj` onto `Bundle.main` (via `object_setClass`) so both `Text` and `String(localized:)` resolve to the chosen language; the root view applies `.environment(\.locale,)` and rebuilds via `.id(language)` for instant switching. Dynamic/backend content stays in its authored language.

**Tech Stack:** SwiftUI, Xcode String Catalogs (`.xcstrings`), `UserDefaults`, Objective-C runtime (`object_setClass`/associated objects).

**Verification note:** This project has **no XCTest target**. Verification per task = `xcodebuild` build success + a runnable `#if DEBUG` self-check (Task 6) + manual language toggle. Do not add a test target (out of scope).

**Build command (used throughout):**
```bash
cd /Users/sebastian.blanco/Documents/Sebas/bulkup
xcodebuild -scheme bulkup-Dev -destination 'generic/platform=iOS Simulator' build CODE_SIGNING_ALLOWED=NO 2>&1 | grep -E "error:|BUILD SUCCEEDED|BUILD FAILED"
```

---

## File Structure

- Create: `bulkup/Localization/Localizable.xcstrings` — the String Catalog (all UI strings, es source + en).
- Create: `bulkup/Localization/LanguageManager.swift` — `AppLanguage` enum + `LanguageManager` observable singleton.
- Create: `bulkup/Localization/Bundle+Language.swift` — `LocalizedBundle` + `Bundle.setLanguage(_:)`.
- Modify: `bulkup.xcodeproj/project.pbxproj` — add `es` to `knownRegions` (en already present).
- Modify: `bulkup/ContentView.swift` — inject `LanguageManager`, apply `.environment(\.locale,)` + `.id(language)`.
- Modify: `bulkup/Views/SettingsView.swift` — add language picker to the "Personalización" section.
- Modify (Phase 1): `bulkup/Views/TrainingView.swift`, `bulkup/Views/ProgressDashboardView.swift` — repoint user-facing `es_ES` display formatters to the active locale.
- Modify (Phase 2, batched): all view/viewmodel files containing user-facing Spanish string literals (~60 files).

---

## PHASE 1 — Infrastructure

### Task 1: Add the String Catalog and register languages

**Files:**
- Create: `bulkup/Localization/Localizable.xcstrings`
- Modify: `bulkup.xcodeproj/project.pbxproj` (knownRegions)

- [ ] **Step 1: Create the catalog with Spanish source + two seeded keys**

Create `bulkup/Localization/Localizable.xcstrings` with this exact content (these two keys are used by the Task 6 self-check):

```json
{
  "sourceLanguage" : "es",
  "strings" : {
    "Ajustes" : {
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "Settings" } }
      }
    },
    "Idioma / Language" : {
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "Language" } }
      }
    }
  },
  "version" : "1.0"
}
```

- [ ] **Step 2: Register `es` in knownRegions**

In `bulkup.xcodeproj/project.pbxproj`, find the `knownRegions = ( … );` block (around line 120). It already contains `en` and `Base`. Add `es,` so it reads (order not significant):

```
knownRegions = (
    en,
    Base,
    es,
);
```

- [ ] **Step 3: Build to confirm the catalog is picked up and `es.lproj`/`en.lproj` get generated**

Run the build command. Expected: `BUILD SUCCEEDED`. (Synchronized file groups auto-include the new files; no manual target membership needed.)

- [ ] **Step 4: Commit**

```bash
git add bulkup/Localization/Localizable.xcstrings bulkup.xcodeproj/project.pbxproj
git commit -m "feat(i18n): add String Catalog (es source, en) and register locales"
```

---

### Task 2: `Bundle.setLanguage` override

**Files:**
- Create: `bulkup/Localization/Bundle+Language.swift`

- [ ] **Step 1: Write the bundle override**

Create `bulkup/Localization/Bundle+Language.swift`:

```swift
import Foundation
import ObjectiveC

private var associatedLanguageBundleKey: UInt8 = 0

/// When installed on Bundle.main, routes localized-string lookups to the
/// selected .lproj bundle so String(localized:)/NSLocalizedString respect an
/// in-app language override.
final class LocalizedBundle: Bundle, @unchecked Sendable {
    override func localizedString(forKey key: String, value: String?, table tableName: String?) -> String {
        if let override = objc_getAssociatedObject(self, &associatedLanguageBundleKey) as? Bundle {
            return override.localizedString(forKey: key, value: value, table: tableName)
        }
        return super.localizedString(forKey: key, value: value, table: tableName)
    }
}

extension Bundle {
    private static let installOverrideOnce: Void = {
        object_setClass(Bundle.main, LocalizedBundle.self)
    }()

    /// Install a language code's .lproj as the active localization.
    /// Pass nil to follow the system default.
    static func setLanguage(_ language: String?) {
        _ = installOverrideOnce
        var override: Bundle?
        if let language,
           let path = Bundle.main.path(forResource: language, ofType: "lproj"),
           let langBundle = Bundle(path: path) {
            override = langBundle
        }
        objc_setAssociatedObject(
            Bundle.main, &associatedLanguageBundleKey, override, .OBJC_ASSOCIATION_RETAIN_NONATOMIC
        )
    }
}
```

- [ ] **Step 2: Build**

Run the build command. Expected: `BUILD SUCCEEDED`.

- [ ] **Step 3: Commit**

```bash
git add bulkup/Localization/Bundle+Language.swift
git commit -m "feat(i18n): add Bundle language override"
```

---

### Task 3: `LanguageManager`

**Files:**
- Create: `bulkup/Localization/LanguageManager.swift`

- [ ] **Step 1: Write the manager**

Create `bulkup/Localization/LanguageManager.swift`:

```swift
import SwiftUI

enum AppLanguage: String, CaseIterable, Identifiable {
    case system
    case spanish = "es"
    case english = "en"

    var id: String { rawValue }

    /// .lproj code to install, or nil to follow the device.
    var localeCode: String? {
        switch self {
        case .system: return nil
        case .spanish: return "es"
        case .english: return "en"
        }
    }
}

@MainActor
final class LanguageManager: ObservableObject {
    static let shared = LanguageManager()
    private let storageKey = "app_language"

    @Published var language: AppLanguage {
        didSet {
            UserDefaults.standard.set(language.rawValue, forKey: storageKey)
            Bundle.setLanguage(language.localeCode)
        }
    }

    /// Locale for SwiftUI's environment (drives Text + formatters).
    var locale: Locale {
        if let code = language.localeCode { return Locale(identifier: code) }
        return Locale(identifier: Locale.preferredLanguages.first ?? "es")
    }

    private init() {
        let stored = UserDefaults.standard.string(forKey: storageKey)
        let initial = AppLanguage(rawValue: stored ?? AppLanguage.system.rawValue) ?? .system
        self.language = initial
        Bundle.setLanguage(initial.localeCode)
    }
}
```

- [ ] **Step 2: Build**

Run the build command. Expected: `BUILD SUCCEEDED`.

- [ ] **Step 3: Commit**

```bash
git add bulkup/Localization/LanguageManager.swift
git commit -m "feat(i18n): add LanguageManager"
```

---

### Task 4: Wire LanguageManager into the app root

**Files:**
- Modify: `bulkup/ContentView.swift`

- [ ] **Step 1: Inject manager, apply locale + rebuild-on-change**

In `bulkup/ContentView.swift`, add to `ContentView`'s properties (next to `@StateObject private var authManager`):

```swift
    @StateObject private var languageManager = LanguageManager.shared
```

Wrap the existing top-level content of `ContentView.body` so the locale and a rebuild id are applied to the whole tree. Locate the outermost view returned by `body` and append these modifiers to it:

```swift
        .environment(\.locale, languageManager.locale)
        .environmentObject(languageManager)
        .id(languageManager.language)
```

(`.id(languageManager.language)` forces a full rebuild on switch so `String(localized:)` strings — which cache per render — refresh immediately.)

- [ ] **Step 2: Build**

Run the build command. Expected: `BUILD SUCCEEDED`.

- [ ] **Step 3: Commit**

```bash
git add bulkup/ContentView.swift
git commit -m "feat(i18n): apply selected locale at app root with live rebuild"
```

---

### Task 5: Settings language picker

**Files:**
- Modify: `bulkup/Views/SettingsView.swift`

- [ ] **Step 1: Add the environment object**

In `SettingsView` (near `@EnvironmentObject var authManager: AuthManager`), add:

```swift
    @EnvironmentObject var languageManager: LanguageManager
```

- [ ] **Step 2: Add the picker to the "Personalización" section**

Inside the `Section("Personalización")` block in `SettingsView.body`, add this as the first `SettingsPicker` (it reuses the existing component, which takes `selection: Binding<String>` and `options: [(String, String)]`):

```swift
                    SettingsPicker(
                        icon: "globe",
                        iconColor: BulkUpColors.accent,
                        title: "Idioma / Language",
                        selection: Binding(
                            get: { languageManager.language.rawValue },
                            set: { languageManager.language = AppLanguage(rawValue: $0) ?? .system }
                        ),
                        options: [
                            ("system", "Sistema / System"),
                            ("es", "Español"),
                            ("en", "English"),
                        ]
                    )
```

- [ ] **Step 3: Build**

Run the build command. Expected: `BUILD SUCCEEDED`.

- [ ] **Step 4: Manual check**

Run the app, open Settings → Personalización → "Idioma / Language", switch to English. Expected: the two seeded strings ("Ajustes"→"Settings", "Idioma / Language"→"Language") flip to English immediately wherever they appear; switch back to Español restores them. (Most of the app is still Spanish until Phase 2.)

- [ ] **Step 5: Commit**

```bash
git add bulkup/Views/SettingsView.swift
git commit -m "feat(i18n): add in-app language picker to Settings"
```

---

### Task 6: DEBUG self-check (runnable verification)

**Files:**
- Modify: `bulkup/Localization/LanguageManager.swift`

- [ ] **Step 1: Add a debug self-check method**

Append to `LanguageManager` (inside the class):

```swift
#if DEBUG
    /// Asserts the localization infra is wired: both lproj bundles exist and the
    /// English override actually changes a known string. Call once at launch.
    static func runSelfCheck() {
        guard
            let esPath = Bundle.main.path(forResource: "es", ofType: "lproj"),
            let enPath = Bundle.main.path(forResource: "en", ofType: "lproj"),
            let esBundle = Bundle(path: esPath),
            let enBundle = Bundle(path: enPath)
        else {
            assertionFailure("i18n: es/en .lproj not found — catalog or knownRegions misconfigured")
            return
        }
        let es = esBundle.localizedString(forKey: "Ajustes", value: nil, table: nil)
        let en = enBundle.localizedString(forKey: "Ajustes", value: nil, table: nil)
        assert(es == "Ajustes", "i18n: Spanish source string changed unexpectedly (got \(es))")
        assert(en == "Settings", "i18n: English translation missing/incorrect (got \(en))")
    }
#endif
```

- [ ] **Step 2: Call it at launch**

In `bulkup/App/BulkUp.swift`, inside `init()` (after `APIConfig.validateConfiguration()`), add:

```swift
#if DEBUG
        LanguageManager.runSelfCheck()
#endif
```

- [ ] **Step 3: Build and run (debug) to exercise the assert**

Run the build command (Expected: `BUILD SUCCEEDED`), then launch the app in the simulator. Expected: no assertion failure in the console (the seeded keys resolve es→"Ajustes", en→"Settings").

- [ ] **Step 4: Commit**

```bash
git add bulkup/Localization/LanguageManager.swift bulkup/App/BulkUp.swift
git commit -m "test(i18n): debug self-check for localization wiring"
```

---

### Task 7: Repoint user-facing display formatters

**Files:**
- Modify: `bulkup/Views/TrainingView.swift` (lines using `Locale(identifier: "es_ES")`)
- Modify: `bulkup/Views/ProgressDashboardView.swift` (the `es_ES` formatter)

- [ ] **Step 1: Replace `es_ES` display locales with the active locale**

In each **user-facing display** `DateFormatter` that currently sets `Locale(identifier: "es_ES")`, replace it with the app's active locale:

```swift
// before
f.locale = Locale(identifier: "es_ES")
// after
f.locale = LanguageManager.shared.locale
```

Apply to: `TrainingView.swift` (the weekday/month label formatters around lines 45, 54, 76, 84) and `ProgressDashboardView.swift` (line ~886).

**Do NOT change** any `Locale(identifier: "en_US_POSIX")` formatter — those produce stable `yyyy-MM-dd` keys (incl. the weekday weight-keys) and must not localize.

- [ ] **Step 2: Build**

Run the build command. Expected: `BUILD SUCCEEDED`.

- [ ] **Step 3: Manual check**

With device/app set to English, confirm weekday/month labels render in English; the underlying plan day data (Spanish) is unchanged. Switch to Español → labels return to Spanish.

- [ ] **Step 4: Commit**

```bash
git add bulkup/Views/TrainingView.swift bulkup/Views/ProgressDashboardView.swift
git commit -m "feat(i18n): localize user-facing date formatters (leave en_US_POSIX keys)"
```

---

## PHASE 2 — String sweep + English translations (batched)

> Phase 2 externalizes and translates the ~1,700 Spanish UI strings. It is done in **batches by area** so each commit builds. Every batch follows the identical procedure below. Order: (A) onboarding/auth, (B) tabs/shell + common components, (C) training, (D) diet, (E) RM/measurements, (F) friends/profile/subscription/settings.

### Per-batch procedure (repeat for each batch A–F)

**Files:** the `.swift` files in that area + `bulkup/Localization/Localizable.xcstrings`.

- [ ] **Step 1: Find non-auto-extracted strings in the batch's files**

Auto-extraction handles `Text("literal")`. You must manually wrap everything else. Find candidates:

```bash
cd /Users/sebastian.blanco/Documents/Sebas/bulkup
# plain-String user-facing assignments / args in the batch dir:
grep -rnE '(errorMessage|message|title|label|placeholder)\s*=\s*"[^"]*[A-Za-zÁÉÍÓÚáéíóúñ]' <batch-paths>
grep -rnE 'Text\([a-zA-Z]' <batch-paths>          # Text(stringVariable) — won't extract
grep -rnE '\.navigationTitle\("|alert\("|\bLabel\("' <batch-paths>
```

- [ ] **Step 2: Wrap non-`Text` strings with `String(localized:)`**

For each user-facing plain `String`, wrap it. Examples (apply the matching shape):

```swift
// plain assignment
errorMessage = "Usuario no autenticado"
// becomes
errorMessage = String(localized: "Usuario no autenticado")

// interpolation — use a format key with arguments, NOT concatenation
let s = "Serie \(n) de \(total)"
// becomes (the catalog key uses %lld placeholders)
let s = String(localized: "Serie \(n) de \(total)")   // Swift maps to "Serie %lld de %lld"
```

`Text("literal")` needs **no change** (auto-extracts). `Text(variable)` where `variable` is a localized `String` is fine once the variable was produced via `String(localized:)`.

- [ ] **Step 3: Build to confirm compilation**

Run the build command. Expected: `BUILD SUCCEEDED`.

> **IMPORTANT — command-line `xcodebuild` does NOT auto-populate the catalog.**
> Verified empirically: extracted `Text("…")` literals are **not** written back
> into the source `Localizable.xcstrings` by `xcodebuild` (that is an Xcode-IDE-only
> behavior). Therefore you must add every key to the catalog **manually** in
> Step 4 — do not expect the build to discover them. A `Text("Hola")` literal
> still localizes correctly at runtime **as long as the catalog has a matching
> entry** (the build compiles `en.lproj`/`es.lproj` from the catalog).

- [ ] **Step 4: Manually add catalog entries (key + English) for every user-facing string in this batch**

> **Invariant (do not break):** the catalog MUST keep emitting `es.lproj`, which
> requires at least the seeded keys ("Ajustes", "Idioma / Language") to retain
> their explicit `es` localizations. New keys need **only an `en` value** — a
> string with no `es` entry still resolves correctly in Spanish because an
> `es.lproj` lookup miss returns the key itself (the Spanish source text). Do not
> delete the seeded `es` entries.

Open `bulkup/Localization/Localizable.xcstrings` and, for **every** user-facing
Spanish string in this batch (both the `Text("…")` literals AND the strings you
wrapped in `String(localized:)`), add an entry whose key is the exact Spanish
string and whose `en` `stringUnit` `value` is the English translation with
`state: "translated"`. The key must match the literal character-for-character.
Example entry:

```json
"Usuario no autenticado" : {
  "localizations" : {
    "en" : { "stringUnit" : { "state" : "translated", "value" : "User not authenticated" } }
  }
}
```

For format strings, keep placeholders identical (`%lld`, `%@`) and reorder words as English grammar requires:

```json
"Serie %lld de %lld" : {
  "localizations" : {
    "en" : { "stringUnit" : { "state" : "translated", "value" : "Set %1$lld of %2$lld" } }
  }
}
```

- [ ] **Step 5: Build, then verify the compiled `en.lproj` contains this batch's translations**

Run the build command (Expected: `BUILD SUCCEEDED`). Then confirm the catalog actually compiled into the English bundle (this replaces the IDE spot-check, since we're headless):

```bash
APP=$(find ~/Library/Developer/Xcode/DerivedData/bulkup-*/Build/Products/Development-iphonesimulator/bulkup.app -maxdepth 0 | head -1)
# spot-check a few keys you added this batch resolve to English:
find "$APP/en.lproj" -name "*.strings" -exec plutil -p {} \; | grep -F "<one of your English values>"
```
Expected: the English values appear. (Optional/manual: launch in the simulator with the app set to English and visit the batch's screens.) Untranslated keys fall back to Spanish (acceptable mid-sweep).

- [ ] **Step 6: Commit the batch**

```bash
git add <batch .swift paths> bulkup/Localization/Localizable.xcstrings
git commit -m "feat(i18n): localize <area> strings to English"
```

### Batch list (each is one pass of the procedure above)

- [ ] **Batch A — Onboarding & auth:** `bulkup/Views/OnboardingView.swift`, `bulkup/Views/LoginView.swift`.
- [ ] **Batch B — Shell & common components:** `bulkup/ContentView.swift`, `bulkup/Views/MainAppView.swift`, `bulkup/Views/TodayView.swift`, `bulkup/Views/Components/Common/*.swift`.
- [ ] **Batch C — Training:** `bulkup/Views/TrainingView.swift`, `bulkup/Views/Components/Training/*.swift`.
- [ ] **Batch D — Diet:** `bulkup/Views/DietView.swift`, `bulkup/Views/Components/Diet/*.swift`, `bulkup/Views/Components/SimpleDayCardView.swift`.
- [ ] **Batch E — RM & measurements & progress:** `bulkup/Views/RMTrackerView.swift`, `bulkup/Views/Components/RM/*.swift`, `bulkup/Views/BodyMeasurementsView.swift`, `bulkup/Views/Components/Measurements/*.swift`, `bulkup/Views/ProgressDashboardView.swift`.
- [ ] **Batch F — Friends, profile, subscription, settings, explorer:** `bulkup/Views/Components/Friends/*.swift`, `bulkup/Views/Components/Profile/*.swift`, `bulkup/Views/ProfileView.swift`, `bulkup/Views/UserProfileView.swift`, `bulkup/Views/SubscriptionView.swift`, `bulkup/Views/SubscriptionRequiredView.swift`, `bulkup/Views/SettingsView.swift`, `bulkup/Views/ExerciseExplorerView.swift`.

### Phase 2 completion check

- [ ] **Final scan for stragglers**

```bash
cd /Users/sebastian.blanco/Documents/Sebas/bulkup
# Spanish string literals NOT inside Text(...) or String(localized:) — review each:
grep -rnE '"[A-Za-zÁÉÍÓÚáéíóúñ ]{4,}"' bulkup/Views bulkup/ViewModels --include="*.swift" \
  | grep -vE 'String\(localized:|Text\(|Locale\(identifier|forKey:|systemName:|"en_US_POSIX"'
```

Review each remaining hit: localize if user-facing, leave if it's an identifier/key/SF Symbol/log. Localize and commit any genuine UI strings found.

- [ ] **Verify no blank English values remain for keys on visited screens** (open the catalog; `state` should be `translated`, not `new`, for shipped keys).

---

## Self-Review (completed during planning)

- **Spec coverage:** UI-chrome scope → Phase 2 batches A–F; Spanish source + English → Task 1; live in-app override (Approach A) → Tasks 2–5; device default → `AppLanguage.system` (Task 3); formatters repointed, `en_US_POSIX` preserved → Task 7; testing → Task 6 self-check + manual steps; out-of-scope dynamic content → untouched (no task). All spec sections mapped.
- **Placeholder scan:** No TBD/TODO; all code steps show real code; the per-batch procedure is concrete (commands + example wrappings) rather than "translate the rest".
- **Type consistency:** `AppLanguage`/`.localeCode`/`.locale`/`LanguageManager.shared.language` used consistently across Tasks 3–7; `Bundle.setLanguage(_:)` signature matches its call sites; seeded keys ("Ajustes", "Idioma / Language") in Task 1 match the Task 6 self-check.
