# Prompt: Sprach-Infrastruktur fertigstellen (I18N-Endspurt + Mehrsprachen-Fundament)

> **Anleitung für Alexander:** Diesen Prompt in einer **frischen Claude-Code-Session** im
> App-Repo (`~/dev/claudvibes/reflexjourney`) ausführen. **Opus 4.8 reicht** — alle
> Architektur-Entscheidungen sind hier bereits getroffen und als exakter Code vorgegeben;
> die Session muss nur präzise ausführen. Der Prompt ist **wiederanlauffähig**: Wenn eine
> Session endet, startest du einfach eine neue mit demselben Prompt — sie liest den Tracker
> und macht beim nächsten Block weiter. Wiederholen, bis die Definition of Done am Ende
> vollständig grün ist.

---

## Rolle

Du bist Senior-Flutter-Engineer mit i18n-Schwerpunkt und professioneller DE→EN-Übersetzer
für Gesundheits-Apps. Du arbeitest in kleinen, einzeln verifizierbaren Blöcken, übersetzt
idiomatisch (nie wörtlich-mechanisch) und hinterlässt **niemals** halbfertige Arbeit im
Working Tree.

## Auftrag (drei Ziele, in dieser Reihenfolge)

1. **Zentrale Sprach-Infrastruktur:** Alle verstreuten Zweisprachigkeits-Weichen
   (`== 'de'`-Ternaries, feste `Locale('de')`-Listen, Zwei-Button-Sprachwahl) auf **eine
   Registry + einen Content-Resolver** zusammenziehen. Danach bedeutet „neue Sprache
   hinzufügen“: 1 ARB-Datei + 1 Registry-Eintrag + Runbook abarbeiten — statt 36 Codestellen
   suchen.
2. **Rest-Externalisierung:** Die verbleibenden ~749 nutzersichtbaren Hardcodes (Stand
   2026-07-19, `scripts/i18n_audit.py`) in den offenen Bereichen (Assessment-UI, Core,
   Bootstrap/Start, Trainer, Chat, launch-versteckte Features, Admin/Dev-Tools) über ARB-Keys
   lokalisieren, bis das Audit-Gate **0** meldet und dauerhaft scharf ist.
3. **Zukunftssicherung:** `docs/I18N_ADD_LANGUAGE.md` (Runbook „Sprache XX hinzufügen“)
   anlegen, Gates auf N Sprachen verallgemeinern, Abschlussreport für den Founder schreiben.

**Pflichtlektüre vor dem Start (in dieser Reihenfolge):** `CLAUDE.md` (bindend),
`tasks/lessons.md`, `docs/I18N_EN_TRACKER.md` (Arbeitsstand + „Nächster Block“),
`docs/TRANSLATION_EN_PROMPT.md` (Style Guide + Glossar-Regeln gelten unverändert weiter),
`docs/GLOSSARY_DE_EN.md`.

## Warum frühere Sessions liegen blieben — Anti-Stall-Protokoll (bindend)

Die bisherigen i18n-Sessions haben gute Arbeit geleistet, endeten aber wiederholt mit
uncommitteten Batches und offenen Restlisten. Deshalb gilt ab jetzt:

1. **Commit-oder-Revert:** Jeder Arbeitsblock endet entweder mit einem grünen Commit oder
   mit `git restore` der Blockdateien + Blocker-Notiz im Tracker. **Eine Session darf
   niemals mit uncommitteten Änderungen unter `lib/`, `test/`, `scripts/`, `supabase/`
   oder `ios/` enden.** (`.claude/`, `.cursor/` und fremde Docs wie
   `docs/REFERRAL_GROWTH_PLAN.md` bleiben unangetastet untracked.)
2. **Tracker ist das Gedächtnis:** Nach jedem Block die betroffenen Zeilen der
   Datei-Status-Tabelle in `docs/I18N_EN_TRACKER.md` aktualisieren, einen Arbeitslog-Absatz
   ergänzen und die Zeile `**Nächster Block:** <Wx/By>` unter der Phasen-Checkliste
   aktualisieren. Der Tracker darf mit in den Block-Commit.
3. **Mechanische Auswahl, kein Ermessen:** Die Blockreihenfolge unten ist verbindlich.
   Innerhalb eines Batches liefert `python3 scripts/i18n_audit.py --tsv /tmp/audit.tsv`
   die Datei-Fundliste; abgearbeitet wird in Tabellenreihenfolge.
4. **Kein Scope-Creep:** Keine „Verbesserungen nebenbei“. Deutsche UI-Texte bleiben
   byte-identisch (Ausnahme: der bereits vorhandene W0-Batch). Keine Logik-Änderungen außer
   den hier exakt spezifizierten.
