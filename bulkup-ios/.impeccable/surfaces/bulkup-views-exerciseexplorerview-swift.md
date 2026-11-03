---
version: 1
slug: "bulkup-views-exerciseexplorerview-swift"
primary_target: "bulkup/Views/ExerciseExplorerView.swift"
related_targets: ["bulkup/Views/Components/RM/RMExerciseDetailSheet.swift","bulkup/ViewModels/ExerciseExplorerManager.swift"]
---

# Surface: Explorador de ejercicios (ExerciseExplorerView sheet + RMExerciseDetailSheet)

Mode: Operate. Audience: the lifter looking up a movement by name or by what is free in the gym (equipment, muscle, level), one thumb, between sets or while editing a plan. Task: type a name or narrow by category/equipment/force/level, scan the list, open one to read muscles and instructions and see the images. States: loading, results, no results (with or without filters), detail with or without images. Constraints: data from ExerciseExplorerManager (local cache of the 1,000+ exercise DB, raw English keys localised through the string catalog); dark and light; Dynamic Type; 44pt targets.

## Direction contract

THESIS: a search field, four filter chips and one long list of rows; the exercise's name is the element and everything else is a quiet caption. Refuses the tile grid with coloured level tags and prev/next pagination.
OWN-WORLD: the same world as Récords — "Ejercicios" in the title voice with the catalogue size in tabular SF beneath; the 44pt lifted search field; a row of capsule chips (raised fill, caption semibold; lime 14 % fill and lime text with "· 2" when active) that open native menus with check marks; the results count in tabular footnote; one lifted slab of rows: a 44pt raised thumbnail square (the exercise image, or a quiet figure glyph), the name in SF subheadline semibold, "Pecho · Barra · Intermedio" in caption secondary, a chevron; a raised "Mostrar más" slab at the end with "18 de 128" beneath. Detail: the image on a raised 16pt slab, the name in title voice, the same meta line, muscles and details as slab rows, instructions as a numbered list in tabular SF. No red/amber/sky on levels, no tag confetti, no emoji.
STORY: "¿Qué hago hoy de hombro con mancuerna?" → tap Equipo, tick Mancuerna → the list narrows, the count says how many → open one → read muscles and instructions.
FIRST VIEWPORT: title + count, search field, the chip row, the count line and the first five rows.
FORM: filtered list with menu chips (first of: list with menu chips, grid of tiles, sectioned alphabet, filter sheet); inherited world, code-led, no seed key.
FINISH: unreviewed and undocumented is unfinished; this build ends with the finish review, the verdict and DESIGN.md.
