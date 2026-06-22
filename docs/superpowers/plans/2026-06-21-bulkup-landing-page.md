# BulkUp Landing Page Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a pre-launch, English-first bilingual marketing site for BulkUp that captures waitlist signups into Resend, optimized for SEO/SEM/LLM, with premium dark-athletic design and motion.

**Architecture:** Astro static site in `/landing` with one Vercel server route for the waitlist. Content is static HTML (≈0 JS); only the waitlist form and motion-heavy sections hydrate as React islands. Copy lives in typed i18n dictionaries; EN renders at `/`, ES at `/es`.

**Tech Stack:** Astro 5, Tailwind CSS v4, React (islands), `motion` (Framer Motion) for animation, Resend Node SDK, `@astrojs/vercel` adapter, Vitest for unit tests. Node 20+.

## Global Constraints

- Node **20+**; package manager **npm**; everything lives under `/landing` (a separate package — never touch the iOS app, widgets, or Go backend).
- **EN is the default locale** at `/`; **ES at `/es`**. `hreflang` for `en`, `es`, and `x-default` → EN.
- Secrets (`RESEND_API_KEY`, `RESEND_AUDIENCE_ID`) come from env only. Repo ships `.env.example` with placeholder values; **never commit real keys**.
- Brand assets are placeholders, swappable in one place. Aesthetic: dark athletic premium (near-black base, electric-lime accent, oversized bold display type, subtle grain/glow).
- All motion must respect `prefers-reduced-motion: reduce` (static fallback, fully usable).
- Primary CTA on every section = **join the waitlist**.
- Commit after every task with `feat(landing): ...` / `chore(landing): ...` style messages on branch `feature/landing-page`.

---

## File Structure

```
/landing
  package.json
  astro.config.mjs              # i18n (en default, es), vercel adapter, tailwind, react
  tsconfig.json
  vitest.config.ts
  .env.example
  .gitignore
  README.md
  src/
    styles/global.css           # tailwind import + design tokens + grain/glow utils
    i18n/
      ui.ts                     # typed dictionaries (en, es) + t() helper + locales
    lib/
      seo.ts                    # buildMeta() + JSON-LD builders
      waitlist.ts               # email validation + payload normalization (pure, unit-tested)
    layouts/
      BaseLayout.astro          # <head> SEO, hreflang, fonts, grain layer, slots
    components/
      LanguageSwitch.astro
      seo/JsonLd.astro
      Reveal.tsx                # shared scroll-reveal island (motion)
      WaitlistForm.tsx          # waitlist island (progressive enhancement)
      sections/
        Hero.astro
        SocialProof.astro
        ProblemSolution.astro
        FeaturesBento.astro
        PremiumDeepDive.astro
        Showcase.astro
        PricingTeaser.astro
        Faq.astro
        FinalCta.astro
        Footer.astro
    pages/
      index.astro               # EN
      es/index.astro            # ES
      sitemap.xml.ts            # generated sitemap
    test/
      waitlist.test.ts
  public/
    robots.txt
    llms.txt
    favicon.svg
    og-default.png              # placeholder
    mockups/                    # placeholder device screens
```

---

### Task 1: Scaffold Astro project, Tailwind v4, adapters, build

**Files:**
- Create: `landing/package.json`, `landing/astro.config.mjs`, `landing/tsconfig.json`, `landing/.gitignore`, `landing/src/styles/global.css`, `landing/src/pages/index.astro`

**Interfaces:**
- Produces: a buildable Astro app; `global.css` imported by all pages; React + motion + Tailwind available.

- [ ] **Step 1: Create `landing/package.json`**

```json
{
  "name": "bulkup-landing",
  "type": "module",
  "version": "0.1.0",
  "private": true,
  "scripts": {
    "dev": "astro dev",
    "build": "astro build",
    "preview": "astro preview",
    "test": "vitest run"
  },
  "dependencies": {
    "@astrojs/react": "^4.2.0",
    "@astrojs/vercel": "^8.0.0",
    "astro": "^5.5.0",
    "motion": "^12.0.0",
    "react": "^19.0.0",
    "react-dom": "^19.0.0",
    "resend": "^4.0.0"
  },
  "devDependencies": {
    "@tailwindcss/vite": "^4.0.0",
    "@types/react": "^19.0.0",
    "@types/react-dom": "^19.0.0",
    "tailwindcss": "^4.0.0",
    "vitest": "^2.1.0"
  }
}
```

- [ ] **Step 2: Install**

Run: `cd landing && npm install`
Expected: lockfile created, no peer-dep errors that block install.

- [ ] **Step 3: Create `landing/astro.config.mjs`**

```js
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
```

- [ ] **Step 4: Create `landing/tsconfig.json`**

```json
{
  "extends": "astro/tsconfigs/strict",
  "compilerOptions": {
    "jsx": "react-jsx",
    "jsxImportSource": "react",
    "baseUrl": ".",
    "paths": { "@/*": ["src/*"] }
  }
}
```

- [ ] **Step 5: Create `landing/.gitignore`**

```
node_modules/
dist/
.astro/
.vercel/
.env
.env.*.local
```

- [ ] **Step 6: Create `landing/src/styles/global.css`** (tokens filled in Task 2; minimal now)

```css
@import "tailwindcss";

:root { color-scheme: dark; }
html { scroll-behavior: smooth; }
@media (prefers-reduced-motion: reduce) {
  html { scroll-behavior: auto; }
  *, *::before, *::after { animation-duration: .001ms !important; transition-duration: .001ms !important; }
}
```

- [ ] **Step 7: Create temporary `landing/src/pages/index.astro`** (replaced in Task 7)

```astro
---
import '../styles/global.css';
---
<html lang="en"><head><meta charset="utf-8" /><title>BulkUp</title></head>
<body class="bg-black text-white"><h1 class="text-4xl p-10">BulkUp landing — scaffold OK</h1></body></html>
```

- [ ] **Step 8: Verify build**

Run: `cd landing && npm run build`
Expected: build completes, `dist/` produced, no errors.

- [ ] **Step 9: Commit**

```bash
git add landing/package.json landing/package-lock.json landing/astro.config.mjs landing/tsconfig.json landing/.gitignore landing/src/styles/global.css landing/src/pages/index.astro
git commit -m "chore(landing): scaffold Astro + Tailwind v4 + React + Vercel adapter"
```

---

### Task 2: Design tokens + global styles (dark athletic premium)

**Files:**
- Modify: `landing/src/styles/global.css`
- Create: `landing/public/favicon.svg`

**Interfaces:**
- Produces: CSS custom properties + Tailwind `@theme` tokens (`--color-accent`, `--color-bg`, fonts), and utility classes `.grain`, `.glow`, `.text-balance`, used by all sections.

- [ ] **Step 1: Replace `global.css` with the token system**

