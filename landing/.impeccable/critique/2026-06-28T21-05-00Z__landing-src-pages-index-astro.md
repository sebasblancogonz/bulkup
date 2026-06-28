---
target: landing
total_score: 36
p0_count: 0
p1_count: 0
timestamp: 2026-06-28T21-05-00Z
slug: landing-src-pages-index-astro
---
# Re-Critique #3 — BulkUp Landing ("Graphite & Voltage") — post P0-P3

Source-based. Conversion goal: waitlist email capture.

## Design Health Score
| # | Heuristic | Score | Key issue |
|---|-----------|-------|-----------|
| 1 | Visibility of System Status | 4 | 6 form states wired + role=status/alert; scroll-progress; chart draw-in. |
| 2 | Match System / Real World | 4 | Kilos/series/PRs/rachas; zero SaaS filler; honesty reframes airtight. |
| 3 | User Control & Freedom | 3 | Retry path real now ("Reintentar"); minor: no dismiss of invalid except editing field. |
| 4 | Consistency & Standards | 4 | Tokens uniform across 11 sections; one form component. |
| 5 | Error Prevention | 3 | Regex + honeypot + double-submit guard; NO inputmode/autocomplete on the email input. |
| 6 | Recognition over Recall | 4 | One field, label, placeholder, reassurance. |
| 7 | Flexibility & Efficiency | 3 | CTAs anchor to #waitlist; no persistent mobile CTA after hero scrolls. |
| 8 | Aesthetic & Minimalist | 4 | Razor rule held, real depth; premium. Capped by stock (not bespoke) photography. |
| 9 | Error Recovery | 3 | Amber errors, recoverable; generic 500 message, no contact fallback. |
| 10 | Help & Documentation | 4 | FAQ answers the 4 real objections in-voice. |
| **Total** | | **36/40** | **Excellent** (32 → 35 → 36). No P0, no P1. |

## Anti-Patterns Verdict
First-order: NOT slop — disciplined graphite system, voiced copy. Second-order: two seams — (1) imagery is still recognizably Unsplash stock (now 4 distinct treatments, but stock); (2) the decorative `// load · grip · go` mono captions flirt with affectation. Detector: 0 findings.

## What moved 35 → 36
- +H1 status / +H3 control: the form error path went from dead-end to live-retry CTA (six states). Biggest real win.
- Honesty airtight: Community "Tu %/1×/día" capabilities, "datos de ejemplo" labels, no fake counters.
- Copy: hero subtitle cut to one scannable clause.
- Image LCP genuinely improved (home 1.6MB→67KB WebP, hero srcset+webp+preconnect) — but offset by the text-LCP finding below.

## Priority issues (no P0/P1 — all P2/P3, honest)
- [P2] Hero copy ships at opacity:0, gated on React hydration. The H1/subtitle/form are wrapped in <Reveal client:load> (Framer initial opacity:0); the no-JS fallback only helps headless crawlers (the .js class is added before render). So on a real slow phone the LCP *text* waits on hydration. Fix: don't wrap the above-the-fold hero H1/subtitle/form in motion Reveals (reveal only below-fold).
- [P2] home.webp (mockup) eager but not preloaded; Google Fonts render-blocking (display=swap only). Fix: self-host/preload fonts; preload the true LCP image. Measure with Lighthouse mobile.
- [P3] Only the HERO Unsplash photo got srcset+fm=webp; Training/Diet/Community still ship a single 1200px non-WebP each (below-fold, lazy → lower impact). Fix: add &fm=webp + small srcset to those 3.
- [P3] 2 unused heavy PNGs (rest.png 345KB, workout.png 314KB) ship in /public (not referenced). Fix: git rm.
- [P3] No on-ramp for Jordan (no-plan first-timer) — the template path exists in copy (PPL/Upper-Lower) but is buried; an FAQ "no tengo plan todavía" would surface it. (Arguably out-of-scope per PRODUCT.md.)

## Cognitive load: 0 hard failures (1 soft: animation-dense default, but prefers-reduced-motion honored).
## Personas: Mateo (skeptic) best-served (honesty work disarms him; only tell = stock photos). Casey (mobile): hero text waits on hydration + no inputmode/autocomplete + no persistent mobile CTA. Jordan: every CTA presupposes an existing plan.
## Minor: og-default.png is 3.1KB (likely bland share card); data.platform reused as a Diet chip; decorative mono captions.

## Ceiling: capped at 36 (not 38-39) by stock photography (interim, not bespoke) + the saturated graphite+lime category lane (sanctioned by the brief). "Built impeccably, not yet shot impeccably."
