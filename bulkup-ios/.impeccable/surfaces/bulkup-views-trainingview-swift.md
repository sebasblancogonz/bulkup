---
version: 1
slug: "bulkup-views-trainingview-swift"
primary_target: "bulkup/Views/TrainingView.swift"
related_targets: ["bulkup/Views/Components/Training/ExerciseCardView.swift","bulkup/Views/Components/Training/ActiveWorkoutHeader.swift","bulkup/Views/Components/Training/RestTimerSheet.swift","bulkup/Views/Components/Training/WorkoutSummaryView.swift"]
---

# Surface: Training (TrainingView, ExerciseCardView, ActiveWorkoutHeader, RestTimerSheet, WorkoutSummaryView, TrainingHub picker)

Mode: Operate. Audience: lifter mid-session, one hand, between sets. Task: check sets, type kilos/reps, add or remove a set, rest, finish. States: not started / in progress / completed day; active session with rest running; skipped exercise; swapped exercise; rest day; week view. Constraints: existing session logic, watch/Live Activity mirror, Dynamic Type, 44pt targets.

## Direction contract

THESIS: the set table is the instrument; everything around it is chrome kept quiet. Refuses rounded cards with accent left-stripes, gradient rings and capsule controls.
OWN-WORLD: graphite ground; the day's name in Saira Condensed uppercase; mono numbers everywhere (kg, reps, timer); exercise cards are surface + 1pt hairline, 14pt radius; set rows with 10pt-radius inputs and square-ish steppers; the check turns sky when done (lime is the CTA and the progress rule); rest timer with a mono countdown and a lime ring; CTA "COMENZAR ENTRENO" in Saira.
STORY: open the day → tap start → check sets as they happen → rest counts down → finish → summary in mono.
FIRST VIEWPORT: segmented control (Plan activo / Mis planes) squared; date nav + week strip; workout name with "1/6" in mono and a lime progress rule; first exercise card expanded with its set table; CTA pinned bottom.
FORM: instrument panel (first of: instrument panel, checklist, timeline, cards, spreadsheet); inherited world, code-led, no seed key.
FINISH: unreviewed and undocumented is unfinished; this build ends with the finish review, the verdict, DESIGN.md, and every shipping raster carrying its provenance.
