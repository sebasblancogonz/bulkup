---
name: BulkUp iOS
description: Graphite & Voltage on native iOS — graphite or bone ground, one lime razor, sky for done, mono for every number.
colors:
  graphite-ground-dark: "#0E1110"
  graphite-glow-dark: "#181D1E"
  graphite-surface-dark: "#15191A"
  graphite-raised-dark: "#1D2224"
  graphite-line-dark: "#2A3033"
  bone-text-dark: "#F2F4F1"
  ash-text-secondary-dark: "#9BA39E"
  ash-text-tertiary-dark: "#7C8581"
  voltage-dark: "#B4FF2E"
  voltage-pressed-dark: "#93D414"
  voltage-glow-dark: "#C9FF66"
  voltage-text-dark: "#B4FF2E"
  sky-done-dark: "#00A9DD"
  amber-error-dark: "#F5A524"
  bone-ground-light: "#F2F4F1"
  bone-glow-light: "#FFFFFF"
  bone-surface-light: "#FFFFFF"
  bone-raised-light: "#E8EBE6"
  bone-line-light: "#D3D8D2"
  graphite-text-light: "#0E1110"
  ash-text-secondary-light: "#5B635E"
  ash-text-tertiary-light: "#747C78"
  voltage-light: "#8FDC14"
  voltage-pressed-light: "#6DB10C"
  voltage-glow-light: "#A8E83A"
  voltage-text-light: "#3E7000"
  sky-done-light: "#007DA8"
  amber-error-light: "#A86400"
  on-voltage: "#0E1110"
  shadow-dark: "#000000"
  shadow-light: "#1A1F1C"
typography:
  display:
    fontFamily: "Saira Condensed, system-ui-condensed, sans-serif"
    fontSize: "40pt"
    fontWeight: 800
    lineHeight: 0.95
    letterSpacing: "-0.2pt"
    textTransform: "uppercase"
  display-section:
    fontFamily: "Saira Condensed, system-ui-condensed, sans-serif"
    fontSize: "34pt"
    fontWeight: 800
    lineHeight: 1
    letterSpacing: "-0.2pt"
    textTransform: "uppercase"
  display-inline:
    fontFamily: "Saira Condensed, system-ui-condensed, sans-serif"
    fontSize: "20pt"
    fontWeight: 700
    lineHeight: 1
    letterSpacing: "-0.2pt"
    textTransform: "uppercase"
  headline:
    fontFamily: "SF Pro Text, -apple-system, system-ui, sans-serif"
    fontSize: "20pt"
    fontWeight: 600
    lineHeight: 1.25
  title:
    fontFamily: "SF Pro Text, -apple-system, system-ui, sans-serif"
    fontSize: "17pt"
    fontWeight: 600
    lineHeight: 1.3
  body:
    fontFamily: "SF Pro Text, -apple-system, system-ui, sans-serif"
    fontSize: "15pt"
    fontWeight: 400
    lineHeight: 1.35
  caption:
    fontFamily: "SF Pro Text, -apple-system, system-ui, sans-serif"
    fontSize: "13pt"
    fontWeight: 500
    lineHeight: 1.35
  label:
    fontFamily: "SF Pro Text, -apple-system, system-ui, sans-serif"
    fontSize: "11pt"
    fontWeight: 700
    letterSpacing: "1.4pt"
    textTransform: "uppercase"
  data:
    fontFamily: "JetBrains Mono, ui-monospace, monospace"
    fontSize: "15pt"
    fontWeight: 500
    lineHeight: 1.2
  data-small:
    fontFamily: "JetBrains Mono, ui-monospace, monospace"
    fontSize: "13pt"
    fontWeight: 500
    lineHeight: 1.2
  data-strong:
    fontFamily: "JetBrains Mono, ui-monospace, monospace"
    fontSize: "17pt"
    fontWeight: 600
    lineHeight: 1.2
  data-stat:
    fontFamily: "JetBrains Mono, ui-monospace, monospace"
    fontSize: "26pt"
    fontWeight: 600
    lineHeight: 1.1
  data-hero:
    fontFamily: "JetBrains Mono, ui-monospace, monospace"
    fontSize: "64pt"
    fontWeight: 600
    lineHeight: 1
