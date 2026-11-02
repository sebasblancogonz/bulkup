---
version: 1
slug: "bulkup-views-subscriptionview-swift"
primary_target: "bulkup/Views/SubscriptionView.swift"
related_targets: ["bulkup/Views/SubscriptionRequiredView.swift"]
---

# Surface: Paywall (SubscriptionView, SubscriptionRequiredView)

Mode: Persuade. Audience: a free user who just hit a PRO gate (AI import, second plan, progress, RM, measurements, recipes) or opened "Mi suscripción". Action: pick a plan and start the trial / subscribe; or restore. Proof: the real feature list (only what is actually gated), real prices from StoreKit, the yearly plan's free trial, 1,000+ exercises and 1RM formulas as product facts. Constraints: Apple 3.1.2 (price, period, auto-renew text, Terms + Privacy links, Restore), no invented claims, Spanish-first copy mirrored in English.

## Direction contract

THESIS: a price list that reads like a plate stack, not a feature carousel. It refuses the crown icon + benefit cards + gradient CTA arrangement.
OWN-WORLD: graphite ground, one Saira Condensed uppercase headline, a hairline-separated list of what unlocks (SF symbol, name, one dry line), two selectable plan rows with mono prices and a lime radio, one lime CTA. No crown, no gradient text, no cards inside cards.
STORY: "Mi plan está en un PDF; PRO lo mete en la app y me enseña si avanzo" → sees exactly what is locked and what it costs per month → starts the trial.
FIRST VIEWPORT: close (X) top-right; headline "TU PROGRESO, VISIBLE" at 34pt; one-line sub; the unlock list (6 rows) immediately; plan rows and the CTA pinned at the bottom with the per-period price in mono; legal links and the auto-renew sentence under the CTA.
FORM: hairline price list (ranked first of the structures considered: price list, comparison table, single-plan hero, feature carousel, timeline of the trial); inherited world, no seed key (world pinned by the user, code-led).
FINISH: unreviewed and undocumented is unfinished; this build ends with the finish review, the verdict, DESIGN.md, and every shipping raster carrying its provenance.
