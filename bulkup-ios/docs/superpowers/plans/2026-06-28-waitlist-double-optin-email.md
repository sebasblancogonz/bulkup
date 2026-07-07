# Waitlist Double Opt-In + Premium Email + Sending Security — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax.

**Goal:** Convert the landing waitlist to double opt-in: a premium bilingual confirmation email (React Email), a stateless signed token, a confirm route that adds the contact only on confirmation, and hardened sending security (Upstash rate limiting, idempotency, retry, no enumeration).

**Architecture:** All in `landing/` (Astro + React 19 + Vercel Node serverless). Pure libs (`waitlist-token`, `ratelimit`, `send-email`) are unit-tested with vitest; the email template and routes are verified with `npm run build` + targeted tests. `POST /api/waitlist` mints a signed token and sends the confirm email; `GET /api/waitlist/confirm` verifies it and creates the Resend contact.

**Tech Stack:** Astro 5, React 19, `resend@6`, `react-email`, `@upstash/ratelimit` + `@upstash/redis`, Node `crypto`, vitest.

## Global Constraints

- `landing/` only. No iOS/Go changes. Node serverless runtime (not edge).
- Sender: `BulkUp <waitlist@getbulkup.com>` (requires `getbulkup.com` verified in Resend).
- Brand (email): lime `#94c51d`, deeper lime `#7da817`, graphite `#111827`, muted `#6b7280`, fog `#f5f5f5`, line `#e5e7eb`, paper-white `#ffffff`; Nunito Sans (system fallback in email); flat/shadowless; max-width 600px; AA contrast.
- resend v6 idempotency is passed as `{ idempotencyKey }` (the SDK sets the header) — NOT a manual `headers` map.
- Token is stateless HMAC-SHA256, 48h TTL, timing-safe verify. Secrets are server-only (no `PUBLIC_` prefix).
- Always return a generic response from `POST /api/waitlist` (no account enumeration). Rate-limit store failures fail OPEN.
- Bilingual en/es throughout (driven by the form's `locale`).
- Verify command: `cd landing && npm test` (vitest) and `cd landing && npm run build` (astro). Both must pass.

---

## Task 1: Signed waitlist token (`waitlist-token.ts`)

**Files:**
- Create: `landing/src/lib/waitlist-token.ts`
- Test: `landing/src/test/waitlist-token.test.ts`
- Modify: `landing/.env.example`

**Interfaces:**
- Produces:
  - `signWaitlistToken(email: string, locale: string, ttlSeconds?: number): string`
  - `verifyWaitlistToken(token: string): { ok: true; email: string; locale: string } | { ok: false }`

- [ ] **Step 1: Write the failing tests**

Create `landing/src/test/waitlist-token.test.ts`:

```ts
import { describe, it, expect, beforeAll } from 'vitest';
import { signWaitlistToken, verifyWaitlistToken } from '../lib/waitlist-token';

beforeAll(() => {
  process.env.WAITLIST_TOKEN_SECRET = 'test-secret-please-change-0123456789';
});

const b64url = (s: string) =>
  Buffer.from(s).toString('base64').replace(/\+/g, '-').replace(/\//g, '_').replace(/=+$/, '');

describe('waitlist-token', () => {
  it('round-trips email and locale', () => {
    const token = signWaitlistToken('a@b.com', 'es');
    expect(verifyWaitlistToken(token)).toEqual({ ok: true, email: 'a@b.com', locale: 'es' });
  });

  it('rejects a tampered payload (signature no longer matches)', () => {
    const token = signWaitlistToken('a@b.com', 'en');
    const sig = token.split('.')[1];
    const forgedBody = b64url(JSON.stringify({ e: 'evil@x.com', l: 'en', x: 9999999999 }));
    expect(verifyWaitlistToken(`${forgedBody}.${sig}`)).toEqual({ ok: false });
  });

  it('rejects a tampered signature', () => {
    const token = signWaitlistToken('a@b.com', 'en');
    const body = token.split('.')[0];
    expect(verifyWaitlistToken(`${body}.AAAABBBBCCCC`)).toEqual({ ok: false });
  });

  it('rejects an expired token', () => {
    const token = signWaitlistToken('a@b.com', 'en', -10); // expired 10s ago
    expect(verifyWaitlistToken(token)).toEqual({ ok: false });
  });

  it('rejects malformed input', () => {
    expect(verifyWaitlistToken('garbage')).toEqual({ ok: false });
    expect(verifyWaitlistToken('')).toEqual({ ok: false });
    expect(verifyWaitlistToken('a.b.c')).toEqual({ ok: false });
  });
});
```

- [ ] **Step 2: Run the tests, verify they fail**

Run: `cd landing && npx vitest run src/test/waitlist-token.test.ts`
Expected: FAIL — cannot resolve `../lib/waitlist-token`.

- [ ] **Step 3: Implement `waitlist-token.ts`**

Create `landing/src/lib/waitlist-token.ts`:

```ts
import crypto from 'node:crypto';

function getSecret(): string {
  const s =
    import.meta.env.WAITLIST_TOKEN_SECRET ?? process.env.WAITLIST_TOKEN_SECRET;
  if (!s) throw new Error('WAITLIST_TOKEN_SECRET is not set');
  return s;
}

function b64url(buf: Buffer): string {
  return buf.toString('base64').replace(/\+/g, '-').replace(/\//g, '_').replace(/=+$/, '');
}
function fromB64url(s: string): Buffer {
  return Buffer.from(s.replace(/-/g, '+').replace(/_/g, '/'), 'base64');
}

interface Payload {
  e: string; // email
  l: string; // locale
  x: number; // expiry, epoch seconds
}

export function signWaitlistToken(email: string, locale: string, ttlSeconds = 60 * 60 * 48): string {
  const payload: Payload = {
    e: email,
    l: locale,
    x: Math.floor(Date.now() / 1000) + ttlSeconds,
  };
  const body = b64url(Buffer.from(JSON.stringify(payload)));
  const sig = b64url(crypto.createHmac('sha256', getSecret()).update(body).digest());
  return `${body}.${sig}`;
}

export type VerifyResult = { ok: true; email: string; locale: string } | { ok: false };

export function verifyWaitlistToken(token: string): VerifyResult {
  if (typeof token !== 'string') return { ok: false };
  const parts = token.split('.');
  if (parts.length !== 2 || !parts[0] || !parts[1]) return { ok: false };
  const [body, sig] = parts;

  let expected: string;
  try {
    expected = b64url(crypto.createHmac('sha256', getSecret()).update(body).digest());
  } catch {
    return { ok: false };
  }
  const sigBuf = Buffer.from(sig);
  const expBuf = Buffer.from(expected);
  if (sigBuf.length !== expBuf.length || !crypto.timingSafeEqual(sigBuf, expBuf)) {
    return { ok: false };
  }

  try {
    const payload = JSON.parse(fromB64url(body).toString('utf8')) as Payload;
    if (typeof payload.e !== 'string' || typeof payload.l !== 'string' || typeof payload.x !== 'number') {
      return { ok: false };
    }
    if (payload.x < Math.floor(Date.now() / 1000)) return { ok: false };
    return { ok: true, email: payload.e, locale: payload.l };
  } catch {
    return { ok: false };
  }
}
```

- [ ] **Step 4: Run the tests, verify they pass**

Run: `cd landing && npx vitest run src/test/waitlist-token.test.ts`
Expected: PASS (5 tests).

- [ ] **Step 5: Add the env var to `.env.example`**

Append to `landing/.env.example`:

```
# HMAC secret for stateless waitlist confirm tokens — generate with: openssl rand -base64 32
WAITLIST_TOKEN_SECRET=replace-with-a-32-byte-random-secret
```

- [ ] **Step 6: Commit**

```bash
git add landing/src/lib/waitlist-token.ts landing/src/test/waitlist-token.test.ts landing/.env.example
git commit -m "feat(landing): stateless signed waitlist confirm token"
```

---

## Task 2: Rate limiting (`ratelimit.ts`)

**Files:**
- Create: `landing/src/lib/ratelimit.ts`
- Test: `landing/src/test/ratelimit.test.ts`
- Modify: `landing/package.json` (deps), `landing/.env.example`

**Interfaces:**
- Produces: `checkWaitlistRateLimit(ip: string, email: string): Promise<{ success: boolean; reason?: 'ip' | 'email' }>`

- [ ] **Step 1: Install Upstash packages**

Run: `cd landing && npm install @upstash/ratelimit @upstash/redis`
Expected: both added to `dependencies` in `package.json`.

- [ ] **Step 2: Write the failing test**

Create `landing/src/test/ratelimit.test.ts`:

```ts
import { describe, it, expect, beforeEach } from 'vitest';
import { checkWaitlistRateLimit } from '../lib/ratelimit';

describe('ratelimit (unconfigured)', () => {
  beforeEach(() => {
    delete process.env.UPSTASH_REDIS_REST_URL;
    delete process.env.UPSTASH_REDIS_REST_TOKEN;
  });

  it('allows (no-ops) when Upstash env is not configured', async () => {
    const r = await checkWaitlistRateLimit('1.2.3.4', 'a@b.com');
    expect(r.success).toBe(true);
  });
});
```

- [ ] **Step 3: Run the test, verify it fails**

Run: `cd landing && npx vitest run src/test/ratelimit.test.ts`
Expected: FAIL — cannot resolve `../lib/ratelimit`.

- [ ] **Step 4: Implement `ratelimit.ts`**

Create `landing/src/lib/ratelimit.ts`:

```ts
import { Ratelimit } from '@upstash/ratelimit';
import { Redis } from '@upstash/redis';

let ipLimiter: Ratelimit | null = null;
let emailLimiter: Ratelimit | null = null;
let initialized = false;

function init(): void {
  if (initialized) return;
  initialized = true;
  const url = import.meta.env.UPSTASH_REDIS_REST_URL ?? process.env.UPSTASH_REDIS_REST_URL;
  const token = import.meta.env.UPSTASH_REDIS_REST_TOKEN ?? process.env.UPSTASH_REDIS_REST_TOKEN;
  if (!url || !token) return; // unconfigured → no-op limiter
  const redis = new Redis({ url, token });
  ipLimiter = new Ratelimit({ redis, limiter: Ratelimit.slidingWindow(5, '60 s'), prefix: 'wl:ip' });
  emailLimiter = new Ratelimit({ redis, limiter: Ratelimit.slidingWindow(3, '3600 s'), prefix: 'wl:email' });
}

/**
 * Per-IP (5/min) and per-email (3/h) sliding-window limits.
 * Fails OPEN: if Upstash is unconfigured or unreachable, returns success
 * so signups never break on infra issues (logged).
 */
export async function checkWaitlistRateLimit(
  ip: string,
  email: string,
): Promise<{ success: boolean; reason?: 'ip' | 'email' }> {
  init();
  if (!ipLimiter || !emailLimiter) return { success: true };
  try {
    const ipRes = await ipLimiter.limit(ip);
    if (!ipRes.success) return { success: false, reason: 'ip' };
    const emailRes = await emailLimiter.limit(email);
    if (!emailRes.success) return { success: false, reason: 'email' };
    return { success: true };
  } catch (e) {
    console.error('waitlist ratelimit error (failing open)', e);
    return { success: true };
  }
}
```

- [ ] **Step 5: Run the test, verify it passes**

Run: `cd landing && npx vitest run src/test/ratelimit.test.ts`
Expected: PASS.

- [ ] **Step 6: Add env vars to `.env.example`**

Append to `landing/.env.example`:

```
# Upstash Redis (rate limiting). Optional locally — limits no-op if unset. https://upstash.com
UPSTASH_REDIS_REST_URL=
UPSTASH_REDIS_REST_TOKEN=
```

- [ ] **Step 7: Commit**

```bash
git add landing/src/lib/ratelimit.ts landing/src/test/ratelimit.test.ts landing/package.json landing/package-lock.json landing/.env.example
git commit -m "feat(landing): Upstash per-IP/per-email waitlist rate limiting (fail-open)"
```

---

## Task 3: Reliable send helper (`send-email.ts`)

**Files:**
- Create: `landing/src/lib/send-email.ts`
- Test: `landing/src/test/send-email.test.ts`

**Interfaces:**
- Produces: `sendWithRetry(args: SendArgs, opts?: { maxRetries?: number; baseDelayMs?: number }): Promise<void>` where
  `SendArgs = { apiKey: string; from: string; to: string; subject: string; react: ReactElement; idempotencyKey: string }`

**Notes:** The resend SDK returns `{ data, error }` (it does NOT throw on API errors). `error` is `{ name, message }`. Retry on transient `error.name` values and on thrown network/timeout errors; throw on permanent errors so the route returns 500.

- [ ] **Step 1: Write the failing test**

Create `landing/src/test/send-email.test.ts`:

```ts
import { describe, it, expect, vi, beforeEach } from 'vitest';

// Mock the resend module: Resend().emails.send is controlled per-test.
const sendMock = vi.fn();
vi.mock('resend', () => ({
  Resend: vi.fn().mockImplementation(() => ({ emails: { send: sendMock } })),
}));

import { sendWithRetry } from '../lib/send-email';
import { createElement } from 'react';

const args = {
  apiKey: 'k',
  from: 'BulkUp <waitlist@getbulkup.com>',
  to: 'a@b.com',
  subject: 'Confirm',
  react: createElement('div', null, 'hi'),
  idempotencyKey: 'wl-abc',
};

beforeEach(() => sendMock.mockReset());

describe('sendWithRetry', () => {
  it('passes the idempotency key and resolves on success', async () => {
    sendMock.mockResolvedValueOnce({ data: { id: '1' }, error: null });
    await sendWithRetry(args, { baseDelayMs: 0 });
    expect(sendMock).toHaveBeenCalledTimes(1);
    expect(sendMock.mock.calls[0][1]).toEqual({ idempotencyKey: 'wl-abc' });
  });

  it('retries on a transient error then succeeds', async () => {
    sendMock
      .mockResolvedValueOnce({ data: null, error: { name: 'rate_limit_exceeded', message: 'slow down' } })
      .mockResolvedValueOnce({ data: { id: '1' }, error: null });
    await sendWithRetry(args, { maxRetries: 3, baseDelayMs: 0 });
    expect(sendMock).toHaveBeenCalledTimes(2);
  });

  it('does NOT retry a permanent error and throws', async () => {
    sendMock.mockResolvedValue({ data: null, error: { name: 'validation_error', message: 'bad from' } });
    await expect(sendWithRetry(args, { maxRetries: 3, baseDelayMs: 0 })).rejects.toThrow();
    expect(sendMock).toHaveBeenCalledTimes(1);
  });

  it('retries on a thrown network error then throws after maxRetries', async () => {
    sendMock.mockRejectedValue(new Error('ETIMEDOUT'));
    await expect(sendWithRetry(args, { maxRetries: 2, baseDelayMs: 0 })).rejects.toThrow();
    expect(sendMock).toHaveBeenCalledTimes(2);
  });
});
```

- [ ] **Step 2: Run the test, verify it fails**

Run: `cd landing && npx vitest run src/test/send-email.test.ts`
Expected: FAIL — cannot resolve `../lib/send-email`.

- [ ] **Step 3: Implement `send-email.ts`**

Create `landing/src/lib/send-email.ts`:

```ts
import { Resend } from 'resend';
import type { ReactElement } from 'react';

export interface SendArgs {
  apiKey: string;
  from: string;
  to: string;
  subject: string;
  react: ReactElement;
  idempotencyKey: string;
}

// Transient Resend error names that are worth retrying.
const RETRYABLE_NAMES = new Set([
  'rate_limit_exceeded',
  'internal_server_error',
  'application_error',
]);

const sleep = (ms: number) => new Promise<void>((r) => setTimeout(r, ms));

function withTimeout<T>(p: Promise<T>, ms: number): Promise<T> {
  return Promise.race([
    p,
    new Promise<T>((_, reject) => setTimeout(() => reject(new Error('send timeout')), ms)),
  ]);
}

export async function sendWithRetry(
  args: SendArgs,
  opts: { maxRetries?: number; baseDelayMs?: number } = {},
): Promise<void> {
  const maxRetries = opts.maxRetries ?? 3;
  const baseDelayMs = opts.baseDelayMs ?? 1000;
  const resend = new Resend(args.apiKey);

  for (let attempt = 0; attempt < maxRetries; attempt++) {
    const last = attempt === maxRetries - 1;
    try {
      const { error } = await withTimeout(
        resend.emails.send(
          { from: args.from, to: args.to, subject: args.subject, react: args.react },
          { idempotencyKey: args.idempotencyKey },
        ),
        15000,
      );
      if (error) {
        const retryable = RETRYABLE_NAMES.has((error as { name?: string }).name ?? '');
        if (retryable && !last) {
          await sleep(baseDelayMs * 2 ** attempt + Math.random() * 250);
          continue;
        }
        throw new Error(`Resend send failed: ${(error as { name?: string }).name ?? 'error'}`);
      }
      return; // success
    } catch (e) {
      if (!last) {
        await sleep(baseDelayMs * 2 ** attempt + Math.random() * 250);
        continue;
      }
      throw e;
    }
  }
}
```

- [ ] **Step 4: Run the test, verify it passes**

Run: `cd landing && npx vitest run src/test/send-email.test.ts`
Expected: PASS (4 tests).

- [ ] **Step 5: Commit**

```bash
git add landing/src/lib/send-email.ts landing/src/test/send-email.test.ts
git commit -m "feat(landing): sendWithRetry — idempotent Resend send with backoff + timeout"
```

---

## Task 4: Premium confirmation email template (`waitlist-confirm.tsx`)

**Files:**
- Create: `landing/emails/waitlist-confirm.tsx`
- Test: `landing/src/test/waitlist-confirm.test.ts`
- Modify: `landing/package.json` (add `react-email` dep + `email` preview script)

**Interfaces:**
- Produces: default export `WaitlistConfirmEmail` (and named export) — props `{ confirmUrl: string; locale: 'en' | 'es' }`

- [ ] **Step 1: Install react-email and add the preview script**

Run: `cd landing && npm install react-email`
Then add to `landing/package.json` `scripts`:

```json
    "email": "email dev --dir emails --port 3000"
```

- [ ] **Step 2: Write the failing test**

Create `landing/src/test/waitlist-confirm.test.ts`:

```ts
import { describe, it, expect } from 'vitest';
import { render } from 'react-email';
import { WaitlistConfirmEmail } from '../../emails/waitlist-confirm';
import { createElement } from 'react';

describe('WaitlistConfirmEmail', () => {
  it('renders the confirm URL and an English CTA', async () => {
    const html = await render(
      createElement(WaitlistConfirmEmail, { confirmUrl: 'https://x.test/c?token=abc', locale: 'en' }),
    );
    expect(html).toContain('https://x.test/c?token=abc');
    expect(html).toContain('Confirm');
    expect(html).toContain('lang="en"');
  });

  it('renders Spanish copy when locale is es', async () => {
    const html = await render(
      createElement(WaitlistConfirmEmail, { confirmUrl: 'https://x.test/c?token=abc', locale: 'es' }),
    );
    expect(html).toContain('Confirma');
    expect(html).toContain('lang="es"');
  });
});
```

- [ ] **Step 3: Run the test, verify it fails**

Run: `cd landing && npx vitest run src/test/waitlist-confirm.test.ts`
Expected: FAIL — cannot resolve `../../emails/waitlist-confirm`.

- [ ] **Step 4: Implement `waitlist-confirm.tsx`**

Create `landing/emails/waitlist-confirm.tsx`:

```tsx
import {
  Html,
  Head,
  Preview,
  Body,
  Container,
  Section,
  Heading,
  Text,
  Button,
  Link,
  Hr,
  Tailwind,
  pixelBasedPreset,
} from 'react-email';

export interface WaitlistConfirmEmailProps {
  confirmUrl: string;
  locale: 'en' | 'es';
}

const copy = {
  en: {
    preview: 'Confirm your email to join the BulkUp waitlist',
    heading: 'Confirm your email',
    body: "You're one tap away from the BulkUp early-access list. Confirm your email and we'll let you know the moment we launch.",
    cta: 'Confirm my email',
    fallback: 'Button not working? Paste this link into your browser:',
    footer: 'This link expires in 48 hours. If you didn’t request this, you can safely ignore this email.',
  },
  es: {
    preview: 'Confirma tu correo para unirte a la lista de BulkUp',
    heading: 'Confirma tu correo',
    body: 'Estás a un toque de la lista de acceso anticipado de BulkUp. Confirma tu correo y te avisaremos en cuanto lancemos.',
    cta: 'Confirmar mi correo',
    fallback: '¿No funciona el botón? Pega este enlace en tu navegador:',
    footer: 'Este enlace caduca en 48 horas. Si no lo solicitaste, puedes ignorar este correo.',
  },
} as const;

export function WaitlistConfirmEmail({ confirmUrl, locale }: WaitlistConfirmEmailProps) {
  const t = copy[locale] ?? copy.en;
  return (
    <Html lang={locale}>
      <Tailwind
        config={{
          presets: [pixelBasedPreset],
          theme: {
            extend: {
              colors: {
                lime: '#94c51d',
                limeDeep: '#7da817',
                graphite: '#111827',
                muted: '#6b7280',
                fog: '#f5f5f5',
                line: '#e5e7eb',
              },
              fontFamily: {
                sans: ['"Nunito Sans"', 'Helvetica', 'Arial', 'sans-serif'],
              },
            },
          },
        }}
      >
        <Head />
        <Body className="bg-white font-sans">
          <Preview>{t.preview}</Preview>
          <Container className="mx-auto my-[40px] max-w-[600px] rounded-[26px] border border-solid border-line bg-white p-[40px]">
            <Text className="m-0 text-[20px] font-extrabold tracking-tight text-graphite">
              Bulk<span className="text-lime">Up</span>
            </Text>

            <Heading as="h1" className="mb-[8px] mt-[28px] text-[28px] font-extrabold leading-[1.15] tracking-tight text-graphite">
              {t.heading}
            </Heading>
            <Text className="mb-[28px] mt-0 text-[16px] leading-[1.6] text-muted">
              {t.body}
            </Text>

            <Section className="mb-[28px]">
              <Button
                href={confirmUrl}
                className="box-border inline-block rounded-[16px] bg-lime px-[28px] py-[14px] text-[16px] font-bold text-graphite no-underline"
              >
                {t.cta}
              </Button>
            </Section>

            <Text className="mb-[6px] mt-0 text-[13px] leading-[1.5] text-muted">{t.fallback}</Text>
            <Link href={confirmUrl} className="text-[13px] text-limeDeep underline">
              {confirmUrl}
            </Link>

            <Hr className="my-[28px] border-none border-t border-solid border-line" />
            <Text className="m-0 text-[12px] leading-[1.5] text-muted">{t.footer}</Text>
          </Container>
        </Body>
      </Tailwind>
    </Html>
  );
}

WaitlistConfirmEmail.PreviewProps = {
  confirmUrl: 'https://getbulkup.com/api/waitlist/confirm?token=preview',
  locale: 'en',
} satisfies WaitlistConfirmEmailProps;

export default WaitlistConfirmEmail;
```

- [ ] **Step 5: Run the test, verify it passes**

Run: `cd landing && npx vitest run src/test/waitlist-confirm.test.ts`
Expected: PASS (2 tests). If `render` is not exported from `react-email`, import it from `@react-email/render` instead and adjust the test import — verify the installed package's exports first.

- [ ] **Step 6: Commit**

```bash
git add landing/emails/waitlist-confirm.tsx landing/src/test/waitlist-confirm.test.ts landing/package.json landing/package-lock.json
git commit -m "feat(landing): premium bilingual waitlist confirmation email template"
```

---

## Task 5: Rework `POST /api/waitlist` to send the confirm email

**Files:**
- Modify: `landing/src/pages/api/waitlist.ts` (full rewrite of the handler body)

**Interfaces:**
- Consumes: `validateWaitlist` (existing), `checkWaitlistRateLimit` (Task 2), `signWaitlistToken` (Task 1), `sendWithRetry` (Task 3), `WaitlistConfirmEmail` (Task 4)

- [ ] **Step 1: Rewrite the route**

Replace the entire contents of `landing/src/pages/api/waitlist.ts` with:

```ts
import type { APIRoute } from 'astro';
import crypto from 'node:crypto';
import { createElement } from 'react';
import { validateWaitlist } from '../../lib/waitlist';
import { checkWaitlistRateLimit } from '../../lib/ratelimit';
import { signWaitlistToken } from '../../lib/waitlist-token';
import { sendWithRetry } from '../../lib/send-email';
import { WaitlistConfirmEmail } from '../../../emails/waitlist-confirm';

export const prerender = false;

const FROM = 'BulkUp <waitlist@getbulkup.com>';
const SUBJECT = {
  en: 'Confirm your email — BulkUp',
  es: 'Confirma tu correo — BulkUp',
} as const;

export const POST: APIRoute = async ({ request }) => {
  let body: Record<string, string> = {};
  const ct = request.headers.get('content-type') ?? '';
  try {
    if (ct.includes('application/json')) body = await request.json();
    else body = Object.fromEntries((await request.formData()) as any);
  } catch {
    return json({ ok: false, reason: 'invalid' }, 400);
  }

  const localeRaw = String(body.locale ?? 'en');
  const locale = localeRaw === 'es' ? 'es' : 'en';

  const result = validateWaitlist({
    email: String(body.email ?? ''),
    locale,
    honeypot: String(body.website ?? ''),
  });
  if (!result.ok) {
    if (result.reason === 'spam') return json({ ok: true }, 200); // no signal to bots
    return json({ ok: false, reason: 'invalid' }, 400);
  }

  const ip = request.headers.get('x-forwarded-for')?.split(',')[0]?.trim() || 'unknown';
  const rl = await checkWaitlistRateLimit(ip, result.email);
  if (!rl.success) return json({ ok: false, reason: 'rate_limited' }, 429);

  const apiKey = import.meta.env.RESEND_API_KEY;
  if (!apiKey) return json({ ok: false, reason: 'server' }, 500);

  try {
    const token = signWaitlistToken(result.email, locale);
    const origin = new URL(request.url).origin;
    const confirmUrl = `${origin}/api/waitlist/confirm?token=${encodeURIComponent(token)}`;
    const idempotencyKey = 'wl-' + crypto.createHash('sha256').update(token).digest('hex');

    await sendWithRetry({
      apiKey,
      from: FROM,
      to: result.email,
      subject: SUBJECT[locale],
      react: createElement(WaitlistConfirmEmail, { confirmUrl, locale }),
      idempotencyKey,
    });
    return json({ ok: true }, 200);
  } catch (e) {
    console.error('waitlist send error', e);
    return json({ ok: false, reason: 'server' }, 500);
  }
};

function json(data: unknown, status: number) {
  return new Response(JSON.stringify(data), {
    status,
    headers: { 'content-type': 'application/json' },
  });
}
```

- [ ] **Step 2: Build to verify it compiles**

Run: `cd landing && npm run build`
Expected: build completes (the route imports the libs + the email template and typechecks). The pre-existing Node-version warning is fine.

- [ ] **Step 3: Run the full test suite**

Run: `cd landing && npm test`
Expected: all tests pass (existing waitlist + token + ratelimit + send-email + email template).

- [ ] **Step 4: Commit**

```bash
git add landing/src/pages/api/waitlist.ts
git commit -m "feat(landing): waitlist POST sends double opt-in confirmation email"
```

---

## Task 6: Confirm route + success page

**Files:**
- Create: `landing/src/pages/api/waitlist/confirm.ts`
- Create: `landing/src/components/Confirmed.astro`
- Create: `landing/src/pages/waitlist/confirmed.astro`
- Create: `landing/src/pages/es/waitlist/confirmed.astro`

**Interfaces:**
- Consumes: `verifyWaitlistToken` (Task 1)

- [ ] **Step 1: Create the confirm API route**

Create `landing/src/pages/api/waitlist/confirm.ts`:

```ts
import type { APIRoute } from 'astro';
import { Resend } from 'resend';
import { verifyWaitlistToken } from '../../../lib/waitlist-token';

export const prerender = false;

function dest(origin: string, locale: string, expired: boolean): string {
  const prefix = locale === 'es' ? '/es' : '';
  const q = expired ? '?expired=1' : '';
  return `${origin}${prefix}/waitlist/confirmed${q}`;
}

export const GET: APIRoute = async ({ request }) => {
  const origin = new URL(request.url).origin;
  const token = new URL(request.url).searchParams.get('token') ?? '';
  const result = verifyWaitlistToken(token);

  if (!result.ok) {
    return Response.redirect(dest(origin, 'en', true), 302);
  }

  const apiKey = import.meta.env.RESEND_API_KEY;
  if (apiKey) {
    try {
      const resend = new Resend(apiKey);
      // Idempotent: re-confirming or an existing contact both land on success.
      const { error } = await resend.contacts.create({ email: result.email, unsubscribed: false });
      if (error) console.error('waitlist confirm contact error', error);
    } catch (e) {
      console.error('waitlist confirm threw', e);
    }
  }
  return Response.redirect(dest(origin, result.locale, false), 302);
};
```

- [ ] **Step 2: Create the shared success component**

First check `landing/src/layouts/` for an existing base layout (e.g. `Base.astro` / `Layout.astro`). If one exists, wrap the markup below in it (passing a title). If not, render a minimal standalone `<html>` as shown.

Create `landing/src/components/Confirmed.astro`:

```astro
---
interface Props { locale: 'en' | 'es'; expired: boolean; }
const { locale, expired } = Astro.props;

const t = {
  en: {
    okTitle: "You're on the list 🎉",
    okBody: "Thanks for confirming. We'll email you the moment BulkUp opens.",
    expTitle: 'This link expired',
    expBody: 'Confirmation links last 48 hours. Head back and join the waitlist again.',
    cta: 'Back to BulkUp',
    home: '/',
  },
  es: {
    okTitle: '¡Estás dentro! 🎉',
    okBody: 'Gracias por confirmar. Te avisaremos en cuanto BulkUp abra.',
    expTitle: 'Este enlace caducó',
    expBody: 'Los enlaces de confirmación duran 48 horas. Vuelve y únete a la lista otra vez.',
    cta: 'Volver a BulkUp',
    home: '/es',
  },
}[locale];

const title = expired ? t.expTitle : t.okTitle;
const bodyText = expired ? t.expBody : t.okBody;
---
<main class="min-h-screen grid place-items-center bg-bg px-6 text-center">
  <div class="max-w-md w-full rounded-[26px] border border-line bg-surface-2 p-10">
    <p class="text-xl font-extrabold tracking-tight text-fg">Bulk<span class="text-accent">Up</span></p>
    <h1 class="mt-6 text-3xl font-extrabold tracking-tight text-fg">{title}</h1>
    <p class="mt-3 text-muted">{bodyText}</p>
    <a href={t.home} class="press mt-8 inline-block rounded-[16px] bg-accent px-7 py-3 font-bold text-ink no-underline">
      {t.cta}
    </a>
  </div>
</main>
```

(If a base layout exists, render this `<main>` inside it instead of relying on a bare fragment — the page files below decide.)

- [ ] **Step 3: Create the two locale pages**

Create `landing/src/pages/waitlist/confirmed.astro`:

```astro
---
import Confirmed from '../../components/Confirmed.astro';
const expired = Astro.url.searchParams.get('expired') === '1';
// Use the site's existing base layout if there is one (check src/layouts/).
---
<html lang="en">
  <head><meta charset="utf-8" /><meta name="viewport" content="width=device-width" /><title>BulkUp</title></head>
  <body>
    <Confirmed locale="en" expired={expired} />
  </body>
</html>
```

Create `landing/src/pages/es/waitlist/confirmed.astro`:

```astro
---
import Confirmed from '../../../components/Confirmed.astro';
const expired = Astro.url.searchParams.get('expired') === '1';
---
<html lang="es">
  <head><meta charset="utf-8" /><meta name="viewport" content="width=device-width" /><title>BulkUp</title></head>
  <body>
    <Confirmed locale="es" expired={expired} />
  </body>
</html>
```

If the project has a shared layout (e.g. `src/layouts/Base.astro`) and the existing pages use it, prefer importing and using it in both page files (passing `title="BulkUp"`) instead of the bare `<html>` above — match the existing pages' pattern so global CSS/fonts load. The `bg-bg`, `text-fg`, `bg-accent`, `text-ink`, `border-line`, `bg-surface-2`, `text-muted`, `press` classes come from the existing Tailwind theme in `src/styles/global.css`; ensure global CSS is included (the layout normally does this).

- [ ] **Step 4: Build to verify**

Run: `cd landing && npm run build`
Expected: build completes; the new API route and both pages are emitted (`/waitlist/confirmed`, `/es/waitlist/confirmed`, `/api/waitlist/confirm`).

- [ ] **Step 5: Run the full suite**

Run: `cd landing && npm test`
Expected: all tests pass.

- [ ] **Step 6: Commit**

```bash
git add landing/src/pages/api/waitlist/confirm.ts landing/src/components/Confirmed.astro landing/src/pages/waitlist/confirmed.astro landing/src/pages/es/waitlist/confirmed.astro
git commit -m "feat(landing): waitlist confirm route + bilingual success page"
```

---

## Task 7: Docs — README env vars

**Files:**
- Modify: `landing/README.md`

- [ ] **Step 1: Document the new env vars**

In `landing/README.md`, update the Develop step and the Deploy env list to include the new vars. Change the develop comment to mention the secret, and the deploy env list to:

```
- Add env vars `RESEND_API_KEY`, `WAITLIST_TOKEN_SECRET`, `UPSTASH_REDIS_REST_URL`, `UPSTASH_REDIS_REST_TOKEN`.
```

Add a one-line note: `Waitlist uses double opt-in — sends a confirmation email; the contact is added to Resend only after the user confirms. Sender domain (getbulkup.com) must be verified in Resend.`

- [ ] **Step 2: Commit**

```bash
git add landing/README.md
git commit -m "docs(landing): document waitlist env vars + double opt-in flow"
```

---

## Self-Review

**Spec coverage:**
- Signed token → Task 1. Rate limiting → Task 2. Reliable send (idempotency/retry/timeout) → Task 3. Premium bilingual email → Task 4. POST sends confirm + no enumeration → Task 5. Confirm route + success page (+ expired state) → Task 6. Env docs → Task 7. ✓
- Double opt-in (contact added only on confirm) → Task 5 (no contact create) + Task 6 (create on confirm). ✓
- Security checklist items all map to Tasks 1/2/3/5/6. ✓

**Placeholder scan:** No TBD/TODO. The "check for an existing layout" notes in Task 6 are verification instructions with a concrete fallback (bare `<html>`), not placeholders. Each code step shows complete code.

**Type consistency:** `signWaitlistToken`/`verifyWaitlistToken`, `checkWaitlistRateLimit`, `sendWithRetry`/`SendArgs`, `WaitlistConfirmEmail({confirmUrl, locale})` are referenced with identical signatures across tasks. `idempotencyKey` passed as `{ idempotencyKey }` (resend v6) consistently. Confirm-URL origin derivation matches between Task 5 (build) and Task 6 (redirect).

**Verification reality:** unlike the iOS work, `landing` builds and tests here — every task ends in a real `npx vitest run` and/or `npm run build`.
