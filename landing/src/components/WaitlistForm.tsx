import { useState, type FormEvent } from 'react';

type Props = {
  locale: string; ctaLabel: string; placeholder: string;
  successMsg: string; errorMsg: string; invalidMsg: string;
};

export default function WaitlistForm({ locale, ctaLabel, placeholder, successMsg, errorMsg, invalidMsg }: Props) {
  const [email, setEmail] = useState('');
  const [state, setState] = useState<'idle' | 'loading' | 'success' | 'error' | 'invalid'>('idle');

  async function onSubmit(e: FormEvent) {
    e.preventDefault();
    const honeypot = (e.currentTarget as HTMLFormElement).website?.value ?? '';
    if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email.trim())) { setState('invalid'); return; }
    setState('loading');
    try {
      const res = await fetch('/api/waitlist', {
        method: 'POST', headers: { 'content-type': 'application/json' },
        body: JSON.stringify({ email, locale, website: honeypot }),
      });
      setState(res.ok ? 'success' : 'error');
      if (res.ok) setEmail('');
    } catch { setState('error'); }
  }

  if (state === 'success')
    return <p className="text-[var(--color-accent)] font-medium" role="status">{successMsg}</p>;

  return (
    <form onSubmit={onSubmit} action="/api/waitlist" method="post"
      className="flex flex-col sm:flex-row gap-3 w-full max-w-md">
      <input type="hidden" name="locale" value={locale} />
      {/* honeypot: hidden from humans, bots fill it */}
      <input type="text" name="website" tabIndex={-1} autoComplete="off"
        style={{ position: 'absolute', left: '-9999px', width: '1px', height: '1px', overflow: 'hidden' }}
        aria-hidden="true" />
      <input
        type="email" name="email" required value={email}
        onChange={(e) => setEmail(e.target.value)} placeholder={placeholder}
        className="flex-1 rounded-full bg-[var(--color-surface)] border border-[var(--color-line)] px-5 py-3.5 text-[var(--color-fg)] placeholder:text-[var(--color-muted)] outline-none focus:border-[var(--color-accent)] transition-colors"
      />
      <button type="submit" disabled={state === 'loading'}
        className="rounded-full bg-[var(--color-accent)] text-black font-semibold px-6 py-3.5 hover:scale-[1.03] active:scale-95 transition-transform disabled:opacity-60">
        {state === 'loading' ? '…' : ctaLabel}
      </button>
      {state === 'invalid' && <p className="text-red-400 text-sm w-full" role="alert">{invalidMsg}</p>}
      {state === 'error' && <p className="text-red-400 text-sm w-full" role="alert">{errorMsg}</p>}
    </form>
  );
}
