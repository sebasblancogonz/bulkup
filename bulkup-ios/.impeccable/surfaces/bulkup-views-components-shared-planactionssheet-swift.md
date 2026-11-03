---
version: 1
slug: "bulkup-views-components-shared-planactionssheet-swift"
primary_target: "bulkup/Views/Components/Shared/PlanActionsSheet.swift"
related_targets: ["bulkup/Views/Components/Shared/ImportPlanView.swift","bulkup/Views/Components/Training/TrainingHubView.swift","bulkup/Views/Components/Diet/DietHubView.swift"]
---

# Surface: Nuevo plan (PlanActionsSheet from the hub's ellipsis, ImportPlanView, ImportPlanByCodeView, the hubs' empty states)

Mode: Operate. Audience: the lifter who has just been handed a routine or a diet as a PDF or a photo and wants it in the app, or who wants a second plan, a template, a manual plan, a shared code. Task: pick how the new plan comes in, name it, upload the file, wait, land on the plan. States: free tier (PRO-gated rows), training vs diet hub, active vs library tab, empty hub, name empty, uploading, reading, failed, timed out, done. Constraints: one backend endpoint (`/process-file-smart`) that detects whether the file is a routine or a diet and reports `detectedType` with the completion notification; share-by-code exists for training plans only; sheets; dark and light; 44pt targets.

## Direction contract

THESIS: one sheet of rows replaces the system menu, and one import replaces two: you upload the plan, the app tells you what it was. Refuses the two parallel "Importar con IA" wizards and the dashed upload boxes.
OWN-WORLD: the hub's ellipsis opens a sheet on the ground with "Nuevo plan" in the title voice and one lifted slab of rows (glyph in secondary, title in SF headline semibold, a one-line reason in caption secondary, a solid lime PRO tag when gated, a chevron); a second slab holds what belongs to the current plan (the day/week picker as a native segmented control, "Explorar ejercicios", "Preferencias y alergias"). The empty hub shows the same slab under "Sin plan activo". The import sheet: "Importar un plan" in the title voice, one sentence of copy, the name field on raised fill (44pt), the optional dates row, then a slab with "Elegir PDF" and "Elegir foto" rows; while the file is read the body becomes a lime ProgressView, "Leyendo tu plan", the step in caption and the file name on a raised chip; failure is amber text with "Reintentar". The code sheet: "Tengo un código", the six characters in JetBrains Mono 32 on raised fill, a lime "Importar" slab. No sparkles glyph, no "con IA" headline, no purple lock, no dashed borders.
STORY: "Me han pasado la rutina" → ellipsis → "Importar PDF o foto" → name it, pick the file → "Leyendo tu plan" → the training tab opens on it (or the diet tab, if that is what it was).
FIRST VIEWPORT: the sheet's title and both slabs in one detent; the import sheet's title, copy, name field and the two file rows.
FORM: sheet of rows with a second contextual slab (first of: sheet of rows, system menu, action-sheet buttons, full-screen chooser); inherited world, code-led, no seed key.
FINISH: unreviewed and undocumented is unfinished; this build ends with the finish review, the verdict and DESIGN.md.
