// Locale-aware copy for the waitlist welcome email. Pure + unit-testable.

type WelcomeEmail = { subject: string; html: string; text: string };

const COPY = {
  en: {
    subject: "You're on the BulkUp waitlist 🎉",
    heading: "You're on the list!",
    body: "Thanks for joining the BulkUp waitlist. We'll let you know the moment early access opens — plus launch news and member-only perks.",
    sign: 'Eat, train, grow, repeat.',
  },
  es: {
    subject: 'Estás en la lista de BulkUp 🎉',
    heading: '¡Estás en la lista!',
    body: 'Gracias por unirte a la lista de BulkUp. Te avisaremos en cuanto se abra el acceso anticipado, con novedades del lanzamiento y ventajas exclusivas.',
    sign: 'Come, entrena, crece, repite.',
  },
} as const;

export function welcomeEmail(locale: string): WelcomeEmail {
  const c = locale === 'es' ? COPY.es : COPY.en;
  const html = `<!doctype html><html><body style="margin:0;background:#f5f5f5;font-family:-apple-system,Segoe UI,Roboto,Helvetica,Arial,sans-serif;color:#111">
  <table role="presentation" width="100%" cellpadding="0" cellspacing="0" style="background:#f5f5f5;padding:32px 0">
    <tr><td align="center">
      <table role="presentation" width="100%" cellpadding="0" cellspacing="0" style="max-width:480px;background:#fff;border-radius:16px;padding:32px">
        <tr><td style="font-size:22px;font-weight:700;padding-bottom:12px">${c.heading}</td></tr>
        <tr><td style="font-size:15px;line-height:1.6;color:#444">${c.body}</td></tr>
        <tr><td style="font-size:14px;font-weight:700;color:#111;padding-top:24px">BulkUp — ${c.sign}</td></tr>
      </table>
    </td></tr>
  </table>
</body></html>`;
  const text = `${c.heading}\n\n${c.body}\n\nBulkUp — ${c.sign}`;
  return { subject: c.subject, html, text };
}
