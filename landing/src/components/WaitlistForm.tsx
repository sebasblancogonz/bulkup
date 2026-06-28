import { useState, type FormEvent } from 'react';

type Props = {
  locale: string; ctaLabel: string; placeholder: string;
  successMsg: string; errorMsg: string; invalidMsg: string;
  loadingMsg?: string; rateMsg?: string;
  reassure?: string; id?: string;
};

export default function WaitlistForm({
  locale, ctaLabel, placeholder, successMsg, errorMsg, invalidMsg,
  loadingMsg, rateMsg, reassure, id,
}: Props) {
  const [email, setEmail] = useState('');
  const [state, setState] = useState<'idle' | 'loading' | 'success' | 'error' | 'rate' | 'invalid'>('idle');

  async function onSubmit(e: FormEvent) {
    e.preventDefault();
    const honeypot = (e.currentTarget as HTMLFormElement).website?.value ?? '';
    if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email.trim())) { setState('invalid'); return; }
    if (state === 'loading') return; // idempotency: ignore double-submits
    setState('loading');
    try {
      const res = await fetch('/api/waitlist', {
        method: 'POST', headers: { 'content-type': 'application/json' },
        body: JSON.stringify({ email, locale, website: honeypot }),
      });
      if (res.ok) { setState('success'); setEmail(''); }
      else if (res.status === 429) setState('rate');
      else setState('error');
    } catch { setState('error'); }
  }

  return (
    <div id={id} className="w-full max-w-md scroll-mt-28">
      {state === 'success' ? (
        <p className="font-bold text-[var(--color-accent)] py-3.5" role="status">{successMsg}</p>
      ) : (
        <>
          <form onSubmit={onSubmit} action="/api/waitlist" method="post"
            className="flex flex-col sm:flex-row gap-3 w-full">
            <input type="hidden" name="locale" value={locale} />
            {/* honeypot: hidden from humans, bots fill it */}
            <input type="text" name="website" tabIndex={-1} autoComplete="off"
              style={{ position: 'absolute', left: '-9999px', width: '1px', height: '1px', overflow: 'hidden' }}
              aria-hidden="true" />
            <input
              type="email" name="email" required value={email}
              onChange={(e) => setEmail(e.target.value)} placeholder={placeholder}
              aria-label={placeholder}
              className="flex-1 rounded-[var(--radius-btn)] bg-[var(--color-surface-2)] border border-[var(--color-line)] px-5 py-3.5 text-[var(--color-fg)] placeholder:text-[var(--color-muted)] outline-none focus:border-[var(--color-accent)] transition-colors"
            />
            <button type="submit" disabled={state === 'loading'}
              className="sweep press rounded-[var(--radius-btn)] bg-[var(--color-accent)] text-[var(--color-bg)] font-bold uppercase tracking-[0.04em] font-[var(--font-display)] text-[1.05rem] px-7 py-3.5 disabled:opacity-60 whitespace-nowrap">
              {state === 'loading' ? (loadingMsg ?? '…') : ctaLabel}
            </button>
          </form>
          {state === 'invalid' && <p className="text-[#F59E0B] text-sm mt-2" role="alert">{invalidMsg}</p>}
          {state === 'rate' && <p className="text-[#F59E0B] text-sm mt-2" role="alert">{rateMsg ?? errorMsg}</p>}
          {state === 'error' && <p className="text-[#F59E0B] text-sm mt-2" role="alert">{errorMsg}</p>}
          {reassure && state !== 'invalid' && state !== 'error' && state !== 'rate' && (
            <p className="text-[var(--color-muted)] text-sm mt-3">{reassure}</p>
          )}
        </>
      )}
    </div>
  );
}
