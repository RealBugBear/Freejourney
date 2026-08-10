# WEBSITE_BUILD_PROMPT — reflexjourney.de (v2, zusammengeführt)

> **Verwendung:** Diesen gesamten Prompt einer Claude-Session (z. B. Sonnet) geben, die im
> Monorepo `corejourney/` arbeitet. Der Prompt ist selbsterklärend und enthält alle
> Entscheidungen, Texte und Prüfschritte. v2 führt zwei Entwürfe zusammen (u. a. neu:
> interaktiver Selbstcheck als Kernstück). Stand: 2026-07-23.

---

## 0. Auftrag

Du bist erfahrene:r Webentwickler:in und Conversion-Texter:in. Baue die öffentliche
Marketing-Website für **Reflex Journey** (reflexjourney.de) als **statische Astro-Site**
im bestehenden Verzeichnis **`reflexjourney-app-site/`** (Monorepo-Root: `corejourney/`).

Reflex Journey ist eine App für Reflexintegrations-Training: geführte Übungsprogramme
zur Integration frühkindlicher Reflexe — mit motorischen UND kognitiven Zielen. Die App
ist noch nicht im App Store (Launch in Vorbereitung).

**Conversion-Funnel der Website:**
1. Primär: **Selbstcheck starten** (interaktiver 3-Minuten-Check, Abschnitt 8) →
   Ergebnis → Warteliste
2. Sekundär: **direkt auf die Warteliste** (Abschnitt 7)

Acht Zielgruppen werden gezielt angesprochen; die Trainer-Plattform ist sekundär
(eine Seite genügt). Nur Deutsch, aber strukturell vorbereitet für Englisch.

Arbeite eigenständig bis zur Definition of Done (Abschnitt 12). Erfinde nichts
(Regel 2.4) — markiere Fehlendes inline als `[FOUNDER: …]` und sammle es in
`FOUNDER_TODO.md`.

---

## 1. Kontext & Quellen der Wahrheit (zuerst lesen!)

- **`app/docs/STORE_LISTING_DRAFT.md`** — Feature-Liste, Tonalität, Wording-Regeln.
  Die Website-Copy muss dazu konsistent sein.
- **`reflexjourney-app-site/index.html`** (aktueller Stand) — Markengrün `#009E6B`,
  Claim „Nervensystem-Training für den Alltag".
- **`app/lib/features/assessment/domain/reflex_questionnaire_definitions.dart`** und
  **`app/lib/features/assessment/domain/reflex_questionnaire.dart`** — der echte
  Einstiegsfragebogen der App (Fragen, Module, Reflex-Zuordnung, `PrimitiveReflex`-Enum,
  Antwortskala `ReflexAnswerType`). Quelle für den Selbstcheck (Abschnitt 8) und die
  Reflexporträts (9.5).
- **`app/lib/features/assessment/domain/reflex_profile_scoring.dart`** —
  Score-Bänder (`ReflexScoreBand`) für die vereinfachte Selbstcheck-Auswertung.
- **`app/lib/core/theme/app_colors.dart`** — Farbwerte der App (in 4.1 übernommen).

**Verlässliche Produkt-Fakten (nur diese verwenden, nichts dazuerfinden):**
aufeinander aufbauende 4-Wochen-Pakete pro Reflex · Einstiegsfragebogen findet den
Startpunkt · täglich geführte Einheiten mit Bildern/Anleitungen · Hands-free-Modus
(Ansagen und Signale führen durch die Einheit, Telefon bleibt weg) · funktioniert
offline, synct später · Dashboard mit Streak, Wochenübersicht, Fortschritt · Journal
nach der Einheit · Stimmungs-Check-ins · optionale Anbindung an zertifizierte:n
Trainer:in (Reflexprofil teilen nur mit Einwilligung, jederzeit widerrufbar) · Profile
für mehrere Personen (z. B. Kind) · EU-Hosting, DSGVO, kein Werbetracking, Konto in
der App löschbar.

**Status Trainer-Plattform:** „Trainer Studio" (Klienten-Verwaltung, eigene Programme)
ist **in Entwicklung** — auf der Website ehrlich als Ausblick kennzeichnen.

---

## 2. Harte Regeln — vor allem anderen lesen

### 2.1 Heilmittelwerberecht (HWG) — wichtigste Regel überhaupt

Keine Heil-, Therapie- oder Medizinversprechen. Reflex Journey ist ein **Trainings-
und Begleitprogramm**, kein Medizinprodukt.