5. **Wiederaufnahme:** Frische Session → Pflichtlektüre → `git status` (muss sauber sein,
   sonst zuerst W0-Protokoll sinngemäß anwenden) → beim Tracker-„Nächster Block“ weitermachen.

## Arbeitsstand (verifiziert 2026-07-19)

- Branch `i18n/english-localization`; **753/753 ARB-Keys**, Parity- und Quality-Gate laufen
  als `make i18n-check` (in `release-readiness-mobile` eingebunden).
- **Fertig verifiziert:** Onboarding, Auth, Dashboard, Training komplett, Packages, Journal,
  Progress, Golden Day, Accompaniment, Mood, Settings, Profil; Fragebogen-Content (123
  Fragen) und Übungs-Content als DE/EN-Feldpaare; iOS `InfoPlist.strings` de/en;
  `profiles.locale`-Sync; serverseitige Push-Copy liest `profiles.locale` (Deploy weiterhin
  Founder-gated); 6 EN-Screenshots in `docs/evidence/I18N-EN/`.
- **Offen laut Audit (749 sichtbare Hardcodes, 479 deutsch, 11 `de_DE`-Formatstellen):**
  Assessment-UI, Core-Services (Client-Push!), Bootstrap/`main_*` (Start-Fehlertexte!),
  Trainer (~240), Chat (~65), Experience/Community/Video (launch-versteckt), Admin (108),
  Dev-Tools, `app.dart`/`app_shell`/Router — Details in der Tracker-Tabelle.
- **Uncommitteter W0-Batch liegt im Tree** (EN-Sicherheits-Feinschliff Übungen +
  `ReflexProfilePdfCopy`-Struktur + Build-Bump) — wird in W0 verifiziert und committet.
- **36 `== 'de'`-Ternaries** in `lib/` (Grep unten) — werden in W2 zentralisiert.
- **Bekannter Bug:** `lib/app.dart:409–413` enthält noch einen Inline-`isDE`-Reminder-Text
  („Zeit für deine Einheit“ / „Time for your unit“) — alter Wortlaut am ARB vorbei; Fix in W2.
- Rechtstexte bleiben Anwalts-Sache: `consent_screen.dart` (335 Literale) und
  `training_disclaimer_dialog.dart` (19) **nicht anfassen, nur geflaggt lassen**.

## Harte Regeln (unverändert gültig)

- DE ist Template und Quelle der Wahrheit (`l10n.yaml` → `app_de.arb`). Jeder neue Key
  gleichzeitig in `app_de.arb` **und** `app_en.arb`, mit `@key`-Metadaten (description,
  placeholders). Semantische Key-Namen, keine Nummerierungen, keine Umbenennung bestehender
  Keys. ICU für Plural/Select; niemals Sätze aus Fragmenten bauen.
- EN nach `docs/GLOSSARY_DE_EN.md` + Style Guide (en-US, warm, „you“, Title Case für
  Buttons/Titel, Sentence case für Fließtext). **Keine Heil-/Therapie-/Diagnose-Sprache in
  beiden Sprachen** („treat/cure/heal/therapy/diagnose/clinically proven“ verboten).
- Log-/Sentry-/Debug-Texte (Kategorie d): auf Englisch vereinheitlichen, **kein** ARB-Key.
- Keine Prod-DB-Zugriffe, keine Live-Migrations, kein Function-Deploy, kein `git push`.
- Commit-Disziplin nach CLAUDE.md §6/§7: explizite Datei-Listen, ein Anliegen pro Commit,
  vor jedem Commit `git diff --cached --name-status` prüfen, Evidenz nie vor der Beobachtung
  notieren.
- Nach jedem Block: `flutter gen-l10n` (falls ARB berührt), `make i18n-check`,
  `flutter analyze --no-fatal-infos` (0 Fehler/0 Warnungen; Infos sind erlaubte Altlast),
  `flutter test` (volle Suite grün).

---

# Arbeitspakete

## W0 — In-flight-Batch verifizieren und landen (zuerst, genau einmal)

Der Tree enthält einen fachlich sinnvollen, aber uncommitteten Batch. Disposition:

- [ ] `git status --short` und `git diff --stat` ausgeben. Erwartet: genau
      `completion_questions.dart`, `reflex_questionnaire.dart`,
      `reflex_questionnaire_definitions.dart`, `reflex_profile_pdf_service.dart`,
      `exercise.dart`, `pubspec.yaml` modifiziert (+ untracked `.claude/`, `.cursor/`,
      `docs/REFERRAL_GROWTH_PLAN.md`, die unangetastet bleiben). Weicht der Stand ab:
      Diff lesen, sinngemäß nach diesem Protokoll dispositionieren, Abweichung im Tracker
      loggen.
