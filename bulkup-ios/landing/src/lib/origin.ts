/**
 * Public-facing origin for building absolute URLs (confirm links, redirects).
 *
 * On Vercel's serverless runtime `request.url` is the INTERNAL address
 * (e.g. `https://localhost`), not the public host — so absolute URLs built from
 * it break in production. In production we use the Astro-configured `site`
 * (`https://getbulkup.com`), which is the canonical public origin and not
 * spoofable via headers. In dev the request origin IS the real localhost, so we
 * use it there (keeps local testing working).
 */
export function publicOrigin(opts: { site?: URL; request: Request; isDev: boolean }): string {
  if (opts.isDev) return new URL(opts.request.url).origin;
  return opts.site?.origin ?? new URL(opts.request.url).origin;
}
