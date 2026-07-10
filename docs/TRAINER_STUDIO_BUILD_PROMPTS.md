# Trainer Studio — ausführbare Build-Prompts (T27.1–T27.6)

**Stand:** 2026-07-10 · **Anlass:** Founder-Anfrage 2026-07-10 („finished plan
to just prompt and build trainer studio")
**Product Source of Truth:** `docs/superpowers/specs/2026-07-08-trainer-studio-design.md`
**Prozess-Rahmen:** `docs/TRAINER_STUDIO_PROMPT.md` (P0–P4-Gates) ·
Kaufweg/Plattform: `docs/PAYMENTS_MASTER_PLAN.md`

> **Einordnung — ehrlich gesagt:** Der Planning-Prompt sieht vor, Build-Prompts
> erst nach P4-GO auszuarbeiten. Der Founder hat am 2026-07-10 ausdrücklich
> die fertige Build-Fassung angefordert — deshalb existiert diese Datei jetzt.
> Die Gates selbst sind damit NICHT aufgehoben: jeder Prompt nennt sein Gate,
> und die Ausführung setzt den dokumentierten Founder-Go voraus (oder dessen
> ausdrücklichen Verzicht — das ist allein Founder-Sache). Empfehlung zur
> Gate-Kompression steht in §2.

## 1. Founder-Entscheidungspaket — eine Nachricht genügt

Damit „nur noch prompten" real wird, braucht es genau diese Entscheidungen.
Jede hat eine Empfehlung; ein „Go TS-6/7/10 wie empfohlen" reicht als Antwort.

### TS-7 — Plattform: **Empfehlung: plattformneutral bauen, iOS-first pilotieren**

Der Code ist via RevenueCat ohnehin für beide Plattformen identisch
(`PAYMENTS_MASTER_PLAN.md` §2). Es gibt keinen technischen Grund, Android
auszuschließen — nur den betrieblichen, den Pilot klein zu halten. Konkret:
alle T27-Workstreams plattformneutral; Pilot-Kohorte startet auf iOS; Android
wird freigeschaltet, sobald T25.3 (Play Billing fürs Nutzer-Abo) bewährt ist.
Das erfüllt „alle Geräte" ohne den Pilot zu verzögern.

### TS-6 — Gründer-Vorteil: **Empfehlung: Preis-Grandfathering statt „50 % für immer"**

„Dauerhaft 50 %" ist mit Store-Mechanik nicht sauber garantierbar (Spec §8.3).
Robust und ehrlich ist: **Studio startet für Gründungs-Trainer zum
Pilot-Preis (z. B. 7,99 €/Monat / 69,99 €/Jahr); spätere Preiserhöhungen
gelten nur für Neu-Abonnenten — Bestandsabos behalten ihren Preis** (Standard-
Grandfathering beider Stores; Mechanik bei T27.6 gegen aktuelle Store-Doku
verifizieren). Kommunizierbares Versprechen: *„Als Gründungs-Trainer behältst
du dauerhaft deinen Startpreis, solange dein Abo aktiv bleibt."* Kein
Prozentversprechen, keine separaten Rabatt-Produkte, keine Offer-Code-Grenzen.

### TS-10 — Preis/Trial: **Empfehlung: Hypothese 14,99 €/Monat · 119,99 €/Jahr · 14 Tage Trial beibehalten**

Endgültig erst nach den Preisfragen aus den Interviews (Spec §10, vier
Preisfragen) und vor T27.6. Preise erscheinen in der App ausschließlich aus
dem Store (lokalisiert, Trial-Berechtigung via StoreKit/Play).

### TS-8/TS-9 — v1-Scope und Sitzungsprotokolle

TS-8 (finaler v1-Scope) fällt nach dem Konzepttest; bis dahin gilt der
Spec-Scope: **Klienten-Briefing + Termin-Automation, sonst nichts.**
TS-9 (Sitzungsprotokolle) bleibt hinter dem vollen Legal-/Security-Go —
T27.5 wird ohne dieses Go nicht ausgeführt, Studio v1 ist auch ohne
Protokolle vollständig.

## 2. Empfohlene Gate-Kompression (Founder entscheidet)

Die P1/P2-Research-Gates schützen vor dem teuersten Fehler (das falsche
Briefing bauen) — und kosten **keine Kalenderzeit**, wenn sie parallel zur
ohnehin bestehenden Wartezeit laufen (T25 ist extern blockiert, Build-Trigger
verlangt ohnehin „Launch ≥ 4 Wochen stabil + T25 bewährt + 8–10 aktive
Trainer"). Empfehlung:

- **Jetzt:** Founder-Go zu diesem Dokument (ersetzt P0) + Entscheidungen §1.
- **Parallel zur Launch-/T25-Phase:** P1 komprimiert (5 Interviews à 25 Min.,
  Leitfaden liegt in Spec §10) + P2 als Low-Fi-Test mit denselben Trainern.
- **P3:** Datenvertragsmatrix entsteht als Teil von T27.3 (Prompt unten
  erzwingt sie); Anwalts-Teil läuft über das bestehende Briefing
  (`trainer_notes`/`mood_checkins` sind dort schon als Launch-Thema markiert).
- **P4:** bleibt als 30-Minuten-GO/NO-GO-Check vor dem ersten Build-Prompt.

Wer schneller will, kann P1/P2 streichen — dann ist das Risiko dokumentiert
(Spec §0 Punkt 7, §12 Stoppbedingungen) und bewusst getragen.

## 3. Gemeinsame Hausregeln aller Build-Prompts

Für jeden Prompt gelten zusätzlich zu CLAUDE.md:

- Arbeit vollständig hinter neuem Compile-Flag `kTrainerStudioEnabled=false`
  (Muster + Doku-Pflichten aus `lib/config/launch_flags.dart`; Skill
  `feature-gate` verwenden). Flag-aus = exakt heutiges Verhalten, per Test belegt.
- Kostenlos Bestehendes bleibt kostenlos (Spec §6) — kein Entzug, keine
  Locked-States auf heutigen Funktionen.
- Sprache neutral: keine Scores/Risiko-/Wirkaussagen; „Erinnerung geplant",
  nie „zugestellt" (Spec §5.3).
- Berechtigung serverseitig aus aktiver Trainer-Klient-Beziehung + Freigabe
  (RLS), nie nur UI (Spec §7).
- DE+EN l10n, Dark Mode, 150 % Schrift, 44-pt-Touchziele, Empty/Loading/
  Offline/Error/Locked/„Freigabe beendet" gestaltet (Spec §13).
- Live-DDL/Deploys/Store-Änderungen nur mit Founder-Go; Evidenz redigiert
  nach `docs/evidence/T27/<workstream>/`.

## 4. Die Build-Prompts

### T27.1 — Studio-Entitlement + Rollout-Fundament *(Gate: P4-GO + T25.2 existiert)*

**Rolle:** Backend-orientierte:r Flutter-/Supabase-Entwickler:in.
**Lies zuerst:** `supabase/migrations/2026070701_premium_entitlements.sql`
(Schutz-Trigger-Muster), `lib/features/premium/domain/entitlement.dart`,
`PAYMENTS_MASTER_PLAN.md` §2, Spec §11.
**Scope:**
1. Migration (lokal, Live-Apply gated): `trainer_profiles` +
   `studio_active boolean NOT NULL DEFAULT false`,
   `studio_valid_until timestamptz`, `studio_source text CHECK (IN
   ('store','pilot'))`; Schutz-Trigger nach T23-Muster (nur service_role).
2. Pilot-Allowlist: `studio_source='pilot'` wird per Admin-/Runbook-Weg
   gesetzt (Runbook analog `ACCESS_CODES_RUNBOOK.md`), damit der Pilot ohne
   Käufe starten kann.
3. `revenuecat-webhook` (T25.2) um das `studio`-Entitlement-Mapping →
   `trainer_profiles` erweitern (inkl. Ablauf-/Schutzlogik analog Premium).
4. Flutter: `StudioEntitlement`-Modell + Repository (Offline-Cache,
   fail-closed) + Riverpod-Provider nach Premium-Vorbild; Flag
   `kTrainerStudioEnabled` anlegen.
5. Kill-Switch-Semantik dokumentieren: Flag aus → Studio-UI weg, Entitlements
   bleiben serverseitig unangetastet.
**Akzeptanz:** `supabase db reset --local` grün; Trigger-Negativtest (Client
kann sich nicht selbst freischalten); Webhook-Tests für Studio-Fälle; Suite
grün; keine UI-Änderung sichtbar.
**Nicht-Ziele:** keine Screens, keine Store-Produkte, kein Live-Apply ohne Go.

### T27.2 — Studio-Einstieg, Locked Preview, Paywall *(Gate: P4-GO + T27.1 + P2-Konzepttest bestanden)*

**Rolle:** Flutter-UI-Entwickler:in mit Gespür für ruhige Oberflächen.
**Lies zuerst:** Spec §4–§5 (IA + Blueprints — verbindlich), §13;
`trainer_dashboard_screen.dart`, `paywall_screen.dart` (Muster).
**Scope:**
1. „Heute"-Arbeitsüberblick als verbesserte Einstiegsschicht im Klienten-Tab
   (Spec §5.1): Termine heute, max. 3 Aufmerksamkeits-Hinweise, Klientenliste.
   Kostenlose Bestandteile bleiben frei; nur neue Automatik-/Verlaufssignale
   tragen Studio-Kennzeichnung.
2. Locked Preview: ehrlich (zeigt Struktur, keine fingierten Daten),
   eine primäre Aktion → Studio-Paywall.
3. Studio-Paywall: Store-Preise lokalisiert via RevenueCat-Offering `studio`,
   Trial nur bei Store-Berechtigung, Restore, Link Abo-Verwaltung; Preis,
   Zeitraum, Verlängerung, Kündigung vor Kauf klar (Spec §13); Organisation
   statt Wirkung verkaufen — kein ROI-Satz ohne Interview-Beleg (Spec §1.3).
4. „Studio-Einstellungen / Abo verwalten" unter Begleitung-Root (Spec §4).
**Akzeptanz:** Screenshots aller Zustände (locked/aktiv/abgelaufen, DE+EN,
Light/Dark) in Evidenz; abgelaufenes Abo lässt Gratis-Funktionen + eigenen
Datenzugang unangetastet (Test); Flag-aus-Regression; Suite grün.
**Nicht-Ziele:** keine Briefing-Daten (T27.3), keine Terminserien (T27.4).

### T27.3 — Klienten-Briefing + belastbare Datenverträge *(Gate: P4-GO + T27.1; Consent-/RLS-Review im Prompt enthalten)*

**Rolle:** Fullstack (Supabase RPC + Flutter); höchste Sorgfalt — hier liegen
Gesundheits- und Kinderdaten-Nähe.
**Lies zuerst:** Spec §5.2 + §7 (Datenvertragsmatrix — Pflicht),
`get_client_sessions`-Definition, Mood-Query im Trainer-Feature,
`2026042503_harden_trainer_client_relationships.sql`.
**Scope:**
1. **Zuerst die Datenvertragsmatrix ausfüllen** (`docs/evidence/T27/planning/
   data_contract_matrix.md`): je Anzeige Quelle, Zeitraum, Freigabe, RLS,
   Entzug, Offline, Löschung. Code-Ist belegen (30-Tage-Limit, Notizfilter +
   Limit 20). Erst nach Founder-Sichtung der Matrix weiterbauen.
2. Neue/erweiterte RPCs: Trainingsrhythmus 8 Wochen (Wochen-Buckets,
   SECURITY DEFINER mit Beziehungs+Freigabe-Prüfung wie Bestand),
   Befindenstrend 8 Wochen (nur geteilte Check-ins, getrennte neutrale Reihen
   Stimmung/Energie/Stress, KEINE Notiztexte, kein synthetischer Score),
   „Seit letztem Termin" (Definition: letzter Termin mit Status confirmed in
   der Vergangenheit, Zeitzonen-fest, getestet).
3. Briefing-Screen nach Spec §5.2: Above-the-fold Identität/Stand/2 Aktionen;
   Charts sekundär, < 2 Datenpunkte → Textzusammenfassung statt Chart; jede
   Kachel zeigt Quelle + Aktualität.
4. Beziehungsende/Freigabe-Entzug: Zugriff endet sofort (RLS-Negativtest).
**Akzeptanz:** RLS-Negativtests (fremder Trainer, beendete Beziehung,
entzogene Freigabe → leer/Fehler, nie Daten); Chart-Zusatztext (a11y);
Matrix committed; Suite grün; redigierte Screenshots.
**Nicht-Ziele:** keine Notizen (T27.5), keine KI-Zusammenfassungen, keine
neuen Datenkategorien ohne Matrix-Eintrag.

### T27.4 — Termin-Automation *(Gate: P4-GO + T27.1)*

**Rolle:** Flutter + Edge-Function-Entwickler:in (Push-Infrastruktur).
**Lies zuerst:** Spec §5.3, `2026042401_trainer_appointments.sql`,
bestehende Reminder-/Push-Infrastruktur (`push_notifications_setup.md`),
Cron-Function-Muster (`x-cron-secret`, fail-closed).
**Scope:**
1. Terminserien: wöchentlich/zweiwöchentlich, Pflicht-Enddatum, Vorschau
   aller erzeugten Termine + Zeitzone vor dem Speichern; Einzeltermin bleibt
   der kostenlose Standardfluss.
2. Erinnerungen: idempotente Planung (Reminder-Job je Termin genau einmal,
   Re-Run erzeugt keine Duplikate), Klienten-Opt-out getrennt von
   Trainings-Erinnerungen, Quiet Hours + Push-Permission respektiert;
   Status-Sprache „geplant"/„nicht geplant".
3. `.ics`-Export je Termin/Serie (ohne `device_calendar` — bleibt disabled,
   Mistake #18; reine Datei-Generierung + Share-Sheet).
4. Push-Ablehnung blockiert Terminverwaltung nicht (Spec §13).
**Akzeptanz:** Idempotenz-Test (doppelter Scheduler-Lauf), Zeitzonen-Test
(DST-Wechsel), Opt-out-Test, `.ics` validiert in Apple/Google Kalender-Import
(Evidenz); Flag-aus-Regression; Suite grün.
**Nicht-Ziele:** keine Kalender-Schreibsync, keine Zustell-Garantie-Aussagen.

### T27.5 — Sitzungsprotokolle *(Gate: TS-9 + volles Legal-/Security-Go — OHNE dieses Go nicht ausführen)*

Erst konkretisieren, wenn das Go dokumentiert vorliegt (Spec §9
Aktivierungs-Gate: freigegebene Texte, Rollen/AVV, Sicherheitsreview,
RLS-Negativtests, Export/Löschung, Klienten-Transparenz). Rahmen aus Spec
§5.4: strukturierte Felder vor Freitext, Sichtbarkeits-Hinweis, Autosave-
Status, Export/Berichtigung/Löschung, keine Diagnosen/ICD/KI-Auswertung.

### T27.6 — Store-Setup, Sandbox-E2E, Pilot *(Gate: T27.1–T27.4 + TS-6/TS-10 entschieden; Store-Anlage = Founder-Sitzung)*

**Rolle:** Release-Engineer:in.
**Lies zuerst:** `PAYMENTS_MASTER_PLAN.md` §3–§5, T25.4-Evidenzmuster.
**Scope:**
1. Founder-Sitzung: Studio-Produkte (eigene Subscription-Gruppe!) in ASC
   (+ Play, falls TS-7-Android schon frei) anlegen; RevenueCat-Entitlement
   `studio` + Offering `studio` konfigurieren; Grandfathering-Mechanik (TS-6)
   gegen aktuelle Store-Doku verifizieren und dokumentieren.
2. Sandbox-E2E: Kauf, Trial, Restore, Kündigung→Ablauf, abgelaufen→
   Gratis-Zustand; auf iOS (und ggf. Android) belegt.
3. App-Review-Vorbereitung: Trainer-Demo-Konto mit fiktiven Klientendaten,
   Review Notes (Trainerrolle erklären, Studio-Fundort, Flag-Status).
4. Pilot-Runbook: 5–10 Trainer-Allowlist (`studio_source='pilot'`),
   Messplan nach Spec §12 (absolute Zahlen!), Supportweg, wöchentliche
   Check-ins, Kill-Switch-Probe dokumentiert.
**Akzeptanz:** E2E-Evidenz vollständig; Pilot-Go bleibt eigener Founder-Go;
GA-Entscheid nach Spec §12-Logik (Weiter/Überarbeiten/Stoppen).
**Nicht-Ziele:** keine öffentliche Kommunikation, kein GA-Rollout.

## 5. Reihenfolge auf einen Blick

```text
JETZT (Founder):   Go zu diesem Doc + TS-6/7/10 + PM-1..4 (Payments-Plan §8)
                   ASC-Sitzung (R4) → entsperrt T25 → entsperrt alles
PARALLEL:          P1-Interviews (5×25 Min.) + P2-Low-Fi — während Launch/T25 ohnehin läuft
NACH T25 + Launch stabil + P4-GO:
                   T27.1 → T27.2 + T27.3 + T27.4 (parallelisierbar) → T27.6 → Pilot
SEPARAT GATED:     T27.5 (Notizen) nur nach Legal-/Security-Go
```

Damit ist der Zustand erreicht, den der Founder angefordert hat: jede
verbleibende Arbeit ist entweder ein fertiger Prompt in dieser Datei, ein
Prompt in `PAYMENTS_MASTER_PLAN.md` §5, oder eine klar benannte
Founder-Handlung mit Empfehlung.
