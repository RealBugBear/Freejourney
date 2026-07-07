# Monetarisierung — realistische Evaluation (2026-07-07)

Auftrag: Founder-Anfrage, die Geldverdien-Optionen ganzheitlich zu bewerten
(logisch, psychologisch, käuferpsychologisch, rechtlich). Baut auf dem
freigegebenen Design `docs/superpowers/specs/2026-05-28-monetization-design.md`
auf und ergänzt es. Input für die R8-Design-Session (Backlog „parked“).

Prämissen: Launch ist kostenlos (Entscheidung 8.4); Paket 1 bleibt dauerhaft
frei; Freischalt-Codes für Gründungsnutzer sind gesetzt (Founder-Anforderung
2026-07-05); Gründungs-Trainern ist der **Eintrag/die Sichtbarkeit** dauerhaft
kostenlos versprochen (8.7) — nicht mehr.

---

## 1. Nutzer-Seite: die drei Modelle im Vergleich

### A) Abo (Monat/Jahr) — Rückgrat, aber richtig erzählen

- **Logik:** Höchster Lebenszeitwert pro Nutzer, planbarer Umsatz, passt zu
  laufendem Wert (Tracking, Erinnerungen, Trainer-Anbindung, künftige
  Inhalte). Apple wickelt Zahlung/Kündigung/Erstattung ab.
- **Psychologie:** Deutsche Nutzer sind abo-müde. Kritisch: Die App ist ein
  **Programm mit absehbarem Ende** (Pakete à 4 Wochen). „Miete für endlichen
  Content“ fühlt sich unfair an → Kündigungswelle nach Programmende ist
  strukturell eingebaut. Gegenmittel: das Abo als **Begleitung** verkaufen
  (Fortschritt, Familienprofile, Trainer-Chat, neue Inhalte), nicht als
  Content-Zugang; Jahres-Abo als hervorgehobener Standard („2 Monate
  geschenkt“ ggü. Monat).
- **Recht:** IAP-Pflicht (Apple 3.1.1); Apple = Kaufabwickler → Widerruf
  läuft über Apple, AGB müssen das abbilden (Anwalts-Baustein 8, bereits als
  Option angefragt). Small Business Program: 15 % statt 30 % Provision
  (< 1 Mio $ Jahresumsatz) — beim ASC-Setup aktiv beantragen.

### B) Lifetime/Einmalzahlung gesamt — behalten, als Anker

- **Logik:** Bedient die (in DE ausgeprägte) Einmalkauf-Präferenz; entlastet
  das „Abo für endlichen Content“-Problem; kein Churn-Management.
- **Psychologie:** Wirkt v. a. als **Preisanker**: 149 € Lifetime macht
  89,99 €/Jahr attraktiv. Käufer sind oft genau die, die ein Abo prinzipiell
  ablehnen — ohne Lifetime wären sie ganz verloren, nicht Abo-Kunden.
- **Risiko:** Kannibalisiert Jahres-Abos, wenn zu billig; bei kleinem
  Content-Katalog ist „lebenslang alles“ schnell „ausgelutscht“. Preisabstand
  Lifetime ≥ 1,6× Jahres-Abo halten (149/89,99 ≈ 1,66 ✓).
- **Recht:** wie A (IAP, Widerruf via Apple).

### C) Einzelkauf pro Reflexpaket — Bauchgefühl verständlich, zum Start NICHT

- **Logik dafür:** passt zur mentalen Buchhaltung („ich brauche nur Moro“),
  niedrige Einstiegshürde.
- **Logik dagegen (überwiegt):** (1) kannibalisiert Abo+Lifetime von unten;
  (2) macht **jede Paketgrenze zur neuen Kaufentscheidung** = eingebauter
  Absprungpunkt statt einmaliger Conversion; (3) widerspricht der
  Produktlogik — die Journey ist sequenziell aufgebaut, nicht à la carte;
  (4) drei Modelle gleichzeitig = Choice Overload auf der Paywall (Konversion
  sinkt nachweislich bei >3 Optionen); (5) je Paket ein IAP-Produkt +
  Entitlement-Matrix = dauerhafter Pflegeaufwand.
