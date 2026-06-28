import {
  Html,
  Head,
  Preview,
  Body,
  Container,
  Section,
  Heading,
  Text,
  Button,
  Link,
  Hr,
  Tailwind,
  pixelBasedPreset,
} from 'react-email';

export interface WaitlistConfirmEmailProps {
  confirmUrl: string;
  locale: 'en' | 'es';
}

const copy = {
  en: {
    preview: 'Confirm your email to join the BulkUp waitlist',
    heading: 'Confirm your email',
    body: "You're one tap away from the BulkUp early-access list. Confirm your email and we'll let you know the moment we launch.",
    cta: 'Confirm my email',
    fallback: 'Button not working? Paste this link into your browser:',
    footer: 'This link expires in 48 hours. If you didn\'t request this, you can safely ignore this email.',
  },
  es: {
    preview: 'Confirma tu correo para unirte a la lista de BulkUp',
    heading: 'Confirma tu correo',
    body: 'Estás a un toque de la lista de acceso anticipado de BulkUp. Confirma tu correo y te avisaremos en cuanto lancemos.',
    cta: 'Confirmar mi correo',
    fallback: '¿No funciona el botón? Pega este enlace en tu navegador:',
    footer: 'Este enlace caduca en 48 horas. Si no lo solicitaste, puedes ignorar este correo.',
  },
} as const;

export function WaitlistConfirmEmail({ confirmUrl, locale }: WaitlistConfirmEmailProps) {
  const t = copy[locale] ?? copy.en;
  return (
    <Html lang={locale}>
      <Tailwind
        config={{
          presets: [pixelBasedPreset],
          theme: {
            extend: {
              colors: {
                lime: '#94c51d',
                limeDeep: '#7da817',
                graphite: '#111827',
                muted: '#6b7280',
                fog: '#f5f5f5',
                line: '#e5e7eb',
              },
              fontFamily: {
                sans: ['"Nunito Sans"', 'Helvetica', 'Arial', 'sans-serif'],
              },
            },
          },
        }}
      >
        <Head />
        <Body className="bg-white font-sans">
          <Preview>{t.preview}</Preview>
          <Container className="mx-auto my-[40px] max-w-[600px] rounded-[26px] border border-solid border-line bg-white p-[40px]">
            <Text className="m-0 text-[20px] font-extrabold tracking-tight text-graphite">
              Bulk<span className="text-lime">Up</span>
            </Text>

            <Heading as="h1" className="mb-[8px] mt-[28px] text-[28px] font-extrabold leading-[1.15] tracking-tight text-graphite">
              {t.heading}
            </Heading>
            <Text className="mb-[28px] mt-0 text-[16px] leading-[1.6] text-muted">
              {t.body}
            </Text>

            <Section className="mb-[28px]">
              <Button
                href={confirmUrl}
                className="box-border inline-block rounded-[16px] bg-lime px-[28px] py-[14px] text-[16px] font-bold text-graphite no-underline"
              >
                {t.cta}
              </Button>
            </Section>

            <Text className="mb-[6px] mt-0 text-[13px] leading-[1.5] text-muted">{t.fallback}</Text>
            <Link href={confirmUrl} className="text-[13px] text-limeDeep underline">
              {confirmUrl}
            </Link>

            <Hr className="my-[28px] border-none border-t border-solid border-line" />
            <Text className="m-0 text-[12px] leading-[1.5] text-muted">{t.footer}</Text>
          </Container>
        </Body>
      </Tailwind>
    </Html>
  );
}

WaitlistConfirmEmail.PreviewProps = {
  confirmUrl: 'https://getbulkup.com/api/waitlist/confirm?token=preview',
  locale: 'en',
} satisfies WaitlistConfirmEmailProps;

export default WaitlistConfirmEmail;
