# BulkUp Landing — Design System

> Adapted from Spotify's design language (dark-first, art-forward, one vivid
> accent, energetic-but-systematic) and fused with BulkUp's own brand pulled
> from the iOS app (`DesignSystem.swift`). Spotify was chosen over Linear
> (too enterprise/console) and Nike (light, photography-led) because BulkUp is
> a **consumer** product that should feel immersive and energetic, carried by a
> single bright accent on layered near-black surfaces — exactly Spotify's model.

---

## 1. Theme & Atmosphere

**Aesthetic:** a cinematic, dark-first fitness product. Imagery and motion create
the emotional layer; metadata and controls stay compact and systematic. Immersive
without chaos.

**Mood:** athletic · confident · energetic · premium · calm-under-density.

**Character:**
- Near-black layered surfaces; depth from surface *stepping*, not heavy borders.
- One bright **teal/mint** accent driving the entire action hierarchy.
- Bold display titles that hold against dark backgrounds; compact, legible metadata.
- Small-to-medium radii on controls; larger radii on feature/media cards.
- Art-led cards and horizontally-scrolling shelves (showcase, screenshots).

---

## 2. Color — BulkUp brand on Spotify's structure

Mirrors the iOS app's `BulkUpColors` (dark palette).

| Token | Hex | Role |
|---|---|---|
| `--color-bg` | `#0A0A0A` | Base background (deepest) |
| `--color-surface` | `#161616` | Elevated panels / cards |
| `--color-surface-2` | `#1E1E1E` | Higher elevation / hover step |
| `--color-line` | `rgba(255,255,255,.09)` | Quiet dividers / card borders |
| `--color-fg` | `#FFFFFF` | Primary headings & key copy |
| `--color-muted` | `#8E8E93` | Secondary/meta copy |
| `--color-accent` | `#00E6C3` | **Brand teal — primary action hierarchy** |
| `--color-accent-glow` | `#00FFD5` | Gradient highlight (CTA, glow) |
| `--color-accent-2` | `#7B61FF` | Electric violet — *sparingly* (ambient only) |

**Accent discipline (Spotify rule):** teal owns every primary action. Violet is
ambient-only (aurora second light) and never used for buttons, links, or focus.
Don't introduce additional neon accents. Semantic colors borrow the app's:
success `#30D158`, error `#FF453A`.

CTA fill = the app's `accentGradient`: `linear-gradient(95deg, #00E6C3, #00FFD5)`,
black text (`onAccent`).

---

## 3. Typography

Compact, bold, scanable. Titles must hold against dark surfaces; metadata stays light.

- **Display family:** `--font-display` (Clash Display / Arial Black fallback) for hero & section titles, weight 900, **letter-spacing `-0.02em`**, line-height ~1.0–1.1.
- **Text family:** `--font-sans` (Inter / system) for body & UI.

| Element | Size | Weight | Tracking |
|---|---|---|---|
| Hero display | clamp ~3rem→5rem | 900 | -0.02em |
| Section title | 2.25–3rem | 900 | -0.02em |
| Card title | 1.25rem | 600 | 0 |
| Body large | 1.125rem | 400 | 0 |
| Body / meta | 0.875–1rem | 400 | 0 |
| Eyebrow/label | 0.75rem | 700 | 0.2em, uppercase |

---

## 4. Components

**Primary button (CTA)** — pill, teal gradient, black text:
- `border-radius: 999px`, generous padding, min-height ~48px.
- Hover: `transform: scale(1.02)` + accent glow shadow. Active: `scale(0.97)`.
- Transition `transform 100–160ms var(--ease-out)`. Light-sweep sheen on hover.

**Secondary / ghost** — transparent, `1px solid rgba(255,255,255,.3)` pill;
hover border → white, bg `rgba(255,255,255,.08)`.

**Feature / media card** — `--color-surface`, radius 16–20px, padding ~28px.
Hover (Spotify signature): **surface steps up** to `--color-surface-2` + subtle
lift + cursor spotlight + accent-tinted border. Depth from the step, not a big shadow.

**Input** — pill on `--color-surface`, `--color-line` border, focus border → accent.

---

## 5. Layout

- Sections separated by **surface stepping** (alternate base ↔ subtle surface tint)
  rather than hard rules. One faint hairline only where it adds rhythm.
- **Shelves/rails:** screenshots and showcase scroll horizontally; never crush cards.
- Bento grid for features; wide tiles for the headline features (training, social).
- Whitespace is "efficient and musical" — roomy for imagery, tight enough to keep
  discovery moving. Max content width ~72rem, comfortable side padding.

---

## 6. Depth & Motion

- **Depth:** black→charcoal surface stepping + soft scrims; reserve real shadow
  (`0 16px 24px rgba(0,0,0,.3)`) for the floating phone and overlays.
- **Motion (energetic, never sluggish):** strong custom easing
  `--ease-out: cubic-bezier(0.16,1,0.3,1)`; entrances ease-out, transforms/opacity
  only. Ambient aurora drift, word-by-word hero reveal, spring 3D phone tilt,
  cursor spotlight, scroll progress, count-up. All gated behind
  `prefers-reduced-motion` and degrade to a static, full-usable page.

---

## 7. Do / Don't

**Do** — stay dark-first and art-forward · let teal own the action hierarchy ·
separate sections with surface stepping · bold white titles + muted-gray meta ·
keep controls pill/compact and motion energetic.

**Don't** — brighten into a generic light SaaS look · flatten the charcoal
hierarchy into one gray · use any neon beyond teal (violet is ambient-only) ·
let gradients/art overwhelm text legibility · make spacing so loose discovery slows.

---

## 8. Pre-launch asset notes

Art carries the emotional layer here — replace the placeholder phone/screens in
`HeroVisual` and `Showcase` with real app captures, and the solid `og-default.png`
with branded art, to realize this system fully. Swap the display webfont
(`--font-display` is a system fallback today).