- **Empfehlung:** Zum Paywall-Start weglassen. Später datengetrieben als
  **Exit-Offer** testen (wer die Paywall zweimal ohne Kauf schließt, bekommt
  einmalig „Nur dieses Paket für X €“) — so schöpft man Einzelkäufer ab,
  ohne das Hauptmodell zu beschädigen.

### Käuferpsychologie der Zielgruppe (gilt für alles)

Eltern mit konkretem Leidensdruck + erwachsene Selbstanwender: hohe
Zahlungsbereitschaft, aber **Vertrauensmarkt**. Konsequenzen:
- **Paywall-Timing steht schon richtig im Design:** nach Abschluss des
  Gratis-Pakets 1 (Erfolgserlebnis + investierter Fortschritt = beste
  Conversion-Basis, „endowed progress“). Paket 1 gratis IST der Trial —
  kein zusätzlicher Free-Trial nötig.
- **Keine Dark Patterns:** keine Countdown-Timer, keine Fake-Rabatte, kein
  Angst-Framing („Ihr Kind verliert Zeit!“). Im Gesundheits-/Kinderkontext
  zerstört das Vertrauen, ist UWG-riskant und fällt im App-Review negativ auf.
  Paywall-Copy unterliegt derselben Regel wie alle Texte: **keine
  Heilversprechen** — verkauft wird das Programm/die Begleitung, nie eine
  Wirkung.
- **Familien:** Ein Abo deckt alle Profile des Kontos ab (Kinderprofile).
  Das ist ein Verkaufsargument („für die ganze Familie“), keine
  Upsell-Schranke — pro-Profil-Bezahlung würde die wertvollste Zielgruppe
  (Mehrkind-Familien) bestrafen.
- **Bestandsschutz (R8):** Vor Paywall-Launch klar kommunizieren: „Wer vor
  der Paywall dabei war, behält Paket 1 dauerhaft kostenlos; Gründungsnutzer-
  Codes schalten darüber hinaus frei.“ Nichts darüber hinaus versprechen.

## 2. Trainer-Seite: Mittelsmann-Modell realistisch betrachtet

> **⚠️ ÜBERHOLT durch Founder-Entscheidung D5 (2026-07-07):**
> **Die Session-Provision ist gestrichen.** Trainer-Sitzungen werden
> ausschließlich **direkt zwischen Trainer und Klient** abgerechnet — die
> Plattform vermittelt nur den Kontakt und stellt Werkzeuge, verarbeitet
> keine Zahlungen, erhält keine Provision und kennt keine Beträge.
> Konsequenzen:
> - Das **Disintermediations-Problem (unten analysiert) entfällt als
>   Geschäftsrisiko** — es gibt nichts zu umgehen; die Analyse bleibt als
>   Begründung der Entscheidung dokumentiert.
> - **Trainer-Monetarisierung = Trainer-Werkzeug-Abo** (einziges Modell,
>   post-launch zu designen): Klientenverwaltung, Fortschritts-/
>   Reflexprofil-Ansicht, Terminplanung, Sichtbarkeits-Features. Mit dem
>   Gründungs-Versprechen kompatibel (kostenlos ist nur Eintrag/
>   Sichtbarkeit — Werkzeuge sind abgrenzbar; Gründungs-Trainern ggf.
>   dauerhaft vergünstigt als Dankeschön).
> - **Rechtlich fällt weg:** Stripe Connect/ZAG-Thematik, DAC7-Meldepflicht
>   (Plattform vermittelt/kennt keine Zahlungen → kein meldepflichtiger
>   Plattform-Betreiber), Storno-/Ausfallregeln im Plattformvertrag,
>   Provisions-USt. **Bleibt zu prüfen (Anwalt, bei Phase 3):** P2B-VO
>   (greift ggf. schon für die reine Vermittlungsleistung) und die
>   Haftungs-Abgrenzung (Vermittlung ≠ Behandlung) — Abgrenzungs-
>   Formulierung ist im Anwalts-Briefing ergänzt.
> - Umsatzseitig: Die unten stehende Provisions-Beispielrechnung ist
>   hinfällig; das Nutzer-Abo ist damit noch eindeutiger der einzige
>   Umsatzmotor zum Start.

*Ursprüngliche Analyse (Basis der Entscheidung, dokumentarisch):*

### Das designte Modell (15 % Session-Provision via Stripe Connect)

