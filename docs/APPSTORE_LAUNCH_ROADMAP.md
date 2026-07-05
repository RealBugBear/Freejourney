# Reflex Journey — App-Store-Launch-Roadmap

Status: Entwurf vom 2026-07-05 (Analyse-Session, keine Code-Änderungen)
Grundlage: `docs/LAUNCH_READINESS_BACKLOG.md` (Stand 2026-07-04) — diese Roadmap **ergänzt** den Backlog, sie ersetzt ihn nicht.
Apple-Angaben: per Websuche geprüft am **2026-07-05**; Quellen jeweils verlinkt. Rechtliche Aussagen sind Orientierung, keine Rechtsberatung.

---

## 1. Zusammenfassung

Die App ist technisch fast fertig für den Launch. Alle Sicherheits-Blocker (P0.1–P0.5) sind erledigt und belegt: Datenbank-Zugriffsschutz (RLS) verifiziert, die verwundbare Chat-Bot-Schnittstelle abgeschaltet, Gerätedaten geschützt. Der Rebrand ist committet, Deep Links und Passwort-Reset funktionieren auf dem Gerät, alle 200 Tests laufen grün. Es fehlt genau **ein** kleiner Technik-Check (Bestätigungslink auf dem iPhone antippen).

Was wirklich fehlt, ist **kein Code, sondern Papier und Entscheidungen**: die finale Datenschutzerklärung vom Anwalt (P0.6), deine Freigabe der Store-Texte, eine minimale Website (Impressum, Datenschutz, Support-Seite — Apple verlangt funktionierende URLs), der App-Store-Connect-Eintrag mit einigen Pflicht-Formularen, die der Backlog noch nicht kennt (Altersfreigabe nach dem **neuen** Apple-System, Privacy Nutrition Labels, EU-Trader-Status, Demo-Account für die Prüfer), Screenshots — und dann TestFlight und Einreichung.

**Empfehlung Monetarisierung: kostenlos launchen.** Eine Paywall existiert im Code nicht (nur ein leeres Konfigurationsfeld); sie vor dem Launch zu bauen würde den Launch um Wochen verschieben, ohne dass das Geschäftsmodell validiert ist.

**Realistische Reihenfolge:** (1) Anwalt sofort beauftragen — das ist der längste Weg und blockiert Store-Eintrag *und* Marketing. (2) Parallel: deine Entscheidungen (Liste in Abschnitt 8), Website-Basisseiten, letzter Geräte-Check. (3) App Store Connect einrichten, Screenshots, TestFlight. (4) Einreichen. Der Trainer-Akquise-Pilot läuft parallel, sobald Datenschutzerklärung und `/trainer`-Seite stehen — er blockiert den App-Launch nicht.

---

## 2. Phasenplan

Aufwand: S = Stunden, M = 1–3 Tage, L = eine Woche oder mehr. „Wer": Claude = eine Claude-Code-Session, Alexander = du (oft nur klicken/entscheiden), Anwalt, Apple = Wartezeit auf Apple, Sina = Content-Partnerin.

### Phase 1 — Entscheidungen & Anwalt (sofort starten; längster Hebel)

| # | Was | Warum | Wer | Abhängig von | Aufwand | Blocker? |
|---|-----|-------|-----|--------------|---------|----------|
| 1.1 | Anwalt beauftragen: Datenschutzerklärung (App + Website + Waitlist + Trainer-Akquise), Impressumspflichten, DPA-Check (Supabase, Agora, Google/FCM, Resend, Vercel) | P0.6 blockiert Datenschutz-URL im Store, Website und Marketing-Pilot. Ein Auftrag, der alles abdeckt, statt drei einzelne | Alexander (+ Anwalt) | — | M (Anwalt: 1–3 Wochen Laufzeit) | **JA** |
| 1.2 | Entscheidungsliste (Abschnitt 8) durchgehen und beantworten | Store-Texte, Support-Adresse, Preis, Trader-Adresse etc. hängen daran | Alexander | — | S | **JA** |
| 1.3 | Store-Listing-Review: `docs/STORE_LISTING_DRAFT.md` freigeben/ändern | Ohne freigegebene Texte kein Store-Eintrag | Alexander | 1.2 | S | **JA** |
| 1.4 | Letzter Geräte-Check: Wegwerf-Konto registrieren, Bestätigungslink **auf dem iPhone antippen** (öffnet die App?) | Einziger offener Punkt aus P1.2; jeder neue Nutzer durchläuft diesen Weg | Alexander (5 Min.) | — | S | **JA** |
| 1.5 | Gated Cleanup: verwaiste Secrets `AGARO-APP-ID`, `BOT-USER-ID` löschen (Freigabe steht seit 2026-07-04 aus) | Hygiene; nichts liest sie mehr (repo-weiter Grep belegt) | Alexander (go) + Claude | — | S | nein |

### Phase 2 — Website-Basis (parallel zu Phase 1)

Details in Abschnitt 6. Kurzfassung:

| # | Was | Wer | Abhängig von | Aufwand | Blocker? |
|---|-----|-----|--------------|---------|----------|
| 2.1 | Impressum-Seite (`/impressum`) | Claude (Inhalt: Alexander) | Pflichtangaben von Alexander | S | **JA** (DE-Rechtspflicht + Vertrauen im Review) |
| 2.2 | Support-Seite (`/support`) + Support-E-Mail-Adresse einrichten | Claude + Alexander | Entscheidung Support-Adresse (8.2) | S | **JA** (Support-URL ist ASC-Pflichtfeld) |
| 2.3 | Schlanke Landingpage (ersetzt Platzhalter; Teil B des Marketing-Specs, ohne Waitlist) | Claude | Copy-Freigabe Alexander | S–M | **JA** (Marketing-/Support-URL zeigen sonst auf einen Platzhalter mit unglücklichem Claim, s. Abschnitt 6) |
| 2.4 | Datenschutz-Seite (`/datenschutz`) mit Anwalts-Text | Claude | 1.1 (Anwalt) | S | **JA** (Datenschutz-URL ist ASC-Pflichtfeld) |
| 2.5 | `/trainer`-Seite + Bewerbungsformular (Teil C) | Claude | 1.1, Entscheidungen 8.7–8.8 | M | nein (blockiert nur den Akquise-Piloten) |
| 2.6 | Waitlist („Zum Launch benachrichtigen") | Claude | 1.1; E-Mail-Tool-Entscheidung | M | nein — Empfehlung: weglassen, wenn Launch < 6 Wochen entfernt |

### Phase 3 — App Store Connect einrichten

| # | Was | Warum | Wer | Abhängig von | Aufwand | Blocker? |
|---|-----|-------|-----|--------------|---------|----------|
| 3.1 | ASC-App-Record unter `de.reflexjourney.app` anlegen (Bundle-IDs sind seit 2026-07-03 registriert) | Ohne Record kein TestFlight, keine Einreichung | Alexander (Klick-Anleitung von Claude) | 1.3 | S | **JA** |
| 3.2 | **Neue** Altersfreigabe-Fragen beantworten (System mit 4+/9+/13+/16+/18+ inkl. Fragen zu „medical or wellness topics") | Seit 2026 Pflicht für Einreichungen; der Entwurf im Store-Listing („4+") stammt aus dem alten System — Ergebnis kann höher ausfallen, ehrlich beantworten und akzeptieren. Quelle: [Apple Age Rating Updates](https://developer.apple.com/news/upcoming-requirements/?id=07242025a), abgerufen 2026-07-05 | Alexander + Claude (Vorbereitung der Antworten) | 3.1 | S | **JA** |
| 3.3 | Privacy Nutrition Labels ausfüllen (Datentypen: Kontaktinfo/E-Mail, Health & Fitness, User Content/Journal, Nutzungsdaten; kein Tracking) | Pflichtfeld vor jeder Einreichung; muss zur finalen Datenschutzerklärung passen. Quelle: [App Privacy Details](https://developer.apple.com/app-store/app-privacy-details/), abgerufen 2026-07-05 | Claude (Entwurf) + Alexander (Eintragen) | 3.1, ideal nach 1.1 | S–M | **JA** |
| 3.4 | EU-Trader-Status (DSA) verifizieren: Adresse, Telefon, E-Mail werden **öffentlich** auf der Produktseite angezeigt | Ohne verifizierten Trader-Status keine EU-Verteilung (Pflicht seit Februar 2025). Quelle: [DSA trader status](https://developer.apple.com/news/upcoming-requirements/?id=02172025a), abgerufen 2026-07-05 | Alexander | Entscheidung 8.5 (welche Adresse/Nummer) | S (+ Apple-Verifizierung) | **JA** |
| 3.5 | Export-Compliance beantworten (Standard-HTTPS ist ausgenommen; `ITSAppUsesNonExemptEncryption=false` in Info.plist prüfen/setzen). Frankreich-Sonderregel nur relevant, wenn dort verteilt wird | Pflichtfrage bei jedem Build-Upload. Quelle: [Export compliance overview](https://developer.apple.com/help/app-store-connect/manage-app-information/overview-of-export-compliance/), abgerufen 2026-07-05 | Claude (Plist-Check) + Alexander (Bestätigen) | 3.1 | S | **JA** |
| 3.6 | Screenshots auf aktuellem Gerät erstellen — **aktuelle Pflichtgröße 6,9" (1320×2868)**; Apple skaliert kleinere Größen daraus. `docs/screenshot_guide.md` nennt noch alte Formate (6,7"/5,5") → aktualisieren | Pflicht (min. 1, max. 10 pro Gerätefamilie). Quelle: [Screenshot specifications](https://developer.apple.com/help/app-store-connect/reference/app-information/screenshot-specifications/), abgerufen 2026-07-05 | Alexander (Gerät) + Claude (Guide-Update, Motivliste aus Store-Draft) | 1.3 | S–M | **JA** |
| 3.7 | Demo-Account für die Review neu aufsetzen: `docs/demo_account_setup.md` ist veraltet (verweist auf Firebase-Auth-Konsole; die App nutzt Supabase-Auth; altes Branding). Frischen Review-Account mit sinnvollem Beispielinhalt anlegen, Zugangsdaten nur in ASC hinterlegen | Guideline 2.1: Prüfer brauchen funktionierende Zugangsdaten; leerer Account provoziert Rückfragen | Claude (Anleitung/Seed-Vorschlag) + Alexander (Anlegen) | 3.1 | S | **JA** |
| 3.8 | Erst-Freigabe von Trainern in der App prüfen/sperren (Marketing-Spec Blocker 2: keine Selbst-Freischaltung während des Piloten) | Schützt das Vetting-Versprechen; kleiner App-Eingriff | Claude | — | S | nein |

### Phase 4 — TestFlight & Qualitätssicherung

| # | Was | Warum | Wer | Abhängig von | Aufwand | Blocker? |
|---|-----|-------|-----|--------------|---------|----------|
| 4.1 | Crash-Reporting entscheiden und einbauen (Empfehlung: Sentry, DSGVO-konform konfiguriert, EU-Region; Datenschutzerklärung + Nutrition Labels entsprechend ergänzen) | Ohne Crash-Reporting siehst du Produktionsfehler erst, wenn Nutzer sich beschweren | Alexander (Entscheidung 8.6) + Claude (Einbau) | vor 4.2, damit TestFlight-Builds es enthalten | M | nein (dringend empfohlen) |
| 4.2 | Produktions-Build hochladen, TestFlight interne Tester (du + ggf. Sina) | Erster echter Store-Build; findet Signier-/Upload-Probleme früh | Claude (Anleitung per `docs/TESTFLIGHT_QUICKSTART.md`) + Alexander | 3.1–3.5 | M | **JA** |
| 4.3 | Volle manuelle Geräte-QA nach `docs/RELEASE_READINESS_CHECKLIST.md` (Hands-free, Reminders v2, Offline-Sync, Dashboard) auf dem TestFlight-Build | Offener P3-Punkt; TestFlight-Build ≠ Dev-Build | Alexander (+ Claude als Protokoll) | 4.2 | M | **JA** |
| 4.4 | Supabase Free → Pro | Entfernt 7-Tage-Pause-Risiko; Backlog-Trigger: spätestens mit erstem echten Nutzer | Alexander (Zahlung) | vor Launch | S | **JA** (vor „live", nicht vor Einreichung) |

### Phase 5 — Einreichung & Review

| # | Was | Warum | Wer | Abhängig von | Aufwand | Blocker? |
|---|-----|-------|-----|--------------|---------|----------|
| 5.1 | Review-Notizen schreiben: Gesundheits-/Kinder-Kontext erklären (App richtet sich an Erwachsene; Kinderprofile werden von Erwachsenen geführt; kein Medizinprodukt, keine Diagnose; Demo-Account-Hinweise) | Senkt Rückfrage-/Ablehnungsrisiko bei 5.1.3-naher Thematik deutlich | Claude (Entwurf) + Alexander (Freigabe) | 3.7 | S | **JA** |
| 5.2 | Alle Metadaten final in ASC eintragen (Texte, URLs, Kategorie Gesundheit & Fitness, Preis „kostenlos", Copyright) | Vollständigkeit vor Submit | Alexander (Klick-Anleitung von Claude) | 1.3, 2.x, 3.x | S | **JA** |
| 5.3 | Einreichen, Review abwarten, auf Rückfragen reagieren | Typisch 1–3 Tage, mit Puffer rechnen | Apple + Alexander | alles davor | Apple: Tage | **JA** |
| 5.4 | Staged Release aktivieren (phased release) + Launch-Tag: Monitoring (Crash-Reports, Supabase-Logs) | Fehler treffen erst wenige Nutzer | Alexander + Claude | 5.3 | S | nein |

**Typische Ablehnungsgründe für diese App — und unsere Antwort:**
- *5.1.3 Gesundheitsdaten/medizinische Genauigkeit* → Wir behaupten keine Messwerte, Diagnosen oder Wirkungen; Texte sind bereits heilversprechen-frei formuliert (Store-Draft, App-Copy). Review-Notiz erklärt das aktiv. Quelle: [App Review Guidelines](https://developer.apple.com/app-store/review/guidelines/), abgerufen 2026-07-05.
- *2.1 App-Vollständigkeit / Login nicht testbar* → frischer Demo-Account mit Inhalt (3.7), Hinweise in den Review-Notizen.
- *5.1.1 Datenschutz: Policy-URL fehlt/deckt Verarbeitung nicht* → Anwalts-Policy (1.1) vor Einreichung live; Nutrition Labels konsistent (3.3).
- *Kids-Verwechslung (1.3/5.1.4)* → Wir sind bewusst **nicht** in der Kids-Kategorie; Zielgruppe Erwachsene; Review-Notiz stellt das klar (deckt sich mit der Empfehlung im Store-Draft).
- *4.2 Minimum Functionality* → geringes Risiko (voll funktionsfähige App mit Offline-Sync, Hands-free, Fragebogen).

### Phase M (parallel) — Marketing & Trainer-Akquise

Startet unabhängig vom Store-Track, sobald Datenschutzerklärung (1.1) und `/trainer` (2.5) live sind. Details Abschnitt 7. **Blockiert den App-Launch nicht.**

### Phase C (parallel) — Content von Sina (P2)

Fragebogen Erwachsene, finale Videos, FAQ-Inhalte sind angefragt (2026-07-03). Wenn sie eintreffen, springt P2 laut Backlog in der Warteschlange nach vorn. **Kein harter Launch-Blocker** — die Medien-Pipeline hat Asset-Fallback; aber Entscheidung 8.9 (mit aktuellem Content launchen oder auf finale Videos warten) bestimmt, ob C vor 5.3 liegt.

---

## 3. Security & Compliance

**P0-Stand aus dem Backlog (belegt, nichts zu tun):** RLS auf allen 37 Tabellen verifiziert und als Migration eingefroren (P0.1 ✅ 2026-07-02/03); chat-triage-bot neutralisiert und deployed, Endpoint antwortet 410 (P0.2 ✅ 2026-07-03); Cron-Secrets fail-closed (P0.3 ✅); Supabase-Region EU/Irland (P0.4 ✅); lokale Daten backup-exkludiert, Consent-Text korrigiert, Account-Löschung wischt lokale DB (P0.5 ✅).

**Offen aus P0:** P0.6 (Anwalt: finale Datenschutzerklärung + DPAs) — einziger offener P0-Punkt, jetzt kritischer Pfad. Dazu zwei bewusst geparkte Post-Launch-Punkte (Keychain-Session, SQLCipher).

**Neu aus der Lückenanalyse (stehen noch nicht im Backlog):**

| Anforderung | Quelle (abgerufen 2026-07-05) | Einordnung |
|---|---|---|
| Neues Altersfreigabe-Fragensystem (4+…18+, Fragen zu Medizin/Wellness-Themen); seit 31.01.2026 Voraussetzung für Einreichungen | [Apple: Age Rating Updates](https://developer.apple.com/news/upcoming-requirements/?id=07242025a) | Pflichtformular; Ergebnis kann über 4+ liegen — kein Problem, nur ehrlich ausfüllen |
| Privacy Nutrition Labels (App Privacy) | [Apple: App Privacy Details](https://developer.apple.com/app-store/app-privacy-details/) | Pflicht vor Einreichung; muss zur Anwalts-Policy passen |
| EU-Trader-Status (DSA Art. 30/31): verifizierte Adresse/Telefon/E-Mail öffentlich auf der Produktseite | [Apple: DSA trader status](https://developer.apple.com/news/upcoming-requirements/?id=02172025a) | Pflicht für EU-Verteilung; Entscheidung nötig, welche Adresse/Nummer öffentlich stehen soll |
| Demo-Account für Review (Guideline 2.1) | [App Review Guidelines](https://developer.apple.com/app-store/review/guidelines/) | Vorhandenes Doc veraltet (Firebase statt Supabase) → neu machen |
| Export-Compliance/Verschlüsselungs-Deklaration; Standard-HTTPS ausgenommen; Frankreich-Sonderformular | [Apple: Export compliance](https://developer.apple.com/help/app-store-connect/manage-app-information/overview-of-export-compliance/) | Formsache, aber Pflichtfrage bei jedem Upload |
| Screenshot-Pflichtgröße heute 6,9" (1320×2868), kleinere werden skaliert | [Apple: Screenshot specifications](https://developer.apple.com/help/app-store-connect/reference/app-information/screenshot-specifications/) | `docs/screenshot_guide.md` nennt veraltete Größen → aktualisieren |
| Gesundheits-Apps: erhöhte Prüfschärfe, „Arzt fragen"-Hinweis empfohlen (5.1.3); Kinder-Regeln (1.3/5.1.4) greifen v. a. für die Kids-Kategorie, die wir bewusst meiden | [App Review Guidelines](https://developer.apple.com/app-store/review/guidelines/) | Durch heilversprechen-freie Texte + Review-Notizen adressiert; Disclaimer im Store-Text vorhanden |

Bereits erfüllt, nur festhalten: In-App-Account-Löschung (Guideline 5.1.1(v)) ist implementiert und verifiziert (P0.5).

---

## 4. Paywall & Monetarisierung

**Was das Design (2026-05-28) vorsieht:** zwei Geldflüsse — Platform-Abo (Paket 1 gratis, Paket 2+ Premium; 12,99 €/Monat, 89,99 €/Jahr, 149 € Lifetime) und Trainer-Session-Zahlungen über Stripe Connect (15 % Provision). Phasenmodell: Phase 1 = Stripe-Checkout im Browser (nur TestFlight!), Phase 2 = App Store mit RevenueCat + Apple IAP.

**Was davon existiert:** praktisch nichts im App-Code. `purchases_flutter` ist in `pubspec.yaml` auskommentiert; es gibt kein Paywall-Screen, kein `isPremium`-Feld, keine Premium-Gating-Logik, keine Stripe-Edge-Functions (Stand: Code-Prüfung 2026-07-05). Die Backlog-Formulierung „RevenueCat is coded but disabled" ist zu optimistisch — vorhanden ist nur ein leeres Konfigurationsfeld.

**Apple-Regeln (geprüft 2026-07-05):** Digitale Abos in der App **müssen** über Apple In-App-Purchase laufen (Guideline 3.1.1). Externe Kauf-Links sind inzwischen in den USA und über die EU-Alternative-Terms möglich, aber mit eigenem Vertragswerk, eigener Compliance und weiterhin Provision — für einen Solo-Gründer beim Erstlaunch unverhältnismäßig. Stripe-Checkout für das Abo (Phase-1-Design) ist im App Store **nicht zulässig**, nur in TestFlight. Trainer-Session-Zahlungen (Dienstleistung durch Dritte) wären dagegen auch später IAP-frei möglich. Quellen: [App Review Guidelines](https://developer.apple.com/app-store/review/guidelines/), [Apple: EU-Angebotskommunikation](https://developer.apple.com/support/communication-and-promotion-of-offers-on-the-app-store-in-the-eu/), abgerufen 2026-07-05.

### Optionen im Vergleich

**Option A — kostenlos launchen, Paywall später (EMPFEHLUNG):**
- Aufwand jetzt: null. Launch-Termin hängt nur an Papierkram.
- Review-Risiko: minimal (keine IAP-Prüfung, kein Trader-Umsatzthema, keine AGB-/Widerrufs-Pflichten für Käufe).
- Rechtlich jetzt nicht nötig: AGB für Verkäufe, Widerrufsbelehrung, Stripe-Datenschutzpassagen.
- Passt zum eigenen Phasenmodell des Monetarisierungs-Designs („Geschäftsmodell validieren, bevor App-Store-Aufwand investiert wird") und zum Gründungs-Trainer-Angebot („ab Tag 1 sichtbar, gratis").
- Kosten: Nutzer der Gratis-Phase erwarten evtl. Bestandsschutz. Lösung: bewusst entscheiden (Entscheidung 8.4b) — z. B. „Early-Bird: alle Launch-Nutzer behalten Paket 1 + X gratis" klar kommunizieren.

**Option B — Paywall vor Launch aktivieren:**
- Aufwand: L (mehrere Wochen): RevenueCat-Integration, IAP-Produkte + Preise in ASC, Paywall-UI, Premium-Gating im Paket-Flow, Restore-Purchases, Sandbox-Tests, dazu AGB/Widerruf (Anwalt, laut Design ~200–500 €) und erweiterte Datenschutz-/Label-Angaben.
- Review-Risiko: höher — IAP-Flows werden aktiv getestet; erste Einreichung mit Abo + Gesundheitsnähe + Kinderdaten stapelt Prüfthemen.
- Einziger Vorteil: Umsatz ab Tag 1 — bei null validierten Nutzern spekulativ.

**Umsetzungsplan für Option A (Launch):** Preis in ASC „kostenlos", keine IAP-Produkte anlegen, Trader-Status trotzdem nötig (kein Ausweg). Im Store-Text nichts versprechen, was eine spätere Paywall ausschließt.
**Nach dem Launch (eigenes Vorhaben, Reihenfolge-Empfehlung):** 1) Nutzungsdaten sammeln (wie viele erreichen Paket 2?), 2) RevenueCat + IAP nach Phase-2-Design bauen, 3) AGB/Widerruf vom Anwalt, 4) IAP-Produkte in ASC anlegen (Abo-Gruppe, 3 Produkte per Trio B), 5) Update einreichen. Trainer-Payments (Stripe Connect) separat und noch später.

---

## 5. App-Store-Einreichung — der komplette Weg

1. **ASC-App-Record anlegen** (Phase 3.1): Plattform iOS, Bundle-ID `de.reflexjourney.app` (registriert seit 2026-07-03, inkl. Associated Domains + Push), SKU, Primärsprache Deutsch.
2. **Pflicht-Formulare** (Phase 3.2–3.5): neues Altersfreigabe-Fragenset, Privacy Nutrition Labels, EU-Trader-Status-Verifizierung, Export-Compliance.
3. **Metadaten** (Phase 5.2): Texte aus dem freigegebenen `STORE_LISTING_DRAFT.md`, Kategorie Gesundheit & Fitness (sekundär Lifestyle), Support-/Marketing-/Datenschutz-URL (Phase 2), Preis kostenlos, Screenshots 6,9".
4. **TestFlight** (Phase 4): Build-Upload nach `docs/TESTFLIGHT_QUICKSTART.md` (vorhandene Anleitung nutzen; Pfad-Verweise auf `/dev/corejourney` darin sind veraltet, Inhalt sonst brauchbar). Interne Tester zuerst; externe Tester brauchen eine eigene Beta-Review.
5. **Review-Vorbereitung** (Phase 3.7 + 5.1): Demo-Account (Supabase-Konto mit Beispiel-Fortschritt; Zugangsdaten NUR in ASC eintragen, nicht in Dokumente im Repo), Review-Notizen: Zielgruppe Erwachsene, Kinderprofile nur unter Eltern-Account, kein Medizinprodukt/keine Diagnose, Hinweis auf Offline-Modus (Prüfer-Netzwerk), Hinweis wie Trainer-Verbindung testbar ist (oder dass sie fürs Review irrelevant ist).
6. **Submission** (Phase 5.3): einreichen, „Phased Release" wählen, auf Rückfragen im Resolution Center schnell antworten (Antwortzeit drückt die Gesamtdauer am meisten).
7. **Nach Freigabe:** Launch-Tag mit Monitoring (4.1-Crash-Reporting, Supabase-Logs), Supabase Pro aktiv (4.4).

---

## 6. Website (`reflexjourney-app-site/`, äußeres Repo, Vercel)

**Ist-Zustand (geprüft 2026-07-05):** ein Platzhalter-`index.html` („Nervensystem-Training für den Alltag" — sollte ersetzt werden, die Formulierung geht Richtung Wirkversprechen), funktionierende Auth-Seiten (`/auth/reset-password`, `/auth/confirm`), `.well-known`-Dateien für Deep Links, `vercel.json`. Keine Impressums-, Datenschutz-, Support- oder Trainer-Seite.

**Bauplan in Reihenfolge:**

| # | Seite | Inhalt | Launch-Blocker? |
|---|-------|--------|-----------------|
| W1 | `/impressum` | Pflichtangaben (Name, Anschrift, Kontakt; vom Anwalt bestätigen lassen) | **JA** — deutsche Rechtspflicht, sobald die Seite geschäftlich ist; auch Vertrauenssignal im Review |
| W2 | `/support` | Kurze Hilfe-Seite: Kontakt (Support-Mail aus 8.2), 2–3 häufige Fragen (Konto löschen, Passwort zurücksetzen, Datenexport) | **JA** — Support-URL ist ASC-Pflichtfeld und muss funktionieren |
| W3 | `/` Landingpage (Teil B, schlank) | Hero (organisatorischer Satz), „Für wen", „Was man mit der App tut" (dokumentieren/festhalten/Trainer finden — keine Wirkaussagen), Vertrauen & Datenschutz, Footer mit Impressum/Datenschutz/Support. **Ohne Waitlist** starten (Empfehlung; sonst Double-Opt-in-Infrastruktur nötig) | **JA** in Minimalform (Marketing-URL zeigt sonst auf Platzhalter mit unglücklichem Claim) |
| W4 | `/datenschutz` | Anwalts-Text (App + Website; falls Waitlist/Trainer-Akquise kommen: mit abdecken) | **JA** — Datenschutz-URL ist ASC-Pflichtfeld; hängt an P0.6 |
| W5 | `/trainer` (Teil C) | Gründungs-Trainer-Angebot, Voraussetzungen (Zertifikat + erweitertes Führungszeugnis zur Sichtprüfung), Ablauf, Bewerbungsformular nach Appendix B (kein Datei-Upload!), Datenschutz-Link | nein — blockiert nur den Akquise-Piloten |
| W6 | Waitlist auf W3 | Nur mit Double-Opt-in + Datenschutz-Abdeckung + E-Mail-Tool | nein — Empfehlung: erst bauen, falls sich der Launch um > 6 Wochen verzögert |

**Technische Notiz zum Formular (W5):** Die Seite ist statisch. Für ~20 Pilot-Bewerbungen reicht ein Formular-Dienst mit DSGVO-AVV oder schlicht ein `mailto:`-Link mit vorstrukturiertem Betreff. Empfehlung: einfachst möglich starten (Formular-Dienst mit EU/AVV oder mailto), kein eigenes Backend. Entscheidung 8.8.

---

## 7. Marketing-Review (Spec vom 2026-07-04)

**Gesamturteil: solide und ungewöhnlich compliance-bewusst — übernehmen, mit vier Anmerkungen.** Die harten Regeln (UWG § 7, DSGVO Art. 10/14/21, MDR-Sprachregeln, „ansehen statt speichern" beim Führungszeugnis, max. 20 Kontakte, Claude sendet nie selbst) sind genau richtig für gesundheitsnah + Kinderdaten.

**Anmerkungen:**
1. **Entkoppeln:** Der Trainer-Pilot darf den App-Launch nicht aufhalten — und umgekehrt. Die App funktioniert für Endnutzer auch ohne Trainer (Selbstanwender-Flow); „App ist ab Tag 1 nicht leer" ist ein Nice-to-have, kein Gate. Empfehlung: Store-Track (Phasen 1–5) hat Vorrang; Pilot startet, sobald seine Blocker (Datenschutzerklärung, `/trainer`, Sichtprüfungs-Ablauf) fallen — ob vor oder nach dem Launch, ergibt sich.
2. **Zielgruppen-Logik ist plausibel**, aber die Erwartung dämpfen: Kontaktformular-Outreach an 20 Praxen liefert erfahrungsgemäß einstellige Antworten. Der Wert des Piloten ist Lernen (Einwände, Sprache, Kanal) — genau so steht es im Spec. Gut: die Entscheidungsmatrix verhindert vorschnelles Skalieren.
3. **Rechtliche Restrisiken** liegen fast alle beim Anwalts-Paket (Blocker 1) — deshalb gehört die Trainer-Akquise und die Waitlist explizit in den Anwaltsauftrag (Phase 1.1), sonst zahlt man zweimal.
4. **„Dauerhaft kostenlos für Gründungs-Trainer"** ist ein unbefristetes Versprechen — bewusst eingehen (Entscheidung 8.7). Formulierung auf der Seite so wählen, dass sie sich auf den Eintrag/die Sichtbarkeit bezieht, nicht auf künftige, noch nicht existierende Funktionen.

**Vor dem App-Launch:** W1–W4 (sowieso Launch-Blocker), Anwaltsauftrag inkl. Akquise-Abdeckung, App-Änderung „Selbst-Freischaltung sperren" (Phase 3.8), Sichtprüfungs-Ablauf definieren (Entscheidung 8.8 — siehe 7a).
**Danach (oder parallel, wenn Zeit übrig):** `/trainer` + Pilotstart, Auswertung nach 20 Kontakten, FAQ-Bereich (P2.C, wenn Sinas Content kommt), Waitlist nur bei Launch-Verzögerung.

### 7a. Empfohlener Sichtprüfungs-Ablauf (Trainer-Vetting, seriös und DSGVO-konform)

Beschlossen 2026-07-05: einfaches Bewerbungsformular (nur Daten, kein Datei-Upload) + Einzelprüfung. Empfohlener Ablauf pro Bewerbung — der Kern ist immer: **ansehen, nie speichern** (Führungszeugnis = Vorstrafendaten, Art. 10 DSGVO):

1. **Eingang:** Bewerbung kommt über `/trainer` mit Selbstauskunft „erweitertes Führungszeugnis vorhanden, ausgestellt am …". Eingangsbestätigung per Mail mit den nächsten Schritten (Vorlage einmal schreiben, dann wiederverwenden).
2. **Plausibilitätsprüfung am Schreibtisch (10–15 Min.):** Website/Profil ansehen; Zertifizierung gegen öffentliche Trainer-Verzeichnisse des genannten Instituts (RIT, INPP, MNRI, PaePKi, KinFlex …) gegenprüfen, wenn ein Verzeichnis existiert. Wirkt etwas unklar → im Sichttermin nachfragen, nicht vorab ablehnen.
3. **Sichttermin per Video (Standard) oder vor Ort:** Drei Dinge im Original zeigen lassen, in dieser Reihenfolge:
   - **Lichtbildausweis** — Name stimmt mit Bewerbung überein.
   - **Zertifikat** der Ausbildung — Institut, Name, Datum.
   - **Erweitertes Führungszeugnis** — Name korrekt, Ausstellungsdatum **nicht älter als 3 Monate**, keine relevanten Einträge („Keine Eintragung" bzw. Sichtung der Einträge auf Relevanz).
   Dabei gilt: **kein Screenshot, keine Aufzeichnung des Termins, keine Kopie, kein Foto** — auch nicht „zur Sicherheit". Wenn das Dokument älter als 3 Monate ist: Termin freundlich vertagen, neues Führungszeugnis beantragen lassen (dauert ca. 2–4 Wochen, ~13 €).
4. **Prüfvermerk anlegen (das Einzige, was gespeichert wird):** Name, „Identität geprüft: ja", „Zertifikat [Institut] gesichtet: ja", „erweitertes Führungszeugnis vorgelegt am [Datum], ausgestellt am [Datum], ohne relevante Einträge: ja", „nächste Prüfung fällig am [Datum + 24 Monate]", Prüfer: Alexander. Keine Dokumenten-Details, keine Kopien, nichts aus dem Inhalt des Zeugnisses außer dem Ja/Nein-Ergebnis.
5. **Freischaltung:** als Gründungs-Trainer freischalten + Bestätigungsmail (Gründungs-Status, wie der Eintrag bearbeitet/gelöscht werden kann).
6. **Wiedervorlage:** alle **24 Monate** erneut ein aktuelles erweitertes Führungszeugnis im Sichttermin zeigen lassen (Kalendereintrag aus dem Prüfvermerk). Ein Führungszeugnis ist eine Momentaufnahme — die Wiedervorlage ist das, was den Prozess dauerhaft seriös macht.
7. **Ablehnung/Zweifel:** Im Zweifel nicht freischalten. Bei Ablehnung nur das Minimum speichern (Name, Datum, „nicht freigeschaltet"), keine Begründungsdetails zu Zeugnisinhalten — auch das sind Vorstrafendaten.

Orientierung, keine Rechtsberatung; die 3-Monats-Grenze und der 24-Monats-Rhythmus sind gängige Praxis (z. B. bei Trägern der Kinder- und Jugendhilfe üblich), im Anwaltsauftrag (Phase 1.1) kurz bestätigen lassen.

---

## 8. Entscheidungsliste für Alexander

Punkte 1–4 übernehmen die 6 offenen Entscheidungen aus `docs/STORE_LISTING_DRAFT.md` (dort im Detail nachlesbar), 5–9 sind neu aus dieser Analyse.

> **Update 2026-07-05 — Founder-Antworten:**
> - **8.1:** EN-Listing soll **zum Launch fertig** sein (neue Aufgabe: Übersetzung nach DE-Freigabe). Noch offen: Untertitel-Wahl + Satz-für-Satz-Copy-Freigabe.
> - **8.2:** Eigene Support-Adresse wird angelegt (Aufgabe: Empfangs-Postfach einrichten, Resend sendet bisher nur).
> - **8.3:** `reflexjourney.app/datenschutz` bestätigt.
> - **8.4:** Launch kostenlos, Paket 1 bleibt kostenlos. Für später gewünscht: **Freischalt-Codes** für bestimmte Nutzer („Gründungsnutzer"), die allen Content ganz oder teilweise kostenlos geben — wird beim Paywall-Design eingeplant (im Backlog unter „Open questions / parked" festgehalten).
> - **8.5:** In Klärung; Alexander besorgt voraussichtlich eine eigene Telefonnummer. Gehört mit in den Anwaltsauftrag (Impressum + Trader-Status, eine Lösung für beides).
> - **8.6:** Sentry — ja.
> - **8.7:** Gründungs-Trainer-Angebot — freigegeben.
> - **8.8:** Einfaches Formular (nur Daten, kein Upload) + Einzelprüfung mit Führungszeugnis. Empfohlener Ablauf siehe Abschnitt 7a.
> - **8.9:** Mit aktuellem Content einreichen — bestätigt.

| # | Frage | Optionen | Empfehlung | Bis wann |
|---|-------|----------|------------|----------|
| 8.1 | Store-Draft-Fragen 1, 5, 6: Untertitel; EN-Listing zum Launch?; Copy-Freigabe jedes Satzes | siehe `STORE_LISTING_DRAFT.md` | „Dein Reflexintegrations-Weg"; Launch nur DE, EN nachziehen; Copy einmal komplett lesen | vor Phase 3.1 |
| 8.2 | Offizielle Support-E-Mail (öffentlich im Store) | z. B. `support@reflexjourney.de` (Empfehlung aus Store-Draft) vs. persönliche Adresse | eigene Support-Adresse einrichten (Resend-Domain existiert) | vor Phase 2.2 |
| 8.3 | Datenschutz-URL | `reflexjourney.app/datenschutz` o. ä. | `/datenschutz` auf der App-Site | mit Anwaltsauftrag 1.1 |
| 8.4 | a) Launch kostenlos? b) Wenn ja: Was versprechen wir Gratis-Phase-Nutzern für später? | A: kostenlos launchen / B: Paywall zuerst bauen | **A** (Begründung Abschnitt 4); b) Bestandsschutz-Formel bewusst festlegen, nichts Unbeabsichtigtes versprechen | a) sofort; b) vor Launch-Kommunikation |
| 8.5 | Trader-Status (DSA): Welche Adresse + Telefonnummer dürfen öffentlich auf der App-Store-Produktseite stehen? | Privatadresse / Geschäftsadresse / ggf. separate Nummer | Falls keine Geschäftsadresse existiert: mit Anwalt klären (Impressum hat dasselbe Problem — eine Lösung für beides) | vor Phase 3.4 |
| 8.6 | Crash-Reporting | Sentry (EU) / Crashlytics reaktivieren / ohne launchen | Sentry mit EU-Datenhaltung; in Anwalts-Policy + Labels aufnehmen | vor Phase 4.2 |
| 8.7 | Gründungs-Trainer-Versprechen final freigeben („dauerhaft gratis", Kennzeichnung, nur bis Launch) | freigeben / abschwächen | freigeben, Formulierung auf „Eintrag/Sichtbarkeit" begrenzen | vor W5 |
| 8.8 | Trainer-Bewerbungsformular-Technik + Sichtprüfungs-Ablauf (Video/vor Ort, 3-Monats-Grenze, Vermerk-Vorlage) | Formular-Dienst mit AVV / mailto; Ablauf-Details | einfachste Variante; Ablauf wie im Spec (3 Monate, Vermerk ohne Dokument) | vor W5 |
| 8.9 | Mit aktuellem Übungs-Content launchen oder auf Sinas finale Videos warten? | jetzt einreichen / auf P2.B warten | Einreichung nicht auf Content warten lassen; wenn Videos rechtzeitig kommen, per Update oder vor 5.3 einspielen | vor Phase 5.3 |

---

## 9. Vorschlag Backlog-Ergänzungen

Zum Einfügen in `docs/LAUNCH_READINESS_BACKLOG.md` **nach deiner Freigabe** (diese Session ändert den Backlog nicht). Quellen-Kurzverweise stehen in Abschnitt 3.

**Unter P0.6 (Anwalt) ergänzen:**
```
- [ ] Anwaltsauftrag deckt AUCH ab: Website (Impressum, Datenschutzseite), Trainer-Akquise (UWG/DSGVO Art. 14) und — falls gebaut — Waitlist. Ein Auftrag statt drei.
```

**Neuer Abschnitt unter P3 (oder als P3.ASC-Block):**
```
- [ ] ASC: App-Record unter `de.reflexjourney.app` anlegen (Bundle-ID registriert 2026-07-03; Record fehlt noch).
- [ ] ASC: NEUES Altersfreigabe-Fragenset beantworten (4+/9+/13+/16+/18+, inkl. Medizin/Wellness-Fragen; Pflicht seit 31.01.2026 — Ergebnis kann über dem alten 4+-Entwurf liegen).
- [ ] ASC: Privacy Nutrition Labels ausfüllen (E-Mail, Health & Fitness, User Content/Journal, Nutzungsdaten; kein Tracking) — konsistent mit finaler Datenschutzerklärung (P0.6).
- [ ] ASC: EU-Trader-Status (DSA) verifizieren — Entscheidung, welche Adresse/Telefonnummer öffentlich auf der Produktseite steht.
- [ ] ASC: Export-Compliance klären; `ITSAppUsesNonExemptEncryption` in Info.plist prüfen/setzen (Standard-HTTPS ist ausgenommen).
- [ ] Review-Demo-Account NEU aufsetzen — `docs/demo_account_setup.md` ist veraltet (Firebase-Anleitung; App nutzt Supabase-Auth). Frisches Konto mit Beispiel-Fortschritt; Zugangsdaten nur in ASC, nie im Repo.
- [ ] Review-Notizen für den Gesundheits-/Kinder-Kontext schreiben (Zielgruppe Erwachsene, kein Medizinprodukt, Kinderprofile nur unter Eltern-Account, Demo-Hinweise).
- [ ] `docs/screenshot_guide.md` auf aktuelle Pflichtgrößen aktualisieren (6,9" / 1320×2868 als Master; alte 6,7"/5,5"-Angaben streichen).
```

**Neuer Abschnitt „Website (Launch-Pflichtseiten)" (äußeres Repo `reflexjourney-app-site/`):**
```
- [ ] Website: `/impressum` mit Pflichtangaben (Anwalt bestätigt) — Launch-Blocker.
- [ ] Website: `/support` + offizielle Support-Mail (ASC-Pflichtfeld Support-URL) — Launch-Blocker.
- [ ] Website: schlanke Landingpage ersetzt Platzhalter (heilversprechen-freie Copy; aktueller Platzhalter-Claim „Nervensystem-Training für den Alltag" wird ersetzt) — Launch-Blocker in Minimalform.
- [ ] Website: `/datenschutz` mit Anwalts-Text (ASC-Pflichtfeld Datenschutz-URL) — Launch-Blocker, hängt an P0.6.
- [ ] Website: `/trainer` + Bewerbungsformular (Marketing-Spec Teil C) — kein Launch-Blocker; Blocker für Akquise-Pilot.
```

**Unter P3 ergänzen (App-Änderung aus dem Marketing-Spec):**
```
- [ ] Trainer-Selbst-Freischaltung in der App für die Pilotphase sperren (Marketing-Spec Blocker 2) — kleine App-Änderung, vor dem ersten Trainer-Onboarding.
```

**Unter „Open questions / parked" ergänzen:**
```
- [ ] Post-Launch-Monetarisierung: RevenueCat + Apple IAP nach `docs/superpowers/specs/2026-05-28-monetization-design.md` Phase 2; vorher AGB/Widerruf (Anwalt) + IAP-Produkte in ASC. Stripe-Checkout fürs Abo ist im App Store nicht zulässig (3.1.1). Bestandsschutz-Kommunikation aus Entscheidung 8.4b umsetzen.
```