```css
@import "tailwindcss";

@theme {
  --color-bg: #0A0A0B;
  --color-surface: #121214;
  --color-surface-2: #1A1A1E;
  --color-line: #26262B;
  --color-fg: #F4F4F2;
  --color-muted: #9A9AA2;
  --color-accent: #C8FF3D;      /* electric lime */
  --color-accent-2: #34D399;    /* app diet green, used sparingly */
  --font-display: "Clash Display", "Arial Black", system-ui, sans-serif;
  --font-sans: ui-sans-serif, system-ui, -apple-system, "Inter", sans-serif;
}

:root { color-scheme: dark; }
html { scroll-behavior: smooth; background: var(--color-bg); }
body { background: var(--color-bg); color: var(--color-fg); font-family: var(--font-sans); }

.text-balance { text-wrap: balance; }

/* Film grain overlay (applied on a fixed full-screen layer in BaseLayout) */
.grain::after {
  content: ""; position: fixed; inset: 0; pointer-events: none; z-index: 50;
  opacity: .04; mix-blend-mode: overlay;
  background-image: url("data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' width='120' height='120'%3E%3Cfilter id='n'%3E%3CfeTurbulence type='fractalNoise' baseFrequency='.9' numOctaves='2'/%3E%3C/filter%3E%3Crect width='100%25' height='100%25' filter='url(%23n)'/%3E%3C/svg%3E");
}

/* Soft radial accent glow utility */
.glow { position: relative; }
.glow::before {
  content: ""; position: absolute; inset: -20% -10% auto; height: 60%;
  background: radial-gradient(50% 50% at 50% 0%, color-mix(in oklab, var(--color-accent) 22%, transparent), transparent 70%);
  pointer-events: none; z-index: 0;
}

@media (prefers-reduced-motion: reduce) {
  html { scroll-behavior: auto; }
  *, *::before, *::after { animation-duration: .001ms !important; transition-duration: .001ms !important; }
}
```

- [ ] **Step 2: Add a placeholder `favicon.svg`**

```svg
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 32 32"><rect width="32" height="32" rx="7" fill="#0A0A0B"/><text x="16" y="22" font-family="Arial Black,Arial" font-size="18" fill="#C8FF3D" text-anchor="middle">B</text></svg>
```

- [ ] **Step 3: Verify build still passes**

Run: `cd landing && npm run build`
Expected: PASS.

- [ ] **Step 4: Commit**

```bash
git add landing/src/styles/global.css landing/public/favicon.svg
git commit -m "feat(landing): dark athletic design tokens, grain + glow utilities"
```

---

### Task 3: i18n dictionaries + `t()` helper

**Files:**
- Create: `landing/src/i18n/ui.ts`

**Interfaces:**
- Produces:
  - `export const locales = ['en', 'es'] as const; export type Locale = 'en' | 'es';`
  - `export const defaultLocale: Locale = 'en';`
  - `export function useT(locale: Locale): (key: string) => string` — returns translator; missing key falls back to EN then to the key itself.
  - `export const ui: Record<Locale, Record<string, string>>` — flat dot-keyed strings (e.g. `hero.title`).
- Consumed by every section component and `BaseLayout`.

- [ ] **Step 1: Create `ui.ts` with the full key set**