rounded:
  sm: "8pt"
  md: "10pt"
  lg: "14pt"
  xl: "18pt"
  pill: "9999pt"
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
    typography: "{typography.display-inline}"
    rounded: "{rounded.md}"
    height: "54pt"
    padding: "0 16pt"
  button-primary-pressed:
    backgroundColor: "{colors.voltage-dark}"
    textColor: "{colors.on-voltage}"
    rounded: "{rounded.md}"
    height: "54pt"
  button-secondary:
    backgroundColor: "{colors.graphite-raised-dark}"
    textColor: "{colors.bone-text-dark}"
    typography: "{typography.body}"
    rounded: "{rounded.md}"
    height: "48pt"
  button-outline:
    backgroundColor: "transparent"
    textColor: "{colors.voltage-dark}"
    typography: "{typography.body}"
    rounded: "{rounded.md}"
    height: "48pt"
  card:
    backgroundColor: "{colors.graphite-surface-dark}"
    textColor: "{colors.bone-text-dark}"
    rounded: "{rounded.lg}"
    padding: "16pt"
  card-flat:
    backgroundColor: "{colors.graphite-raised-dark}"
    textColor: "{colors.bone-text-dark}"
    rounded: "{rounded.md}"
    padding: "16pt"
  card-active:
    backgroundColor: "{colors.graphite-surface-dark}"
    textColor: "{colors.bone-text-dark}"
    rounded: "{rounded.lg}"
    padding: "16pt"
  chip-pill:
    backgroundColor: "{colors.voltage-dark}"
    textColor: "{colors.voltage-dark}"
    typography: "{typography.label}"
    rounded: "{rounded.pill}"
    padding: "5pt 10pt"
  input-set:
    backgroundColor: "{colors.graphite-raised-dark}"
    textColor: "{colors.bone-text-dark}"
    typography: "{typography.data}"
    rounded: "{rounded.sm}"
    height: "40pt"
  check-done:
    backgroundColor: "{colors.sky-done-dark}"
    textColor: "{colors.bone-text-dark}"
    rounded: "{rounded.sm}"
    size: "34pt"
  calendar-day-today:
    backgroundColor: "{colors.voltage-dark}"
    textColor: "{colors.on-voltage}"
    typography: "{typography.data-small}"
    rounded: "{rounded.sm}"
    size: "32pt"
  plan-row:
    backgroundColor: "{colors.graphite-surface-dark}"
    textColor: "{colors.bone-text-dark}"
    rounded: "{rounded.lg}"
    padding: "16pt"
    height: "64pt"
  plan-row-selected:
    backgroundColor: "{colors.graphite-raised-dark}"
    textColor: "{colors.bone-text-dark}"
    rounded: "{rounded.lg}"
    padding: "16pt"
    height: "64pt"
---

# Design System: BulkUp iOS

## Overview

**Creative North Star: "The Instrument Panel"**

BulkUp on iOS is the landing's "Graphite & Voltage" world (`landing/DESIGN.md`) translated into native SwiftUI. The screen is a gym instrument, not a feed: a graphite (dark) or bone (light) ground that is never pure black or white, hairlines instead of shadows between blocks, numbers set in a monospace face so kilos, reps, timers and prices line up like a readout, and one electric-lime razor that fires only where there is action (the CTA, today's square in the week strip, the progress rule) or progress (the draining rest rule). Sky is the only other chroma, and it means exactly one thing: done.

Density is operational. The set table is the hero of the training screen; everything around it (segmented plan picker, date nav, week strip) is quiet chrome in secondary ash. Display moments are rare and loud: Saira Condensed, uppercase, ExtraBold at 40pt for the workout name or the paywall headline, with a lime progress rule underneath. Everything else is SF Pro at Dynamic Type sizes, so the brand lives in the three voices (display, UI, data), the tint discipline and the hairline, not in custom chrome. System navigation, tab bar and sheets stay native.

