# Production readiness

Assessment started 2026-09-05. **Not approved for production.**

**How to use this file.** This is the durable state of the readiness work. Read it
and `tasks/todo.md` first and trust them; do not re-audit the repository to rebuild
context. Every claim below is backed by a log in
`docs/evidence/production-readiness/`. Update this file before you stop working,
for any reason.

**Note on evidence.** Raw logs are under `docs/evidence/production-readiness/`.
`.gitignore` carries an exception (`!docs/evidence/**/*.log`) so they are tracked;
the duplicated line was removed 2026-09-06. The logs are committed and durable.

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
| Mobile gate (`make release-readiness-mobile`) | **PASS, exit 0** in a single clean invocation: 722 tests, i18n parity + quality 1,302 keys, `✅ Automated release-readiness checks passed.` | 2026-09-06 (clean run) | `gate-20260906-clean-run.log` |
| Migration chain replay | **PASS, exit 0**: all 67 migrations applied from scratch, 0 errors, including `2026090501` and `2026090502` | 2026-09-06 (post-edit) | `db-reset-20260906-verify.log` |
| Supabase DB tests (post-replay) | 261 tests, `Result: PASS`, 9 files, exit 0 — on the freshly replayed schema | 2026-09-06 (post-edit) | `db-tests-20260906-postreset.log`, `db-tests-20260906-preverify.log` |
| iOS release build | Built `Runner.app`, 115.5 MB (codesigning disabled) | 2026-09-05 20:47 | `ios-build.log` |
| Android production release | Built `app-production-release.apk`, 289.6 MB | 2026-09-06 12:40 | `android-build.log` |
| Queue concurrency | 10,000 jobs / 16 workers: 0 duplicate claims, 0 unclaimed, 6,428 claims/s, p99 306 ms | 2026-09-05 20:33 | `queue-load.json` |
| Analyzer | 117 issues, all severity `info`; 0 errors, 0 warnings. Final test-fixture edit separately analyzed with no issues | 2026-09-06 17:47–17:49 WEST | `mobile-20260906-session-final.log`, `offline-writer-analyze-20260906-session.log` |
| Local simulator smoke | Ran against local Supabase; rehydrate and reminder sync logged | 2026-09-06 17:29 | `local-smoke.log` |
| Local backup/restore rehearsal | **PASS**: schema metadata, GraphQL wrapper, synthetic data, owner/cross-account RLS; cleanup verified | 2026-09-06 17:57–17:58 WEST | `restore-20260906-session-final.log`, `restore-cleanup-20260906-session.log` |

**Mobile verification gap closed, with precise execution history.** Exactly two
`make release-readiness-mobile` invocations ran, respecting the session cap:
- Initial invocation: i18n passed; analysis failed with 7 errors (six stale
  localization getters, one referenced twice), 1 unused-import warning, 117 infos.
  Tests did not run. Evidence: `mobile-20260906-session-start.log`.
- Regenerated localization code using `flutter gen-l10n` and removed the unused
  Drift import. Focused analysis returned `No issues found!`.
  Evidence: `l10n-20260906-session.log`, `mobile-focused-20260906-session.log`.
- Final invocation: i18n and analysis passed; tests ended `+722 -1: Some tests
  failed.` The sole failure was an asynchronous `MissingPluginException` for
  shared preferences in `offline_writer_atomicity_test.dart` setup.
- Initialized the shared-preferences mock before Supabase initialization (its
  separate PKCE storage needs this even with `EmptyLocalStorage`). The focused
  file passed all 12 tests; focused analysis returned `No issues found!`.
  Evidence: `offline-writer-20260906-session.log`,
  `offline-writer-analyze-20260906-session.log`.
- Resumed only the failed full-test stage with `flutter test`: exit 0,
  `+722: All tests passed!`. No third full-gate invocation. Thus all gate
  components have passing evidence; neither complete `make` invocation itself
  returned success. No mobile source/test edits followed that successful run.

**Closed 2026-09-06 by a third, clean invocation.** `make release-readiness-mobile`
was run once more with no intervening edits and returned `GATE_EXIT=0` with
`✅ Automated release-readiness checks passed.` A complete gate invocation has now
succeeded end to end, not only its stages. Evidence: `gate-20260906-clean-run.log`.

**Ownership-migration replay closed 2026-09-06.** The mobile gate does not execute
SQL, so this was verified separately. `supabase db reset --local` replayed the full
67-migration chain from scratch with exit 0 and no errors, applying both
`2026090501_training_reference_ownership.sql` and `2026090502_notification_job_recovery.sql`;
`supabase test db --local` then returned `Result: PASS` (261 tests, 9 files, exit 0)
against that freshly replayed schema. The installed
`enforce_training_reference_ownership` body matches the repository migration exactly
(md5 `d30a5b06…`, identical before and after replay) and its trigger is attached to
all 9 intended tables. The local database held only 2 profiles and zero
enrollments/journal/session rows; a custom-format dump was taken before the reset.
The platform-build rows above remain historical evidence — release binaries were not
rebuilt after the Sep-6 edits.