```ts
export const locales = ['en', 'es'] as const;
export type Locale = (typeof locales)[number];
export const defaultLocale: Locale = 'en';

export const ui = {
  en: {
    'meta.title': 'BulkUp — Turn any workout or diet PDF into a smart training app',
    'meta.description': 'Upload a PDF or photo of your workout or diet plan and BulkUp\'s AI turns it into a fully trackable app. Personalized training, AI diet parsing, 1RM and body tracking. Join the waitlist.',
    'nav.waitlist': 'Join waitlist',
    'hero.eyebrow': 'AI-powered fitness coaching',
    'hero.title': 'Your plan. Your app. In seconds.',
    'hero.subtitle': 'Upload a PDF or photo of any workout or diet plan. Our AI turns it into a trackable, personalized training app — no manual setup.',
    'hero.cta': 'Get early access',
    'hero.placeholder': 'you@email.com',
    'social.title': 'Join {count}+ athletes already on the list',
    'problem.title': 'From a messy PDF to a living plan',
    'problem.before': 'A PDF buried in your downloads',
    'problem.after': 'A structured, trackable plan',
    'features.title': 'Everything your coach gives you — supercharged',
    'feature.training.title': 'Smart training plans',
    'feature.training.body': 'Templates (PPL, Upper/Lower, Full Body) or import your own. Log weights every week.',
    'feature.diet.title': 'AI diet parsing',
    'feature.diet.body': 'Upload your nutrition PDF — meals, supplements and rest-day swaps become tappable.',
    'feature.rm.title': '1RM tracking',
    'feature.rm.body': 'Track max lifts with proven formulas and a 1000+ exercise database.',
    'feature.body.title': 'Body composition',
    'feature.body.body': 'Weight, body fat, lean mass and circumferences with historical charts.',
    'feature.meals.title': 'Meal compliance & streaks',
    'feature.meals.body': 'Daily check-ins, compliance % and streaks that keep you honest.',
    'feature.friends.title': 'Friends & leaderboard',
    'feature.friends.body': 'Add friends by code, compare streaks, stay accountable.',
    'premium.title': 'Built to feel premium',
    'premium.body': 'Real-time processing, native iOS performance, and a design that respects your focus.',
    'showcase.title': 'See it in motion',
    'pricing.title': 'Simple pricing. Waitlist gets early access.',
    'pricing.monthly': 'Monthly',
    'pricing.annual': 'Annual',
    'pricing.annualNote': 'Best value · includes free trial',
    'pricing.cta': 'Join the waitlist',
    'faq.title': 'Frequently asked questions',
    'faq.q1': 'What is BulkUp?',
    'faq.a1': 'A fitness app that turns your existing workout and diet plans into a fully trackable, personalized experience using AI.',
    'faq.q2': 'How does the PDF import work?',
    'faq.a2': 'You upload a PDF or photo of your plan. Our AI reads it and builds a structured, editable plan you can track day by day.',
    'faq.q3': 'When does it launch?',
    'faq.a3': 'We are in pre-launch. Join the waitlist to get early access and launch updates.',
    'faq.q4': 'Is it free?',
    'faq.a4': 'BulkUp offers a free trial with monthly and annual premium plans. Waitlist members get early-access perks.',
    'cta.title': 'Be first to train smarter',
    'cta.subtitle': 'Join the waitlist for early access, launch news, and member-only perks.',
    'cta.button': 'Join the waitlist',
    'form.success': "You're on the list. Check your inbox.",
    'form.error': 'Something went wrong. Please try again.',
    'form.invalid': 'Please enter a valid email.',
    'footer.tagline': 'Eat, train, grow, repeat.',
    'footer.rights': 'All rights reserved.',
  },
  es: {
    'meta.title': 'BulkUp — Convierte cualquier PDF de entreno o dieta en una app inteligente',
    'meta.description': 'Sube un PDF o foto de tu plan de entrenamiento o dieta y la IA de BulkUp lo convierte en una app totalmente medible. Entrenamiento personalizado, dieta con IA, seguimiento de 1RM y composición corporal. Únete a la lista.',
    'nav.waitlist': 'Unirme',
    'hero.eyebrow': 'Coaching fitness con IA',
    'hero.title': 'Tu plan. Tu app. En segundos.',
    'hero.subtitle': 'Sube un PDF o foto de cualquier plan de entreno o dieta. Nuestra IA lo convierte en una app personalizada y medible, sin configuración manual.',
    'hero.cta': 'Acceso anticipado',
    'hero.placeholder': 'tu@email.com',
    'social.title': 'Únete a más de {count} atletas que ya están en la lista',
    'problem.title': 'De un PDF caótico a un plan vivo',
    'problem.before': 'Un PDF perdido en tus descargas',
    'problem.after': 'Un plan estructurado y medible',
    'features.title': 'Todo lo que te da tu coach — potenciado',
    'feature.training.title': 'Planes de entreno inteligentes',
    'feature.training.body': 'Plantillas (PPL, Torso/Pierna, Full Body) o importa el tuyo. Registra pesos cada semana.',
    'feature.diet.title': 'Dieta con IA',
    'feature.diet.body': 'Sube tu PDF de nutrición: comidas, suplementos y cambios de día de descanso, todo tocable.',
    'feature.rm.title': 'Seguimiento de 1RM',
    'feature.rm.body': 'Registra tus máximos con fórmulas probadas y una base de 1000+ ejercicios.',
    'feature.body.title': 'Composición corporal',
    'feature.body.body': 'Peso, grasa, masa magra y perímetros con gráficos históricos.',
    'feature.meals.title': 'Cumplimiento y rachas',
    'feature.meals.body': 'Check-ins diarios, % de cumplimiento y rachas que te mantienen firme.',
    'feature.friends.title': 'Amigos y ranking',
    'feature.friends.body': 'Añade amigos por código, compara rachas y mantén la responsabilidad.',
    'premium.title': 'Diseñada para sentirse premium',
    'premium.body': 'Procesado en tiempo real, rendimiento nativo en iOS y un diseño que respeta tu concentración.',
    'showcase.title': 'Míralo en movimiento',
    'pricing.title': 'Precios simples. La lista tiene acceso anticipado.',
    'pricing.monthly': 'Mensual',
    'pricing.annual': 'Anual',
    'pricing.annualNote': 'Mejor precio · incluye prueba gratis',
    'pricing.cta': 'Unirme a la lista',
    'faq.title': 'Preguntas frecuentes',
    'faq.q1': '¿Qué es BulkUp?',
    'faq.a1': 'Una app fitness que convierte tus planes de entreno y dieta en una experiencia medible y personalizada con IA.',
    'faq.q2': '¿Cómo funciona la importación de PDF?',
    'faq.a2': 'Subes un PDF o foto de tu plan. Nuestra IA lo lee y crea un plan estructurado y editable que puedes seguir día a día.',
    'faq.q3': '¿Cuándo se lanza?',
    'faq.a3': 'Estamos en pre-lanzamiento. Únete a la lista para acceso anticipado y novedades.',
    'faq.q4': '¿Es gratis?',
    'faq.a4': 'BulkUp ofrece prueba gratis con planes premium mensual y anual. La lista tiene ventajas de acceso anticipado.',
    'cta.title': 'Sé el primero en entrenar mejor',
    'cta.subtitle': 'Únete a la lista para acceso anticipado, novedades y ventajas exclusivas.',
    'cta.button': 'Unirme a la lista',
    'form.success': 'Estás en la lista. Revisa tu correo.',
    'form.error': 'Algo salió mal. Inténtalo de nuevo.',
    'form.invalid': 'Introduce un email válido.',
    'footer.tagline': 'Come, entrena, crece, repite.',
    'footer.rights': 'Todos los derechos reservados.',
  },
} as const;

export function useT(locale: Locale) {
  return (key: string): string =>
    (ui[locale] as Record<string, string>)[key] ??
    (ui.en as Record<string, string>)[key] ??
    key;
}
```

- [ ] **Step 2: Verify it compiles**

Run: `cd landing && npx astro check 2>/dev/null || npm run build`
Expected: no type errors referencing `ui.ts`.

- [ ] **Step 3: Commit**

```bash
git add landing/src/i18n/ui.ts
git commit -m "feat(landing): bilingual EN/ES dictionaries + t() helper"
```

---

### Task 4: Waitlist core logic (pure, unit-tested) — TDD

**Files:**
- Create: `landing/src/lib/waitlist.ts`, `landing/src/test/waitlist.test.ts`, `landing/vitest.config.ts`

**Interfaces:**
- Produces:
  - `export function isValidEmail(email: string): boolean`
  - `export type WaitlistInput = { email: string; locale?: string; honeypot?: string }`
  - `export type WaitlistResult = { ok: true; email: string } | { ok: false; reason: 'invalid' | 'spam' }`
  - `export function validateWaitlist(input: WaitlistInput): WaitlistResult` — trims/lowercases email; rejects invalid; treats non-empty `honeypot` as `spam`.
- Consumed by the API route in Task 5.

- [ ] **Step 1: Create `vitest.config.ts`**

```ts
import { defineConfig } from 'vitest/config';
export default defineConfig({ test: { include: ['src/test/**/*.test.ts'] } });
```

- [ ] **Step 2: Write failing test `src/test/waitlist.test.ts`**

```ts
import { describe, it, expect } from 'vitest';
import { isValidEmail, validateWaitlist } from '../lib/waitlist';

describe('isValidEmail', () => {
  it('accepts normal emails', () => expect(isValidEmail('a@b.com')).toBe(true));
  it('rejects junk', () => {
    expect(isValidEmail('nope')).toBe(false);
    expect(isValidEmail('a@b')).toBe(false);
    expect(isValidEmail('')).toBe(false);
  });
});

describe('validateWaitlist', () => {
  it('normalizes good email', () => {
    expect(validateWaitlist({ email: '  ME@Mail.COM ' })).toEqual({ ok: true, email: 'me@mail.com' });
  });
  it('flags invalid', () => {
    expect(validateWaitlist({ email: 'bad' })).toEqual({ ok: false, reason: 'invalid' });
  });
  it('flags honeypot as spam', () => {
    expect(validateWaitlist({ email: 'a@b.com', honeypot: 'bot' })).toEqual({ ok: false, reason: 'spam' });
  });
});
```

- [ ] **Step 3: Run test, verify it fails**

Run: `cd landing && npm test`
Expected: FAIL — cannot find module `../lib/waitlist`.

- [ ] **Step 4: Implement `src/lib/waitlist.ts`**