**Verboten:**
- „heilt", „behandelt", „kuriert", „garantiert", „Wunder…", Therapieersatz-Suggestion,
  Diagnose-Sprache („dein Kind hat …")
- **Krankheits-/Störungsbilder als Zielgruppe oder Wirkversprechen** — ADHS, LRS u. ä.
  werden NIE genannt. Benannte Diagnosen (z. B. Skoliose) dürfen ausschließlich in
  der Rahmung „begleitend und in Absprache mit deinen Behandlern" vorkommen, nie als
  „dagegen hilft es".
- Therapie-Fachrichtungen (Logopädie, Ergotherapie, Physiotherapie …) nur in
  Abgrenzungs-/Begleit-Konstruktionen: „begleitend zu …", „ersetzt keine …".
- Erfundene **Testimonials, Nutzerzahlen, Studien, Zertifikate, Auszeichnungen,
  Preise, Termine, Screenshots** — nichts davon existiert freigegeben; nichts erfinden!

**Geboten:**
- „Training", „Übungsprogramm", „kann unterstützen", „begleitend", „viele
  Anwenderinnen und Anwender berichten", beobachtbare **Alltagsthemen** benennen
  (statt Diagnosen).
- Reflex-Zuordnungen immer als Möglichkeit formulieren: „kann/können … in Verbindung
  stehen", „werden damit in Verbindung gebracht" — nie kausal versprechen.
- **Ehrliche wissenschaftliche Einordnung** auf der Wissensseite (9.5): Praxis-
  erfahrungen und wachsendes Interesse, aber begrenzte Studienlage — nüchtern und
  offen; das schafft Vertrauen und ist rechtlich sicher.
- **Pflicht-Disclaimer** (wörtlich, als Komponente `DisclaimerBox`):

  > Reflex Journey ist ein Übungs- und Begleitprogramm. Die App ist kein Medizinprodukt,
  > ersetzt keine ärztliche oder therapeutische Beratung und dient nicht der Erkennung,
  > Behandlung oder Heilung von Krankheiten. Bei gesundheitlichen Beschwerden wende dich
  > bitte an deine Ärztin, deinen Arzt oder deine Therapeutin bzw. deinen Therapeuten.

  Er steht auf **jeder Zielgruppenseite**, auf der Startseite, auf `/app` und auf dem
  **Selbstcheck-Ergebnis** (jeweils vor dem Abschluss-CTA). Kurzform im Footer jeder
  Seite: „Kein Medizinprodukt. Ersetzt keine ärztliche oder therapeutische Beratung."

**Tonalität:** Du-Form (wie der Store-Text), warm, klar, konkret — **keine Esoterik**,
keine Mystik-Metaphern, kein Marketing-Geschrei, keine Angstmache. Keine Emojis in
Headlines. Personenbezeichnungen: Doppelnennung oder :in-Form.

### 2.2 Technik-Erhalt (App-Funktionalität hängt daran!)

**NIEMALS inhaltlich verändern oder unter anderer URL ausliefern:** `auth/confirm/…`,
`auth/reset-password/…`, `.well-known/apple-app-site-association`,
`.well-known/assetlinks.json` sowie die zugehörigen `headers` in `vercel.json`.
Das sind Deep-Link-Ziele der App (Passwort-Reset, E-Mail-Bestätigung, Universal Links).

- Bei Astro: Dateien **byte-identisch** nach `public/auth/…` und `public/.well-known/…`
  legen, sodass **exakt dieselben URLs** erreichbar bleiben.
- `vercel.json`: bestehende `headers` unangetastet lassen; nur ergänzen
  (`"buildCommand": "npm run build"`, `"outputDirectory": "dist"`).
- `.vercel/` (Projekt-Verknüpfung) nicht anfassen.
- **Pflicht-Verifikation am Ende:** `diff -r` zwischen Ursprungsdateien und
  `dist/auth/…` + `dist/.well-known/…` → identisch.

### 2.3 Datenschutz by Design

- **Keine externen Requests**: keine Google Fonts (Abmahnrisiko!), keine CDNs, keine
  Analytics, keine Tracker, keine externen Bilder/Scripts. Fonts self-hosted (3.1).
  Einzige Ausnahmen: der Formular-POST an den konfigurierten Warteliste-Endpoint (7)
  und der String `https://schema.org` als JSON-LD-Kontext.
- Dadurch: **kein Cookie-Banner nötig — keins einbauen.** Das ist Absicht und bleibt so.
- Selbstcheck: Antworten verlassen den Browser nie (Details in 8.7).

### 2.4 Nichts erfinden — `[FOUNDER: …]`-Konvention

Wo dir Fakten fehlen (Preise, Launch-Datum, Altersempfehlung, Support-E-Mail, echte
Screenshots, finale Rechtstexte, Zertifizierungsdetails): **neutralen Platzhalter im
Format `[FOUNDER: was gebraucht wird]`** direkt an der Stelle setzen, zusätzlich in
`FOUNDER_TODO.md` eintragen, weiterarbeiten. Niemals konkrete Zahlen, Termine, Preise
oder Zitate erfinden.

### 2.5 Git & Deploy

- Branch **`website-v1`** im Monorepo; nur Dateien unter `reflexjourney-app-site/`
  erstellen/ändern — nichts außerhalb.
- **Lokale Commits** nach jeder Etappe (Abschnitt 11) sind erwünscht (Checkpoints).
- **NIEMALS pushen, niemals deployen** — das Repo kann automatisch deployen; Deploy
  macht ausschließlich der Founder nach Review.

---

## 3. Technik

### 3.1 Stack

- **Astro** (aktuelle stabile Version, ≥ 5), rein statischer Output, kein Adapter,
  **kein React/Vue** — Interaktivität (Selbstcheck, Formular, Mobile-Nav) mit
  Vanilla-TypeScript in Astro-Komponenten/`<script>`-Blöcken.
- Integration: nur `@astrojs/sitemap`.
- Font: `@fontsource-variable/inter` lokal; falls das Probleme macht, sauberer
  system-ui-Stack als Fallback.
- Styling: Vanilla CSS — globale Design-Tokens (4.1) + komponentenbezogene
  `<style>`-Blöcke. Kein Tailwind, kein Sass.
- FAQ-Akkordeons mit nativen `<details>/<summary>` — ohne JS.
- Node ≥ 20, npm.

### 3.2 Projektstruktur (Zielzustand in `reflexjourney-app-site/`)

```
reflexjourney-app-site/
├── astro.config.mjs          # site: 'https://reflexjourney.de', sitemap
├── package.json / tsconfig.json
├── vercel.json               # Header BEHALTEN + buildCommand/outputDirectory ergänzt
├── README.md                 # Setup, Build, wo Copy liegt, wie EN & Erwachsenen-Check
│                             # später ergänzt werden (3.3)
├── FOUNDER_TODO.md           # gesammelte [FOUNDER: …]-Punkte + Startliste (13)
├── public/
│   ├── auth/…                # unverändert übernommen (2.2)
│   ├── .well-known/…         # unverändert übernommen (2.2)
│   ├── favicon.svg           # Platzhalter: „RJ"-Monogramm, weiß auf #009E6B
│   └── robots.txt
├── src/
│   ├── styles/global.css     # Tokens, Reset, Basis-Typo (4.1)
│   ├── config.ts             # WAITLIST_ENDPOINT, SITE_URL, Kontakt-Platzhalter
│   ├── data/                 # ALLE Texte/Copy als TS/JSON — pro Seite ein Modul +
│   │   ├── site.ts           #   Nav/Footer/Form-Strings; KEINE hartcodierten
│   │   ├── audiences.ts      #   Strings in Komponenten/Seiten (EN-ready!)
│   │   ├── faq.ts
│   │   └── selfcheck/kinder.json
│   ├── components/           # Header, Footer, Hero, AudienceCard, FeatureGrid,
│   │                         # StepList, PhoneMockup, WaitlistForm, DisclaimerBox,
│   │                         # CtaSection, FaqList, Seo, SelfCheck (8)
│   ├── layouts/Base.astro    # <html lang="de">, Seo, Header, Footer, Skip-Link
│   └── pages/                # siehe Sitemap (5)
```

### 3.3 EN-ready-Prinzip (strikt!)

**Sämtliche sichtbaren Texte** liegen in `src/data/`-Modulen (bzw. der Selbstcheck-
JSON) — Komponenten und Seiten konsumieren nur. Eine englische Version später darf
**ausschließlich neue Datendateien** erfordern, null Komponentenänderung. Genau das im
README dokumentieren (die App-Codebase hat mit ~750 nachträglichen Hardcode-Funden
schmerzhaft gelernt, warum diese Regel gilt).

---

## 4. Design-System

Ruhig, professionell, gesundheitsnah, warm — keine Esoterik-Anmutung, keine
Stockfoto-Klischees. Viel Weißraum, sanfte Rundungen, dezente organische Formen
als Deko-Elemente.

### 4.1 Tokens (aus `app/lib/core/theme/app_colors.dart` übernommen)

```css
:root {
  color-scheme: light; /* v1 ist bewusst nur Light Mode */

  --color-primary: #009E6B;        /* Markengrün — Akzente, Deko, große Flächen */
  --color-primary-dark: #007A52;   /* Buttons, Links, Text auf Weiß (AA-sicher) */
  --color-primary-light: #6FD4A8;  /* Verläufe, Hintergrund-Akzente */
  --color-text: #0D1F15;           /* Primärtext (Anthrazit-Grün) */
  --color-text-secondary: #3D6B4F;
  --color-bg: #F4FAF6;             /* warmes Off-White/Mint als Seitenhintergrund */
  --color-surface: #FFFFFF;
  --color-surface-alt: #F0F5F2;
  --color-divider: #D8EEE2;
  --color-error: #FF3B30;          /* Formular-Fehler, sparsam */

  --font-sans: 'Inter Variable', system-ui, -apple-system, sans-serif;
  --radius-s: 8px; --radius-m: 12px; --radius-l: 20px;
  --shadow-card: 0 2px 12px rgba(13, 31, 21, 0.06);
  --space-1: 4px; --space-2: 8px; --space-3: 16px; --space-4: 24px;
  --space-5: 40px; --space-6: 64px; --space-7: 96px;
  --max-width: 1120px;
}
```

**Kontrast-Regel (häufiger Fehler):** Weißer Text auf `--color-primary` (#009E6B)
besteht WCAG AA **nur** bei großer Schrift (≥ 24px oder ≥ 18.5px fett). Deshalb:
Buttons/Links auf hellem Grund immer `--color-primary-dark` (#007A52, Kontrast 5.4:1);
Hover darf auf #009E6B aufhellen. Fließtext nie weiß auf Mittelgrün. Alle
Text-Kombinationen AA-prüfen.

### 4.2 Typografie & Ikonen

Inter Variable (`font-display: swap`), Fließtext 16–18px, Zeilenhöhe 1.6, Headlines
kräftig (700). Ikonen: einfache Inline-SVG-Linienicons (24px-Raster,
`stroke="currentColor"`, `stroke-width="2"`, `aria-hidden="true"`) — selbst zeichnen,
simpel halten, keine Icon-Bibliothek.

### 4.3 Bildsprache v1 (es gibt noch keine Fotos/Screenshots)

- Komponente **`PhoneMockup`**: CSS/SVG-Smartphone-Rahmen mit **stilisierten,
  abstrakten UI-Andeutungen** (Balken, Karten, Kreise in Markenfarben + echten kurzen
  Feature-Begriffen wie „Tag 12 von 28", „Hands-free"). Als Illustration erkennbar —
  **keine fotorealistischen Fake-Screenshots.**
- Überall, wo später echte Bilder hingehören: `[FOUNDER: Screenshot/Foto …]`-Marker
  setzen; Struktur so bauen, dass Austausch per Bildpfad reicht.

### 4.4 Barrierefreiheit & Performance

Semantische Landmarks, genau **ein `<h1>` pro Seite**, logische Heading-Hierarchie,
Skip-Link, sichtbare Fokus-Stile, sinnvolle `aria`-Attribute, Touch-Ziele ≥ 44px,
echte Labels (kein Placeholder-als-Label), `prefers-reduced-motion` respektieren.
**Selbstcheck und Formulare komplett per Tastatur bedienbar.** Kein Bild > 100 KB
(v1 ist ohnehin SVG-only), kein unnötiges JS. Ziel: Lighthouse ≥ 95 überall.

---

## 5. Sitemap & Navigation (URLs ohne Umlaute)

`/` · `/selbstcheck` · `/app` · `/fuer/eltern-und-kinder` · `/fuer/stress-und-alltag` ·
`/fuer/sport` · `/fuer/beruf-und-leistung` · `/fuer/koerper-und-haltung` ·
`/fuer/sprechen-und-mundmotorik` · `/fuer/senioren` · `/trainer` ·
`/wissen/reflexintegration` · `/faq` · `/warteliste` · `/impressum` · `/datenschutz` ·
404-Seite

Die 7 `/fuer/*`-Seiten entstehen aus **einem** Template (`fuer/[slug].astro` mit
`getStaticPaths` über `audiences.ts`).

**Header:** Wortmarke „Reflex Journey" (Text + kleines SVG-Monogramm) · Für wen?
(Aufklapp-Liste der 7 Zielgruppen) · Die App · Wissen · Für Trainer · FAQ ·
CTA-Button „Selbstcheck" (immer sichtbar). Mobil: Burger → Overlay.

**Footer:** Kurzbeschreibung + Disclaimer-Kurzform · Spaltenliste aller Seiten ·
Impressum/Datenschutz · „© 2026 Reflex Journey".

---

## 6. Zielgruppenseiten `/fuer/*` — ein Template, 7 Datensätze

### 6.1 Template-Aufbau

1. **Hero**: Eyebrow „Reflexintegration für <Gruppe>" · H1 (Claim) · 2–3 Sätze Intro ·
   CTA primär „Selbstcheck starten" + sekundär „Auf die Warteliste"
2. **„Kennst du das?"** — 4–6 Alltags-Painpoints als Karten (Icon + 1 Satz, du-Form,
   empathisch, ohne Diagnosen, ohne Angstmache)
3. **„Was dahinterstecken kann"** — 2–3 Absätze: welche Restreflexe hier
   typischerweise eine Rolle spielen können (rein informativ, „kann"-Formulierungen)
   + Mini-Liste der Reflexe mit je 1 Satz. Link auf `/wissen/reflexintegration`.
4. **„So begleitet dich Reflex Journey"** — 3–4 Schritte (StepList: Fragebogen →
   Startpunkt → tägliche geführte Einheiten, 10–15 Min → Fortschritt & Journal) +
   2–3 zielgruppenspezifische Feature-Highlights (nur Fakten aus Abschnitt 1)
5. **Mini-FAQ** — 3 zielgruppenspezifische Fragen
6. **DisclaimerBox** (wörtlich, 2.1)
7. **CtaSection**: Selbstcheck-CTA + WaitlistForm (Seiten-Slug wird als Segment
   mitgesendet, 7)

### 6.2 Daten der 7 Zielgruppen (nach `audiences.ts` übertragen)

Typ: `slug`, `navLabel`, `metaTitle`, `metaDescription`, `eyebrow`, `h1`, `intro`,
`tone`, `painpoints[]`, `reflexes[]`, `appBenefits[]`, `faq[]`. Painpoints/FAQ darfst
du sprachlich glätten und regelkonform ergänzen — Kernaussagen beibehalten.

**Wichtig:** Gleiche alle Reflex-Nennungen mit dem `PrimitiveReflex`-Enum der App ab
(`reflex_questionnaire.dart`). Nenne nur Reflexe, die es dort gibt; Sammelbegriffe wie
„orale Reflexe" sind zusätzlich erlaubt. Passe die Listen unten entsprechend an.

**1. `eltern-und-kinder` — Eltern & Kinder** · Ton: warm, entlastend, ohne Druck
- H1: „Stärke dein Kind — spielerisch, 10 Minuten am Tag"
- Painpoints: Konzentration kippt nach wenigen Minuten Hausaufgaben · ständiges
  Zappeln/Rutschen auf dem Stuhl · verkrampfte Stifthaltung, Schreiben strengt an ·
  mühsames Lesen/Schreiben trotz Übens · stolpert oft, wirkt „ungeschickt" ·
  Zehengang · schnell frustriert oder überreizt
- Reflexe: Moro, ATNR, STNR, Spinaler Galant, Palmar, TLR
- App-Nutzen: gemeinsames tägliches Ritual mit bildgeführten Übungen · eigenes Profil
  für dein Kind · Erinnerungen, die in den Familienalltag passen
- FAQ: Ab welchem Alter? (`[FOUNDER: Altersempfehlung]`; bis dahin: „gemeinsam mit
  einem Erwachsenen") · Ersetzt das Ergo-/Lerntherapie? (Nein — begleitend, in
  Absprache) · Wie lange dauert eine Einheit? (ca. 10–15 Minuten)
- Compliance: ADHS/LRS nicht nennen; „begleitend zu Ergo-/Lerntherapie" ist die
  erlaubte Rahmung.

**2. `stress-und-alltag` — Stress, innere Unruhe & Schlaf** · Ton: ruhig, verständnisvoll
- H1: „Wenn dein Nervensystem nie auf ‚Ruhe' schaltet"
- Painpoints: ständig „auf Habacht", auch wenn nichts ansteht · Gedankenkarussell beim
  Einschlafen · schreckhaft bei Geräuschen oder Berührung · Reizüberflutung in lauten,
  vollen Umgebungen · Schultern/Nacken abends wie festgezurrt · Erschöpfung trotz
  Pausen
- Reflexe: Moro, TLR (weitere nur, falls im Enum vorhanden, z. B. Furcht-Lähmungs-Reflex)
- App-Nutzen: feste Abendroutine mit Hands-free-Führung · Journal + Stimmungs-Check-ins
  zeigen Veränderungen über Wochen · offline nutzbar, ohne Extra-Bildschirmzeit
- FAQ: Wie schnell merke ich etwas? (individuell; 4-Wochen-Blöcke, Regelmäßigkeit
  zählt) · Ist das Meditation? (Nein — körperliche Übungen mit Bezug zu frühkindlichen
  Reflexen) · Ersetzt es Psychotherapie? (Nein — Disclaimer-Rahmung)

**3. `sport` — Sport & Leistungssport** · Ton: präzise, leistungsorientiert (Hobby bis Profi)
- H1: „Die Basis, die zwischen dir und deinem nächsten Level liegt"
- Painpoints: Plateau trotz sauberem Trainingsplan · Balance/einbeinige Stabilität
  links/rechts spürbar unterschiedlich · Reaktionszeit lässt unter Druck nach ·
  Überkreuz-Koordination kostet Konzentration · Bewegungen fühlen sich „eckig" statt
  flüssig an — das letzte Prozent fehlt
- Reflexe: ATNR, STNR, TLR
- App-Nutzen: 4-Wochen-Blöcke als Ergänzung zum Trainingsplan · kurze tägliche
  Einheiten, Konstanz über Streak & Wochenübersicht sichtbar · Hands-free im Warm-up
- FAQ: Ersetzt das mein Techniktraining? (Nein — Grundlagenarbeit darunter) · Für
  welche Sportarten? (übergreifend — es geht um Basis-Bewegungsmuster) · Passt es ins
  Warm-up? (Ja, Einheiten sind kurz und geführt)

**4. `beruf-und-leistung` — Beruf & Leistung** · Ton: nüchtern, effizient; motorisch UND kognitiv argumentieren
- H1: „Klarer Kopf, wenn es zählt"
- Painpoints: Fokus bricht in langen Meetings ein · mentale Ermüdung ab Nachmittag ·
  unter Druck flacher Atem, hochgezogene Schultern · Verspannung am Schreibtisch
  (Nacken, Kiefer) · Stressregulation vor wichtigen Terminen fällt schwer · abends
  schlecht abschalten
- Reflexe: Moro, STNR, ATNR
- App-Nutzen: 10 Minuten am Tag, klar geführt · Hands-free — kein zusätzlicher
  Bildschirmkonsum · Fortschritt und Stimmungsverlauf sichtbar
- FAQ: Wie viel Zeit brauche ich? (10–15 Min/Tag) · Ist das Biohacking?
  (Bodenständiger: strukturiertes Körpertraining mit Bezug zu frühkindlichen
  Reflexen) · Merkt mein Umfeld etwas? (Übungen sind unauffällig, zuhause machbar)

**5. `koerper-und-haltung` — Körper, Haltung & Verspannungen** · Ton: körpernah, seriös
- H1: „Wenn Verspannungen immer wiederkommen, lohnt der Blick eine Ebene tiefer"
- Painpoints: chronische Nacken-/Schulter-/Rückenverspannung trotz Massagen ·
  Kieferanspannung, Zähneknirschen (auch nachts) · Haltung „fällt zusammen", sobald
  die Aufmerksamkeit weg ist · Gefühl von Schiefstand/einseitiger Belastung · langes
  Sitzen strengt überproportional an · Dehnen hilft nur kurz
- Reflexe: TLR, Spinaler Galant, STNR, Landau, Babkin (Enum-Abgleich!)
- App-Nutzen: tägliche kurze Einheiten statt seltener großer Termine · geführte
  Übungen mit Bild und Ansage · Journal fürs Körpergefühl über Wochen
- FAQ: Diagnostizierte Skoliose — geeignet? (Nur begleitend und in Absprache mit
  deinen Behandlern; ersetzt keine Behandlung) · Ersetzt das Physiotherapie oder
  ärztliche Abklärung? (Nein — Ergänzung) · Muss ich fit/beweglich sein? (Nein,
  niedrigschwellig)

**6. `sprechen-und-mundmotorik` — Sprechen & Mundmotorik** · Ton: fachlich, respektvoll
- H1: „Deutlicher sprechen beginnt vor der Aussprache"
- Painpoints: Nuscheln/undeutliche Aussprache — andere fragen oft nach (Kind wie
  Erwachsene) · schnelles, verwaschenes Sprechen · die Zunge scheint „im Weg" ·
  lautes, deutliches Sprechen strengt an · Kiefer verspannt beim Reden
- Reflexe: Babkin, Saug-/Suchreflex, Palmar (Enum-Abgleich!)
- App-Nutzen: geführte Einheiten als Basisarbeit — damit gezielte Übungen (z. B.
  begleitend zur Logopädie) besser aufsetzen können · kurze tägliche Routine ·
  Fortschritts-Journal
- FAQ: Ersetzt das Logopädie? (Nein — Basisarbeit, begleitend, in Absprache) · Für
  Erwachsene UND Kinder? (Ja, eigene Profile) · Was sind orale Reflexe? (Kurzerklärung
  + Link `/wissen/reflexintegration`)

**7. `senioren` — Aktiv im Alter** · Ton: respektvoll, ermutigend, klar
- H1: „Sicher auf den Beinen bleiben — mit täglichem, sanftem Training"
- Painpoints: Unsicherheit auf Treppen/unebenem Boden · Gang wird kleinschrittiger ·
  Gleichgewicht fordert mehr Aufmerksamkeit als früher · Beweglichkeit nimmt schneller
  ab als gewünscht · geistig aktiv bleiben ist dir wichtig · bei Übungen allein:
  unklar, ob man sie richtig macht
- Reflexe: TLR, Moro, Babinski (Enum-Abgleich!)
- App-Nutzen: einfache, geführte Einheiten in deinem Tempo · klare Bilder und
  Ansagen · Erinnerungen halten die Routine am Laufen
- FAQ: Ist das anstrengend? (Sanft, niedrigschwellig, eigenes Tempo) · Brauche ich
  Geräte? (Nein — bequeme Kleidung, Matte optional) · Kann Training Stürzen
  vorbeugen? (Gleichgewicht und Trittsicherheit lassen sich trainieren; bei
  Sturzvorgeschichte zusätzlich ärztlich beraten lassen)

---

## 7. Warteliste

`WaitlistForm`-Komponente — auf jeder Seite (CtaSection), auf dem Selbstcheck-Ergebnis
und als eigene Seite `/warteliste` („Die App erscheint bald — trag dich ein, wir melden
uns zum Launch. Kein Spam, keine Weitergabe.").

- **Felder:** E-Mail (Pflicht, `type=email`, sichtbares Label) · optionales Select
  „Ich interessiere mich als: Elternteil / für mich selbst / Fachperson bzw.
  Trainer:in" · verstecktes Feld `segment` (Seiten-Slug bzw. Sonderwerte
  `erwachsenen-check`, `trainer`) · Honeypot-Textfeld (visually hidden,
  `tabindex="-1"`, `autocomplete="off"`; bei Befüllung Submit verwerfen).
- **Technik:** POST an `WAITLIST_ENDPOINT` aus `src/config.ts`
  (`= "[FOUNDER: Endpoint eintragen]"`), mit Kommentar im Code, wie Formspree ODER
  Supabase eingetragen wird. **Solange der Platzhalter steht:** Formular rendert
  normal, bei Submit erscheint ein freundlicher Hinweis, dass die Anmeldung in Kürze
  freigeschaltet wird — kein toter Request, kein Absturz. Mit gesetztem Endpoint:
  `fetch`-Submit mit sauberen Erfolgs-/Fehlerzuständen + natives POST-Fallback
  ohne JS.
- **Rechtstext unterm Button:** „Mit dem Eintragen bist du einverstanden, dass wir
  dich per E-Mail über den Start von Reflex Journey informieren. Du kannst dich
  jederzeit abmelden. Mehr in der Datenschutzerklärung." (verlinkt;
  `[FOUNDER: finalen Einwilligungstext mit Kanzlei klären]`)
- Keine weiteren Pflichtfelder, kein Captcha.

---

## 8. Selbstcheck `/selbstcheck` — Kernstück, sorgfältig bauen

**Konzept:** Interaktiver 3-Minuten-Kurzcheck als Teaser. Das vollständige Reflexprofil
gibt es nur in der App — der Check macht neugierig und führt zur Warteliste. Oben auf
der Seite klarstellen: Beobachtungshilfe, **kein Diagnose-Instrument**.

1. **Einstieg:** Zwei Karten — **„Für mein Kind"** (aktiv; Eltern beantworten den
   Check über ihr Kind) und **„Für mich selbst (Erwachsene)"** mit Badge „Bald
   verfügbar" und eigenem Wartelisten-Feld („Wir sagen dir Bescheid, sobald der
   Erwachsenen-Check da ist", `segment=erwachsenen-check`). Viele Besucher sind
   Erwachsene — diese Karte muss einladend sein, nicht wie ein toter Link.
