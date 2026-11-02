---
version: 1
slug: "bulkup-views-todayview-swift"
primary_target: "bulkup/Views/TodayView.swift"
related_targets: []
---

# Surface: Today (TodayView)

Mode: Operate. Audience: the lifter opening the app in the morning or at the gym door. Task: see today's workout and meals, start logging, tick meals. Important states: rest day, no plan, loading, all done. Frequency: daily. Constraints: data from backend managers; inline logger kept functional; Dynamic Type; dark and light.

## Direction contract

THESIS: today's workout name is the headline of the day, set like a plate on a bar; the stats are one strip of evidence, not three cards. Refuses the greeting + hero card + three stat tiles template.
OWN-WORLD: graphite ground; date in mono micro label; greeting in SF; the workout name in Saira Condensed uppercase at 40pt with a lime progress rule beneath; a hairline data strip (entrenos · dieta · peso) in mono; hairline-separated exercise rows with mono set×reps; meals as a hairline list with mono times and square sky checks.
STORY: "¿Qué toca hoy?" → the name and the count → "Empezar entreno" → later, meals ticked.
FIRST VIEWPORT: week strip (hairline row, today a lime 10pt-radius square); the workout block (name, mono "6 ejercicios · 24 series", lime progress rule, the CTA); the data strip; the first exercise rows.
FORM: hairline list over a display block (first of: display block + list, calendar-first, stats dashboard, card stack, timeline); inherited world, code-led, no seed key.
FINISH: unreviewed and undocumented is unfinished; this build ends with the finish review, the verdict, DESIGN.md, and every shipping raster carrying its provenance.
