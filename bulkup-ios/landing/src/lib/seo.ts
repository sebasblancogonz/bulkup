import { ui, type Locale } from '../i18n/ui';

const SITE = 'https://getbulkup.com';

// Localized pages whose ES slug is not just the EN slug prefixed with /es.
const LOCALIZED_SLUGS: Record<string, string> = {
  '/terms': '/es/terminos',
  '/privacy': '/es/privacidad',
};

/** Returns the EN and ES paths for a given page path (either locale). */
export function localePaths(path: string): { en: string; es: string } {
  const normalized = path.replace(/\/$/, '') || '/';
  for (const [en, es] of Object.entries(LOCALIZED_SLUGS)) {
    if (normalized === en || normalized === es) return { en, es };
  }
  const clean = normalized.replace(/^\/es(?=\/|$)/, '') || '/';
  return { en: clean, es: clean === '/' ? '/es' : `/es${clean}` };
}

export function buildAlternates(path: string) {
  const { en: enPath, es: esPath } = localePaths(path);
  const en = `${SITE}${enPath === '/' ? '' : enPath}`;
  const es = `${SITE}${esPath}`;
  return [
    { hreflang: 'en', href: en },
    { hreflang: 'es', href: es },
    { hreflang: 'x-default', href: en },
  ];
}

export function softwareAppLd(locale: Locale) {
  return {
    '@context': 'https://schema.org',
    '@type': 'SoftwareApplication',
    name: 'BulkUp',
    applicationCategory: 'HealthApplication',
    operatingSystem: 'iOS',
    description: ui[locale]['meta.description'],
    offers: { '@type': 'Offer', category: 'subscription' },
  };
}

export function articleLd(title: string, description: string, path: string) {
  return {
    '@context': 'https://schema.org',
    '@type': 'Article',
    headline: title,
    description,
    url: `${SITE}${path}`,
    author: { '@type': 'Organization', name: 'BulkUp', url: SITE },
    publisher: { '@type': 'Organization', name: 'BulkUp', url: SITE },
  };
}

export function organizationLd() {
  return {
    '@context': 'https://schema.org',
    '@type': 'Organization',
    name: 'BulkUp',
    url: SITE,
    logo: `${SITE}/favicon.svg`,
  };
}

export function faqLd(locale: Locale) {
  const t = (k: string) => (ui[locale] as Record<string, string>)[k];
  const pairs = [['faq.q1', 'faq.a1'], ['faq.q2', 'faq.a2'], ['faq.q3', 'faq.a3'], ['faq.q4', 'faq.a4']];
  return {
    '@context': 'https://schema.org',
    '@type': 'FAQPage',
    mainEntity: pairs.map(([q, a]) => ({
      '@type': 'Question',
      name: t(q),
      acceptedAnswer: { '@type': 'Answer', text: t(a) },
    })),
  };
}