- **Logik:** Sauber konstruiert — Stripe ist der lizenzierte
  Zahlungsdienstleister (Application Fee), Geld fließt nie über unser Konto
  (sonst ZAG-Lizenzthema!). 15 % ist marktüblich und für Trainer psychologisch
  akzeptabel, WENN die Plattform sichtbar liefert (Klienten, Buchung,
  Zahlungsabwicklung, Fortschrittsdaten).
- **Die ehrliche Schwachstelle — Disintermediation:** Unser Anwendungsfall
  ist eine **wiederkehrende 1:1-Beziehung über Wochen**. Nach der ersten
  Session kennen sich Trainer und Klient → Anreiz, an der Plattform vorbei
  bar/direkt zu zahlen, ist strukturell hoch (wie bei Nachhilfe-/
  Therapie-Plattformen). Realistisch verdient die Session-Provision
  zuverlässig nur an der **Erstvermittlung**. Gegenmittel: Wert in der App
  halten (Reflexprofil-Sharing, Chat, Termine, Verlauf — existiert alles!),
  moderate Fee (15 % nicht erhöhen), und kein Polizei-Spielen (undurchsetzbar,
  vergiftet die Beziehung).
- **Robustere Ergänzung mittelfristig:** **Trainer-Werkzeug-Abo** (z. B.
  9–19 €/Monat für Klientenverwaltung, Fortschrittsansicht, Terminplanung,
  Sichtbarkeits-Features) — nicht umgehbar, wertbasiert, planbar. Mit dem
  Gründungs-Versprechen kompatibel: kostenlos versprochen ist nur
  **Eintrag/Sichtbarkeit**; Premium-Werkzeuge sind abgrenzbar. Verworfen:
  Lead-/Kontaktgebühren (bestrafen Kontaktaufnahme, passen nicht zum
  Vertrauensmarkt).
- **Reihenfolge (Henne-Ei):** Aktuell 0 freigeschaltete Trainer. Erst
  Angebotsseite aufbauen (Gründungs-Trainer gratis, läuft), dann Nutzer-
  Paywall (Phase 2), dann Trainer-Payments (Phase 3). Wichtig: Die spätere
  Provision **ab dem ersten Trainer-Onboarding transparent ankündigen**
  (im Trainer-Plattformvertrag), sonst Vertrauensbruch + P2B-Änderungsfristen.

### Größenordnung (Annahmen, keine Prognose)

- Nische Reflexintegration DACH: eher Hunderte aktive Trainer insgesamt.
  Beispiel: 30 aktive Plattform-Trainer × 4 vermittelte Sessions/Monat ×
  70 € × 15 % ≈ **1.250 €/Monat** — optimistisches erstes Jahr.
- Nutzer-Abo: 500 Zahler × ~7,50 €/Monat effektiv (Jahres-Abo-Mix) − 15 %
  Apple ≈ **3.200 €/Monat**.
- **Fazit:** Das Nutzer-Abo ist der Umsatzmotor. Der Trainer-Marktplatz ist
  strategisch (Differenzierung, Netzwerkeffekt, Retention) — als
  Haupt-Umsatzquelle im ersten Jahr unrealistisch.

## 3. Rechtliche Gesamtlage (kompakt)

| Thema | Status |
|---|---|
| IAP-Pflicht für digitale Inhalte (Apple 3.1.1); Stripe-Checkout fürs Abo im App Store unzulässig | bekannt, Roadmap §4; EU-Alternativen (DMA-Link-out) für Solo-Gründer unverhältnismäßig — bleibt so |
| Trainer-Sessions: seit D5 komplett außerhalb der Plattform (direkte Abrechnung Trainer↔Klient) — kein Apple-Thema, kein Zahlungsrecht | D5 2026-07-07 |
| AGB + Widerrufsbelehrung (digitale Inhalte, § 356 Abs. 5 BGB-Mechanik via Apple) | im Anwalts-Briefing als **Baustein 8 (optional)** angefragt ✓ |
| Gewährleistung digitale Produkte (§§ 327 ff. BGB), Preisangaben | ins AGB-Paket (Anwalt) |
| Trainer-Vertragsverhältnis: Haftungsabgrenzung (Vermittlung ≠ Behandlung, Plattform ist nicht Vertragspartei der Sitzungen) + P2B-Verordnung (EU 2019/1150) für die Vermittlungsleistung | Abgrenzungs-Formulierung im Anwalts-Briefing ergänzt (D5); P2B bei Phase 3 prüfen |
| ~~Stripe Connect/ZAG, DAC7-Meldepflicht, Storno-Regeln, Provisions-USt~~ | **entfallen mit D5** (keine Zahlungsvermittlung, keine Kenntnis der Beträge) |
| Keine Heilversprechen in Paywall-/Verkaufs-Copy (UWG/HWG-Nähe) | Standing Rule des Projekts, gilt auch hier |
| Bestandsschutz-Kommunikation vor Paywall-Live | R8-Formel, Founder-Freigabe nötig |

