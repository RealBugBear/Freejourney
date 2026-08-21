# Einladungen und Wirkungs-Visual — Design

**Datum:** 2026-08-21
**Status:** Fassung 2 — Konsistenzkorrekturen aus dem Founder-Review eingearbeitet, zur finalen Abnahme
**Scope:** Nutzer-zu-Nutzer-Einladung (MVP), Wirkungs-Visual, Attribution, Messung
**Nicht im Scope:** Belohnung für Einladende, Trainer-Einladung, Haushalts-/Partnerzugriff, Push/Badge

Alle Annahmen sind als `[ANNAHME RJ-INV-n]` markiert und in Abschnitt 15 gesammelt.

---

## 1. Ziel, Nicht-Ziele, Erfolgskriterien

### Ziel

Nutzer können andere Menschen einladen, und die App gibt ihnen einen ruhigen,
glaubwürdigen Grund, es zu tun. Der Eingeladene bekommt sofort etwas Echtes in
die Hand — den kostenlosen Selbstcheck im Browser, ohne Konto und ohne
Installation. Der Einladende sieht aggregiert, wie viele Menschen über ihn
gestartet sind, und erfährt nie, wer.

### Nicht-Ziele

- Keine Belohnung für den Einladenden, auch nicht später (Founder-Entscheidung 2026-08-21).
- Keine Prämien, keine Punkte, keine Ranglisten, kein Vergleich zwischen Nutzern.
- Keine Kontaktbuch-Anbindung, kein Adressimport, keine Empfehlungsvorschläge.
- Keine Tracking-SDKs. Die Attribution bleibt erststellig.
- Kein Push und kein Badge — der Stand wird nur beim Öffnen der Einladungsseite sichtbar.
- Keine Trainer-Einladung im MVP (nachrüstbar, siehe Abschnitt 14).

### Erfolgskriterien

Der Trichter hat vier Stufen (Definitionen in Abschnitt 10). Die folgenden
Zielwerte sind **Hypothesen für die ersten 90 Tage nach Aktivierung**, keine
Zusagen — sie dienen dazu, nach dem ersten Quartal zu entscheiden, ob das
Feature bleibt, geändert oder zurückgebaut wird:

| Kennzahl | Zielwert (Hypothese) |
|---|---|
| Aktive Nutzer, die mindestens einmal den Teilen-Knopf drücken | ≥ 15 % |
| Einlösungen je 100 Zielseitenaufrufe | ≥ 5 |
| Aktivierungen je 100 Einlösungen | ≥ 50 |

Abbruchkriterium: Liegt die Aktivierungsquote nach 90 Tagen unter 20 %, taugt
der Erfolgsmoment nicht und wird neu bewertet, statt das Feature auszubauen.

---

## 2. Produktentscheidungen (getroffen im Brainstorming 2026-08-21)

| # | Entscheidung |
|---|---|
| D1 | Zweistufig: Stufe 1 ohne jede Belohnung, Stufe 2 (Geschenk für Eingeladene) getrennt und später. |
| D2 | Empfängernutzen ist der bestehende Web-Selbstcheck, nicht ein Rabatt. |
| D3 | Erfolg = erstes abgeschlossenes Training des Eingeladenen. Nicht Installation, nicht Registrierung. |
| D4 | Sichtbare Motivation ist ein wachsender Baum, aggregiert, ohne Namen und ohne Zeitangaben. |
| D5 | Attribution über Link mit Code im Query-Parameter; Code-Eingabe ist der Fallback, nie automatisch, immer mit Bestätigung. |
| D6 | Keine Belohnung für Einladende — weder in Stufe 1 noch in Stufe 2. |
| D7 | Kein Push, kein Badge. |
| D8 | Trainer- und Haushalts-Einladung sind eigene, spätere Vorhaben. |
| D9 | Zum Start läuft nur Impuls I1 (Reflexprofil-Ergebnis). I2 wird gebaut, aber deaktiviert ausgeliefert. |
| D10 | Der dauerhafte Einstieg steht nur in den Einstellungen, nicht zusätzlich im Profil. |
| D11 | Im MVP wird **keine** Stufe-2-Infrastruktur gebaut: keine Kampagnenzeile, keine Programm-Abfrage, keine Abfrage der Website. Stufe 2 ist ausschließlich dokumentiert. |
| D12 | Selbstcheck-Abschlüsse werden im MVP nirgends gemessen. |

---

## 3. Nutzerflüsse

### 3.1 Einladender

1. Einstieg über den dauerhaften Eintrag in den Einstellungen oder über den
   Impuls (Abschnitt 3.5).
2. Screen `/einladen` ruft beim Öffnen `get_my_invite_overview()`. Die RPC legt
   den persönlichen Code beim ersten Aufruf an und liefert ihn zusammen mit der
   Anzahl aktivierter Einladungen zurück.
3. Der Screen zeigt von oben nach unten: Baumkarte, ein erklärender Satz,
   Hauptknopf „Einladung teilen“, darunter klein der Code mit Kopieren-Knopf,
   ganz unten die Transparenzzeile.
4. „Einladung teilen“ ruft `log_invite_share_action_tapped()` und öffnet danach
   das native Share-Menü mit dem vorformulierten, editierbaren Text plus Link
   `https://reflexjourney.app/einladung?c=<CODE>`. Gemessen wird damit der
   Knopfdruck, nicht das Menü und erst recht nicht das Teilen — die Benennung
   sagt das überall genauso.
5. Ist der Stand höher als der zuletzt lokal gemerkte, wächst der neue Zweig
   einmalig sichtbar ein (600 ms). Danach bleibt das Bild ruhig.

### 3.2 Eingeladener, Hauptweg (App nicht installiert)

1. Link antippen → Browser → `https://reflexjourney.app/einladung?c=<CODE>`.
2. Die Zielseite erklärt in zwei Sätzen, dass jemand eingeladen hat, und startet
   direkt den Selbstcheck. Der Code wird angezeigt und in `sessionStorage`
   gehalten. Ein Zählschlag geht an `log_invite_landing_view(<CODE>)`.
3. Nach dem Ergebnis erscheint „Weiter mit der App“: Store-Buttons und der Code
   groß, kopierbar.
4. Installation, Registrierung, Onboarding. Am Ende des Onboardings fragt ein
   Schritt „Hat dich jemand eingeladen?“ mit Einfüge-Knopf.
5. Nach Eingabe erscheint die Bestätigung (Abschnitt 3.4). Erst „Einladung
   annehmen“ ruft `redeem_invite_code`.

### 3.3 Eingeladener, App bereits installiert