```ts
export type WaitlistInput = { email: string; locale?: string; honeypot?: string };
export type WaitlistResult = { ok: true; email: string } | { ok: false; reason: 'invalid' | 'spam' };

const EMAIL_RE = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

export function isValidEmail(email: string): boolean {
  return EMAIL_RE.test(email.trim());
}

export function validateWaitlist(input: WaitlistInput): WaitlistResult {
  if (input.honeypot && input.honeypot.trim() !== '') return { ok: false, reason: 'spam' };
  const email = input.email.trim().toLowerCase();
  if (!isValidEmail(email)) return { ok: false, reason: 'invalid' };
  return { ok: true, email };
}
```

- [ ] **Step 5: Run test, verify it passes**

Run: `cd landing && npm test`
Expected: PASS (all cases green).

- [ ] **Step 6: Commit**

```bash
git add landing/vitest.config.ts landing/src/lib/waitlist.ts landing/src/test/waitlist.test.ts
git commit -m "feat(landing): waitlist validation logic with tests"
```

---

### Task 5: Waitlist API route → Resend Audience + `.env.example`

**Files:**
- Create: `landing/src/pages/api/waitlist.ts`, `landing/.env.example`

**Interfaces:**
- Consumes: `validateWaitlist` from Task 4.
- Produces: `POST /api/waitlist` accepting JSON or form-encoded `{ email, locale, website }` (`website` = honeypot). Returns `200 {ok:true}`, `400 {ok:false,reason}`, or `500 {ok:false,reason:'server'}`. Adds the contact to the Resend Audience.

- [ ] **Step 1: Create `.env.example`**

```
# Resend — create at https://resend.com/api-keys
RESEND_API_KEY=re_xxxxxxxxxxxxxxxxxxxx
# Resend Audience ID — https://resend.com/audiences
RESEND_AUDIENCE_ID=00000000-0000-0000-0000-000000000000
```

- [ ] **Step 2: Create `src/pages/api/waitlist.ts`**

```ts
import type { APIRoute } from 'astro';
import { Resend } from 'resend';
import { validateWaitlist } from '../../lib/waitlist';

export const prerender = false;

export const POST: APIRoute = async ({ request }) => {
  let body: Record<string, string> = {};
  const ct = request.headers.get('content-type') ?? '';
  try {
    if (ct.includes('application/json')) body = await request.json();
    else body = Object.fromEntries((await request.formData()) as any);
  } catch {
    return json({ ok: false, reason: 'invalid' }, 400);
  }

  const result = validateWaitlist({
    email: String(body.email ?? ''),
    locale: String(body.locale ?? 'en'),
    honeypot: String(body.website ?? ''), // hidden field named "website"
  });

  if (!result.ok) {
    // Spam: pretend success so bots get no signal.
    if (result.reason === 'spam') return json({ ok: true }, 200);
    return json({ ok: false, reason: 'invalid' }, 400);
  }

  const apiKey = import.meta.env.RESEND_API_KEY;
  const audienceId = import.meta.env.RESEND_AUDIENCE_ID;
  if (!apiKey || !audienceId) return json({ ok: false, reason: 'server' }, 500);

  try {
    const resend = new Resend(apiKey);
    await resend.contacts.create({ email: result.email, audienceId, unsubscribed: false });
    return json({ ok: true }, 200);
  } catch (e) {
    console.error('waitlist resend error', e);
    return json({ ok: false, reason: 'server' }, 500);
  }
};

function json(data: unknown, status: number) {
  return new Response(JSON.stringify(data), { status, headers: { 'content-type': 'application/json' } });
}
```

- [ ] **Step 3: Verify build (route compiles)**

Run: `cd landing && npm run build`
Expected: PASS; build output lists the `/api/waitlist` endpoint as server-rendered.

- [ ] **Step 4: Commit**

```bash
git add landing/src/pages/api/waitlist.ts landing/.env.example
git commit -m "feat(landing): waitlist API route adding contacts to Resend audience"
```

---

### Task 6: SEO library (meta + JSON-LD) + BaseLayout

**Files:**
- Create: `landing/src/lib/seo.ts`, `landing/src/components/seo/JsonLd.astro`, `landing/src/components/LanguageSwitch.astro`, `landing/src/layouts/BaseLayout.astro`

**Interfaces:**
- Consumes: `useT`, `Locale` from Task 3.
- Produces:
  - `seo.ts`: `buildAlternates(path: string): {hreflang:string,href:string}[]`, `softwareAppLd(locale)`, `organizationLd()`, `faqLd(locale)` returning JSON-LD objects.
  - `BaseLayout.astro` props: `{ locale: Locale; path: string; title?: string; description?: string }` — renders full `<head>`, grain layer, `<slot />`.

- [ ] **Step 1: Create `src/lib/seo.ts`**

```ts
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
```

- [ ] **Step 2: Create `src/components/seo/JsonLd.astro`**

```astro
---
const { data } = Astro.props as { data: unknown };
---
<script type="application/ld+json" set:html={JSON.stringify(data)} />
```

- [ ] **Step 3: Create `src/components/LanguageSwitch.astro`**

```astro
---
import type { Locale } from '../i18n/ui';
const { locale } = Astro.props as { locale: Locale };
const enHref = '/';
const esHref = '/es';
---
<div class="flex gap-2 text-sm text-[var(--color-muted)]">
  <a href={enHref} class={locale === 'en' ? 'text-[var(--color-fg)] font-semibold' : 'hover:text-[var(--color-fg)]'}>EN</a>
  <span aria-hidden="true">/</span>
  <a href={esHref} class={locale === 'es' ? 'text-[var(--color-fg)] font-semibold' : 'hover:text-[var(--color-fg)]'}>ES</a>
</div>
```

- [ ] **Step 4: Create `src/layouts/BaseLayout.astro`**

```astro
---
import '../styles/global.css';
import { useT, type Locale } from '../i18n/ui';
import { buildAlternates, softwareAppLd, organizationLd, faqLd } from '../lib/seo';
import JsonLd from '../components/seo/JsonLd.astro';

interface Props { locale: Locale; path: string; title?: string; description?: string }
const { locale, path, title, description } = Astro.props;
const t = useT(locale);
const pageTitle = title ?? t('meta.title');
const pageDesc = description ?? t('meta.description');
const canonical = new URL(Astro.url.pathname, 'https://getbulkup.com').href;
const alternates = buildAlternates(path);
const ogImage = 'https://getbulkup.com/og-default.png';
---
<!doctype html>
<html lang={locale}>
  <head>
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1" />
    <title>{pageTitle}</title>
    <meta name="description" content={pageDesc} />
    <link rel="canonical" href={canonical} />
    {alternates.map((a) => <link rel="alternate" hreflang={a.hreflang} href={a.href} />)}
    <meta property="og:type" content="website" />
    <meta property="og:title" content={pageTitle} />
    <meta property="og:description" content={pageDesc} />
    <meta property="og:image" content={ogImage} />
    <meta property="og:locale" content={locale === 'es' ? 'es_ES' : 'en_US'} />
    <meta name="twitter:card" content="summary_large_image" />
    <meta name="twitter:title" content={pageTitle} />
    <meta name="twitter:description" content={pageDesc} />
    <meta name="twitter:image" content={ogImage} />
    <link rel="icon" href="/favicon.svg" />
    <meta name="theme-color" content="#0A0A0B" />
    <JsonLd data={softwareAppLd(locale)} />
    <JsonLd data={organizationLd()} />
    <JsonLd data={faqLd(locale)} />
  </head>
  <body class="grain antialiased">
    <slot />
  </body>
</html>
```

