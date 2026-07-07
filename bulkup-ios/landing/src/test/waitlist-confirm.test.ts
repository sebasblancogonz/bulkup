import { describe, it, expect } from 'vitest';
import { render } from 'react-email';
import { WaitlistConfirmEmail } from '../../emails/waitlist-confirm';
import { createElement } from 'react';

describe('WaitlistConfirmEmail', () => {
  it('renders the confirm URL and an English CTA', async () => {
    const html = await render(
      createElement(WaitlistConfirmEmail, { confirmUrl: 'https://x.test/c?token=abc', locale: 'en' }),
    );
    expect(html).toContain('https://x.test/c?token=abc');
    expect(html).toContain('Confirm');
    expect(html).toContain('lang="en"');
  });

  it('renders Spanish copy when locale is es', async () => {
    const html = await render(
      createElement(WaitlistConfirmEmail, { confirmUrl: 'https://x.test/c?token=abc', locale: 'es' }),
    );
    expect(html).toContain('Confirma');
    expect(html).toContain('lang="es"');
  });
});
