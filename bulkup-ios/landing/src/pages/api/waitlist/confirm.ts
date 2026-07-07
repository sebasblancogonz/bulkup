import type { APIRoute } from 'astro';
import { Resend } from 'resend';
import { verifyWaitlistToken } from '../../../lib/waitlist-token';
import { publicOrigin } from '../../../lib/origin';

export const prerender = false;

function dest(origin: string, locale: string, expired: boolean): string {
  const prefix = locale === 'es' ? '/es' : '';
  const q = expired ? '?expired=1' : '';
  return `${origin}${prefix}/waitlist/confirmed${q}`;
}

export const GET: APIRoute = async ({ request, site }) => {
  const origin = publicOrigin({ site, request, isDev: import.meta.env.DEV });
  const token = new URL(request.url).searchParams.get('token') ?? '';
  const result = verifyWaitlistToken(token);

  if (!result.ok) {
    return Response.redirect(dest(origin, 'en', true), 302);
  }

  const apiKey = import.meta.env.RESEND_API_KEY;
  if (apiKey) {
    try {
      const resend = new Resend(apiKey);
      // Optional: bucket the confirmed signup into a Resend Segment.
      const segmentId = import.meta.env.RESEND_SEGMENT_ID ?? process.env.RESEND_SEGMENT_ID;
      // Idempotent: re-confirming or an existing contact both land on success.
      const { error } = await resend.contacts.create({
        email: result.email,
        unsubscribed: false,
        ...(segmentId ? { segments: [{ id: segmentId }] } : {}),
      });
      if (error) console.error('waitlist confirm contact error', error);
    } catch (e) {
      console.error('waitlist confirm threw', e);
    }
  }
  return Response.redirect(dest(origin, result.locale, false), 302);
};