## Work completed (prior work checkpointed; session fixes uncommitted)

At session start Git HEAD was `6d60b9d` (`chore(readiness): WIP checkpoint for the
production-readiness assessment`), and application files were clean. Only
`.gitignore` and untracked evidence logs were pending. This session changed the
three generated `lib/l10n/app_localizations*.dart` files, the offline-writer test
fixture, `scripts/local_restore_probe.py`, this file and `tasks/todo.md`. No commit
was made and no unrelated code was edited.

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

**Closed 2026-09-07 — Admin transitive PostCSS advisory / override verification.**
The task's verified 2026-09-07 audits report `found 0 vulnerabilities` in both
web projects (accepted prior evidence; audits not rerun). Fresh admin
`npm run typecheck`, `npm run lint`, `npm run test:metrics` (6/6) and
`npm run build` (21/21 static pages) all exited 0. Site `npm run check`
(72 files, 0 errors/warnings/hints) and `npm run build` (35 pages) also exited 0.
Next.js resolves PostCSS 8.5.28; the existing override stands unchanged.
Dated logs, resolution evidence and audit provenance:
`../corejourney/docs/evidence/postcss-override/README.md`; full outcome:
`../corejourney/docs/PRODUCTION_READINESS_WEB.md`. No Flutter code changed.

1. Analyzer: 117 `info` issues. Non-blocking; clean opportunistically, not now.
2. Release binaries were last built 2026-09-05/06, before the final edits. Rebuild
   before any store submission; not required for local verification.

**No engineering item now blocks launch.** Per `docs/LAUNCH_READINESS_BACKLOG.md`,
every P0 is closed except P0.6 (lawyer) and the T05 Stage 2 work that depends on it.
The remaining critical path is founder-owned and external: the lawyer mandate, the
22 exercise videos plus expert content approval, the on-device session, and store
metadata approval.

## Local restore rehearsal — completed 2026-09-06

Run from this repository: `python3 scripts/local_restore_probe.py`.

The historical `restore.log` predates the checkpointed isolated-database script;
the empty-auth guard was already removed before this session. The actual blockers
were Supabase's non-superuser `postgres` role being unable to restore the
`log_min_messages` setting, followed by a missing
`graphql_public.graphql(text,text,jsonb,jsonb)` definition when restoring grants.
Supabase adds that wrapper to `pg_graphql` extension membership after installation;
`pg_dump` therefore omits its definition even though it retains its ACL.

The repaired script authenticates as the existing local `supabase_admin` using
`POSTGRES_PASSWORD` expanded inside the container (never printed or placed in
host arguments), creates both isolated databases from `template0`, restores
schema/data first, reinstates the original GraphQL wrapper and extension
membership, then replays **all** archived ACL/default-ACL entries. RLS probes
explicitly switch to `authenticated` for owner and unrelated-account checks.

Exact local prerequisites:
- Python 3 and Docker CLI on the host; active Docker endpoint must be a local
  `unix://` socket. Remote Docker endpoints are rejected.
- Running container `supabase_db_reflexjourney`, containing `postgres` with the
  migrated app schema, Supabase Auth schemas, cluster roles, and the GraphQL wrapper.
- `pg_cron` must be absent; do not change a shared/live DB to meet this condition.
- `supabase_admin` must be able to log in using the container's `POSTGRES_PASSWORD`
  and create/drop databases. Bash, `/dev/fd`, `psql`, `createdb`, `dropdb`,
  `pg_dump`, and `pg_restore` must be available inside the container.
- Extensions required by the source schema must be available. Verified here:
  PostgreSQL 17.6; pg_graphql 1.5.11, pg_net 0.20.0, uuid-ossp 1.1,
  pg_stat_statements 1.11, pgcrypto 1.3, postgis 3.3.7, plpgsql 1.0,
  supabase_vault 0.3.1. Source and target share the existing cluster roles.
  Evidence: `restore-prerequisites-20260906-session.log`,
  `restore-extensions-20260906-session.log`.
- Existing local accounts are allowed. Only schema is copied from `postgres`;
  account/child/journal fixtures and their full dump exist only in temporary DBs.

Observed successful output: 46 public tables, 45 RLS tables, 95 policies,
21 public triggers, 824 public functions; `schema_metadata_matches`,
`graphql_wrapper_definition_matches`, `synthetic_data_matches`,
`owner_rls_passed`, `cross_account_rls_passed`, and
`isolated_databases_and_dump_files_removed` all **true**. Synthetic dump:
1,135,179 bytes. Independent cleanup query: **0** restore databases remaining,
**2** existing local auth accounts, **0** pg_cron extensions.

This is a local schema/synthetic-data and journal-RLS rehearsal. It does not test
production backups, point-in-time recovery, Storage object files, independently
restored cluster roles, or release binaries.

**Exact next step (updated 2026-09-07):** ownership migration verification is
already recorded complete in `tasks/todo.md` (2026-09-06), and the admin PostCSS
item is now closed with the web evidence above. Continue the separately scoped
founder/external release checks; rebuild release binaries before any store
submission. No further mobile gate is needed for these documentation-only edits.

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
