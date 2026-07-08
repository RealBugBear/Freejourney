/// Compile-time launch gates — Founder-Entscheidungen D1/D2 vom 2026-07-06.
///
/// Bewusst simple Konstanten (kein Remote-Config, keine DI): Ein Flag auf
/// `true` stellt die versteckte Oberfläche vollständig und unverändert
/// wieder her. Der dahinterliegende Code bleibt kompiliert und getestet —
/// er schläft nur.
///
/// WICHTIG vor dem Reaktivieren von [kCommunityEnabled]: Melde-Funktion und
/// Nutzer-Blockieren (T02/T03, Apple Guideline 1.2) MÜSSEN vorher umgesetzt
/// sein — siehe docs/LAUNCH_TASK_PROMPTS.md.
library;

/// Video-Calls (D2=A: für v1 versteckt).
///
/// Gated: videocam-Actions in Chat-AppBar und Message-Input-Bar, „Annehmen“
/// auf Call-Request-Bubbles, der globale [IncomingCallListener] sowie
/// Anzeige/Weiterleitung eingehender `video_call`-Push-Events (werden mit
/// Log-Zeile still ignoriert). Agora-Code und Edge Functions bleiben
/// unangetastet; Dev-Verhalten mit Flag=true unverändert.
const bool kVideoCallsEnabled = false;

/// Community-Kanäle + Experience-Feed (D1=A: für v1 versteckt).
///
/// Gated: Routen `/community` und `/experience/:channelId` (Redirect aufs
/// Dashboard), Share-Prompt im Mood-Check-in, Share-Checkbox im
/// Post-Training-Sheet, „Geteilte Erfahrungen“-Karten in Begleitung-Tab und
/// Trainer-Dashboard sowie Community-Feed-Formulierungen im Profil.
/// Trainer-1:1-Chat (DMs) ist davon unabhängig und bleibt aktiv.
const bool kCommunityEnabled = false;

/// Paywall (D4, 2026-07-07: Struktur gebaut, Aktivierung erst post-launch).
///
/// Flag AUS = heutiges Launch-Verhalten: die ersten drei Pakete sind frei,
/// spätere im UI gesperrt, Route `/paywall` leitet aufs Dashboard um.
/// Flag AN = Paket 1 (Moro) frei, Paket 2+ nur mit Entitlement
/// (`profiles.is_premium`, gesetzt ausschließlich server-seitig — DB-Trigger
/// `trg_prevent_direct_premium_change`); Paketübergang und gesperrte Pakete
/// führen zum Paywall-Screen (Trio: Monat/Jahr/Lifetime).
///
/// VOR Aktivierung MÜSSEN vorliegen: R8-Trigger (Founder), Bestandsschutz-
/// Kommunikation, AGB/Widerruf (Anwalts-Baustein 8), T25 (RevenueCat/IAP,
/// echter Kaufweg) und die live angewendete Migration 2026070701.
const bool kPaywallEnabled = false;
