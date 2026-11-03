---
name: BulkUp iOS
description: Graphite & Voltage on native iOS, second pass — light instead of lines. Warm graphite lit from the top, one lime razor, sky for done, mono only where a number is the element.
colors:
  graphite-ground-dark: "#0E0F0C"
  graphite-glow-dark: "#1C1E19"
  graphite-surface-dark: "#1A1B17"
  graphite-raised-dark: "#272923"
  graphite-line-dark: "#2C2E27"
  bone-text-dark: "#F3F1EA"
  ash-text-secondary-dark: "#A6A89D"
  ash-text-tertiary-dark: "#8E9086"
  voltage-dark: "#B4FF2E"
  voltage-pressed-dark: "#93D414"
  voltage-glow-dark: "#C9FF66"
  voltage-text-dark: "#B4FF2E"
  sky-done-dark: "#00A9DD"
  amber-error-dark: "#F5A524"
  bone-ground-light: "#F0EEE8"
  bone-glow-light: "#FAF9F6"
  bone-surface-light: "#FDFCF8"
  bone-raised-light: "#F3F1EB"
  bone-line-light: "#DCD9D1"
  graphite-text-light: "#141510"
  ash-text-secondary-light: "#5C5E56"
  ash-text-tertiary-light: "#66685F"
  voltage-light: "#8FDC14"
  voltage-pressed-light: "#6DB10C"
  voltage-glow-light: "#A8E83A"
  voltage-text-light: "#3E7000"
  sky-done-light: "#00729A"
  amber-error-light: "#A86400"
  on-voltage: "#0E0F0C"
  on-fill-dark-glyph: "#0E0F0C"
  on-fill-light-glyph: "#F3F1EA"
  shadow-dark: "#000000"
  shadow-light: "#2A2A22"
typography:
  poster:
    fontFamily: "Saira Condensed, system-ui-condensed, sans-serif"
    fontSize: "40pt"
    fontWeight: 800
    lineHeight: 0.95
    letterSpacing: "-0.2pt"
    textTransform: "uppercase"
  title:
    fontFamily: "SF Pro, -apple-system, system-ui, sans-serif"
    fontSize: "34pt"
    fontWeight: 700
    lineHeight: 1.05
    letterSpacing: "-0.3pt"
    fontVariation: "width condensed"
  title-compact:
    fontFamily: "SF Pro, -apple-system, system-ui, sans-serif"
    fontSize: "28pt"
    fontWeight: 700
    lineHeight: 1.1
    letterSpacing: "-0.3pt"
    fontVariation: "width condensed"
  headline:
    fontFamily: "SF Pro, -apple-system, system-ui, sans-serif"
    fontSize: "20pt"
    fontWeight: 600
    lineHeight: 1.25
  card-title:
    fontFamily: "SF Pro, -apple-system, system-ui, sans-serif"
    fontSize: "17pt"
    fontWeight: 600
    lineHeight: 1.3
  body:
    fontFamily: "SF Pro, -apple-system, system-ui, sans-serif"
    fontSize: "15pt"
    fontWeight: 400
    lineHeight: 1.35
  caption:
    fontFamily: "SF Pro, -apple-system, system-ui, sans-serif"
    fontSize: "13pt"
    fontWeight: 500
    lineHeight: 1.35
  numeric:
    fontFamily: "SF Pro, -apple-system, system-ui, sans-serif"
    fontSize: "15pt"
    fontWeight: 500
    lineHeight: 1.35
    fontFeature: "tnum"
  column-label:
    fontFamily: "SF Pro, -apple-system, system-ui, sans-serif"
    fontSize: "11pt"
    fontWeight: 600
    letterSpacing: "0.6pt"
    textTransform: "uppercase"
  mono-hero:
    fontFamily: "JetBrains Mono, ui-monospace, monospace"
    fontSize: "44pt"
    fontWeight: 600
    lineHeight: 1
  mono-countdown:
    fontFamily: "JetBrains Mono, ui-monospace, monospace"
    fontSize: "64pt"
    fontWeight: 600
    lineHeight: 1
  mono-stat:
    fontFamily: "JetBrains Mono, ui-monospace, monospace"
    fontSize: "22pt"
    fontWeight: 600
    lineHeight: 1.1
  mono-field:
    fontFamily: "JetBrains Mono, ui-monospace, monospace"
    fontSize: "16pt"
    fontWeight: 600
    lineHeight: 1.2
  mono-inline:
    fontFamily: "JetBrains Mono, ui-monospace, monospace"
    fontSize: "17pt"
    fontWeight: 600
    lineHeight: 1.2