- [ ] Diffs vollständig lesen (`git diff <datei>`). Prüfkriterien: nur EN-Werte und
      PDF-Copy-Struktur geändert, **keine deutschen UI-Texte umformuliert**, keine
      Claim-Sprache („treat/cure/heal/therapy/diagnose“) in neuen EN-Texten.
- [ ] Verifizieren: `make i18n-check` → grün; `flutter analyze --no-fatal-infos` → 0/0;
      `flutter test` → volle Suite grün. Schlägt etwas fehl und ist nicht in ≤3 kleinen
      Fixes zu heilen: gesamten Batch mit `git restore <dateien>` zurücksetzen, im Tracker
      als „W0 verworfen wegen <Grund>“ loggen, weiter mit W1.
- [ ] Drei getrennte Commits (ein Anliegen pro Commit):
      1. `git add lib/features/training/domain/models/exercise.dart lib/features/assessment/domain/reflex_questionnaire.dart lib/features/assessment/domain/reflex_questionnaire_definitions.dart lib/features/assessment/domain/completion_questions.dart`
         → `i18n: safety-conscious EN exercise copy + clearer reflex labels`
      2. `git add lib/features/assessment/domain/services/reflex_profile_pdf_service.dart`
         (+ zugehörige Tests/ARB, falls der Diff welche enthält)
         → `i18n: localized copy structure for reflex-profile PDF (ReflexProfilePdfCopy)`
      3. `git add pubspec.yaml` → `chore: bump build number (2026071601)`
- [ ] Tracker: W0-Absatz ins Arbeitslog, „Nächster Block: W1“.

## W1 — Sprach-Registry `AppLanguages` (das eine Verzeichnis aller Sprachen)

**Dateien:** Neu `lib/core/l10n/app_languages.dart`, neu
`test/core/l10n/app_languages_test.dart`.

- [ ] **Test zuerst** (`test/core/l10n/app_languages_test.dart`):

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:corejourney/core/l10n/app_languages.dart';

void main() {
  test('registry lists German first and English second', () {
    expect(AppLanguages.all.map((l) => l.code).toList(), ['de', 'en']);
    expect(AppLanguages.sourceCode, 'de');
  });

  test('locales derive from the registry', () {
    expect(AppLanguages.locales, const [Locale('de'), Locale('en')]);
  });

  test('isSupported accepts registry codes only', () {
    expect(AppLanguages.isSupported('de'), isTrue);
    expect(AppLanguages.isSupported('en'), isTrue);
    expect(AppLanguages.isSupported('fr'), isFalse);
    expect(AppLanguages.isSupported(null), isFalse);
  });

  test('resolveInitial: supported device language wins, otherwise English', () {
    expect(AppLanguages.resolveInitial('de'), 'de');
    expect(AppLanguages.resolveInitial('en'), 'en');
    expect(AppLanguages.resolveInitial('fr'), 'en');
    expect(AppLanguages.resolveInitial(''), 'en');
  });

  test('normalize falls back to the source language', () {
    expect(AppLanguages.normalize('en'), 'en');
    expect(AppLanguages.normalize('xx'), 'de');
    expect(AppLanguages.normalize(null), 'de');
  });

  test('byCode returns the registry entry', () {
    expect(AppLanguages.byCode('en').autonym, 'English');
    expect(AppLanguages.byCode('de').flagEmoji, '🇩🇪');
  });
}
```

- [ ] Test läuft rot (Datei existiert nicht). Dann Implementierung:

```dart
import 'dart:ui' show Locale;

/// One supported app language.
///
/// [code] is the ISO-639-1 code and MUST match three things at once:
/// the ARB file name (`lib/l10n/app_<code>.arb`), the `profiles.locale`
/// value synced to Supabase, and the `SupportedLocale` union in
/// `supabase/functions/_shared/notification_copy.ts`.
class AppLanguage {
  final String code;
  /// The language's own name, shown untranslated in every picker
  /// ("Deutsch", "English") — autonyms are never localized.
  final String autonym;
  final String flagEmoji;

  const AppLanguage({
    required this.code,
    required this.autonym,
    required this.flagEmoji,
  });

  Locale get locale => Locale(code);
}

/// Single source of truth for which languages the app supports.
///
/// Adding a language = add ONE entry here + follow
/// docs/I18N_ADD_LANGUAGE.md. Nothing else in lib/ may hardcode a
/// language list or a `Locale('de')`-style literal.
class AppLanguages {
  AppLanguages._();

  static const AppLanguage german =
      AppLanguage(code: 'de', autonym: 'Deutsch', flagEmoji: '🇩🇪');
  static const AppLanguage english =
      AppLanguage(code: 'en', autonym: 'English', flagEmoji: '🇬🇧');

  /// Order = display order in pickers. German (source language) first.
  static const List<AppLanguage> all = [german, english];

  /// The content source language (DE is the template ARB and the
  /// fallback of last resort for content fields).
  static const String sourceCode = 'de';

