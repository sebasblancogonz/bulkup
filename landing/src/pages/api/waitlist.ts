import type { APIRoute } from 'astro';
import crypto from 'node:crypto';
import { createElement } from 'react';
import { validateWaitlist } from '../../lib/waitlist';
import { checkWaitlistRateLimit } from '../../lib/ratelimit';
import { signWaitlistToken } from '../../lib/waitlist-token';
import { sendWithRetry } from '../../lib/send-email';
import { WaitlistConfirmEmail } from '../../../emails/waitlist-confirm';

export const prerender = false;

// Configurable sender (must be a verified Resend domain); falls back to the brand default.
const FROM =
  import.meta.env.RESEND_FROM ?? process.env.RESEND_FROM ?? 'BulkUp <waitlist@getbulkup.com>';
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
    honeypot: String(body.website ?? ''), // hidden field named "website"
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

  // Double opt-in: send a confirmation email. The contact is created only after the
  // user confirms (see api/waitlist/confirm.ts). No contact is created here.
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