rounded:
  small: "8pt"
  medium: "12pt"
  large: "16pt"
  xl: "20pt"
  pill: "9999px"
spacing:
  xs: "4pt"
  sm: "8pt"
  md: "16pt"
  screen-h: "20pt"
  lg: "24pt"
  section-gap: "28pt"
  xl: "32pt"
  xxl: "48pt"
components:
  button-primary:
    backgroundColor: "{colors.voltage-dark}"
    textColor: "{colors.on-voltage}"
    typography: "{typography.card-title}"
    rounded: "{rounded.medium}"
    height: "54pt"
    width: "100%"
  button-primary-light:
    backgroundColor: "{colors.voltage-light}"
    textColor: "{colors.on-voltage}"
    typography: "{typography.card-title}"
    rounded: "{rounded.medium}"
    height: "54pt"
    width: "100%"
  button-secondary:
    backgroundColor: "{colors.graphite-raised-dark}"
    textColor: "{colors.bone-text-dark}"
    typography: "{typography.card-title}"
    rounded: "{rounded.medium}"
    height: "50pt"
    width: "100%"
  button-outline:
    backgroundColor: "transparent"
    textColor: "{colors.voltage-text-dark}"
    typography: "{typography.card-title}"
    rounded: "{rounded.medium}"
    height: "50pt"
    width: "100%"
  card:
    backgroundColor: "{colors.graphite-surface-dark}"
    textColor: "{colors.bone-text-dark}"
    rounded: "{rounded.large}"
    padding: "16pt"
  card-flat:
    backgroundColor: "{colors.graphite-raised-dark}"
    textColor: "{colors.bone-text-dark}"
    rounded: "{rounded.medium}"
    padding: "16pt"
  field-mono:
    backgroundColor: "{colors.graphite-raised-dark}"
    textColor: "{colors.bone-text-dark}"
    typography: "{typography.mono-field}"
    rounded: "{rounded.small}"
    height: "44pt"
  set-row-active:
    backgroundColor: "{colors.graphite-raised-dark}"
    textColor: "{colors.bone-text-dark}"
    rounded: "{rounded.medium}"
    padding: "4pt 6pt"
  check-done:
    backgroundColor: "{colors.sky-done-dark}"
    textColor: "{colors.on-fill-dark-glyph}"
    rounded: "{rounded.small}"
    size: "36pt"
  pill-badge:
    backgroundColor: "{colors.voltage-dark}"
    textColor: "{colors.on-voltage}"
    typography: "{typography.column-label}"
    rounded: "{rounded.pill}"
    padding: "5pt 10pt"
  calendar-day-today:
    backgroundColor: "{colors.voltage-dark}"
    textColor: "{colors.on-voltage}"
    typography: "{typography.numeric}"
    rounded: "{rounded.small}"
    size: "32pt"
---

# Design System: BulkUp iOS

## Overview

**Creative North Star: "Graphite & Voltage — light instead of lines"**

This is the landing's Graphite & Voltage world carried onto native iOS, in its second pass. The first pass drew every container with a hairline and the screens read as wireframes on a cold, narrow ramp (critique `.impeccable/critique/2026-11-02T21-07-35Z__bulkup-views.md`, P0 "depth"). The second pass replaced the lines with light: the ground is warm graphite that is visibly lighter at the top of every screen (`BulkUpGround`), containers are lighter slabs that catch a 1pt light along their top edge in the dark appearance and cast a soft shadow in the light appearance (`LiftModifier`), and the ramp was widened and warmed so a card separates from the ground by tone alone. The only structural lines left are list separators and the outline button.

