import { ui, type Locale } from '../i18n/ui';

const SITE = 'https://getbulkup.com';

export function buildAlternates(path: string) {
  const clean = path.replace(/^\/es/, '') || '/';
  const en = `${SITE}${clean === '/' ? '' : clean}` || SITE;
  const es = `${SITE}/es${clean === '/' ? '' : clean}`;
  return [
    { hreflang: 'en', href: en || SITE },
    { hreflang: 'es', href: es },
    { hreflang: 'x-default', href: en || SITE },
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
