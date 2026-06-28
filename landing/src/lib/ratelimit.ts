import { Ratelimit } from '@upstash/ratelimit';
import { Redis } from '@upstash/redis';

let ipLimiter: Ratelimit | null = null;
let emailLimiter: Ratelimit | null = null;
let initialized = false;

function init(): void {
  if (initialized) return;
  initialized = true;
  // Accept both the native Upstash names and Vercel KV's auto-injected names.
  // KV_REST_API_TOKEN is the READ-WRITE token (rate limiting writes counters) —
  // NOT KV_REST_API_READ_ONLY_TOKEN. (Static import.meta.env refs so Vite inlines
  // them; process.env is the runtime fallback on Vercel.)
  const url =
    import.meta.env.UPSTASH_REDIS_REST_URL ?? process.env.UPSTASH_REDIS_REST_URL ??
    import.meta.env.KV_REST_API_URL ?? process.env.KV_REST_API_URL;
  const token =
    import.meta.env.UPSTASH_REDIS_REST_TOKEN ?? process.env.UPSTASH_REDIS_REST_TOKEN ??
    import.meta.env.KV_REST_API_TOKEN ?? process.env.KV_REST_API_TOKEN;
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
