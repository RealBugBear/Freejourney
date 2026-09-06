# Production readiness

Assessment started 2026-09-05. **Not approved for production.**

**How to use this file.** This is the durable state of the readiness work. Read it
and `tasks/todo.md` first and trust them; do not re-audit the repository to rebuild
context. Every claim below is backed by a log in
`docs/evidence/production-readiness/`. Update this file before you stop working,
for any reason.

**Note on evidence.** `*.log` is gitignored repo-wide, so the raw logs below live on
disk only and are not in git history (`queue-load.json` is tracked). They survive
`git checkout`/`reset` but not `git clean -fdx`. To make them durable, add
`!docs/evidence/**/*.log` to `.gitignore` — founder decision, not yet taken.

## Architecture and scope

Reflex Journey is a bilingual German/English Flutter wellness training app for
adults and parent-managed child profiles. Riverpod/go_router drive the UI; Drift
SQLite stores offline user data and a sync outbox. Supabase Auth, PostgreSQL/RLS,
Storage and Deno Edge Functions provide the backend. FCM/APNs provide push; Sentry
is configured for minimal error reporting. Payments, invites, community and calls
have release gates; unfinished gated products must stay gated.

The app/backend repository is this directory. The separate repository at
`../corejourney` holds `admin-web` and `reflexjourney-app-site`; its readiness is
tracked in `../corejourney/docs/PRODUCTION_READINESS_WEB.md`. Supabase has one
linked **live** project; all mutating validation targets local infrastructure only.

## Verification status — READ THIS BEFORE CLAIMING ANYTHING IS GREEN

| Check | Result | Ran | Evidence |
|---|---|---|---|
| Mobile gate (`make release-readiness-mobile`) | 709 tests passed, i18n parity 1,296 keys | 2026-09-05 20:38 | `mobile-final.log` |
| Supabase DB tests | 261 tests, `Result: PASS`, 9 files | 2026-09-05 20:48 | `db-tests.log`, `db-reset.log` |
| iOS release build | Built `Runner.app`, 115.5 MB (codesigning disabled) | 2026-09-05 20:47 | `ios-build.log` |
| Android production release | Built `app-production-release.apk`, 289.6 MB | 2026-09-06 12:40 | `android-build.log` |
| Queue concurrency | 10,000 jobs / 16 workers: 0 duplicate claims, 0 unclaimed, 6,428 claims/s, p99 306 ms | 2026-09-05 20:33 | `queue-load.json` |
| Analyzer | 117 issues, all severity `info` (mostly `unnecessary_import` in tests); 0 errors, 0 warnings | 2026-09-06 12:40 | `mobile-analyze-latest.log` |
| Local simulator smoke | Ran against local Supabase; rehydrate and reminder sync logged | 2026-09-06 17:29 | `local-smoke.log` |
| Backup/restore rehearsal | **FAILED TO RUN** — probe aborts: "Requires an empty synthetic local auth database" | 2026-09-05 20:47 | `restore.log` |

**Open verification gap (highest priority).** 18 files were edited on 2026-09-06
between 12:45 and 12:47 — after the analyzer and Android build (both 12:40) and
long after the full gate (09-05 20:38). They include `lib/core/sync/sync_service.dart`,
`lib/core/sync/sync_backend.dart`, `lib/app.dart`, `lib/features/auth/presentation/providers/auth_provider.dart`,
the mood/journal/streak-credits repositories, and both `lib/l10n/app_*.arb` files.

**Nothing currently in the working tree has been verified by any check.** The gate
must be re-run before any further claim of green. The ARB edits mean the i18n key
parity check is also unverified.

## Work completed (uncommitted, checkpointed)

Fixes carry regression tests; test names are the specification.

