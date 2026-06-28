import { describe, it, expect } from 'vitest';
import { publicOrigin } from '../lib/origin';

const req = (url: string) => new Request(url);

describe('publicOrigin', () => {
  it('uses the configured site origin in production (request.url is internal on Vercel)', () => {
    expect(
      publicOrigin({
        site: new URL('https://getbulkup.com'),
        request: req('https://localhost/api/waitlist/confirm?token=abc'),
        isDev: false,
      }),
    ).toBe('https://getbulkup.com');
  });

  it('uses the request origin in dev so local testing works', () => {
    expect(
      publicOrigin({
        site: new URL('https://getbulkup.com'),
        request: req('http://localhost:4321/api/waitlist'),
        isDev: true,
      }),
    ).toBe('http://localhost:4321');
  });

  it('falls back to the request origin when site is undefined in production', () => {
    expect(
      publicOrigin({
        site: undefined,
        request: req('https://example.com/api/waitlist'),
        isDev: false,
      }),
    ).toBe('https://example.com');
  });
});
