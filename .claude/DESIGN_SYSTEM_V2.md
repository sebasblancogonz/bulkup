# BulkUp Design System V2 — Complete Redesign Specification
## "Dark Forge" — Premium Fitness Aesthetic, 2026

---

# A. COLOR PALETTE

The new identity moves away from generic iOS blue/orange toward a bold, ownable palette. The primary color is a warm electric amber — energetic, motivational, and distinctive in the fitness app space. Dark mode is the PRIMARY experience.

## Dark Mode (Primary)

### Brand Colors
| Token                  | Hex       | Usage                                      |
|------------------------|-----------|---------------------------------------------|
| `brand.primary`        | `#F5A623` | Primary amber — logo, active tab, key CTAs  |
| `brand.primaryLight`   | `#FFD080` | Hover/highlight states on primary            |
| `brand.primaryDark`    | `#C47F0A` | Pressed states on primary                    |
| `brand.secondary`      | `#6C5CE7` | Secondary violet — accent charts, badges     |
| `brand.secondaryLight` | `#A29BFE` | Secondary highlight states                   |
| `brand.accent`         | `#00E676` | Success/completion green — CTA gradients     |

### Surfaces
| Token                  | Hex       | Usage                                      |
|------------------------|-----------|---------------------------------------------|
| `surface.base`         | `#0D0D0F` | App background (near-black, warm undertone) |
| `surface.raised`       | `#1A1A1F` | Card backgrounds, sheets                     |
| `surface.elevated`     | `#242429` | Elevated cards, modals, popovers             |
| `surface.overlay`      | `#2E2E35` | Input fields, segmented controls background  |
| `surface.divider`      | `#3A3A42` | Separators, borders                          |

### Text
| Token                  | Hex       | Usage                                      |
|------------------------|-----------|---------------------------------------------|
| `text.primary`         | `#F2F2F7` | Headings, primary content                    |
| `text.secondary`       | `#8E8E93` | Subtitles, metadata, captions                |
| `text.tertiary`        | `#636366` | Placeholder text, disabled labels            |
| `text.inverse`         | `#0D0D0F` | Text on brand.primary buttons                |

### Semantic Colors
| Token                  | Hex       | Usage                                      |
|------------------------|-----------|---------------------------------------------|
| `semantic.success`     | `#00E676` | Completed exercises, saved states            |
| `semantic.successBg`   | `#00E67615` | 8% opacity background for success badges   |
| `semantic.warning`     | `#FFAB40` | Approaching limits, partial completion       |
| `semantic.warningBg`   | `#FFAB4015` | 8% opacity background                      |
| `semantic.error`       | `#FF5252` | Errors, destructive actions                  |
| `semantic.errorBg`     | `#FF525215` | 8% opacity background                      |
| `semantic.info`        | `#448AFF` | Informational, links, tips                   |
| `semantic.infoBg`      | `#448AFF15` | 8% opacity background                      |

### Feature Colors (for section theming)
| Token                  | Hex       | Usage                                      |
|------------------------|-----------|---------------------------------------------|
| `feature.training`     | `#448AFF` | Training section tint                        |
| `feature.diet`         | `#66BB6A` | Diet section tint                            |
| `feature.progress`     | `#F5A623` | Progress/stats section tint                  |
| `feature.profile`      | `#6C5CE7` | Profile section tint                         |

### Gradients
| Token                       | Values                               | Usage                          |
|-----------------------------|--------------------------------------|--------------------------------|
| `gradient.primaryCTA`       | `#F5A623` -> `#FF8F00`              | Primary buttons                |
| `gradient.success`          | `#00E676` -> `#00C853`              | Completion states              |
| `gradient.premiumBadge`     | `#6C5CE7` -> `#A29BFE`              | PRO badges, subscription       |
| `gradient.cardShine`        | `#FFFFFF08` -> `#FFFFFF00`           | Subtle card highlight          |
| `gradient.backgroundMesh`   | `#F5A62308` center, `#0D0D0F` edges | Subtle ambient glow on screens |

---

## Light Mode (Secondary)

### Surfaces
| Token                  | Hex       |
|------------------------|-----------|
| `surface.base`         | `#F5F5F7` |
| `surface.raised`       | `#FFFFFF` |
| `surface.elevated`     | `#FFFFFF` |
| `surface.overlay`      | `#EBEBF0` |
| `surface.divider`      | `#D1D1D6` |

### Text
| Token                  | Hex       |
|------------------------|-----------|
| `text.primary`         | `#1C1C1E` |
| `text.secondary`       | `#8E8E93` |
| `text.tertiary`        | `#AEAEB2` |
| `text.inverse`         | `#FFFFFF` |

All brand, semantic, feature, and gradient colors remain the same in light mode. Only surfaces and text adapt.

---

# B. TYPOGRAPHY SCALE

Use **SF Pro** as the primary typeface. Use **SF Pro Rounded** for numerical displays and stat widgets to convey energy.

