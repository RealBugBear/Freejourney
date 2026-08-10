# Reflex Journey — Operating Manual for AI Agents

You are working on **Reflex Journey** (rebranded from CoreJourney): a Flutter app for
primitive-reflex-integration training. It is **health-adjacent and holds children's data**
(child profiles under a parent account). The founder is **solo and non-technical** — explain
what you do in plain language, work hands-off through everything not explicitly gated, and
never require him to debug your output.

This file is binding. When it conflicts with your instincts, this file wins.

---

## 1. The territory — two repos, four projects

| Task involves… | Work in… | Commit in… |
|---|---|---|
| Mobile app, Supabase migrations/functions, launch tasks | `app/` (THIS directory) | nested `app/` git repo |
| Admin dashboard (Next.js 15) | `../admin-web/` | **outer** repo |
| Auth pages / Universal Links site | `../reflexjourney-app-site/` | **outer** repo |
| Product specs, outer planning docs | `../specs/`, `../docs/` | **outer** repo |

- Correct app path: `/Users/alexandermessinger/dev/claudvibes/reflexjourney`.
  `/Users/alexandermessinger/dev/corejourney` is an **obsolete clone — never touch it**.
- The outer folder `corejourney` and Dart package `corejourney` keep the old name;
  everything user-facing is Reflex Journey / `de.reflexjourney.app` / `reflexjourney.app`.
- The outer `supabase/` folder is a stub. Real migrations/functions live in `app/supabase/`.
- Supabase project: `sxvpiggednbftfqeokyd`, West EU (Ireland). **One project for
  dev/staging/prod — the live DB contains real user data. There is no throwaway environment.**

**Before any substantial action, verify all three:** current directory → which git repo is
active (`git rev-parse --show-toplevel`) → which project the task belongs to.

## 2. Session protocol

Read, in order, at every session start:
1. This file
2. `tasks/lessons.md` — mistakes already made once; do not repeat them
3. `docs/LAUNCH_READINESS_BACKLOG.md` — single source of truth for WHAT is open
4. `docs/LAUNCH_TASK_PROMPTS.md` — status tracker + exact execution prompt per T-task
5. `docs/LAUNCH_MASTER_PROMPT.md` — full session rules (gated actions, redaction, evidence)

Then:
1. **State snapshot first:** `git status` in the app repo (and outer repo if relevant).
   Report the uncommitted state in 1–2 sentences. In-flight work from earlier sessions is
   normal — never sweep it into your commits.
2. Pick the highest-priority non-blocked item (P0 → P3; P4 only if explicitly chosen), or
   the item the founder named. **Announce it, don't ask.**
3. T-numbered items: set tracker status to `🔄`, follow the task prompt **exactly** (role,
   scope, acceptance criteria, non-goals). Check the 🔶 Founder-Review index: if an open
   R-block gates your item, present it verbatim for decision before implementing.
4. Non-trivial work (3+ steps or architectural choices): write a plan to `tasks/todo.md`
   with checkable boxes before touching code. Trivial items: just say what you're doing.
5. When done and verified, tick the backlog/tracker with an evidence note (format in §6).
6. Before ending: update the backlog's **Next up** block, update tracker status for every
   touched task, update `tasks/lessons.md` if you were corrected, and print the next
   workable task's prompt verbatim.

## 3. Permissions — autonomous vs. founder-gated

**Autonomous (do without asking):** anything read-only or local-only — git status/diff/log,
`flutter analyze`, tests, `make release-readiness-mobile`, reading files, read-only SQL
against the live DB (redacted, see §5), `supabase secrets list` (names only), editing
working-tree files, and local commits under the commit discipline in §6.

**Gated (show exactly what will happen + get explicit founder go, every time):**
- Mutating SQL on the live DB (INSERT/UPDATE/DELETE/DDL/policy changes) — present the exact
  SQL, blast radius, and rollback first
- Deploying or deleting Edge Functions
- Changing Supabase secrets, auth settings, or dashboard configuration
- **`git push` — never.** `.github/workflows/deploy_production.yml` exists; a push can
  trigger a production deploy.
- Anything destructive or hard to reverse (force-push, deleting files outside the working
  tree, store submissions)

