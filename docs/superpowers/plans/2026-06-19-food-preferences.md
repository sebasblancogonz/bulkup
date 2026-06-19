# Food Preferences & Allergies Implementation Plan (Diet sub-project A)

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Let the user keep three free-text lists — allergies, liked foods, disliked foods — on their profile, edited from a screen reachable in the Diet section.

**Architecture:** Reuse the existing profile flow (`GET/PUT /profile`, `ProfileManager`). Add three `[]string` fields to the backend `User`/profile request+response, mirror them in the iOS profile Codables + `ProfileManager`, and build a `FoodPreferencesView` (three tag editors) entered from `DietHubView`.

**Tech Stack:** Go (Gin/mux + MongoDB), SwiftUI, existing `ProfileManager`/`APIService`.

**Verification:** Backend can't build locally (tesseract/leptonica cgo) → `gofmt` the changed Go files. iOS has no XCTest target → `xcodebuild` build + a `#if DEBUG` self-check for tag hygiene + manual round-trip. Do NOT add a test target.

**iOS build command:**
```bash
cd /Users/sebastian.blanco/Documents/Sebas/bulkup
xcodebuild -scheme bulkup-Dev -destination 'generic/platform=iOS Simulator' build CODE_SIGNING_ALLOWED=NO 2>&1 | grep -E "error:|BUILD SUCCEEDED|BUILD FAILED"
```

**Field contract (stable — sub-project B consumes these):** `allergies`, `likedFoods`, `dislikedFoods` (arrays of strings).

---

## File Structure

- Backend `internal/models/user.go` — add 3 fields to `User`, `UpdateProfileRequest`, `ProfileResponse`.
- Backend `internal/services/profile.go` — set the 3 fields in `UpdateProfile`.
- Backend `internal/handlers/profile.go` — include the 3 fields when building `ProfileResponse` from `User` (if the handler maps it).
- iOS — the file defining `ProfileResponse` + `UpdateProfileRequest` Codables (find via grep); add 3 fields.
- iOS `bulkup/ViewModels/ProfileManager.swift` — `updateFoodPreferences(...)`.
- iOS `bulkup/Views/Components/Diet/FoodPreferencesView.swift` (new) — three tag editors + `FoodTagInput` helper.
- iOS `bulkup/Views/Components/Diet/DietHubView.swift` — entry point row.

---

## PHASE 1 — Backend

### Task 1: Add the three lists to the User model + profile request/response + update

**Files:** `internal/models/user.go`, `internal/services/profile.go`, `internal/handlers/profile.go`.

- [ ] **Step 1: Add fields to `User`**

In `internal/models/user.go`, in `type User struct`, after `NextReviewDate`:
```go
	Allergies     []string `bson:"allergies,omitempty" json:"allergies,omitempty"`
	LikedFoods    []string `bson:"likedFoods,omitempty" json:"likedFoods,omitempty"`
	DislikedFoods []string `bson:"dislikedFoods,omitempty" json:"dislikedFoods,omitempty"`
```

- [ ] **Step 2: Add to `UpdateProfileRequest` (pointer slices = optional update)**

```go
	Allergies     *[]string `json:"allergies,omitempty"`
	LikedFoods    *[]string `json:"likedFoods,omitempty"`
	DislikedFoods *[]string `json:"dislikedFoods,omitempty"`
```

- [ ] **Step 3: Add to `ProfileResponse`**

```go
	Allergies     []string `json:"allergies,omitempty"`
	LikedFoods    []string `json:"likedFoods,omitempty"`
	DislikedFoods []string `json:"dislikedFoods,omitempty"`
```

- [ ] **Step 4: Persist in `UpdateProfile`**

In `internal/services/profile.go` `UpdateProfile`, after the existing `if req.NextReviewDate != nil { … }`:
```go
	if req.Allergies != nil {
		update["allergies"] = *req.Allergies
	}
	if req.LikedFoods != nil {
		update["likedFoods"] = *req.LikedFoods
	}
	if req.DislikedFoods != nil {
		update["dislikedFoods"] = *req.DislikedFoods
	}
```

- [ ] **Step 5: Map fields into the `ProfileResponse` in the handler**

In `internal/handlers/profile.go`, find where a `models.ProfileResponse` is built from a `models.User` (in `GetProfile`/`UpdateProfile` handlers). Add the three fields to that struct literal:
```go
		Allergies:     user.Allergies,
		LikedFoods:    user.LikedFoods,
		DislikedFoods: user.DislikedFoods,
```
(If the handler returns `*models.User` directly rather than a `ProfileResponse`, no mapping is needed — the `json` tags on `User` already serialize them; in that case skip this step and note it.)

- [ ] **Step 6: Verify + commit**

```bash
cd /Users/sebastian.blanco/Documents/Sebas/weight-tracker-backend
gofmt -l internal/models/user.go internal/services/profile.go internal/handlers/profile.go   # expect no output
git add internal/models/user.go internal/services/profile.go internal/handlers/profile.go
git commit -m "feat(profile): add allergies/likedFoods/dislikedFoods to user profile"
```
(Repo: `/Users/sebastian.blanco/Documents/Sebas/weight-tracker-backend`. Full `go build` is blocked by the tesseract cgo dep; `gofmt` clean is the local gate.)

