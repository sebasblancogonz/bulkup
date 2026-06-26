import type { APIRoute } from 'astro';
import { Resend } from 'resend';
import { validateWaitlist } from '../../lib/waitlist';
import { welcomeEmail } from '../../lib/welcome-email';

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

  const locale = String(body.locale ?? 'en');
  const result = validateWaitlist({
    email: String(body.email ?? ''),
    locale,
    honeypot: String(body.website ?? ''), // hidden field named "website"
  });

  if (!result.ok) {
    // Spam: pretend success so bots get no signal.
    if (result.reason === 'spam') return json({ ok: true }, 200);
    return json({ ok: false, reason: 'invalid' }, 400);
  }

  const apiKey = import.meta.env.RESEND_API_KEY;
  const audienceId = import.meta.env.RESEND_AUDIENCE_ID;
  const from = import.meta.env.RESEND_FROM;
  if (!apiKey || !audienceId || !from) {
    console.error('waitlist misconfigured: missing RESEND_API_KEY, RESEND_AUDIENCE_ID or RESEND_FROM');
    return json({ ok: false, reason: 'server' }, 500);
  }

  const resend = new Resend(apiKey);

  // 1) Add the contact to the Resend audience. The SDK returns { data, error }
  //    instead of throwing, so we must inspect `error` explicitly.
  const contact = await resend.contacts.create({ email: result.email, audienceId, unsubscribed: false });
  if (contact.error) {
    console.error('waitlist contacts.create error', contact.error);
    return json({ ok: false, reason: 'server' }, 500);
  }

  // 2) Send the welcome email. Best-effort: a delivery hiccup must not lose a
  //    signup that already landed in the audience, so we log and still return ok.
  const email = welcomeEmail(locale);
  const sent = await resend.emails.send({
    from,
    to: result.email,
    subject: email.subject,
    html: email.html,
    text: email.text,
  });
  if (sent.error) console.error('waitlist emails.send error', sent.error);

  return json({ ok: true }, 200);
};

function json(data: unknown, status: number) {
  return new Response(JSON.stringify(data), { status, headers: { 'content-type': 'application/json' } });
}
