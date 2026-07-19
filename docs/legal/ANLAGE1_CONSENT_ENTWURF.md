# Anlage 1 — In-App-Einwilligungstext (Consent-Screen), Entwurfsfassung DE + EN

> **⚠️ ENTWURF — zur anwaltlichen Prüfung (Briefing Leistung 4).**
> Stand: 19.07.2026. Dieser Text ist die wörtliche Extraktion des im
> App-Code vorbereiteten Launch-Entwurfs (Datei
> `lib/features/consent/presentation/screens/consent_screen.dart`,
> T05 Stufe 1 vom 07.07.2026). Er ist **noch nicht aktiv** — die App zeigt
> derzeit die alte Testphasen-Fassung (bekannte Abweichung, Briefing
> Abschnitt 4). Nach Ihrer Freigabe wird dieser Text aktiviert und alle
> Bestandsnutzer willigen über die vorhandene Re-Consent-Mechanik
> (Versions-Bump) neu ein.
>
> **Kontext der Anzeige:** Der Text erscheint beim ersten App-Start als
> scrollbare Punkteliste mit Symbolen; der Nutzer bestätigt aktiv per
> Button („Ich stimme zu“), ohne Zustimmung ist die App nicht nutzbar.
> Die deutsche Fassung ist führend; die englische ist unsere Übersetzung.

---

## Deutsche Fassung

**Datenschutzerklärung**

Diese Datenschutzerklärung informiert dich darüber, wie Reflex Journey
personenbezogene Daten gemäß DSGVO verarbeitet.

**Verantwortlicher** — Verantwortlicher im Sinne der DSGVO: Alexander
Messinger. Kontakt für Datenschutzanfragen: über die in der App
hinterlegten Kontaktdaten.

**Erhobene Daten** — Wir verarbeiten: E-Mail-Adresse und Passwort
(Registrierung), Fortschrittsdaten (Trainingseinheiten,
Einstiegsfragebogen), Stimmungs- und Journaldaten, deine optionale Angabe
zum Einstiegsbereich, Geräteinformationen (Betriebssystem, App-Version)
sowie — wenn du Mitteilungen aktivierst — ein Geräte-Token für
Push-Nachrichten.

**Profile für Kinder** — Profile für Kinder werden ausschließlich durch
den erziehungsberechtigten Kontoinhaber angelegt und verwaltet. Die Daten
des Kindes (z. B. Name, Geburtsdatum, Trainingsfortschritt) gehören zu
deinem Konto und werden wie deine eigenen Daten geschützt.

**Standort & Karte** — Dein Standort wird nur auf deine Anfrage für die
Trainer-Suche verwendet und nicht gespeichert. Beim Anzeigen der Karte
werden Kartenkacheln von Servern der OpenStreetMap Foundation geladen;
diese erhält dabei technisch bedingt deine IP-Adresse und das angezeigte
Kartengebiet.

**Zweck der Verarbeitung** — Bereitstellung der App-Funktionen,
Speicherung und Synchronisierung deines Trainingsfortschritts, Zustellung
von Mitteilungen und Erinnerungen sowie System-E-Mails zu deinem Konto
(z. B. Registrierungs-Bestätigung, Passwort-Zurücksetzen).

**Datenverarbeitung & Speicherort** — Deine Daten werden verschlüsselt
auf Servern von Supabase (EU-Region) gespeichert. Lokal auf deinem Gerät
werden Daten für die Offline-Funktionalität in einer app-eigenen
Datenbank gehalten, die nur diese App lesen kann, durch die
Geräteverschlüsselung deines Betriebssystems geschützt ist und von
Geräte-Backups ausgeschlossen wird.

**Auftragsverarbeiter & Empfänger** — Deine Daten werden nicht verkauft.
Eine Übermittlung erfolgt nur an technische Dienstleister im Rahmen der
Auftragsverarbeitung (Art. 28 DSGVO): Supabase (Datenbank und Anmeldung,
EU-Region), Google Firebase Cloud Messaging (Zustellung von
Push-Nachrichten), Resend (Versand von System-E-Mails) und Sentry
(anonymisierte Absturzberichte: Fehlertyp, technischer Ablauf,
Gerätemodell — keine Inhalte, EU-Datenhaltung). Beim Kartenabruf in der
Trainer-Suche ist die OpenStreetMap Foundation externer Empfänger
(IP-Adresse, Kartengebiet).

**Push-Benachrichtigungen** — Erinnerungen können lokal auf deinem Gerät
geplant werden. Für Mitteilungen (z. B. Nachrichten deines Trainers) wird
ein Geräte-Token über Google Firebase Cloud Messaging verarbeitet.
Mitteilungen kannst du in den Systemeinstellungen jederzeit deaktivieren.

**Speicherdauer** — Deine Daten bleiben gespeichert, bis du dein Konto
löschst. Konto und Daten kannst du jederzeit direkt in der App löschen;
Details zur Speicherdauer einzelner Datenarten regelt die
Datenschutzerklärung.