- [ ] **Step 5: Verify build**

Run: `cd landing && npm run build`
Expected: PASS.

- [ ] **Step 6: Commit**

```bash
git add landing/src/lib/seo.ts landing/src/components/seo/JsonLd.astro landing/src/components/LanguageSwitch.astro landing/src/layouts/BaseLayout.astro
git commit -m "feat(landing): SEO meta, hreflang, JSON-LD, BaseLayout, language switch"
```

---

### Task 7: Reveal motion island + WaitlistForm island

**Files:**
- Create: `landing/src/components/Reveal.tsx`, `landing/src/components/WaitlistForm.tsx`

**Interfaces:**
- Produces:
  - `Reveal.tsx` default export: `<Reveal delay?={number} y?={number}>{children}</Reveal>` — fades/translates children in on scroll; renders children unchanged when `prefers-reduced-motion`.
  - `WaitlistForm.tsx` default export props `{ locale, ctaLabel, placeholder, successMsg, errorMsg, invalidMsg }` — controlled email form; honeypot input named `website`; posts JSON to `/api/waitlist`; shows loading/success/error inline. Works as a normal form if JS fails (has `action="/api/waitlist" method="post"`).

- [ ] **Step 1: Create `src/components/Reveal.tsx`**

```tsx
import { motion, useReducedMotion } from 'motion/react';
import type { ReactNode } from 'react';

export default function Reveal({ children, delay = 0, y = 24 }: { children: ReactNode; delay?: number; y?: number }) {
  const reduce = useReducedMotion();
  if (reduce) return <>{children}</>;
  return (
    <motion.div
      initial={{ opacity: 0, y }}
      whileInView={{ opacity: 1, y: 0 }}
      viewport={{ once: true, margin: '-80px' }}
      transition={{ duration: 0.6, delay, ease: [0.22, 1, 0.36, 1] }}
    >
      {children}
    </motion.div>
  );
}
```

- [ ] **Step 2: Create `src/components/WaitlistForm.tsx`**

```tsx
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
        className="hidden" aria-hidden="true" />
      <input
        type="email" name="email" required value={email}
        onChange={(e) => setEmail(e.target.value)} placeholder={placeholder}
        className="flex-1 rounded-full bg-[var(--color-surface)] border border-[var(--color-line)] px-5 py-3.5 text-[var(--color-fg)] placeholder:text-[var(--color-muted)] outline-none focus:border-[var(--color-accent)] transition-colors"
      />
      <button type="submit" disabled={state === 'loading'}
        className="rounded-full bg-[var(--color-accent)] text-black font-semibold px-6 py-3.5 hover:scale-[1.03] active:scale-95 transition-transform disabled:opacity-60">
        {state === 'loading' ? '…' : ctaLabel}
      </button>
      {state === 'invalid' && <p className="text-red-400 text-sm w-full">{invalidMsg}</p>}
      {state === 'error' && <p className="text-red-400 text-sm w-full">{errorMsg}</p>}
    </form>
  );
}
```

- [ ] **Step 3: Verify build**

Run: `cd landing && npm run build`
Expected: PASS.

- [ ] **Step 4: Commit**

```bash
git add landing/src/components/Reveal.tsx landing/src/components/WaitlistForm.tsx
git commit -m "feat(landing): scroll-reveal + waitlist form islands"
```

---

### Task 8: Hero + SocialProof sections

**Files:**
- Create: `landing/src/components/sections/Hero.astro`, `landing/src/components/sections/SocialProof.astro`

**Interfaces:**
- Consumes: `useT`, `Locale`; `WaitlistForm` (island, `client:load`); `LanguageSwitch`.
- Produces: `<Hero locale={...} />`, `<SocialProof locale={...} />`.

- [ ] **Step 1: Create `Hero.astro`**

```astro
---
import { useT, type Locale } from '../../i18n/ui';
import WaitlistForm from '../WaitlistForm.tsx';
import LanguageSwitch from '../LanguageSwitch.astro';
const { locale } = Astro.props as { locale: Locale };
const t = useT(locale);
---
<header class="glow relative overflow-hidden">
  <nav class="relative z-10 max-w-6xl mx-auto flex items-center justify-between px-6 py-6">
    <span class="font-[var(--font-display)] text-xl font-black tracking-tight">BulkUp</span>
    <LanguageSwitch locale={locale} />
  </nav>
  <div class="relative z-10 max-w-6xl mx-auto px-6 pt-12 pb-24 grid lg:grid-cols-2 gap-12 items-center">
    <div>
      <p class="uppercase tracking-[0.2em] text-xs text-[var(--color-accent)] mb-5">{t('hero.eyebrow')}</p>
      <h1 class="font-[var(--font-display)] text-5xl sm:text-6xl lg:text-7xl font-black leading-[0.95] text-balance mb-6">{t('hero.title')}</h1>
      <p class="text-lg text-[var(--color-muted)] max-w-md mb-8">{t('hero.subtitle')}</p>
      <WaitlistForm client:load locale={locale}
        ctaLabel={t('hero.cta')} placeholder={t('hero.placeholder')}
        successMsg={t('form.success')} errorMsg={t('form.error')} invalidMsg={t('form.invalid')} />
    </div>
    <div class="relative">
      <!-- placeholder phone mockup; swap with real screenshot -->
      <div class="mx-auto w-[280px] h-[580px] rounded-[2.5rem] border border-[var(--color-line)] bg-[var(--color-surface)] shadow-2xl shadow-black/60 flex items-center justify-center">
        <span class="text-[var(--color-muted)] text-sm">App preview</span>
      </div>
    </div>
  </div>
</header>
```

- [ ] **Step 2: Create `SocialProof.astro`**

```astro
---
import { useT, type Locale } from '../../i18n/ui';
const { locale } = Astro.props as { locale: Locale };
const t = useT(locale);
const count = 250; // swap with live count later
---
<section class="border-y border-[var(--color-line)] bg-[var(--color-surface)]/40">
  <div class="max-w-6xl mx-auto px-6 py-6 text-center text-[var(--color-muted)]">
    {t('social.title').replace('{count}', String(count))}
  </div>
</section>
```

- [ ] **Step 3: Verify build**

Run: `cd landing && npm run build`
Expected: PASS.

- [ ] **Step 4: Commit**