| Token         | Font            | Size | Weight    | Line Height | Tracking | Usage                              |
|---------------|-----------------|------|-----------|-------------|----------|------------------------------------|
| `display.xl`  | SF Pro Rounded  | 48pt | Bold      | 56pt        | -0.5pt   | Hero stats (weight, streak count)  |
| `display.lg`  | SF Pro Rounded  | 36pt | Bold      | 42pt        | -0.5pt   | Large stat numbers                 |
| `display.md`  | SF Pro Rounded  | 28pt | Bold      | 34pt        | -0.3pt   | Card stat numbers                  |
| `title.lg`    | SF Pro          | 28pt | Bold      | 34pt        | 0        | Screen titles (navigation)         |
| `title.md`    | SF Pro          | 22pt | Bold      | 28pt        | 0        | Section titles                     |
| `title.sm`    | SF Pro          | 20pt | Semibold  | 24pt        | 0        | Card titles                        |
| `headline`    | SF Pro          | 17pt | Semibold  | 22pt        | -0.2pt   | Section headers, exercise names    |
| `body.lg`     | SF Pro          | 17pt | Regular   | 24pt        | 0        | Primary body text                  |
| `body.md`     | SF Pro          | 15pt | Regular   | 20pt        | 0        | Secondary body, descriptions       |
| `body.sm`     | SF Pro          | 13pt | Regular   | 18pt        | 0        | Compact body text                  |
| `caption.lg`  | SF Pro          | 13pt | Medium    | 18pt        | 0        | Labels, tags, metadata             |
| `caption.sm`  | SF Pro          | 11pt | Medium    | 14pt        | 0.2pt    | Timestamps, fine print             |
| `caption.xs`  | SF Pro          | 10pt | Semibold  | 12pt        | 0.5pt    | Tab bar labels, badge text         |
| `mono`        | SF Mono         | 15pt | Medium    | 20pt        | 0        | Weight inputs, set numbers         |

### Typography Rules
- ALL CAPS: Only for tab bar labels, badge text, and section eyebrows. Use `caption.xs` with 0.5pt tracking.
- Numbers in stats: Always use `SF Pro Rounded` (the `display.*` tokens).
- Weight inputs: Use `SF Mono` for alignment in grids.
- Minimum touch-target text: `body.sm` (13pt).

---

# C. SPACING SYSTEM

Base unit: **4pt**. All spacing is a multiple of 4.

| Token    | Value | Usage                                          |
|----------|-------|------------------------------------------------|
| `xxs`    | 2pt   | Icon-to-text tight spacing (inside tags)       |
| `xs`     | 4pt   | Minimal gaps (between status dots)             |
| `sm`     | 8pt   | Compact spacing (inside compact cards, between chips) |
| `md`     | 12pt  | Default inner gap (label groups, field spacing) |
| `base`   | 16pt  | Standard padding (card internal, section gaps)  |
| `lg`     | 20pt  | Between cards in a list                         |
| `xl`     | 24pt  | Between major sections on a screen              |
| `xxl`    | 32pt  | Screen top/bottom breathing room                |
| `xxxl`   | 48pt  | Hero section vertical spacing                   |

### Layout Constants
| Token                    | Value | Usage                                    |
|--------------------------|-------|------------------------------------------|
| `page.horizontalMargin`  | 20pt  | Left/right screen margins                |
| `page.topInset`          | 16pt  | Below navigation bar                     |
| `card.padding`           | 16pt  | Internal card padding (all sides)        |
| `card.paddingCompact`    | 12pt  | Compact card variant padding             |
| `card.cornerRadius`      | 16pt  | Standard card corners                    |
| `card.cornerRadiusSmall` | 12pt  | Nested elements, inputs, tags            |
| `card.cornerRadiusPill`  | 9999pt | Pill-shaped elements (badges, chips)    |
| `button.height`          | 52pt  | Primary button height                    |
| `button.heightCompact`   | 44pt  | Secondary/compact button height          |
| `input.height`           | 48pt  | Text field height                        |
| `tabBar.height`          | 56pt  | Custom tab bar height (excluding safe area) |
| `bottomSafeSpacing`      | 100pt | Scroll content bottom inset (tab bar + padding) |

---

# D. COMPONENT LIBRARY

## D1. Cards

### Elevated Card (Standard)
- Background: `surface.raised`
- Corner radius: `card.cornerRadius` (16pt)
- Padding: `card.padding` (16pt)
- Border: 1pt `surface.divider` at 50% opacity
- Shadow: none in dark mode (rely on surface contrast). In light mode: `0 2 8 rgba(0,0,0,0.06)`
- No gradient overlays on standard cards.

### Interactive Card (Tappable)
- Same as Elevated Card, plus:
- On press: scale to 0.98, background shifts to `surface.elevated`
- Transition: spring(response: 0.25, dampingFraction: 0.8)
- Chevron indicator: `caption.sm` size, `text.tertiary` color, right-aligned

### Stat Card
- Background: `surface.raised`
- Corner radius: 16pt
- Internal layout: vertical stack
  - Eyebrow label: `caption.xs`, ALL CAPS, `text.secondary`, tracking 0.5pt
  - Stat number: `display.md` (28pt), `text.primary`
  - Delta indicator (optional): `caption.lg`, colored pill with up/down arrow
    - Positive: `semantic.success` text on `semantic.successBg`
    - Negative: `semantic.error` text on `semantic.errorBg`
    - Neutral: `text.secondary` text on `surface.overlay`
- Left accent bar: 3pt wide, full height, colored per stat type, corner radius 2pt

### Feature Card (Onboarding, Plan cards)
- Background: subtle gradient from `surface.raised` to `surface.elevated`
- Left icon area: 48x48pt rounded square (12pt radius), filled with feature color at 15% opacity, icon in feature color
- Title: `headline`, `text.primary`
- Subtitle: `body.sm`, `text.secondary`
- Right chevron: 24x24pt circle, `surface.overlay` background, `text.tertiary` icon

---

## D2. Buttons

### Primary Button
- Height: 52pt
- Corner radius: 14pt
- Background: `gradient.primaryCTA` (`#F5A623` -> `#FF8F00`)
- Text: `headline` (17pt Semibold), `text.inverse` (`#0D0D0F`)
- Full width by default (`maxWidth: .infinity`)
- Shadow: `0 4 16 #F5A62340` (25% opacity amber glow)
- Press state: scale 0.97, shadow reduces to `0 2 8 #F5A62320`
- Disabled state: opacity 0.4, no shadow
- Loading state: replace text with 20pt white `ProgressView`

### Secondary Button
- Height: 44pt
- Corner radius: 12pt
- Background: `surface.overlay`
- Text: `body.md` (15pt Semibold), `text.primary`
- Border: 1pt `surface.divider`
- Press state: background shifts to `surface.divider`

