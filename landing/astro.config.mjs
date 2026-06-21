import { defineConfig } from 'astro/config';
import react from '@astrojs/react';
import vercel from '@astrojs/vercel';
import tailwindcss from '@tailwindcss/vite';

// Server output so /api/waitlist runs on Vercel; pages stay static via prerender.
export default defineConfig({
  site: 'https://getbulkup.com',
  output: 'server',
  adapter: vercel(),
  integrations: [react()],
  vite: { plugins: [tailwindcss()] },
  i18n: {
    defaultLocale: 'en',
    locales: ['en', 'es'],
    routing: { prefixDefaultLocale: false }, // en at /, es at /es
  },
});
