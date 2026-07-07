import { describe, it, expect, vi, beforeEach } from 'vitest';

// Mock the resend module: Resend().emails.send is controlled per-test.
const sendMock = vi.fn();
vi.mock('resend', () => ({
  Resend: vi.fn().mockImplementation(() => ({ emails: { send: sendMock } })),
}));

import { sendWithRetry } from '../lib/send-email';
import { createElement } from 'react';

const args = {
  apiKey: 'k',
  from: 'BulkUp <waitlist@getbulkup.com>',
  to: 'a@b.com',
  subject: 'Confirm',
  react: createElement('div', null, 'hi'),
  idempotencyKey: 'wl-abc',
};

beforeEach(() => { sendMock.mockReset(); });

describe('sendWithRetry', () => {
  it('passes the idempotency key and resolves on success', async () => {
    sendMock.mockResolvedValueOnce({ data: { id: '1' }, error: null });
    await sendWithRetry(args, { baseDelayMs: 0 });
    expect(sendMock).toHaveBeenCalledTimes(1);
    expect(sendMock.mock.calls[0][1]).toEqual({ idempotencyKey: 'wl-abc' });
  });

  it('retries on a transient error then succeeds', async () => {
    sendMock
      .mockResolvedValueOnce({ data: null, error: { name: 'rate_limit_exceeded', message: 'slow down' } })
      .mockResolvedValueOnce({ data: { id: '1' }, error: null });
    await sendWithRetry(args, { maxRetries: 3, baseDelayMs: 0 });
    expect(sendMock).toHaveBeenCalledTimes(2);
  });

  it('does NOT retry a permanent error and throws', async () => {
    sendMock.mockResolvedValue({ data: null, error: { name: 'validation_error', message: 'bad from' } });
    await expect(sendWithRetry(args, { maxRetries: 3, baseDelayMs: 0 })).rejects.toThrow();
    expect(sendMock).toHaveBeenCalledTimes(1);
  });

  it('retries on a thrown network error then throws after maxRetries', async () => {
    sendMock.mockRejectedValue(new Error('ETIMEDOUT'));
    await expect(sendWithRetry(args, { maxRetries: 2, baseDelayMs: 0 })).rejects.toThrow();
    expect(sendMock).toHaveBeenCalledTimes(2);
  });
});
