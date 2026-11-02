import type { APIRoute } from 'astro';
const SITE = 'https://getbulkup.com';
export const prerender = true;
export const GET: APIRoute = () => {
  const urls = ['/', '/es'];
  // EN-only content pages: no hreflang alternates.
  const enOnly = ['/import-workout-pdf', '/bulkup-vs-hevy', '/bulkup-vs-strong', '/apple-watch-workout-tracker'];
  // Legal pages: localized with different slugs per language.
  const legal = [
    { en: '/terms', es: '/es/terminos' },
    { en: '/privacy', es: '/es/privacidad' },
  ];
  const body = `<?xml version="1.0" encoding="UTF-8"?>
<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9" xmlns:xhtml="http://www.w3.org/1999/xhtml">
${urls.map((u) => `  <url><loc>${SITE}${u === '/' ? '' : u}</loc>
    <xhtml:link rel="alternate" hreflang="en" href="${SITE}"/>
    <xhtml:link rel="alternate" hreflang="es" href="${SITE}/es"/>
    <xhtml:link rel="alternate" hreflang="x-default" href="${SITE}"/>
  </url>`).join('\n')}
${enOnly.map((u) => `  <url><loc>${SITE}${u}</loc></url>`).join('\n')}
${legal.flatMap(({ en, es }) => [en, es].map((u) => `  <url><loc>${SITE}${u}</loc>
    <xhtml:link rel="alternate" hreflang="en" href="${SITE}${en}"/>
    <xhtml:link rel="alternate" hreflang="es" href="${SITE}${es}"/>
    <xhtml:link rel="alternate" hreflang="x-default" href="${SITE}${en}"/>
  </url>`)).join('\n')}
</urlset>`;
  return new Response(body, { headers: { 'content-type': 'application/xml' } });
};
