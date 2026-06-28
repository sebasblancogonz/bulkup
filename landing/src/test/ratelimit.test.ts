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
