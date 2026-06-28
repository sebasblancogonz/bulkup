---
target: landing
total_score: 35
p0_count: 1
p1_count: 2
timestamp: 2026-06-28T20-39-50Z
slug: landing-src-pages-index-astro
---
# Re-Critique — BulkUp Landing ("Graphite & Voltage") — post-fix

Source-based (browser automation unavailable). Conversion goal: waitlist email capture.

## Design Health Score
| # | Heuristic | Score | Key issue |
|---|-----------|-------|-----------|
| 1 | Visibility of System Status | 4 | Form now has 6 states (idle/loading "Enviando…"/success/invalid/429-rate/500-error) + disable-on-submit. Complete. |
| 2 | Match System / Real World | 4 | Kilos, series, PRs, 1RM, PPL — elite audience match, no SaaS lexicon. |
| 3 | User Control & Freedom | 3 | Native <details>, lang switch, anchors. Success replaces field with no back-out. |
| 4 | Consistency & Standards | 4 | Tokens disciplined; eyebrow cadence now Hero+FAQ only. |
| 5 | Error Prevention | 3 | Regex + double-submit guard + honeypot; no inline validation until submit. |
| 6 | Recognition over Recall | 4 | One field, verb CTA, reassurance under it. |
| 7 | Flexibility & Efficiency | 3 | Two CTA placements to one form, EN/ES. |
| 8 | Aesthetic & Minimalist | 4 | Lime <=10%, real depth, real photography. Strongest axis. |
| 9 | Error Recovery | 3 | 429 vs 500 distinguished, amber (not lime). But error states are dead-ends (no retry/contact). |
| 10 | Help & Documentation | 3 | FAQ answers the 4 real objections in-voice; no contact/privacy near the form. |
| **Total** | | **35/40** | **Strong, near-excellent** (was 32/40). |

## Anti-Patterns Verdict
First-order: NOT slop — committed graphite system, no gradient/glass/rounded-everything, authored voice. Second-order: one residue — the 4 section photos use an identical treatment filter (grayscale 0.35 / contrast 1.05 / brightness 0.78) → reads as "consistent filter on bought stock", which Mateo (the skeptic) detects. Competent stock, not bespoke.
Detector (B): 0 findings (the prior false-positive is gone). Browser overlays: unavailable in this env.

## What improved vs. before (~27-29 hypothetical → 35)
- Status 2→4: form went idle/success-only → 6 states + 429/500 + loading.
- Aesthetic + slop: real Unsplash photography under graphite treatment delivers "show the body" (placeholder blocks never could).
- Consistency: eyebrow removed from every section (Hero+FAQ only) — kills the anti-SaaS tell.
- Honesty: "datos de ejemplo" labels on the demo chart/bpm defuse the fake-metric trigger.
- Distinctiveness: Inter → Hanken Grotesk (off the AI-default face).

## Priority Issues
- [P0] Hero LCP: home.png is 1.6MB + the 1600px Unsplash hero photo, BOTH eager, neither preloaded; render-blocking Google Fonts. The added hero photo arguably WORSENED LCP. Audience is throttled-mobile. → compress home.png to AVIF/WebP <200KB, responsive srcset on the Unsplash hero, preload the LCP image, &fm=webp. (/impeccable optimize)
- [P1] Uniform stock imagery: identical filter string x4 + most-recognizable Unsplash frames. → vary treatment per section now; bespoke shoot later. (art-direct)
- [P1] Community prints an unlabeled `100%` adherence + `1x/día` as bare metrics while ProgressWatch labels its demo data — honesty inconsistency Mateo reads as fabricated. → reframe as capabilities or add the sample label. (honesty audit)
- [P2] Form error/rate states are dead-ends (no retry affordance / contact path). → add Reintentar on 500, soft cooldown on 429. (/impeccable harden)
- [P3] Hero subtitle density: the aphoristic rhythm taxes first-scan skimmers (voice-correct, keep it lower-page). → shorten the hero subtitle to one clause. (/impeccable clarify)

## Cognitive Load: 3/8 fail (text-over-hero-photo margin thin; copy density; Community unlabeled 100%).

## Persona flags
- Casey (mobile, PRIMARY): the LCP weight + DataStrip horizontal scroll with no affordance cue.
- Jordan (first-timer): the whole frame assumes "the plan you already have"; no "no plan yet → start from a template" on-ramp.
- Mateo (burned lifter): mostly survives him (sample-data labels, honest scarcity, amber errors) but the unlabeled Community 100% + uniform stock are his exact triggers.

## Minor: continue_workout.png 906KB; og-default.png 3.1KB (likely placeholder); two hero glow layers slightly busy; Hanken is quiet against Saira (acceptable). Accessibility holds up (aria-hidden decorative, bilingual alt, lime focus rings, reduced-motion).