Lime is still a razor. It fires only where the next action or live progress lives: the primary CTA, the progress rule, today's square in the week strip, the pulsing session dot, the stroke around the one set the lifter should do next, the selected plan row. Sky means done. Amber is the only error colour. Three type voices each own a small territory: SF Pro (bold condensed for the day's name and screen titles) carries everything people read, Saira Condensed is a poster used in exactly two places, and JetBrains Mono carries numbers that stand alone (fields, timers, prices, big stats). Operate screens are dense and quiet; the two moments of persuasion and reward (paywall, summary) are the only ones allowed to raise their voice.

**Key Characteristics:**
- Warm graphite ground lit from the top; warm bone by day. Never pure black or white on the canvas.
- Depth by light: top-edge light catch (dark) or a soft offset shadow (light). Container outlines are gone.
- Hairlines survive only as 1pt list separators and the outline button's border.
- One lime object of consequence per region; sky for done; amber for wrong.
- SF Pro bold condensed titles in sentence case; Saira Condensed posters in two homes; JetBrains Mono ≥16pt only where the number is the element.
- CTAs in sentence case, 54pt lime slabs, 12pt radius.
- The set table is an instrument: the active row steps forward on a raised fill; done rows get a sky check; pending rows sit at 72 %.

## Colors

A warm graphite ramp with ≥6 L* between adjacent steps so depth reads without a line, one electric lime, one sky, one amber. Every token is adaptive; the light appearance is a mirrored bone ramp, not an inversion.

### Primary
- **Voltage** (`voltage-dark` / `voltage-light`): the razor. Primary CTA fill, the draining rest rule, the progress rule under the workout name, today's 32pt square in the week strip, the 8pt pulsing session dot, the 1.5pt stroke on the next set's check and on a focused field, the selected plan row's stroke. Light appearance drops to `#8FDC14` so the slab keeps contrast against bone.
- **Voltage pressed** (`voltage-pressed-*`): the deep end of the accent; also the "diet" context tint and small PRO tags (`BulkUpColors.secondary`).
- **Voltage as text** (`voltage-text-*`): lime that reads as a word. On graphite it is the accent itself; on bone it is `#3E7000`, the only lime legible as 17pt text on `#F0EEE8`. Used for the summary's delta sentence, the outline button, "Saltar", the per-month price, the gate's checkmarks.
- **On voltage** (`on-voltage` `#0E0F0C`): glyphs and labels on any lime fill are always graphite, in both appearances.

### Secondary
- **Sky, done** (`sky-done-dark` `#00A9DD` / `sky-done-light` `#00729A`): the second green. Completed set checks, completed exercise marks, the logged-day 5pt dot under a calendar day, the "training" context tint, the summary's 56pt done mark. The light value was deepened from `#007DA8` so the check fill passes against bone surfaces.

### Tertiary
- **Amber** (`amber-error-*`): the only warning and error colour (failed save, the "F" failure mark on a set). It never competes with lime and lime is never "wrong".

### Neutral
- **Ground** (`graphite-ground-dark` `#0E0F0C` / `bone-ground-light` `#F0EEE8`): the canvas below the glow.
- **Glow** (`graphite-glow-dark` `#1C1E19` / `bone-glow-light` `#FAF9F6`): the top of every screen. `BulkUpGround` fades glow → ground over the first 42 % of the height. Light mode glow is warm bone, not `#FFFFFF`.
- **Surface** (`graphite-surface-dark` `#1A1B17` / `bone-surface-light` `#FDFCF8`): content containers, the rest sheet, the primary button's inner field on the active row.
- **Raised** (`graphite-raised-dark` `#272923` / `bone-raised-light` `#F3F1EB`): fills inside a container (fields, steppers, the pause button, secondary button), the active set row, the rest banner, the nested flat card.
- **Line** (`graphite-line-dark` `#2C2E27` / `bone-line-light` `#DCD9D1`): 1pt list separators, the progress ring's track, the empty part of the rest rule, the stats strip's 1×44pt dividers. Never a container border.
- **Text primary** (`bone-text-dark` `#F3F1EA` / `graphite-text-light` `#141510`).
- **Text secondary** (`ash-text-secondary-*`): the greeting, the "90s descanso" line, stepper glyphs, labels under stats.
- **Text tertiary** (`ash-text-tertiary-dark` `#8E9086` / `ash-text-tertiary-light` `#66685F`): column labels, pending set numbers, the pending check's 50 % stroke, the drag indicator. Lifted from `#7C8581`/`#747C78` so 11pt column labels pass against the surface.
- **Shadow** (`shadow-light` `#2A2A22`): the warm graphite that casts the light-mode lift and anything that floats. `shadow-dark` is unused by the lift (dark lifts by edge light instead).