### Ghost Button
- Height: 44pt
- Background: transparent
- Text: `body.md` (15pt Medium), `brand.primary`
- Press state: background `brand.primary` at 8% opacity

### Destructive Button
- Same dimensions as Secondary
- Text color: `semantic.error`
- Border color: `semantic.error` at 30% opacity
- Press background: `semantic.errorBg`

### Icon Button
- Size: 40x40pt (standard) or 32x32pt (compact)
- Corner radius: 10pt
- Background: `surface.overlay`
- Icon: 16pt (standard) or 14pt (compact), `text.secondary`
- Press state: background `surface.divider`, icon `text.primary`

### Floating Action Button (FAB) — for "Add" actions in library views
- Size: 56x56pt
- Corner radius: 16pt
- Background: `gradient.primaryCTA`
- Icon: 24pt, `text.inverse`
- Shadow: `0 8 24 #F5A62350`
- Position: 20pt from right edge, 20pt above tab bar

---

## D3. Tab Bar (Custom)

Replace the system tab bar with a fully custom implementation.

- Background: `surface.raised` with 0.95 ultraThinMaterial blur
- Top border: 0.5pt `surface.divider`
- Height: 56pt content + safe area inset
- Layout: equal-width HStack, 4 tabs (reduced from 6 — see Section G3)

### Tab Item (Inactive)
- Icon: SF Symbol, 22pt, medium weight, `text.tertiary`
- Label: `caption.xs` (10pt, Semibold), ALL CAPS, `text.tertiary`
- Spacing icon-to-label: 4pt

### Tab Item (Active)
- Icon: SF Symbol filled variant, 22pt, semibold, `brand.primary`
- Label: `caption.xs`, `brand.primary`
- Active indicator: 4pt tall pill (24pt wide), `brand.primary`, positioned 4pt above the icon, corner radius 2pt
- Transition: icon swap with `.symbolEffect(.bounce)`, label color with 0.2s ease

### Tab Configuration (4 tabs)
| Tab        | Icon (inactive)           | Icon (active)              | Label     |
|------------|---------------------------|----------------------------|-----------|
| Entreno    | `dumbbell`                | `dumbbell.fill`            | ENTRENO   |
| Dieta      | `leaf`                    | `leaf.fill`                | DIETA     |
| Progreso   | `chart.line.uptrend.xyaxis` | `chart.line.uptrend.xyaxis` | PROGRESO  |
| Perfil     | `person.circle`           | `person.circle.fill`       | PERFIL    |

Rationale for 4 tabs: Merge "Mis RM" into the Progress tab as a sub-section. Merge "Ejercicios" into the Training hub as a discovery feature. This reduces cognitive load and follows the 4-5 tab best practice.

---

## D4. Section Headers

### Standard Section Header
- Layout: HStack
- Left: `headline` (17pt Semibold), `text.primary`
- Right (optional): Ghost button with `body.sm` text + chevron, `brand.primary`
- Bottom spacing: `md` (12pt)

### Section Header with Eyebrow
- Eyebrow: `caption.xs`, ALL CAPS, feature color, tracking 0.5pt
- Title: `title.md` (22pt Bold), `text.primary`
- Spacing eyebrow-to-title: `xs` (4pt)

---

## D5. Stat Widgets

### Inline Stat
- Layout: horizontal — icon (20pt) | value (`display.md`) | label (`caption.lg`)
- Used in summary bars

### Stat Ring
- Outer diameter: 64pt (standard) or 44pt (compact)
- Track: 4pt stroke, `surface.divider`
- Progress: 4pt stroke, lineCap round, colored per metric
- Center: stat value in `body.md` (Semibold) or completion icon
- Animation: `.easeInOut(duration: 0.6)` on appear

### Streak Counter
- Layout: flame icon (SF Symbol `flame.fill`, `#FF6D00`) + count (`display.md`, `#FF6D00`)
- Background pill: `#FF6D0012` (7% opacity), corner radius pill
- Padding: 8pt vertical, 16pt horizontal

---

## D6. Progress Indicators

### Linear Progress Bar
- Height: 6pt (standard) or 4pt (compact)
- Track: `surface.divider`, corner radius 3pt
- Fill: feature color, corner radius 3pt, animated width
- Optional label at trailing end: `caption.sm`, value + "%"

### Skeleton Loading
- Background: `surface.overlay`
- Shimmer: linear gradient sweep from `surface.overlay` -> `surface.divider` -> `surface.overlay`
- Animation: 1.5s linear repeat, left-to-right sweep
- Shape: match the element being loaded (rounded rect for cards, circle for avatars, capsule for text lines)
- Use skeleton screens instead of spinners for all content loading states.

---

## D7. Input Fields

### Standard Text Field
- Height: 48pt
- Background: `surface.overlay`
- Corner radius: 12pt
- Border: 1pt `surface.divider` (default), 1.5pt `brand.primary` (focused)
- Text: `body.md`, `text.primary`
- Placeholder: `body.md`, `text.tertiary`
- Left icon (optional): 20pt, `text.secondary`, 12pt spacing to text
- Padding: 16pt horizontal

### Numeric Input (Weight tracking)
- Height: 48pt
- Width: 80pt (fixed)
- Background: `surface.overlay`
- Corner radius: 10pt
- Text: `mono` (15pt SF Mono Medium), center-aligned, `text.primary`
- Unit label below: `caption.sm`, `text.tertiary`
- Focus ring: 1.5pt `brand.primary`
- Completed state: background `semantic.successBg`, border `semantic.success` at 30%