```bash
git add landing/src/components/sections/Hero.astro landing/src/components/sections/SocialProof.astro
git commit -m "feat(landing): hero + social proof sections"
```

---

### Task 9: ProblemSolution + FeaturesBento sections

**Files:**
- Create: `landing/src/components/sections/ProblemSolution.astro`, `landing/src/components/sections/FeaturesBento.astro`

**Interfaces:**
- Consumes: `useT`, `Locale`, `Reveal` (`client:visible`).
- Produces: `<ProblemSolution locale />`, `<FeaturesBento locale />`.

- [ ] **Step 1: Create `ProblemSolution.astro`**

```astro
---
import { useT, type Locale } from '../../i18n/ui';
import Reveal from '../Reveal.tsx';
const { locale } = Astro.props as { locale: Locale };
const t = useT(locale);
---
<section class="max-w-6xl mx-auto px-6 py-28">
  <Reveal client:visible>
    <h2 class="font-[var(--font-display)] text-4xl sm:text-5xl font-black text-center text-balance mb-16">{t('problem.title')}</h2>
  </Reveal>
  <div class="grid md:grid-cols-2 gap-6">
    <div class="rounded-2xl border border-[var(--color-line)] bg-[var(--color-surface)] p-8 opacity-70">
      <p class="text-sm uppercase tracking-widest text-[var(--color-muted)] mb-4">PDF</p>
      <p class="text-xl">{t('problem.before')}</p>
    </div>
    <div class="rounded-2xl border border-[var(--color-accent)]/40 bg-[var(--color-surface-2)] p-8">
      <p class="text-sm uppercase tracking-widest text-[var(--color-accent)] mb-4">BulkUp</p>
      <p class="text-xl">{t('problem.after')}</p>
    </div>
  </div>
</section>
```

- [ ] **Step 2: Create `FeaturesBento.astro`**

```astro
---
import { useT, type Locale } from '../../i18n/ui';
import Reveal from '../Reveal.tsx';
const { locale } = Astro.props as { locale: Locale };
const t = useT(locale);
const features = [
  { k: 'training', span: 'md:col-span-2' },
  { k: 'diet', span: '' },
  { k: 'rm', span: '' },
  { k: 'body', span: '' },
  { k: 'meals', span: '' },
  { k: 'friends', span: 'md:col-span-2' },
];
---
<section class="max-w-6xl mx-auto px-6 py-28">
  <Reveal client:visible>
    <h2 class="font-[var(--font-display)] text-4xl sm:text-5xl font-black text-center text-balance mb-16">{t('features.title')}</h2>
  </Reveal>
  <div class="grid md:grid-cols-3 gap-4 auto-rows-fr">
    {features.map((f, i) => (
      <Reveal client:visible delay={i * 0.05}>
        <article class={`h-full rounded-2xl border border-[var(--color-line)] bg-[var(--color-surface)] p-7 hover:border-[var(--color-accent)]/50 transition-colors ${f.span}`}>
          <h3 class="text-xl font-semibold mb-2">{t(`feature.${f.k}.title`)}</h3>
          <p class="text-[var(--color-muted)]">{t(`feature.${f.k}.body`)}</p>
        </article>
      </Reveal>
    ))}
  </div>
</section>
```

- [ ] **Step 3: Verify build**

Run: `cd landing && npm run build`
Expected: PASS.

- [ ] **Step 4: Commit**

```bash
git add landing/src/components/sections/ProblemSolution.astro landing/src/components/sections/FeaturesBento.astro
git commit -m "feat(landing): problem/solution + features bento sections"
```

---

### Task 10: PremiumDeepDive + Showcase + PricingTeaser sections

**Files:**
- Create: `landing/src/components/sections/PremiumDeepDive.astro`, `landing/src/components/sections/Showcase.astro`, `landing/src/components/sections/PricingTeaser.astro`

**Interfaces:**
- Consumes: `useT`, `Locale`, `Reveal`.
- Produces: the three section components, each taking `{ locale }`.

- [ ] **Step 1: Create `PremiumDeepDive.astro`**

```astro
---
import { useT, type Locale } from '../../i18n/ui';
import Reveal from '../Reveal.tsx';
const { locale } = Astro.props as { locale: Locale };
const t = useT(locale);
---
<section class="glow relative max-w-6xl mx-auto px-6 py-32 text-center">
  <Reveal client:visible>
    <h2 class="font-[var(--font-display)] text-4xl sm:text-6xl font-black text-balance mb-6">{t('premium.title')}</h2>
    <p class="text-lg text-[var(--color-muted)] max-w-xl mx-auto">{t('premium.body')}</p>
  </Reveal>
</section>
```

- [ ] **Step 2: Create `Showcase.astro`** (placeholder mockups, swappable)

```astro
---
import { useT, type Locale } from '../../i18n/ui';
const { locale } = Astro.props as { locale: Locale };
const t = useT(locale);
---
<section class="max-w-6xl mx-auto px-6 py-28">
  <h2 class="font-[var(--font-display)] text-4xl sm:text-5xl font-black text-center text-balance mb-14">{t('showcase.title')}</h2>
  <div class="flex gap-6 overflow-x-auto snap-x pb-6">
    {[1,2,3,4].map(() => (
      <div class="snap-center shrink-0 w-[240px] h-[500px] rounded-[2rem] border border-[var(--color-line)] bg-[var(--color-surface)] flex items-center justify-center text-[var(--color-muted)] text-sm">Screen</div>
    ))}
  </div>
</section>
```

- [ ] **Step 3: Create `PricingTeaser.astro`**

```astro
---
import { useT, type Locale } from '../../i18n/ui';
const { locale } = Astro.props as { locale: Locale };
const t = useT(locale);
---
<section class="max-w-4xl mx-auto px-6 py-28">
  <h2 class="font-[var(--font-display)] text-4xl sm:text-5xl font-black text-center text-balance mb-14">{t('pricing.title')}</h2>
  <div class="grid sm:grid-cols-2 gap-5">
    <div class="rounded-2xl border border-[var(--color-line)] bg-[var(--color-surface)] p-8">
      <p class="text-[var(--color-muted)] mb-2">{t('pricing.monthly')}</p>
    </div>
    <div class="rounded-2xl border border-[var(--color-accent)]/50 bg-[var(--color-surface-2)] p-8">
      <p class="text-[var(--color-accent)] mb-2">{t('pricing.annual')}</p>
      <p class="text-sm text-[var(--color-muted)]">{t('pricing.annualNote')}</p>
    </div>
  </div>
  <p class="text-center mt-10">
    <a href="#waitlist" class="inline-block rounded-full bg-[var(--color-accent)] text-black font-semibold px-7 py-3.5 hover:scale-105 transition-transform">{t('pricing.cta')}</a>
  </p>
</section>
```

- [ ] **Step 4: Verify build**