Der Universal Link öffnet die App auf der Route `/einladung`. Der Code wird aus
dem Query-Parameter gelesen und im dateibasierten Zwischenspeicher abgelegt.

- Angemeldet und berechtigt → Bestätigung, dann Einlösung.
- Angemeldet, aber nicht berechtigt → die zutreffende Erklärung aus Abschnitt 8.
- Nicht angemeldet → Code bleibt gespeichert, Registrierung läuft normal, danach
  erscheint die Bestätigung. **Nie automatisch einlösen.**

### 3.4 Bestätigungsschritt (identisch an allen drei Einstiegen)

Zeigt Code, Nutzen und wörtlich:

> Die Person, die dich eingeladen hat, sieht später nur, dass eine weitere Person
> über ihre Einladung mit dem Training begonnen hat – niemals deinen Namen.

Knöpfe: „Einladung annehmen“ und „Nicht jetzt“. „Nicht jetzt“ verwirft nichts —
der Weg über die Einstellungen bleibt 30 Tage offen.

### 3.5 Impulse

Als ruhige Karte im Fluss, **nie als Dialog**:

| Impuls | Ort | Datei | Zustand |
|---|---|---|---|
| I1 | Unter dem Reflexprofil-Ergebnis, beim ersten Anzeigen | `lib/features/assessment/presentation/screens/reflex_profile_result_screen.dart` | zum Start aktiv |
| I2 | Auf dem Golden-Day-Screen nach dem ersten abgeschlossenen Paket | `lib/features/golden_day/presentation/screens/golden_day_screen.dart` | gebaut, aber deaktiviert ausgeliefert (D9) |

I2 wird vollständig gebaut und getestet, aber hinter einer eigenen Konstante
deaktiviert ausgeliefert. So lässt er sich ohne neuen Code zuschalten, sobald
I1 genug Zahlen geliefert hat.

Frequenzregeln, alle lokal ausgewertet und in reiner Logik gekapselt:

- höchstens ein Impuls in 30 Tagen
- höchstens drei im ersten Jahr
- nach zweimaligem Anzeigen ohne Antippen dauerhaft still
- unterdrückt, wenn in den letzten 24 Stunden ein Mood-Check-in mit `mood <= 2`
  liegt (Skala 1–5, siehe `lib/core/database/tables/mood_checkins_table.dart:13`)
- nie während einer laufenden Trainingssitzung

Der dauerhafte Eintrag in den Einstellungen unterliegt keiner Regel.

### 3.6 Aktivierung

Sobald für den Eingeladenen die erste Zeile mit `is_completed = true` in
`public.training_sessions` ankommt, hebt ein Trigger seine `referrals`-Zeile von
`pending` auf `activated`. Weil die Synchronisation offline-first und
wiederholend ist, muss der Trigger idempotent sein — das ist er, weil er nur
Zeilen mit `status = 'pending'` anfasst.

Der Einladende erfährt davon nichts, bis er die Einladungsseite das nächste Mal
öffnet.

---

## 4. Zustandsmodell

```
                 redeem_invite_code()            erste abgeschlossene
   (kein Eintrag) ──────────────────► pending ──────────────────────► activated
                                         │      Trainingssitzung
                                         │
                                         └──── manuell durch Admin ──► blocked
```

- `pending → activated` ist der einzige automatische Übergang.
- `blocked` ist ausschließlich manuell und **ausschließlich aus `pending`
  erreichbar**. Eine bereits aktivierte Einladung wird nie rückwirkend
  blockiert — die Datenbank verhindert das von selbst, weil
  `referrals_activation_shape_check` bei `status = 'blocked'` ein leeres
  `activated_at` verlangt und Geschichte damit gelöscht werden müsste.
  Bei Missbrauchsverdacht ist die einzige Maßnahme
  `referral_codes.is_active = false`.
- Rückwege gibt es nicht. Eine gelöschte Zeile ist kein Zustand, sondern ein Fehler.
- Löscht der Eingeladene sein Konto, bleibt die Zeile mit `invitee_user_id IS NULL`
  im bisherigen Zustand stehen (siehe Abschnitt 5.3).

---

## 5. Datenmodell, RLS, Datenschutz

### 5.1 Tabellen

Migration: `supabase/migrations/2026082105_referral_program.sql`

```sql
CREATE TABLE IF NOT EXISTS public.referral_codes (
  user_id uuid PRIMARY KEY REFERENCES public.profiles(id) ON DELETE CASCADE,
  code text NOT NULL UNIQUE
    CONSTRAINT referral_codes_code_shape_check
    CHECK (code ~ '^[ABCDEFGHJKMNPQRSTUVWXYZ23456789]{8}$'),
  is_active boolean NOT NULL DEFAULT true,
  share_action_tapped_count integer NOT NULL DEFAULT 0
    CONSTRAINT referral_codes_share_count_check CHECK (share_action_tapped_count >= 0),
  landing_view_count integer NOT NULL DEFAULT 0
    CONSTRAINT referral_codes_landing_count_check CHECK (landing_view_count >= 0),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.referrals (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  inviter_user_id uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  invitee_user_id uuid UNIQUE REFERENCES public.profiles(id) ON DELETE SET NULL,
  code text NOT NULL,
  status text NOT NULL DEFAULT 'pending'
    CONSTRAINT referrals_status_check CHECK (status IN ('pending', 'activated', 'blocked')),
  created_at timestamptz NOT NULL DEFAULT now(),
  activated_at timestamptz,
  blocked_at timestamptz,
  blocked_reason text,
  CONSTRAINT referrals_no_self_check
    CHECK (invitee_user_id IS NULL OR invitee_user_id <> inviter_user_id),
  CONSTRAINT referrals_activation_shape_check
    CHECK ((status = 'activated') = (activated_at IS NOT NULL)),
  CONSTRAINT referrals_block_shape_check
    CHECK ((status = 'blocked') = (blocked_at IS NOT NULL))
);

CREATE INDEX IF NOT EXISTS referrals_inviter_status_idx
  ON public.referrals (inviter_user_id, status);
```

`updated_at` auf `referral_codes` wird von den schreibenden Funktionen gesetzt;
es gibt bewusst keinen eigenen Trigger dafür, weil nur drei Funktionen schreiben.

Bewusst **nicht** enthalten: `invite_kind`. Trainer-Einladungen sind nicht im
MVP; die Spalte kommt später als triviale Migration mit Default `'peer'`.

`referrals_activation_shape_check` erzwingt nebenbei die Regel aus Abschnitt 4:
Ein Wechsel von `activated` nach `blocked` ist nur möglich, wenn `activated_at`
geleert wird — und genau das ist verboten. Aktivierte Einladungen bleiben also
unveränderlich, ohne dass es dafür einen zusätzlichen Trigger braucht.