### Named Rules
**The Two-Greens Rule.** Lime means action or progress; sky means done or logged. A finished set, a logged day, a completed exercise is sky, never lime. A thing you should tap next is lime, never sky.

**The One Razor Rule.** Lime covers ≤10 % of any screen and names one object of consequence per region: the CTA, the next check, the rule, today. The summary is the single exception where lime may own a region, as a 16 % → 0 % glow over the first 420pt.

**The On-Fill Rule.** Glyphs on a filled element are chosen by WCAG luminance with the threshold at L > 0.30 (`Color.onFill`): lime and sky both get graphite glyphs (`#0E0F0C`); only a fill darker than that gets bone (`#F3F1EA`). Never put white on sky.

**The Never-Pure Rule.** No `#000000` or `#FFFFFF` on the canvas, a container, or text. The ground stops at `#0E0F0C`, the lightest surface at `#FDFCF8`.

## Typography

**Display Font:** Saira Condensed (ExtraBold 800, bundled; falls back to system condensed)
**Body / Title Font:** SF Pro (system; titles use `.fontWidth(.condensed)`)
**Data Font:** JetBrains Mono (Medium 500 / SemiBold 600, bundled)

**Character:** three voices, each with a fenced territory. SF carries the app and takes the condensed width only when it is the day's name or a screen title, so the gym-poster gesture survives without a second family. Saira shouts twice, as a reward and as a pitch. Mono is the sound of a number being measured, never of a sentence being typed.

### Hierarchy
- **Poster** (Saira Condensed ExtraBold, 40pt, uppercase, tracking −0.2, relative to largeTitle): two homes only — the paywall headline "TU PROGRESO, VISIBLE." (`SubscriptionView.swift`) and "ENTRENO COMPLETADO" (`WorkoutSummaryView.swift`). Both ship via `.displayVoice(40, weight: .extraBold)`.
- **Title** (SF Bold, largeTitle 34pt, condensed width, tracking −0.3, sentence case, `.titleVoice(.largeTitle)`): the day's workout name on Today and Training, the PRO gate title. The `.title` 28pt step is used for a plan name inside a card.
- **Headline** (SF Semibold, title3 20pt): section headers ("Ejercicios", "Lo que desbloqueas").
- **Card title** (SF Semibold, headline 17pt): exercise names, plan names in rows, the active workout name in the header, every button label.
- **Body** (SF Regular, subheadline 15pt): the paywall sub, gate copy, unlock descriptions.
- **Caption** (SF Medium, footnote 13pt): stat labels, meta lines, "Guardando...".
- **Numeric** (SF with `monospacedDigit()`, any text style): a number inside a sentence or label — "6 ejercicios · 21 series", "1/6 ejercicios registrados", "+320 kg más que la última vez", set numbers, calendar day numbers, "Siguiente 3 · 62,5 kg × 8", "3,33 €/mes".
- **Column label** (SF Semibold, caption2 11pt, uppercase, tracking 0.6, text tertiary): the set table's SERIE / KG / REPS header only.
- **Mono** (JetBrains Mono SemiBold): where the number *is* the element — 64pt rest countdown, 44pt summary volume, 28pt plan stats, 22pt summary strip values, 17pt elapsed timer / rest banner / plan price, 16pt kg and reps fields. Smallest shipped size is 16pt.

### Named Rules
**The Two Homes Rule.** Saira Condensed appears in exactly two strings: "TU PROGRESO, VISIBLE." and "ENTRENO COMPLETADO". A third poster is a system change, not an extension.

