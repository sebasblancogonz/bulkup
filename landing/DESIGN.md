---
name: BulkUp
description: Premium fitness brand system — graphite discipline, electric-lime proof of progress.
colors:
  graphite-bg: "#0E1110"
  surface: "#15191A"
  surface-2: "#1D2224"
  line: "#2A3033"
  bone-white: "#F2F4F1"
  muted: "#9BA39E"
  electric-lime: "#B4FF2E"
  lime-deep: "#93D414"
  sky-complete: "#00A9DD"
  amber-error: "#F59E0B"
typography:
  display:
    fontFamily: "Saira Condensed, Arial Narrow, system-ui, sans-serif"
    fontSize: "clamp(3rem, 7vw, 5.5rem)"
    fontWeight: 800
    lineHeight: 0.95
    letterSpacing: "-0.03em"
  headline:
    fontFamily: "Saira Condensed, Arial Narrow, system-ui, sans-serif"
    fontSize: "clamp(2rem, 4vw, 3.25rem)"
    fontWeight: 700
    lineHeight: 1.02
    letterSpacing: "-0.02em"
  body:
    fontFamily: "Hanken Grotesk, Inter, ui-sans-serif, system-ui, sans-serif"
    fontSize: "clamp(17px, 1.1vw, 19px)"
    fontWeight: 400
    lineHeight: 1.6
    letterSpacing: "normal"
  label:
    fontFamily: "Saira Condensed, Arial Narrow, sans-serif"
    fontSize: "13px"
    fontWeight: 600
    lineHeight: 1.2
    letterSpacing: "0.2em"
  mono:
    fontFamily: "JetBrains Mono, ui-monospace, monospace"
    fontSize: "1rem"
    fontWeight: 500
    lineHeight: 1.3
    letterSpacing: "normal"
rounded:
  card: "14px"
  btn: "10px"
  chip: "999px"
  phone: "38px"
spacing:
  section: "clamp(96px, 14vh, 180px)"
  container: "1200px"
components:
  button-primary:
    backgroundColor: "{colors.electric-lime}"
    textColor: "{colors.graphite-bg}"
    typography: "{typography.label}"
    rounded: "{rounded.btn}"
    padding: "14px 28px"
  button-primary-hover:
    backgroundColor: "{colors.lime-deep}"
    textColor: "{colors.graphite-bg}"
    rounded: "{rounded.btn}"
  input-email:
    backgroundColor: "{colors.surface-2}"
    textColor: "{colors.bone-white}"
    rounded: "{rounded.btn}"
    padding: "14px 20px"
  card:
    backgroundColor: "{colors.surface}"
    textColor: "{colors.bone-white}"
    rounded: "{rounded.card}"
    padding: "20px"
  eyebrow:
    textColor: "{colors.electric-lime}"
    typography: "{typography.label}"
---

# Design System: BulkUp

## 1. Overview

**Creative North Star: "Graphite & Voltage"**

A pre-dawn weight room: matte graphite, dropped barbells, one strip of electric light. The system is built on disciplined darkness — near-black graphite surfaces (`#0E1110`, never pure black) that carry weight and seriousness — punctuated by a single charge of electric lime (`#B4FF2E`) that fires only where progress is being made: a CTA, a logged number, the active line on a chart. Graphite is the eight-years-of-training discipline; lime is the spark of seeing you actually moved the bar. The two never blur together.

The typography is built like equipment: Saira Condensed, set uppercase with tight tracking, stacks like loaded plates — narrow, dense, structural. Body copy is Hanken Grotesk (a clean grotesque, deliberately not rounded; Inter as fallback), and every datapoint — kilos, %, PRs, streaks — is set in JetBrains Mono so the numbers read as evidence, not decoration. Surfaces have real depth: a subtle graphite gradient rather than a flat fill, fine film grain at 3–5%, and genuine shadows under device mockups so the app floats off the page instead of lying on it.

This system explicitly rejects the four things its audience can smell instantly: **generic SaaS / tech-startup** chrome (corporate voice, hero-metric templates, an eyebrow on every section); the **soft consumer app** it came from (white backgrounds, rounded display type, the universal 26px radius, flat and shadowless — the "Foodnoms-light" look); **loud supplement bro-marketing** (screaming neon, hype, poster clichés); and the **cold corporate dashboard** (gray-on-gray KPIs with no soul). It is athletic, not clinical; premium, not precious; energetic, not loud.

**Key Characteristics:**
- Graphite-dark canvas with a single electric-lime accent used as a razor (≤10% of any screen).
- Condensed uppercase display type (Saira) + neutral grotesque body (Hanken Grotesk) + mono for all data (JetBrains Mono).
- Real depth: graphite gradient, film grain, genuine shadows, lime glow — never flat-shadowless.
- Hierarchised radii (14 / 10 / 999 / 38px), not one friendly universal radius.
- Numbers are the hero. Data is set as evidence, in mono, often in lime.

## 2. Colors

A disciplined graphite ground with one electric accent; everything earns its place by role, not decoration.