Run: `cd landing && npm run build`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add landing/src/components/sections/PremiumDeepDive.astro landing/src/components/sections/Showcase.astro landing/src/components/sections/PricingTeaser.astro
git commit -m "feat(landing): premium deep-dive, showcase, pricing teaser sections"
```

---

### Task 11: Faq + FinalCta + Footer sections

**Files:**
- Create: `landing/src/components/sections/Faq.astro`, `landing/src/components/sections/FinalCta.astro`, `landing/src/components/sections/Footer.astro`

**Interfaces:**
- Consumes: `useT`, `Locale`, `WaitlistForm`, `LanguageSwitch`.
- Produces: the three components, each taking `{ locale }`. (FAQ JSON-LD already emitted by BaseLayout via `faqLd`.)

- [ ] **Step 1: Create `Faq.astro`** (native `<details>` — zero JS)

```astro
---
import { useT, type Locale } from '../../i18n/ui';
const { locale } = Astro.props as { locale: Locale };
const t = useT(locale);
const items = [['faq.q1','faq.a1'],['faq.q2','faq.a2'],['faq.q3','faq.a3'],['faq.q4','faq.a4']];
---
<section class="max-w-3xl mx-auto px-6 py-28">
  <h2 class="font-[var(--font-display)] text-4xl sm:text-5xl font-black text-center text-balance mb-12">{t('faq.title')}</h2>
  <div class="divide-y divide-[var(--color-line)] border-y border-[var(--color-line)]">
    {items.map(([q,a]) => (
      <details class="group py-5">
        <summary class="cursor-pointer list-none flex justify-between items-center text-lg font-medium">
          {t(q)}
          <span class="text-[var(--color-accent)] group-open:rotate-45 transition-transform">+</span>
        </summary>
        <p class="text-[var(--color-muted)] mt-3">{t(a)}</p>
      </details>
    ))}
  </div>
</section>
```

- [ ] **Step 2: Create `FinalCta.astro`**

```astro
---
import { useT, type Locale } from '../../i18n/ui';
import WaitlistForm from '../WaitlistForm.tsx';
const { locale } = Astro.props as { locale: Locale };
const t = useT(locale);
---
<section id="waitlist" class="glow relative overflow-hidden">
  <div class="relative z-10 max-w-3xl mx-auto px-6 py-32 text-center flex flex-col items-center">
    <h2 class="font-[var(--font-display)] text-4xl sm:text-6xl font-black text-balance mb-5">{t('cta.title')}</h2>
    <p class="text-lg text-[var(--color-muted)] mb-8 max-w-md">{t('cta.subtitle')}</p>
    <WaitlistForm client:visible locale={locale}
      ctaLabel={t('cta.button')} placeholder={t('hero.placeholder')}
      successMsg={t('form.success')} errorMsg={t('form.error')} invalidMsg={t('form.invalid')} />
  </div>
</section>
```

- [ ] **Step 3: Create `Footer.astro`**

```astro
---
import { useT, type Locale } from '../../i18n/ui';
import LanguageSwitch from '../LanguageSwitch.astro';
const { locale } = Astro.props as { locale: Locale };
const t = useT(locale);
const year = 2026;
---
<footer class="border-t border-[var(--color-line)]">
  <div class="max-w-6xl mx-auto px-6 py-12 flex flex-col sm:flex-row gap-6 justify-between items-center text-sm text-[var(--color-muted)]">
    <div>
      <p class="font-[var(--font-display)] font-black text-[var(--color-fg)] text-lg">BulkUp</p>
      <p>{t('footer.tagline')}</p>
    </div>
    <LanguageSwitch locale={locale} />
    <p>© {year} BulkUp. {t('footer.rights')}</p>
  </div>
</footer>
```

- [ ] **Step 4: Verify build**

Run: `cd landing && npm run build`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add landing/src/components/sections/Faq.astro landing/src/components/sections/FinalCta.astro landing/src/components/sections/Footer.astro
git commit -m "feat(landing): FAQ, final CTA, footer sections"
```

---

### Task 12: Assemble pages (EN `/` + ES `/es`), sitemap, robots, llms.txt

**Files:**
- Modify: `landing/src/pages/index.astro` (replace scaffold)
- Create: `landing/src/pages/es/index.astro`, `landing/src/pages/sitemap.xml.ts`, `landing/public/robots.txt`, `landing/public/llms.txt`, `landing/public/og-default.png` (placeholder)

**Interfaces:**
- Consumes: every section component + `BaseLayout`.
- Produces: full EN and ES pages, `/sitemap.xml`, `/robots.txt`, `/llms.txt`.

- [ ] **Step 1: Replace `src/pages/index.astro` (EN)**

```astro
---
import BaseLayout from '../layouts/BaseLayout.astro';
import Hero from '../components/sections/Hero.astro';
import SocialProof from '../components/sections/SocialProof.astro';
import ProblemSolution from '../components/sections/ProblemSolution.astro';
import FeaturesBento from '../components/sections/FeaturesBento.astro';
import PremiumDeepDive from '../components/sections/PremiumDeepDive.astro';
import Showcase from '../components/sections/Showcase.astro';
import PricingTeaser from '../components/sections/PricingTeaser.astro';
import Faq from '../components/sections/Faq.astro';
import FinalCta from '../components/sections/FinalCta.astro';
import Footer from '../components/sections/Footer.astro';
const locale = 'en';
---
<BaseLayout locale={locale} path="/">
  <Hero locale={locale} />
  <SocialProof locale={locale} />
  <ProblemSolution locale={locale} />
  <FeaturesBento locale={locale} />
  <PremiumDeepDive locale={locale} />
  <Showcase locale={locale} />
  <PricingTeaser locale={locale} />
  <Faq locale={locale} />
  <FinalCta locale={locale} />
  <Footer locale={locale} />
</BaseLayout>
```

- [ ] **Step 2: Create `src/pages/es/index.astro` (ES)** — identical but `const locale = 'es'` and `path="/es"`

```astro
---
import BaseLayout from '../../layouts/BaseLayout.astro';
import Hero from '../../components/sections/Hero.astro';
import SocialProof from '../../components/sections/SocialProof.astro';
import ProblemSolution from '../../components/sections/ProblemSolution.astro';
import FeaturesBento from '../../components/sections/FeaturesBento.astro';
import PremiumDeepDive from '../../components/sections/PremiumDeepDive.astro';
import Showcase from '../../components/sections/Showcase.astro';
import PricingTeaser from '../../components/sections/PricingTeaser.astro';
import Faq from '../../components/sections/Faq.astro';
import FinalCta from '../../components/sections/FinalCta.astro';
import Footer from '../../components/sections/Footer.astro';
const locale = 'es';
---
<BaseLayout locale={locale} path="/es">
  <Hero locale={locale} />
  <SocialProof locale={locale} />
  <ProblemSolution locale={locale} />
  <FeaturesBento locale={locale} />
  <PremiumDeepDive locale={locale} />
  <Showcase locale={locale} />
  <PricingTeaser locale={locale} />
  <Faq locale={locale} />
  <FinalCta locale={locale} />
  <Footer locale={locale} />
</BaseLayout>
```