Die Eindeutigkeit auf `invitee_user_id` ist der eigentliche Missbrauchsschutz:
ein Konto kann nur ein einziges Mal geworben werden, und die Datenbank
entscheidet das, nicht der Client. `NULL` ist in Postgres mehrfach erlaubt, was
für gelöschte Konten genau richtig ist.

### 5.2 Zugriff

Beide Tabellen bekommen `ENABLE ROW LEVEL SECURITY` **und keine einzige Policy**,
dazu `REVOKE ALL ... FROM anon, authenticated`. Es gibt keinen direkten
Tabellenzugriff — jeder Weg führt über `SECURITY DEFINER`-Funktionen. Das ist
dieselbe Haltung wie bei `benefit_codes` in `2026071901_multi_grant_entitlements.sql`
und beantwortet die Datenschutzfrage strukturell: der Einladende kann
`referrals` gar nicht lesen, egal was der Client versucht.

Funktionen (alle `SECURITY DEFINER`, `SET search_path = public`, mit
`REVOKE ALL ... FROM PUBLIC` und gezieltem `GRANT EXECUTE`):

| Funktion | Aufrufer | Rückgabe |
|---|---|---|
| `_referral_code()` | intern | 8-stelliger Code, Alphabet und Schleife wie `_trainer_activation_code()` in `20260428_trainer_applications.sql:271` |
| `get_my_invite_overview()` | `authenticated` | `{code, activated_count}` — legt den Code beim ersten Aufruf an. `activated_count` zählt ausschließlich Zeilen mit `status = 'activated'`; `pending` und `blocked` erscheinen nirgends |
| `redeem_invite_code(p_code text)` | `authenticated` | `{result}` — ein einziges Feld |
| `log_invite_share_action_tapped()` | `authenticated` | `void` |
| `log_invite_landing_view(p_code text)` | `anon`, `authenticated` | `void` — zählt nur, wenn der Code existiert **und** `is_active` |
| `activate_referral_on_first_completed_session()` | Trigger | — |

Sechs Funktionen, keine mehr. Insbesondere gibt es **keine** Abfrage eines
Belohnungsprogramms — im MVP existiert kein Programm, das man abfragen könnte
(D11).

`redeem_invite_code` gibt einen maschinenlesbaren Wert im Feld `result` zurück
statt `RAISE EXCEPTION` mit deutschem Text — anders als ältere RPCs im Projekt,
weil die App zweisprachig ist und die Meldung lokalisiert werden muss.
Verbindlicher Vertrag: genau ein Schlüssel `result`. Mögliche Werte:
`accepted`, `unknown_code`, `code_inactive`, `own_code`, `already_referred`,
`account_too_old`. Es gibt kein paralleles `status`/`reason`-Feld.

Prüfungen in `redeem_invite_code`, in dieser Reihenfolge:

1. Code existiert und entspricht der Form → sonst `unknown_code`
2. `referral_codes.is_active` → sonst `code_inactive`
3. Code gehört nicht dem Aufrufer → sonst `own_code`
4. Aufrufer hat noch keine `referrals`-Zeile → sonst `already_referred`
5. `profiles.created_at > now() - interval '30 days'` → sonst `account_too_old`
6. Einlösen: Zeile anlegen. Existiert für den Aufrufer bereits mindestens eine
   `training_sessions`-Zeile mit `is_completed = true`, wird die Referral-Zeile
   **direkt** als `activated` mit `activated_at = now()` eingefügt — sonst als
   `pending`. So bleibt der Erfolgsmoment erhalten, wenn das erste Training vor
   der Code-Eingabe lag (der Trigger auf `training_sessions` wäre dann schon
   gelaufen und würde eine spätere `pending`-Zeile nicht mehr sehen).
   Redeem und Trigger serialisieren über dasselbe
   `pg_advisory_xact_lock(87201405, hashtext(invitee_user_id))`, damit ein
   gleichzeitiger Session-Sync und die Einlösung einander nicht verpassen.

Trigger:

```sql
CREATE TRIGGER activate_referral_after_completed_session
  AFTER INSERT OR UPDATE OF is_completed ON public.training_sessions
  FOR EACH ROW WHEN (NEW.is_completed)
  EXECUTE FUNCTION public.activate_referral_on_first_completed_session();
```

Verifiziert: `public.training_sessions` besitzt `user_id` und `is_completed`
(`supabase/migrations/20260412_core_schema_baseline.sql:189-198`).

### 5.3 Datenschutz

- Der Einladende bekommt ausschließlich `activated_count` — keine Namen, keine
  Zeitpunkte, keine offenen Einlösungen. Alles andere ist serverseitig
  unerreichbar, nicht nur ausgeblendet.
- **Ehrliche Grenze:** Wer genau eine Person eingeladen hat, erfährt aus dem
  Zähler dennoch, dass diese Person mit dem Training begonnen hat. Das lässt
  sich mit keinem Zähler wegkonstruieren. Deshalb steht es im
  Bestätigungstext, den der Eingeladene vor dem Einlösen liest, und in der
  Datenschutzerklärung — nicht in einer Beschwichtigung.
- `referrals` enthält bis zur Kontolöschung eine `invitee_user_id`. Das ist ein
  Personenbezug. Er existiert für genau drei Zwecke: Einlösung, Missbrauchsschutz,
  Aktivierung. Er verlässt die Datenbank nie in Richtung des Einladenden.
- Share- und Zielseitenzähler enthalten **keine Empfängeridentität** — sie sind
  reine Ganzzahlen an `referral_codes`, ohne Zeitreihe pro Person.
- Kein Kontaktbuchzugriff, keine Empfehlungsvorschläge, keine Cookies auf der
  Zielseite.
- **Löschung:** Löscht der Eingeladene sein Konto, setzt `ON DELETE SET NULL` die
  `invitee_user_id` auf `NULL`. Damit wird die direkte Zuordnung zum eingeladenen
  Konto entfernt; die aggregierte Zuordnung zum Einladenden und der
  Aktivierungsstatus bleiben bestehen. Das ist ausdrücklich **keine** vollständige
  Anonymisierung: bei kleinen Zahlen kann die verbleibende Zeile weiterhin
  Rückschlüsse erlauben. Löscht der Einladende sein Konto, kaskadieren
  `referral_codes` und seine `referrals`-Zeilen; der Code wird damit ungültig
  und Einlösungsversuche laufen in `unknown_code`.
- Die Datenschutzerklärung in App und Website braucht einen neuen Absatz zur
  Verarbeitung „Einladungsbeziehung“ (Abschnitt 14).

### 5.4 Missbrauch