**The Mono Floor Rule.** JetBrains Mono never goes below 16pt and never sits inside a sentence. A number next to words uses SF with tabular figures. Prices, timers, fields and hero stats are the whole mono vocabulary.

**The Sentence-Case CTA Rule.** Every button label is SF headline semibold in sentence case ("Continuar entreno", "Guardar y salir", "Empezar 7 días gratis"). The brand lives in the lime fill, not in a shout.

## Layout

Single column, 20pt screen gutters (`Spacing.screenH`), 16pt inside containers, 24pt between blocks and 28pt between sections. Everything flows on an 4/8/16/24/32/48pt scale. The canvas is `BulkUpGround` on Today, Training and the paywall; the summary swaps the glow for the lime region.

Today: greeting and date as one quiet 15pt line, the week strip as a lifted slab, the workout name in the title voice with an SF numeric line and a 4pt lime progress rule beneath, the 54pt CTA, one caption strip of evidence, then exercise rows inside a single lifted slab with inset 1pt separators. Training: the active session header (mono timer with pulsing dot, headline name, 36pt pause square), the rest banner under it when a rest runs with the sheet dismissed, then exercise cards each holding its own set table. Paywall: headline, one 15pt sub, a proof strip of three facts, the unlock list separated by hairlines, and the plan rows plus CTA pinned at the bottom behind a 28pt fade. Summary: content anchored to the top third (done mark, poster, hero number and sentence, one stats strip), actions at the bottom.

Touch targets in the set table are 44pt tall: 36×44 steppers, a 44pt field, a 44pt check hit area around a 36pt visible square.

## Elevation & Depth

Hybrid: tonal layering carries the hierarchy (ground → surface → raised, ≥6 L* apart) and light does the lifting. In the dark appearance a container has no shadow at all; it catches a 1pt light along its top edge, white at 9 % fading to 1.5 % at the bottom (`BulkUpColors.edgeLight`, `LiftModifier`). In the light appearance the same container casts a soft warm shadow. Neither draws an outline. Fills inside a container (fields, steppers) are the raised step with no stroke. Anything that floats (the rest banner, the floating workout menu) takes the same lift at 12pt radius.

### Shadow Vocabulary
- **Lift, light appearance** (`0 3pt 12pt rgba(42,42,34,0.07)` = `shadow-light` at 7 %, radius 12, y 3): every lifted container in light mode.
- **Lift, dark appearance** (no shadow; 1pt inner stroke `linear-gradient(white 9 %, white 1.5 %)` top → bottom): every lifted container in dark mode.
- **State stroke** (1pt, tinted): the lift can swap its edge light for a tinted 1pt stroke on a state — sky 60 % on a completed day card, lime 50 % on the compact PRO gate, lime 100 % on the selected plan row.
- **Float shadow** (`shadow` at 28 %, radius 20, y 10, `cardShadow()`): reserved helper for things that float above content; the shipped screens use `lift` instead.
- **Accent glow** (`accent` at 35 %, radius 16, `accentGlowShadow()`): reserved helper; not on any shipped screen.

### Named Rules
**The Light-Not-Lines Rule.** A container is separated from the ground by its fill and its top-edge light (or light-mode shadow), never by a hairline border. Hairlines are allowed in exactly two roles: a 1pt `line` Rectangle between list rows, and the 1pt border of the outline button.

**The Earned Shadow Rule.** Shadows in dark mode are zero. In light mode the only shadow is the 7 % lift; nothing heavier ships.

## Shapes

Continuous-corner rounded rectangles on a four-step hierarchy: 8pt for fields, steppers, checks and the calendar square; 12pt for buttons, inputs, the active set row, the rest banner, the pause square and nested flat cards; 16pt for cards, the plan rows and the summary's done mark; 20pt for sheets and hero blocks. Capsules are for chips and badges only ("Mejor valor", the 36×5 drag indicator). Checks are 36pt squares, not circles; the plan radio is a 22pt circle because it is a radio. No side stripes, no accent bars.

## Components