### Segmented Control (Section Picker)
- Height: 40pt
- Background: `surface.overlay`, corner radius 10pt
- Segment: `body.sm` (Semibold), `text.secondary`
- Active segment: `surface.raised` background, `text.primary` text, corner radius 8pt
- Active indicator: subtle shadow `0 1 4 rgba(0,0,0,0.15)` (dark mode)
- Transition: spring(response: 0.3, dampingFraction: 0.85)

---

## D8. Tags / Chips

### Filter Chip
- Height: 32pt
- Padding: 12pt horizontal
- Corner radius: pill (9999pt)
- Inactive: `surface.overlay` background, `text.secondary` text, `body.sm`
- Active: `brand.primary` at 15% opacity background, `brand.primary` text, 1pt `brand.primary` border
- Transition: 0.2s ease

### Label Tag
- Height: 24pt
- Padding: 8pt horizontal
- Corner radius: 6pt
- Background: semantic color at 12% opacity
- Text: `caption.lg`, semantic color
- Used for: "Completado", "PRO", "Nuevo", set count badges

---

## D9. List Rows

### Standard Row
- Height: minimum 56pt (auto-sizing)
- Padding: 16pt horizontal, 12pt vertical
- Left icon: 36x36pt rounded square (10pt radius), feature color at 12% background
- Title: `body.lg`, `text.primary`
- Subtitle: `caption.lg`, `text.secondary`
- Right accessory: chevron (14pt, `text.tertiary`) or toggle or value text
- Separator: 0.5pt `surface.divider`, leading inset 64pt (aligned after icon)

### Swipeable Row
- Same as Standard Row
- Leading swipe: `semantic.success` background, checkmark icon (mark complete)
- Trailing swipe: `semantic.error` background, trash icon (delete)
- Swipe threshold: 80pt

---

## D10. Empty States

### Layout
- Center-aligned vertically in available space
- Top: 80x80pt icon area
  - Circle background: feature color at 10% opacity, 80pt diameter
  - Icon: 40pt, feature color
- Title: `title.md` (22pt Bold), `text.primary`, 16pt below icon
- Subtitle: `body.md`, `text.secondary`, center-aligned, max 280pt width, 8pt below title
- Primary CTA: Primary Button, 32pt below subtitle
- Secondary link (optional): Ghost Button, 12pt below primary

### Illustration Concepts (for future asset creation)
- Training empty: stylized dumbbell with upward arrow motif
- Diet empty: stylized leaf with fork
- Progress empty: ascending bar chart with sparkle
- Style: monoline, 2-color (feature color + `text.tertiary`), 120x120pt

---

## D11. Notifications / Toasts

### Toast Banner
- Position: top of screen, below safe area, 20pt horizontal margin
- Background: `surface.elevated` with ultraThinMaterial
- Corner radius: 14pt
- Height: auto (min 52pt)
- Layout: HStack — status icon (20pt) | message (`body.sm`, `text.primary`) | dismiss X (optional)
- Status icon colors: success = `semantic.success`, error = `semantic.error`, info = `semantic.info`
- Entry animation: slide down + opacity, spring(response: 0.4, dampingFraction: 0.8)
- Auto-dismiss: 3 seconds
- Shadow: `0 4 20 rgba(0,0,0,0.25)`

---

# E. ANIMATION & MOTION

## Transition Standards
| Context                  | Animation                                            | Duration |
|--------------------------|------------------------------------------------------|----------|
| Tab switch content       | Crossfade opacity                                    | 0.2s     |
| Card expand/collapse     | `spring(response: 0.35, dampingFraction: 0.85)`      | ~0.35s   |
| Button press             | Scale 0.97 + opacity 0.9                              | 0.15s    |
| Sheet presentation       | iOS default detent (keep native)                      | system   |
| Navigation push          | iOS default (keep native)                             | system   |
| Skeleton shimmer         | Linear gradient sweep                                 | 1.5s loop|
| Stat ring fill           | `.easeOut(duration: 0.8)` on appear                   | 0.8s     |
| Toast entry              | `spring(response: 0.4, dampingFraction: 0.8)` + slide | ~0.4s    |
| Toast exit               | Opacity + slide up                                    | 0.25s    |
| Weight saved checkmark   | `.symbolEffect(.bounce)` on SF Symbol                 | system   |
| Tab bar active indicator | `spring(response: 0.3, dampingFraction: 0.75)`        | ~0.3s    |

## Micro-Interactions
- **Set completion**: When a weight input is filled, the set dot transitions from gray to green with a scale bounce (1.0 -> 1.3 -> 1.0, 0.3s spring).
- **Exercise card 100%**: When all sets complete, the completion ring fills to 100% with a `confettiEffect`-style particle burst (subtle, 0.5s). The card border briefly glows `semantic.success` (0.3s fade in, 1s hold, 0.5s fade out).
- **Meal checked off**: Circle checkbox fills with `.symbolEffect(.bounce)`, card gets a subtle green left border (3pt) with 0.2s transition.
- **Streak increment**: Flame icon does a scale bounce + brief `#FF6D00` glow ring.
- **Pull to refresh**: Custom lottie-style dumbbell animation (or SF Symbol `arrow.clockwise` with rotation).

## Loading Strategy
- ALWAYS use skeleton screens for content loading (cards, lists, stats).
- Use `ProgressView` spinner only for action confirmations (saving, uploading).
- Skeleton shapes should exactly mirror the layout of the content they replace.

---

# F. ICONOGRAPHY

## SF Symbol Standards
- **Weight**: Medium (default), Semibold (active/selected states)
- **Rendering**: Hierarchical rendering mode for multi-layer symbols
- **Size standard by context**:
  - Tab bar: 22pt
  - Navigation bar: 18pt
  - Card headers: 20pt
  - Inline labels: 14pt
  - Stat widgets: 24pt
  - Empty states: 40pt

## Filled vs Outlined
- **Filled**: Active tab icons, completed states, feature icons in cards
- **Outlined**: Inactive tabs, default states, navigation bar actions
- Transition between fill states: use `.symbolVariant(.fill)` or `.symbolEffect(.replace)`