The build confirmed a few things the contract only proposed: cards are surface + 1pt hairline at 14pt, with no accent side-stripes; progress is a 4pt rule, not a ring, on every screen sampled; chips in set rows are square-ish (6–8pt) and only true chips (badges, "MEJOR VALOR", drag handle) are capsules.

**Key Characteristics:**
- Graphite / bone ground with a faint radial glow at the top (`BulkUpGround`), never a flat swatch, never #000 or #FFF.
- Two greens with two meanings: lime is action and progress, sky is done and logged. They never swap.
- Amber is the only error / warning colour; no red anywhere.
- Three type voices: Saira Condensed uppercase (display), SF Pro text styles (UI), JetBrains Mono (every datapoint).
- 1pt hairlines are the structural grammar; shadows are earned by floating controls and sheets only.
- Hierarchised radii 14 / 10 / 8 (cards / buttons & inputs / fields & small squares); capsules only for chips.

## Colors

Two tonal families (graphite at night, bone by day) carry a single lime accent, one sky "done" colour and one amber error colour; every token resolves per appearance through `Color.adaptive(dark:light:)`.

### Primary
- **Voltage Lime** (dark `{colors.voltage-dark}` / light `{colors.voltage-light}`): the action colour. Primary CTA fill, today's square in the week strip, the in-progress rule, the selected radio and selected plan-row hairline, the pulsing live-session dot. Rationed to ≤10% of any screen.
- **Voltage Pressed** (dark `{colors.voltage-pressed-dark}` / light `{colors.voltage-pressed-light}`): the deep end of the accent, the right end of `accentGradient`, the "diet" context tint and the small "PRO" tag tint (`secondary`).
- **Voltage Glow** (dark `{colors.voltage-glow-dark}` / light `{colors.voltage-glow-light}`): the light end of the accent; used by `accentGlowShadow` and highlight fills.
- **Voltage Text** (dark `{colors.voltage-text-dark}` / light `{colors.voltage-text-light}`): lime *as text or icon* on the ground. In light mode it darkens to a forest green so it clears 4.5:1 on bone; in dark mode it is the raw accent. Used for "BULKUP PRO", proof-strip values, unlock-list icons, "1/6" counters, inline text buttons ("Usar anterior", "Añadir serie").
- **On Voltage** (`{colors.on-voltage}`): graphite text and icons on any lime fill, both appearances. `Color.onFill` picks this by WCAG luminance.

### Secondary
- **Sky Done** (dark `{colors.sky-done-dark}` / light `{colors.sky-done-light}`): completed sets, logged exercises, the completed-day progress rule, the finished-workout mark, the logged-day dot under the week strip, "Ya eres PRO" seal. Also the "training" context tint for hub cards. Never used as a CTA.

### Tertiary
- **Amber Error** (dark `{colors.amber-error-dark}` / light `{colors.amber-error-light}`): the only error and warning colour (save failed, negative trend, validation). Lime is never "wrong" and red never competes with it.

### Neutral (dark appearance)
- **Graphite Ground** (`{colors.graphite-ground-dark}`): the screen canvas, sheet backgrounds, the pinned purchase panel.
- **Graphite Glow** (`{colors.graphite-glow-dark}`): the lighter radial the top of each screen fades from (85% opacity, 460pt radius, centred top).
- **Graphite Surface** (`{colors.graphite-surface-dark}`): cards, exercise cards, plan rows, summary stat cells.
- **Graphite Raised** (`{colors.graphite-raised-dark}`): nested containers, secondary buttons, set-row inputs, selected plan row, the pause button, the rest banner.
- **Graphite Line** (`{colors.graphite-line-dark}`): every 1pt hairline, the progress-rule track, the ring track, the 1pt gutters in the summary grid, unchecked outlines.
- **Bone Text** (`{colors.bone-text-dark}`): primary text and display headlines.
- **Ash Secondary** (`{colors.ash-text-secondary-dark}`): body copy under headlines, captions, micro labels, inactive week-strip letters.
- **Ash Tertiary** (`{colors.ash-text-tertiary-dark}`): placeholders, dividers in legal links, the unselected radio stroke, the drag indicator.

