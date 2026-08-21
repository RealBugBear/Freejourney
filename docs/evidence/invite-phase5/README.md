# Phase 5 — Deep Link + dateibasierter Speicher

**Datum:** 2026-08-21  
**Flag:** `kInviteEnabled = false` (UI gegated; Landing/Speicher unabhängig)

## Geliefert

| Teil | Ort |
|---|---|
| `PendingInviteStore` (30-Tage-TTL, kein SharedPreferences) | `lib/core/storage/pending_invite_store.dart` |
| Deep-Link-Parser `/einladung` + `/en/einladung` | `lib/core/navigation/invite_deep_link.dart` |
| Handler in `lib/app.dart` (speichern immer; UI nur bei Flag) | + Sign-in öffnet pending Code ohne Auto-Redeem |
| Android `pathPrefix` `/einladung` + `/en/einladung` | `AndroidManifest.xml` |
| AASA-Pfade (prod/staging/dev) | Website-Repo `.well-known` + `public/.well-known` |
| Baum: `previousActivatedCount` aus Store | `InviteScreen` |
| Confirm-Sheet scrollbar bei 200 % Textskala | `invite_confirm_sheet.dart` |

## AASA (Website-Repo)

Beide Kopien (`.well-known/` und `public/.well-known/`) müssen **pro AppID**
mindestens enthalten:

- `/auth/*` (deckt `/auth/confirm`, `/auth/reset-password`, …)
- `/einladung`, `/einladung/*`, `/en/einladung`, `/en/einladung/*`

Regression im Website-Repo: `npm run test:aasa`
(`scripts/aasa_paths.test.mjs`). Die Flutter-Suite setzt kein Schwester-Repo voraus.


## Noch offen (Abschluss-Gate)

Manuelle Geräteprüfung iPhone + Android:

`https://reflexjourney.app/einladung?c=<TESTCODE>`

in den drei Anmeldezuständen. AASA-Änderungen brauchen Website-Deploy und
ggf. AASA-Cache-Zeit, bevor Geräte sie sehen.

## Tests (beobachtet) — maßgebliches Ergebnis

| Suite | Umfang | Ergebnis |
|---|---|---|
| Flutter | Store + Deep-Link + Invite (inkl. Redeem clear/keep) **nach** Memory-Only-Fix | **grün** |
| Website | `npm run test:aasa` | **1/1 passed** |
| Analyze | store / deep-link / invite | No issues found |

**Maßgeblich** ist nur der Lauf nach dem Memory-Only-Fix am
`PendingInviteStore` (Widget-Tests unter FakeAsync ohne blockierende
dart:io-Queue). Darin u. a.: terminale RPCs löschen Pending-Code; Decline /
Netzwerkfehler behalten ihn; Parser, TTL, serialisierte Mutationen.

### Überholte Evidence (nicht zitieren)

Redeem-Läufe mit **Timeout** (~10 Min.) auf
`terminal non-accepted…` / `accepted RPC clears…` /
`decline and network errors keep…` stammen **vor** dem Memory-Only-Fix.
Status: **überholt — kein aktueller Fehler.** Nicht als Phase-5-Ergebnis
verwenden.

Flutter setzt kein Schwester-Repo voraus (AASA-Prüfung nur im Website-Repo).