  /// What a fresh install gets when the device language is unsupported.
  static const String internationalDefault = 'en';

  static List<Locale> get locales =>
      all.map((language) => language.locale).toList(growable: false);

  static bool isSupported(String? code) =>
      code != null && all.any((language) => language.code == code);

  /// First-launch detection: keep the device language if we support it,
  /// otherwise fall back to [internationalDefault].
  static String resolveInitial(String deviceLanguageCode) =>
      isSupported(deviceLanguageCode) ? deviceLanguageCode : internationalDefault;

  /// Storage/service normalization: unknown or missing codes resolve to
  /// the source language (mirrors the server-side fallback).
  static String normalize(String? code) => isSupported(code) ? code! : sourceCode;

  static AppLanguage byCode(String code) =>
      all.firstWhere((language) => language.code == code,
          orElse: () => german);
}
```

- [ ] Registry verdrahten (jede Stelle einzeln, danach `flutter analyze` scoped):
      - `lib/app.dart`: `supportedLocales: const [Locale('de'), Locale('en')]` →
        `supportedLocales: AppLanguages.locales` (Import ergänzen).
      - `lib/core/settings/settings_provider.dart` (Erstsprach-Erkennung, Z. ~122):
        Ternary ersetzen durch
        `AppLanguages.resolveInitial(WidgetsBinding.instance.platformDispatcher.locale.languageCode)`;
        in `setLanguage` zusätzlich als erste Zeile
        `assert(AppLanguages.isSupported(code), 'unsupported language code: $code');`.
      - `lib/features/settings/presentation/screens/language_selection_screen.dart`:
        die zwei festen `_LanguageButton`-Blöcke durch eine Schleife über
        `AppLanguages.all` ersetzen (`label: language.autonym`,
        `selected: _selectedCode == language.code`); Vorschau-Lookup
        `lookupAppLocalizations(Locale(_selectedCode))` bleibt.
      - `lib/features/settings/presentation/screens/settings_screen.dart` (Z. ~162):
        `code == 'de' ? l10n.languageGerman : l10n.languageEnglish` →
        `AppLanguages.byCode(code).autonym`; die Sprachauswahl-Liste im Dialog ebenfalls
        über `AppLanguages.all` iterieren.
      - `lib/features/auth/presentation/screens/login_screen.dart` (Sprach-Chips
        `🇩🇪 Deutsch` / `🇬🇧 English`): Chips aus `AppLanguages.all` bauen
        (`'${language.flagEmoji} ${language.autonym}'`). Die zwei Allowlist-Einträge in
        `scripts/i18n_audit_allowlist.txt` bleiben gültig, weil die sichtbaren Strings
        identisch bleiben.
      - `lib/core/sync/`/Profil-Locale-Sync (Service, der `profiles.locale` schreibt):
        eingehenden Code durch `AppLanguages.normalize(...)` schicken, statt eigener
        de/en-Prüfung (Datei per `grep -rn "ProfileLocaleSyncService" lib` finden).
- [ ] Widget-Test der Sprachwahl anpassen/ergänzen: rendert **einen Button pro
      Registry-Eintrag** (Test iteriert `AppLanguages.all`, nicht hartes 2).
- [ ] Verifizieren: `flutter test test/core/l10n/ test/features/settings/` grün,
      volle Suite grün, analyze 0/0.
- [ ] Commit: `i18n: central AppLanguages registry drives locales, pickers, detection, sync`
      (+ Tracker-Update, „Nächster Block: W2“).

## W2 — Content-Resolver: alle `== 'de'`-Ternaries auf eine Stelle ziehen

**Dateien:** Neu `lib/core/l10n/localized_content.dart`, neu
`test/core/l10n/localized_content_test.dart`, dann die Aufrufstellen.

- [ ] **Test zuerst:**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:corejourney/core/l10n/localized_content.dart';

void main() {
  test('German picks the German variant', () {
    expect(pickLocalized('de', de: 'Halten', en: 'Hold'), 'Halten');
  });
  test('English picks the English variant', () {
    expect(pickLocalized('en', de: 'Halten', en: 'Hold'), 'Hold');
  });
  test('unknown locales resolve like the international default (English)', () {
    expect(pickLocalized('fr', de: 'Halten', en: 'Hold'), 'Hold');
  });
  test('works for non-string content', () {
    expect(pickLocalized<List<String>>('de', de: ['a'], en: ['b']), ['a']);
  });
}
```

- [ ] Implementierung:

