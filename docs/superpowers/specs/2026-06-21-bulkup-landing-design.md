# BulkUp Landing Page — Design Spec

**Date:** 2026-06-21
**Status:** Approved (pending user review of this doc)
**Location:** `/landing` (self-contained, does not touch the iOS app)

## Goal

A pre-launch marketing site for BulkUp (AI-powered fitness coaching app) whose
single job is to **capture waitlist signups** while showcasing the app as a
premium product. Optimized hard for SEO, SEM, and LLM/GEO discoverability.

Primary CTA everywhere: **join the waitlist**.

## Decisions (locked)

| Topic | Decision |
|---|---|
| Launch status | Pre-launch. Waitlist is the only conversion goal. |
| Languages | Bilingual EN + ES. **EN is default (`/`)**, ES at `/es`. `hreflang` + `x-default`. |
| Email backend | **Resend** — contacts stored in a Resend Audience; enables newsletter broadcasts later. |
| Brand assets | User provides logo + real screenshots later. Build with swappable placeholders (device mockups, logo slot). |
| Aesthetic | Dark athletic premium — near-black bg, vibrant lime/electric-green accent, oversized bold type, cinematic gradients/glow, subtle grain. Organic, not templated. |
| Tech stack | **Astro + React islands + Tailwind v4**, deployed on **Vercel**. |
| Domain | getbulkup.com (or subdomain — final value set in Vercel, not hardcoded). |

## Tech Stack

- **Astro 5** (static output + Vercel adapter for the one server route).
- **Tailwind CSS v4** for styling (design tokens via CSS vars).
- **React islands** only where interactivity/animation needs hydration
  (waitlist form, scroll/motion components). Everything else is static HTML →
  near-zero JS.
- **Motion** (`motion`/Framer Motion) and/or **GSAP** for scroll-triggered and
  micro animations, loaded only inside islands.
- **Resend** Node SDK, called from the server route only.
- Deploy: **Vercel**, building from the `/landing` subdirectory.

Rationale: a marketing page is mostly content; Astro ships ~0 JS for static
content → best Core Web Vitals (a Google ranking factor) and cleanest HTML for
LLM crawlers. Islands give us premium motion without taxing the whole page.

## Page Structure (single long-scroll)

Each section is an independent component with one clear purpose.

1. **Hero** — oversized headline leading with the differentiator (upload a
   PDF/photo of your plan → AI turns it into a trackable app). Waitlist email
   input as primary CTA. Animated phone mockup, glow, grain.
2. **Social proof strip** — "Join N+ athletes" waitlist counter + trust signals.
3. **Problem → Solution** — animated before→after: messy PDF plan → structured
   digital plan. The core hook.
4. **Premium features bento grid** — Training plans (templates + AI import),
   AI diet parsing, 1RM tracking, body composition, meal compliance/streaks,
   friends leaderboard. Scroll-triggered reveals.
5. **Premium deep-dive** — 2–3 scroll-scrubbed/pinned sections highlighting the
   features that justify the subscription.
6. **Visual showcase** — device mockup carousel (placeholder screens, swappable).
7. **Pricing teaser** — monthly + annual tiers (mirrors StoreKit setup); waitlist
   = early access perk.
8. **FAQ** — accordion; also emits `FAQPage` JSON-LD.
9. **Final waitlist CTA** — full-bleed repeat capture.
10. **Footer** — nav, language switch, legal, social.

## Waitlist Flow

- Native `<form>` (functions without JS) posts to `POST /api/waitlist`.
- Server route validates the email, adds the contact to the **Resend Audience**,
  optionally sends a welcome email, returns JSON.
- React island enhances UX (inline success/error, loading state) but degrades
  gracefully.
- **Honeypot** hidden field + basic rate limiting for spam.
- Secrets: `RESEND_API_KEY`, `RESEND_AUDIENCE_ID` as Vercel env vars. Repo ships
  a `.env.example` only — never real keys.

## SEO / SEM / LLM Plan

- Per-page `<title>`, meta description, canonical, OG + Twitter cards.
- `hreflang` for en/es + `x-default` (→ EN).
- `sitemap.xml`, `robots.txt`, and `llms.txt`.
- JSON-LD: `SoftwareApplication`, `Organization`, `FAQPage`.
- Keyword-targeted bilingual copy
  (EN: "personalized workout plan app", "turn PDF workout plan into app",
  "AI diet tracking app"; ES mirrors:
  "app entrenamiento personalizado", "convertir plan PDF en app",
  "seguimiento dieta IA").
- Dynamic OG image. Performance budget: near-100 Lighthouse, green Core Web Vitals.

## Design System (dark athletic premium)

- **Palette:** near-black base (`#0A0A0B`-ish), layered dark surfaces, one
  vibrant accent (electric lime/green), warm white text, muted grays. Optional
  secondary accent pulled from app feature colors used sparingly.
- **Type:** bold oversized display for headlines, clean grotesk for body. One
  display + one text family.
- **Texture:** subtle film grain, soft radial glows, gradient meshes behind hero.
- **Motion:** scroll reveals, parallax on mockups, magnetic/hover micro-states on
  CTAs, scrubbed scrolly in deep-dive. Respect `prefers-reduced-motion`.
- All tokens centralized (CSS vars / Tailwind theme) so brand can be retuned in
  one place when real assets land.

## Repo Layout

```
/landing
  package.json          # self-contained, own deps
  astro.config.mjs      # i18n + vercel adapter + tailwind
  .env.example
  src/
    pages/              # index.astro (en, default), es/index.astro
    components/         # one file per section + shared UI
    layouts/
    content/            # bilingual copy (i18n dictionaries)
    styles/             # tokens + globals
  public/               # robots.txt, llms.txt, placeholder assets, favicon
```

The iOS app, widgets, and Go backend are untouched.

## Out of Scope (YAGNI)

- No CMS — copy lives in typed i18n dictionaries.
- No blog (can add later if content marketing is pursued).
- No analytics vendor decision here (leave a single swappable script slot).
- No real screenshots/logo — placeholders wired for easy swap.
- No App Store download flow (pre-launch).

## Success Criteria

- Builds and deploys to Vercel from `/landing`.
- Waitlist form adds a real contact to the Resend Audience.
- Lighthouse SEO + Performance ≥ 95 on the hero page.
- Valid JSON-LD (passes Rich Results test), correct hreflang, sitemap present.
- Both `/` (EN) and `/es` render fully with working language switch.
- Reduced-motion users get a static, fully-usable page.
