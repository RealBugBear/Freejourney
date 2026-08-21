# Invite feature — final handoff (Phases 0–8)

**Status:** lokal vollständig implementiert und verifiziert  
**Datum Abschlussprüfung:** 2026-08-21  
**Nicht getan:** Commit, Push, Live-Migration, Flag-Freischaltung

Parallel läuft ein Fragebogen-Task mit überlappenden Dateien. Diese Handoff-Liste
trennt **invite_exclusive** und **shared**; shared-Dateien nicht pauschal stagen.

---

## Phasen 0–8

| Phase | Ergebnis |
|---|---|
| 0 Linkarchitektur | Evidence `invite-phase0/` — Domain/AASA-Pfade dokumentiert; Geräte-UL weiterhin Gate |
| 1 DB Referral | Migration `2026082105` lokal; pgTAP 58/58; **nicht live** |
| 2 Datenschicht | Repository/Provider/Models + Tests |
| 3 Einladen-UI + Baum | Screen, Painter, Golden/Semantics; Flag aus |
| 4 Einlösen + Confirm | Redeem, Sheet, Settings/Onboarding-Gates |
| 5 Deep Links + Store | PendingInviteStore, AASA-Pfade, Manifest; Geräte-QA offen |
| 6 Impulse I1 | Policy/Store-Queue; I2 Flag aus |
| 7 Website `/einladung` | DE/EN, SelfCheck, Landing-RPC, noindex; Pre-Launch Warteliste |
| 8 Admin-Trichter | `get_admin_invite_funnel_v1` + `/admin/metrics/invites`; soft-fail nur Missing-RPC |

---

## Finale Testresultate (beobachtet 2026-08-21)

### App-Repo
| Check | Result |
|---|---|
| pgTAP `2026082105_referral_program_test` | **1..58**, 0 failures |
| pgTAP `2026082106_admin_invite_funnel_test` | **1..23**, 0 failures |
| Flutter invite suite (`test/features/invite` + deep link + pending store) | **81 passed** |
| `flutter analyze` (invite + Integrationsdateien) | **No issues found** |
| `kInviteEnabled` | `false` |
| `kInviteImpulseI2Enabled` | `false` |
| Writes zu `entitlement_grants` / `benefit_campaigns` / `benefit_codes` | keine (nur Verbots-Kommentare in Migrationen) |

### Website (`reflexjourney-app-site`)
| Check | Result |
|---|---|
| `test:aasa` | pass |
| `test:invite-code` (Helper + Landing-Controller) | 8 pass |
| `test:invite-pages` | 2 pass |
| `check:i18n` | OK |
| `astro build` | 35 pages |
| Sitemap enthält `einladung` | nein |
| Pre-Launch Wartelisten-CTA + „noch nicht im Store“ | aktiv |
| Platzhalter / TestFlight / Internal Store-Links | keine |

### Admin-web
| Check | Result |
|---|---|
| `npm run test:metrics` (Missing-RPC soft-fail / permission / andere Fehler) | **6 pass** |
| `tsc --noEmit` | clean |
| Primary Signals Invites | alle 3 Conversion-Raten: `conv_landing_per_share`, `conv_redeem_per_landing`, `conv_activated_per_redeemed` |
| Soft-fail | nur `PGRST202` oder „Could not find the function“; Permission-/Runtime-Fehler nicht verschluckt |

---

## Keine PII im Admin-Payload

`get_admin_invite_funnel_v1` liefert nur Aggregate (`page`, `group_key`, `metric_key`,
`label`, `value`, `unit`, `metadata` mit Definitionen/Nennern). Keine
`invitee_user_id`, Namen, E-Mails oder Codes in Spalten oder Metadata-Werten
(pgTAP ok 17–18).

## Stufe 2

Nicht umgesetzt: keine `benefit_campaigns`, keine `entitlement_grants`, keine
Belohnungs-UI/Website-Abfrage.

## Post-Launch Store-Buttons

**W-024** / **F9.6** / Spec §14 Punkt 3 / `docs/evidence/invite-phase7/README.md`  
Erst nach öffentlicher Store-Verfügbarkeit; bis dahin Warteliste.

## Bekannte vorbestehende Testblockade

`supabase/migrations/2026072301_moro_content_snapshot_v1.sql` bricht
`supabase db reset --local` (`rhythm_type` fehlt in früheren Migrationen).
Workaround: Datei temporär aside, Reset, Datei zurück — **nicht committen**.
Siehe `docs/evidence/invite-phase1/README.md`.

---

## Geänderte Dateien nach Repository

### A. `invite_exclusive_files` (App-Repo `reflexjourney`)

Nur Einladungstask (neu oder klar invite-owned):

```
docs/evidence/invite-phase0/
docs/evidence/invite-phase1/
docs/evidence/invite-phase3/
docs/evidence/invite-phase4/
docs/evidence/invite-phase5/
docs/evidence/invite-phase6/
docs/evidence/invite-phase7/
docs/evidence/invite-phase8/
docs/evidence/invite-final/
docs/superpowers/specs/2026-08-21-einladungen-cursor-prompt.md
docs/superpowers/specs/2026-08-21-einladungen-und-wirkungsvisual-design.md
lib/core/navigation/invite_deep_link.dart
lib/core/storage/pending_invite_store.dart
lib/features/invite/   (gesamter Feature-Tree)
supabase/migrations/2026082105_referral_program.sql
supabase/migrations/2026082106_admin_invite_funnel.sql
supabase/tests/2026082105_referral_program_test.sql
supabase/tests/2026082106_admin_invite_funnel_test.sql
test/core/navigation/invite_deep_link_test.dart
test/core/storage/pending_invite_store_test.dart
test/features/invite/
```