```dart
import 'app_languages.dart';

/// Resolves bilingual content-field pairs (the `*De`/`*En` model pattern
/// backed by the `_de`/`_en` DB columns).
///
/// THE one place that knows the content-fallback policy:
/// requested language if it is German, otherwise the English variant
/// (English doubles as the international fallback until more content
/// languages exist). When a third content language is added, extend THIS
/// function and the model fields together — see docs/I18N_ADD_LANGUAGE.md.
T pickLocalized<T>(String locale, {required T de, required T en}) =>
    locale == AppLanguages.sourceCode ? de : en;
```

- [ ] Alle Ternary-Stellen umstellen. Vollständige Liste per
      `grep -rn "== 'de'\|=='de'" lib --include="*.dart" | grep -v app_localizations`
      (Stand 2026-07-19: 36 Treffer). Regeln:
      - **Accessor-Methoden** (`exercise.dart` `title/label/hints/...(locale)`,
        `reflex_questionnaire.dart` `label/shortLabel(locale)`,
        `completion_questions.dart:58`): Rumpf durch `pickLocalized(locale, de: …, en: …)`
        ersetzen. Signaturen und Aufrufer bleiben unverändert.
      - **Direkte Feldzugriffe in Widgets** (`immersive_exercise_screen.dart:263f`,
        `exercise_movement_widget.dart:93/355`): ebenfalls `pickLocalized(...)`.
      - **Formatierungs-Weichen** (`progress_overview_screen.dart:27`,
        `accompaniment_screen.dart:1047`, `settings_screen.dart:338/354`): hier KEIN
        `pickLocalized` — stattdessen die bestehende DE/EN-Formatlogik beibehalten, aber
        die Bedingung auf `Localizations.localeOf(context).languageCode ==
        AppLanguages.sourceCode` umschreiben (Format-Sonderfälle bleiben dokumentiert
        lokal; ein drittes Locale erbt automatisch das EN-Format).
      - **Bug-Fix `lib/app.dart:409–413`:** den kompletten `isDE`-Block ersetzen durch
        die vorhandenen ARB-Keys (`l10n.reminderSessionTitle` / `l10n.reminderSessionBody`
        via `lookupAppLocalizations(Locale(next.languageCode))`, da hier kein
        `BuildContext` mit App-Locale sicher ist). Alte Inline-Strings ersatzlos löschen.
      - `language_selection_screen.dart:78` (`_selectedCode == 'de'`) wurde in W1 bereits
        durch die Registry-Schleife ersetzt — verifizieren.
- [ ] Erfolgskriterium (hartes Grep-Gate):
      `grep -rn "== 'de'\|=='de'" lib --include="*.dart" | grep -v app_localizations | grep -v "core/l10n/"`
      → **0 Treffer**.
- [ ] Volle Suite + analyze + `make i18n-check` grün.
- [ ] Commit: `i18n: single pickLocalized resolver replaces all inline locale ternaries`
      (+ Tracker, „Nächster Block: W3“).

## W3 — Gates auf N Sprachen verallgemeinern

**Dateien:** `scripts/i18n_check.py`, `scripts/i18n_quality_check.py`, zugehörige
Python-Tests (liegen laut Tracker neben den Skripten bzw. unter `scripts/`/`test/` —
per `grep -rln "i18n_check" .` lokalisieren).

- [ ] `scripts/i18n_check.py`: Statt fest `app_de.arb`/`app_en.arb` zu vergleichen,
      **entdeckt** das Skript alle Kataloge: Template bleibt `lib/l10n/app_de.arb`;
      verglichen wird gegen **jede** weitere Datei `lib/l10n/app_*.arb` (sorted Glob).
      Alle bestehenden Prüfungen (Key-Parität, Metadaten-Parität, Leerwerte,
      ICU-Platzhalter vs. `@`-Metadaten, Umlaut-Check) laufen **pro Zielsprache** in einer
      Schleife; die Fehlermeldung nennt die jeweilige Datei. Exit ≠ 0, sobald irgendeine
      Sprache scheitert. Der Umlaut-Check gilt nur für Nicht-DE-Kataloge.
- [ ] Python-Test ergänzen: Ein temporärer Fixture-Katalog `app_fr.arb` mit fehlendem Key
      lässt das Gate scheitern; mit vollständigen Keys besteht es. (Fixtures im Test
      generieren, nicht ins echte `lib/l10n/` legen.)
- [ ] `scripts/i18n_quality_check.py`: Regeln sind EN-spezifisch (Glossar, en-US,
      Claim-Begriffe). Umbauen auf eine Struktur `RULES_BY_LOCALE = {'en': […]}`, die
      unbekannte Kataloge **überspringt und das im Output benennt** („app_fr.arb: no
      quality rules defined yet — add them when the language ships“). Verhalten für EN
      bleibt identisch (bestehende Tests müssen unverändert grün bleiben).
- [ ] `make i18n-check` unverändert lassen (ruft beide Skripte); Kommentar im Makefile
      ergänzen: `# validates ALL lib/l10n/app_*.arb catalogs against the DE template`.
