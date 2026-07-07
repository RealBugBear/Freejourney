# Release Readiness Checklist

Scope: latest core flows (hands-free training, reminders v2, offline sync, dashboard progress UI).

## Automated checks

Run:

```bash
make release-readiness-mobile
```

For Phase-0 stabilization rounds (recommended):

```bash
make phase0-smoke
```

Expected:
- `flutter analyze` has no errors
- `test/features/progress/streak_logic_test.dart` passes
- Phase-0 prompt includes midnight/offline/restart smoke cases

## Build-Nummer (vor JEDEM Store-/TestFlight-Upload)

Schema: `version: X.Y.Z+YYYYMMDDNN` in `pubspec.yaml` (Datum + zweistellige
Tageslaufnummer). Das ist die **einzige Quelle** — iOS `CFBundleVersion` und
Android `versionCode` erben daraus, und `make testflight` /
`make android-testers` lesen sie seit T16 ebenfalls von dort.
Limit-Check (T16): Androids `versionCode`-Maximum ist 2.147.483.647 —
`YYYYMMDDNN` bleibt bis Ende 2099 darunter (2099123199 < 2147483647);
Apple verlangt nur strenge Monotonie pro Version.

- `make bump-build` — Build-Nummer auf heute setzen; mehrfach am selben Tag
  → NN zählt hoch (01, 02, …). **Vor jedem Upload ausführen.**
- `make bump-patch` — Patch-Version erhöhen (1.0.5 → 1.0.6) + Build-Nummer
  auf heute+01. Marketing-Version nur nach Founder-Entscheidung.

## Manual smoke (must-pass)

1. Hands-free training
- Start training in `Routine (Hands-free)` mode.
- Screen stays on during the session.
- Audio/haptic feedback works according to selected feedback mode.
- Background music (e.g. Spotify/Apple Music) keeps playing.

2. Reminder behavior v2
- Enable reminders and set cadence (`Minimal` and `Ausgewogen`).
- Verify no duplicate reminder is scheduled.
- Verify "already trained today" pushes reminder to next day.
- Verify in-window reminder uses delayed scheduling.

3. Offline-first sync
- Put device in airplane mode.
- Complete training and change settings while offline.
- Go back online and verify queue drains to zero.
- Confirm data appears correctly after sync.

4. Dashboard consistency
- Complete a training and return to dashboard.
- Verify `Heute`, `Diese Woche`, `Streak`, and `Tag x/28` are consistent.
- Verify momentum bar and journey map match snapshot values.

## Go / No-Go

Go only if:
- automated checks pass
- no critical blockers in manual smoke
- no data loss or duplicate reminder behavior observed