Website exclusive (outer `corejourney/reflexjourney-app-site`):

```
src/pages/einladung.astro
src/pages/en/einladung.astro
src/content-pages/EinladungPage.astro
src/lib/inviteCode.ts
src/lib/inviteLanding.ts
src/lib/safeSessionStorage.ts
scripts/invite_code.test.ts
scripts/invite_landing.test.ts
scripts/invite_pages.test.mjs
scripts/aasa_paths.test.mjs   (invite paths; AASA-Dateien auch Phase-5)
```

Admin exclusive (outer `corejourney/admin-web`):

```
app/admin/metrics/invites/page.tsx
lib/metrics/inviteMetricsMerge.ts
lib/metrics/inviteMetricsMerge.test.ts
```

### B. `shared_files` (Überlapp / Integrationsflächen)

#### App-Repo — Fragebogen-relevant oder Integrations-Touch

| Datei | Invite-spezifische Hunks |
|---|---|
| `lib/features/assessment/presentation/screens/reflex_profile_result_screen.dart` | Import `invite_impulse_i1_slot.dart`; Widget `InviteImpulseI1Slot(isFirstResultDisplay: …)` unter dem Ergebnis-Header. |
| `lib/l10n/app_en.arb` / `app_de.arb` | Neue Keys `invite*` / `impulseInvite*` (DE+EN). Fragebogen-Keys unberührt lassen. |
| `lib/l10n/app_localizations*.dart` | Generiert aus ARB inkl. Invite-Strings. |
| `lib/config/launch_flags.dart` | Neu: `kInviteEnabled = false`, `kInviteImpulseI2Enabled = false` + Doc-Kommentare. |
| `lib/core/navigation/app_router.dart` | Routes `/einladen`, `/einladung`, `inviteGateRedirect`, Screen-Builder. |
| `lib/app.dart` | Invite-Deep-Link-Parsing, `PendingInviteStore`, gated Navigation. |
| `lib/features/settings/…/settings_screen.dart` | `if (kInviteEnabled)` Sektion „Freunde einladen“. |
| `lib/features/onboarding/…/entry_points_screen.dart` | Bei Flag: Weiterleitung zu `/einladung?onboarding=1`. |
| `lib/features/mood/…/mood_repository.dart` | Neu: `hasLowMoodInWindow` für Impuls-Suppress. |
| `android/app/src/main/AndroidManifest.xml` | `pathPrefix` `/einladung` und `/en/einladung`. |
| `tasks/todo.md` | Invite-Phasen-Todos (Fragebogen kann eigene Plan-Dateien haben). |
| `pubspec.yaml` | Diff zeigt nur Build-Number `+2026081002` — **vorbestehend/parallel**, nicht invite-Feature-Code. Beim Commit nicht mit Invite vermischen ohne Prüfung. |

#### App-Repo — Dirty, aber **nicht** Invite-owned (nicht in Invite-Commit)

| Datei | Hinweis |
|---|---|
| `firebase.json` | App-ID-Wechsel — vorbestehend; nicht Teil Invite-Scope. |
| `android/settings.gradle.kts` | Kotlin-Pin für Sentry — vorbestehend; nicht Teil Invite-Scope. |
| `supabase/.temp/cli-latest` | CLI-Temp; nicht committen. |
| Fragebogen-Docs unter `docs/superpowers/specs/…adult…` / `…questionnaire…` | Parallel-Task; unberührt lassen. |

#### Website shared

| Datei | Invite-Hunks |
|---|---|
| `src/components/SelfCheck.astro` | Optional `hideDefaultResultCtas` + Slot `result-ctas`; Default-Selbstcheck unverändert. |
| `src/data/de/site.ts` / `en/site.ts` | `meta.einladung`, `einladungPage` inkl. Pre-Launch-Copy. |
| `src/config.ts` | `SUPABASE_URL` / `SUPABASE_ANON_KEY` (+ `isWaitlistLive` bleibt). |
| `astro.config.mjs` | Sitemap-Filter `/einladung`. |
| `package.json` | Scripts `test:invite-*`, `test:aasa`. |
| `public/.well-known/apple-app-site-association` (+ Root-Spiegel) | Invite-Pfade neben `/auth/*`. |
| `FOUNDER_TODO.md` | F9.6 Store-Buttons Post-Launch. |
| `WEBSITE_BACKLOG.md` | W-024. |

#### Admin-web shared

| Datei | Invite-Hunks |
|---|---|
| `lib/metrics/config.ts` | Page `invites` + 7 Primary Keys inkl. aller 3 Conversion-Raten. |
| `lib/metrics/data.ts` | Merge über `combineAdminMetricResults`. |
| `components/metrics/metric-card.tsx` | `null` → `—` (für Null-Denominator-Raten). |
| `components/metrics/metrics-page.tsx` | `invites` Decision Notes; Group `conversion`. |
| `app/admin/nav.tsx` | Link „Einladungen“. |
| `package.json` | Script `test:metrics`. |
| `tsconfig.json` | Exclude `**/*.test.ts`. |

---

## Offene Rollout-Gates

1. Datenschutz und Verarbeitungsverzeichnis („Einladungsbeziehung“)
2. Migrationen `2026082105` und `2026082106` live anwenden (Founder-Go)
3. Website inklusive AASA deployen
4. echte Universal-Link-Tests auf iPhone und Android
5. Release mit `kInviteEnabled=true`
6. öffentliche Store-Links nach Store-Launch (W-024 / F9.6)

---

## Evidence-Index

- Phases: `docs/evidence/invite-phase0/` … `invite-phase8/`
- This file: `docs/evidence/invite-final/README.md`