- [ ] Volle Suite + `make i18n-check` grün. Commit:
      `i18n: parity/quality gates generalized to any number of ARB catalogs`
      (+ Tracker, „Nächster Block: W4/B1“).

## W4 — Rest-Externalisierung in festen Batches (bis Audit = 0)

**Protokoll pro Batch** (identisch für B1–B7):
1. `python3 scripts/i18n_audit.py --tsv /tmp/audit.tsv` laufen lassen; nur Dateien des
   Batches betrachten, in Tracker-Tabellen-Reihenfolge.
2. Jede Datei vollständig lesen. Pro Fund entscheiden: (a) UI → ARB-Key DE+EN mit
   Metadaten, (b) Log/Exception → englischer technischer Text ohne ARB, (c) technisches
   Literal → ggf. Audit-Filter-/Allowlist-Fall (nur mit exakter Begründung als
   `<pfad>\t<string>`-Zeile, niemals Wildcards), (d) `de_DE`-Format → über aktives Locale
   formatieren.
3. `flutter gen-l10n` → `make i18n-check` → scoped Audit (Datei muss aus der
   TSV-Fundliste verschwinden, Kategorien a/b/c) → `flutter analyze --no-fatal-infos`
   → `flutter test`.
4. Ein Commit pro Batch (`i18n: <bereich> strings externalized (Bx)`), Tracker-Zeilen der
   Batch-Dateien auf `verifiziert (<beleg>)`, Arbeitslog-Absatz, „Nächster Block“.

**Batch-Reihenfolge (verbindlich):**

- [ ] **B1 — Start & Gerüst (nutzersichtbar bei jedem App-Start):** `lib/bootstrap/bootstrap.dart`
      (26 — Start-/Fehler-Screens!), `lib/main_development.dart` (20; Dev-Banner darf
      englisch-technisch bleiben, sichtbare Fehlertexte in ARB), `lib/main_production.dart`,
      `lib/main_staging.dart`, `lib/main_smoke.dart`, `lib/app.dart` (Rest), 
      `lib/core/navigation/app_shell.dart` (6 — Tab-Labels!), `lib/core/navigation/app_router.dart` (3),
      `lib/core/widgets/error_retry_widget.dart` (1), `lib/core/database/app_database.dart` (2).
- [ ] **B2 — Hinweise & Client-Push:** `lib/core/onboarding/onboarding_hint_provider.dart` (20)
      + `onboarding_hint_gate.dart` (3), `lib/core/services/notification_service.dart` (30 —
      deutsche Default-Texte; Defaults an die Aufrufstellen verschieben und dort aus ARB
      befüllen; die irreführenden Parameternamen `titleDe`/`bodyDe` in `title`/`body`
      umbenennen — reine Umbenennung, keine Logik), `lib/core/notifications/notification_service.dart`
      (2 + Parameternamen wie zuvor), `lib/core/push/push_notification_service.dart` (11),
      `lib/core/reminders/*` (3 Dateien), `lib/core/settings/settings_provider.dart` (1),
      `lib/core/sync/sync_service.dart` (1 sichtbarer + Logs EN), `lib/core/logging/logger_service.dart`,
      `lib/core/monitoring/sentry_service.dart` (Logs EN).
- [x] **B3 — Assessment-UI komplett:** `duration_recommendation_screen.dart` (20),
      `analysis_placeholder_screen.dart` (16), `reflex_profile_screen.dart` (Rest-UI),
      `reflex_profile_result_screen.dart` + `_helpers.dart`, `reflex_profile_demo_screen.dart`,
      `reflex_radar_chart.dart` (Leerzustand), `reflex_profile_provider.dart` (3 sichtbare),
      `reflex_profile_pdf_service.dart` (Rest laut Audit nach W0),
      `draft_persistence_service.dart` (Logs EN).
- [x] **B4 — Trainer komplett (~240):** alle Tracker-Dateien unter `lib/features/trainer/`
      externalisiert; scoped Audit 0 a/b/c; Parity 1091/1091; 283/283 Tests.
- [x] **B5 — Chat komplett (~65):** alle Tracker-Dateien unter `lib/features/chat/`
      externalisiert; scoped Audit 0 a/b/c; Parity 1128/1128; 283/283 Tests.
- [ ] **B6 — Launch-versteckte Features:** `lib/features/experience/`,
      `lib/features/community/`, `lib/features/video/`, `lib/features/premium/data/premium_repository.dart`
      — gleiche Sorgfalt (Flags können wieder angehen), niedrigste Dringlichkeit.
- [ ] **B7 — Intern:** `lib/features/admin/` (108) und `lib/features/dev_tools/` (36+7)
      vollständig externalisieren (kompakte, aber semantische Keys `admin…`/`devTools…`),
      damit das Gate ohne Ausnahmen auf 0 steht.

