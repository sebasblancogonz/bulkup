---
version: 1
slug: "bulkup-views-dietview-swift"
primary_target: "bulkup/Views/DietView.swift"
related_targets: ["bulkup/Views/Components/Diet/DietHubView.swift","bulkup/Views/Components/Diet/MealCardView.swift","bulkup/Views/Components/Diet/SupplementsView.swift","bulkup/Views/Components/Diet/DietFidelityView.swift","bulkup/Views/Components/Diet/MealOptionView.swift","bulkup/Views/Components/Diet/MealConditionsView.swift"]
---

# Surface: Dieta (DietHubView picker + DietView day page, MealCardView, SupplementsView, DietFidelityView)

Mode: Operate. Audience: the lifter at the table or in the kitchen, one thumb, checking what the next meal is and ticking the last one. Task: see today's meals in order, open one to read the options and ingredients, tick it, note what you ate, log a cheat meal, see the day's macros and supplements. States: weekly single plan ("Dieta Semanal") vs one page per day; no plan; loading; all meals done; PRO-gated fidelity card. Constraints: data from DietManager/MealTrackingManager; sheets (recipe, food preferences, editor) kept; Dynamic Type; dark and light; 44pt targets.

## Direction contract

THESIS: today's meals are a checklist you read at the table; the next meal steps forward, the rest wait. Refuses the ring-and-cards dashboard (metric ring, macro tiles, emoji headers).
OWN-WORLD: the same world as Hoy and Entreno — warm graphite lit from the top; the plan name in SF large-title bold condensed, sentence case; a lifted day strip when the plan has several days (selected day a lime 8pt-radius square); "3/5 comidas" with a lime progress rule, sky when the day is done; one lifted evidence strip for the macros (kcal in JetBrains Mono 22, protein/carbs/fat in tabular SF); the meal list as one lifted slab with inset separators, square sky checks, meal name in SF headline, time in tabular footnote, the next pending meal on a raised row; expanded meal content in SF body/caption with the "Receta con IA" link in lime text; cheat meal and supplements as quiet lifted slabs with sentence-case headings; no uppercase labels, no emoji, no lime for "done".
STORY: "¿Qué me toca comer?" → the raised row says it → open it, read the option → tick it → the rule grows, sky at the end.
FIRST VIEWPORT: hub picker (Plan activo / Mis planes) squared and lifted; the plan name; the day strip (multi-day plans); "3/5 comidas" + lime rule; the macro strip; the first meal rows with the next one raised.
FORM: checklist with a raised current row (first of: checklist, timeline by hour, cards, dashboard with ring); inherited world, code-led, no seed key.
FINISH: unreviewed and undocumented is unfinished; this build ends with the finish review, the verdict, DESIGN.md, and every shipping raster carrying its provenance.