A standing go in the founder's message covers exactly what it names, for this session only.
Say so when you use one. When blocked on a gate, continue with the next workable item and
present all blocked items together at the end.

## 4. Architecture and conventions (Flutter app)

- **Features:** `lib/features/<name>/{data,domain,presentation}/`. Abstract repository in
  `domain/repositories/`, Supabase implementation in `data/repositories/supabase_*_repository.dart`,
  Riverpod wiring in `presentation/providers/`. Screens end `_screen.dart`, files snake_case.
- **State:** `flutter_riverpod`. Core singletons are throw-stub providers in
  `lib/bootstrap/providers.dart`, overridden at startup via `bootstrapOverrides()`. Follow
  the existing provider taxonomy (`Provider` for repos, `StreamProvider` for streams,
  `StateNotifierProvider` for flows).
- **Offline-first sync (the biggest maintenance liability — touch with care):** Drift DB in
  `lib/core/database/`, outbox in `sync_jobs` table, engine in `lib/core/sync/sync_service.dart`.
  Pattern for user data writes: write Drift locally → `enqueueUpsert()`/`enqueueDelete()` →
  fire-and-forget `drain()`. Rehydration on sign-in: server wins unless local `needsSync=true`.
  After Drift table changes: `dart run build_runner build` (generated files are committed).
- **Routing:** `go_router`, all in `lib/core/navigation/app_router.dart`. Feature gates use
  the redirect pattern (`communityGateRedirect`, `paywallGateRedirect`) — gated routes
  redirect to dashboard, never crash.
- **Launch flags:** `lib/config/launch_flags.dart` — compile-time `const bool` only
  (`kCommunityEnabled`, `kVideoCallsEnabled`, `kPaywallEnabled`) for ordinary product
  features. Hidden features stay compiled and tested ("sleeping, not dead"). Each flag's
  doc comment lists every gated surface and the reactivation preconditions — keep those
  comments current. **Narrow approved exception (PM-D12, Founder 2026-07-19):** paid
  `premium`/`studio` surfaces may use server-side `sales_rollout` and `feature_rollout`
  states because a compile flag cannot stop sales without a store update. This is not a
  general remote-config system: writes are service-role-only, clients read only,
  unavailable/unconfigured state means sales off while existing valid access is left
  unchanged, and compile flags remain the only gate for everything else.
- **Localization:** every user-facing string goes into `lib/l10n/app_en.arb` (template)
  AND `app_de.arb`, then `flutter gen-l10n`. Generated `app_localizations*.dart` are
  committed. German copy addresses the user as "du".
- **Migrations:** `supabase/migrations/YYYYMMDDNN_descriptive_snake_case.sql`, idempotent,
  and `supabase db reset --local` must replay green including your new file. Same-day
  ordering comes from the NN suffix.
- **Edge Functions:** kebab-case folders under `supabase/functions/`, Deno `index.ts`,
  JWT verification on by default. Verify with `deno check`. Cron functions authenticate via
  `x-cron-secret` and fail closed if `CRON_SECRET` is unset.
- **Entitlements/roles are server-side only:** `profiles.role` and `profiles.is_premium`
  are protected by DB triggers (`trg_prevent_direct_role_change`,
  `trg_prevent_direct_premium_change`). Never build a client-side path that grants either.
- **Logging:** `appLogger` from `lib/core/logging/`, never `print`. Sentry is configured
  privacy-minimal (no PII, no messages, errors + stacktraces only) — don't loosen it.
- **Internal tester gate:** `@reflexjourney.de` email domain (dev tools, package switching).
- **Tests:** mirror `lib/` under `test/`. Widget harness = `ProviderScope` with overrides +
  minimal `MaterialApp` with l10n delegates. Hand-written stubs/fakes (mocktail is unused).
  `AppDatabase.inMemory()` for DB-touching tests.
- **admin-web:** anon key + RLS/RPCs only, never a service-role key in the client. Mutations
  go through Edge Functions (`lib/functions.ts`); admin gate is `requireAdmin()` server-side.

### Commands

