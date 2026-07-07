# Waitlist Double Opt-In + Premium Email + Sending Security — Design

**Date:** 2026-06-28
**Scope:** `landing/` (Astro + React 19 + Vercel) only. No iOS/Go changes.

Turn the landing waitlist from a single-step "create Resend contact" into a **double opt-in** flow: a premium, brand-aligned **confirmation email** (React Email), a stateless signed token, a confirm route that adds the contact only on confirmation, and hardened email-sending security (rate limiting, idempotency, retry, no enumeration).

---

## Goals
- Premium, aesthetic, brand-aligned waitlist **confirmation email**, bilingual (en/es), following Resend/React Email best practices.
- Double opt-in: contact is added to the Resend audience **only after** the user clicks the confirm link.
- Email-sending security: rate limiting (Upstash), signed/expiring HMAC token, idempotency + retry + timeout on send, no account enumeration.

## Non-goals
- A second post-confirmation "welcome" email (redirect to a success page instead; easy follow-up later).
- Disposable-email/MX validation, CAPTCHA, a persistent DB (token is stateless).
- Domain verification / Upstash provisioning (user-controlled infra; code degrades gracefully if env is unset).

---

## Decisions (locked)
- **Opt-in:** double opt-in.
- **Sender:** `BulkUp <waitlist@getbulkup.com>` (requires `getbulkup.com` verified in Resend).
- **Rate limiting:** Upstash Redis via `@upstash/ratelimit`.

---

## Flow

```
POST /api/waitlist  (email, locale, website[honeypot])
  → validateWaitlist()           # existing: honeypot + format
  → rate limit (Upstash)         # per-IP 5/min, per-email 3/h ; fail-open on store error
  → token = signWaitlistToken({ email, locale }, 48h)
  → sendWithRetry(confirm email) # Resend, idempotency key, backoff, timeout
  → return { ok: true }          # ALWAYS generic (no enumeration)

GET /api/waitlist/confirm?token=...
  → verifyWaitlistToken(token)   # HMAC + expiry, timing-safe
    valid   → resend.contacts.create({ email, unsubscribed: false })  (idempotent; 409 = already in → treat as success)
            → 302 redirect to /[es/]waitlist/confirmed
    invalid → 302 redirect to /[es/]waitlist/confirmed?expired=1  (friendly "link expired, sign up again")
```

The confirm link is built from the request origin (`new URL(request.url).origin`) — no extra site-URL env var.

---

## Components

### `landing/src/lib/waitlist-token.ts`
Stateless signed token, no DB. Node `crypto` (Vercel Node serverless runtime).

```ts
// payload: { e: email, l: locale, x: expiryEpochSeconds }
signWaitlistToken(email: string, locale: string, ttlSeconds = 60*60*48): string
verifyWaitlistToken(token: string): { ok: true; email: string; locale: string } | { ok: false }
```
- Format: `base64url(JSON payload)` + `"."` + `base64url(HMAC_SHA256(payloadPart, secret))`.
- Secret: `import.meta.env.WAITLIST_TOKEN_SECRET`. If unset, `sign` throws (caught upstream → 500) — fail closed for signing.
- `verify`: recompute HMAC, `crypto.timingSafeEqual`, then check `x > now`. Any parse/format error → `{ ok: false }`.

### `landing/src/lib/ratelimit.ts`
```ts
// Returns { success: boolean }. Fails OPEN (returns success:true) if Upstash env is
// missing or the call throws, so signups never break on infra issues (logged).
checkWaitlistRateLimit(ip: string, email: string): Promise<{ success: boolean; reason?: 'ip' | 'email' }>
```
- Lazily construct `Ratelimit` (sliding window) from `UPSTASH_REDIS_REST_URL` / `UPSTASH_REDIS_REST_TOKEN`.
- Two limiters: IP `5/60s`, email `3/3600s`. Check both; first failure returns `{ success:false, reason }`.
- If env vars are absent → return `{ success:true }` (no-op) so local/dev works without Upstash.

### `landing/src/lib/send-email.ts`
```ts
sendWithRetry(args: { from, to, subject, react, idempotencyKey }, maxRetries = 3): Promise<void>
```
- Wraps `resend.emails.send(payload, { headers:{'Idempotency-Key':key}, ... })`.
- Retry on `statusCode >= 500 || statusCode === 429`; exponential backoff `1s,2s,4s` + jitter; otherwise throw.
- 15s timeout via `AbortController` per attempt.
- Resend SDK renders `react` to both HTML and plain text automatically.

