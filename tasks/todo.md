# P0.1 (3rd checkbox): Convert hand-run RLS scripts into versioned migrations

Session 2026-07-02. Rule applied: "the live DB is the fact; the repo gets
fixed to match reality." Completed — see review below.

## Steps

- [x] 1. Read-only dump of live policy state (pg_policies + rls flags) for the
      13 core tables via Management API — policy metadata only, no user rows.
- [x] 2. Diff live state vs. hand-run scripts (`rls_apply.sql`,
      `journal_entries_migration.sql`) and vs. the migrations pipeline.
- [x] 3. Check remote migration history → `supabase_migrations.schema_migrations`
      does not exist remotely; every past migration was SQL-Editor-applied.
- [x] 4. Write `supabase/migrations/20260702_rls_baseline_core_tables.sql`
      (idempotent; encodes live reality; drops policy names superseded by the
      "cj:" set; includes journal updated_at trigger).
- [x] 5. Handle untracked `20260513_enable_rls_postgis_spatial_ref_sys.sql` —
      it broke replay (not owner of extension table, SQLSTATE 42501, plus
      duplicate version 20260513). Made it permission-safe (EXCEPTION handler,
      NOTICE + skip) and renamed to `2026051301_…` for a unique version.
- [x] 6. Fix second pre-existing replay blocker: `20260601_admin_audit_events.sql`
      sorted after dependent `2026060102_admin_attribution_delete_behavior.sql`
      → `git mv` to `2026060100_admin_audit_events.sql`.
- [x] 7. Verify: `supabase db reset --local` replays all migrations green;
      identical dump query against replayed-local vs. live → only diff is the
      redundant legacy policy "Users manage own journal" (live-only), which
      the new migration intentionally drops.
- [x] 8. Tick backlog checkbox with evidence; add gated follow-up item
      (apply 20260702 on live via SQL Editor).

## Review

- New: `supabase/migrations/20260702_rls_baseline_core_tables.sql` — RLS
  baseline for profiles, enrollments, intake_assessments,
  completion_questionnaires, training_sessions, progress_entries,
  mood_checkins, journal_entries, trainer_client_relationships, access_codes
  (deny-all), device_tokens, user_consents, appointments (incl. the
  live-only "Trainees confirm own appointments" policy that existed in no
  script) + journal updated_at trigger.
- Fixed: `2026051301_enable_rls_postgis_spatial_ref_sys.sql` (was untracked
  in-flight work; permission-safe + unique version).
- Fixed: `2026060100_admin_audit_events.sql` (replay order).
- Verified: full local replay green; local-vs-live policy diff clean modulo
  the intended legacy-policy drop.
- NOT done (gated): applying 20260702 to the live DB. Remote has no migration
  history table; `db push` known to hang against the pooler → SQL Editor is
  the apply path.