## Key Icon Mapping
| Concept             | SF Symbol                          |
|---------------------|------------------------------------|
| Training            | `dumbbell.fill`                    |
| Diet                | `leaf.fill`                        |
| Progress            | `chart.line.uptrend.xyaxis`        |
| Profile             | `person.circle.fill`               |
| Rest day            | `moon.zzz.fill`                    |
| Streak              | `flame.fill`                       |
| Weight input        | `scalemass.fill`                   |
| Sets/reps           | `arrow.trianglehead.2.counterclockwise` |
| Timer/rest          | `timer`                            |
| Notes               | `text.bubble.fill`                 |
| Checkmark           | `checkmark.circle.fill`            |
| Add/create          | `plus`                             |
| Upload              | `arrow.up.doc.fill`                |
| Share               | `square.and.arrow.up`              |
| Settings            | `gearshape.fill`                   |
| Crown/PRO           | `crown.fill`                       |
| Calendar            | `calendar`                         |
| Clock               | `clock.fill`                       |
| Meal - Desayuno     | `cup.and.saucer.fill`              |
| Meal - Almuerzo     | `sun.max.fill`                     |
| Meal - Merienda     | `carrot.fill`                      |
| Meal - Cena         | `moon.stars.fill`                  |

---

# G. SCREEN-BY-SCREEN REDESIGN

---

## G1. Login / Register

### Concept: "Dark Entry"
A moody, confident entry point. No gradients — just clean type on a near-black background with the amber brand mark.

### Layout (top to bottom)
1. **Status bar area**: standard, light content
2. **Logo**: BulkUp logo mark, 80x80pt, centered. Below it: `display.md` "BulkUp" wordmark. Below that: `body.sm` tagline "Come, entrena, crece, repite." in `text.secondary`. Total header group centered vertically in top 40% of screen.
3. **Auth form**: positioned in lower 60%
   - Segmented control at top: "Iniciar Sesion" | "Crear Cuenta" — uses the D7 segmented control style, 40pt height, full width minus 40pt margins
   - Fields appear below with 16pt spacing:
     - Name field (register only): standard text field with person icon
     - Email field: standard text field with envelope icon
     - Password field: standard text field with lock icon, toggle eye button right-aligned inside
   - 16pt below fields: Primary Button "Iniciar Sesion" or "Crear Cuenta"
   - 12pt below: error message area (if applicable): `body.sm`, `semantic.error`, centered
4. **Divider**: HStack with thin line | "o" in `caption.lg` `text.tertiary` | thin line. 24pt vertical margin.
5. **Apple Sign In**: Native `SignInWithAppleButton`, black style, 52pt height, 14pt corner radius, full width.
6. **Background**: `surface.base` solid. Optional: very subtle radial gradient of `brand.primary` at 3% opacity emanating from behind the logo.

### Transitions
- Switching between login/register: fields animate in/out with `.transition(.move(edge: .top).combined(with: .opacity))` and 0.25s spring.

---

## G2. Onboarding

### Concept: "Quick Setup, High Impact"
4 screens. Minimal. Each screen has a single clear purpose. Progress bar at top. No clutter.

### Global Elements
- Progress bar: 3 capsule segments (screens 2-4), 4pt height, `brand.primary` fill, `surface.divider` track, 6pt spacing between segments. Positioned 8pt below safe area, 24pt horizontal margins.
- Background: `surface.base`
- Bottom CTA area: Primary Button, 20pt horizontal margins, 40pt from bottom safe area

### Screen 1 — Welcome
- Center vertically:
  - App logo: 120x120pt
  - 16pt gap
  - Title: `title.lg` "Bienvenido a BulkUp", `text.primary`, centered
  - 8pt gap
  - Subtitle: `body.md`, `text.secondary`, centered
  - 32pt gap
  - Value props: 3 rows, each with:
    - 40x40pt rounded square icon container (feature color at 12% bg, icon in feature color, 10pt radius)
    - 16pt gap
    - Text: `body.lg` `text.primary`
    - Row spacing: 16pt
- CTA: "Comenzar"

### Screen 2 — Goal Selection
- Title group: `title.md` "Cual es tu objetivo?", subtitle `body.md` `text.secondary`, centered, top 25% of content
- 3 goal cards below, 12pt spacing:
  - Each card: Interactive Card style
    - Left: 48x48pt icon container (rounded 12pt, `brand.primary` at 12% bg when unselected, `brand.primary` solid bg with white icon when selected)
    - Title: `headline`, `text.primary`
    - Subtitle: `body.sm`, `text.secondary`
    - Right: empty (unselected) or `checkmark.circle.fill` 24pt in `brand.primary` (selected)
    - Selected border: 2pt `brand.primary`
- CTA: "Continuar" (disabled until selection)

### Screen 3 — Basic Measurements
- Title group: same pattern
- 3 measurement inputs, 16pt spacing:
  - Each: HStack — icon (20pt, `text.secondary`) | TextField (numeric, `body.lg`) | unit label (`body.sm`, `text.tertiary`)
  - Wrapped in standard text field container
- CTA: "Guardar y continuar"
- Skip link below: Ghost Button "Omitir por ahora"

### Screen 4 — First Plan Upload
- Title group with subtitle explaining AI feature
- 2 Feature Cards (training + diet), 16pt spacing
  - Left icon: 48x48pt, feature color gradient background, white icon
  - Title + subtitle
  - Right chevron
- Skip link: "Explorar la app"

---

## G3. Main Tab Bar — New Structure

### Proposed 4-Tab Layout
Reducing from 6 tabs to 4. "Mis RM" becomes a section inside Progreso. "Ejercicios" becomes accessible from the Training hub (a search/discover section in the library tab).

