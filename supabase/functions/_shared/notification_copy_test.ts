import {
  assertEquals,
  assertStringIncludes,
} from 'https://deno.land/std@0.168.0/testing/asserts.ts';

import {
  buildAppointmentConfirmedCopy,
  buildAppointmentProposalCopy,
  buildCallRequestCopy,
  buildDefaultAppointmentTitle,
  buildIncomingVideoCallCopy,
  formatAppointmentDateTime,
  normalizeSupportedLocale,
} from './notification_copy.ts';

Deno.test('supported locale normalization accepts language tags and defaults to German', () => {
  assertEquals(normalizeSupportedLocale('de'), 'de');
  assertEquals(normalizeSupportedLocale('de-DE'), 'de');
  assertEquals(normalizeSupportedLocale(' EN_us '), 'en');
  assertEquals(normalizeSupportedLocale('en-GB'), 'en');
  assertEquals(normalizeSupportedLocale('fr-FR'), 'de');
  assertEquals(normalizeSupportedLocale(''), 'de');
  assertEquals(normalizeSupportedLocale(null), 'de');
  assertEquals(normalizeSupportedLocale(undefined), 'de');
});

Deno.test('appointment proposal copy is available in German and English', () => {
  assertEquals(buildAppointmentProposalCopy('de'), {
    title: 'Neue Terminvorschlaege',
    body: 'Waehle einen passenden Termin aus.',
  });
  assertEquals(buildAppointmentProposalCopy('en'), {
    title: 'New Appointment Options',
    body: 'Choose a time that works for you.',
  });
});

Deno.test('call copy is available in German and English', () => {
  assertEquals(buildCallRequestCopy('de'), {
    title: 'Video-Call Anfrage',
    body: 'Ein Klient moechte einen Video-Call starten.',
  });
  assertEquals(buildCallRequestCopy('en'), {
    title: 'Video Call Request',
    body: 'A client would like to start a video call.',
  });
  assertEquals(buildIncomingVideoCallCopy('de'), {
    title: 'Eingehender Video-Call',
    body: 'Tippe, um den Anruf zu öffnen.',
  });
  assertEquals(buildIncomingVideoCallCopy('en'), {
    title: 'Incoming Video Call',
    body: 'Tap to open the call.',
  });
});

Deno.test('appointment confirmation uses recipient language and localized defaults', () => {
  const scheduledFor = '2026-07-15T12:30:00Z';
  const german = buildAppointmentConfirmedCopy({
    locale: 'de',
    traineeName: 'Alex',
    scheduledFor,
  });
  const english = buildAppointmentConfirmedCopy({
    locale: 'en',
    traineeName: null,
    scheduledFor,
  });

  assertEquals(german.title, 'Termin bestaetigt');
  assertStringIncludes(german.body, 'Alex hat');
  assertStringIncludes(german.body, '15.07.2026');
  assertStringIncludes(german.body, '14:30');
  assertEquals(english.title, 'Appointment Confirmed');
  assertStringIncludes(english.body, 'Client accepted the appointment');
  assertStringIncludes(english.body, 'Jul 15, 2026');
  assertStringIncludes(english.body, '2:30 PM');
  assertEquals(
    buildDefaultAppointmentTitle('de'),
    'Isometrische Partneruebung',
  );
  assertEquals(
    buildDefaultAppointmentTitle('en'),
    'Isometric Partner Exercise',
  );
});

Deno.test('appointment time keeps existing Europe/Berlin DST semantics', () => {
  const winter = formatAppointmentDateTime(
    '2026-01-15T12:30:00Z',
    'en',
  );
  const summer = formatAppointmentDateTime(
    '2026-07-15T12:30:00Z',
    'en',
  );

  assertStringIncludes(winter, '1:30 PM');
  assertStringIncludes(summer, '2:30 PM');
});
