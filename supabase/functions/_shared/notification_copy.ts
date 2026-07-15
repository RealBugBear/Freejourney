export type SupportedLocale = 'de' | 'en';

export interface NotificationCopy {
  title: string;
  body: string;
}

export interface AppointmentConfirmedCopyInput {
  locale: SupportedLocale;
  traineeName?: string | null;
  scheduledFor: string;
  timeZone?: string;
}

// Appointment notifications historically render scheduled_for in Berlin time.
// Keep that behavior so localization cannot shift an existing appointment; the
// recipient locale controls only the language and date/time presentation.
export const APPOINTMENT_TIME_ZONE = 'Europe/Berlin';

export function normalizeSupportedLocale(locale: unknown): SupportedLocale {
  if (typeof locale !== 'string') return 'de';

  const language =
    locale.trim().toLowerCase().replaceAll('_', '-').split('-')[0];
  return language === 'en' ? 'en' : 'de';
}

export function buildAppointmentProposalCopy(
  locale: SupportedLocale,
): NotificationCopy {
  if (locale === 'en') {
    return {
      title: 'New Appointment Options',
      body: 'Choose a time that works for you.',
    };
  }

  return {
    title: 'Neue Terminvorschlaege',
    body: 'Waehle einen passenden Termin aus.',
  };
}

export function buildAppointmentConfirmedCopy(
  input: AppointmentConfirmedCopyInput,
): NotificationCopy {
  const when = formatAppointmentDateTime(
    input.scheduledFor,
    input.locale,
    input.timeZone,
  );
  const traineeName = input.traineeName ?? buildDefaultClientLabel(input.locale);

  if (input.locale === 'en') {
    return {
      title: 'Appointment Confirmed',
      body:
        `${traineeName} accepted the appointment for ${when}. Tap to view it in your calendar.`,
    };
  }

  return {
    title: 'Termin bestaetigt',
    body: `${traineeName} hat ${when} angenommen. Tippe zum Kalendereintrag.`,
  };
}

export function buildDefaultAppointmentTitle(
  locale: SupportedLocale,
): string {
  return locale === 'en'
    ? 'Isometric Partner Exercise'
    : 'Isometrische Partneruebung';
}

export function buildDefaultClientLabel(locale: SupportedLocale): string {
  return locale === 'en' ? 'Client' : 'Klient';
}

export function buildCallRequestCopy(
  locale: SupportedLocale,
): NotificationCopy {
  if (locale === 'en') {
    return {
      title: 'Video Call Request',
      body: 'A client would like to start a video call.',
    };
  }

  return {
    title: 'Video-Call Anfrage',
    body: 'Ein Klient moechte einen Video-Call starten.',
  };
}

export function buildIncomingVideoCallCopy(
  locale: SupportedLocale,
): NotificationCopy {
  if (locale === 'en') {
    return {
      title: 'Incoming Video Call',
      body: 'Tap to open the call.',
    };
  }

  return {
    title: 'Eingehender Video-Call',
    body: 'Tippe, um den Anruf zu öffnen.',
  };
}

export function formatAppointmentDateTime(
  scheduledFor: string,
  locale: SupportedLocale,
  timeZone = APPOINTMENT_TIME_ZONE,
): string {
  return new Intl.DateTimeFormat(localeTag(locale), {
    dateStyle: 'medium',
    timeStyle: 'short',
    timeZone,
  }).format(new Date(scheduledFor));
}

function localeTag(locale: SupportedLocale): string {
  return locale === 'en' ? 'en-US' : 'de-DE';
}
