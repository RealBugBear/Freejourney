# Feature Flags — Ist-Zustand

Stand: 2026-07-07 (T20). Die frühere Fassung dieses Dokuments beschrieb ein
Firebase-Remote-Config-System, das **nie implementiert wurde** (0 Treffer
im Code; Historie in git).

## Das reale System: compile-time Launch-Flags

`lib/config/launch_flags.dart` — einfache `const bool`-Konstanten, die
Features für den v1-Launch verstecken (Founder-Entscheidungen D1/D2,
2026-07-06):

| Flag | Wert | Versteckt | Reaktivierung |
|------|------|-----------|---------------|
| `kCommunityEnabled` | `false` | Community-Tab, Experience-Feed, Share-CTAs (T04) | NUR mit Reaktivierungs-Checkliste R9 im Backlog (Apple 1.2: Melden/Blocken Pflicht!) |
| `kVideoCallsEnabled` | `false` | Call-Buttons, IncomingCallListener, Call-Pushes (T06) | R9-Checkliste (Agora in Policy/Labels, AGORA_APP_ID in .env.prod) |
| `kUsePrivacyLaunchDraft` (in `consent_screen.dart`) | `false` | Launch-Fassung des Consent-Textes (T05 Stufe 2 aktiviert sie) | nach P0.6 + `kConsentVersion`-Bump |

Eigenschaften: kein Remote-Toggle, keine Laufzeit-Änderung — ein Flag
umlegen heißt: Code ändern, Tests laufen lassen, neues Release. Das ist
für den Launch bewusst so (reversibel, auditierbar, kein
Remote-Config-Risiko im Review).

## Geparkt

- Die Live-Tabelle `feature_flags` existiert in der DB, wird aber von
  keinem Code gelesen — Zukunfts-Option für Remote-Flags, aktuell ungenutzt
  (nicht darauf bauen).
