# Phase 4 — Redeem, confirm, settings, onboarding

**Datum:** 2026-08-21 (Korrektur-Iteration)

## `_postAuthHome` (vorgefunden)

Nur: lokaler Consent → Dashboard, sonst Consent. Kein for-whom / entry-points.
Einstiegsbereiche enden mit Navigation zum Dashboard.

**Einbau:** Onboarding-Redeem **nach** Einstiegsbereichen (`?onboarding=1`),
wenn `kInviteEnabled`. `_postAuthHome` unverändert.

## Geliefert (nach Review-Korrektur)

- Confirm-Sheet zeigt **Code**, **Nutzen** (`inviteWhy`) und Datenschutztext
- Settings: eigener Abschnitt „Einladen“ (vor „Erweitert“), nicht unter Advanced
- Fehler: PostgREST/`SocketException` → Offline; `FormatException` → `inviteErrorUnexpected`
- Route `/einladung` + Gate; Settings → `/einladen`; Flag bleibt aus
- Tests: Code/Nutzen im Sheet; „Nicht jetzt“ ohne RPC; Skip→Dashboard;
  Ablehnen bleibt auf Redeem; Netzwerk vs. FormatException

## Tests (beobachtet)

`flutter test test/features/invite/` → **47/47 passed**  
`dart format` auf geänderte Invite-/Router-/Settings-Dateien  
`flutter analyze` inkl. `app_router.dart` → No issues found
