---
version: 2
slug: "bulkup-views-progressdashboardview-swift"
primary_target: "bulkup/Views/ProgressDashboardView.swift"
related_targets: ["bulkup/Views/BodyMeasurementsView.swift","bulkup/Views/RMTrackerView.swift","bulkup/Views/Components/Common/StatsStrip.swift"]
---

# Surface: Progreso (ProgressDashboardView, BodyMeasurementsView, RMTrackerView)

Mode: Operate. Audience: the lifter on Sunday night or after a weigh-in, checking whether the plan is working. Task: see the week (workouts done, meals done, streak), the latest body numbers and their direction, the last records, and where you stand against friends; open body or records to add an entry. States: free tier (week only, three locked sections, one gate); PRO with data; PRO with no measurements / no records / no friends; loading; empty search. Constraints: existing managers and sheets, Swift Charts, Dynamic Type, dark and light, 44pt targets.

## Direction contract

THESIS: progress is a strip of numbers you can read in two seconds and three slabs of rows beneath it, not a scoreboard of rings. Refuses the three hero rings, uppercase micro-labels, gradient stat tiles, trophy circles, coloured good/bad deltas (a bulk goes up on purpose) and the "Whoop card".
OWN-WORLD: "Progreso" in the title voice with the week's dates beneath; one lifted stats strip (mono 22 values, caption labels, 3pt lime rules for the three live fractions); "Cuerpo" as a slab with three mono numbers and signed neutral deltas; "Récords" as rows (name, date, "100 kg × 3" in mono 17, 1RM in tabular footnote); "Ranking" as rows (rank, 28pt initial avatar on raised, name, days) with my row on the raised fill and "Mi código · Añadir amigo" as footer links; free tier shows three locked rows with a PRO tag and the compact gate. Body screen: latest measurement strip (peso / IMC / cintura, mono 22, neutral deltas), the weight as one 2pt sky line with ≥8pt points on a recessive `line` grid, y fitted to the data, the last point labelled; history as rows in one slab. Records screen: the same strip (registros / ejercicios con RM / este mes), a 44pt raised search field, exercises as rows with mono values and a quiet menu.
STORY: open → the week in one strip → scroll to the body, the records, the ranking → tap into one to add.
FIRST VIEWPORT: title + week line, the strip, the body slab, the top of the records slab.
FORM: instrument panel (first of: instrument panel, checklist, timeline, cards, spreadsheet); inherited world, code-led, no seed key.
FINISH: unreviewed and undocumented is unfinished; this build ends with the finish review, the verdict and DESIGN.md.
