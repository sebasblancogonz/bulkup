# BulkUp Landing

Astro + Tailwind v4 marketing site (EN default `/`, ES `/es`). Waitlist → Resend.

## Develop
```bash
cd landing
cp .env.example .env   # fill RESEND_API_KEY, WAITLIST_TOKEN_SECRET, UPSTASH_REDIS_REST_URL, UPSTASH_REDIS_REST_TOKEN
npm install
npm run dev
```

## Test
```bash
npm test
```

## Deploy (Vercel)
- Set **Root Directory** = `landing`.
- Add env vars `RESEND_API_KEY`, `WAITLIST_TOKEN_SECRET`, `UPSTASH_REDIS_REST_URL`, `UPSTASH_REDIS_REST_TOKEN` (on Vercel KV the last two arrive as `KV_REST_API_URL`/`KV_REST_API_TOKEN`, which the code also reads). Optional: `RESEND_FROM` (sender override) and `RESEND_SEGMENT_ID` (bucket confirmed signups into a Resend Segment).
- Framework preset: Astro.
- Waitlist uses double opt-in — sends a confirmation email; the contact is added to Resend only after the user confirms. Sender domain must be verified in Resend.

## Swap placeholders before launch
- `public/og-default.png` — replace the placeholder solid-color PNG with branded 1200×630 art.
- `public/favicon.svg`, logo wordmark in `Hero.astro` / `Footer.astro`.
- Device mockups in `Hero.astro` and `Showcase.astro` — real screenshots.
- `SocialProof.astro` / count value.
- Display font `--font-display` in `global.css` (currently a system fallback; add the real webfont).