- Ein Konto kann nur einmal geworben werden (Datenbank-Eindeutigkeit).
- Nur in den ersten 30 Tagen eines Kontos.
- Selbst-Einlösung ist per Constraint und per Prüfung ausgeschlossen.
- Der Erfolgsmoment ist ein abgeschlossenes Training — Massenanlage von Konten
  lohnt sich nicht, weil jedes davon ein Training durchlaufen müsste.
- Erraten eines Codes ist bei 31^8 ≈ 8,5 · 10^11 Möglichkeiten unattraktiv und
  wäre ohnehin folgenlos: es ordnet den Ratenden einem fremden Baum zu, mehr nicht.
  `random()` ist nicht kryptografisch sicher; für einen öffentlichen Code ist das
  vertretbar und entspricht dem bestehenden Trainer-Code. `[ANNAHME RJ-INV-5]`
- Beobachtung statt Automatik: eine Admin-Sicht listet Einladende mit mehr als
  10 Aktivierungen in 30 Tagen. Es passiert automatisch **nichts**; die einzige
  Maßnahme ist manuell `referral_codes.is_active = false`.
- `log_invite_landing_view` ist für `anon` ausführbar und damit von außen
  aufblasbar. Der Schaden ist eine verfälschte Trichterzahl, kein Datenabfluss.
  Bewusst akzeptiert. `[ANNAHME RJ-INV-6]`

---

## 6. Änderungen nach Systemen

### 6.1 Supabase

- neue Migration `2026082105_referral_program.sql` (Tabellen, Funktionen, Trigger, Grants)
- neuer Test `supabase/tests/2026082105_referral_program_test.sql`
- Admin-Sicht für den Trichter, anschlussfähig an `2026060105_admin_metrics_v1.sql`
- **kein** Eintrag in `entitlement_grants` — im MVP wird kein Anspruch erzeugt

### 6.2 Flutter-App

Neues Feature-Verzeichnis `lib/features/invite/` nach dem im Projekt üblichen
Schnitt (`domain/`, `data/`, `presentation/`). Berührte bestehende Dateien:

| Datei | Änderung |
|---|---|
| `lib/core/navigation/app_router.dart` | `Routes.invite = '/einladen'`, `Routes.inviteAccept = '/einladung'`, beide Routen registrieren, UI-Gate analog `paywallGateRedirect` |
| `lib/app.dart` | Deep-Link-Handler um die Pfade `/einladung` **und** `/en/einladung` erweitern (heute nur `/auth/reset-password`, siehe `lib/app.dart:31`) — die Website hat beide Sprachvarianten, beide müssen in der App landen |
| `lib/config/launch_flags.dart` | `kInviteEnabled` — gated **nur** die App-Oberfläche |
| `lib/l10n/app_de.arb`, `lib/l10n/app_en.arb` | neue Schlüssel aus Abschnitt 7 |
| `lib/features/settings/presentation/screens/settings_screen.dart` | einziger dauerhafter Eintrag, Muster `_SectionHeader` + `ListTile` (D10) |
| `lib/features/assessment/presentation/screens/reflex_profile_result_screen.dart` | Impuls I1 |
| `lib/features/golden_day/presentation/screens/golden_day_screen.dart` | Impuls I2, deaktiviert ausgeliefert |

Der Doc-Kommentar von `kInviteEnabled` listet nach der Hausregel jede gegatete
Fläche und die Voraussetzungen zur Reaktivierung — wie bei `kCommunityEnabled`
und `kPaywallEnabled`.

**Achtung Localization:** `l10n.yaml` weist `app_de.arb` als Vorlage aus,
`CLAUDE.md` §4 nennt `app_en.arb`. Die Konfigurationsdatei ist die Tatsache.
Für die Umsetzung ist das folgenlos, weil ohnehin **beide** Dateien gepflegt und
danach `flutter gen-l10n` laufen muss; die Abweichung gehört aber gemeldet und
in einer der beiden Quellen korrigiert.

Neue Datei `lib/core/storage/pending_invite_store.dart`: kleiner
dateibasierter Speicher in `getApplicationSupportDirectory()`, gebaut nach dem
Vorbild von `lib/core/storage/file_local_storage.dart`. **Nicht** `SharedPreferences` —
deren Pigeon-Kanal fällt auf iOS 26 aus, weshalb im Bootstrap ein
In-Memory-Fallback liegt; ein dort abgelegter Code überlebt einen Neustart
mitten in der Registrierung nicht. Derselbe Speicher hält den zuletzt gesehenen
Baumstand und den Impuls-Zustand.

### 6.3 Website (`reflexjourney-app-site`, eigenes Repo)

- `src/pages/einladung.astro` (DE) und `src/pages/en/einladung.astro` (EN), beide
  rendern `src/content-pages/EinladungPage.astro` — dasselbe Muster wie
  `selbstcheck.astro` → `SelbstcheckPage.astro`
- Texte in `src/i18n/`
- `SelfCheck.astro` unverändert wiederverwenden
- Code aus `?c=` lesen, Form clientseitig prüfen, in `sessionStorage` halten
- `robots`-Meta auf `noindex`, Ausschluss aus der Sitemap analog Impressum
- `public/.well-known/apple-app-site-association`: `paths` um `/einladung`,
  `/einladung/*`, `/en/einladung`, `/en/einladung/*` erweitern — für alle drei
  AppIDs (`de.reflexjourney.app`, `.staging`, `.dev`)
- Android: neuer `intent-filter` mit `pathPrefix="/einladung"` in
  `android/app/src/main/AndroidManifest.xml`; `assetlinks.json` braucht keine
  Änderung, weil es ohnehin alle URLs delegiert

**Der Link muss auf `reflexjourney.app` zeigen**, nicht auf `reflexjourney.de` —
nur diese Domain steht in `Runner.entitlements` unter `applinks:`. Laut
`FOUNDER_TODO.md` (F7) ist `reflexjourney.app` ein Vercel-Alias desselben
Projekts, die AASA wird dort also mit ausgeliefert. Vor der Freischaltung live
prüfen. `[ANNAHME RJ-INV-1]`

---

## 7. UI-Texte

### 7.1 App (ARB-Schlüssel, Vorlage ist Deutsch)