### Neutral (light appearance)
- **Bone Ground** (`{colors.bone-ground-light}`), **Bone Glow / Surface** (`{colors.bone-glow-light}`, `{colors.bone-surface-light}`), **Bone Raised** (`{colors.bone-raised-light}`), **Bone Line** (`{colors.bone-line-light}`): the same four roles by day; the surface is true white but the ground is bone, so cards still read as raised material.
- **Graphite Text** (`{colors.graphite-text-light}`), **Ash Secondary** (`{colors.ash-text-secondary-light}`), **Ash Tertiary** (`{colors.ash-text-tertiary-light}`): the inverse text ramp.
- **Shadow** (dark `{colors.shadow-dark}` / light `{colors.shadow-light}`): the only shadow colour, at 18% for `cardShadow` and 55% as the purchasing scrim.

### Named Rules
**The Two-Greens Rule.** Lime means action or progress; sky means done or logged. A checked set, a finished day, a logged meal turn sky; the CTA, today's square and the in-progress rule stay lime. Neither colour ever takes the other's job.

**The Razor Rule.** Lime covers ≤10% of any screen. One filled CTA per screen; everything else lime is a 1pt stroke, a 4pt rule, a 12pt radio dot, or text in `accentText`.

**The Amber-Only Rule.** Amber is the sole error and warning colour in both appearances. No red, no second alarm colour.