| Position | Tab       | Icon                              | Destination                   |
|----------|-----------|-----------------------------------|-------------------------------|
| 1        | Entreno   | `dumbbell` / `dumbbell.fill`      | TrainingHubView               |
| 2        | Dieta     | `leaf` / `leaf.fill`              | DietHubView                   |
| 3        | Progreso  | `chart.line.uptrend.xyaxis`       | ProgressDashboardView (with RM)|
| 4        | Perfil    | `person.circle`/`person.circle.fill` | UserProfileView             |

### Tab Bar Visual Spec
- See D3 for full specs.
- The tab bar is a VStack:
  - 0.5pt top divider line
  - 56pt content area with 4 equally spaced tab items
  - Safe area bottom inset
- Background: `surface.raised` with ultra-thin material blur (allows content to peek through subtly)

---

## G4. Home / Dashboard (Training Tab — Active Plan)

### Concept: "Today's Mission"
The first thing users see is their workout for today. No browsing, no noise — just what they need to do RIGHT NOW.

### Layout (ScrollView, vertical)

#### A. Top Header Bar (not in scroll)
- Custom nav bar: Left = greeting "Hola, [Name]" in `headline` + today's date in `caption.lg` `text.secondary`. Right = notification bell icon button + profile avatar (32x32 circle, tappable).
- Below: Segmented control "Plan Activo" | "Mis Planes" (same as current hub pattern but using new D7 segmented style)

#### B. Today Summary Strip (inside scroll, first element)
- HStack, full width, `surface.overlay` background, 12pt corner radius, `card.paddingCompact` (12pt)
- 3 inline stats equally spaced:
  - Streak: flame icon + count, `feature.progress` color
  - Day: "Dia [X] de [Y]" or day name, `feature.training` color
  - Completion: percentage ring (44pt compact) showing today's progress
- Tapping this strip expands to show weekly overview (animated expand with D-style spring)

#### C. Day Navigation
- Horizontal date pill scroller:
  - 7 day pills for current week (Mon-Sun)
  - Each pill: 44x60pt, vertical layout: day abbreviation (`caption.sm`, `text.tertiary`) + date number (`body.md`, `text.primary`)
  - Today pill: `brand.primary` background, `text.inverse` text
  - Has-training pill: small 4pt dot below date in `feature.training`
  - Selected pill: `brand.primary` ring (2pt border), no fill
  - Rest day pill: `moon.zzz` tiny icon instead of dot
  - Horizontally scrollable, today initially centered

#### D. Workout Content
- If training day: list of ExerciseCards (see G6)
- If rest day: Rest Day Empty State
  - Icon: `moon.zzz.fill`, 48pt, `text.tertiary`
  - Title: "Dia de descanso", `title.sm`, `text.secondary`
  - Subtitle: "Recupera y vuelve mas fuerte", `body.sm`, `text.tertiary`
  - Centered vertically in remaining space

#### E. Workout Name Badge
- Above exercise list: pill tag showing workout name (e.g., "Pecho + Triceps")
- `caption.lg`, `feature.training` text on `feature.training` at 12% bg, pill shape

#### F. Bottom Safe Space
- 100pt bottom padding for tab bar clearance

---

## G5. Training Day View (Exercises List)

This IS the main content of G4 section D. The exercises list is the core of the app.

### Exercise List Layout
- VStack with `lg` (20pt) spacing between cards
- Each card is an ExerciseCardView (see G6)
- Cards are grouped — no section headers needed since they're all for one day
- Week navigation: Picker in toolbar "Semana [date range]" with left/right chevrons (keep current pattern but restyle)

### Week Selector
- Positioned as toolbar items (same functional pattern as current)
- Center: `headline` week label. Below: `caption.lg` date range in `text.secondary`
- Left/Right: Icon Buttons (compact, 32pt) with chevron.left / chevron.right

### View Mode Toggle
- Toolbar trailing: Menu picker "Diario" | "Semanal"
- Semanal view: collapsible day sections (accordion pattern, same as current but with new card styles)

---

## G6. Exercise Card — Redesigned

### Concept: "At-a-Glance Progress"
The most interacted-with component. Must be information-dense but scannable. Expandable for weight tracking.

### Collapsed State (Default)
Height: ~72pt. Full-width card (Elevated Card style).

Layout HStack:
1. **Completion Ring** (left, 44pt):
   - Track: 3pt `surface.divider`
   - Fill: 3pt, `feature.training` (in progress) or `semantic.success` (100%), lineCap round
   - Center content: `body.sm` Semibold "[completed]/[total]" or checkmark icon at 100%
   - Rotation: -90 degrees start

2. **Exercise Info** (center, flexible):
   - Name: `headline` (17pt Semibold), `text.primary`, 1 line truncated
   - Metadata row: HStack with `caption.lg` `text.secondary`:
     - Sets x Reps: "[sets] x [reps]" with `arrow.trianglehead.2.counterclockwise` icon
     - Rest: "[seconds]s" with `timer` icon (if > 0)
     - 12pt spacing between items

3. **Expand Toggle** (right, 32pt):
   - 32x32pt circle, `surface.overlay` background
   - `chevron.down` / `chevron.up`, 12pt, `text.tertiary`
   - Rotation animation: 180 degrees flip on expand

### Expanded State
Appears below the collapsed header via `.transition(.move(edge: .top).combined(with: .opacity))`.

Layout VStack with 16pt spacing:

1. **Divider**: 0.5pt, `surface.divider`, 16pt horizontal inset

2. **Exercise Notes** (if present):
   - `surface.overlay` background, 10pt corner radius, `card.paddingCompact`
   - `text.bubble.fill` icon + "Notas del ejercicio" label: `caption.lg`, `text.secondary`
   - Note text: `body.sm`, `text.primary`

