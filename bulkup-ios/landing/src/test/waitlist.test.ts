import { describe, it, expect } from 'vitest';
import { isValidEmail, validateWaitlist } from '../lib/waitlist';

describe('isValidEmail', () => {
  it('accepts normal emails', () => expect(isValidEmail('a@b.com')).toBe(true));
  it('rejects junk', () => {
    expect(isValidEmail('nope')).toBe(false);
    expect(isValidEmail('a@b')).toBe(false);
    expect(isValidEmail('')).toBe(false);
  });
});

describe('validateWaitlist', () => {
  it('normalizes good email', () => {
    expect(validateWaitlist({ email: '  ME@Mail.COM ' })).toEqual({ ok: true, email: 'me@mail.com' });
  });
  it('flags invalid', () => {
    expect(validateWaitlist({ email: 'bad' })).toEqual({ ok: false, reason: 'invalid' });
  });
  it('flags honeypot as spam', () => {
    expect(validateWaitlist({ email: 'a@b.com', honeypot: 'bot' })).toEqual({ ok: false, reason: 'spam' });
  });
});