| Schlüssel | DE | EN |
|---|---|---|
| `inviteTitle` | Einladen | Invite |
| `inviteTreeHeadlineZero` | Verschenke einen guten Start | Give someone a good start |
| `inviteTreeHeadline` (Plural) | `{count, plural, =1{1 Mensch ist über deine Einladung gestartet.} other{{count} Menschen sind über deine Einladung gestartet.}}` | `{count, plural, =1{1 person has started through your invitation.} other{{count} people have started through your invitation.}}` |
| `inviteTreeEmptyHint` | Wenn jemand über deine Einladung sein erstes Training abschließt, wächst hier ein Zweig. | When someone completes their first training through your invitation, a branch grows here. |
| `inviteWhy` | Der Selbstcheck ist kostenlos, dauert fünf Minuten und braucht kein Konto. Du kannst ihn weitergeben. | The self-check is free, takes five minutes and needs no account. You can pass it on. |
| `inviteShareAction` | Einladung teilen | Share invitation |
| `inviteCodeLabel` | Dein Code | Your code |
| `inviteCodeCopied` | Code kopiert | Code copied |
| `invitePrivacyFootnote` | Du erfährst nur, wie viele Menschen begonnen haben. Nie wer. | You only learn how many people have started. Never who. |
| `inviteShareMessage` | Falls du dich fragst, ob frühkindliche Reflexe bei euch eine Rolle spielen: Hier gibt es einen kostenlosen 5-Minuten-Check – ohne Anmeldung und ohne App. {link} | If you are wondering whether retained primitive reflexes play a role for you: here is a free 5-minute check – no sign-up, no app. {link} |
| `inviteRedeemQuestion` | Hat dich jemand eingeladen? | Did someone invite you? |
| `inviteRedeemPaste` | Aus Zwischenablage einfügen | Paste from clipboard |
| `inviteRedeemSkip` | Überspringen | Skip |
| `inviteConfirmTitle` | Einladung annehmen? | Accept invitation? |
| `inviteConfirmBody` | Die Person, die dich eingeladen hat, sieht später nur, dass eine weitere Person über ihre Einladung mit dem Training begonnen hat – niemals deinen Namen. | The person who invited you will later only see that one more person has started training through their invitation – never your name. |
| `inviteConfirmAccept` | Einladung annehmen | Accept invitation |
| `inviteConfirmDecline` | Nicht jetzt | Not now |
| `inviteRedeemSuccess` | Einladung angenommen. | Invitation accepted. |
| `inviteErrorUnknownCode` | Diesen Code kennen wir nicht. Prüf bitte die Schreibweise. | We do not know this code. Please check the spelling. |
| `inviteErrorCodeInactive` | Dieser Code ist nicht mehr gültig. | This code is no longer valid. |
| `inviteErrorOwnCode` | Das ist dein eigener Code. | That is your own code. |
| `inviteErrorAlreadyReferred` | Zu deinem Konto gehört schon eine Einladung. | Your account already has an invitation. |
| `inviteErrorAccountTooOld` | Eine Einladung lässt sich nur in den ersten 30 Tagen eines Kontos annehmen. | An invitation can only be accepted within an account's first 30 days. |
| `inviteErrorOffline` | Dafür braucht es kurz Internet. Versuch es später noch einmal. | This needs a moment of internet. Please try again later. |
| `inviteEntryTitle` | Freunde einladen | Invite friends |
| `inviteEntrySubtitle` | Den kostenlosen Selbstcheck weitergeben | Pass on the free self-check |
| `impulseInviteTitle` | Verschenke einen guten Start | Give someone a good start |
| `impulseInviteBody` | Kennst du jemanden, der sich dieselbe Frage stellt? Der 5-Minuten-Check ist kostenlos. | Do you know someone asking the same question? The 5-minute check is free. |
| `inviteTreeSemantics` | Wachsender Baum. {count} Menschen sind über deine Einladung gestartet. | Growing tree. {count} people have started through your invitation. |

### 7.2 Website

| Ort | DE | EN |
|---|---|---|
| H1 | Du wurdest eingeladen | You have been invited |
| Intro | Jemand, der die App nutzt, hat dir diesen Link geschickt. Der Selbstcheck dauert fünf Minuten, ist kostenlos und braucht kein Konto. | Someone who uses the app sent you this link. The self-check takes five minutes, is free and needs no account. |
| Nach dem Ergebnis | Weiter mit der App | Continue with the app |
| Code-Hinweis | Dein Einladungscode: {code} — gib ihn beim ersten Start der App ein. | Your invitation code: {code} — enter it when you first open the app. |
| Ohne gültigen Code | Der Link ist unvollständig. Den Selbstcheck kannst du trotzdem machen. | The link is incomplete. You can still take the self-check. |

Die Zielseite verspricht keine Vergünstigung und fragt auch keine ab — im MVP
existiert kein Belohnungsprogramm (D11). Für alle neuen Texte in App und
Website gilt zusätzlich die Hausregel gegen Heilversprechen: beschrieben werden
Tätigkeiten, nie Wirkung, Therapie, Diagnose oder Nutzen für die Gesundheit.

---

## 8. Fehler- und Offline-Verhalten

| Fall | Verhalten |
|---|---|
| Kein Netz beim Öffnen von `/einladen` | Zuletzt geholter Code wird angezeigt und ist teilbar; der Zähler zeigt „—“, nie eine veraltete Zahl |
| Code noch nie geholt, kein Netz | Hinweis, dass der Code einmal Internet braucht; Screen bleibt bedienbar |
| Kein Netz beim Bestätigen | `inviteErrorOffline`, erneut versuchen; das 30-Tage-Fenster trägt |
| Unbekannter / stillgelegter / eigener Code | jeweils eigene Meldung aus Abschnitt 7.1 |
| Konto schon geworben | eigene Meldung, kein Fehlerdialog |
| Konto älter als 30 Tage | eigene Meldung mit Nennung der Frist |
| Zwei Einlösungen gleichzeitig | Datenbank-Eindeutigkeit gewinnt; die zweite bekommt `already_referred` |
| Einladender hat sein Konto gelöscht | `unknown_code` |
| Zielseite ohne `?c=` | Selbstcheck läuft trotzdem, ohne Code-Block |
| Trainingssitzung synchronisiert mehrfach | Trigger fasst nur `pending` an, Aktivierung bleibt einmalig |

---

## 9. Accessibility

- Der Baum ist ein `CustomPainter` und für Screenreader unsichtbar. Die Karte
  bekommt ein `Semantics`-Label mit `inviteTreeSemantics`; der Painter selbst
  wird als `ExcludeSemantics` gekapselt. Das Label nennt bewusst **keine
  Zweigzahl**, weil ab zwölf Aktivierungen keine neuen Zweige mehr entstehen und
  jede genannte Zahl damit falsch wäre.
- Die Einwachs-Animation respektiert `MediaQuery.disableAnimations`; ist sie
  gesetzt, erscheint der neue Zweig ohne Bewegung.
- Der Code wird in `textTheme.headlineSmall` mit erhöhtem Buchstabenabstand
  gesetzt und ist auch als Text auswählbar, nicht nur über den Kopieren-Knopf.
