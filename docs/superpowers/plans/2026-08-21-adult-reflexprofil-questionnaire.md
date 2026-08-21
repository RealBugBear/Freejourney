# Adult Reflexprofil Questionnaire (`adult_v3`) — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.
>
> **Executing without Superpowers (e.g. Cursor):** work phases in order. Do not modify child scoring/UI behavior unless a phase explicitly says so. Do not invent medical warning copy or hard-gate safety logic.

**Goal:** Ship a versioned adult (16+) self-report reflex questionnaire and a non-diagnostic Reflexprofil result experience that reuses the existing assessment infrastructure without regressing the live child parent-report flow.

**Architecture:** Stay inside `lib/features/assessment/`. Add an **adult-only** catalog + scoring engine + result presentation path. Keep child catalog, child bands, and child result chrome unchanged. Persist via existing Supabase tables (`reflex_subject_profiles`, `reflex_profile_assessments`) with new questionnaire/scoring version stamps. Gate movement checks and unfinished safety hard-blocks behind compile flags.

**Tech Stack:** Flutter + Riverpod + go_router; Supabase (online assessments, not Drift/outbox); SharedPreferences local drafts; ARB chrome + Dart-catalog question text (same pattern as child); `pdf` + `share_plus` for export.

**Spec / Quellen (Vorrang):**
- Maßgeblich Fragen/Mapping/Scoring: `docs/superpowers/specs/Reflexprofil_Erwachsenenfragebogen_adult_v3_Arbeitsfassung.docx` (extrahiert ausgewertet 2026-08-21)
- Ergänzend Produkt/UX/Sprache: `docs/superpowers/specs/Reflexprofil_Gesamtkonzept_adult_v2.docx`
- Sicherheit/Freigabeprozess: `docs/superpowers/specs/Reflexprofil_Sicherheitspruefung_Experten.docx` (liegt im Repo, siehe §8.2 — enthält **geprüfte Textentwürfe**, keine Freigabe)
- Bestehende Produktentscheidung „eine App, zwei Zielgruppen“: `docs/superpowers/specs/2026-08-05-eine-app-zwei-zielgruppen-design.md`
- Backlog-Eintrag: `docs/LAUNCH_READINESS_BACKLOG.md` → P2.A

**Revision 2026-08-21b (Review gegen die drei Quelldokumente).** Korrigiert: `possibleCount`-Pseudocode (§7.1), Ergebnis-Branch auf Version statt Typ (§10.4), Movement-Flag verändert Nenner ohne Versionsstempel (§7.5/§11.2), Filter-Antwort „?“ (§6.1), `f_handwriting`-ID-Liste (§5.3), Filtermodul-Enum (§5.2), Safety-Copy referenziert jetzt den Expertenentwurf statt eines Leer-Platzhalters (§8.2), Zeitmessung entkoppelt von Analytics-Consent (§11.4), Lücke „Medikamente“ ergänzt (§17). Nicht geändert (bewusste Founder-Entscheidung): Unter-16-Hinweis auf das Kinderprofil bleibt — der Kinderbogen ist ein **Elternbericht über ein Kind**, keine Selbstauskunft, und ist damit der richtige Verweis.

## Global Constraints

- Working directory: `/Users/alexandermessinger/dev/claudvibes/reflexjourney` only.
- No `git push`. No live DB mutations / function deploys without founder go.
- Copy: no diagnosis / healing / “Reflex aktiv” / guaranteed training effect language (CLAUDE.md §15 + adult_v2 Sprachregel).
- Never log answer bodies, names, emails, or safety details to Sentry/console.
- Child regression bar: existing `test/features/assessment/*` stay green; child bands and formulas unchanged.
- EN+DE for every new user-facing chrome string via ARB; question bodies follow child pattern (DE+EN fields on catalog objects).
- Do not activate movement checks or invent safety pop-up final copy until §17 blockers are cleared.

---

## 1. Executive Summary

Die App hat bereits ein vollständiges **Kinder-Reflexprofil** unter `lib/features/assessment/`: deklarativer Dart-Fragenkatalog, Equal-Weight-Scoring, Modul-Pager-UI, Server-Drafts + lokale Drafts, Supabase-Persistenz, Ergebnis-Screen mit Radar und PDF/Trainer-Share. Der Erwachsenenpfad ist vorbereitet (`adult_self` Profile, `adult_self_report` Constraint, For-Whom-Auswahl), aber UI-seitig mit „coming soon“ blockiert.

`adult_v3` liefert **87 Score-**, **4 Kontext-**, **10 Sicherheits-** und **2 Bewegungsitems** (103 gemappte IDs) in 13 Abschnitten, Antwortmodell Ja/Nein/?/n.z., Filterbedingungen, eigene Bandformulierungen, Amphibien-Sonderanzeige und **keinen öffentlichen Gesamtscore**. Die Kinder-Scoring-Engine und Bandschwellen **dürfen nicht** ungeprüft übernommen werden.

**Empfehlung:** Feature im bestehenden Assessment-Modul erweitern, aber **eigene** Versionen (`adult_v3` / `adult_equal_weight_v1`), eigene Scoring-Engine, eigene Ergebnisdarstellung und Feature-Flags für Bewegung/Sicherheits-Hardgate. Öffentliche Freigabe erst nach den Fachblockern in §17.

**State snapshot (Plan-Session 2026-08-21):** Branch `i18n/english-localization` mit unrelated dirty files (`android/settings.gradle.kts`, `firebase.json`, `pubspec.yaml`) plus untracked Invite/Supabase-Stub-Dateien — Adult-Arbeit darf diese Diffs nicht einsweepen.

---

## 2. Analyse der vorhandenen Kinder-Implementierung

### 2.1 Tech-Stack und Feature-Heimat

| Bereich | Fundstelle |
|--------|------------|
| Feature-Root | `lib/features/assessment/` |
| Domain-Typen | `domain/reflex_questionnaire.dart` |
| Kinderkatalog (109 Fragen) | `domain/reflex_questionnaire_definitions.dart` → `childParentQuestionnaireV1` (`child_parent_v2_2026_05`) |
| Demo-Kurzbogen | dieselbe Datei → `demoChildShortQuestionnaireV1` |
| Scoring | `domain/reflex_profile_scoring.dart` → `ReflexProfileScoringService`, Version stamp `score_equal_weight_v1` |
| Assessment-Model | `domain/models/reflex_profile_assessment.dart` |
| Drafts lokal | `domain/draft_persistence_service.dart` (`SharedPreferences` key `reflex_draft_$profileId`) |
| PDF | `domain/services/reflex_profile_pdf_service.dart` + `presentation/reflex_profile_pdf_copy.dart` |
| Provider | `presentation/providers/reflex_profile_provider.dart` |
| Fragebogen-UI | `presentation/screens/reflex_profile_screen.dart` (**hardcoded** `_definition => childParentQuestionnaireV1`) |
| Ergebnis-UI | `presentation/screens/reflex_profile_result_screen.dart` + `reflex_profile_result_helpers.dart` + `widgets/reflex_radar_chart.dart` |
| Routing | `lib/core/navigation/app_router.dart` → `/reflex-profile`, `/reflex-profile/result`, `/reflex-profile/demo` |
| Einstieg | `lib/features/onboarding/presentation/screens/for_whom_screen.dart` |
| Progress-Karte | `lib/features/progress/presentation/screens/progress_overview_screen.dart` (`_ReflexProfileCard`) |
| Flags | `lib/config/launch_flags.dart` — **kein** Reflexprofil-Flag heute |
| Theme | `lib/core/theme/app_colors.dart`, `app_theme.dart` (Light+Dark), `theme_provider.dart` |

**Nicht** Teil des Reflexprofils (nicht vermischen): Drift `intake_assessments`, `completion_questionnaires`, Analysis-Placeholder.

### 2.2 Persistenz (online, nicht Offline-First)

Tabellen (Migrationen `supabase/migrations/2026050101_reflex_profile_foundation.sql`, `20260510_reflex_profile_questionnaire_v1.sql`, Alters-Snapshot `2026051101_…`):

- `reflex_subject_profiles` — `profile_type IN ('child','adult_self')`
- `reflex_profile_assessments` — `questionnaire_type` inkl. `adult_self_report`, `scoring_version`, `answers`/`scores` JSONB, `status` draft/skipped/completed, `warning_confirmations`, `safety_status`
- `reflex_profile_trainer_shares`, `reflex_subject_profile_notes`

RPCs: `submit_reflex_profile_assessment`, Draft-Save/Load, `get_latest_reflex_profile_assessment`, Admin-Rollups.

### 2.3 Kinder-Scoring (nicht 1:1 für Adult verwenden)

- Nur `role == score` mit nicht-leeren `reflexes`
- Ja zählt positiv; **keine Polung**
- `unknown` / unbeantwortet: nicht im Nenner
- Bänder: strong ≥100, elevated ≥80, indication ≥50, sonst inconspicuous; `answeredCount==0` → insufficientData
- Warnungen: `professionalClearanceRequired` bei Ja → `warningQuestionIds`; manche Safety-Items tragen trotzdem Reflexe und scoren mit

### 2.4 Kinder-UX