### Buttons
- **Shape:** gently rounded slab (12pt continuous).
- **Primary:** lime fill (`voltage-*`), graphite label via `onFill`, SF headline semibold sentence case, full width, 54pt min height. Press: `.pressable()` scales to 0.97 with a 0.3s/0.7 spring.
- **Secondary:** raised fill (`*-raised-*`), text primary, 50pt min height. "+30 s", "Sensaciones, notas y fotos", "Reintentar".
- **Outline:** transparent, lime-text label, 1pt hairline in lime-text at 60 %, 50pt. "Saltar" in the rest sheet. This is one of the two surviving hairline roles.
- **Icon square:** 36×36 raised square, 12pt radius, SF footnote bold glyph (pause); lime fill with graphite glyph when it shows "play" (paused).

### Chips / Badges
- **Pill badge:** capsule, colour at 15 % fill, colour text, 11pt bold uppercase tracking 1 (`PillBadge`). The paywall's "Mejor valor" is the solid variant: lime fill, graphite 11pt semibold, 7×3pt padding.
- **Rep scheme chips:** 8pt squares in the exercise card header; sky fill with graphite label when the set is done, raised fill and secondary text when pending.

### Cards / Containers
- **Corner Style:** 16pt continuous (`cardStyle`); nested flat card 12pt (`flatCardStyle`).
- **Background:** surface; nested card and fields use raised.
- **Shadow Strategy:** `.lift()` — see Elevation.
- **Border:** none. State strokes (sky done, lime active/selected) replace the edge light via `.lift(stroke:)`.
- **Internal Padding:** 16pt.
- **Stats strip** (summary): one surface slab, three cells divided by 1×44pt line rectangles, 22pt mono value, 13pt caption label, 11pt tabular delta in lime-text when up or text tertiary otherwise.

### Inputs / Fields
- **Style:** raised fill, 8pt radius, 44pt tall, JetBrains Mono 16 semibold centred, no stroke. On the active row the field inverts to surface so it reads as a pocket in the raised row. The previous session's kilos sit as the placeholder.
- **Focus:** 1.5pt lime stroke, nothing else.
- **Done:** no stroke, text secondary, disabled.
- **Steppers:** 36×44 hit areas on each side of the field, 13pt bold SF symbol in text secondary, no outline.

### Navigation
- Native iOS tab bar (system material and tint); the lime appears only as the selected tab's tint. Screen titles use the title voice in the content, not the navigation bar. Sheets use surface fill with a 36×5 capsule drag indicator in text tertiary.

### Set Table (signature)
The instrument of the app (`ExerciseCardView.swift`). Columns SERIE / KG / REPS / check under an 11pt tracked column label. Each row is 44pt of controls with 4pt vertical and 6pt horizontal padding, bled 6pt past the card's inset.
- **Active (next) row:** raised fill, 12pt radius; set number in text primary; fields invert to surface; check is a 36pt square with lime at 14 % fill and a 1.5pt lime stroke. The transition to the next row springs at 0.35s / 0.85 damping.
- **Done row:** no row fill; set number and check in sky; check filled sky with a graphite checkmark (`onFill`); fields disabled in text secondary.
- **Pending row:** no fill, 72 % opacity, set number in text tertiary, check stroke text tertiary at 50 %.
- **Failure:** 24pt amber circle with "F" in graphite, shown only on a completed failed set.
- **Context menu:** record / view video and remove set live behind a long press; a sky `video.fill` glyph marks a row that has one.
- **Completion:** success notification haptic; rest starts.

### Rest Timer (signature)
Sheet on surface: "Descanso" in 15pt semibold secondary, countdown in JetBrains Mono 64 semibold with `numericText` transition, a 4pt rule in line that drains lime linearly over the rest, "Siguiente 3 · 62,5 kg × 8" in SF numeric, then outline "Saltar" and secondary "+30 s". Banner variant when dismissed: raised 12pt slab with lift, timer glyph in lime-text, 17pt mono time, native `ProgressView` tinted lime, "Saltar" and "+30 s" as 13pt text buttons.

