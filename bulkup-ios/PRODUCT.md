# Product

<!-- impeccable:product-schema 1 -->

## Platform

ios

## Users

People who already train and already have a plan: a routine and/or diet a coach handed them as a PDF or a photo. Lifters mid-program who care about progressing (sets, kilos, PRs, body composition, adherence). They use the app on an iPhone at the gym, between sets, one-handed and sweaty, and on an Apple Watch on the wrist. The job: log the session they are doing right now in a few taps, and know whether they are advancing week over week. (Carried from the landing's PRODUCT.md; confirmed by the user's answers in this session.)

## Product Purpose

BulkUp turns the training/diet plan you already have into a trackable iOS + Apple Watch app: AI parses the PDF/photo once, then you log every set, weight and PR, follow the diet, track body measurements, keep streaks and compete with friends. Success for the app itself is a logged session: every set checked, every kilo saved, the week's progress visible without hunting for it.

## Positioning

The plan is yours and already exists; BulkUp digitises it instead of selling you a template. The product enemy is invisible progress: training hard without knowing if you are advancing.

## Operating Context

- Training tab: active plan (day view with exercise cards and an in-session mode with rest timer, per-set check-off, failure marks, skip/swap exercise, add/remove sets), week view, plan library, templates, manual editor, AI import, import by code.
- Today tab: greeting, week strip, today's workout, quick stats, exercise list with inline logging, today's meals with check-off.
- Diet, Progress (dashboard, RM, measurements, friends ranking) and Profile tabs.
- Apple Watch companion mirrors the live session (sets, weights, rest) and reads heart rate / energy; a Lock Screen Live Activity mirrors the current set.
- Backend: api.getbulkup.com (Go/Mongo). Spanish is the source language, English is mirrored.

## Capabilities and Constraints

- Free tier: one active training plan and one diet plan (user decision 2 Nov 2026), manual plan creation, templates, logging, watch. PRO (auto-renewable monthly / yearly via Apple IAP, yearly carries a free trial): AI import of PDFs/photos, more than one plan, share/import plans by code, progress dashboard, body measurements and composition, personal records (RM), AI recipes, diet fidelity.
- App Store readiness is the current constraint: account deletion, privacy manifest, legal pages, correct versions, Dynamic Type and Dark Mode support.
- Supports light and dark appearance (user setting: system/light/dark).
- Terminology (ES): entreno, serie, reps, kg, descanso, récord (RM), plan, racha, fidelidad.

## Brand Commitments

- Name: BulkUp. Voice: the training partner who has lifted eight years, not the influencer. Direct, dry, on your side; speaks in kilos, sets, weeks and streaks. Tutea. No hype, no "transforma tu vida", no self-applied "premium", no "con IA" in a headline.
- Visual world (binding, chosen by the user 2 Nov 2026): the landing's "Graphite & Voltage" system (`landing/DESIGN.md`): graphite ground (never pure black), bone-white text, electric lime as a razor (≤10% of a screen, only where action or progress lives), sky for "done", amber as the only error colour; Saira Condensed uppercase for display moments, SF Pro for UI, JetBrains Mono for every datapoint; hierarchised radii (14 cards, 10 buttons/inputs, pills only for chips); hairlines over shadows.
- Fonts Saira Condensed and JetBrains Mono (OFL) are bundled in the app (user approval 2 Nov 2026).
- Assets: logo and wordmark variants in `assets/`, app icon in `bulkup/Assets.xcassets/AppIcon.appiconset`.

## Evidence on Hand

- Real product facts: 1,000+ exercise database, standard 1RM formulas, iOS + Apple Watch. No testimonials, user counts or benchmarks exist; never invent them.
- Prices come from StoreKit at runtime (never hard-coded in the UI).

## Product Principles

1. The set being logged right now is the hero; everything else steps back.
2. Numbers are proof: every kilo, rep, % and streak is set in mono and never faked.
3. Lime fires only on action and progress; graphite does the rest.
4. Native first: system navigation, controls, Dynamic Type, Dark Mode. Brand lives in type, tint and data.
5. Say less, in the gym's own words.

## Accessibility & Inclusion

Text ≥4.5:1 on its ground in both appearances, 44pt touch targets for every control used mid-set, Dynamic Type via text styles and `relativeTo` for custom faces, Reduce Motion honoured for decorative animation, VoiceOver labels on icon-only controls.