**The Never-Pure Rule.** The ground is graphite (#0E1110) or bone (#F2F4F1), never #000000 or #FFFFFF, and it always carries the top radial glow from `BulkUpGround`.

## Typography

**Display Font:** Saira Condensed (SemiBold 600, Bold 700, ExtraBold 800; bundled TTFs, registered in Info.plist)
**Body Font:** SF Pro via system text styles (Dynamic Type)
**Label/Mono Font:** JetBrains Mono (Medium 500, SemiBold 600; bundled)

**Character:** A condensed, uppercase display voice that lands like a plate on a bar, a neutral native UI voice that disappears, and a monospace data voice that makes every number look measured. All three scale with Dynamic Type: custom faces are declared `relativeTo:` a system text style.

### Hierarchy
- **Display** (Saira Condensed ExtraBold 800, 40pt relative to largeTitle, uppercase, tracking −0.2, lineSpacing −4): the one headline of a screen — today's workout name, "TU PROGRESO, VISIBLE.", "ENTRENO COMPLETADO". Four uses across the app; never more than one per screen.
- **Display Section** (Saira Condensed ExtraBold 800, 34–36pt relative to largeTitle, uppercase): the day name on the training screen, the PRO gate title, the completed-day block (32pt).
- **Display Inline** (Saira Condensed Bold 700 / SemiBold 600, 19–20pt relative to headline, uppercase): the workout name in the live-session header; the primary button label at 19pt SemiBold with tracking 0.8.
- **Headline** (SF Pro Semibold 600, title3 ≈ 20pt): section headers (`sectionHeader()`), 47 uses.
- **Title** (SF Pro Semibold 600, headline ≈ 17pt): card titles, exercise names, plan names, unlock-list titles (`cardTitle()`).
- **Body** (SF Pro Regular 400, subheadline ≈ 15pt): the one-line sub under a display headline, feature rows, descriptions (`body()`).
- **Caption** (SF Pro Medium 500, footnote ≈ 13pt): meta lines, "90s descanso", renewal copy, trend text (`caption()`, 250 uses; the workhorse).
- **Label** (SF Pro Bold 700, caption2 ≈ 11pt, tracking 1.4, uppercase): `microLabel()` — column headers (SERIE · PESO · REPS), data-strip labels (ENTRENOS · DIETA), section labels (LO QUE DESBLOQUEAS, EJERCICIOS, DESCANSO), stat-cell labels. Badge text uses the same face at tracking 1.0.
- **Data** (JetBrains Mono Medium 500, 15pt relative to subheadline): set-row kg and reps inputs, proof-strip values, "6 ejercicios · 21 series" counts.
- **Data Small** (JetBrains Mono Medium 500, 12–13pt relative to footnote/caption): previous-set hints ("ant. 60 kg × 12"), week-strip day numbers, dates, per-month price, set-count badges.
- **Data Strong** (JetBrains Mono SemiBold 600, 16–17pt relative to headline): prices, elapsed session time, data-strip values.
- **Data Stat** (JetBrains Mono SemiBold 600, 26–28pt relative to title2): stat cards and the workout-summary grid.
- **Data Hero** (JetBrains Mono SemiBold 600, 44–64pt relative to largeTitle): the rest countdown (64pt); `heroStat()` 44pt and `heroStatMedium()` 36pt for big single stats.

### Named Rules
**The Mono-For-Numbers Rule.** Every kilo, rep, %, timer, price, date-number and streak is set in JetBrains Mono. A number in SF Pro is a defect.

**The One-Shout Rule.** Saira Condensed appears once per screen as the headline (plus the CTA label and the live-session header name). Section titles, card titles and body are SF Pro.

**The Relative-To Rule.** Custom faces are always declared `relativeTo:` a system text style so Dynamic Type scales them; raw point sizes without a style are not used.

## Layout

Single-column, full-bleed lists on a 20pt horizontal screen margin (`Spacing.screenH`). The vertical rhythm runs on a 4/8/16/24/32/48 scale with a dedicated 28pt `sectionGap` between major blocks. Screens are a `ZStack` over `BulkUpGround`, a `ScrollView` of `VStack`s, and the primary CTA either sits inside the display block (Today, Training) or is pinned with `safeAreaInset(edge: .bottom)` on a ground-coloured panel with a 1pt top hairline (paywall).

Lists are hairline-separated rows, not stacked cards: the unlock list, the exercise list on Today, the meal list and the proof strip all use a 1pt `line` Rectangle as the separator, with 16pt vertical padding per row (10pt in compact feature rows). Strips of evidence (week strip, data strip, proof strip) are bounded top and bottom by hairlines and divided by 1pt × 30pt vertical rules, items `maxWidth: .infinity` so they share the width evenly.

The set table in an exercise card is a fixed-column instrument: 32pt steppers either side of a 46pt kg field (110pt total) and a 28pt reps field (92pt total), a 44pt check target, rows at 40pt. Touch targets for anything used mid-set are ≥44pt (steppers are 32pt wide but full row height). Text uses Dynamic Type everywhere; display and mono faces scale through `relativeTo:`. Both appearances are first-class: every colour token is adaptive and screenshots exist for each.

## Elevation & Depth

Depth is tonal and linear, not cast. Four tonal steps (ground → surface → raised) plus a 1pt hairline in the `line` colour give every container its edge; the top-of-screen radial glow in `BulkUpGround` gives the canvas its material. Cards do not carry shadows at rest. State is shown by changing the hairline colour (lime at 60–70% for active/accent cards, lime solid for the selected plan row, sky at 60% for a completed exercise card) rather than by lifting.

### Shadow Vocabulary
- **Card shadow** (`shadow(color: shadow.opacity(0.18), radius: 12, y: 6)`): helper exists for floating elements (sheets, floating controls); not applied to content cards.
- **Accent glow** (`shadow(color: accent.opacity(0.35), radius: 16)`): a lime halo for a floating lime control (the live-session mini timer).
- **Scrim** (`shadow.opacity(0.55)` full-screen, or `background.opacity(0.92)` for the PRO gate overlay): dims content under a modal state.
- **Glass**: `.ultraThinMaterial` / `.glassEffect()` appear only in the navigation layer (tab bar container); never on content cards.

### Named Rules
**The Hairline-Over-Shadow Rule.** A 1pt stroke in `line` (or a tinted hairline for state) separates and contains; shadows are reserved for things that genuinely float above the scroll (sheets, floating timers). A content card with a drop shadow is a defect.

**The Tinted-Edge Rule.** State lives in the hairline colour, not in a side stripe or a tinted fill: lime 60–70% for active, sky 60% for done, solid lime for selected.

## Shapes

Continuous-corner rounded rectangles throughout (`style: .continuous`), hierarchised by element size: 14pt for cards, exercise cards, plan rows, the summary grid and the 64pt done mark; 10pt for buttons, inputs, the pause square, the rest banner and nested flat cards; 8pt for set-row fields, the 34pt check square and the 32pt today square in the week strip; 18pt (`xl`) reserved for sheets and hero blocks. Sub-8 radii (6–7pt) are used only on ≤28pt squares (rep chips, the exercise-level logged square). Capsules are chips only: `PillBadge`, the "MEJOR VALOR" tag, the sheet drag indicator. Progress is a 4pt straight rule with butt caps, not a ring; the `GradientProgressRing` component exists with butt caps and a `line` track for the few places a ring is needed. Radios are 22pt circles with a 1.5pt stroke and a 12pt lime dot.

## Components

### Buttons
Squared, confident, one per screen in lime.
- **Shape:** gently squared (10pt continuous radius), full width.
- **Primary** (`primaryButtonStyle`): lime fill, graphite label in Saira Condensed SemiBold 19pt uppercase with 0.8 tracking, 54pt min height. Pressed: scale 0.97 with a spring (`pressable()`), no colour change.
- **Secondary** (`secondaryButtonStyle`): raised surface fill, primary text in SF subheadline Semibold, 1pt `line` hairline, 48pt min height. Used for "+30 s", "Gestionar suscripción", "Reintentar".
- **Outline** (`outlineButtonStyle`): transparent fill, lime text, lime 70% hairline, 48pt. Used for "Saltar" rest.
- **Text actions:** inline SF footnote/subheadline Semibold in `accentText` ("Usar anterior", "Añadir serie", "Saltar" in the banner); 32pt min height for legal "Restaurar compras".
- **Icon squares:** 36pt raised square at 10pt radius with a hairline (pause); turns lime fill + lime hairline when the session is paused.

### Chips
- **PillBadge:** capsule, colour at 15% fill, colour text in SF caption2 Bold uppercase tracking 1.0, 10×5pt padding, optional 9pt SF Symbol.
- **Best-value tag:** capsule, solid lime, graphite text, 7×3pt padding, tracking 0.8.
- **Rep chips (set row):** 6pt-radius squares, raised fill with mono 12pt; sky fill with on-fill text once the set is logged.

### Cards / Containers
- **Card** (`cardStyle`): surface fill, 14pt continuous radius, 1pt `line` hairline, 16pt padding. The exercise card, the active-subscription block, the "Procesando…" box.
- **Flat card** (`flatCardStyle`): raised fill, 10pt radius, no hairline, 16pt padding. `StatCard` and nested containers.
- **Accent / Active card:** card with the hairline tinted lime at 60% / 70% (the compact PRO gate at 50%).
- **Completed exercise card:** card hairline tinted sky 60%.
- **Summary grid:** 2-column cells of surface on a `line` background so the 0.5pt cell inset reads as 1pt hairline gutters, clipped at 14pt with an outer hairline.
- **Shadow strategy:** none at rest (see Elevation & Depth).

### Inputs / Fields
- **Set-row field:** raised fill, 8pt continuous radius, 40pt high, JetBrains Mono 15pt centred, `line` 1pt stroke; decimal/number keypad. Once the set is logged the stroke turns sky (60% in stepper rows, solid in the compact Today logger). Steppers are 32pt-wide SF bold "−" / "+" either side of the field inside the same rounded container.
- **Notes:** plain `TextField` "Notas…" in caption, tertiary placeholder, no container.
- **Placeholder:** "—" in tertiary text.

### Navigation
- **Tab bar:** system `TabView` with SF Symbols, tinted lime for the selected tab; iOS 26 glass container untouched.
- **Nav bar:** `.inline` title, background hidden on brand screens so `BulkUpGround` runs under it; close is an `xmark` SF Symbol in footnote Bold tinted primary text.
- **Segmented plan picker (Training):** two raised, hairlined segments "Plan Activo / Mis Planes" plus a "···" overflow square.
- **Date nav:** 36pt circular chevron buttons on raised fill, date in SF body.
- **Sheets:** ground-coloured, 36×5pt tertiary capsule drag indicator, 16pt top padding.

### Week Strip (signature)
Seven `CalendarDayView`s between two hairlines: day letter in SF 13pt (Bold + primary when today, Medium + secondary otherwise), the day number in mono 13pt inside a 32pt square — lime fill at 8pt radius with graphite text for today, clear otherwise — and a 5pt sky dot beneath logged days.

### Display Block + Progress Rule (signature)
A micro label (HOY / day name, lime text; sky when done), the workout name in Display 40pt, a mono count line ("6 ejercicios · 21 series" or "1/6"), then a 4pt rule: `line` track, lime fill proportional to progress (easeOut 0.4s), turning full sky when the day is done. The primary CTA sits directly beneath.

### Data Strip (signature)
A hairline-bounded `HStack` of equal-width items: value in mono 17pt SemiBold (or 15pt on the paywall proof strip, in `accentText`), label beneath as a micro label; 1pt × 30pt `line` dividers between items.

### Rest Timer (signature)
Sheet: "DESCANSO" micro label, countdown in mono 64pt SemiBold with `numericText(countsDown:)` transition, a 4pt lime rule that drains linearly over the rest, "Siguiente" + mono next-set line, then Outline "Saltar" and Secondary "+30 s" side by side. Banner (sheet dismissed): raised 10pt container with a lime 60% hairline, timer icon in `accentText`, mono 16pt time, a lime system `ProgressView`, and two footnote text actions.

### Plan Row (signature)
64pt min height, surface fill (raised when selected), 14pt radius, hairline `line` (solid lime when selected); 22pt radio with a 12pt lime dot; title in Title, detail in Caption; price right-aligned in mono 17pt SemiBold with the per-month equivalent in mono 12pt `accentText`.

### Live-Session Header (signature)
8pt lime dot pulsing (scale 1.3 / opacity 0.6, 1s easeInOut repeat) beside the elapsed time in mono 17pt SemiBold; workout name centred in Display Inline 20pt; 36pt pause square at the trailing edge.

## Do's and Don'ts

### Do:
- **Do** put every number in JetBrains Mono via `BulkUpFont.mono(_:weight:relativeTo:)`, including dates, counts, prices and timers.
- **Do** limit each screen to one Saira Condensed headline (40pt ExtraBold, uppercase via `displayVoice`) and one lime-filled CTA (`primaryButtonStyle`, 54pt).
- **Do** separate rows and bound strips with 1pt `BulkUpColors.line` Rectangles; contain cards with `hairline()` at 14pt.
- **Do** turn things sky (`BulkUpColors.complete`) when they are done: set checks, logged squares, finished-day rule, week-strip dots.
- **Do** use `accentText` (not `accent`) for lime text and icons on the ground so light mode stays ≥4.5:1.
- **Do** declare custom fonts `relativeTo:` a text style and keep mid-set controls at ≥44pt.
- **Do** start every top-level screen on `BulkUpGround()` and hide the nav-bar background so the glow runs under it.
- **Do** show state in the hairline colour: lime 60–70% active, sky 60% done, solid lime selected.

### Don't:
- **Don't** use pure black or pure white as a ground, or a flat swatch without the top radial glow.
- **Don't** use lime to mean "done" or sky to mean "go": the two greens never swap jobs.
- **Don't** use red; amber (`warning` / `error`) is the only alarm colour.
- **Don't** put drop shadows on content cards or use glass on content; both belong to floating controls and the navigation layer only.
- **Don't** add accent side-stripes, gradient text, gradient rings or crown/trophy badges to cards and headers.
- **Don't** use capsules for anything but chips, tags and the drag indicator; buttons, inputs and squares are 10pt / 8pt continuous rectangles.
- **Don't** nest a card inside a card; nested content uses `flatCardStyle` (raised fill, 10pt, no hairline) or a hairline list.
- **Don't** set a number in SF Pro or a display headline in a weight lighter than SemiBold.