### Workout Summary (signature)
Delta-first peak-end on a flat ground with a lime 16 % → 0 % vertical glow over the top 420pt. A 56pt sky square with a graphite check springs in (0.5s / 0.6), the rest fades and rises in at 0.5s / 0.85 after a 0.35s delay, and a success haptic fires on appear. Order: done mark, "ENTRENO COMPLETADO" poster, the volume in mono 44, the delta sentence in SF title3 semibold (lime-text when improved, secondary otherwise), the stats strip, then "Guardar y salir" (primary) and a secondary.

### Plan Row (paywall)
Surface slab, 16pt radius, 64pt min height, `.lift()`. Selected: lime 10 % tint over surface plus a 1pt lime stroke, radio with lime ring and 12pt lime dot. Unselected: plain surface, radio ring in text tertiary. Price in mono 17 semibold; per-month in SF numeric caption, lime-text on the best-value row.

### Meal Checklist (signature)
`DietView.swift` + `MealCardView.swift` + `SupplementsView.swift`. The day's meals are one lifted slab of rows: a 26pt square sky check (6pt radius, 44pt hit area), the meal name in SF headline, the first option as a caption hint, the time in tabular footnote, a chevron. The first meal not yet ticked sits on a raised `surfaceElevated` row, exactly like the active set in the set table; ticked rows strike through in `textSecondary`. Above the list: the day name in SF title3 semibold with "2/5 comidas" in tabular SF and a 3pt lime rule that turns sky when the day is done; then one lifted macro strip (kcal in JetBrains Mono 22, protein/carbs/fat in tabular SF headline). Cheat meal and supplements are quiet lifted slabs with sentence-case headings and doses on `surfaceElevated` chips. No ring, no emoji, no uppercase labels, no lime for "done".

### Calendar Day
Letter in caption2 (bold on today, text primary; medium text tertiary otherwise), 32pt square with 8pt radius filled lime on today with the day number in SF numeric bold graphite, and a 5pt sky dot beneath a logged day.

## Do's and Don'ts

### Do:
- **Do** lift every container with `.lift()`: top-edge white 9 % → 1.5 % 1pt stroke in dark, `#2A2A22` 7 % r12 y3 shadow in light. No outline.
- **Do** keep hairlines to two roles: 1pt `line` separators between list rows, and the outline button's 1pt border.
- **Do** keep lime on one object per region and sky on everything finished (the Two-Greens Rule).
- **Do** put graphite glyphs on lime and sky fills via `Color.onFill` (threshold L > 0.30).
- **Do** set the day's name and screen titles in SF bold, condensed width, sentence case (`.titleVoice`).
- **Do** use JetBrains Mono ≥16pt only where the number is the element: fields, timers, prices, hero and strip stats; use SF `monospacedDigit()` for a number inside a sentence.
- **Do** write every CTA in sentence case on a 54pt lime slab with 12pt radius.
- **Do** make the next set's row step forward (raised fill, primary number, lime-stroked check) and keep every table control 44pt tall.
- **Do** mark success with a spring (0.35–0.5s, 0.6–0.85 damping) and a success notification haptic.
- **Do** use the warm ramp as shipped; never pure black or white on canvas, container or text.

### Don't:
- **Don't** put a kicker or eyebrow above a heading; the 11pt tracked uppercase label exists for table column headers and tags only.
- **Don't** outline a container with a hairline; depth comes from fill and light.
- **Don't** shout a CTA, title or badge in Title Case or uppercase SF; only the two Saira posters are uppercase.
- **Don't** use mono as costume: no mono under 16pt, no mono in sentences, labels, dates or weekday letters, no mono for words ("iOS + Watch" is SF).
- **Don't** add a third Saira Condensed home.
- **Don't** draw side stripes, accent bars or gradient text; gradients are the ground's glow, the summary's lime region and the paywall's 28pt content fade only.
- **Don't** use sky for an action or lime for a done state.
- **Don't** use red; amber is the only error and warning colour.
- **Don't** stroke a field at rest; lime stroke on focus only, nothing when done.
- **Don't** stack shadows in dark mode or exceed the 7 % lift in light mode.