- Farbkontrast: Baumgrün gegen beide Themes nach `docs/ACCESSIBILITY_GUIDE.md`
  prüfen; die Zahl wird nie allein durch Farbe transportiert.
- Alle Ziele mindestens 48 dp; der Screen funktioniert bei 200 % Textskalierung
  ohne Abschneiden — dieselbe Prüfung wie in
  `test/features/training/presentation/widgets/training_responsive_accessibility_test.dart`.

---

## 10. Messdefinitionen

| Kennzahl | Definition | Quelle |
|---|---|---|
| Teilen-Knopf gedrückt (`share_action_tapped`) | Der Nutzer hat den Teilen-Knopf gedrückt. Gezählt wird **vor** dem Öffnen des nativen Menüs. Ob das Menü erschien und ob tatsächlich geteilt wurde, ist unbekannt und wird nirgends behauptet. | `referral_codes.share_action_tapped_count` |
| Zielseite aufgerufen | Aufruf von `/einladung` mit formgültigem Code | `referral_codes.landing_view_count` |
| Eingelöst | `referrals`-Zeile mit `status = 'pending'` entstanden | `referrals` |
| Aktiviert | Übergang auf `activated` nach erstem abgeschlossenen Training | `referrals.activated_at` |

Selbstcheck-Abschlüsse werden im MVP **gar nicht gemessen** (D12) — weder
gespeichert noch gezählt noch angezeigt. Der Vier-Stufen-Trichter ist ohne sie
vollständig. Sollte die Kennzahl später gewünscht sein, braucht sie ein eigenes
Datenmodell, eine eigene Funktion, eine eigene Datenschutzprüfung und eigene
Tests; sie darf nicht nebenbei entstehen.

Es gibt kein Analytics-SDK: `firebase_analytics` ist in `pubspec.yaml:35`
auskommentiert, die Website hat keins. Das bleibt so.

---

## 11. Implementierungsphasen

Jede Phase ist für sich lauffähig, testbar und einzeln abnehmbar.

**Phase 0 — Linkarchitektur verifizieren. Blockierend für Domain-/Hosting-Fragen.**
Vor jeder Zeile Code ist zu prüfen, ob die Linkarchitektur überhaupt trägt:

1. `https://reflexjourney.app/.well-known/apple-app-site-association` liefert
   HTTP 200 mit `Content-Type: application/json` und den erwarteten AppIDs
2. `https://reflexjourney.app/.well-known/assetlinks.json` liefert HTTP 200 mit
   `de.reflexjourney.app`
3. `https://reflexjourney.app/selbstcheck` und `/en/selbstcheck` liefern HTTP 200
   — die Domain bedient also nicht nur die AASA, sondern die Website
4. Manuelle Geräteprüfung eines bestehenden Universal Links
   (`/auth/reset-password`) auf echtem iPhone und Android — dokumentiert als
   „ausstehend“, blockiert die datenbank- und appinternen Phasen 1–4 **nicht**.
   Die entscheidende End-to-End-Prüfung erfolgt in Phase 5 mit
   `https://reflexjourney.app/einladung?c=<TESTCODE>` nach Erweiterung von
   AASA, Android-Manifest und App-Routing. Phase 5 und der Rollout gelten
   ohne erfolgreiche Tests auf iPhone und Android **nicht** als abgeschlossen.

Schlagen die Live-HTTP-Punkte 1–3 fehl, **stoppt die Umsetzung**. Dann ist zuerst
die Domain- und Hosting-Frage zu klären, denn davon hängen Linkformat, AASA-Pfade
und die gesamte Zielseiten-Architektur ab. Ergebnis dieser Phase ist eine
Notiz unter `docs/evidence/invite-phase0/` mit den vier Befunden.

**Phase 1 — Datenbank**
`supabase/migrations/<YYYYMMDDNN>_referral_program.sql` — Datum des
Umsetzungstages, `NN` ist die nächste freie Nummer dieses Tages (am 2026-08-21
wäre `2026082105` die nächste, weil `2026082104` belegt ist). Dazu
`supabase/tests/<gleiche-ID>_referral_program_test.sql`.
Die Migration muss idempotent sein und `supabase db reset --local` grün
durchlaufen. **Nicht auf die Live-Datenbank anwenden** — dort liegen echte
Nutzerdaten, und mutierendes SQL ist Founder-gegated.
Fertig, wenn alle SQL-Tests grün sind und kein Client die Tabellen direkt lesen kann.

**Phase 2 — Datenschicht in der App**
`lib/features/invite/domain/models/invite_overview.dart`,
`lib/features/invite/domain/repositories/invite_repository.dart`,
`lib/features/invite/data/repositories/supabase_invite_repository.dart`,
`lib/features/invite/presentation/providers/invite_providers.dart`.
Tests mit gefälschtem Repository unter `test/features/invite/`.

**Phase 3 — Einladen-Screen und Baumkarte**
`lib/features/invite/presentation/screens/invite_screen.dart`,
`.../widgets/impact_tree_card.dart`, `.../widgets/impact_tree_painter.dart`,
ARB-Schlüssel, Route und `kInviteEnabled` in `lib/config/launch_flags.dart`.
Feste Positionstabelle für Zweige — nichts Zufälliges, sonst sind Golden-Tests wertlos.

**Phase 4 — Einlösen mit Bestätigung**
`.../screens/invite_redeem_screen.dart`, `.../widgets/invite_confirm_sheet.dart`,
dauerhafter Einstieg ausschließlich in den Einstellungen (D10 — nicht im Profil),
Einbau des Onboarding-Schritts.
Der genaue Platz in der Onboarding-Kette ist an der Weiterleitungslogik in
`lib/core/navigation/app_router.dart` (`_postAuthHome`, Zeile 177 ff.) zu
bestimmen; vorgesehen ist der letzte Schritt vor dem Dashboard. `[ANNAHME RJ-INV-4]`

**Phase 5 — Deep Link**
`lib/core/storage/pending_invite_store.dart`, Erweiterung in `lib/app.dart`,
`android/app/src/main/AndroidManifest.xml`, AASA-Pfade im Website-Repo.
Fertig, wenn ein Link auf beiden Plattformen in allen drei Anmeldezuständen
korrekt landet.

**Phase 6 — Impulse**
`lib/features/invite/domain/invite_prompt_policy.dart` (reine, testbare Logik),
`.../widgets/invite_prompt_card.dart`, Einbau in Ergebnis- und Golden-Day-Screen.
I1 aktiv, I2 gebaut und getestet, aber deaktiviert ausgeliefert (D9).

