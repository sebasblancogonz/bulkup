import type { APIRoute } from 'astro';
import { Resend } from 'resend';
import { validateWaitlist } from '../../lib/waitlist';

export const prerender = false;

export const POST: APIRoute = async ({ request }) => {
  let body: Record<string, string> = {};
  const ct = request.headers.get('content-type') ?? '';
  try {
    if (ct.includes('application/json')) body = await request.json();
    else body = Object.fromEntries((await request.formData()) as any);
  } catch {
    return json({ ok: false, reason: 'invalid' }, 400);
  }

  const result = validateWaitlist({
    email: String(body.email ?? ''),
    locale: String(body.locale ?? 'en'),
    honeypot: String(body.website ?? ''), // hidden field named "website"
  });

  if (!result.ok) {
    // Spam: pretend success so bots get no signal.
    if (result.reason === 'spam') return json({ ok: true }, 200);
    return json({ ok: false, reason: 'invalid' }, 400);
  }

  const apiKey = import.meta.env.RESEND_API_KEY;
  const audienceId = import.meta.env.RESEND_AUDIENCE_ID;
  if (!apiKey || !audienceId) return json({ ok: false, reason: 'server' }, 500);

  try {
    const resend = new Resend(apiKey);
    await resend.contacts.create({ email: result.email, audienceId, unsubscribed: false });
    return json({ ok: true }, 200);
  } catch (e) {
    console.error('waitlist resend error', e);
    return json({ ok: false, reason: 'server' }, 500);
  }
};

function json(data: unknown, status: number) {
  return new Response(JSON.stringify(data), { status, headers: { 'content-type': 'application/json' } });
}