3. **Weight Tracking Section** (if `weightTracking == true`):
   - Section header: "Registro de Peso" `headline` + completion percentage tag (Label Tag style)
   - **Set Grid**: horizontal scroll of set cards
     - Each set card: 100pt wide, `surface.overlay` background, 10pt corner radius, 8pt padding
       - Top: "Serie [n]" `caption.sm` with completion dot (6pt circle, green if has weight)
       - Previous weight reference: `caption.sm`, `semantic.info` color, clock icon + "[weight] kg"
       - Delta arrow if current weight exists (up green, down amber)
       - Weight input: Numeric Input style (D7), 48pt height, centered
       - "Usar" button if previous weight exists and current is empty: tiny ghost button, `semantic.info`
   - **Notes input**: TextEditor, 60pt height, `surface.overlay` background, 10pt corner radius, placeholder "Notas de hoy"
   - **Save button**: full width, 44pt height
     - Default: `feature.training` background, white text, "Guardar"
     - Saving: ProgressView spinner
     - Saved: `semantic.successBg` background, `semantic.success` text, checkmark + "Guardado"

---

## G7. Diet Day View — Redesigned

### Concept: "Checklist Clarity"
The diet view should feel like a satisfying checklist. Each meal is a clear task. Completion tracking is front and center.

### Layout

#### A. Compliance Summary Bar (sticky top)
- Full width, `surface.overlay` background, 10pt corner radius
- HStack: checkmark.circle.fill `semantic.success` | summary text `body.sm` `text.primary` | percentage `headline` colored (green >= 80%, amber >= 50%, `text.secondary` otherwise)
- 16pt horizontal margin, 10pt vertical padding

#### B. Meal Cards List
- VStack with `lg` (20pt) spacing
- Each card is a MealCardView (see G8)
- Day navigation: same horizontal date pill pattern as training (G4 section C)

#### C. Metrics Header (Collapsible)
- Keep existing pattern but restyle:
  - Collapsed: compact stat bar with weight, body fat %, compliance in `caption.lg` with colored labels
  - Expanded: full stat cards grid (2x2) with body stats
  - Toggle chevron, spring animation

---

## G8. Meal Card — Redesigned

### Concept: "Clean Rows with Completion Satisfaction"

### Layout (Elevated Card style)

#### Header Row (always visible)
HStack:
1. **Meal icon**: 40x40pt rounded square (12pt radius), meal-type color at 12% background, meal icon (see iconography table)
2. **Meal info** (center, flexible):
   - Meal type: `headline`, `text.primary` (e.g., "Desayuno")
   - Time + date: `caption.lg`, `text.secondary` with clock/calendar icons
3. **Completion toggle** (right):
   - If tracking enabled: 28pt `circle` (unchecked) or `checkmark.circle.fill` (checked), `semantic.success` when checked, `surface.divider` when unchecked
   - `.symbolEffect(.bounce)` on toggle
   - If no tracking: option count tag (Label Tag, `surface.overlay`)

#### Notes Callout (if meal has notes)
- `surface.overlay` background, 8pt corner radius
- `lightbulb.fill` yellow icon + note text `body.sm` `text.secondary`
- 8pt padding

#### Tracking Notes (if meal completed)
- `semantic.infoBg` background, 8pt corner radius
- `text.bubble.fill` `semantic.info` icon + text field
- 8pt padding

#### Meal Options
- Each option as an indented row:
  - 2pt left accent bar in meal color
  - Option title `body.md` `text.primary`
  - Ingredients list: `caption.lg` `text.secondary`, comma-separated or vertical list

#### Completed State
- Left border: 3pt `semantic.success`, full card height
- Card background: `semantic.successBg` at 50% opacity blended with `surface.raised`
- Subtle green tint throughout

---

## G9. Progress Dashboard — Redesigned

### Concept: "Your Numbers, Beautiful"
Data visualization done right. The progress screen is where users see the payoff of their consistency.

### Layout (ScrollView)

#### A. Hero Streak Card (top)
- Full width, gradient background: `#FF6D0015` -> `surface.raised`
- Center: flame icon 32pt + streak number `display.xl` (48pt) + "dias" `body.md` `text.secondary`
- Below: "Racha actual" `caption.lg` `text.secondary`
- Below: mini calendar heatmap showing last 30 days (5x6 grid of 8pt rounded squares)
  - Completed day: `semantic.success`
  - Missed day: `surface.divider`
  - Today: `brand.primary` ring
  - Future: `surface.overlay`

#### B. Weekly Summary Card
- 3-column stat grid using Stat Card style:
  - Entrenos completados: `feature.training` accent
  - Cumplimiento dieta: `feature.diet` accent
  - Racha actual: `feature.progress` accent
- Each with eyebrow label, stat number, delta tag

#### C. Training Progress Section
- Section header: "Progreso de Entrenamiento"
- Horizontal scrollable exercise progress cards:
  - Each card: 160pt wide, `surface.raised`, 16pt radius
  - Exercise name: `body.sm` Semibold, truncated to 1 line
  - Current weight: `display.md`, `text.primary`
  - Delta from last week: Label Tag with arrow
  - Mini sparkline (50pt tall, last 4 weeks): line in `feature.training`, no axes

#### D. Meal Compliance Section
- Section header: "Cumplimiento Nutricional"
- Weekly bar chart: 7 bars (Mon-Sun), max height 80pt
  - Bar fill: `feature.diet` (completed %)
  - Day label below: `caption.xs`, day abbreviation
  - Target line: dashed horizontal at 80% in `text.tertiary`

#### E. Body Stats (Premium)
- Section header with PRO badge
- 2x2 grid of Stat Cards:
  - Peso | Grasa corporal | Masa muscular | IMC
- Below: weight trend line chart (last 12 entries), 160pt tall
  - Line: `feature.progress`, 2pt stroke
  - Fill below line: `feature.progress` at 10% opacity
  - Y-axis labels: `caption.sm`
  - X-axis: `caption.xs` date labels