**Phase 7 — Website**
`src/pages/einladung.astro`, `src/pages/en/einladung.astro`,
`src/content-pages/EinladungPage.astro`, Texte in `src/i18n/`, `noindex`,
Sitemap-Ausschluss.

**Phase 8 — Messung**
Admin-Sicht für den Trichter, Anschluss an die bestehende Admin-Metrik.

### Abnahmekriterien je Phase

Zusätzlich zu den phasenspezifischen Punkten gelten die Qualitätsschranken aus
`CLAUDE.md` §7 unverändert: `flutter analyze --no-fatal-infos` ohne Fehler und
Warnungen, `flutter test` vollständig grün (beides über
`make release-readiness-mobile`), jede neue Verhaltensweise mit mindestens einem
Test, jede neue Zeichenkette in **beiden** `.arb`-Dateien gefolgt von
`flutter gen-l10n`, und für jeden berührten Screen Vorher-Nachher-Screenshots
unter `docs/evidence/<task>/`. Kein Screen darf nach dem Einbau eine leere
Sektion, eine verwaiste Überschrift oder eine Sackgasse zeigen.

---

## 12. Tests und manuelle QA

### SQL (`supabase/tests/2026082105_referral_program_test.sql`)

- Selbst-Einlösung wird abgewiesen
- Doppel-Einlösung wird abgewiesen (zwei sequenzielle Aufrufe; der Unique
  Constraint auf `invitee_user_id` ist der Schutz auch bei Nebenläufigkeit —
  ein echter Paralleltest ist nicht Teil dieser Suite)
- Konto älter als 30 Tage wird abgewiesen
- stillgelegter Code wird abgewiesen
- Training abgeschlossen **vor** Code-Einlösung → Zeile entsteht direkt als
  `activated` (nicht dauerhaft `pending`)
- `authenticated` kann `referrals` und `referral_codes` weder lesen noch
  mutieren (SELECT/INSERT/UPDATE/DELETE)
- Funktionsrechte: `authenticated` darf die vorgesehenen RPCs; `anon` nur
  `log_invite_landing_view`; `PUBLIC` darf interne Funktionen nicht ausführen
- `log_invite_landing_view` zählt nur aktive Codes (`is_active`)
- Trigger aktiviert genau einmal, auch bei mehrfach synchronisierter Sitzung
- Trigger rührt fremde `referrals`-Zeilen nicht an
- Kontolöschung des Eingeladenen setzt `invitee_user_id` auf `NULL` und verändert
  `activated_count` des Einladenden nicht
- Kontolöschung des Einladenden entfernt Code und Zeilen
- `get_my_invite_overview` liefert bei zwei Aufrufen denselben Code
- ein Wechsel von `activated` nach `blocked` wird von der Datenbank abgewiesen
- **kein** `entitlement_grants`-Eintrag entsteht irgendwo im Ablauf
- **keine** Zeile in `benefit_campaigns` oder `benefit_codes` entsteht
- `redeem_invite_code` liefert ausschließlich `{result: …}` (kein `status`/`reason`)

### Flutter

- Golden-Tests der Baumkarte bei 0, 1, 5 und 12, hell und dunkel
- `invite_prompt_policy` als reine Unit-Tests: 30-Tage-Regel, Jahresdeckel,
  zweimal-ignoriert-Regel, Mood-Unterdrückung, Trainingssperre
- Deep-Link-Route bis zum Bestätigungsdialog, angemeldet und abgemeldet
- Alle sechs Fehlerfälle mit passender Meldung
- Offline-Zustand des Einladen-Screens
- Textskalierung 200 % ohne Überlauf

### Manuelle QA-Matrix

| # | Plattform | App installiert | Angemeldet | Fall | Erwartung |
|---|---|---|---|---|---|
| 1 | iOS | nein | — | Link antippen | Zielseite, Selbstcheck startet |
| 2 | iOS | ja | ja, neu | Link antippen | App öffnet, Bestätigung erscheint |
| 3 | iOS | ja | nein | Link antippen | Code überlebt Registrierung, Bestätigung danach |
| 4 | iOS | ja | ja, Konto > 30 Tage | Link antippen | Meldung „Frist“ |
| 5 | Android | nein | — | Link antippen | wie 1 |
| 6 | Android | ja | ja | Link antippen | wie 2 |
| 7 | beide | ja | ja | Code manuell eingeben | Bestätigung, dann Erfolg |
| 8 | beide | ja | ja | eigenen Code eingeben | Meldung „eigener Code“ |
| 9 | beide | ja | ja | Flugmodus, Einladen öffnen | Code sichtbar, Zähler „—“ |
| 10 | beide | ja | ja | erstes Training des Eingeladenen abschließen | Baum des Einladenden wächst beim nächsten Öffnen |
| 11 | beide | ja | ja | App-Neustart mitten in der Registrierung | Code ist noch da (iOS-26-Fall) |
| 12 | beide | ja | ja | VoiceOver / TalkBack auf dem Einladen-Screen | Karte wird als Satz plus Zahl vorgelesen |

Die Kette über den App Store bleibt manuell und gehört in `docs/HANDOFF_QA_MATRIX.md`.

---

## 13. Rollout, Flagging, Rückbau

`kInviteEnabled` in `lib/config/launch_flags.dart` gated **ausschließlich die
Oberfläche der App** — Routen, Einträge, Impulse. Es kann weder einen
Datenbank-Trigger noch die Website beeinflussen. Für Stufe 2 ist deshalb ein
serverseitiger Schalter vorgesehen (siehe unten), kein Compile-Flag.

Reihenfolge der Freischaltung:

0. Phase 0 Live-HTTP (Punkte 1–3) bestanden; manuelle Geräteprüfung (Punkt 4)
   dokumentiert ausstehend — End-to-End in Phase 5
1. Migration anwenden (Tabellen und Funktionen sind ohne Oberfläche wirkungslos);
   das Anwenden auf die Live-Datenbank ist Founder-gegated
2. App-Release mit `kInviteEnabled = false`
3. Zielseite live, AASA-Pfade live, erneut verifiziert
4. Deep-Link-Test auf echten Geräten (QA-Matrix Zeilen 1–6)
5. `kInviteEnabled = true` im nächsten Release

**Post-Launch (nach öffentlicher Store-Verfügbarkeit, nicht Teil der MVP-Phasen):**
Store-Buttons auf der Einladungs-Zielseite — siehe Abschnitt 14 Punkt 3 und
`docs/evidence/invite-phase7/README.md`. Bis dahin: Wartelisten-CTA und ehrliche
Pre-Launch-Copy; keine Platzhalter- oder TestFlight-Links.

