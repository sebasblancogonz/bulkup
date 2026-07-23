# US SEO for BulkUp landing (getbulkup.com)

**Goal:** get US organic traffic into the waitlist. Site is live but not indexed by Google.

## Problems found
- `site:getbulkup.com` returns nothing — never submitted to Search Console.
- Single-page site: only rankable for brand terms.
- EN meta title is brand-led ("finally measurable set by set"), matches no search query.

## Design
1. **Indexing (user action):** owner verifies domain in Google Search Console (DNS TXT via Vercel, or meta tag) and submits `sitemap.xml`. Code side: meta verification tag slot if token provided.
2. **On-page:** rewrite EN `meta.title`/`meta.description` for US search intent (workout tracker, import coach's plan PDF, iOS + Apple Watch). ES copy unchanged.
3. **Content pages (EN-only, each with waitlist CTA, Article JSON-LD, in sitemap, linked from footer):**
   - `/import-workout-pdf` — "turn your coach's PDF into a trackable plan" (bottom-funnel, weak competition)
   - `/bulkup-vs-hevy` — comparison, honest, marks BulkUp as pre-launch
   - `/bulkup-vs-strong` — same
   - `/apple-watch-workout-tracker` — short guide
4. **Layout:** new `ArticleLayout.astro` (BaseLayout + Header + prose + FinalCta + Footer). BaseLayout gets a flag to skip hreflang alternates on EN-only pages.

## Out of scope (YAGNI)
Blog/content collections, ES versions of content pages, listicles, paid/social. Add later if these pages get traffic.
