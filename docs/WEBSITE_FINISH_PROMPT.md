# WEBSITE_FINISH_PROMPT — reflexjourney.de von Prototyp zu Go-live

> **Verwendung:** Diesen gesamten Prompt einer Claude-Session geben, die im Monorepo
> `corejourney/` arbeitet (äußeres Repo!). Er führt die fertig gebaute Prototyp-Website
> bis zum Live-Gang. Stand: 2026-07-23.

---

## 0. Auftrag

Die Marketing-Website liegt fertig gebaut unter **`reflexjourney-app-site/`** auf dem
**äußeren** Git-Repo, Branch **`website-v1`** (Commits `e57f752` Build + `6744782`
Prototyp-Politur). Sie ist als Prototyp komplett vorzeigbar: 17 Seiten, Selbstcheck,
Warteliste (Graceful-Modus ohne Endpoint), Legal-Seiten als gekennzeichnete
Entwurfsfassungen.

Deine Aufgabe: die verbleibenden Schritte bis zum Go-live abarbeiten — **streng in der
Reihenfolge und mit den Gates aus Abschnitt 2**. Single Source of Truth für Offenes:
**`reflexjourney-app-site/FOUNDER_TODO.md`** (zuerst lesen!).

## 1. Kontext & Regeln, die weiterhin gelten

- **Repo-Struktur:** `corejourney/` ist das äußere Repo (Website, admin-web, specs);
  `corejourney/app/` ist ein **eigenes, verschachteltes Repo** (Flutter-App) — dort
  arbeitest du NICHT. `app/CLAUDE.md` gilt sinngemäß: Commit-Disziplin, keine
  erfundene Evidenz, Redaktion (keine Secrets/PII in den Chat).