- For-Whom → Kindprofil wählen/anlegen → **Modul-Pager** (8 Module, **mehrere Fragen pro Screen**) → Submit → Ergebnis
- Antworten: Ja / Nein / Weiß ich nicht (3 Buttons); kein „trifft nicht zu“
- Auto-Save: Debounce + Lifecycle Pause → Server-Draft + lokal
- Adult-Zweig: `_buildAdultComingSoon()`
- Bedingte Sichtbarkeit heute nur: `q032` wenn `q031 == no`

### 2.5 Ergebnis / Verlauf / Analytics

- Ergebnis: Titel „Hinweisstärken“, Disclaimer, Radar, farbige Bänder (error/warning/primary/success), PDF, Trainer-Share
- Verlauf: **nur latest completed** pro Subject in Progress — keine Timeline-UI
- Product Analytics: **keine** Event-Hooks im Assessment-Flow; Admin-Aggregate + Sentry errors-only

### 2.6 Tests

- `test/features/assessment/reflex_profile_scoring_test.dart`
- `reflex_questionnaire_localization_test.dart`
- `domain/draft_persistence_service_test.dart`
- `presentation/screens/reflex_profile_result_helpers_test.dart`
- Kein voller Widget-Flow-Test für `ReflexProfileScreen`

### 2.7 Wiederverwenden / erweitern / trennen

| Wiederverwenden | Erweitern | Trennen / neu |
|-----------------|-----------|---------------|
| Subject-Profile + RPCs + Draft-Pattern | `ReflexQuestion` (Polung, Applicability, ItemRole movement) | Adult-Katalogdatei |
| Provider-Helfer create/submit/draft/share | Answer-JSON (`not_applicable`) | Adult-Scoring-Engine + Bänder |
| Modul-Pager-Shell, Progress, Clearance-Dialog-Gerüst | `ReflexProfileScreen` Definition-Routing | Adult-Ergebnis-Widgets (Balken, Detail-Expansion) |
| PDF/Share-Pipeline (Copy adult-spezifisch) | Progress/ForWhom Adult-Unlock | Bewegungsteil hinter Flag |
| Theme/Colors/l10n-Chrome-Pattern | `PrimitiveReflex` + Amphibien | Kinderkatalog/Kinderbänder unangetastet |
| Dark Mode Theme | Optional History-Provider | Intake/Completion |

---

## 3. Empfohlene Zielarchitektur

```
ForWhom / Progress / Training
        │
        ▼
ReflexProfileScreen
  ├─ child  → childParentQuestionnaireV1 + Child scoring (unverändert)
  └─ adult  → adultSelfQuestionnaireV3 + AdultScoringService
        │ filters hide items; drafts save answers + filter state
        ▼
submit_reflex_profile_assessment
  questionnaire_type = adult_self_report
  questionnaire_version = adult_v3
  scoring_version = adult_equal_weight_v1
        │
        ▼
Adult result path (branched in result screen)
  horizontal bars + expandable reflex details
  no total score; amphibian special display
        │
        ▼ (optional later)
History for same person + compatible versions
```

**Entscheidungsprinzipien**

1. **Ein Feature-Modul**, zwei Questionnaire-Definitionen — keine zweite App (bereits Founder-Entscheidung 2026-08-05).
2. **Scoring-Engines getrennt** (`ReflexProfileScoringService` child vs. `AdultReflexProfileScoringService`) — schützt vor Band-/Polungs-Regression.
3. **Versionierung ist Pflichtfeld** auf jeder Assessment-Zeile; Neuberechnung nur mit gespeicherter `scoring_version` + eingefrorenem Katalog-Snapshot der Version.
4. **Bewegung default OFF** (`kAdultMovementChecksEnabled = false`).
5. **Safety: soft hint only** bis Expertenfreigabe; kein Hard-Block, keine erfundenen Warntexte (`kAdultSafetyHardGateEnabled = false`).

---

## 4. Unterschiede Kinderprofil vs. Erwachsenenprofil

