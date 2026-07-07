export type WaitlistInput = { email: string; locale?: string; honeypot?: string };
export type WaitlistResult = { ok: true; email: string } | { ok: false; reason: 'invalid' | 'spam' };

const EMAIL_RE = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

export function isValidEmail(email: string): boolean {
  return EMAIL_RE.test(email.trim());
}

export function validateWaitlist(input: WaitlistInput): WaitlistResult {
  if (input.honeypot && input.honeypot.trim() !== '') return { ok: false, reason: 'spam' };
  const email = input.email.trim().toLowerCase();
  if (!isValidEmail(email)) return { ok: false, reason: 'invalid' };
  return { ok: true, email };
}
