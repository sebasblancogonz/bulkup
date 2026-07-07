export const locales = ['en', 'es'] as const;
export type Locale = (typeof locales)[number];
export const defaultLocale: Locale = 'en';

export const ui = {
  en: {
    'meta.title': 'BulkUp — your training and diet plan, finally measurable set by set',
    'meta.description': 'Import your coach\'s PDF or photo and track every set, weight, PR and meal on iOS + Apple Watch. Measurable training and diet in one app — join the waitlist for founder access.',

    // NAV
    'nav.features': 'Features',
    'nav.faq': 'FAQ',
    'nav.cta': 'Join',

    // HERO
    'hero.eyebrow': 'TRAIN. LOG. PROGRESS.',
    'hero.title': 'Your plan, turned into an app that measures.',
    'hero.subtitle': 'Drop a photo or the PDF and the app logs every set, meal and kilo for you.',
    'hero.cta': 'I want in',
    'hero.placeholder': 'you@email.com',
    'hero.reassure': 'No spam. Just the launch heads-up.',

    // DATA STRIP
    'data.exercises': '1,000+ exercises',
    'data.formulas': 'Real 1RM formulas',
    'data.platform': 'iOS + Apple Watch',

    // HOW IT WORKS
    'howitworks.title': 'From a dead PDF to a plan that lives with you',
    'howitworks.before': 'A PDF lost in Downloads',
    'howitworks.after': 'A plan you log every week',
    'howitworks.s1.t': 'Upload',
    'howitworks.s1.b': 'The photo or PDF of your plan. Once.',
    'howitworks.s2.t': 'Train',
    'howitworks.s2.b': 'Log every set and weight from your phone or wrist.',
    'howitworks.s3.t': 'Eat',
    'howitworks.s3.b': 'Follow your diet and tick what you eat. No fighting the paper.',
    'howitworks.s4.t': 'Measure',
    'howitworks.s4.b': 'Weights, maxes and progress, history up front.',

    // FEATURES
    'training.eyebrow': 'TRAINING',
    'training.metric': 'PRs',
    'training.title': 'Sets, weights and PRs',
    'training.body': "Import yours or start with PPL, Upper/Lower or Full Body. Log each week's weight and see if you're climbing or stalling. Your maxes with the classic formulas across 1,000+ exercises: you know when it's time to add weight.",
    'diet.eyebrow': 'DIET',
    'diet.title': 'Your diet stops being a sheet of paper',
    'diet.body': "Upload your nutrition plan and meals, supplements and the rest-day swap are right there. Tick what you eat and you're done.",
    'progress.title': 'See how much you’ve added',
    'progress.body': "Weight, body fat, lean mass and measurements, history up front. The mirror lies; the numbers don't. And the Apple Watch logs heart rate and calories from your wrist.",
    'progress.sample': 'sample data',
    'community.eyebrow': 'COMMUNITY',
    'community.title': 'Compete with your crew',
    'community.body': 'Daily check-in and your real adherence %. Add your crew by code, compare streaks and see who slips first. Spoiler: not you.',

    // FAQ
    'faq.eyebrow': 'FAQ',
    'faq.title': 'What everyone asks',
    'faq.q1': 'What is BulkUp, exactly?',
    'faq.a1': 'You take the plan your coach already gave you (PDF or photo) and BulkUp turns it into an app where you log sets, meals and progress. The plan is yours; we put the numbers on it.',
    'faq.q2': 'Does it really read my PDF, or do I copy it by hand?',
    'faq.a2': "You read it once and never touch it again. Upload the file or photo, we process it, and you get an editable plan, day by day. If something's off, you fix it in two taps.",
    'faq.q3': 'When can I use it?',
    'faq.a3': "We're nearly there. Join the list and you're among the first to try it — we'll ping you the day it opens, no spam.",
    'faq.q4': 'How much does it cost?',
    'faq.a4': 'Joining the list is free. You start with a free trial, and list members get founder pricing.',

    // CTA FINAL
    'cta.title': 'The list goes first',
    'cta.subtitle': 'Join the list, get BulkUp before anyone else, and lock in founder pricing.',
    'cta.button': 'Give me access',

    // FORM
    'form.success': "You're in. Check your inbox to confirm.",
    'form.sending': 'Sending…',
    'form.error': 'Something went wrong. Try again.',
    'form.errorRate': 'Too many tries, give it a moment.',
    'form.invalid': 'Enter a valid email.',
    'form.reassure': 'No spam. Just the launch heads-up.',

    // FOOTER
    'footer.tagline': 'Fewer PDFs, more reps.',
    'footer.rights': 'All rights reserved.',
  },
  es: {
    'meta.title': 'BulkUp — tu plan de entreno y dieta, por fin medible serie a serie',
    'meta.description': 'Importa el PDF o foto de tu entrenador y registra series, pesos, PRs y comidas en iOS + Apple Watch. Entreno y dieta medibles en una app — únete a la lista para precio de fundador.',

    // NAV
    'nav.features': 'Funciones',
    'nav.faq': 'FAQ',
    'nav.cta': 'Entrar',

    // HERO
    'hero.eyebrow': 'ENTRENA. REGISTRA. PROGRESA.',
    'hero.title': 'Tu plan, convertido en una app que mide.',
    'hero.subtitle': 'Sube una foto o el PDF y la app registra cada serie, comida y kilo por ti.',
    'hero.cta': 'Quiero probarlo',
    'hero.placeholder': 'tu@email.com',
    'hero.reassure': 'Sin spam. Solo el aviso de lanzamiento.',

    // DATA STRIP
    'data.exercises': '1.000+ ejercicios',
    'data.formulas': 'Fórmulas de 1RM reales',
    'data.platform': 'iOS + Apple Watch',

    // HOW IT WORKS
    'howitworks.title': 'De un PDF muerto a un plan que vive contigo',
    'howitworks.before': 'Un PDF perdido en Descargas',
    'howitworks.after': 'Un plan que registras cada semana',
    'howitworks.s1.t': 'Sube',
    'howitworks.s1.b': 'La foto o el PDF de tu plan. Una vez.',
    'howitworks.s2.t': 'Entrena',
    'howitworks.s2.b': 'Registra cada serie y cada peso desde el móvil o la muñeca.',
    'howitworks.s3.t': 'Come',
    'howitworks.s3.b': 'Sigue tu dieta y tacha lo que comes. Sin pelearte con el papel.',
    'howitworks.s4.t': 'Mide',
    'howitworks.s4.b': 'Pesos, máximos y progreso, con el histórico delante.',

    // FEATURES
    'training.eyebrow': 'ENTRENO',
    'training.metric': 'PRs',
    'training.title': 'Series, pesos y PRs',
    'training.body': 'Importa la tuya o arranca con PPL, Torso/Pierna o Full Body. Apuntas el peso de cada semana y ves si subes o te estancas. Tus máximos con las fórmulas de toda la vida sobre +1.000 ejercicios: sabes cuándo toca subir barra.',
    'diet.eyebrow': 'DIETA',
    'diet.title': 'Tu dieta deja de ser un papel',
    'diet.body': 'Subes tu plan de nutrición y quedan a mano comidas, suplementos y el cambio de día de descanso. Tachas lo que comes y listo.',
    'progress.title': 'Mira cuánto has subido',
    'progress.body': 'Peso, grasa, masa magra y medidas, con el histórico delante. El espejo miente; los números no. Y el Apple Watch registra pulsaciones y calorías desde la muñeca.',
    'progress.sample': 'datos de ejemplo',
    'community.eyebrow': 'COMUNIDAD',
    'community.title': 'Pícate con los tuyos',
    'community.body': 'Check-in diario y tu % de cumplimiento real. Añade a tus colegas por código, comparad rachas y a ver quién falla primero. Spoiler: tú no.',

    // FAQ
    'faq.eyebrow': 'FAQ',
    'faq.title': 'Lo que todo el mundo pregunta',
    'faq.q1': '¿Qué es BulkUp exactamente?',
    'faq.a1': 'Coges el plan que ya te pasó tu entrenador (en PDF o foto) y BulkUp lo convierte en una app donde registras series, comidas y progreso. El plan es tuyo; nosotros le ponemos los números.',
    'faq.q2': '¿De verdad lee mi PDF o lo copio a mano?',
    'faq.a2': 'Lo lees tú una vez y no vuelves a tocarlo. Subes el archivo o la foto, lo procesamos y te queda un plan editable, día a día. Si algo no cuadra, lo ajustas en dos toques.',
    'faq.q3': '¿Cuándo lo puedo usar?',
    'faq.a3': 'Estamos a punto. Entra en la lista y eres de los primeros en probarlo — te avisamos el día que abre, sin spam.',
    'faq.q4': '¿Cuánto cuesta?',
    'faq.a4': 'Entrar en la lista es gratis. Empiezas con prueba gratis y quien entra desde la lista se lleva precio de fundador.',

    // CTA FINAL
    'cta.title': 'La lista entra primero',
    'cta.subtitle': 'Entra en la lista, estrena BulkUp antes que nadie y llévate el precio de fundador.',
    'cta.button': 'Dame acceso',

    // FORM
    'form.success': 'Estás dentro. Revisa tu correo para confirmar.',
    'form.sending': 'Enviando…',
    'form.error': 'Algo salió mal. Inténtalo de nuevo.',
    'form.errorRate': 'Demasiados intentos, espera un momento.',
    'form.invalid': 'Introduce un email válido.',
    'form.reassure': 'Sin spam. Solo el aviso de lanzamiento.',

    // FOOTER
    'footer.tagline': 'Menos PDFs, más repeticiones.',
    'footer.rights': 'Todos los derechos reservados.',
  },
} as const;

export function useT(locale: Locale) {
  return (key: string): string =>
    (ui[locale] as Record<string, string>)[key] ??
    (ui.en as Record<string, string>)[key] ??
    key;
}
