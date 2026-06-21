# BulkUp Landing

Astro + Tailwind v4 marketing site (EN default `/`, ES `/es`). Waitlist → Resend.

## Develop
```bash
cd landing
cp .env.example .env   # fill RESEND_API_KEY + RESEND_AUDIENCE_ID
npm install
npm run dev
```

## Test
```bash
npm test
```

## Deploy (Vercel)
- Set **Root Directory** = `landing`.
- Add env vars `RESEND_API_KEY`, `RESEND_AUDIENCE_ID`.
- Framework preset: Astro.

## Swap placeholders before launch
- `public/og-default.png` — replace the placeholder solid-color PNG with branded 1200×630 art.
- `public/favicon.svg`, logo wordmark in `Hero.astro` / `Footer.astro`.
- Device mockups in `Hero.astro` and `Showcase.astro` — real screenshots.
- `SocialProof.astro` / count value.
- Display font `--font-display` in `global.css` (currently a system fallback; add the real webfont).