Rückbau: Flag auf `false`. Daten bleiben unangetastet, bereits aktivierte
Einladungen bleiben gültig. Einzelfall-Maßnahme ist
`referral_codes.is_active = false`, was nur diesen einen Code stilllegt.

### Stufe 2 — Architekturentscheidung, ausdrücklich nicht Teil dieses MVP

Der MVP baut **nichts** davon: keine Kampagnenzeile, keine Programm-Abfrage,
keine Website-Abfrage, keinen Grant, keine vorbereitende Spalte (D11). Der
folgende Absatz hält nur die Richtung fest, damit eine spätere Umsetzung nicht
von vorn anfängt.

Ein Compile-Flag scheidet als Schalter aus, weil es weder einen
Datenbank-Trigger noch eine Website erreicht. Die gemeinsame Wahrheit müsste
serverseitig liegen — naheliegend ist eine Zeile in `benefit_campaigns`, die App
und Website über eine dann zu bauende Funktion lesen. Der Aktivierungs-Trigger
würde zusätzlich einen `entitlement_grants`-Eintrag anlegen
(`source = 'referral'`, `source_ref = referrals.id`, `store = 'promotional'`);
die vorhandene Eindeutigkeit `(source, source_ref, entitlement_key)` würde die
Gutschrift von selbst einmalig machen. Ob `source = 'referral'` dafür der
richtige Wert ist und wie die Website an die Wahrheit kommt, ist **offen** und
gehört in ein eigenes Design, zusammen mit der rechtlichen Prüfung aus
Abschnitt 14.

---

## 14. Offene Entscheidungen und rechtlich zu Prüfendes

### Am 2026-08-21 entschieden, damit geschlossen

- Nur Impuls I1 zum Start; I2 gebaut, aber deaktiviert (D9).
- Dauerhafter Einstieg nur in den Einstellungen (D10).
- Keine Stufe-2-Infrastruktur im MVP (D11).
- Keine Selbstcheck-Abschlussmessung (D12).
- 30-Tage-Einlösungsfenster bleibt.
- Einwachs-Animation beim bewussten Öffnen der Seite bleibt.

### Noch offen

1. Höhe und Form des Geschenks in Stufe 2 — offen, gehört in das eigene Stufe-2-Design.
2. Zeitpunkt, zu dem I2 zugeschaltet wird (Kriterium: genug Zahlen aus I1).
3. **Post-Launch — Store-Buttons auf `/einladung` (nicht MVP):** Die App ist noch
   nicht öffentlich im Apple App Store und Google Play Store. Bis dahin bleiben
   ehrliche Pre-Launch-Texte und der Wartelisten-CTA. **Keine** Platzhalter-,
   TestFlight- oder Internal-Testing-Links auf der öffentlichen Website.
   Nach Veröffentlichung:
   - Apple-ID in App Store Connect ermitteln
   - iOS-URL: `https://apps.apple.com/app/id<APPLE_ID>`
   - Android-URL: `https://play.google.com/store/apps/details?id=de.reflexjourney.app`
   - URLs als zentrale Konstanten in der Website-`config` (nicht in Astro-Komponenten)
   - getrennte, lokalisierte App-Store- und Play-Buttons auf der Einladungsergebnisseite
   - Wartelisten-CTA nur solange keine öffentlichen Store-URLs gesetzt sind
   - Pre-Launch-Text „noch nicht im Store“ entfernen; DE und EN gemeinsam
   - auf echten Geräten prüfen; Tests für Store-URLs und Pre-Launch-Fallback
   Tracking: `docs/evidence/invite-phase7/README.md`, Website `WEBSITE_BACKLOG.md` W-024,
   `FOUNDER_TODO.md` F9.6.

### Rechtlich zu prüfen, vor Freischaltung

1. **Datenschutzerklärung** in App und Website um die Verarbeitung
   „Einladungsbeziehung“ ergänzen: welche Daten, welcher Zweck, welche
   Speicherdauer, und ausdrücklich die aggregierte Rückmeldung an den
   Einladenden samt der in 5.3 benannten Grenze.
2. **Verarbeitungsverzeichnis** um den neuen Zweck erweitern.
3. **HWG / UWG**: Zuwendungen im Zusammenhang mit einer
   Gesundheitsanwendung. Betrifft erst Stufe 2, sollte aber vor deren Bau
   geklärt sein — Anwalts-Baustein, keine Entwicklungsfrage.
4. **Store-Regeln**: Die konkrete Gestaltung von Stufe 2 muss vor der Umsetzung
   gegen die dann aktuellen Regeln von Apple und Google sowie gegen HWG und UWG
   geprüft werden. Dieses Dokument hat dazu **keine** belastbare Prüfung
   vorgenommen und trifft deshalb keine Aussage zur Zulässigkeit.
5. **Kopplungsverbote, die schon für den MVP zu beachten sind**: Die Einladung
   darf zu keinem Zeitpunkt an eine Store-Bewertung, eine Rezension oder eine
   Zahlung außerhalb der In-App-Kaufwege gekoppelt werden. Das ist im MVP
   trivial erfüllt, weil es keine Belohnung gibt — es gilt aber als Randbedingung
   für jede spätere Änderung.

---

## 15. Annahmen

| ID | Annahme | Prüfung |
|---|---|---|
| RJ-INV-1 | `reflexjourney.app` ist ein Alias desselben Vercel-Projekts und liefert AASA, Asset Links und Website aus (`FOUNDER_TODO.md`, F7) | **Phase 0** — Live-HTTP-Punkte 1–3 blockierend; Geräteprüfung (Punkt 4) dokumentiert ausstehend, End-to-End in Phase 5 |
| RJ-INV-2 | Die Website bleibt statisch gebaut, deshalb Query-Parameter statt Pfad-Route | `astro.config.mjs` — kein Adapter, kein `output: 'server'` |
| RJ-INV-3 | Mood-Skala ist 1–5, Unterdrückungsschwelle `mood <= 2` | `lib/core/database/tables/mood_checkins_table.dart:13` |
| RJ-INV-4 | Der Onboarding-Schritt passt als letzter Schritt vor dem Dashboard | Weiterleitungslogik in `app_router.dart:177 ff.` beim Bau bestätigen |
| RJ-INV-5 | `random()` genügt für einen öffentlichen Einladungscode | bewusst akzeptiert, wie beim bestehenden Trainer-Code |
| RJ-INV-6 | Ein von `anon` aufrufbarer Zielseiten-Zähler ist vertretbar | bewusst akzeptiert; nur Zahlen, keine Personendaten |
| RJ-INV-7 | 30-Tage-Fenster und die Schwelle von 10 Aktivierungen je 30 Tage sind sinnvolle Startwerte | nach 90 Tagen anhand echter Zahlen überprüfen |