2. **Fragenquelle:** Wähle **12–15 Fragen wörtlich** aus
   `reflex_questionnaire_definitions.dart`. Regeln: **nur Alltags-/Beobachtungs-
   module** — das Modul `pregnancyBirth` (Schwangerschaft/Geburt) ist für die
   öffentliche Website **tabu**; möglichst viele verschiedene Reflexe abdecken; nur
   klar beobachtbare, nicht stigmatisierende Fragen. Antwortskala aus
   `ReflexAnswerType` übernehmen (gleiche Optionen wie in der App).
3. **Datenformat:** `src/data/selfcheck/kinder.json` — pro Frage: `id`, `module`,
   `text`, `reflexes[]`, `answerType`. Eine **generische Komponente** rendert jeden
   Fragebogen aus so einer JSON. Der Erwachsenen-Check ist später nur eine zweite
   Datei `erwachsene.json` — null Codeänderung. Im README dokumentieren.
4. **UI:** Eine Frage pro Schritt, Fortschrittsbalken, Zurück möglich, komplett per
   Tastatur bedienbar. Kein Login, keine Pflichtfelder außer den Antworten.
5. **Auswertung (rein client-seitig):** Mappe Reflexe auf 5 Alltagsbereiche:
   Gleichgewicht & Koordination · Konzentration & Lernen · Haltung & Verspannung ·
   Mund & Sprache · Stressreaktion & Schlaf. Schwellen vereinfacht pro Bereich,
   orientiert an den Score-Bändern der App (`ReflexScoreBand` in
   `reflex_profile_scoring.dart` — lies die echten Werte dort nach). Ergebnis-Sprache
   ausschließlich beobachtend: „Deine Antworten zeigen Hinweise in 3 Bereichen: …" —
   niemals Diagnose-Sprache, niemals „dein Kind hat …". Bei wenigen/keinen Hinweisen
   ein ehrliches, positives Ergebnis (**kein künstliches Alarmieren**).