**Nicht anfassen:** `consent_screen.dart`, `training_disclaimer_dialog.dart` (e-legal),
`lib/core/database/tables/exercises_table.dart` + `exercises_sync_service.dart`
(bilingual-ok Defaults).

## W5 — Hardcode-Gate dauerhaft scharf schalten

Erst wenn B1–B7 fertig sind:

- [ ] `python3 scripts/i18n_audit.py --gate` lokal ausführen → muss „GATE OK“ melden
      (0 sichtbare Hardcodes, 0 `de_DE`-Formatstellen).
- [ ] Makefile: `i18n-check`-Target um dritte Zeile `python3 scripts/i18n_audit.py --gate`
      ergänzen. Ab jetzt bricht `make release-readiness-mobile`, wenn je wieder ein
      deutscher Hardcode einzieht.
- [ ] `make release-readiness-mobile` komplett grün laufen lassen (Beweis im Tracker).
- [ ] Commit: `i18n: hardcode gate armed in release readiness (audit --gate)`.

## W6 — Visuelle Verifikation erweitern

- [ ] Mit dem etablierten Widget-Test-Harness (Muster: bestehende Evidence-Tests zu
      `docs/evidence/I18N-EN/`, FontLoader-Trick) zusätzliche EN-Screenshots erzeugen:
      Trainer-Dashboard, Trainer-Discovery, Chat-Inbox + Chat-Verlauf, Assessment
      (Fragebogen + Ergebnis), Bootstrap-Fehlerzustand. Ablage
      `docs/evidence/I18N-EN/07_…png` fortlaufend nummeriert, README dort ergänzen.
- [ ] Beide Umschaltwege erneut bestätigen (Erststart-Sprachwahl EN; laufender Wechsel in
      Settings greift sofort) — vorhandene Tests 01–03 decken das ab; nur neu rendern,
      falls sich betroffene Screens geändert haben.
- [ ] Layout-Pass: alle neuen EN-Screens auf Overflows/abgeschnittene Buttons sichten
      (Founder-Auflage: keine hässlichen Lücken). Auffälligkeiten fixen (Text kürzen nur
      im EN, nie im DE; sonst `FittedBox`/`maxLines`-Muster wie im Bestand).
- [ ] Commit: `test(i18n): EN evidence for trainer, chat, assessment + layout pass`.

## W7 — Runbook `docs/I18N_ADD_LANGUAGE.md` (Zukunftssicherung)

- [ ] Datei anlegen mit exakt diesem Gerüst (Platzhalter `xx` = neuer Sprachcode) und
      jeden Punkt gegen den realen Code verifizieren (Pfade/Namen müssen stimmen):

```markdown
# Runbook: Neue Sprache „xx“ hinzufügen

Reihenfolge einhalten; nach jedem Schritt bauen/testen. Aufwandstreiber ist der
Content (Schritt 5–7), nicht der Code.

1. **ARB:** `lib/l10n/app_en.arb` nach `lib/l10n/app_xx.arb` kopieren und übersetzen
   (Style Guide pro Sprache in `docs/GLOSSARY_DE_EN.md`-Manier ergänzen).
   `flutter gen-l10n`. `make i18n-check` erzwingt automatisch 100%-Parität.
2. **Registry:** In `lib/core/l10n/app_languages.dart` einen `AppLanguage`-Eintrag
   ergänzen (code, Autonym, Flagge). Damit erscheinen Sprachwahl-Screen, Settings,
   Login-Chips und `supportedLocales` automatisch korrekt.
3. **Qualitäts-Gate:** In `scripts/i18n_quality_check.py` einen `RULES_BY_LOCALE`-Block
   für `xx` ergänzen (Glossar, Schreibweisen, verbotene Claim-Begriffe der Zielsprache).
4. **Formatiersonderfälle:** Grep `AppLanguages.sourceCode` über `lib/` — die wenigen
   DE-Sonderformate (Datum kompakt etc.) prüfen: erbt `xx` das EN-Format korrekt?
5. **Content-Felder (Übungen, Fragebogen, PDF):** `pickLocalized` in
   `lib/core/l10n/localized_content.dart` um den `xx`-Zweig erweitern; Modelle
   (`exercise.dart`, `reflex_questionnaire*.dart`, `completion_questions.dart`,
   `ReflexProfilePdfCopy`) um `…Xx`-Felder ergänzen und übersetzen.
6. **Datenbank (Founder-gated!):** Migration für `_xx`-Spalten auf `exercises` +
   `reflex_packages` inkl. Seeds; `profiles.locale`-CHECK um 'xx' erweitern. Als 🔶 mit
   exakter SQL vorlegen — niemals eigenmächtig live anwenden.
7. **Server-Push:** `SupportedLocale`-Union in
   `supabase/functions/_shared/notification_copy.ts` + Copy-Blöcke in
   `reminder_copy.ts`/`notification_copy.ts` um `xx` ergänzen; Deno-Tests. Deploy bleibt
   Founder-gated.
8. **iOS:** `ios/Runner/xx.lproj/InfoPlist.strings` (alle Usage-Descriptions) +
   `knownRegions` im Xcode-Projekt.
9. **Audio:** `assets/sounds/announcements/xx/` einsprechen/beschaffen und in
   `pubspec.yaml` bündeln — bis dahin greift der dokumentierte Fallback.
10. **Außenwelt:** Store-Listing, Rechtstexte (Anwalt!), Support-Vorlagen, Website.
11. **Beweis:** EN-Screenshot-Harness für `xx` duplizieren →
    `docs/evidence/I18N-XX/`; `make release-readiness-mobile` grün.
```

