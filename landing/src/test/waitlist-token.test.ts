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

  it('rejects a valid-length but wrong signature', () => {
    const a = signWaitlistToken('a@b.com', 'en');
    const b = signWaitlistToken('c@d.com', 'en'); // different signature, same length
    const forged = `${a.split('.')[0]}.${b.split('.')[1]}`;
    expect(verifyWaitlistToken(forged)).toEqual({ ok: false });
  });

  it('rejects malformed input', () => {
    expect(verifyWaitlistToken('garbage')).toEqual({ ok: false });
    expect(verifyWaitlistToken('')).toEqual({ ok: false });
    expect(verifyWaitlistToken('a.b.c')).toEqual({ ok: false });
  });
});