- **HWG-Sprachregeln** (keine Heil-/Therapieversprechen, ADHS/LRS nie, Diagnosen nur
  „begleitend + in Absprache", Pflicht-Disclaimer) — bei JEDER Copy-Änderung.
- **Technik-Erhalt:** `public/auth/…` + `public/.well-known/…` und die `headers` in
  `vercel.json` bleiben byte-identisch erreichbar; nach jedem Build `diff -r auth
  dist/auth` und `diff -r .well-known dist/.well-known`.
- **Keine externen Requests** (Fonts self-hosted, kein Analytics, kein Cookie-Banner).
- **KEINE BILDER GENERIEREN.** Wenn ein Bild fehlt (OG-Bild, Screenshots, Favicon):
  beim Founder **anfordern** (Format + Maße + Zweck nennen) und den Punkt offen
  lassen, bis er liefert. Niemals selbst rastern, zeichnen oder KI-generieren.
- **Nichts erfinden**: fehlende Fakten → Founder fragen; Platzhalter-Konvention
  `[FOUNDER: …]` + Eintrag in `FOUNDER_TODO.md`.

## 2. Gates — nur mit ausdrücklichem Founder-Go im Chat, jedes Mal

- **`git push`** (kann Deploys triggern) — niemals ohne Go.
- **Vercel-/Domain-Änderungen** (Projekt-Settings, Domains, Env) — Founder klickt
  selbst (ggf. mit Claude in Chrome); du lieferst exakte Anleitungen.
- **Alles an der Live-Supabase** (falls Warteliste via Supabase gebaut wird):
  Migrationen/Functions nur mit Go, SQL vorher wörtlich zeigen.
- Accounts anlegen (Formspree, Postfach) macht der Founder immer selbst.

Wenn ein Gate dich blockiert: nächsten Punkt weiterbearbeiten, alle blockierten
Punkte am Ende gesammelt vorlegen.

## 3. Aufgaben in Reihenfolge

### F1 — Warteliste-Endpoint scharf schalten

1. Founder-Entscheidung einholen: **Formspree** (schnell, 5 Min) oder **Supabase**
   (eigene Infrastruktur, mehr Kontrolle)?
2. **Formspree-Weg:** Founder legt Formular an und nennt dir die Endpoint-URL →
   in `src/config.ts` bei `WAITLIST_ENDPOINT` eintragen. Prüfe lokal beide Modi:
   Platzhalter → „wird in Kürze freigeschaltet"; echte URL → erfolgreicher POST,
   Erfolgs-/Fehlerzustand, No-JS-Fallback (natives POST), Honeypot.
3. **Supabase-Weg (Alternative):** Edge Function + Tabelle im **App-Repo**
   (`app/supabase/`) — das ist Live-Infrastruktur mit echten Nutzerdaten: exakten
   Plan (SQL + Function-Code) vorlegen, Founder-Go abwarten, App-Repo-Konventionen
   beachten (idempotente Migration, `YYYYMMDDNN_name.sql`).
4. **Double-Opt-in:** klären, wie der Bestätigungslink versendet wird (Formspree-
   Feature bzw. E-Mail-Tool). Solange DOI nicht steht, den Satz „Die Anmeldung wird
   per Bestätigungs-E-Mail verifiziert (Double-Opt-in)." in
   `src/pages/datenschutz.astro` an die Realität anpassen.

### F2 — Kanzlei-Texte einsetzen (sobald der Anwalt liefert)

In `src/pages/impressum.astro` + `src/pages/datenschutz.astro`:
Kanzlei-Fassung 1:1 übernehmen, „Entwurfsfassung"-Banner und alle
„[wird ergänzt]"-Stellen entfernen (Anschrift, USt-Angabe, Aufsichtsbehörde),
Stand-Datum setzen, **`noindex={true}` von beiden Seiten entfernen**. Danach
Compliance- und Link-Check.

### F3 — Kanzlei-Nachmeldung Warteliste (Founder erinnern!)

Das Anwaltspaket vom 19.07. kennt die Warteliste nicht. Der Founder muss der
Kanzlei nachmelden: Warteliste-Formular (E-Mail + optionale Interessenangabe,
Einwilligung Art. 6 Abs. 1 lit. a, Double-Opt-in, Dienstleister je nach F1-Wahl
Formspree oder Supabase; ggf. AVV). Du formulierst ihm die kurze Nachmeldungs-Mail
als Entwurf vor.

### F4 — Assets anfordern und einbauen (NICHT generieren)

Beim Founder anfordern, dann einbauen:
1. **OG-Bild**: PNG, exakt 1200×630 → als `public/og/default.png` ablegen; in
   `src/components/Seo.astro` die `ogImage`-Zeile von `default.svg` auf
   `default.png` umstellen und den `[FOUNDER…]`-HTML-Kommentar entfernen.
2. **App-Screenshots** (Slots: Startseiten-Hero, 4 Feature-Blöcke `/app`,
   optional Zielgruppenseiten): Einbau ersetzt die stilisierten `PhoneMockup`s —
   Struktur so lassen, dass die Komponente ein `img`-Slot bekommt; Maße/Format mit
   Founder klären (Portrait, ~2× Retina, < 150 KB pro Bild, WebP oder PNG).
3. **Finales Favicon** (ersetzt das „RJ"-Monogramm-SVG).
Fehlt etwas: Punkt bleibt offen in `FOUNDER_TODO.md`, Go-live nicht daran scheitern
lassen (nur OG/Favicon sind nice-to-have; Screenshots können nach Launch kommen).

### F5 — Konsistenz-Checks Inhalte

1. Support-Postfach `support@reflexjourney.app` muss real existieren (Founder, R5) —
   vorher nicht live gehen (steht in Impressum/Datenschutz!).
2. Prototyp-Annahmen aus `FOUNDER_TODO.md` Abschnitt 1 vom Founder bestätigen
   lassen (Preise, Launch-Formulierung, Alters-Antwort, Trainer-FAQ) und ggf.
   anpassen.
3. Selbstcheck-Fragenfreigabe (Tabelle in `FOUNDER_TODO.md`): bei Streichungen
   `src/data/selfcheck/kinder.json` anpassen und alle Ergebnis-Pfade
   (viele/wenige/keine Hinweise) erneut durchspielen.

### F6 — Finale lokale Abnahme (vor jedem Deploy komplett)

1. `npm run build` + `npx astro check` → 0 Fehler
2. Erhalt-Diffs `auth` + `.well-known` → identisch
3. Compliance-Grep über `src/` und `dist/`:
   `heilt |Heilung|kuriert|garantiert|Wunder|ADHS|LRS` → 0 außerhalb
   Disclaimer-Negation
4. Kein sichtbares `[FOUNDER` im gerenderten Output
5. Externe Hosts in `dist/` (ohne `auth/`): nur Warteliste-Endpoint + schema.org
6. Responsive 360/768/1280, Selbstcheck + Formular per Tastatur, ein `<h1>`/Seite
7. Legal-Seiten: `noindex` nur solange Entwurf; danach entfernt
8. Lokale Commits je Etappe auf `website-v1`; `git diff --cached --name-status`
   vor jedem Commit — nur geplante Dateien (nichts aus `admin-web/`!)

### F7 — Deploy (nur mit Founder-Go, Schritt für Schritt)

1. Founder-Go für `git push origin website-v1` einholen; klären, ob Vercel am
   äußeren Repo hängt (Auto-Deploy-Risiko!) — im Zweifel zuerst nur Preview.
2. Vercel-Projekt (verknüpft via `.vercel/`): Build-Settings prüfen/prüfen lassen
   (Framework Astro, Output `dist`, `vercel.json`-Header aktiv) — Founder klickt,
   du leitest an.
3. Domains: `reflexjourney.de` als Primärdomain, `reflexjourney.app` → Redirect
   (außer `/auth/*` und `/.well-known/*` — **diese Pfade müssen auf
   reflexjourney.app direkt erreichbar bleiben**, die App verlinkt darauf!
   Redirect-Regeln entsprechend ausnehmen und testen).
4. Merge nach `main` erst, wenn Live-Verifikation (F8) grün ist.

### F8 — Post-Deploy-Verifikation (kritisch — App-Funktionen hängen daran)

1. `https://reflexjourney.app/.well-known/apple-app-site-association` →
   HTTP 200, `Content-Type: application/json`, Inhalt byte-identisch zu vorher
   (curl-Vergleich); dasselbe für `assetlinks.json`
2. Passwort-Reset-Flow einmal echt durchspielen (Reset-Mail → Link öffnet
   `/auth/reset-password` bzw. die App) — Founder testet am iPhone
3. Alle 17 Seiten live aufrufen (Statuscodes), `sitemap-index.xml` + `robots.txt`
   erreichbar, Canonicals auf `reflexjourney.de`
4. Warteliste: eine echte Test-Anmeldung inkl. Bestätigungsmail
5. Ergebnis als kurzen Verifikationsbericht an den Founder

### F9 — Nach App-Launch (separat, nicht Teil des Go-live)

Store-Badge + Link einsetzen („Bald im App Store" ablösen), Preis-/Alters-FAQ gegen
die finalen Store-Angaben prüfen, Datenschutz-URL in App Store Connect eintragen,
optional Plausible (EU) erwägen, Erwachsenen-Selbstcheck (`erwachsene.json`)
freischalten, sobald Fragen freigegeben sind.

## 4. Arbeitsweise

Zu Beginn: `FOUNDER_TODO.md` lesen, `git -C <monorepo> branch --show-current`
(= `website-v1`) und `git status` prüfen (vorbestehende `admin-web`-Änderungen
liegen lassen!). Dann F1–F8 abarbeiten; was auf den Founder wartet, sammelst du und
legst es ihm als kompakte Entscheidungs-/Erledigungsliste vor. Jede Etappe: lokaler
Commit mit sauberem Staging. Am Ende: `FOUNDER_TODO.md` aktualisieren und den
erreichten Stand in 5 Sätzen zusammenfassen.