### `landing/emails/waitlist-confirm.tsx`
React Email template (`react-email` package, `Tailwind` + `pixelBasedPreset`). Props `{ confirmUrl: string; locale: 'en' | 'es' }`.
- `<Html lang={locale}>`, `<Preview>` first, single `<Container>` (max 600px).
- Brand Tailwind config: `colors: { lime:'#94c51d', limeDeep:'#7da817', graphite:'#111827', muted:'#6b7280', fog:'#f5f5f5', line:'#e5e7eb' }`, paper-white bg, Nunito Sans font stack (system fallback in email).
- Content: text **"BulkUp"** wordmark (no SVG) → `<Heading as="h1">` "Confirm your email" / "Confirma tu correo" → one value-prop line → lime `<Button>` (`box-border`) "Confirm" / "Confirmar" → small footer: "expires in 48h · ignore if this wasn't you" + a plain `<Link>` fallback of the same URL.
- Copy is chosen by `locale` from a small in-file `t` map. `.PreviewProps` set for `npm run email`.
- Accessibility: AA contrast, alt text on any image (none here besides the text wordmark), `<Hr border-solid>`.

### `landing/src/pages/api/waitlist.ts` (rework)
- Keep the parse + `validateWaitlist` (honeypot/format) prologue.
- Add IP extraction: `request.headers.get('x-forwarded-for')?.split(',')[0]?.trim() ?? 'unknown'`.
- `checkWaitlistRateLimit(ip, email)` → on `!success` return `{ ok:false, reason:'rate_limited' }` 429.
- `signWaitlistToken` → build `confirmUrl = ${origin}/api/waitlist/confirm?token=${token}`.
- `sendWithRetry({ from:'BulkUp <waitlist@getbulkup.com>', to:email, subject:<localized>, react:<WaitlistConfirmEmail confirmUrl locale/>, idempotencyKey:'waitlist-confirm-'+sha256(token).slice(0,32) })`.
- Guard: if `!RESEND_API_KEY` → 500 `server` (as today). On send throw → 500 `server`. On success → `{ ok:true }`.
- Spam honeypot still returns `{ ok:true }` (no signal to bots).

### `landing/src/pages/api/waitlist/confirm.ts` (new)
- `GET`, `prerender = false`.
- `verifyWaitlistToken(token)`; on invalid → 302 to confirmed page with `?expired=1` (locale from token if parseable, else en).
- On valid → `new Resend(apiKey).contacts.create({ email, unsubscribed:false })`; catch a 409/"already exists" and treat as success (idempotent); other errors → still redirect to success (the user's intent is satisfied; log the error). Redirect 302 to `/waitlist/confirmed` (or `/es/waitlist/confirmed`).

### Success page
- Shared `landing/src/components/Confirmed.astro` (or `.tsx`): brand-aligned "You're on the list" with an `expired` variant.
- `landing/src/pages/waitlist/confirmed.astro` (en) and `landing/src/pages/es/waitlist/confirmed.astro` (es) — thin wrappers passing locale + reading `?expired`.

---

## New dependencies & env

**deps:** `react-email`, `@upstash/ratelimit`, `@upstash/redis`.

**env (server-only — no `PUBLIC_` prefix), added to `.env.example` + README:**
- `WAITLIST_TOKEN_SECRET` — random 32+ byte secret for HMAC.
- `UPSTASH_REDIS_REST_URL`, `UPSTASH_REDIS_REST_TOKEN` — Upstash (optional locally; rate limit no-ops if absent).
- `RESEND_API_KEY` — existing.

---

## Error handling
- Missing `RESEND_API_KEY` → 500 `server`.
- Rate limited → 429 `rate_limited`.
- Send failure (after retries) → 500 `server`; the client form shows its generic error.
- Invalid/expired confirm token → friendly success-page `expired` state, not a 4xx wall.
- Upstash down → fail open (allow), logged.

## Testing (landing builds + runs here)
- `waitlist-token.test.ts` (vitest): sign→verify round-trip returns the email/locale; tampered payload → `{ok:false}`; tampered signature → `{ok:false}`; expired (`ttl` in the past) → `{ok:false}`; malformed string → `{ok:false}`.
- Extend `waitlist.test.ts`: keep existing validation cases.
- `npm run build` (astro) must pass — compiles the API routes + the React Email import.
- `npm run email` available for visual preview of the template (`.PreviewProps`).
- Manual: real send requires verified domain + Upstash; verified by the user post-merge.

## Security checklist (the "rate limiting and etc")
- [x] Rate limiting per-IP + per-email (Upstash).
- [x] Double opt-in (consent + verified address; contact added only on confirm).
- [x] Signed, expiring, timing-safe HMAC token; stateless.
- [x] Idempotency key on send; retry/backoff; 15s timeout.
- [x] No account enumeration (generic response).
- [x] Honeypot + server-side validation (existing, retained).
- [x] Secrets server-only; confirm URL from request origin.
- [ ] (Accepted trade-off) GET-confirm may be auto-fetched by inbox scanners — harmless for a waitlist.