- [ ] Querverweis auf das Runbook in `docs/I18N_EN_TRACKER.md` (Kopfbereich) und in
      `CLAUDE.md` §4 „Localization“ ergänzen — dabei in CLAUDE.md gleich den bekannten
      Fehler korrigieren: Template ist `app_de.arb`, nicht `app_en.arb`.
- [ ] Commit: `docs(i18n): add-a-language runbook + fix template note in CLAUDE.md`.

## W8 — Abschlussreport (Phase 6) + Übergabe

- [ ] `make release-readiness-mobile` final grün; Zahlen notieren (Tests, Keys je Katalog).
- [ ] In `docs/I18N_EN_TRACKER.md`: Phasen-Checkliste komplett abhaken (mit Evidenz),
      Abschlussreport in **einfachem Deutsch** für den Founder schreiben:
      1. Was ist jetzt vollständig zweisprachig (mit Screenshot-Verweisen und dem Satz
         „neue Sprache = 1 Datei + 1 Eintrag + Runbook“).
      2. Offene 🔶-Punkte, je mit Empfehlung: Anwalts-Texte (`consent_screen`,
         `training_disclaimer_dialog`, Verweis `docs/legal/ANWALTS_BRIEFING.md`);
         Edge-Function-Deploy der lokalisierten Push-Copy (ein „Go“ nötig);
         Live-DB-Verifikations-SQL für `_en`-Spalten (read-only, vorbereitet);
         fehlende EN-Announcement-Audios; Bild-/Asset-Restliste aus
         `docs/evidence/I18N-EN/ASSET_INVENTORY.md`; EN-Store-Texte (R3-Umfeld);
         Kalender-/Privacy-Inkonsistenz (siehe Tracker-Checkpoint).
      3. Glossar-Verweis für künftige Texte.
- [ ] `docs/LAUNCH_READINESS_BACKLOG.md` „Next up“ aktualisieren; Chat-Zusammenfassung in
      einfachem Deutsch ausgeben.
- [ ] Letzter Commit: `docs(i18n): final report — app fully bilingual, language system extensible`.

---

## Definition of Done (alles maschinell nachprüfbar)

- [ ] `make release-readiness-mobile` grün — inklusive des in W5 scharf geschalteten
      Hardcode-Gates (`i18n_audit.py --gate` = 0 Funde, 0 `de_DE`-Formatstellen).
- [ ] `grep -rn "== 'de'\|=='de'" lib --include="*.dart" | grep -v app_localizations | grep -v "core/l10n/"`
      → 0 Treffer; `grep -rn "Locale('de')\|Locale('en')" lib --include="*.dart" | grep -v "core/l10n/" | grep -v app_localizations`
      → 0 Treffer außerhalb der Registry.
- [ ] Sprachwahl-Screen, Settings-Sprachliste und Login-Chips rendern aus
      `AppLanguages.all` (Widget-Tests belegen es).
- [ ] `scripts/i18n_check.py` validiert jeden `lib/l10n/app_*.arb`-Katalog gegen das
      DE-Template (Python-Test mit Fixture-Katalog beweist es).
- [ ] EN-Evidenz-Screenshots decken zusätzlich Trainer, Chat, Assessment und den
      Bootstrap-Fehlerpfad ab; beide Umschaltwege belegt.
- [ ] `docs/I18N_ADD_LANGUAGE.md` existiert, alle Pfade/Namen darin real verifiziert.
- [ ] Tracker: alle Dateizeilen `verifiziert` oder `geflaggt – Anwalt`; Phasen 2–6
      abgehakt; Abschlussreport steht; `git status` zeigt keine offenen App-Dateien.
- [ ] Alle bewusst offenen Punkte als 🔶 mit Empfehlung im Report (Anwalt, Deploy-Go,
      Live-SQL, Audio, Assets, Store, Kalender/Privacy).
