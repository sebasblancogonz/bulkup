# Food Preferences & Allergies — Design (Diet sub-project A)

**Date:** 2026-06-19
**Status:** Approved (design), pending implementation plan

## Context

This is **sub-project A** of a larger diet effort decomposed during brainstorming:
- **A — Food preferences & allergies** (this spec): user-level lists of allergies,
  liked foods, and disliked foods.
- **B — AI recipe chat** (later): per-meal chat suggesting recipes from the diet's
  ingredients, **excluding** A's allergies/dislikes. Depends on A.
- **C — Skipped-day logging + calorie-based diet fidelity %** (later, independent).

A is the foundation that feeds B's exclusion/preference context.

## Goal

Let the user maintain three free-text lists — **allergies**, **liked foods**,
**disliked foods** — stored on their profile (global to the user), editable from a
screen reachable in the Diet section. Later consumed by the AI recipe chat.

## Scope

**In scope:**
- Add the three lists to the user profile (backend `User` + iOS profile model).
- Persist via the existing profile update flow (`GetProfile`/`UpdateProfile`,
  `ProfileManager`).
- A `FoodPreferencesView` (three tag editors) reachable from the Diet section.

**Out of scope (later sub-projects):** the AI chat that consumes these (B); any
calorie/fidelity logic (C); a curated food catalog (we chose free-text tags).

## Decisions (from brainstorming)

- **Three categories:** allergies, likes (gusta), dislikes (no gusta).
- **Free-text tags** (no catalog) — flexible; the AI does fuzzy matching later.
- **Stored on the user profile** (global, not per-plan).
- **Entry point in the Diet section.**

## Architecture & Components

### Backend (reuse profile flow)
- `internal/models/user.go` `User`: add
  `Allergies []string \`bson:"allergies,omitempty" json:"allergies,omitempty"\``,
  `LikedFoods []string \`bson:"likedFoods,omitempty" json:"likedFoods,omitempty"\``,
  `DislikedFoods []string \`bson:"dislikedFoods,omitempty" json:"dislikedFoods,omitempty"\``.
- Add the same three fields to `UpdateProfileRequest` and `ProfileResponse` (the GET
  profile response shape).
- `internal/services/profile.go UpdateProfile`: set these fields on the update
  document when present in the request (mirror how existing optional fields are
  handled). `GetProfile` returns them as part of the user.
- No new route/handler — uses existing `GET /profile` and `PUT /profile`.

### iOS
- Extend the profile model decoded by `ProfileManager` (and the API request used to
  update profile) with `allergies: [String]`, `likedFoods: [String]`,
  `dislikedFoods: [String]` (default `[]`).
- `ProfileManager`: expose the three lists as published state; `updateProfile`
  includes them in the request body.
- `FoodPreferencesView` (new SwiftUI view): three sections (Alergias / Me gusta /
  No me gusta), each a **tag editor** — a text field to add a tag (on submit) and a
  wrapping set of removable chips. Uses `BulkUpColors` (adaptive) and `Text`
  literals (localized via the String Catalog; add English values).
- **Entry point:** a row/button in `DietHubView` (Diet section) navigating to
  `FoodPreferencesView`.
- **Tag hygiene:** trim whitespace; ignore empties; **dedupe case-insensitively**
  within a list (keep first-entered casing). A soft cap (e.g. 50 per list) guards
  against runaway input — silently ignore additions past the cap.

## Data Flow

1. Profile is fetched on load (existing `ProfileManager` flow) → includes the three
   lists → published → `FoodPreferencesView` binds.
2. User adds/removes a tag → `ProfileManager.updateProfile(...)` sends the full
   lists via `PUT /profile` → backend persists on `User`.
3. (Later) Sub-project B reads `allergies`/`dislikedFoods`/`likedFoods` from the
   profile to build the AI exclusion/preference context.

## Error Handling / Edge Cases

- All lists empty by default; empty is valid.
- Network failure on save → surface a non-blocking error; keep local edits and
  retry on next change (match existing `ProfileManager` error behavior).
- Duplicate/whitespace tags rejected client-side before save.
- Backward compatibility: missing fields decode to `[]` (omitempty on the wire).

## Testing

- Backend can't build locally (tesseract/leptonica cgo) → verify changed Go files
  with `gofmt`.
- iOS has no XCTest target → a `#if DEBUG` assert self-check for the tag-hygiene
  helper (add dedupes case-insensitively, trims, ignores empties, respects the
  cap). Manual: add/remove tags in each list, save, kill+relaunch, confirm they
  reload from the profile.

## Risks / Notes

- Small, contained sub-project; main care is matching the existing profile
  update/decoding pattern exactly so the new fields round-trip.
- Field names (`allergies`/`likedFoods`/`dislikedFoods`) are the contract sub-project
  B will consume — keep them stable.