### Primary
- **Electric Lime** (`#B4FF2E`): the single voltage of the brand. Used ONLY where progress or action lives — the primary CTA fill, the active chart line, key metrics in mono, the eyebrow labels, focus rings, the one highlighted word in a headline. On graphite it burns; that brightness is the whole point.
- **Lime Deep** (`#93D414`): hover/pressed state of the lime CTA and the end stop of any lime gradient. Never a resting fill on its own.

### Tertiary
- **Sky Complete** (`#00A9DD`): a single, narrow job — the "registered / completed" state inside progress charts and rings, so lime never has to compete with itself for two different meanings. Not a general accent.

### Neutral
- **Graphite BG** (`#0E1110`): the page canvas. Near-black, never pure `#000` (pure black reads cheap). Rendered as a subtle radial gradient (`#171C1D` → bg), not a flat fill.
- **Surface** (`#15191A`): cards, alternating section bands.
- **Surface 2** (`#1D2224`): elevated cards, input fields, hover surfaces.
- **Line** (`#2A3033`): 1px hairlines, borders, dividers. The structural grammar between blocks (Whoop/Linear language).
- **Bone White** (`#F2F4F1`): primary text. Never pure `#fff`.
- **Muted** (`#9BA39E`): secondary text and captions. ~7:1 on graphite — readable, not decorative-gray.

### Functional
- **Amber Error** (`#F59E0B`): the ONLY error color. Lime is success; errors must never be lime.

### Named Rules
**The Razor Rule.** Electric lime covers ≤10% of any given surface. One word of a headline, the primary CTA, the live metrics, one chart line, the focus ring. Paint a whole block lime and it reads as a supermarket protein bag. Its rarity is the voltage.

**The Two-Greens Rule.** Lime means *action / progress*. Sky means *done / logged*. They never swap roles, and lime is never used to mean "completed."

## 3. Typography

**Display Font:** Saira Condensed (with Arial Narrow, system-ui fallback)
**Body Font:** Hanken Grotesk (with Inter, ui-sans-serif, system-ui fallback)
**Label / Mono Font:** JetBrains Mono (with ui-monospace fallback)

**Character:** Condensed-uppercase display stacked like loaded plates against a neutral, unfussy grotesque body — a contrast pairing (condensed vs. normal-width, structural vs. neutral), never two similar sans. The mono is reserved entirely for data, so numbers always read as evidence.

### Hierarchy
- **Display / H1** (800, `clamp(3rem, 7vw, 5.5rem)`, line-height 0.95, tracking -0.03em, UPPERCASE): hero and closing headlines. Tight, dense, shouting only by scale.
- **Headline / H2** (700, `clamp(2rem, 4vw, 3.25rem)`, line-height 1.02, tracking -0.02em, UPPERCASE): section titles.
- **Title / H3** (600, tracking -0.01em, UPPERCASE): subsection / card titles.
- **Body** (400, `clamp(17px, 1.1vw, 19px)`, line-height 1.6, Hanken Grotesk): paragraphs and feature copy. Cap measure at 65–75ch.
- **Label / Eyebrow** (600, 13px, tracking 0.2em, UPPERCASE, lime, Saira): the short kicker `ENTRENA. REGISTRA. PROGRESA.` and section labels. Reserved for ≤4 words.
- **Data / Mono** (500, JetBrains Mono, `tnum`): every kilo, %, PR, streak, price, datapoint — frequently in lime.

### Named Rules
**The No-Pillow Rule.** Display type is condensed and uppercase. Rounded, friendly, geometric faces (Nunito and family) are forbidden in this system — a rounded headline on a fitness brand is wearing slippers to the gym.

**The Numbers-Are-Mono Rule.** Any datapoint a user could read as proof (weight, %, max, streak, count, price) is set in JetBrains Mono, never the body font. Mono is what makes a number feel measured.

## 4. Elevation

This system has real depth and uses it deliberately — the opposite of the flat, shadowless surface it replaced. Depth is built from four materials: a subtle graphite radial gradient on the body (so the canvas is never a uniform fill), 3–5% film grain over surfaces (`mix-blend-mode: overlay`), genuine shadows under device mockups, and a soft lime radial glow behind the hero device. Hairlines (`1px #2A3033`) do the quiet structural separation between blocks. Cards sit flat at rest and lift on hover.

### Shadow Vocabulary
- **Card** (`box-shadow: 0 20px 60px rgba(0,0,0,0.5)`): under phone/device mockups so the app floats off the page.
- **Lift** (`box-shadow: 0 24px 70px rgba(0,0,0,0.55)`): the hover state of an interactive card, paired with `translateY(-4px)` and a lime-tinted border.
- **Glow** (`radial-gradient(closest-side, rgba(180,255,46,0.18), transparent 70%)`): the breathing lime halo behind the hero mockup — light, not a drop shadow.

### Named Rules
**The Earned-Shadow Rule.** Shadows are heavy and intentional under mockups and on hover; they are not sprinkled on every card at rest. Surfaces are separated by hairlines and tone first, shadow second.