**Sync and offline data integrity** — `lib/core/sync/`, `test/core/sync/` (19 tests)
- Drain reserved its lock after an `await`, allowing two concurrent drains.
- Conflict recovery deleted an unsent enrollment graph; local data is now retained.
- Last-job coalescing lost fields from ordered partial writes.
- A stale response could acknowledge a changed stable-ID job.
- `needsSync` cleared before all record writes had succeeded.
- A late restore response could repopulate account data after logout; stale
  account jobs could transmit under a different account.
- Outbox failures now roll back atomically across enrollment, session, mood and
  journal paths, including concurrent submission and same-day retry.

**Authorization** — `supabase/migrations/2026090501_training_reference_ownership.sql`
- A caller could attach their own rows to another account's child profile or
  enrollment, including occupying that child's globally unique active-enrollment
  slot. A `SECURITY DEFINER` trigger now enforces owner/subject/enrollment
  consistency on write. No existing data is rewritten; RLS and grants unchanged.
  Covered by `supabase/tests/2026090501_training_reference_ownership_test.sql`.

**Notification worker recovery** — `supabase/migrations/2026090502_notification_job_recovery.sql`
- A worker that died mid-attempt left jobs stuck in `sending` forever. `updated_at`
  is now a claim lease and `attempt_count` fences stale worker results, with a
  partial retry index and bounded retry. RPC return shape preserved.
  Covered by `supabase/tests/2026090502_notification_recovery_test.sql`.

**Session storage** — `lib/core/storage/file_local_storage.dart` (5 tests)
- Legacy session files migrated into a backup-excluded store, writes and logout
  serialized, atomic replacement, interrupted temp files removed, failed backup
  exclusion rejects persistence while erasure stays usable.

**Auth** — `lib/features/auth/`, `apple_nonce_test.dart`
- Apple sign-in binds a fresh nonce per attempt between the Apple challenge and
  Supabase verification. Sign-out cleanup completed; auth links no longer written
  to a diagnostic file.

**Media pipeline** — `docs/media/`, `scripts/`
- `exercise_video_manifest.v1.json`: 22 videos, schema + contract, stable
  `video_id`/`exercise_id`, revision, content version, owners, bilingual titles.
  All 22 are `status: awaiting_production`.
- `validate_exercise_videos.py`, `prepare_exercise_video_release.py` with tests;
  `exercise_video_inventory_test.dart` asserts the manifest covers the complete
  local exercise catalog. `EXERCISE_VIDEO_DELIVERY.md` holds the filming and
  delivery specification.
- `exercise_video_widget.dart` surfaces late playback errors as retry state.

## Open items, in order

1. **Re-run the full mobile gate** and close the verification gap above. Fix what
   it surfaces. Nothing else should start before this is green.
2. **Backup/restore rehearsal**: make `scripts/local_restore_probe.py` complete, or
   document exactly what local infrastructure it requires. It currently aborts
   because the local auth database is not empty.
3. **Admin transitive PostCSS advisory** in `../corejourney/admin-web` — an override
   was being added; unverified. Website advisories were cleared.
4. Analyzer: 117 `info` issues. Non-blocking; clean opportunistically, not now.

## Assumptions

No production traffic test, release, or real user data mutation is authorized.
Synthetic local users and data only. The queue measurement covers PostgreSQL job
claiming only — not push delivery, and not a production capacity claim.

## External dependencies (not resolvable in the repository)

- Final exercise footage for all 22 videos: commissioning, filming, editing,
  captions/transcripts, poster images, rights and performer permissions.
- Exercise-professional content approval; legal review and approved privacy copy.
- Store/account/provider setup, production monitoring delivery, device acceptance.
- No placeholder may be marked production-ready; no footage may be fabricated.

## Rollout and rollback

No push, production migration, function deployment, store submission or public
publication has been performed. Both repositories carry a WIP checkpoint commit on
their feature branches (`i18n/english-localization` here, `website-v1` in
`../corejourney`); rollback is `git revert` of that commit or `git reset` to its
parent. A specific release may be approved only after the open items close and the
external gates are met. The two new migrations are additive and forward-only;
neither rewrites existing rows.