6. **Ergebnis-Screen:** Bereiche mit Hinweisen in Alltagssprache (Reflex-Fachbegriffe
   nur als aufklappbare „Mehr erfahren"-Ebene) → DisclaimerBox (2.1) → CTA: „Das
   vollständige Reflexprofil und dein Übungsprogramm bekommst du in der App" +
   WaitlistForm direkt auf dem Ergebnis-Screen.
7. **Datenschutz:** Antworten verlassen den Browser nie und werden nicht dauerhaft
   gespeichert (allenfalls `sessionStorage` für den Zwischenstand). Beim
   Wartelisten-Eintrag wird **nur die E-Mail (+ Segment)** übertragen, niemals
   Antworten oder Ergebnis. Sichtbar unter dem Check erklären: „Deine Antworten
   bleiben auf deinem Gerät."
8. **Review-Ausgabe:** Liste am Ende alle gewählten Fragen mit Modul und
   Reflex-Zuordnung zur Freigabe durch den Founder auf (Teil der Abschluss-Ausgabe,
   Abschnitt 13).

---

## 9. Übrige Seiten

### 9.1 Startseite `/`

1. **Hero:** Claim auf Basis „Nervensystem-Training für den Alltag" (schlage in der
   Abschluss-Ausgabe 2 Alternativen zur Auswahl vor) · Subline: für wen und was es
   bringt (z. B. „Reflex Journey führt dich Schritt für Schritt durch die Integration
   frühkindlicher Reflexe — für Ruhe, Fokus und Bewegungsqualität. Für dich oder
   gemeinsam mit deinem Kind.") · CTA primär „Selbstcheck starten", sekundär „Auf die
   Warteliste" · Badge „Bald im App Store" · PhoneMockup
2. **Vertrauenszeile** (nur Fakten): „Hosting in der EU · DSGVO-konform · Kein
   Werbetracking · Optional begleitet von zertifizierten Trainerinnen und Trainern"
3. **Was ist Reflexintegration?** — 3–4 seriöse Sätze: frühkindliche Reflexe als
   normale Entwicklungsprogramme; bleiben sie aktiv, können sie Bewegung, Haltung,
   Konzentration und Stressreaktion im Alltag beeinflussen; gezieltes Training setzt
   genau dort an. Link auf `/wissen/reflexintegration`.
4. **Für wen** — Karten-Grid: 7 Zielgruppen + Trainer-Karte, je 1 Painpoint-Hook-Satz,
   verlinkt auf die Unterseiten.
5. **Die App** — 4 Feature-Blöcke mit PhoneMockup-Platzhaltern: Dein Programm (Pakete +
   Einstiegsfragebogen) · Hands-free-Training im Alltag · Fortschritt sichtbar
   (Dashboard, Journal, Stimmung) · Gemeinsam statt allein (Trainer, Familienprofile).
   Link auf `/app`.
6. **So funktioniert's** — 3 Schritte: Selbstcheck/Fragebogen → tägliche geführte
   Einheiten → Veränderung beobachten.
7. **Vertrauen & Ehrlichkeit** — EU-Hosting, DSGVO, kein Werbetracking, Daten
   löschbar + DisclaimerBox (was die App ist und was nicht).
8. **FAQ-Teaser** (3 Fragen, Link auf `/faq`) · 9. **CtaSection** (Selbstcheck +
   WaitlistForm) · Footer.

### 9.2 `/app`

Ausführliche Fassung von Startseiten-Block 5: alle Produkt-Fakten aus Abschnitt 1 in
erlebbaren Nutzen übersetzt, gegliedert wie der Store-Draft (Dein Programm · Training
im Alltag · Deine Entwicklung im Blick · Gemeinsam statt allein · Deine Daten gehören
dir), je Feature ein PhoneMockup-Platzhalter. **Preise nicht nennen**
(`[FOUNDER: Preismodell-Kommunikation zum Launch]`). Abschluss: DisclaimerBox +
CtaSection.

### 9.3 `/trainer` (Fachkreise & Trainer)

- Zielgruppe: Ergotherapie, Logopädie, Physiotherapie, Osteopathie, Lerntherapie,
  Heilpraktiker:innen, Reflexintegrations-Trainer:innen, Coaches.
- Inhalt: App als Begleit-Tool für Klientinnen und Klienten zwischen den Terminen
  (geführte Einheiten, Erinnerungen → Dranbleiben) · Fortschritt/Reflexprofil einsehen
  **nur mit expliziter, jederzeit widerrufbarer Einwilligung** · Onboarding per
  Zugangscode · Trainer-Plattform „Trainer Studio" (Klienten-Verwaltung, eigene
  Programme) ehrlich als **„in Entwicklung"** kennzeichnen.