```bash
make run           # physical iPhone (profile mode only — debug/release fail on iOS 26 beta; unlock phone first)
make run-sim       # iOS simulator, debug
make run-android   # Android — the ONLY sanctioned way (see mistake #1)
make release-readiness-mobile   # analyze + full test suite — the standard "am I done" gate
make bump-build    # REQUIRED before every store upload (pubspec is the only build-number source)
flutter gen-l10n                # after .arb changes
dart run build_runner build     # after Drift table changes
flutter build ios --flavor production -t lib/main_production.dart --release --no-codesign  # prod build check
```

Read-only live SQL (token stays in keychain, never printed):

```bash
TOKEN=$(security find-generic-password -s "Supabase CLI" -a supabase -w | sed 's/^go-keyring-base64://' | base64 -d)
curl -s -X POST "https://api.supabase.com/v1/projects/sxvpiggednbftfqeokyd/database/query" \
  -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" \
  -d '{"query": "<read-only SQL>"}'
```

## 5. Data redaction — always

The live DB holds health-adjacent and children's data. **Never print user rows, journal or
message contents, names, emails, device tokens, or secret values into the chat** — not even
from read-only queries. Report counts, booleans, table names, policy names, and pass/fail
only. If a query would return user data, rewrite it to return aggregates. Secret *names*
are fine; values never.

## 6. Known failure modes — the mistake, and the rule that prevents it

1. **The Stale-APK Trap.** `flutter run` on Android without `--flavor development` silently
   installs a cached `app-debug.apk` from the wrong project — wrong logo, wrong code, no
   error. → *Only ever `make run-android`. Never invoke `flutter run -d <android-id>` manually.*
2. **The Wrong-Directory Mistake.** Editing the obsolete `/dev/corejourney` clone.
   → *Verify `pwd` ends in `claudvibes/corejourney/app` before editing app code.*
3. **The Two-Repo Mixup.** Committing admin-web/site/specs work into the app repo or vice
   versa. → *Run `git rev-parse --show-toplevel` before every commit; match it against the
   table in §1.*
4. **The Swept-Index Commit.** `git mv` (and earlier adds) stage immediately; a later
   `git add <file> && git commit` sweeps them into an unrelated commit. → *Immediately
   before every commit run `git diff --cached --name-status`; the staged list must contain
   exactly the files in your commit plan — nothing inherited.*
5. **The Invented Evidence.** Writing a commit hash, test count, or "verified" into a plan
   or tracker before the action ran. → *Evidence notes are written only AFTER the referenced
   action produced observed output. Drafts use unchecked boxes and placeholders, never
   invented identifiers.*
6. **The Optimistic Tick.** Marking a checkbox or tracker ✅ because the work *should* be
   done. → *✅ requires the format `✅ YYYY-MM-DD — <what ran/was checked> → <observed
   result>`, citing real command output or an evidence file. Partially done items get
   split: tick the done part with evidence, leave the rest as its own unchecked box.*
7. **The Innocent SELECT.** `SELECT my_function()` can mutate data — "it's a SELECT" does
   not mean read-only. → *Read-only SQL = SELECT on tables, views, and system catalogs.
   Call a function on the live DB only after reading its definition and confirming it
   cannot write.*
8. **The PII Leak.** Pasting query results containing emails, names, or message contents
   into chat "as evidence". → *§5 applies to every query, every time. Aggregates only.*
9. **The Silent Deploy.** Pushing to remote "to back up work" — a push can trigger the
   production deploy workflow. → *Never `git push` without an explicit founder go. All §3
   gated actions need the go even when you're confident.*
10. **The Env Commit.** Committing `.env.dev` / `.env.prod`, or echoing a secret value while
    debugging. → *Env files are never staged. Secret names may be listed; values never
    retrieved into output.*
11. **The SQL-Editor Drift.** Applying schema/policy changes only via dashboard or ad-hoc
    SQL, so repo and DB diverge. → *Every schema or security change is a timestamped
    migration in `supabase/migrations/` that replays green locally. If repo and live DB
    disagree: the live DB is the fact; fix the repo to match reality, then change reality
    via migration.*
12. **The Half-Translated String.** Adding an l10n key to one `.arb` only, or hardcoding a
    German string in a widget. → *Every string lands in `app_en.arb` AND `app_de.arb`, then
    `flutter gen-l10n`. No user-facing literals in widget code.*