**The Never-Flat Rule.** The canvas is always a graphite gradient with grain, never a uniform fill. If a section looks like a flat swatch of one color, it's unfinished.

## 5. Components

### Buttons
- **Shape:** soft-square, `border-radius: 10px` (`--radius-btn`). Never a pill — a pill CTA reads consumer-app; the squared corner reads equipment.
- **Primary:** electric-lime fill (`#B4FF2E`) with graphite text (`#0E1110`, never light text on lime — that's an AA failure), Saira uppercase, wide tracking, `padding: ~14px 28px`. Carries the `.press` (scale feedback) and `.sweep` (a single diagonal shine on hover).
- **Hover / Focus:** background shifts to Lime Deep (`#93D414`); focus-visible draws a 2px lime outline at 2px offset.
- **Label:** verb-first, no "waitlist" in the button text — "Quiero probarlo" (hero), "Dame acceso" (close), "Entrar" (nav). The waitlist idea lives in the subtext, never on the button.

### Cards / Containers
- **Corner Style:** `border-radius: 14px` (`--radius-card`).
- **Background:** Surface (`#15191A`); elevated/hover use Surface 2 (`#1D2224`).
- **Border:** a single `1px #2A3033` hairline (`.hairline`) — full border, never a side-stripe accent.
- **Shadow Strategy:** flat at rest; on hover `.lift` (translateY(-4px) + heavier shadow + lime-tinted border). See Elevation.
- **Internal Padding:** ~20px.

### Inputs / Fields
- **Style:** Surface 2 fill (`#1D2224`), `1px #2A3033` border, `border-radius: 10px`, generous `padding: ~14px 20px`, bone-white text, muted placeholder.
- **Focus:** border shifts to electric lime; no glow, just a clean lime edge.
- **States:** success message in lime; error / invalid message in **Amber** (`#F59E0B`) — never lime. A muted reassurance line ("Sin spam. Solo el aviso de lanzamiento.") sits under the field.

### Navigation
- **Style:** sticky header on a translucent graphite (`#0E1110` ~85%) with backdrop-blur and a bottom hairline.
- **Links:** Hanken Grotesk, bone-white, hover to lime. Kept minimal (Funciones, FAQ) — no "Pricing" in the nav on a waitlist page.
- **CTA:** the lime primary button (see Buttons).

### Signature: Device Mockup & Photo Placeholder
- **Mockup (`.phone`):** `border-radius: 38px` (real iPhone radius), `1px` line border, Surface 2 fill, the Card shadow, often over a breathing lime `.glow`.
- **Photo placeholder:** where real gym photography is pending, a deliberate graphite block — radial gradient (`#1D2224` → `#15191A` → `#0E1110`) + `.grain` + faint lime glow, marked `role="img"` with an `aria-label`. Premium and intentional, never a broken alt-box. (Real gym/effort photography replaces these.)

### Data Strip
- A row of mono proof points (`1.000+ ejercicios · fórmulas de 1RM reales · iOS + Apple Watch`), separated by hairlines, numbers in lime. Honest proof, never invented logos or fake counters.

## 6. Do's and Don'ts

### Do:
- **Do** keep the canvas graphite (`#0E1110`) with the radial gradient + grain. Never a flat fill, never pure black.
- **Do** ration electric lime to ≤10% of any screen (the Razor Rule): one headline word, the CTA, live metrics, one chart line, the focus ring.
- **Do** set every datapoint (kilos, %, PR, streak, price) in JetBrains Mono, frequently in lime — numbers are the proof.
- **Do** set headlines in Saira Condensed uppercase with tight tracking; pair with Hanken Grotesk body and nothing rounder.
- **Do** put graphite text (`#0E1110`) on any lime fill, and amber (`#F59E0B`) on errors.
- **Do** use real shadows under mockups and `.lift` on hover; separate blocks with `1px #2A3033` hairlines.
- **Do** write CTAs as verbs ("Quiero probarlo", "Dame acceso"); keep "waitlist / acceso anticipado" out of the button and in the subtext.

### Don't:
- **Don't** ship the **soft consumer-app (Foodnoms-light)** look: no white/`#fff` backgrounds, no rounded display type (Nunito and family), no universal 26px radius, no flat-shadowless surfaces. That is exactly the system this brand left.
- **Don't** drift into **generic SaaS / tech-startup** chrome: no hero-metric template, no tiny uppercase eyebrow above *every* section, no corporate voice, no "Pricing" teaser planted before a free-email CTA.
- **Don't** go **loud supplement bro-marketing**: no screaming full-bleed neon, no hype, no poster clichés ("transforma tu vida", "siguiente nivel", "potenciar").
- **Don't** become a **cold corporate dashboard**: no soulless gray-on-gray KPI tables; data still has to feel like an athlete's evidence.
- **Don't** paint whole blocks lime, use a pill on the primary CTA, put light text on a lime fill, color an error lime, or fabricate a social-proof number (no hardcoded counts — real scarcity instead).
- **Don't** use a colored `border-left`/`border-right` stripe as an accent, gradient-clipped text, or decorative glassmorphism.
