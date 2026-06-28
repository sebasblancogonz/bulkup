import crypto from 'node:crypto';

function getSecret(): string {
  const s =
    import.meta.env.WAITLIST_TOKEN_SECRET ?? process.env.WAITLIST_TOKEN_SECRET;
  if (!s) throw new Error('WAITLIST_TOKEN_SECRET is not set');
  return s;
}

function b64url(buf: Buffer): string {
  return buf.toString('base64').replace(/\+/g, '-').replace(/\//g, '_').replace(/=+$/, '');
}
function fromB64url(s: string): Buffer {
  return Buffer.from(s.replace(/-/g, '+').replace(/_/g, '/'), 'base64');
}

interface Payload {
  e: string; // email
  l: string; // locale
  x: number; // expiry, epoch seconds
}

export function signWaitlistToken(email: string, locale: string, ttlSeconds = 60 * 60 * 48): string {
  const payload: Payload = {
    e: email,
    l: locale,
    x: Math.floor(Date.now() / 1000) + ttlSeconds,
  };
  const body = b64url(Buffer.from(JSON.stringify(payload)));
  const sig = b64url(crypto.createHmac('sha256', getSecret()).update(body).digest());
  return `${body}.${sig}`;
}

export type VerifyResult = { ok: true; email: string; locale: string } | { ok: false };

export function verifyWaitlistToken(token: string): VerifyResult {
  if (typeof token !== 'string') return { ok: false };
  const parts = token.split('.');
  if (parts.length !== 2 || !parts[0] || !parts[1]) return { ok: false };
  const [body, sig] = parts;

  let expBuf: Buffer;
  try {
    expBuf = crypto.createHmac('sha256', getSecret()).update(body).digest();
  } catch {
    return { ok: false };
  }
  const sigBuf = fromB64url(sig);
  if (sigBuf.length !== expBuf.length || !crypto.timingSafeEqual(sigBuf, expBuf)) {
    return { ok: false };
  }

  try {
    const payload = JSON.parse(fromB64url(body).toString('utf8')) as Payload;
    if (typeof payload.e !== 'string' || typeof payload.l !== 'string' || typeof payload.x !== 'number') {
      return { ok: false };
    }
    if (payload.x < Math.floor(Date.now() / 1000)) return { ok: false };
    return { ok: true, email: payload.e, locale: payload.l };
  } catch {
    return { ok: false };
  }
}
