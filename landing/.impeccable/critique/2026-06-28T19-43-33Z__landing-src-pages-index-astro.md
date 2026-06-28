---
target: landing
total_score: 32
p0_count: 1
p1_count: 1
timestamp: 2026-06-28T19-43-33Z
slug: landing-src-pages-index-astro
---
# Critique — BulkUp Waitlist Landing ("Graphite & Voltage")

Source-based review (browser automation unavailable in this env; judged from code + tokens). Conversion goal: waitlist email capture.

## Design Health Score

| # | Heuristic | Score | Key issue |
|---|-----------|-------|-----------|
| 1 | Visibility of System Status | 3 | Form has all states, but loading is a quiet `…` for the page's one conversion action — no "Enviando…"/spinner. |
| 2 | Match System / Real World | 4 | Best-in-class: kilos, series, PRs, racha, "PDF muerto en Descargas". Speaks the lifter's language. |
| 3 | User Control & Freedom | 3 | Smooth anchors, native `<details>`, persistent lang switch. Success replaces the whole form, no "use another email". |
| 4 | Consistency & Standards | 3 | Tokens rigorous, but `.eyebrow` implemented 3 ways (class vs hand-rolled spans). |
| 5 | Error Prevention | 3 | Regex + honeypot + server rate-limit. Native+custom email messages can double-fire. |
| 6 | Recognition over Recall | 4 | Everything visible; linear narrative; nothing to memorize. |
| 7 | Flexibility & Efficiency | 3 | Lime focus rings; but no `autocomplete="email"`/`inputmode` for the mobile-first context. |
| 8 | Aesthetic & Minimalist | 3 | Premium and restrained on color, but eyebrow-everywhere + 4 placeholder blocks add weight that pays nothing. |
| 9 | Error Recovery | 3 | Amber errors (correct), `role=alert` — but generic ("Algo salió mal"); no 429-vs-500 distinction (rate-limited user retries into the same wall). |
| 10 | Help & Documentation | 3 | FAQ strong + honest + JSON-LD; only 4 Qs, nothing on data/privacy for an email-capture form. |
| **Total** | | **32/40** | **Good — ships, not yet Impeccable.** The form (the page's one job) is the weakest cluster. |

## Anti-Patterns Verdict

**Does this look AI-generated? First-order: mostly no — a real achievement.** Committed graphite palette (never #000), hierarchised radii (38/14/10/999, kills the universal-radius tell), lime rationed as accent, amber-only errors, real depth (gradient+grain+earned shadow). Copy is the strongest anti-slop signal ("El espejo miente; los números no", "a ver quién falla primero. Spoiler: tú no") — written by someone with a voice. No banned clichés.

**Second-order tells cluster, and they're real:**
1. Eyebrow on ~8/9 sections (3 recycled) — the page reproduces the one anti-pattern its own DESIGN.md bans.
2. Graphite-dark + electric-lime athletic is the saturated "premium fitness that isn't bright" lane (Whoop/Gymshark-dark). Sanctioned by the brief, but nothing yet escapes the lane except one chart detail (the sky-dot).
3. Inter body font is on the brand reflex-reject list (the single most AI-defaulted body sans).

**Deterministic scan (detector):** effectively clean — 1 finding, a **false positive** (`broken-image` at `Diet.astro:55` matched the literal text "`<img>`" inside a TODO *comment*, not a real tag; the element there is a deliberate `aria-hidden` `.grain` placeholder). Notably, the detector's false positive points at the same place as the #1 real issue: the placeholder imagery.

**Visual overlays:** not available — browser automation isn't present in this environment, so no in-page overlay was injected. Findings are source-based.

## Overall Impression

This is a genuinely premium, disciplined dark-athletic landing that clears the AI baseline on craft and voice. The single biggest opportunity is **real photography**: the brand's #1 principle is "show the body, not just the screen," and the page currently ships only screens + four graphite placeholder blocks. The second is **restraint** — strip the eyebrow-everywhere scaffolding and tighten the form (its one job), and this jumps from "competent dark-fitness template" to "distinctly BulkUp."

## What's Working

1. **The data layer is the brand's honest core, executed with craft.** The ProgressWatch SVG chart (real weight series 82.4→79.2, drawn on scroll, mono `tnum`, and the sky-dot for "logged today" vs lime for "progress") is a defensible idea no template ships. Make it louder — it's the one move a competitor couldn't screenshot by Friday.
2. **Token discipline that defeats the tells by construction** (radii, never-pure-black/white, lime as razor, amber-only errors, real depth).
3. **Copy that sounds like a person who lifts** — and honest scarcity ("plazas de fundador") instead of a fake "Join 12,000 athletes" counter. The no-fake-metric principle is mostly honored; the skeptic feels it.

## Priority Issues

**[P0] No real body / gym / effort / food imagery — four placeholder blocks where the brand's #1 principle demands photography.**
- *Where:* Hero bg (`Hero.astro:19`), Training (`Training.astro:23`), Diet meal-prep (`Diet.astro:57`), Community (`Community.astro:60`) — `.grain` gradient rectangles marked `TODO foto`. (Phone mockups DO use real app screenshots; the *body* half is missing.)
- *Why:* The thesis is "earn the athletic feeling with real effort imagery *before* the UI." Zero humans/sweat/iron/food hands the skeptic persona his "vaporware/template" verdict before the honest chart+copy can win him.
- *Fix:* Source 4 real photos to the TODO art-direction already written in the comments (sweaty hand on phone in a bokeh gym; loaded barbell + chalk; overhead meal-prep on matte graphite; post-set fist bump). One strong stock effort photo in the Hero already beats the block. → **`colorize`** then **`polish`**.

**[P1] Eyebrow on every section (8/9, one doubled, 3 recycled) — violates the brand's own ban.**
- *Why:* DESIGN.md explicitly rejects "a tiny uppercase eyebrow above every section"; reusing `hero.eyebrow` ×3 and `data.platform` as both a fact and a kicker reads automated.
- *Fix:* Keep the kicker on ≤2 places (the Hero mantra; maybe FAQ). Strip from Training/Diet/Community/ProgressWatch/FinalCta — let the Saira headline carry the section. → **`distill`** then **`quieter`**.

**[P2] The conversion form is the weakest UX cluster.**
- *What:* Loading = `…` only; errors don't distinguish 429 vs 500; the **closing FinalCta form drops the `reassure` prop** (FinalCta:38–47) so it loses the spam-safety line the hero form has — pressure kept, safety removed, exactly at peak commitment.
- *Fix:* "Enviando…" + disabled; map 429→"Demasiados intentos, espera"; add `reassure={t('hero.reassure')}` to FinalCta; add `autocomplete="email"` `inputmode="email"`. → **`harden`** then **`onboard`** (the success moment).

**[P3] Residual "spec-built, not authored" texture: Inter body + em-dash density + repeated aphorism rhythm.**
- *What:* Inter (reflex AI body sans); 5+ em dashes incl. a malformed Spanish bracketing in `faq.a1` ("tu entrenador —en PDF o foto—" glued); the "statement; short rebuttal" move repeated 4–5×.
- *Fix:* Swap Inter for a body grotesque with more character (keep the contrast-pairing logic); space the raya / use parentheses; thin the aphorism rhythm to 2–3 hero lines. → **`typeset`** then **`clarify`**.

## Persona Red Flags

- **Jordan (first-timer):** value lands fast, but dense paragraphs + 8 kickers blur "the point"; the silent `…` after submit gives no confidence the click worked.
- **Riley (stress-tester):** 429 → "Algo salió mal. Inténtalo de nuevo" → retries into the same wall; clocks `data.platform` doing double duty as machine output.
- **Casey (distracted mobile — the PRIMARY context):** long paragraphs, 4 decorative blocks loading weight for nothing, glows+sweep+ping competing, no `inputmode="email"`, DataStrip facts may hide off-edge under the scroll mask.
- **Mateo (the burned lifter who's tried 5 apps — make-or-break):** wins on honest scarcity, real screenshots, the "does it really read my PDF" FAQ; **loses** on the four "(foto pendiente)" blocks (exactly what his fakery-radar hunts) and the seen-it-before lime-on-graphite lane — the honest proof (chart, copy) arrives only after he scrolls past the placeholders.

## Minor Observations

- **Invented datapoints in a brand that bans fake metrics:** ProgressWatch hardcodes `142 bpm` and a 72% activity ring as decoration (`ProgressWatch.astro:140,186`) — fake numbers presented as evidence. Either real-data them or visibly mark as illustrative.
- Community reuses `/home.png` as its mockup (`Community.astro:81`) but the section is about check-in/crew — the screen doesn't show the claim.
- `home.png` is 1.7 MB + `loading="eager"` in the Hero (`Hero.astro:75`) — LCP risk for the mobile-first audience; compress + `srcset`.
- `.eyebrow` implemented 3 ways (Faq:11, ProgressWatch:51 hand-rolled) — consolidate to one component.
- `// load · grip · go` mono captions (Training:30, Community:75) are mono-as-costume — a gym isn't a terminal.
- Footer grain at `opacity-60` (Footer:9) is far above the documented 3–5% grain spec.
- Confirmed.astro CTA label uses Inter (`var(--font-sans)`) while the system sets CTAs in Saira — small drift.

## Questions to Consider

1. The brand's #1 principle is "show the body, not just the screen." You shipped only screens. If the imagery never arrives, is the thesis a lie the page tells about itself?
2. You followed DESIGN.md so faithfully you reproduced the one anti-pattern it bans (eyebrow-everywhere). When the spec and its own warnings conflict, which wins?
3. Lime-on-graphite + Saira condensed is now itself a template. What's the one move a competitor couldn't reproduce by Friday — and if it's the sky-dot in the chart, why is it 6px instead of the brand's whole identity?
4. You removed the spam-reassurance from the closing form and kept only the scarcity line. Decision, or missing prop?
