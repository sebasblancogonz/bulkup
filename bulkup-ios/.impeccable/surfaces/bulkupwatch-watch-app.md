---
version: 2
slug: "bulkupwatch-watch-app"
primary_target: "BulkUpWatch Watch App/ActiveWorkoutView.swift"
related_targets: ["BulkUpWatch Watch App/TodayView.swift","BulkUpWatch Watch App/RestTimerView.swift","BulkUpWatch Watch App/RootView.swift","BulkUpWatch Watch App/WatchTheme.swift","bulkup/Shared/BrandPalette.swift"]
---

# Surface: Watch app (Today, Active workout, Rest)

Mode: Operate. Audience: lifter with the phone in the bag, wrist up, chalk on the fingers. Task: see today's workout and start it; mid-set, nudge kilos or reps and complete the set; ride the rest; tick a meal. States: nothing synced / plan for today / rest day with meals / mid-set / weight missing / resting / finished. Constraints: 40–49mm screens (162–205pt wide), black OLED ground by platform convention, Digital Crown scroll, ≥40pt targets, HealthKit metrics when authorised, one language with the phone (Spanish keys, English values).

## Direction contract

THESIS: the watch is the set table's active row on the wrist; it shows one set, two numbers and one button. Refuses uppercase kickers ("TODAY", "MEALS", "REST", "SERIE 2 / 4" in a lime capsule), bordered system steppers, red heart and orange flame metrics, English copy on a Spanish app.
OWN-WORLD: black ground (platform), content as one lifted graphite slab (`#1A1B17` with the 1pt top-edge light) holding rows with 1pt separators; the day's workout name in SF bold condensed sentence case; "6 ejercicios · 21 series" tabular; exercise rows caption + tabular "4 × 12"; the CTA "Empezar entreno" as a 44pt lime slab, 12pt radius, graphite label. Mid-set: exercise name headline condensed, "Serie 3 de 4" tabular footnote, elapsed as tabular caption with a lime dot, metrics as a quiet tabular line in secondary (heart glyph in secondary, no red); the kilos field as a raised slab with JetBrains Mono 22 and 40×44 raised "−/+" squares, reps the same at mono 18; the CTA "Completar serie" lime, "Ajusta el peso" raised and dim when blocked; a 3pt lime rule with "4/18 series" beneath; "Finalizar" as a text button in secondary. Rest: "Descanso" subheadline secondary, countdown mono 40, a system ProgressView draining lime, "Siguiente · Serie 3 · 62,5 kg × 8" tabular, "Saltar" outline and "+30 s" raised at 40pt. Meals: "Comidas" headline, rows with a 22pt sky square check, strikethrough when done, time tabular.
STORY: raise wrist → the workout → "Empezar" → one set at a time → rest → next → "Finalizar".
FIRST VIEWPORT: 46mm: name, count line, first two exercise rows, the CTA above the fold. Mid-set: name, set line, the kilos field and the CTA.
FORM: instrument panel (first of: instrument panel, checklist, timeline, cards, spreadsheet); inherited world, code-led, no seed key.
FINISH: unreviewed and undocumented is unfinished; this build ends with the finish review, the verdict and DESIGN.md.