- Sektion „So arbeitet ihr zusammen" (3 Schritte) + Mini-FAQ (Einwilligung/Datenschutz ·
  Kosten für Trainer `[FOUNDER]` · Voraussetzungen `[FOUNDER: Zertifizierungs-/
  Kooperationsdetails]`).
- CTA: WaitlistForm mit `segment=trainer`, Überschrift „Trainer-Warteliste: Wir melden
  uns, sobald es losgeht."

### 9.4 `/wissen/reflexintegration` (SEO-Kernseite)

Seriöse Grundlagenseite: Was sind frühkindliche Reflexe (sinnvolle automatische
Bewegungsprogramme des Babys) · warum werden sie normalerweise integriert · was heißt
Restaktivität (kann sich bei Kindern und Erwachsenen in Haltung, Konzentration,
Stressreaktion oder Bewegungsqualität bemerkbar machen — „kann"-Formulierungen!) ·
wie sieht Training aus (regelmäßige, spezifische Bewegungsübungen über Wochen).

- **„Was sagt die Forschung?"** — ehrlicher Absatz: Praxiserfahrungen und wachsendes
  Interesse, aber begrenzte Studienlage; die App versteht sich als Trainingsprogramm,
  nicht als Therapie. Genau so nüchtern schreiben.
- **Reflex-Kurzporträts** aus dem `PrimitiveReflex`-Enum der App (je 2–3 neutrale
  Sätze: wofür der Reflex beim Baby da ist, was bei Restaktivität im Alltag
  beobachtbar sein kann — keine Krankheitszuschreibungen).
- „Woran du merkst, dass Reflexe ein Thema sein könnten" → 5–6 Alltagsbeispiele quer
  durch die Zielgruppen, je mit Link auf die passende `/fuer/…`-Seite (interne
  Verlinkung!). Selbstcheck-CTA + CtaSection.

### 9.5 `/faq`

Ca. 10 Fragen aus `faq.ts`, als `<details>`-Liste + JSON-LD `FAQPage`: Was ist
Reflexintegration? · Für wen ist die App? · Ersetzt sie Therapie oder Arztbesuch?
(klares Nein + Disclaimer-Kern) · Wie läuft ein Programm ab / wie lange dauert es?
(4 Wochen pro Reflex, täglich 10–15 Min) · Wie schnell merke ich etwas? (ehrlich:
individuell, Konstanz zählt) · Brauche ich eine:n Trainer:in? (Nein — optional) ·
Ab welchem Alter? `[FOUNDER]` · Was kostet die App? `[FOUNDER]` · Wann ist Launch?
(`[FOUNDER]` — kein Datum erfinden; auf Warteliste verweisen) · Funktioniert sie
offline? (Ja) · Was passiert mit meinen Daten? (EU, DSGVO, kein Werbetracking, in
der App löschbar)

### 9.6 `/impressum`, `/datenschutz`, 404

- Legal-Seiten: nur Gerüst mit vollständiger Abschnittsstruktur und
  `[FOUNDER: von Kanzlei freigegebenen Text einfügen]` — **keine Rechtstexte selbst
  formulieren** (Entwürfe liegen bereits bei der Kanzlei). Beide mit `noindex`
  (Meta-Robots), bis Inhalte final sind.
- 404: freundlich, mit Navigation zur Startseite, zum Selbstcheck und zu den
  Zielgruppen.

---

## 10. SEO & Meta

- `Seo`-Komponente: `<title>`, Meta-Description, Canonical
  (`https://reflexjourney.de/...`), `og:title/description/type/url/image`
  (og:image → Platzhalterpfad `/og/default.png`, `[FOUNDER: OG-Bild 1200×630]`),
  `twitter:card`, `theme-color #009E6B`.
- JSON-LD: `Organization` + `WebSite` global; `FAQPage` auf `/faq`;
  `SoftwareApplication` auf `/app` (`operatingSystem: iOS`,
  `applicationCategory: HealthApplication`, ohne Preis/Rating).
- `@astrojs/sitemap` + `robots.txt`; 404 von der Sitemap ausgeschlossen; Legal-Seiten
  `noindex`.
- Keywords natürlich einarbeiten (Reflexintegration, frühkindliche Reflexe,
  Moro-Reflex, restaktive Reflexe, Übungen, App) — kein Stuffing, **keine
  Krankheits-Keywords**.
- **Meta-Texte (verbatim übernehmen; Muster „… | Reflex Journey" wo Platz ist):**

| Seite | Title (≤ 60) | Description (≤ 155) |
|---|---|---|
| `/` | Reflex Journey — Nervensystem-Training für den Alltag | Die App für Reflexintegration: geführte tägliche Übungen zur Integration frühkindlicher Reflexe — für Ruhe, Fokus und Bewegungsqualität. |
| `/selbstcheck` | Reflex-Selbstcheck für dein Kind — 3 Minuten | 12–15 Alltagsfragen aus dem echten Einstiegsfragebogen, Ergebnis sofort — anonym, ohne Anmeldung. Deine Antworten bleiben auf deinem Gerät. |
| `/app` | Die Reflex-Journey-App: Funktionen im Überblick | 4-Wochen-Programme, Hands-free-Modus, Journal, Familienprofile, optionale Trainer-Anbindung — DSGVO-konform mit EU-Hosting. |
| `/fuer/eltern-und-kinder` | Reflexintegration für Kinder — Übungen für zuhause | Konzentration, Stifthaltung, Stillsitzen: Wie frühkindliche Reflexe damit zusammenhängen können — und wie ihr mit 10 Minuten am Tag trainiert. |
| `/fuer/stress-und-alltag` | Innere Unruhe & Stress: Training fürs Nervensystem | Ständig auf Habacht, schlecht abschalten? Wie der Mororeflex damit in Verbindung stehen kann — und wie tägliches Training aussieht. |
| `/fuer/sport` | Reflexintegration im Sport — Basis für Performance | Balance, Koordination, Bewegungsqualität: Warum Restreflexe Sportler ausbremsen können und wie du die Basis in 4-Wochen-Blöcken trainierst. |
| `/fuer/beruf-und-leistung` | Fokus & Stressregulation im Beruf trainieren | Klarer Kopf unter Druck: tägliches 10-Minuten-Training mit Bezug zu frühkindlichen Reflexen — geführt, hands-free, ohne Extra-Bildschirmzeit. |
| `/fuer/koerper-und-haltung` | Verspannungen & Haltung: eine Ebene tiefer ansetzen | Wiederkehrende Verspannungen, Kieferanspannung, Haltung: Wie Grundtonus und Restreflexe zusammenhängen können — und wie du täglich trainierst. |
| `/fuer/sprechen-und-mundmotorik` | Mundmotorik & deutlich sprechen — Basistraining | Nuscheln, verwaschenes Sprechen? Orale Reflexe als mögliche Basis-Ebene — Training als Ergänzung zur Logopädie, für Erwachsene und Kinder. |
| `/fuer/senioren` | Gleichgewicht im Alter — sanftes tägliches Training | Sicher auf den Beinen: geführte, sanfte Übungen für Balance und Beweglichkeit — in deinem Tempo, mit klaren Bildern und Ansagen. |
| `/trainer` | Reflex Journey für Trainer, Praxen & Fachkreise | Begleite Klientinnen und Klienten zwischen den Terminen: einwilligungsbasierte Fortschritts-Einblicke, geführte Programme, Trainer-Warteliste. |
| `/wissen/reflexintegration` | Was ist Reflexintegration? Einfach erklärt | Frühkindliche Reflexe, Restaktivität und Training: verständlich erklärt — mit Reflex-Glossar von Moro bis ATNR und ehrlicher Einordnung. |
| `/faq` | FAQ — häufige Fragen zu Reflex Journey | Antworten zu Reflexintegration, Programmablauf, Alter, Datenschutz und Launch der App. |
| `/warteliste` | Warteliste — beim Launch dabei sein | Trag dich ein und erfahre als Erstes, wenn Reflex Journey für iPhone erscheint. Kein Spam, jederzeit abmeldbar. |

---

## 11. Arbeitsplan

**Gib zuerst einen kurzen Plan aus** (Seitenliste, Komponentenliste, die gewählten
Selbstcheck-Fragen mit Modul/Reflex) — dann baue in Etappen, je mit lokalem Commit
(kein Push!):

1. **E1 Setup & Erhalt:** Branch `website-v1` · Astro initialisieren · `auth/` +
   `.well-known/` nach `public/` · `vercel.json` ergänzen · Build läuft ·
   Erhalt-Diff grün (2.2)
2. **E2 Fundament:** `global.css` (Tokens) · `Base.astro` · `Seo` · Header/Footer ·
   `site.ts`, `config.ts` · README-Gerüst
3. **E3 Komponenten:** Hero, AudienceCard, FeatureGrid, StepList, PhoneMockup,
   DisclaimerBox, WaitlistForm, CtaSection, FaqList
4. **E4 Startseite** komplett
5. **E5 Selbstcheck** (Kernstück — Fragen wählen, JSON, Komponente, Auswertung,
   Ergebnis-Screen)
6. **E6 Zielgruppen:** `audiences.ts` (alle 7) + `fuer/[slug].astro`
7. **E7 Übrige Seiten:** `app`, `trainer`, `wissen/reflexintegration`, `faq`,
   `warteliste`, Legal-Gerüste, 404
8. **E8 Finish:** SEO (Meta-Tabelle, JSON-LD, sitemap, robots) · Definition of Done
   (12) · README + `FOUNDER_TODO.md` vervollständigen · Abschluss-Ausgabe (13)

Bei Unsicherheit: konservativ entscheiden, `[FOUNDER: …]` setzen, nichts erfinden.

---

## 12. Definition of Done (alles selbst prüfen, bevor du „fertig" sagst)

1. `npm run build` und `npx astro check` laufen fehlerfrei; Output angesehen.
2. Alle 17 Seiten (Abschnitt 5 inkl. 404) existieren im `dist/`-Output.
3. **Erhalt-Check:** `dist/auth/…` und `dist/.well-known/…` byte-identisch zum
   Ursprungszustand (`diff -r`); `vercel.json`-Header unangetastet.
4. Jede Seite: genau ein `<h1>`, Title + Description exakt aus der Meta-Tabelle,
   Canonical gesetzt; jede Seite von Nav oder Startseite erreichbar; alle internen
   Links funktionieren.
5. **Compliance-Grep** über `src/` und `dist/`: `heilt|Heilung|kuriert|garantiert|
   Wunder|ADHS|LRS` → 0 Treffer außerhalb der Disclaimer-Negation („…Heilung von
   Krankheiten"). Zusätzlich manuell: keine Diagnose als Wirkversprechen;
   DisclaimerBox auf allen Zielgruppenseiten, Startseite, `/app` und
   Selbstcheck-Ergebnis; Kurzform im Footer.
6. **Extern-Check:** keine Requests auf fremde Hosts in `dist/` (grep `https://` in
   HTML/CSS/JS) außer `WAITLIST_ENDPOINT`-Konfiguration und `schema.org`-Kontext.
   Keine Fonts von extern, kein Cookie-Banner.
7. Keine erfundenen Zahlen, Testimonials, Logos, Preise, Termine, Studien (manuell
   gegenlesen); alle Lücken als `[FOUNDER: …]` markiert.
8. **Selbstcheck:** alle Antwortpfade durchgespielt (viele / wenige / keine
   Hinweise) — Ergebnis-Copy in allen Fällen HWG-konform und nicht alarmierend;
   `pregnancyBirth`-Fragen nirgends enthalten; Antworten werden nie übertragen.
9. Formulare: mit Platzhalter-Endpoint freundlicher Hinweis statt totem Request;
   mit Endpoint saubere Erfolgs-/Fehlerzustände + No-JS-Fallback; Honeypot aktiv.
10. Responsive 360–1440 px; Kontrast AA; Selbstcheck + Formulare komplett per
    Tastatur bedienbar; sinnvolle `aria`-Attribute.
11. Jede Seite endet mit Selbstcheck- oder Warteliste-CTA.
12. Lokale Commits je Etappe auf `website-v1`; **nichts gepusht/deployt**; nichts
    außerhalb `reflexjourney-app-site/` geändert.

---

## 13. Abschluss-Ausgabe an den Founder

Am Ende ausgeben (und in `FOUNDER_TODO.md` ablegen):

1. **Alle `[FOUNDER: …]`-Platzhalter** mit Datei/Fundort.
2. **Die gewählten Selbstcheck-Fragen** (je: Fragetext, Modul, Reflex-Zuordnung) zur
   Freigabe.
3. **2 Claim-Alternativen** für den Hero (zusätzlich zum bestehenden Claim).
4. **Offene Punkte & Empfehlungen** aus deiner Arbeit.

Dazu gehört als Startliste in `FOUNDER_TODO.md` (vom Founder zu erledigen, nicht
deine Aufgabe): Warteliste-Endpoint anlegen (Formspree oder Supabase) + Double-Opt-in ·
finale Rechtstexte nach Anwaltsfreigabe einsetzen, `noindex` entfernen ·
Selbstcheck-Fragenauswahl freigeben · echte Screenshots/Fotos + OG-Bild + finales
Favicon · Domain reflexjourney.de im Vercel-Projekt verbinden, reflexjourney.app als
Redirect · Support-/Kontakt-E-Mail festlegen und eintragen · Altersempfehlung,
Preis-Kommunikation, Launch-Datum · Trainer-Zertifizierungs-/Kooperationsdetails ·
verfügbare Reflex-Pakete zum Launch bestätigen (Zielgruppenseiten ggf. nachschärfen) ·
nach Launch: Store-Badge einsetzen, „Bald im App Store" ablösen · optional später:
cookiefreies Analytics (z. B. Plausible, EU) — bewusst nicht in v1 · später:
Erwachsenen-Selbstcheck (`erwachsene.json`) freigeben.