#### F. Personal Records (Premium — formerly "Mis RM" tab)
- Section header "Records Personales"
- List of PR cards:
  - Exercise name: `headline`
  - Current 1RM: `display.md`, `text.primary`
  - Date achieved: `caption.lg`, `text.secondary`
  - Improvement badge: Label Tag with delta

#### G. Friends Leaderboard (Premium)
- Section header "Amigos" with add friend icon button
- Leaderboard rows:
  - Rank number: `display.md` Rounded, `text.tertiary`
  - Avatar: 36pt circle
  - Name: `body.lg`
  - Streak: flame icon + count, `brand.primary`

---

## G10. Profile — Redesigned

### Concept: "Clean Identity"
A settings-oriented screen that also shows user stats at a glance.

### Layout (ScrollView)

#### A. Profile Header
- Center-aligned VStack:
  - Avatar: 96pt circle, with 3pt `brand.primary` ring (2pt gap), tap to edit overlay (camera icon, 24pt, `surface.overlay` circle at bottom-right)
  - Name: `title.md`, `text.primary`
  - Email: `body.sm`, `text.secondary`
  - Subscription badge: PRO (gradient.premiumBadge background, crown icon, "PRO" in white `caption.xs` CAPS) or "Plan Basico" (ghost style, `text.tertiary`)

#### B. Quick Stats Row
- HStack of 3 mini stat widgets, full width:
  - Planes activos: count + icon
  - Dias de racha: streak + flame
  - Dias registrados: total + calendar
- `surface.raised` background card, 16pt radius

#### C. Menu Sections
Grouped lists using Standard Row (D9) style with section headers:

**Cuenta**
- Editar perfil (person.fill)
- Medidas corporales (ruler.fill)
- Notificaciones (bell.fill)

**App**
- Ajustes (gearshape.fill)
- Exportar datos (square.and.arrow.up.fill)
- Compartir app (heart.fill)

**Suscripcion**
- If free: "Desbloquear PRO" card — special Feature Card with `gradient.premiumBadge` left accent, crown icon, compelling subtitle. Tappable -> subscription sheet.
- If PRO: "Plan PRO Activo" with green checkmark and manage link

**Legal**
- Terminos y Condiciones
- Politica de Privacidad

**Peligro**
- Cerrar sesion: `semantic.error` text
- Eliminar cuenta: `semantic.error` text, confirms with alert

#### D. App Version
- Centered, `caption.sm`, `text.tertiary`: "BulkUp v[X.Y.Z]"

---

## G11. Subscription / Paywall

### Concept: "Unlock Your Full Potential"
A compelling, non-aggressive paywall that showcases value.

### Layout (Full-screen sheet)

#### A. Close button
- Top-right: 32pt X icon button, `text.tertiary`

#### B. Hero Section
- Crown icon: 48pt, `gradient.premiumBadge` color
- Title: `title.lg` "Desbloquea todo tu potencial", `text.primary`, centered
- Subtitle: `body.md` `text.secondary`, centered

#### C. Feature List
- VStack of benefit rows (5-6 items), 16pt spacing:
  - Each row: HStack
    - `checkmark.circle.fill` 20pt in `brand.primary`
    - Feature text `body.lg` `text.primary`
  - Examples: "Medidas corporales y graficos", "Records personales (1RM)", "Tabla de amigos", "Planes ilimitados", "Exportar datos"

#### D. Plan Selector
- 2 plan cards side by side (HStack, 12pt gap):
  - Each: `surface.raised` background, 16pt radius, `card.padding`
    - Plan name: `headline`
    - Price: `display.md`
    - Period: `caption.lg` `text.secondary`
    - Selected: `brand.primary` 2pt border + checkmark badge
    - "Mejor valor" tag on annual plan: Label Tag, `semantic.success`

#### E. Subscribe CTA
- Primary Button "Suscribirse" with price included
- Below: `caption.lg` `text.tertiary` legal text (auto-renewal, etc.)
- Below: "Restaurar compra" Ghost Button

---

# H. IMPLEMENTATION NOTES FOR DEVELOPER

## Color Implementation
Create a `DesignTokens.swift` file with a `BulkUpTheme` enum containing static color properties. Use `Color(uiColor:)` with `UIColor { traitCollection in }` closures to support dynamic light/dark switching. Define all colors as named colors in the asset catalog OR as code constants.

## Typography Implementation
Create extension on `Font` with static properties: `.bulkDisplayXL`, `.bulkTitleLG`, `.bulkHeadline`, `.bulkBodyMD`, `.bulkCaptionSM`, etc. Each returns the appropriate `Font.system(size:weight:design:)` call.

## Spacing Implementation
Create a `Spacing` enum with static CGFloat properties: `.xs`, `.sm`, `.md`, `.base`, `.lg`, `.xl`, `.xxl`.

## ViewModifier Refactor
Replace existing `CardStyle`, `FlatCardStyle`, `PrimaryButtonModifier` with new modifiers:
- `.elevatedCard()` — new elevated card
- `.interactiveCard()` — with press animation
- `.statCard(accentColor:)` — with left accent bar
- `.primaryButton()` — new amber gradient button
- `.secondaryButton()` — outlined style
- `.ghostButton()` — transparent
- `.numericInput(isCompleted:)` — weight tracking field

## Migration Strategy
1. Implement `DesignTokens.swift` with all colors, fonts, spacing
2. Refactor `ViewModifiers.swift` with new component modifiers
3. Build new custom `BulkUpTabBar` component (replacing system TabView)
4. Update screens one at a time, starting with Login -> Onboarding -> TabBar -> Training -> Diet -> Progress -> Profile
5. Each screen update should be a separate PR for reviewability

---

END OF DESIGN SYSTEM SPECIFICATION