- [ ] **Step 3: Create `src/pages/sitemap.xml.ts`**

```ts
import type { APIRoute } from 'astro';
const SITE = 'https://getbulkup.com';
export const prerender = true;
export const GET: APIRoute = () => {
  const urls = ['/', '/es'];
  const body = `<?xml version="1.0" encoding="UTF-8"?>
<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9" xmlns:xhtml="http://www.w3.org/1999/xhtml">
${urls.map((u) => `  <url><loc>${SITE}${u === '/' ? '' : u}</loc>
    <xhtml:link rel="alternate" hreflang="en" href="${SITE}"/>
    <xhtml:link rel="alternate" hreflang="es" href="${SITE}/es"/>
    <xhtml:link rel="alternate" hreflang="x-default" href="${SITE}"/>
  </url>`).join('\n')}
</urlset>`;
  return new Response(body, { headers: { 'content-type': 'application/xml' } });
};
```

- [ ] **Step 4: Create `public/robots.txt`**

```
User-agent: *
Allow: /
Sitemap: https://getbulkup.com/sitemap.xml
```

- [ ] **Step 5: Create `public/llms.txt`**

```
# BulkUp

> AI-powered fitness coaching app (iOS). Upload a PDF or photo of any workout or diet plan and BulkUp's AI turns it into a fully trackable, personalized app.

## What it does
- Smart training plans: templates (PPL, Upper/Lower, Full Body) or AI-imported from your own PDF/photo. Weekly weight logging.
- AI diet parsing: nutrition PDFs become tappable meals, supplements, and rest-day swaps.
- 1RM tracking with a 1000+ exercise database.
- Body composition tracking with historical charts.
- Meal compliance, streaks, friends and leaderboard.

## Status
Pre-launch. Join the waitlist at https://getbulkup.com for early access.

## Pricing
Free trial with monthly and annual premium subscriptions.
```

- [ ] **Step 6: Add a placeholder `public/og-default.png`** (any 1200×630 PNG; replace with branded image later)

Run: `cd landing && printf '' > public/og-default.png` then note in README it must be replaced. (A real 1200×630 PNG is required for valid OG previews.)

- [ ] **Step 7: Build and verify both pages + assets render**

Run: `cd landing && npm run build`
Expected: PASS; build lists `/`, `/es`, `/sitemap.xml`, `/api/waitlist`.

- [ ] **Step 8: Commit**

```bash
git add landing/src/pages landing/public/robots.txt landing/public/llms.txt landing/public/og-default.png
git commit -m "feat(landing): assemble EN/ES pages, sitemap, robots, llms.txt"
```

---

### Task 13: Final verification, README, deploy config

**Files:**
- Create: `landing/README.md`, `landing/vercel.json`

**Interfaces:**
- Produces: deploy docs + Vercel config so the project builds from the `/landing` subdirectory.

- [ ] **Step 1: Create `vercel.json`**

```json
{
  "$schema": "https://openapi.vercel.sh/vercel.json",
  "buildCommand": "npm run build",
  "framework": "astro"
}
```

- [ ] **Step 2: Create `README.md`**

````markdown
# BulkUp Landing

Astro + Tailwind v4 marketing site (EN default `/`, ES `/es`). Waitlist → Resend.

## Develop
```bash
cd landing
cp .env.example .env   # fill RESEND_API_KEY + RESEND_AUDIENCE_ID
npm install
npm run dev
```

## Test
```bash
npm test
```

## Deploy (Vercel)
- Set **Root Directory** = `landing`.
- Add env vars `RESEND_API_KEY`, `RESEND_AUDIENCE_ID`.
- Framework preset: Astro.

## Swap placeholders before launch
- `public/og-default.png` — real 1200×630 OG image.
- `public/favicon.svg`, logo wordmark in `Hero.astro` / `Footer.astro`.
- Device mockups in `Hero.astro` and `Showcase.astro` — real screenshots.
- `SocialProof.astro` / count value.
- Display font `--font-display` in `global.css` (currently a system fallback; add the real webfont).
````

- [ ] **Step 3: Run full check (tests + build + reduced-motion sanity)**

Run: `cd landing && npm test && npm run build`
Expected: tests PASS; build PASS. Manually load `npm run preview`, confirm `/` and `/es` render, language switch works, FAQ accordions open with JS off, and the waitlist form shows the invalid-email state for `bad@`.

- [ ] **Step 4: Validate SEO output**

Run: `cd landing && npm run build && grep -r "application/ld+json" dist | head`
Expected: JSON-LD present in built HTML. Confirm `dist/sitemap.xml`, `dist/robots.txt`, `dist/llms.txt` exist (or are served), and each page has `hreflang` link tags.

- [ ] **Step 5: Commit**

```bash
git add landing/README.md landing/vercel.json
git commit -m "chore(landing): vercel config + README + final verification"
```

---

## Self-Review

**Spec coverage:**
- Pre-launch waitlist (primary CTA) → Tasks 5, 7, 8, 11, 12. ✓
- Bilingual EN-default/ES → Tasks 3, 6, 12 (i18n routing, hreflang, both pages). ✓
- Resend Audience → Task 5. ✓
- Swappable placeholders → Tasks 8/10/12 + README swap list (Task 13). ✓
- Dark athletic aesthetic + tokens → Task 2; sections use the tokens. ✓
- Astro + React islands + Tailwind v4 + Vercel → Tasks 1, 7, 13. ✓
- All 10 sections → Tasks 8–11. ✓
- SEO (meta, OG, hreflang, sitemap, robots, llms.txt, JSON-LD `SoftwareApplication`/`Organization`/`FAQPage`) → Tasks 6, 12. ✓
- Reduced-motion → Task 2 (CSS) + Task 7 (`useReducedMotion`). ✓
- `.env.example`, no real keys → Task 5. ✓
- iOS/backend untouched; self-contained `/landing` → Task 1. ✓

**Placeholder scan:** Visual/content placeholders (mockups, OG image, count) are intentional and tracked in the README swap list — not plan placeholders. No "TBD"/"implement later" steps. ✓

**Type consistency:** `useT(locale)` returns `(key)=>string` used everywhere; `validateWaitlist` signature matches between Task 4 (def), Task 5 (route), and the client regex mirror in Task 7; `WaitlistForm` props match call sites in Tasks 8 and 11; `Reveal` props (`delay`, `y`) match usage in Task 9. ✓

## Notes / Known simplifications (ponytail)

- FAQ uses native `<details>` (zero JS) instead of a JS accordion — same UX, no island.
- No live waitlist counter backend — static number, swap when there's real data.
- Display font is a system fallback until a real webfont is dropped in (one token change).
- Spam protection is a honeypot only; add rate limiting / captcha only if abuse shows up.
