---
version: 2
slug: "bulkup-views-trainingview-swift"
primary_target: "bulkup/Views/TrainingView.swift"
related_targets: ["bulkup/Views/Components/Training/ExerciseCardView.swift","bulkup/Views/Components/Training/ActiveWorkoutHeader.swift","bulkup/Views/Components/Training/RestTimerSheet.swift","bulkup/Views/Components/Training/WorkoutSummaryView.swift"]
---

# Surface: Training (TrainingView, ExerciseCardView, ActiveWorkoutHeader, RestTimerSheet, WorkoutSummaryView, TrainingHub picker)

Mode: Operate. Audience: lifter mid-session, one hand, between sets. Task: check sets, type kilos/reps, add or remove a set, rest, finish. States: not started / in progress / completed day; active session with rest running; skipped exercise; swapped exercise; rest day; week view. Constraints: existing session logic, watch/Live Activity mirror, Dynamic Type, 44pt targets.

## Direction contract

THESIS: the set table is the instrument; everything around it is chrome kept quiet. Refuses rounded cards with accent left-stripes, gradient rings and capsule controls.
OWN-WORLD: warm graphite ground; the day's name in SF large-title bold, condensed width, sentence case; exercise cards are surface slabs lifted by light (no outline), 16pt radius; the set table is the instrument: the current set's row steps forward on a raised fill with the set number in primary text and a lime-tinted check, completed rows dim with a sky check, pending rows sit at 72 %; fields are inset pills with JetBrains Mono 16 values (sky stroke never, lime stroke only while focused); steppers are 36×44 targets; video and remove live in the row's context menu; CTA "Continuar entreno" in SF headline on lime; rest sheet with a 64pt mono countdown and a draining lime rule; summary leads with the volume in mono 44 and a sentence that says how it moved.
STORY: open the day → tap start → check sets as they happen → rest counts down → finish → summary in mono.
FIRST VIEWPORT: segmented control (Plan activo / Mis planes) squared; date nav + week strip; workout name with "1/6" in mono and a lime progress rule; first exercise card expanded with its set table; CTA pinned bottom.
FORM: instrument panel (first of: instrument panel, checklist, timeline, cards, spreadsheet); inherited world, code-led, no seed key.
FINISH: unreviewed and undocumented is unfinished; this build ends with the finish review, the verdict, DESIGN.md, and every shipping raster carrying its provenance.