13. **The Hand-Edited Generated File.** "Fixing" `app_localizations_*.dart` or `*.g.dart`
    directly. → *Only edit sources (.arb files, Drift table definitions) and regenerate.*
14. **The Amputated Screen.** Hiding a feature and leaving an empty section, orphaned
    heading, lone divider, or dead-end CTA. → *Every screen that lost an entry point gets a
    before/after screenshot in `docs/evidence/`; layouts must look intentional, not gated.
    (Founder-Auflage 2026-07-06 — hard acceptance criterion.)*
15. **The Healing Promise.** German or English copy that claims therapy, healing, diagnosis,
    or medical benefit. → *All copy (app, store, website) describes activities only. No
    medical-claim language anywhere, including keywords. Explicit "kein Medizinprodukt"
    stance.*
16. **The Dirty-File Layering.** Editing a file that `git status` already shows as modified,
    without knowing what's in the existing diff. → *Inspect the file's current diff first.
    If you must layer onto it, say so explicitly and keep your change minimal. Never commit
    a diff that mixes pre-existing unrelated changes with your work — stop and show it.*
17. **The Chained Mutation.** Combining a repo mutation with a long-running command
    (`git mv … && supabase db reset`). → *Repo mutations are single-purpose, individually
    auditable commands; run long verifications separately.*
18. **The Resurrection Bug.** Re-enabling `flutter_tts` or `device_calendar` (they crash on
    iOS 26), deleting "unused" flag-gated code, or removing the Agora dependency to "clean
    up". → *Disabled dependencies stay disabled; sleeping features stay compiled and tested;
    reactivation follows the preconditions documented in `launch_flags.dart` and tracker R9.*
19. **The Forgotten Bump.** Building a store upload with a stale build number. → *`make
    bump-build` before every upload; pubspec is the single source; never edit the marketing
    version without a founder decision.*
20. **The Scope Surprise.** Silently fixing or building something the founder hasn't seen
    because it "seemed needed". → *New blockers or security findings get added to the
    backlog under the right priority and flagged — visible scope, not silent scope.*

**After any founder correction:** add the pattern to `tasks/lessons.md` in the style above
(what happened → the rule that prevents it). That file exists so mistakes are made at most
once.

## 7. Quality bars — checkable, not adjectives

A code change is done when **all** of these are true:
- [ ] `flutter analyze --no-fatal-infos` → 0 errors, 0 warnings (infos are tracked
      deprecation debt, allowed)
- [ ] `flutter test` → 100% pass (`make release-readiness-mobile` runs both)
- [ ] New behavior has at least one test; changed behavior has an updated test
- [ ] If flags, Info.plist, AndroidManifest, or pubspec were touched: prod build passes
      (`flutter build ios --flavor production -t lib/main_production.dart --release --no-codesign`)

A UI change is done when, additionally:
- [ ] Every new string exists in both `.arb` files and `gen-l10n` ran
- [ ] Before/after screenshots for every touched screen are in `docs/evidence/<task>/`
- [ ] No screen shows an empty section, orphaned control, or dead-end where something was
      removed

A DB/security change is done when, additionally:
- [ ] Migration file follows `YYYYMMDDNN_name.sql` and is idempotent
- [ ] `supabase db reset --local` replays green including the new migration
- [ ] If applied live: apply response + read-only verification dumps (columns/policies/
      function defs) saved under `docs/evidence/<task>/`, and local↔live diff reported
- [ ] RLS impact stated explicitly (which policies, which roles)

A commit is done when:
- [ ] `git diff --cached --name-status` lists exactly the planned files
- [ ] One concern per commit; message references the backlog/task ID
      (e.g. `fix(security): gate chat-triage-bot behind JWT + membership (P0.2)`)
- [ ] Committed file list appears in your summary so the founder can audit

A session is done when:
- [ ] Tracker status updated for every touched task (✅ with evidence / ⛔ with blocker)
- [ ] Backlog boxes ticked with evidence notes; **Next up** block updated
- [ ] `tasks/lessons.md` updated if a correction happened
- [ ] The next workable task's prompt printed verbatim (or the founder decision table, if
      the next step is founder-only)
