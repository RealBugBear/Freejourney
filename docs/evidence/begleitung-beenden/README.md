# Begleitung beenden — verification evidence

**Datum:** 2026-08-21  
**Spec:** `docs/superpowers/specs/2026-08-21-begleitung-beenden-design.md`  
**Plan:** `docs/superpowers/plans/2026-08-21-begleitung-beenden.md`  
**Live-Apply / Edge deploy / git push:** ❌ not done — founder gates (CLAUDE.md §3)

## What was built

| Piece | Location |
|---|---|
| Client-end markers + `end_trainer_relationship` | `supabase/migrations/2026082102_relationship_end_lifecycle.sql` |
| Resurrection guard + switch marking | same migration |
| Direct-chat write gate via `can_write_chat_channel` | `supabase/migrations/2026082103_direct_chat_write_requires_relationship.sql` |
| Lifecycle write lock (INVOKER trigger) | `supabase/migrations/2026082104_protect_relationship_lifecycle.sql` |
| Idempotent trainer notify (not deployed) | `supabase/functions/notify-accompaniment-ended/` |
| Client UI + provider | `lib/features/accompaniment/…`, `trainer_provider.dart` |
| Locked composer | `chat_channel_screen.dart` + `channelWritableProvider` |

## Commits (local only)

| Hash | Message |
|---|---|
| `942bb26` | feat(db): add end_trainer_relationship RPC and client-end markers |
| `ee168bb` | fix(db): stop reconcile from resurrecting a client-ended relationship |
| `1357fd2` | fix(db): mark displaced relationships on trainer switch and clear markers pair-wide |
| `46f60ca` | fix(security): require an active relationship to write in a direct channel |
| `8756594` | fix(security): block direct writes to relationship lifecycle columns |
| `f6ab001` | feat(notify): add idempotent accompaniment-ended trainer notification |
| `3a8496a` | feat(accompaniment): add endTrainerRelationship provider call and copy |
| `eb1f373` | feat(accompaniment): let clients end a trainer accompaniment |
| `7d9e986` | feat(chat): explain the locked composer after an accompaniment ends |

## pgTAP (observed after clean `supabase db reset --local`)

Moro migration `2026072301` temporarily moved aside for reset (restored unchanged). Reset finished including `2026082102`, `2026082103`, `2026082104`.

| Suite | Plan | `not ok` |
|---|---|---|
| `2026071901_multi_grant_entitlements_test` | `1..95` | 0 |
| `2026082101_reflex_share_revocation_test` | `1..10` | 0 |
| `2026082102_relationship_end_lifecycle_test` | `1..28` | 0 |
| `2026082103_direct_chat_write_test` | `1..10` | 0 |
| `2026082104_relationship_lifecycle_protection_test` | `1..9` | 0 |

`prevent_direct_relationship_lifecycle_change` has `prosecdef = f` (INVOKER).  
`can_write_chat_channel` and `end_trainer_relationship` remain DEFINER (`prosecdef = t`).

## Flutter / Deno / i18n (observed)

| Check | Result |
|---|---|
| `deno check notify-accompaniment-ended/index.ts _shared/notification_copy.ts` | exit 0, no errors |
| `python3 scripts/i18n_check.py` | `i18n check passed: app_en.arb has 1202 message keys in parity with the DE template.` |
| `flutter test test/features/accompaniment/end_accompaniment_dialog_test.dart` | 3/3 passed |
| `flutter analyze --no-fatal-infos` on touched accompaniment/chat/trainer provider paths | No issues found |

### Known blockers for full `make release-readiness-mobile`

Not introduced by this feature; recorded so the gate is not falsely claimed green:

1. `scripts/i18n_quality_check.py` exits 1 on three pre-existing allowlist keys (`routineMode`, `trainingRoutineSubtitle`, `tutorialMode`) — “values are no longer identical”.
2. Full `flutter test` previously reported 3 failures in `immersive_session_screen_completion_test.dart` (google_fonts network load of Poppins), unrelated to accompaniment-end.

## Dry-run (local, aggregates only)

Snippet: `supabase/snippets/begleitung_beenden_dryrun.sql`  
Observed on fresh local DB:

```
likely_switch | no_active_trainer | resurrectable_chat | resurrectable_appt | duplicate_pair | total_disconnected
0 | 0 | 0 | 0 | 0 | 0
```

**Not run against live.** Founder go required; results would be counts only.

## Screenshots

| File | Content |
|---|---|
| `composer-before-writable.png` | Writable composer chrome (input + send) |
| `composer-after-locked.png` | Locked notice using DE copy `chatWriteLockedNoRelationship` |

Captured as static evidence of the amputated-screen replacement (sim login path not used). After image shows the real German string from l10n.

## Explicitly not done

1. Live apply of `2026082101`, `2026082102`, `2026082103`, `2026082104`
2. Deploy of `notify-accompaniment-ended`
3. Backfill decision for historical `disconnected` rows (needs live dry-run counts)
4. `git push`
5. Protecting / relocating `trainer_notes` behind an RPC