## 4. Empfohlene Ziel-Architektur (für die R8-Design-Session)

1. **Phase 2 (erste Monetarisierung, nach R8-Trigger):** Paywall am Übergang
   zu Paket 2 mit **genau drei Optionen**: Monat 12,99 € · **Jahr 89,99 €
   (hervorgehoben)** · Lifetime 149 € (Anker). Paket 1 dauerhaft frei.
   Freischalt-Codes (access_codes) von Tag 1 im Entitlement-Modell.
   RevenueCat + Apple IAP; Small Business Program beantragen.
2. **Kein Einzelpaket-Verkauf zum Start**; später als Exit-Offer testen,
   wenn Paywall-Absprungdaten es rechtfertigen.
3. **Phase 3 (Trainer-Seite) — Stand D5 2026-07-07:** KEINE Session-Provision
   (Abrechnung direkt Trainer↔Klient, Plattform außen vor). Einziges
   künftiges Trainer-Modell: **Werkzeug-Abo** (eigene Design-Session
   post-launch; P2B-Frage + Haftungs-Abgrenzung dann zum Anwalt).
4. **Stripe entfällt komplett** (D5 + Launch-kostenlos): Nutzer-Käufe laufen
   über Apple IAP (T25), Trainer-Zahlungen existieren plattformseitig nicht.

## Founder-Entscheidung D4 (2026-07-07) — Update

Der Founder bestätigt die Empfehlungen (Trio, kein Einzelkauf zum Start)
und zieht den **Bau der Paywall-Struktur vor** (Aktivierung bleibt
post-launch). Neue Fakten aus der Praxis:

- **Alle Pakete launchen gleichzeitig**; Nutzer trainieren chronologisch.
  Einzelne Frühnutzer werden manuell in ein späteres Paket gesetzt —
  Admin-Sonderfall, kein Paywall-Scope.
- **Reale Programmdauer: 10–12+ Monate** (bei Pausen/Neustarts länger).
  Das validiert die Preisleiter: Monats-Abo über die volle Dauer
  ≈ 156 € > Lifetime 149 € > Jahres-Abo 89,99 €. Jede Option hat damit
  eine ehrliche Rolle: Monat = unverbindlicher Einstieg (zahlt Aufpreis
  für Flexibilität), **Jahr = rationaler Standard** (deckt fast die ganze
  Journey), Lifetime = Pausen-/Neustart-Sicherheit + Abo-Verweigerer.
  Paywall-Copy darf diese Logik ehrlich zeigen („Das Programm dauert
  typischerweise 10–12 Monate“) — das ist Transparenz, kein Druckmittel.

Umsetzung: Tasks **T23** (Entitlement-Modell + Paket-Gating + Paywall-UI,
alles hinter `kPaywallEnabled=false`), **T24** (Freischalt-Codes für
Gründungsnutzer über `access_codes`), **T25** (RevenueCat/IAP-Verkabelung,
⛔ bis ASC-Record + Produkte + RevenueCat-Konto existieren) — Prompts im
Tracker.

## Offene Founder-Entscheidungen (bei Aktivierung der Paywall)

- Bestandsschutz-Formel freigeben (R8-Wortlaut) — vor der ersten
  Launch-Kommunikation.
- Aktivierungs-Trigger bestätigen (Launch stabil + Nutzer erreichen Paket 2).
- AGB/Widerruf beim Anwalt beauftragen (Briefing-Baustein 8 → Festpreis
  liegt dann schon vor).
- Trainer-Monetarisierung (Phase 3): nur Provision vs. Provision +
  Werkzeug-Abo; § 19 UStG mit Steuerberater.