| Dimension | Kind (live) | Adult `adult_v3` |
|-----------|-------------|------------------|
| Berichtsart | Elternbericht | Selbstbericht ab 16 |
| Item-IDs | `q001`… | `s*` / `a*` (+ geplante Filter-IDs `f*`) |
| Module | 8 (Schwangerschaft…Sonstiges) | Filtermodul + 11 Inhaltskapitel + Safety + optional Movement (= 14 Enum-Werte) |
| Antworten | Ja/Nein/? | Ja/Nein/?/**n.z.** |
| Polung | keine | Feld vorhanden; in v3 Score-Items alle `d`, Movement `i` |
| „trifft nicht zu“ | fehlt | eigener Persistenzwert, aus Zähler+Nenner |
| Filter | 1 Follow-up | 7 Lebenslagen-Filter |
| Bänder | 50/80/100 + strong@100 | 0–29 / 30–59 / 60–79 / 80–100 mit neuen Labels |
| Amphibien | nicht im Enum | Sonderanzeige 0/1/2 von 2 |
| Gesamtscore | nicht prominent, aber Radar aggregiert Eindruck | **explizit verboten** öffentlich |
| Safety→Score | teils mit Reflexen | nur wenn Mapping Reflexe nennt; ADHS → nur ATNR/STNR |
| Visual | Radar + alarmnahe Farben | ruhige Balken + Textkategorien |
| Sprache Ergebnis | „Hinweisstärken“ / strong/elevated… | „passende Angaben“ / „Antwortmuster“ / „Hinweiswert“ |

---

## 5. Datenmodell und versionierter Fragenkatalog

### 5.1 Versionsstempel

| Feld | Wert |
|------|------|
| `questionnaireVersion` | `adult_v3` |
| `questionnaire id` | `adult_self_reflex_profile` |
| `scoringVersion` | `adult_equal_weight_v1` |
| `questionnaire_type` (DB) | `adult_self_report` |
| `minAgeYears` | 16 |
| `audience` | `adult_self` |

Jede inhaltliche oder Formeländerung → neue Versionsstrings (nie stille Mutation).

### 5.2 Erweiterungen an Domain-Typen (`reflex_questionnaire.dart`)

```dart
enum ReflexItemPolarity { direct, inverse }

enum ReflexAnswerChoice { yes, no, unknown, notApplicable }

enum AdultQuestionModule {
  lifeContext,          // Filtermodul „Deine Lebenssituation" (§9.2 Schritt 4).
                        // Nicht im Kapitelindex von adult_v3 — App-eigenes Modul,
                        // enthält ausschließlich die sieben f_*-Items.
  sensory,
  postureSitting,
  motorCoordination,
  workScreenFocus,
  drivingOrientationTravel,
  sportBalanceFeet,
  speechMouthJaw,
  writingFineMotor,
  readingLearningOrientation,
  behaviorStressEmotion,
  sleepDigestionBody,
  safety,
  movementOptional,
}

enum AdultHintBand {
  fewMatching,          // 0–29
  someMatching,         // 30–59
  clusteredPattern,     // 60–79
  stronglyClustered,    // 80–100
  insufficientData,     // denominator 0
}

enum AmphibianDisplay {
  noneMatching,   // 0/2
  singleHint,     // 1/2
  clearSingleHint // 2/2
}

enum ApplicabilityFilter {
  swims,
  screenWork,
  deskWork,
  drives,
  ridesAsPassenger,
  handwriting,
  toolUse,
  afterSafetyCleared, // movement only
}
```

`ReflexQuestion` Erweiterungen (rückwärtskompatibel für Kind):

- `polarity` (default `direct`)
- `role` um `movement` ergänzen **oder** separates `isMovement` + bestehendes `ReflexQuestionRole` belassen und movement als `context`-ähnliche Rolle mit Flag — **Empfehlung:** `ReflexQuestionRole.movement` hinzufügen
- `requiresFilters: Set<ApplicabilityFilter>` (alle müssen „ja/anwendbar“ sein)
- `approvalStatus` optional: `draft | expertPending | approved` (für interne Markierung; UI-Publish nur approved Score-Items)
- `evidenceLevel` optional A–E aus Gesamtkonzept (nicht nutzerseitig nötig für v1)

`ReflexAnswerValue`:

- Beibehalten von `yesNoUnknown` + `isUnknown` für Kind
- Neu: `isNotApplicable` **oder** besser Unified: `ReflexAnswerChoice? choice` mit Migration Helpers
- Serialisierung Adult: `"answer": "yes"|"no"|"unknown"|"not_applicable"`
- Kind-JSON unverändert lassen (`yes`/`no`/`unknown`)

`PrimitiveReflex`: **`amphibian` hinzufügen**. Kind-Katalog mappt es nicht → erscheint in Kind-Scores nicht (`possibleCount == 0` filter).

`PrimitiveReflex.delay` bleibt kind-spezifisch; Adult-Ergebnis listet nur Reflexe mit `possibleCount > 0` im Adult-Katalog.

### 5.3 Katalogdatei

**Neu:** `lib/features/assessment/domain/adult_reflex_questionnaire_definitions.dart`

- Konstante `adultSelfQuestionnaireV3`
- Helpers analog `_q` / `_context` / `_safety` / `_movement` / `_filter`
- 13 Module in Dokumentreihenfolge
- DE-Texte 1:1 aus adult_v3; EN-Texte professionell übersetzen (ARB nicht für Fragetexte — Kind-Pattern)

**Filter-Items (im Dokument als Bedingung, nicht als eigene ID):**

Im Katalog **neu einführen** als `role: context`, `answerType: yesNoUnknown` (ohne n.z. oder mit n.z.=nein-Äquivalent), stabile IDs:

| Filter-ID | Steuert | Empfohlener Fragetext (DE, Platzhalter bis Copy-Freigabe) |
|-----------|---------|-----------------------------------------------------------|
| `f_swim` | `s030` | Hast du Schwimmerfahrung? |
| `f_screen` | `a025`, `a027` | Arbeitest du regelmäßig am Bildschirm? |
| `f_desk` | `a036` | Arbeitest du regelmäßig am Schreibtisch? |
| `f_drive` | `a040`, `a042` | Fährst du selbst Auto? |
| `f_passenger` | `a043` | Sitzt du regelmäßig als Mitfahrer:in im Auto? |
| `f_handwriting` | `s061`, `s066`, `s068`, `s069`, `s070`, `s072`, `s073`, `s074`, `a074` — **9 Items, kein Bereich**: `s067` und `s071` wurden in adult_v3 Teil C gestrichen und existieren nicht | Schreibst du regelmäßig von Hand? |
| `f_tools` | `a068` | Nutzt du regelmäßig Werkzeuge (z. B. Schere, Schraubendreher)? |

**Blocker-Hinweis:** Filter-Wortlaut ist **nicht** in adult_v3 kanonisch — vor Launch kurze Copy-Freigabe. Technisch unverzichtbar, sonst bleibt nur „n.z.“ als Ausweichventil (Dokument will Filter bevorzugen).

### 5.4 Mapping-Übernahme (Score-Auszug)

Vollständige Mapping-Tabelle steht in adult_v3 Teil B.4 — 1:1 in den Katalog übernehmen. Kritische Mehrfachzuordnungen (>3 Reflexe) **markieren** `approvalStatus: expertPending`:

- `s029` → Moro, TLR, ATNR, STNR
- `s063` → STNR, Babkin, Plantar, Palmar, Such-Saug
- zusätzlich `s023`, `s072`, Movement `s005`/`s006`

Amphibien: `s017` (auch Galant+STNR), `s102` (nur Amphibien).

Safety: `s046` ADHS/ADS → ATNR+STNR scorewirksam; alle anderen Safety ohne Reflexe → kein Score.

Movement: `s005`/`s006` inverse, multi-reflex, nur nach Safety — **Flag OFF**.

### 5.5 Ergebnis-Copy-Modell (für Detail-Expansion)

**Neu (v1 minimal):** `lib/features/assessment/domain/adult_reflex_result_copy.dart`

Pro `PrimitiveReflex` (Adult-relevant):

- `shortDescriptionDe/En`
- `alternativeExplanationsDe/En`
- `limitsDe/En`
- `optionalPhysicalCheckHintDe/En`

Texte aus Gesamtkonzept-Anforderungen; **keine** Ursachen-/Diagnoseformulierungen. Fehlende Fachtexte → neutrale Platzhalter + `expertPending`, nicht erfinden.

---

## 6. Filter- und Fragebogen-Flow

### 6.1 Sichtbarkeitsregeln

```
visible(item) =
  item.role != movement OR kAdultMovementChecksEnabled
  AND all(filters in item.requiresFilters are NOT answered "no")
     // "yes" und "?" blenden ein; nur explizites "Nein" blendet aus
  AND if movement: safety module completed AND soft-policy allows offer
```

- **Nur explizites „Nein“ auf eine Filterfrage blendet die abhängigen Items aus** (nicht als n.z. vorbefüllt).
- **„?“ auf eine Filterfrage blendet NICHT aus** — die abhängigen Items werden gezeigt. Begründung: Gesamtkonzept §4 trennt bewusst „weiß ich nicht“ (fehlendes Wissen) von „trifft auf mich nicht zu“ (Lebenssituation nicht gegeben). Ausblenden bei „?“ würde das eine still in das andere umdeuten und Informationen vernichten, die die Person auf Itemebene sehr wohl beantworten kann. Wirkungsgröße: `f_handwriting` steuert allein 9 der 87 Score-Items (~10 %) — ein einzelnes „?“ auf Filterebene würde mehrere Reflexprozente spürbar verschieben. Die Person kann pro Item weiterhin „?“ oder „n. z.“ wählen; beide fallen ohnehin aus Zähler und Nenner.
- Filterantwort selbst wird persistiert (`yes` / `no` / `unknown`), damit die Sichtbarkeitsentscheidung reproduzierbar bleibt und `possibleCount` nachvollziehbar ist.
- Bereits beantwortete abhängige Items bei Filter-Wechsel auf Nein: Antwort **behalten im Draft**, aber als `superseded_by_filter` markieren und **nicht scoren**; bei erneutem Ja wieder einblenden mit alter Antwort (editierbar)
- „n.z.“ bleibt manuell möglich für Items ohne Filter oder wenn Filter Ja aber Situation trotzdem nicht passt

### 6.2 Fortsetzen / Abbruch

Bestehenden Mechanismus erweitern:

- Server draft + local draft speichern: `answers`, `warning_confirmations`, `current_module_index`, `questionnaire_for=adult`, **neu** `questionnaire_version`, `filter_answers` (redundant in answers), `started_at`, optional `module_timings`
- Resume-Dialog unverändert nutzbar
- Abbruch: Draft behalten; kein completed-Row
- Submit nur wenn alle **sichtbaren** Pflicht-Score/Context/Safety-Items beantwortet (Movement optional/skip)

### 6.3 Zusammenfassung vor Absenden

Neuer Zwischenschritt (Adult):

- Anzahl beantworteter / übersprungener / ausgeblendeter Items
- Hinweis: Profil zeigt Antwortmuster, keine Diagnose
- Liste offener sichtbarer Fragen → Deep-Link zurück ins Modul
- Safety: „Du hast X sicherheitsrelevante Angaben gemacht“ **ohne** Details in Logs

---

## 7. Scoring-Spezifikation mit Pseudocode

### 7.1 Reguläre Reflexwerte

```
for each score-contributing item mapped to reflex R:
  if item not visible under filters: skip entirely (not in possible/answered)
  possibleCount += 1   # JEDES sichtbare Item zählt hier — beantwortet oder nicht.
                       # (Revision 2026-08-21b: stand vorher fälschlich nur im
                       #  unbeantwortet-Zweig, wodurch possibleCount die Anzahl der
                       #  UNbeantworteten Items ergeben hätte statt der sichtbaren.)
  if answer in {unknown, not_applicable, missing}: 
      # possibleCount ist oben bereits gezählt; answeredCount bleibt unverändert
      continue
  answeredCount += 1
  indication = 
    if polarity == direct:  (answer == yes ? 1 : 0)
    if polarity == inverse: (answer == no  ? 1 : 0)
  yesCount += indication   # name kept as "positiveIndicationCount"

hintPercent = answeredCount == 0 ? null : round1(100 * yesCount / answeredCount)
band = bandFor(hintPercent) // see thresholds
```

**possibleCount-Politik (festlegen und testen):**

- **Empfehlung A (bevorzugt, entschieden):** `possibleCount` = Anzahl Score-Items für R, die unter **aktuellen Filtern sichtbar** sind. Ausgeblendete zählen nicht.
- Es gilt immer `answeredCount <= possibleCount`. Unbeantwortete sichtbare Items erhöhen nur `possibleCount` → Coverage „7 von 9 Merkmalen beantwortet“ (`answered_count: 7`, `possible_count: 9`).
- **Invariante als Test festhalten:** für jeden Reflex `answered_count + unknown + not_applicable + missing == possible_count`. Genau diese Invariante hätte den Pseudocode-Fehler der Erstfassung gefangen.
- `possibleCount` hängt vom Flag `kAdultMovementChecksEnabled` ab (Movement-Items mappen 5–6 Reflexe). Siehe §7.5 `meta.movement_included` und §11.2 — ein Flag-Flip macht Ergebnisse **nicht** vergleichbar, obwohl beide Versionsstrings gleich bleiben.

**Rundung:** Anzeige als ganze Zahl mit `round()` half-up; intern `double` speichern. Stabile Tests mit exakten Brüchen (z. B. 1/3 → 33).

**Nenner 0:** `insufficientData` / keine Prozentzahl; Copy „Keine ausreichende Datengrundlage“.

### 7.2 Rollen

| Role | Score? |
|------|--------|
| score + reflexes≠∅ | ja |
| context | nein |
| safety + reflexes≠∅ | ja (nur s046 in v3) |
| safety + reflexes=∅ | nein |
| movement | nur wenn Flag ON und explizit in Engine-Allowlist; default nicht scoren in öffentlicher Version |

**Falle für Phase 4 (nach Phase-2-Review festgestellt): `ReflexQuestion.contributesToScore` darf die Adult-Engine NICHT verwenden.** Der Getter lautet `role == ReflexQuestionRole.score && reflexes.isNotEmpty` ([`reflex_questionnaire.dart:350`](../../../lib/features/assessment/domain/reflex_questionnaire.dart)). Im Kinderkatalog funktioniert das nur, weil der Helfer `_warning()` Sicherheitsfragen **mit** Reflexen kurzerhand als `role: score` anlegt ([`reflex_questionnaire_definitions.dart:839`](../../../lib/features/assessment/domain/reflex_questionnaire_definitions.dart)). Der Adult-Katalog macht es korrekt: `s046` ist `role: safety` mit `[atnr, stnr]` — `contributesToScore` liefert dafür **`false`**. Wer den Getter wiederverwendet, lässt ADHS still aus ATNR und STNR herausfallen, ohne dass ein Test anschlägt.

Die Adult-Engine braucht ein eigenes Prädikat:

```dart
bool _adultScores(ReflexQuestion q, {required bool movementEnabled}) =>
    q.reflexes.isNotEmpty &&
    switch (q.role) {
      ReflexQuestionRole.score => true,
      ReflexQuestionRole.safety => true,       // in adult_v3 genau s046
      ReflexQuestionRole.movement => movementEnabled,
      ReflexQuestionRole.context => false,
    };
```

Test 7 (§14.1) prüft das direkt: `s046` mit „ja“ muss ATNR und STNR erhöhen und sonst nichts.

### 7.3 Bänder

| % | Band-ID | Nutzertext |
|---|---------|------------|
| 0–29 | fewMatching | Wenige passende Angaben |
| 30–59 | someMatching | Einzelne passende Angaben |
| 60–79 | clusteredPattern | Gehäuftes Antwortmuster |
| 80–100 | stronglyClustered | Stark gehäuftes Antwortmuster |

Grenztests: 29→few, 30→some, 59→some, 60→clustered, 79→clustered, 80→strong.

### 7.4 Amphibien

Separater Pfad: Items `s017`+`s102` die Amphibien mappen (s017 mappt zusätzlich andere Reflexe — für Amphibien-Bucket nur Amphibien-Anteil zählen; für Galant/STNR normales Scoring).

```
amphAnswered = count applicable yes/no on amphibian-mapped items
amphPositive = count positive indications
display =
  0 → Kein passender Einzelhinweis
  1 → Einzelner Hinweis
  2 → Deutlicher Einzelhinweis
do NOT show percent bar as primary for amphibian
```

> **Founder-Entscheidung 2026-08-21 — überschreibt den Zusatztext aus adult_v3 Teil B §2.**
> Der Amphibienblock bekommt **keinen** eigenen Erklär- oder Rechtfertigungstext. Kein „Aufgrund der wenigen verfügbaren Merkmale …“, kein Hinweis auf fehlende wissenschaftliche Belastbarkeit, kein abgesetzter Warnkasten. Begründung des Founders: das liest sich wie eine Entschuldigung und lässt das Ergebnis halbfertig wirken; gewünscht ist schlicht **eine andere Darstellungsform derselben Auswertung**.
> Der Seiten-Disclaimer oben („Das sind nur deine subjektiven Antwortmuster. Sie sind kein Reflexnachweis und keine Diagnose.“) deckt den Block mit ab — eine Wiederholung nur unter diesem einen Reflex ließe ihn wie einen Problemfall aussehen.
> Diese Abweichung ist bewusst und muss der Expertenprüfung (§17) **als Entscheidung vorgelegt** werden, nicht als Versehen. Darstellungsvorgabe: §10.2b.

**Nachtrag aus dem Phase-4-Review: `display` darf nicht allein aus `positiveCount` abgeleitet werden.**

Die Erstfassung oben bildet `0 → Kein passender Einzelhinweis` ab, ohne `answeredCount` anzusehen. Damit liefert der Fall „beide Amphibien-Items mit `?` oder `n. z.` beantwortet“ (`answeredCount == 0`, `positiveCount == 0`) die Anzeige **„Kein passender Einzelhinweis“** — eine Aussage über die Person, für die keine Datengrundlage existiert. Das ist derselbe Fehler, den die regulären Reflexe über `insufficientData` bereits vermeiden; Amphibien haben bisher kein Gegenstück.

Erreichbar ist der Fall regulär: `?` und `n. z.` gelten nach §6.2 als beantwortet, der Submit-Gate greift also nicht.

Korrigierte Regel:

```
if amphAnswered == 0 → AmphibianDisplay.insufficientData
                       Copy: „Keine ausreichende Datengrundlage"
else 0 positive      → Kein passender Einzelhinweis
     1 positive      → Einzelner Hinweis
     2 positive      → Deutlicher Einzelhinweis
```

`AmphibianDisplay` bekommt dafür einen fünften Wert `insufficientData`. Phase 7 zeigt zusätzlich immer „X von Y beantwortet“ mit dem **tatsächlichen** `answeredCount` — nie „X von 2“, wenn nur eines der beiden Items beantwortet wurde.

Test: beide Items `unknown` → `insufficientData`; beide `notApplicable` → `insufficientData`; eines `unknown` + eines `no` → `noneMatching` mit `answeredCount == 1`.

**Nicht actionable, aber notiert:** Band und gerundeter Anzeigewert könnten theoretisch auseinanderfallen (`percent` 29,6 → Band „wenige“, Anzeige „30 %“). Für alle Nenner 1–24 ist das rechnerisch unmöglich, und der größte Adult-Reflex (STNR) hat 19 mögliche Items. Sollte `adult_v4` einen Reflex über 24 Items bringen, hier erneut prüfen.

### 7.5 Scores-JSON (Persistenz)

```json
{
  "scoring_version": "adult_equal_weight_v1",
  "questionnaire_version": "adult_v3",
  "reflexes": {
    "moro": {
      "positive_count": 3,
      "answered_count": 7,
      "possible_count": 9,
      "percent": 42.857,
      "percent_display": 43,
      "band": "someMatching"
    }
  },
  "amphibian": {
    "positive_count": 1,
    "answered_count": 2,
    "display": "singleHint"
  },
  "meta": {
    "hidden_item_ids": ["a040"],
    "not_applicable_item_ids": ["a068"],
    "unknown_item_ids": ["s034"],
    "no_public_total_score": true,
    "movement_included": false,
    "filter_answers": { "f_swim": "yes", "f_drive": "no", "f_handwriting": "unknown" }
  }
}
```

Child scores JSON shape bleibt unverändert (`yes_count`, `band` names strong/elevated/…).

**`meta.movement_included` ist Pflicht (Revision 2026-08-21b).** `kAdultMovementChecksEnabled` ist ein Compile-Flag und verändert `possibleCount` für FLR, Moro, TLR, ATNR, Aufricht und Babinski — **ohne** dass sich `questionnaire_version` oder `scoring_version` ändern. Ohne dieses Feld würde §11.2 zwei nach unterschiedlicher Methode berechnete Profile als vergleichbar behandeln. Regeln:

- Beim Submit den effektiven Flag-Zustand schreiben (nicht den Wunschzustand).
- Verlaufsvergleich und Diff verlangen Gleichheit von `questionnaire_version` **und** `scoring_version` **und** `meta.movement_included`.
- Fehlt das Feld auf einer Zeile (Alt-/Fremdzeile), gilt der Vergleich als unzulässig — nicht `false` annehmen.

`meta.filter_answers` dupliziert die f_*-Antworten bewusst in die Scores, damit ein Ergebnis ohne Rückgriff auf `answers` erklärbar bleibt („diese Items wurden ausgeblendet, weil …“).

### 7.6 Pseudocode Engine-API

```dart
class AdultReflexProfileScoringService {
  AdultQuestionnaireScore score({
    required ReflexQuestionnaireDefinition definition, // must be adult_v3
    required Map<String, ReflexAnswerValue> answers,
    required Set<ApplicabilityFilter> activeFilters,
  });
}
```

Assert `definition.version == 'adult_v3'` und `definition.type == adultSelfReport` — wirft/fails tests if child definition passed.

---

## 8. Sicherheits- und Feature-Flag-Konzept

### 8.1 Neue Flags in `lib/config/launch_flags.dart`

```dart
/// Adult Vollfragebogen (P2.A). false = coming soon bleibt.
const bool kAdultReflexQuestionnaireEnabled = true; // nach interner QA; Store-Rollout separat

/// Freiwillige Bewegungsprüfungen s005/s006. Default false bis Expertenfreigabe.
const bool kAdultMovementChecksEnabled = false;

/// Harte Sperr-/Freigabelogik nach Safety-Antworten. Default false —
/// nur neutrale situationsbezogene Hinweise, keine Trainings-/Bewegungssperre.
const bool kAdultSafetyHardGateEnabled = false;
```

Doc-Comments: gated surfaces auflisten (wie bei Community/Video).

### 8.2 Safety-Verhalten bis Freigabe

- Zeige Safety-Modul **nach** Inhaltsmodulen, **vor** optionalem Bewegungsteil
- Bei Ja auf relevanter Safety-Frage: Dialog mit dem **Textentwurf aus `Reflexprofil_Sicherheitspruefung_Experten.docx` §6**, nicht mit einem selbst formulierten Text und nicht mit einem inhaltsleeren Platzhalter. Der Entwurf ist fachlich vorformuliert, aber **noch nicht abgenommen** (Abnahmebogen §10 dort ist ungezeichnet) → im Code als `expertPending` markieren:

  > „Deine Angabe kann bedeuten, dass einzelne Bewegungen oder Trainingsübungen angepasst oder vorher fachlich besprochen werden sollten. Dieses Ergebnis bewertet deine Diagnose nicht.“

  **Wichtig:** Der Originalentwurf endet mit „Führe die gekennzeichneten Übungen nicht ohne die hier empfohlene Rücksprache durch.“ Dieser Satz setzt gekennzeichnete Übungen voraus — die gibt es erst mit `kAdultMovementChecksEnabled = true`. Solange das Flag AUS ist, **den Satz weglassen** (er hätte keinen Bezug); mit Flag AN gehört er dazu. Kein Umformulieren, nur Weglassen/Anhängen.

- Text vor dem freiwilligen Bewegungsteil ebenfalls 1:1 aus dem Expertendokument §6 („Die folgenden Bewegungen sind freiwillig und ersetzen keine Untersuchung. …“). Wird erst mit dem Movement-Flag sichtbar.

- **Bestätigung:** darf laut Expertendokument §6 ausschließlich dokumentieren, **dass der Hinweis angezeigt wurde**. Keine Copy, die Verantwortung auf die Person überträgt („Ich bestätige, dass ich auf eigene Gefahr …“) — das wäre zusätzlich nach BGB § 309 Nr. 7 angreifbar. Zulässig: „Hinweis gelesen.“

- **Zielstruktur `safety_status` ist bekannt, aber noch nicht freigegeben:** Stufe A (Stop), B (Rücksprache), C (Vorsicht) aus Expertendokument §3. In v1 **nicht** implementieren — die Zuordnung Frage → Stufe ist genau der offene Punkt (§11.1 dort). v1 speichert nur „Hinweis gezeigt/bestätigt“, ohne Stufe.
- **Nicht** implementieren: automatische Trainingssperre, Notfallnummern-Erfindung, Diagnosehinweise
- `warning_confirmations` speichern mit `message_version: 'adult_safety_expertdraft_v0'` (Entwurfstand des Expertendokuments; nach Abnahme → `_v1`, damit alte Bestätigungen nicht als Zustimmung zum finalen Text gelten)
- `safety_status`: bestehende Werte wiederverwenden; neue Enum-Werte nur per Migration wenn Hardgate kommt

### 8.3 Bewegungsteil

- UI-Entry nur wenn `kAdultMovementChecksEnabled`
- Sonst: Abschnitt unsichtbar; Skip implizit
- Wenn Flag später true: eigener Screen nach Safety, großer Skip-CTA, inverse Scoring nur dann in Engine

---

## 9. UX-Konzept des Fragebogens

### 9.1 Entscheidung: mehrere Fragen pro Screen (Modul-Pager)

**Begründung:** Die Kinder-UX nutzt bereits Module mit mehreren Items + Progress; Zielzeit 12–15 Min bei ~87+ Items + Filter macht One-Question-Per-Screen (~100 Screens) zu langsam und abweichend. Adult übernimmt Modul-Pager mit 11+1(+1) Kapiteln aus adult_v3, großen 2×2-Antwortflächen (Ja/Nein/?/n.z.), ausreichendem Kontrast (Theme Light/Dark), Semantik für Screenreader.

### 9.2 Ablauf

1. Einstieg: nicht-diagnostischer Zwecktext (adult_v2 §1)
2. Kind vs. Adult (bestehende For-Whom / Screen-Auswahl); Adult nur wenn Flag
3. Adult-Profil: Name + Geburtsdatum; **Gate Alter ≥ 16** (berechnet), sonst Hinweis auf Kinderprofil / Ablehnung
4. Filter-Block früh (kurz, ein Modul „Deine Lebenssituation“) **oder** Filter inline vor dem ersten abhängigen Kapitel — **Empfehlung:** eigenes kurzes Filter-Modul direkt nach Intro
5. Kapitel 1–11
6. Safety
7. Optional Movement (flag)
8. Summary → Submit → Adult Result

### 9.3 Interaktion

- Auto-Save wie Kind
- Zurück: Antworten bleiben
- Fortschritt: Module + optional Item-Zähler „42 / 78 sichtbare Angaben“
- n.z. und ? visuell sekundär, aber gleichermaßen erreichbar (Barriere)

---

## 10. Detaillierte Spezifikation des Reflexprofil-Screens

### 10.1 Übersicht („Dein Reflexprofil“)

Komponenten (neu, Adult-Branch in Result Screen oder `adult_reflex_profile_result_screen.dart`):

- Titel: **Dein Reflexprofil**
- Subline: Erwachsenenprofil · Datum · `adult_v3` / `adult_equal_weight_v1`
- Disclaimer: subjektive Antwortmuster; kein Nachweis; keine Diagnose
- **Kein** Gesamtscore, **kein** Durchschnitts-Radar als Gesamtnote (Radar optional später nur als Multi-Achsen-Übersicht ohne „Gesamt %“ — **Empfehlung v1:** kein Radar, horizontale Balken)
- Liste Reflexe sortiert nach `percent` desc; Amphibien als **letzte Karte derselben Liste** — kein eigener Abschnitt, keine eigene Überschrift (§10.2b)
- Pro Zeile: Name, Prozent oder Amphibien-Text, Band-**Text**, „7 von 9 Merkmalen beantwortet“, Unsicherheitshinweis wenn coverage niedrig oder band insufficient
- Farbe: eine neutrale Primärfarbe + Graustufen; **kein** Rot=schlecht / Grün=gut Mapping. Farbe nie alleinige Information

### 10.2 Expandierbare Detailkarte

- Reflexname + Kurzbeschreibung
- Hinweisstärke (Bandtext + %)
- Datengrundlage
- Passende eigene Angaben (Item-Texte wo positive Indication)
- Alternativerklärungen
- Grenzen
- Optional: Hinweis auf persönliche körperliche Überprüfung durch qualifizierte Person
- **Keine** Trainingserfolgsversprechen

### 10.2b Amphibien-Darstellung (Founder-Entscheidung 2026-08-21)

Der Amphibienreflex ist **kein Sonderfall im Layout**, sondern nur eine andere Messart. Er steht als letzte Karte in derselben Reflexliste, im selben Kartendesign wie alle anderen.

| | Regulärer Reflex | Amphibien |
|---|---|---|
| Anzeige des Werts | horizontaler Prozentbalken | **zwei Punkte** nebeneinander, einer je Item; gefüllt = passende Angabe |
| Textzeile | „60 % · Gehäuftes Antwortmuster“ | „Einzelner Hinweis“ (bzw. Kein passender / Deutlicher Einzelhinweis) |
| Datengrundlage | „5 von 6 Merkmalen beantwortet“ | „2 von 2 beantwortet“ — echtes `answeredCount` |
| Zusatztext | keiner | **keiner** |
| Ohne Antworten | „Keine ausreichende Datengrundlage“ | schlicht **„Keine Angaben“** |

Verboten in diesem Block: Erklärtexte zur Aussagekraft, Hinweise auf die geringe Itemzahl, Warnkästen, abweichende Hintergrundfarbe, doppelte Nennung des Reflexnamens (Abschnittsüberschrift **und** Kartentitel).

Der Seiten-Disclaimer oben gilt für die gesamte Liste, Amphibien eingeschlossen. Siehe die Begründung in §7.4.

### 10.2a Einladungs-Impuls im Adult-Ergebnis (Founder-Entscheidung 2026-08-21)

`reflex_profile_result_screen.dart` zeigt seit den Invite-Commits einen `InviteImpulseI1Slot` unter dem **Kinder**-Ergebnis (zwischen Trainer-Share und Bereichsliste). Für das Erwachsenenergebnis lautet die Entscheidung: **ja, aber nicht dort.**

- **Nicht** zwischen oder direkt unter den Reflexwerten. Ein „lade jemanden ein“ unmittelbar neben Aussagen über den eigenen Körper liest sich anders als unter einem Elternbericht über ein Kind.
- Platzierung im Adult-Flow **nach** den Ergebnisinhalten — unterhalb der Export-/Teilen-Aktionen am Seitenende, sichtbar abgesetzt von Werten und Detailkarten. Alternativ später in der Verlaufsansicht (Phase 8).
- Kinderergebnis bleibt unverändert.
- Phase 7 legt die konkrete Stelle fest und belegt sie mit einem Screenshot unter `docs/evidence/adult-reflexprofil/`; die endgültige Position bestätigt der Founder am Bild.

### 10.3 Zustände

| Zustand | UI |
|---------|-----|
| insufficientData | „Keine ausreichende Datengrundlage“ |
| partial (draft) | Result screen nicht; Progress „Profil noch nicht abgeschlossen“ + Resume |
| amphibian | Karte wie jeder andere Reflex, zwei Punkte statt Balken, **kein** Zusatztext (§10.2b) |
| alte Version | Banner „Erstellt mit älterer Methode“; keine Misch-Vergleiche |
| Methodenwechsel | History-Bruch markieren |

### 10.4 Child Result

Unverändert lassen (Radar, alte Band-Labels). Branch explizit — **auf die Version, nicht auf den Typ** (Revision 2026-08-21b):

```dart
if (assessment.questionnaireType == 'adult_self_report') {
  // NICHT einfach adult_v3 rendern: der Typ existiert in der DB seit
  // 2026051106_phase2_adult_self_backfill.sql und kann Zeilen aus einer
  // früheren Iteration mit unbekannter Version und unbekanntem scores-Shape
  // enthalten.
  if (assessment.questionnaireVersion == 'adult_v3') {
    return AdultReflexProfileResult(...);
  }
  return AdultReflexProfileLegacyNotice(...); // §10.3 „alte Version"
}
// existing child UI
```

**Fundstelle:** [`supabase/migrations/2026051106_phase2_adult_self_backfill.sql`](../../../supabase/migrations/2026051106_phase2_adult_self_backfill.sql) Step 7 verknüpft bestehende `adult_self_report`-Zeilen mit `adult_self`-Subject-Profilen und verifiziert „unlinked (adult_self_report — should be 0)“. Heute schreibt **kein** Dart-Code diesen Typ (`grep -rn "adult_self_report" lib/` findet nur den Enum-Namen). Die Migration rechnet also mit Bestandsdaten.

**Vor Phase 7 zu klären (read-only, kein Schreibzugriff):**

```sql
select questionnaire_version, scoring_version, status, count(*)
from public.reflex_profile_assessments
where questionnaire_type = 'adult_self_report'
group by 1, 2, 3;
```

Ergebnis 0 Zeilen → Legacy-Zweig bleibt trotzdem als Schutz drin (kostet nichts). Ergebnis > 0 → Legacy-Copy und Umgang mit diesen Zeilen sind ein eigener Entscheidungspunkt für §17.

---

## 11. Persistenz, Verlauf, Datenschutz und Analytics

### 11.1 Persistenz

- Weiterhin Supabase rows; Rohantworten in `answers`; berechnete `scores`
- Client berechnet Scores vor Submit (wie Kind); Server speichert JSON unverändert
- Löschung: bestehendes Account-Delete / Subject-Delete-Verhalten prüfen und Adult-Rows abdecken
- Export/Share: PDF-Pfad erweitern mit Adult-Copy; nur nach bewusster Nutzeraktion

### 11.2 Verlauf

- Neu: Provider `reflexProfileHistoryForSubjectProvider` — completed assessments für Subject, sortiert `completed_at DESC`
- Vergleich UI nur wenn `questionnaire_version` **und** `scoring_version` **und** `scores.meta.movement_included` gleich sind (§7.5). Fehlt eines der Felder → kein Vergleich, nicht defaulten
- Zeilen mit `questionnaire_version != 'adult_v3'` erscheinen in der Verlaufsliste als Eintrag mit Datum, aber ohne Wert und ohne Diff (§10.4 Legacy-Zweig)
- Copy: „Seit der letzten Befragung haben sich deine Angaben verändert.“
- Bei Versionswechsel: neue Serie / Banner Methodenwechsel
- v1 Scope: History-Liste + Diff pro Reflex optional Phase 8; nicht blockierend für erstes Adult-Submit

### 11.3 Datenschutz

- Antworten = potenziell besondere Kategorien → Datensparsamkeit; keine Analytics-Defaults
- Alter 16+: juristische Prüfung (§17)
- Explizites Speichern = Submit; Drafts lokal+server unter Account
- Keine Answer-Bodies in `appLogger` / Sentry
- Admin-Rollups: adult_self_report bereits filterbar; sicherstellen dass Demo ausgeschlossen bleibt

### 11.4 Optionale Analytics (Phase 8, hinter Consent / Flag)

Events (nur Aggregat-taugliche Metadaten, keine Freitexte):

- `adult_questionnaire_started|module_completed|abandoned|resumed|submitted`
- timings total/module
- `filter_hidden_count`, `answer_changed_count`
- `safety_hint_shown|confirmed`
- `movement_started|skipped|aborted`

Speicherort-Empfehlung: später eigene Tabelle oder `metadata` JSON — **nicht** in Sentry. Default OFF.

**Zirkularität auflösen (Revision 2026-08-21b).** §17 macht „Messung der digitalen Bearbeitungszeit und Abbruchstellen“ zum Freigabe-Blocker, und das Gesamtkonzept §9 steuert die Kürzung ausdrücklich über gemessene Zeit statt über feste Itemzahlen. Wenn die einzige Messung hinter einem Analytics-Consent-Flag mit Default OFF in Phase 8 liegt, misst **niemand** — der Blocker kann nie abgehakt werden.

Deshalb getrennt behandeln:

| | Was | Wo | Consent |
|---|---|---|---|
| **Dauer (Pflicht, Phase 5)** | `started_at`, `completed_at`, `module_timings` — reine Zeitstempel, **keine** Antwortinhalte | direkt auf der Assessment-Zeile bzw. im Draft (steht dort ohnehin) | kein zusätzlicher Consent nötig: gehört zur Bearbeitung des eigenen Bogens, nicht zur Produktanalyse |
| **Verhaltensanalytik (optional, Phase 8)** | `abandoned`, `resumed`, `answer_changed_count`, `filter_hidden_count`, `safety_hint_shown` | Analytics-Pfad | Consent + Flag, Default OFF |

Damit ist die Zielzeit 12–15 Min (adult_v3 „Bearbeitungsziel“) intern am Piloten messbar, ohne Analytics zu aktivieren. Abbruchstellen im engeren Sinn bleiben Phase 8 bzw. manuelle Beobachtung im Verständlichkeitstest (Gesamtkonzept §12.1).

**Größenordnung zur Erwartungssteuerung:** 7 Filter + 87 Score + 4 Kontext + 10 Safety = **108 sichtbare Items im Worst Case** (alle Filter „ja“). 12–15 Min bedeuten ca. 7–8 s pro Item inklusive Lesen der Kapitelintros. Das ist erreichbar, aber ohne Puffer — die Filter sind kein Komfort, sondern Teil der Zeitrechnung.

---

## 12. Phasenweiser Implementierungsplan

### Phase 1 — Bestandsaufnahme und Architekturentscheidung

- **Ziel:** Entscheidungen dieses Dokuments im Repo verankern (Plan/Spec), keine Produktlogik.
- **Dateien:** dieser Plan; optional kurzes Design-Note unter `docs/superpowers/specs/2026-08-21-adult-reflexprofil-design.md` (Summary + offene Blocker).
- **DoD:** Team/Founder bestätigt Architektur „extend assessment / separate scoring“.

### Phase 2 — Adult-v3 Datenmodell und Katalog

- **Ziel:** Kompilierbarer Katalog + Typ-Erweiterungen ohne UI-Unlock.
- **Neu:** `adult_reflex_questionnaire_definitions.dart`, ggf. `adult_reflex_filters.dart`, `adult_reflex_result_copy.dart`
- **Modify:** `reflex_questionnaire.dart` (Enums/Felder), Localization maps, Tests Katalog-Zählung 87/4/10/2 + Filter
- **Migration:** keine zwingend (Versionsstrings sind Textfelder)
- **DoD:** Unit-Test zählt Items/Roles/Mappings; Kind-Definition-Tests grün

### Phase 3 — Antwort-, Filter-, Persistenzlogik

- **Ziel:** Answer-JSON `not_applicable`; Visibility-Engine; Draft Meta Version
- **Modify:** `reflex_profile_screen.dart` helpers extract to `adult_questionnaire_visibility.dart`; draft serialize; provider draft payload
- **DoD:** Tests Visibility + Filter-Supersede; Roundtrip JSON

### Phase 4 — Scoring-Engine

- **Ziel:** `AdultReflexProfileScoringService` + Amphibien + Bänder
- **Neu:** `adult_reflex_profile_scoring.dart`
- **Tests:** siehe §14
- **DoD:** Suite deckt Grenzwerte/Polung/Multi-Map; Child scoring file untouched behavior

### Phase 5 — Fragebogen-UI

- **Ziel:** Adult-Pfad live hinter Flag; Coming-soon entfernen wenn Flag true
- **Modify:** `reflex_profile_screen.dart` (definition switch, 4-answer UI, filter module, summary), `for_whom_screen.dart`, ARB keys, age gate
- **DoD:** Manual/widget smoke; child path regression; analyze clean
- **Aus dem Phase-3-Review mitgenommen — zwei Stellen im Screen sind nur *scheinbar* verdrahtet und müssen hier echt angeschlossen werden:**
  - `_buildDraftMeta()` setzt `supersededItemIds` nie → der Provider bekommt dauerhaft eine leere Liste, obwohl `AdultQuestionnaireVisibility.supersededAnswerIds` existiert und getestet ist. Visibility-Instanz im Screen halten und das Feld daraus füllen.
  - `_buildDraftMeta()` leitet `filterAnswers` über die String-Heuristik `key.startsWith('f_')` ab statt über `providesFilter`. Durch `AdultQuestionnaireVisibility.filterAnswersForMeta` ersetzen und die Heuristik löschen.
  - Beides ist im Kinderpfad folgenlos (keine `f_`-IDs, keine Filter) — deshalb schlägt heute auch kein Test an. Ein Test in Phase 5 muss belegen, dass `superseded_item_ids` im Adult-Draft tatsächlich gefüllt wird.

### Phase 6 — Safety + deaktivierter Bewegungsteil

- **Ziel:** Safety-Modul + Flags; Movement code path present but off
- **DoD:** Movement not reachable with default flags; placeholder safety dialog without medical invention

### Phase 7 — Reflexprofil Übersicht + Details

- **Ziel:** Adult Result UI
- **Neu:** widgets `adult_reflex_hint_bar.dart`, `adult_reflex_detail_tile.dart`; screen branch
- **Modify:** PDF copy adult; progress card supports adult_self
- **DoD:** No total score in widget tree tests; forbidden strings grep test; screenshots in `docs/evidence/adult-reflexprofil/`

### Phase 8 — Verlauf, Export, Analytics (soweit sinnvoll)

- **Ziel:** History same-version; PDF adult; analytics stub OFF
- **DoD:** History refuses cross-version compare

### Phase 9 — Migration, Tests, QA, Rollout

- **Ziel:** `make release-readiness-mobile`; local db reset if migration added; rollout checklist §15
- **Migration only if needed:** e.g. extend `safety_status` check, index on `(subject_profile_id, questionnaire_version, completed_at)`
- **DoD:** Evidence notes; P2.A tracker update; movement still flagged off for public

---

## 13. Datei-für-Datei-Änderungsliste

### Neu

| Datei | Verantwortung |
|-------|----------------|
| `lib/features/assessment/domain/adult_reflex_questionnaire_definitions.dart` | Katalog adult_v3 |
| `lib/features/assessment/domain/adult_reflex_profile_scoring.dart` | Scoring-Engine |
| `lib/features/assessment/domain/adult_questionnaire_visibility.dart` | Filter/Visibility |
| `lib/features/assessment/domain/adult_reflex_result_copy.dart` | Detailtexte |
| `lib/features/assessment/presentation/screens/adult_reflex_profile_result_screen.dart` | Ergebnis (oder starker Branch) |
| `lib/features/assessment/presentation/widgets/adult_reflex_hint_bar.dart` | Balken |
| `lib/features/assessment/presentation/widgets/adult_reflex_detail_tile.dart` | Expansion |
| `lib/features/assessment/presentation/adult_score_band_l10n.dart` | Band-Labels |
| `test/features/assessment/adult_reflex_profile_scoring_test.dart` | Engine-Tests |
| `test/features/assessment/adult_questionnaire_visibility_test.dart` | Filter-Tests |
| `test/features/assessment/adult_reflex_questionnaire_localization_test.dart` | DE/EN Parität |
| `test/features/assessment/adult_result_copy_guardrails_test.dart` | Verbotene Phrasen |
| `docs/evidence/adult-reflexprofil/*` | Screenshots |
| ggf. `supabase/migrations/20260821NN_adult_reflex_profile_history_index.sql` | optionale Indexes |

### Modify

| Datei | Änderung |
|-------|----------|
| `lib/features/assessment/domain/reflex_questionnaire.dart` | polarity, movement role, amphibian, adult modules/bands |
| `lib/features/assessment/presentation/screens/reflex_profile_screen.dart` | definition switch, 4 answers, filters, summary, age gate |
| `lib/features/assessment/presentation/screens/reflex_profile_result_screen.dart` | branch adult |
| `lib/features/assessment/presentation/providers/reflex_profile_provider.dart` | adult profile lists, history |
| `lib/features/assessment/domain/draft_persistence_service.dart` | version fields |
| `lib/features/assessment/domain/services/reflex_profile_pdf_service.dart` | adult layout/copy |
| `lib/features/assessment/presentation/reflex_profile_pdf_copy.dart` | adult strings |
| `lib/features/onboarding/presentation/screens/for_whom_screen.dart` | unlock adult |
| `lib/features/progress/presentation/screens/progress_overview_screen.dart` | adult cards |
| `lib/config/launch_flags.dart` | 3 neue Flags + Docs |
| `lib/l10n/app_en.arb`, `app_de.arb` | Chrome-Copy |
| generated l10n (via `flutter gen-l10n`) | commit generated |
| `docs/LAUNCH_READINESS_BACKLOG.md` / tracker | P2.A fortschreiben nach Umsetzung |
| Admin panel analytics (minimal) | adult band names if rollup breaks |

### Nicht anfassen (außer Regressionsschutz)

- Child question bodies in `reflex_questionnaire_definitions.dart`
- Child thresholds in existing `ReflexScoringDefinition` instances
- Drift intake/completion
- Offline sync engine

---

## 14. Teststrategie und konkrete Testfälle

### 14.1 Unit — Scoring

1. Direct item Ja → +1 / Nein → 0  
2. Inverse item (fixture) Nein → +1 / Ja → 0  
3. `unknown` excluded from numerator & denominator  
4. `not_applicable` excluded likewise  
5. Context never scores  
6. Safety without reflexes never scores  
7. `s046` scores only ATNR+STNR  
8. Multi-map item increments multiple reflex buckets  
9. Filter hides item → not in possibleCount  
10. Denominator 0 → insufficientData, no percent  
11. Thresholds 29/30, 59/60, 79/80  
12. Amphibian 0/1/2 display + disclaimer flag  
13. Passing child definition into adult engine fails/asserts  
14. Child engine golden: existing tests still pass unchanged  
14a. **Invariante:** `answered + unknown + not_applicable + missing == possible_count` für jeden Reflex, über zufällige Antwortkombinationen (property-style). Fängt den `possibleCount`-Fehler der Planerstfassung  
14b. **`possible_count` zählt sichtbare, nicht unbeantwortete Items:** 9 sichtbare Moro-Items, 7 beantwortet → `answered_count == 7 && possible_count == 9` (nicht 2)  
14c. **Filterantwort „?“ blendet NICHT aus:** `f_handwriting == unknown` → alle 9 abhängigen Items bleiben in `possible_count`; nur `f_handwriting == no` entfernt sie  
14d. **`meta.movement_included` spiegelt den Flag-Zustand** und `possible_count` für Babinski/FLR/Moro/TLR/ATNR/Aufricht unterscheidet sich messbar zwischen Flag ON und OFF  

### 14.2 Unit — Visibility / Persistence

15. Filter no hides dependents; answers retained superseded  
16. Draft roundtrip four answer values  
17. Resume restores module index  
17a. **Katalog-Guard:** `f_handwriting` steuert exakt die 9 IDs aus §5.3; `s067` und `s071` existieren im Adult-Katalog **nicht** (Test schlägt fehl, falls jemand den alten Bereich `s066`–`s074` aufgelöst hat)  
17b. **Ergebnis-Branch:** Zeile mit `questionnaire_type == 'adult_self_report'` und `questionnaire_version != 'adult_v3'` rendert den Legacy-Hinweis, nicht die adult_v3-Balken  
17c. **History-Gate:** zwei Zeilen gleicher Version, aber unterschiedlichem `movement_included` → kein Vergleich; fehlendes Feld → ebenfalls kein Vergleich  

### 14.3 Widget / Golden

18. Adult result shows title „Dein Reflexprofil“ / EN equivalent  
19. No widget with Gesamtscore / average percent  
20. Band text present even if color blind  
21. Dark mode smoke  
22. Large text / small device layout  
23. Semantics labels on answer buttons  

### 14.4 Regression

24. Child coming path still uses child definition  
25. Child result radar still works  
26. `make release-readiness-mobile`  

### 14.5 Guardrail-Tests

27. Grep/test forbidden strings in adult result copy: `Diagnose`, `Reflex aktiv`, `nicht integriert`, `nachgewiesen`, `Ursache` (in user-facing adult copy files)

---

## 15. Migration und Rollout

1. **Internal:** Flag adult questionnaire ON for `@reflexjourney.de` optional later; initially compile flag true only after Phase 7 DoD  
2. **DB:** Meist keine Schema-Änderung; wenn History-Index: Migration lokal `supabase db reset --local`, live nur mit founder go  
3. **Content freeze:** `adult_v3` / `adult_equal_weight_v1` taggen; Änderungen → `adult_v4`  
4. **Public:** erst nach §17; Movement bleibt OFF  
5. **Store/Copy:** Zweckbestimmung mit Legal abstimmen  
6. **Rollout-Monitor:** Abbruchstellen manuell / später Analytics  

---

## 16. Risiken und offene Entscheidungen

| Risiko | Mitigation |
|--------|------------|
| Child/Adult scoring mix | Separate services + version asserts |
| Dirty-file layering on branch | Never stage unrelated files |
| Filter-Copy fehlt in Spec | Placeholder IDs `f_*` + founder/Sina copy review |
| Amphibien + multi-map s017 | Special bucket + expert review |
| Alarmistische Kind-Farben auf Adult | Eigene Widgets, keine ScoreBand-Color-Reuse |
| Medizinprodukte-/Werberisiko | Legal blocker §17; copy guardrails |
| EN-Übersetzungen der 100 Items | Parallel batch; DE ship internal first only if founder allows — default: both before release |
| Result-Copy Alternativerklärungen fehlen | Platzhalter + expertPending, nicht halluzinieren |
| Duration recommendation uses child bands | Gate: don’t feed adult scores into `recommendTrainingDuration` until separate decision |
| Bestands-`adult_self_report`-Zeilen aus früherer Iteration | Ergebnis-Branch auf `questionnaire_version` statt Typ + Legacy-Zweig (§10.4); read-only Query vor Phase 7 |
| Movement-Flag verschiebt Nenner ohne Versionswechsel | `meta.movement_included` persistieren und in History-Gate aufnehmen (§7.5/§11.2) |
| `possibleCount` als „unbeantwortet“ statt „sichtbar“ implementiert | Invariantentest 14a + expliziter Fixture-Test 14b (§14.1) |
| Zeitmessung nur hinter Analytics-Consent → Blocker nie abhakbar | Dauer von Verhaltensanalytik trennen, Dauer ab Phase 5 (§11.4) |
| Safety-Copy neu erfunden statt Expertenentwurf verwendet | §8.2 zitiert den Entwurf wörtlich; Guardrail-Test 27 prüft verbotene Formulierungen |

**Technische Entscheidungen — in Revision 2026-08-21b entschieden, nicht mehr offen:**

1. Filter-Modul vs. Inline → **eigenes Filtermodul** `AdultQuestionModule.lifeContext` direkt nach dem Intro (§6/§9)  
2. Adult Result eigene Route vs. Branch → **Branch** in bestehender Result-Route (weniger Router-Risiko)  
3. `possibleCount` → **Empfehlung A**: alle unter aktuellen Filtern sichtbaren Score-Items (§7.1)  
4. Filterantwort „?“ → **blendet nicht aus** (§6.1, Begründung dort)  
5. Ergebnis-Branch → auf `questionnaire_version`, nicht auf `questionnaire_type` (§10.4)  
6. `safety_status` Stufen A/B/C → **nicht** in v1 (§8.2)

---

## 17. Vor öffentlicher Freigabe erforderliche Fachentscheidungen

- Fachprüfung Zuordnungen mit >3 Reflexen, besonders **s029** und **s063** (auch s023, s072, Movement)
- Fachprüfung Amphibien-Items **s017** und **s102**
- **Bewusste Abweichung vom Dokument, der Prüfung vorzulegen:** Der in adult_v3 Teil B §2 vorgeschriebene Amphibien-Zusatztext („Aufgrund der wenigen verfügbaren Merkmale …“) wird **nicht** angezeigt (Founder-Entscheidung 2026-08-21, §7.4/§10.2b). Der Seiten-Disclaimer trägt die Aussage für die gesamte Liste. Die Prüfung entscheidet, ob das so bleibt
- Expertenfreigabe aller Sicherheitsfragen, Pop-ups und Bewegungsprüfungen (separates Experten-Dokument existiert außerhalb: `Reflexprofil_Sicherheitspruefung_Experten.docx` — inhaltlich noch nicht Produktfreigabe)
- Verständlichkeitstest mit 5–8 Personen ab 16
- Messung digitaler Bearbeitungszeit und Abbruchstellen
- Grundratencheck mit 10–15 Personen ohne bekannten Reflexverdacht
- Datenschutzprüfung sensible Daten + Nutzung ab 16
- Rechtliche Prüfung Zweckbestimmung, Werbeaussagen, mögliche Medizinprodukte-Einordnung
- Neue Fragebogen- und Scoringversion nach jeder inhaltlichen/methodischen Änderung
- Finaler Wortlaut der sieben Filterfragen
- **Lücke im Katalog: Medikamente.** Expertendokument §4 führt „Medikamente — noch nicht strukturiert berücksichtigt“ mit der Frage, ob Schwindel, Kreislauf, Sedierung oder Koordination als Funktionsfrage erfasst werden sollen. adult_v3 hat dazu **kein** Item. Das ist bewusst **kein** adult_v3-Nachtrag (Content-Freeze, §15.3) — es wäre ein neues Safety-Item in `adult_v4`. Bis dahin nicht durch eigene Formulierungen schließen
- **Bestandszeilen `adult_self_report`** aus früherer Iteration: existieren sie in Prod, und wie werden sie dargestellt? (§10.4, read-only Query dort)
- Zuordnung jeder Sicherheitsfrage zu Stufe A/B/C und die konkrete Folge pro Ja-Antwort (Expertendokument §11.1/§11.2) — Voraussetzung für `kAdultSafetyHardGateEnabled`
- Freigabe der Bewegungsprüfungen inkl. Haltedauer Einbeinstand (10 s vs. 30 s), Sicherung und Abbruchregeln (Expertendokument §5)
- Entscheidung, ob Adult-Scores die Trainingsdauer-Empfehlung ansteuern dürfen

---

## 18. Definition of Done

### Intern testbar (Entwicklungs-DoD)

> Abgenommen 2026-08-21 nach Review der Phasen 2–7. Commits `41960e8`…`0a86357`.

- [x] Adult-Katalog `adult_v3` vollständig gemappt (87/4/10/2 + 7 Filter = 110 Items) — ✅ 2026-08-21 → Katalog gegen adult_v3 Teil B.4 maschinell diffed → 0 Abweichungen über 103 gemappte IDs; 110 Items
- [x] Adult-Scoring-Tests grün inkl. Grenzwerte, Amphibien, Filter — ✅ 2026-08-21 → `flutter test test/features/assessment/` → 96/96 grün
- [x] Invariante `answered + unknown + n.a. + missing == possible_count` als Test grün (14a) — ✅ 2026-08-21 → Test 14a grün; possibleCount zählt sichtbare Items
- [x] `meta.movement_included` wird geschrieben und im History-Gate geprüft (17c) — ✅ 2026-08-21 → immer im scores-JSON, auch bei false
- [x] Ergebnis-Branch prüft `questionnaire_version`, Legacy-Zweig getestet (17b) — ✅ 2026-08-21 → Branch auf `questionnaire_version == adult_v3`; Legacy-Zweig getestet; Live-Abfrage 0 Zeilen
- [x] Safety-Copy stammt wörtlich aus dem Expertenentwurf; kein selbst formulierter medizinischer Text — ✅ 2026-08-21 → ARB-Text zeichenidentisch mit Expertendokument §6; Bewegungssatz flag-gated
- [x] Child-Tests unverändert grün — ✅ 2026-08-21 → unverändert grün; kein P2.A-Commit an Child-Scoring
- [x] `flutter analyze --no-fatal-infos` 0 errors/warnings; `flutter test` 100% — ✅ 2026-08-21 → 0 errors, 0 warnings, 98 infos; flutter test assessment 96/96
- [x] Adult-UI: Resume, Back, 4 Antworten, Summary, Result ohne Gesamtscore — ✅ 2026-08-21 → Resume, Back, 2×2-Antworten, Summary, Result ohne Gesamtscore und ohne Radar
- [x] Movement default OFF; Safety hardgate OFF — ✅ 2026-08-21 → kAdultMovementChecksEnabled=false, kAdultSafetyHardGateEnabled=false
- [x] l10n DE+EN chrome; Katalog DE+EN — ✅ 2026-08-21 → Chrome in beiden ARB, Katalog DE+EN mit Paritätstest
- [x] Evidence screenshots Result + Questionnaire — ✅ 2026-08-21 → 01–04 + Invite-Platzierung unter docs/evidence/adult-reflexprofil/
- [x] Keine verbotenen diagnostischen Strings in Adult-Copy-Tests — ✅ 2026-08-21 → Guardrail-Test auf verbotene Strings grün
- [x] Unrelated dirty files not committed — ✅ 2026-08-21 → nur settings.gradle.kts, firebase.json, pubspec.yaml, tasks/todo.md — nicht committet

### Öffentliche Freigabe-DoD (zusätzlich)

- [ ] Alle Punkte §17 abgehakt oder bewusst deferred mit Flag
- [ ] Legal/Datenschutz Go
- [ ] Founder Go für Flag-Zustände und Store-Kommunikation

---

## 19. Empfohlene Commit-Reihenfolge

Kleine, reviewbare Commits (nur Adult-Dateien + Tests; Message-Referenz `P2.A`):

1. `feat(assessment): extend domain types for adult polarity, n/a, amphibian (P2.A)`
2. `feat(assessment): add adult_v3 questionnaire catalog and filters (P2.A)`
3. `feat(assessment): add adult equal-weight scoring engine (P2.A)`
4. `test(assessment): cover adult scoring thresholds, filters, amphibian (P2.A)`
5. `feat(assessment): wire adult questionnaire UI path behind launch flags (P2.A)`
6. `feat(assessment): add adult safety module placeholders; keep movement gated off (P2.A)`
7. `feat(assessment): add adult reflex profile result bars and detail tiles (P2.A)`
8. `feat(assessment): adult PDF copy + progress/for-whom unlock (P2.A)`
9. `feat(assessment): optional same-version history provider (P2.A)`
10. `chore(assessment): evidence screenshots + backlog P2.A note (P2.A)`

---

## Appendix A — adult_v3 Kapitelreihenfolge

0. **Deine Lebenssituation** (App-eigenes Filtermodul, 7 `f_*`-Items — nicht Teil von adult_v3, siehe §5.3)  
1. Sinneswahrnehmung und Reizverarbeitung  
2. Körperhaltung und Sitzen  
3. Motorik und Koordination  
4. Arbeit, Bildschirm und Konzentration  
5. Autofahren, Orientierung und Reisen  
6. Sport, Gleichgewicht und Füße  
7. Sprache, Mund und Kiefer  
8. Schreiben und Feinmotorik  
9. Lesen, Lernen und Orientierung  
10. Verhalten, Stress und Gefühle  
11. Schlaf, Verdauung und Körper  
12. Sicherheitsfragen  
13. Freiwillige Bewegungsprüfungen (Flag OFF)

## Appendix B — Konkrete Fundstellen Child Coming-Soon

- `reflex_profile_screen.dart`: `_definition => childParentQuestionnaireV1`; `_questionnaireFor == 'adult'` → coming soon  
- `reflex_profile_provider.dart`: `createAdultSelfProfile` existiert; `reflexSubjectProfilesProvider` filtert child-only  
- Demo-Screen: Adult-Auswahl ebenfalls coming-soon-ähnlich  

## Appendix C — Agent execution notes

When implementing, create `tasks/todo.md` checkboxes mirroring Phases 2–7 before coding. After each phase run focused tests; before claiming done run `make release-readiness-mobile`. Never push. Never apply live SQL without founder go.
