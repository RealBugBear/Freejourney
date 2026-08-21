# Resume prompt — "Begleitung beenden", Task 4 onward

Paste everything below the line into the Cursor session.

---

Your Task 4 diagnosis was correct and the plan has been amended. Two review
points, one new required task, then continue.

Working directory: `/Users/alexandermessinger/dev/claudvibes/reflexjourney`.
All rules from the original handoff prompt still apply — no `git push`, no live
database, no Edge Function deploy, no user data in output.

## 1. Task 4 — the policy was wrong, not your test

You were right about the cause, and it was reproduced independently before the
plan was changed: `other_members_visible_to_sender = 0` while the definer
function returned `true` for the same actor and channel. RLS applies to
subqueries inside a policy expression, so `members_select_own` blinded the inline
`EXISTS`.

The corrected Task 4 is in `docs/superpowers/plans/2026-08-21-begleitung-beenden.md`
(see the **Amendment 2026-08-21** block near the top). Changes:

- The predicate now lives only in the definer function and the policy delegates
  to it.
- The function is renamed `can_write_direct_channel` → **`can_write_chat_channel`**,
  because after delegation it decides for every channel type, not just direct.
  Rename it in your uncommitted migration and test.
- The policy keeps an inline own-membership clause deliberately. It is the one
  part the sender can evaluate under RLS, so the definer function is not the
  sole gate. Keep it.

Both the delegating policy and the final three-clause shape were verified on the
local database: a trainer with an active relationship inserts successfully, and
the unrelated third member of the same channel is still rejected with
`new row violates row-level security policy`. The three-member regression the
policy exists for still holds.

You already applied the broken version locally. Replace the migration file with
the corrected one and re-run `supabase db reset --local` rather than layering a
second policy edit on top.

**Keep your corrected fixture fields** (`name_de` / `name_en` /
`sequence_number`). That adjustment was right and the plan's "adjust the
fixture" note covered it.

## 2. What proves the gate

Only the real `INSERT` attempts — the `lives_ok` / `throws_ok` cases — are
evidence that RLS holds.

The four `can_write_chat_channel` assertions are **unit tests of the function**.
Since the policy now calls that same function, an assertion that the two "agree"
is tautological and proves nothing on its own. They have been relabelled
accordingly. Do not treat a green run of those four as evidence the policy works,
and never relax an `INSERT` assertion to make a run go green.

## 3. New required task — Task 10, do it immediately after Task 4

**The feature you have already built does not currently do what it claims**, and
this is not optional cleanup.

`ended_by_client_at` is not a guarantee. It is a value in a table both parties
can write: `authenticated` holds `UPDATE` on every column and `cj: tcr all
trainer` is `FOR ALL`. Four bypasses were proven on the local database, each in
a rolled-back transaction:

| As | Action | Result |
|---|---|---|
| Ex-trainer | `UPDATE … SET ended_by_client_at = NULL` | succeeds |
| Ex-trainer | `UPDATE … SET status = 'active'` (marker untouched) | succeeds |
| Ex-trainer | `INSERT` a fresh `active` row for the same pair | succeeds — 2 rows, 1 active |
| Client | `UPDATE … SET trainer_id = <other trainer>` | succeeds |

Note rows two and three: **they never touch the marker columns.** Guarding only
`ended_by_client_at` and `end_notification_sent_at` would be security theatre.
The protected set must also include `status`, `trainer_id` and `client_id`, and
the guard must cover `INSERT` as well as `UPDATE`.

Task 10 in the plan has the full migration, the test list and the reasoning. Two
things in it that will not match your instincts, both deliberate:

- **Guard on `current_user`, not `auth.role()`.** The house pattern
  (`prevent_direct_role_change`) uses `auth.role() != 'service_role'`, but that
  pattern does not transfer: those columns are written by Edge Functions holding
  the service-role key, whereas ours are written by `SECURITY DEFINER` RPCs
  invoked by ordinary users. The JWT claim stays `authenticated` inside such a
  function. Measured: inside a definer function `current_user = postgres` and
  `auth.role() = authenticated`; on a direct write both read `authenticated`.
  An `auth.role()` guard would reject `accept_invite()` and
  `end_trainer_relationship()` along with the attacker.
- **Do not use a session GUC** (`set_config('app.…')`) set by the RPCs and
  checked by the trigger. `authenticated` can call `set_config` itself and raise
  the flag before writing. It looks like a guard and is not.

`trainer_notes` is deliberately **not** protected by this trigger — `saveNotes`
writes it directly today, and moving that behind an RPC belongs to a separate
round. Task 10 step 1 includes a `lives_ok` regression asserting note writing
still works; keep it.

After applying the trigger, re-run **every** suite, not just the new one. The
existing fixtures run as `postgres` so the trigger should permit them. If one of
them now fails, that fixture was relying on a write path real users should not
have — report it rather than working around it.

## 4. Then continue

Task 5 → 6 → 7 → 8 → 9, unchanged. Task 8's provider is renamed
`directChannelWritableProvider` → `channelWritableProvider` to match the
function.

Same discipline as before: failing test first, read the failure and confirm it
fails for the stated reason, implement, re-run, `git diff --cached --name-status`
before every commit, one concern per commit. The working tree still carries
unrelated modifications to `android/settings.gradle.kts`, `firebase.json` and
`pubspec.yaml` — never stage those.

Stop and report rather than improvising if a column or function does not match
the plan, or if making a test pass would require weakening an assertion.
