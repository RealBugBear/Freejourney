# Handoff prompt — implement "Begleitung beenden"

Paste everything below the line into a fresh Cursor session with the repository open.

---

You are implementing a feature in **Reflex Journey**, a Flutter + Supabase app for primitive-reflex-integration training. It is health-adjacent and stores data about **children** under parent accounts. Treat access control as the primary concern of this task, not a detail of it.

## Working directory

```
/Users/alexandermessinger/dev/claudvibes/reflexjourney
```

Verify with `git rev-parse --show-toplevel` before your first commit. Two decoy directories exist and must never be touched: `/Users/alexandermessinger/dev/corejourney` (obsolete clone) and `/Users/alexandermessinger/dev/claudvibes/corejourney/app` (empty shell left by a directory move). Both have the same bundle id, so editing the wrong one fails silently.

## Read before writing anything

1. `CLAUDE.md` — binding operating rules for this repo. Section 6 lists twenty known failure modes; you are expected not to repeat them.
2. `docs/superpowers/specs/2026-08-21-begleitung-beenden-design.md` — the design and, more importantly, the reasoning. Written in German.
3. `docs/superpowers/plans/2026-08-21-begleitung-beenden.md` — **your instruction set.** Nine tasks with the actual SQL, Dart and test code to write.

Read all three before Task 1. The plan tells you what to type; the spec tells you why, which is what you will need when something does not behave as the plan predicts.

## What you are building

A client (a parent) currently cannot end a trainer relationship. The only exit is accepting a different trainer's invite code. Worse, ending one is not durable: a background reconcile re-derives relationships from chat membership and open appointments, and flips a disconnected relationship back to active the next time the trainer opens their client list.

You are adding a real end: it revokes the trainer's access to the child's reflex profiles, cancels open appointments, ends chat write rights on both sides, notifies the trainer exactly once, and cannot be undone by the reconcile.

## Non-negotiable rules

- **Never `git push`.** A push can trigger the production deploy workflow. Local commits only.
- **Never touch the live database.** One Supabase project serves dev and prod and holds real user data. Everything is verified against the local stack. Live apply is the founder's decision, not yours.
- **Never deploy an Edge Function.** Task 5 writes and type-checks one; deploying it is the founder's decision.
- **Never print user data.** Not from queries, not into evidence, not into the chat. Counts, booleans and table names only. Tests use synthetic UUIDs and `@example.invalid` emails.
- **Every user-facing string goes into both `lib/l10n/app_en.arb` and `lib/l10n/app_de.arb`**, then `flutter gen-l10n`. No string literals in widgets. German addresses the user as "du".
- **No medical claims** in any copy — no healing, therapy, diagnosis or benefit language. Never assert that a notification was delivered; say the trainer "wird informiert".
- **Every `SECURITY DEFINER` function** gets `SET search_path = public, pg_temp`, schema-qualified objects, and `REVOKE ALL ... FROM PUBLIC, anon;` **before** `GRANT EXECUTE ... TO authenticated;`. PostgreSQL grants EXECUTE to PUBLIC on `CREATE FUNCTION`, so granting to `authenticated` alone leaves the function callable by `anon`.

## How to work

Work the nine tasks **in order, one at a time**. Do not batch them and do not read ahead to "save time" — each task ends at a point where the repository is consistent and reviewable.

Every task follows the same cycle, and the order matters:

1. Write the failing test.
2. **Run it and read the failure.** Confirm it fails for the reason the plan predicts. A test that fails because of a typo in your fixture proves nothing.
3. Implement.
4. Re-run until green.
5. Commit.

Before every commit run `git diff --cached --name-status` and confirm the staged list is exactly the files that task names. The working tree already carries unrelated modifications to `android/settings.gradle.kts`, `firebase.json` and `pubspec.yaml` from earlier work — **never** stage those.

Commit messages: one concern per commit, imperative mood, `type(scope): summary`. Look at recent `git log` for the house style.

## Environment

Start the local Supabase stack once:

```bash
supabase start
```

Run a pgTAP suite:

```bash
docker exec -i supabase_db_reflexjourney psql -U postgres -d postgres < supabase/tests/<file>.sql
```

Flutter quality gate:

```bash
make release-readiness-mobile
```

Two quirks that are **not** your bugs, documented so you do not chase them:

- `supabase/config.toml` is untracked. It was recreated on 2026-08-21 after being lost in a directory move. It is required locally; leave it untracked unless asked.
- `supabase db reset --local` currently fails on the pre-existing migration `2026072301_moro_content_snapshot_v1.sql` — it writes `exercises.rhythm_type`, a column that lives only in the hand-run `supabase/exercises_migration.sql` and in no migration. To run a clean replay, temporarily move that one file out of `supabase/migrations/`, reset, then put it back unchanged. **Never commit its removal**, and do not fix it here — it is tracked separately.

## Definition of done

- `supabase db reset --local` replays green including both new migrations
- Both new pgTAP suites green
- The two existing suites still green — `2026082101_reflex_share_revocation_test.sql` (10 tests) and `2026071901_multi_grant_entitlements_test.sql` (95 tests). You are changing functions they exercise indirectly; a regression here is a blocker.
- `make release-readiness-mobile` → 0 errors, 0 warnings, 100% tests pass
- `deno check` clean for the new Edge Function
- `python3 scripts/i18n_check.py` parity passes
- Before/after screenshots for the chat composer in `docs/evidence/begleitung-beenden/`
- Evidence file written **from output you actually saw** — never write a count, hash or "verified" before the command has run

## When something does not match the plan

The plan was written against the code as it stood on 2026-08-21 and every claim in it was verified against a running database. If reality disagrees with it, that is information, not an obstacle to route around.

**Stop and report** rather than improvising, specifically if:

- Task 4 step 1 finds a shipped flow that legitimately messages a trainer without an *active* relationship — for example a pending discovery request. Widening the policy to `status IN ('active','pending')` would be a design change, and the spec would need amending first.
- A column or function referenced by the plan does not exist or has a different shape.
- Making a test pass would require weakening one of its assertions.

Do not weaken a test to make it pass. Do not add `try`/`catch` around a failing call to move on. If you are blocked, say what you found, what you expected, and what you think it implies.

## Not in scope

Do not fix these even though you will encounter them:

- `trainer_notes`, a free-text field where trainers write about clients — an open legal question, deliberately untouched.
- The same notification-replay gap in the existing `notify-*` functions.
- The two redundant partial unique indexes on `trainer_client_relationships`.
- The broken `2026072301` migration.
- Deduplicating existing `disconnected` rows.

If you spot something else worth fixing, note it at the end of your final summary rather than doing it.