---

## PHASE 2 — iOS data layer

### Task 2: Add the fields to the iOS profile Codables + ProfileManager

**Files:** the iOS file defining `ProfileResponse` + `UpdateProfileRequest`, and `bulkup/ViewModels/ProfileManager.swift`.

- [ ] **Step 1: Locate the Codables**

```bash
cd /Users/sebastian.blanco/Documents/Sebas/bulkup
grep -rln "struct ProfileResponse\|struct UpdateProfileRequest" bulkup --include="*.swift"
```

- [ ] **Step 2: Add fields to `ProfileResponse`**

In `struct ProfileResponse`, add (defaulting to `[]` so older payloads decode):
```swift
    var allergies: [String]?
    var likedFoods: [String]?
    var dislikedFoods: [String]?
```
(Use optionals so missing JSON keys decode cleanly; read with `?? []` at use sites.)

- [ ] **Step 3: Add fields to `UpdateProfileRequest`**

```swift
    var allergies: [String]?
    var likedFoods: [String]?
    var dislikedFoods: [String]?
```
Ensure its `init`/usage still compiles (if it has an explicit memberwise init or `CodingKeys`, add the new keys). If existing call sites construct `UpdateProfileRequest(...)` positionally, give the new fields defaults `= nil`.

- [ ] **Step 4: Add `updateFoodPreferences` to `ProfileManager`**

In `bulkup/ViewModels/ProfileManager.swift`, add:
```swift
    func updateFoodPreferences(allergies: [String], likedFoods: [String], dislikedFoods: [String]) async -> Bool {
        let request = UpdateProfileRequest(
            allergies: allergies, likedFoods: likedFoods, dislikedFoods: dislikedFoods
        )
        do {
            let updated = try await apiService.updateProfile(request)
            await MainActor.run { self.profile = updated }
            return true
        } catch {
            await MainActor.run { self.errorMessage = "No se pudieron guardar las preferencias" }
            return false
        }
    }
```
Match the EXACT signature `apiService.updateProfile(...)` already uses (check the existing `updateProfile` method in this file for the call shape; mirror it — including how it builds `UpdateProfileRequest` and which APIService method it calls). If `UpdateProfileRequest` requires all fields, pass the current profile's other values through (read from `self.profile`).

- [ ] **Step 5: Build + commit**

Run the iOS build command. Expected `BUILD SUCCEEDED`.
```bash
git add bulkup/ViewModels/ProfileManager.swift <ProfileResponse/UpdateProfileRequest file>
git commit -m "feat(profile): iOS food-preference fields + ProfileManager.updateFoodPreferences"
```

### Task 3: Tag-hygiene helper + DEBUG self-check

**Files:** `bulkup/Views/Components/Diet/FoodPreferencesView.swift` (new — helper lives here for now).

- [ ] **Step 1: Write the helper**

Create `bulkup/Views/Components/Diet/FoodPreferencesView.swift` with (view added in Task 4):
```swift
import SwiftUI

enum FoodTagInput {
    static let maxPerList = 50

    /// Trims, rejects empties/case-insensitive dups, respects the cap. Returns the (possibly unchanged) list.
    static func add(_ raw: String, to list: [String]) -> [String] {
        let tag = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !tag.isEmpty, list.count < maxPerList,
              !list.contains(where: { $0.caseInsensitiveCompare(tag) == .orderedSame })
        else { return list }
        return list + [tag]
    }

    #if DEBUG
    static func runSelfCheck() {
        assert(add("  Nuez  ", to: []) == ["Nuez"], "trims whitespace")
        assert(add("nuez", to: ["Nuez"]) == ["Nuez"], "case-insensitive dedupe")
        assert(add("", to: ["Nuez"]) == ["Nuez"], "ignores empty")
        let full = Array(repeating: "x", count: maxPerList).enumerated().map { "\($0.offset)" }
        assert(add("new", to: full).count == maxPerList, "respects cap")
    }
    #endif
}
```

- [ ] **Step 2: Call the self-check at launch**

In `bulkup/App/BulkUp.swift` `init()`, inside the existing `#if DEBUG` block, add `FoodTagInput.runSelfCheck()`.

- [ ] **Step 3: Build + run (debug)**

Run the iOS build command (Expected `BUILD SUCCEEDED`); launch in the simulator; confirm no assertion failure.

- [ ] **Step 4: Commit**

```bash
git add bulkup/Views/Components/Diet/FoodPreferencesView.swift bulkup/App/BulkUp.swift
git commit -m "feat(diet): food-tag input helper + debug self-check"
```

---

## PHASE 3 — iOS UI

### Task 4: FoodPreferencesView (three tag editors)

**Files:** `bulkup/Views/Components/Diet/FoodPreferencesView.swift` (extend).

- [ ] **Step 1: Implement the view**

