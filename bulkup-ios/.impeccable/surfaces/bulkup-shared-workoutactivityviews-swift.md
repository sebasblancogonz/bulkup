---
version: 2
slug: "bulkup-shared-workoutactivityviews-swift"
primary_target: "bulkup/Shared/WorkoutActivityViews.swift"
related_targets: ["BulkUpWidgets/BulkUpWidgetsLiveActivity.swift","bulkup/Shared/BrandPalette.swift","bulkup/Shared/WorkoutActivityAttributes.swift"]
---

# Surface: Live Activity (lock-screen card and Dynamic Island)

Mode: Operate. Audience: lifter with the phone face-up on the bench, screen locked, between sets; one glance, one thumb. Task: see which set is next, nudge kilos or reps, complete the set, ride the rest, add 30 s or skip. States: mid-set / weight missing / resting / finished (4 s). Constraints: ActivityKit (160pt lock-screen cap, intents only, no custom animation), a card that may sit on a light wallpaper, no Dynamic Type control, Saira never (the poster has two homes and this is not one).

## Direction contract

THESIS: the lock-screen card is the set table's active row lifted out of the app and dropped on the bench. Refuses the icon-plus-name header, circle-icon steppers, capsule CTAs and the uppercase "DESCANSO" kicker.
OWN-WORLD: a graphite slab (ground `#0E0F0C`, glow at the top) in both appearances because the lock screen is where the gym is; the current exercise in SF headline, "Serie 3 de 4 · Pecho y hombros" in tabular footnote; the elapsed timer in JetBrains Mono 17 with the 6pt pulsing-dot stand-in (a static lime dot); kilos and reps as two raised fields (`#272923`, 8pt) with mono 17 values and bare SF "−/+" glyphs in secondary text as 36pt targets; one lime CTA slab "Completar serie" (12pt, 44pt tall, graphite label); a 3pt lime progress rule along the bottom edge of the card. Resting: "Descanso" in secondary, the countdown in mono 32, the next set as a tabular line, a system `ProgressView(timerInterval:)` draining lime, "Saltar" outline and "+30 s" raised. Finished: a sky square check and "Entreno completado" in headline. Dynamic Island mirrors the same voices at system sizes: compact = lime dot + tabular "4/18" or the rest countdown; expanded = exercise + set on the left, timer on the right, the fields and CTA across the bottom.
STORY: glance → it says which set → tap the big lime thing → the card turns into the rest countdown → tap again in 90 s.
FIRST VIEWPORT: the whole card: name line, fields, CTA, rule. Nothing scrolls, nothing hides.
FORM: instrument panel (first of: instrument panel, checklist, timeline, cards, spreadsheet); inherited world, code-led, no seed key.
FINISH: unreviewed and undocumented is unfinished; this build ends with the finish review, the verdict and DESIGN.md.
