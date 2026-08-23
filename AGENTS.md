# AGENTS.md — Reflex Journey

Binding for every AI coding agent working in this repository (Cursor, Codex,
Claude Code and anything else that reads this file).

## Read this first

**`CLAUDE.md` in the repository root is the operating manual and it is binding.**
Read it in full before touching anything. It covers the directory map, the
architecture and naming conventions, the permission model, the quality bars and
twenty known failure modes with the rule that prevents each one.

Then read `tasks/lessons.md` — mistakes that have already been made once here.

When a task prompt and `CLAUDE.md` disagree, `CLAUDE.md` wins. When a task
prompt and its own spec document disagree, the spec wins. Report the
contradiction instead of resolving it yourself.

## Never, without an explicit go from the owner

These are repeated here because they are the ones that cause real damage, and
because an agent that skipped `CLAUDE.md` still needs to see them.

1. **Never `git push`.** `.github/workflows/deploy_production.yml` exists — a
   push can trigger a production deploy. Local commits are fine.
2. **Never run mutating SQL against the live database.** There is exactly one
   Supabase project (`sxvpiggednbftfqeokyd`) and it holds real user data,
   including children's profiles. There is no staging environment. Migrations
   are written and proven with `supabase db reset --local`; applying them is a
   separate, explicitly approved step.
3. **Never deploy or delete Edge Functions**, change Supabase secrets, auth
   settings or dashboard configuration.
4. **Never print user data.** No names, e-mail addresses, journal or message
   contents, device tokens or secret values — not even as evidence. Counts,
   booleans, table names and policy names are fine. Secret *names* are fine;
   values never.
5. **Never claim a result you have not observed.** "Tested", "verified", commit
   hashes and test counts are written only after the command actually ran and
   you read its output.

## Working here

The owner is a solo founder and not technical. Explain what you did in plain
language. Work hands-off through everything that is not explicitly gated, and
never require him to debug your output.

Definition of done for a code change:

- `flutter analyze --no-fatal-infos` → 0 errors, 0 warnings
- `flutter test` → 100% pass (`make release-readiness-mobile` runs both plus the
  i18n gate)
- new behaviour has at least one test; changed behaviour has an updated test
- every user-facing string exists in **both** `lib/l10n/app_en.arb` and
  `lib/l10n/app_de.arb`, then `flutter gen-l10n` ran
- touched screens have before/after screenshots under `docs/evidence/<task>/`

The Flutter app lives in this directory. `git rev-parse --show-toplevel` must
print this path before every commit — the admin dashboard, the website and the
product specs live in a **different** repository one level up.