Append to `FoodPreferencesView.swift`:
```swift
struct FoodPreferencesView: View {
    @ObservedObject private var profileManager = ProfileManager.shared
    @Environment(\.dismiss) private var dismiss

    @State private var allergies: [String] = []
    @State private var liked: [String] = []
    @State private var disliked: [String] = []

    var body: some View {
        NavigationStack {
            List {
                tagSection("Alergias", systemImage: "exclamationmark.triangle.fill",
                           color: BulkUpColors.error, tags: $allergies)
                tagSection("Me gusta", systemImage: "hand.thumbsup.fill",
                           color: BulkUpColors.success, tags: $liked)
                tagSection("No me gusta", systemImage: "hand.thumbsdown.fill",
                           color: BulkUpColors.textSecondary, tags: $disliked)
            }
            .navigationTitle("Preferencias y alergias")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Listo") { Task { await save(); dismiss() } }
                }
            }
            .task {
                if profileManager.profile == nil { await profileManager.loadProfile() }
                allergies = profileManager.profile?.allergies ?? []
                liked = profileManager.profile?.likedFoods ?? []
                disliked = profileManager.profile?.dislikedFoods ?? []
            }
        }
    }

    @ViewBuilder
    private func tagSection(_ title: LocalizedStringKey, systemImage: String,
                            color: Color, tags: Binding<[String]>) -> some View {
        Section {
            ForEach(tags.wrappedValue, id: \.self) { tag in
                Text(tag)
            }
            .onDelete { idx in tags.wrappedValue.remove(atOffsets: idx); Task { await save() } }
            AddTagField { newTag in
                tags.wrappedValue = FoodTagInput.add(newTag, to: tags.wrappedValue)
                Task { await save() }
            }
        } header: {
            Label(title, systemImage: systemImage).foregroundColor(color)
        }
    }

    private func save() async {
        _ = await profileManager.updateFoodPreferences(
            allergies: allergies, likedFoods: liked, dislikedFoods: disliked
        )
    }
}

private struct AddTagField: View {
    @State private var text = ""
    let onAdd: (String) -> Void
    var body: some View {
        HStack {
            TextField("Añadir…", text: $text)
                .submitLabel(.done)
                .onSubmit { commit() }
            Button { commit() } label: { Image(systemName: "plus.circle.fill") }
                .disabled(text.trimmingCharacters(in: .whitespaces).isEmpty)
        }
    }
    private func commit() {
        let t = text
        text = ""
        onAdd(t)
    }
}
```

- [ ] **Step 2: Build + commit**

Run the iOS build command. Expected `BUILD SUCCEEDED`.
```bash
git add bulkup/Views/Components/Diet/FoodPreferencesView.swift
git commit -m "feat(diet): FoodPreferencesView with three tag editors"
```

### Task 5: Entry point in the Diet section

**Files:** `bulkup/Views/Components/Diet/DietHubView.swift`.

- [ ] **Step 1: Add state + a row that opens the sheet**

In `DietHubView`, add `@State private var showingFoodPreferences = false`. Add a tappable row near the diet section's header/actions (match the file's existing button/row style — e.g. a `Button` in the active-plan header area):
```swift
            Button {
                showingFoodPreferences = true
            } label: {
                Label("Preferencias y alergias", systemImage: "fork.knife.circle")
            }
            .sheet(isPresented: $showingFoodPreferences) {
                FoodPreferencesView()
            }
```
Place the `.sheet` on a stable container view in the body (not inside a conditional that may unmount). If the file already has a row/menu of diet actions, add this as one more item there instead of a free-floating button.

- [ ] **Step 2: Build + manual check**

Run the iOS build command (Expected `BUILD SUCCEEDED`). Launch → Diet section → tap "Preferencias y alergias" → add a few tags to each list, tap Listo, reopen → confirm they persisted (round-trips through the profile).

- [ ] **Step 3: Commit**

```bash
git add bulkup/Views/Components/Diet/DietHubView.swift
git commit -m "feat(diet): entry point to food preferences from the diet hub"
```

---

## Self-Review (completed during planning)

- **Spec coverage:** three lists on the user profile → Task 1 (backend) + Task 2 (iOS); persistence via existing profile flow → Tasks 1–2; free-text tag editor UI → Task 4; tag hygiene (trim/dedupe/cap) → Task 3; entry point in Diet section → Task 5; testing (gofmt + DEBUG self-check + manual round-trip) → Tasks 1/3/5. All spec sections mapped.
- **Placeholder scan:** code steps contain real code; the two "find the exact file/handler shape" steps (iOS Codable location, handler mapping) are concrete grep/lookup instructions with the fallback behavior spelled out, not vague TODOs.
- **Type consistency:** field names `allergies`/`likedFoods`/`dislikedFoods` consistent across Go (`User`/`UpdateProfileRequest`/`ProfileResponse`/`UpdateProfile`), iOS Codables, `ProfileManager.updateFoodPreferences`, and `FoodPreferencesView`. `FoodTagInput.add(_:to:)` signature matches its call site in `tagSection`.
