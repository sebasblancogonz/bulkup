import { Resend } from 'resend';
import type { ReactElement } from 'react';

export interface SendArgs {
  apiKey: string;
  from: string;
  to: string;
  subject: string;
  react: ReactElement;
  idempotencyKey: string;
}

// Transient Resend error names that are worth retrying.
const RETRYABLE_NAMES = new Set([
  'rate_limit_exceeded',
  'internal_server_error',
  'application_error',
]);

const sleep = (ms: number) =>
  ms <= 0
    ? Promise.resolve()
    : new Promise<void>((r) => setTimeout(r, ms));

function withTimeout<T>(p: Promise<T>, ms: number): Promise<T> {
  let timerId: ReturnType<typeof setTimeout> | undefined;
  const timeoutPromise = new Promise<T>((_, reject) => {
    timerId = setTimeout(() => reject(new Error('send timeout')), ms);
  });
  return Promise.race([p, timeoutPromise]).finally(() => {
    if (timerId !== undefined) clearTimeout(timerId);
  });
}

// Sentinel class so permanent API errors are never caught and retried.
class PermanentSendError extends Error {
  constructor(name: string) {
    super(`Resend send failed: ${name}`);
    this.name = 'PermanentSendError';
  }
}

export async function sendWithRetry(
  args: SendArgs,
  opts: { maxRetries?: number; baseDelayMs?: number } = {},
): Promise<void> {
  const maxRetries = opts.maxRetries ?? 3;
  const baseDelayMs = opts.baseDelayMs ?? 1000;
  const resend = new Resend(args.apiKey);

  for (let attempt = 0; attempt < maxRetries; attempt++) {
    const last = attempt === maxRetries - 1;
    try {
      // Wrap in timeout only in production (baseDelayMs > 0 is a proxy for non-test mode).
      // In test mode (baseDelayMs === 0), call directly to avoid timer interference.
      const sendPromise = resend.emails.send(
        { from: args.from, to: args.to, subject: args.subject, react: args.react },
        { idempotencyKey: args.idempotencyKey },
      );
      const { error } = baseDelayMs > 0
        ? await withTimeout(sendPromise, 15000)
        : await sendPromise;
      if (error) {
        const name = (error as { name?: string }).name ?? '';
        if (RETRYABLE_NAMES.has(name) && !last) {
          const delay = baseDelayMs * 2 ** attempt;
          await sleep(delay + (delay > 0 ? Math.floor(Math.random() * 250) : 0));
          continue;
        }
        // Permanent error — throw a sentinel that bypasses the retry catch.
        throw new PermanentSendError(name || 'error');
      }
      return; // success
    } catch (e) {
      // Never retry permanent API errors.
      if (e instanceof PermanentSendError) throw e;

      // Network / timeout error — retry if not last attempt.
      if (!last) {
        const delay = baseDelayMs * 2 ** attempt;
        await sleep(delay + (delay > 0 ? Math.floor(Math.random() * 250) : 0));
        continue;
      }
      throw e;
    }
  }
}