**Deine Rechte (DSGVO)** — Du hast das Recht auf: Auskunft (Art. 15),
Berichtigung (Art. 16), Löschung (Art. 17), Einschränkung der
Verarbeitung (Art. 18), Datenübertragbarkeit (Art. 20) und Widerspruch
(Art. 21). Zur Geltendmachung deiner Rechte kontaktiere uns über die App.

*Abschluss:* Die vollständige Datenschutzerklärung findest du jederzeit
unter reflexjourney.app/datenschutz.

---

## Englische Fassung (unsere Übersetzung, zur Freigabe)

**Privacy Policy**

This Privacy Policy explains how Reflex Journey processes personal data in
accordance with the GDPR.

**Data Controller** — The data controller within the meaning of the GDPR:
Alexander Messinger. For privacy inquiries, use the contact information
provided in the app.

**Data We Process** — We process: email address and password
(registration), progress data (training sessions, intake questionnaire),
mood and journal data, your optional entry-point selection, device
information (OS, app version), and — if you enable notifications — a
device token for push messages.

**Profiles for Children** — Profiles for children are created and managed
exclusively by the parent or guardian who owns the account. The child's
data (e.g. name, date of birth, training progress) belongs to your
account and is protected like your own data.

**Location & Map** — Your location is used only at your request for the
trainer search and is never stored. When the map is shown, map tiles are
loaded from servers of the OpenStreetMap Foundation, which technically
receives your IP address and the displayed map area.

**Purpose of Processing** — Providing app features, storing and syncing
your training progress, delivering notifications and reminders, and
sending account emails (e.g. sign-up confirmation, password reset).

**Data Processing & Storage** — Your data is stored encrypted on Supabase
servers (EU region). Locally on your device, data is held for offline
functionality in an app-private database that only this app can read, is
protected by your operating system's device encryption, and is excluded
from device backups.

**Processors & Recipients** — Your data is never sold. It is transmitted
only to technical service providers under data processing agreements
(Art. 28 GDPR): Supabase (database and authentication, EU region), Google
Firebase Cloud Messaging (push delivery), Resend (system emails), and
Sentry (anonymised crash reports: error type, technical trace, device
model — no content, EU data residency). When the trainer-search map is
displayed, the OpenStreetMap Foundation is an external recipient (IP
address, map area).

**Push Notifications** — Reminders can be scheduled locally on your
device. For messages (e.g. from your trainer), a device token is
processed via Google Firebase Cloud Messaging. You can disable
notifications in your system settings at any time.

**Retention Period** — Your data is stored until you delete your account.
You can delete your account and data at any time directly in the app;
retention details for individual data types are set out in the Privacy
Policy.

**Your Rights (GDPR)** — You have the right to: access (Art. 15),
rectification (Art. 16), erasure (Art. 17), restriction of processing
(Art. 18), data portability (Art. 20), and objection (Art. 21). To
exercise your rights, contact us via the app.

*Closing:* You can find the full Privacy Policy at any time at
reflexjourney.app/datenschutz.

---

## Beleg-Liste (aus dem Code übernommen — jede Behauptung ist belegt)

- „Supabase, EU-Region“ → Projektregion West-EU (Irland), verifiziert 02.07.2026.
- „app-eigene DB, Geräteverschlüsselung, von Backups ausgeschlossen“ →
  iOS: backup-ausgeschlossenes Verzeichnis; Android: `allowBackup=false`
  (Commit `c654998`).
- „Konto und Daten jederzeit in der App löschbar“ → In-App-Löschung ruft
  serverseitige Löschfunktion und wischt alle lokalen Nutzertabellen.
- „Standort nur auf Anfrage, nicht gespeichert“ + „OSMF erhält IP und
  Kartengebiet“ → Standort-Datenfluss-Dokumentation (Anlage 2);
  Datenbankfunktion ist schreibgeschützt (`STABLE`), kein Persistenzpfad.
- „Geräte-Token über Firebase Cloud Messaging“ → Push-Modul + Tabelle
  `device_tokens` mit Zugriffsregeln.
- „Resend (System-E-Mails)“ → eigene Versand-Domain `send.reflexjourney.de`.
- „Kinderprofile durch Kontoinhaber“ → eigene Tabelle, Zugriff nur für den
  Kontoinhaber (Row Level Security), kein Kinder-Login.
- Kein Tracking/keine Analytics behauptet → keine Analytics-/Werbe-SDKs in
  den App-Abhängigkeiten.
- Agora (Video-Calls) bewusst nicht genannt → Funktion im Launch-Build
  deaktiviert; vor Reaktivierung wird der Text erweitert.
- „Sentry (Absturzberichte)“ → PII-Versand deaktiviert, Request-Daten
  werden vor Versand entfernt; nur Fehlertyp, Stacktrace, Gerätekontext;
  EU-Datenhaltung.
