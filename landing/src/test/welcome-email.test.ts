import { describe, it, expect } from 'vitest';
import { welcomeEmail } from '../lib/welcome-email';

describe('welcomeEmail', () => {
  it('returns English copy by default', () => {
    const e = welcomeEmail('en');
    expect(e.subject).toContain('BulkUp');
    expect(e.html).toContain("You're on the list!");
    expect(e.text).toContain('Eat, train, grow, repeat.');
  });
  it('returns Spanish copy for es', () => {
    const e = welcomeEmail('es');
    expect(e.html).toContain('¡Estás en la lista!');
    expect(e.text).toContain('Come, entrena, crece, repite.');
  });
  it('falls back to English for unknown locales', () => {
    expect(welcomeEmail('fr').html).toContain("You're on the list!");
  });
});
