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

/// Community-Kanäle + Experience-Feed (D1=A: für v1 versteckt).
///
/// Gated: Routen `/community` und `/experience/:channelId` (Redirect aufs
/// Dashboard), Share-Prompt im Mood-Check-in, Share-Checkbox im
/// Post-Training-Sheet, „Geteilte Erfahrungen“-Karten in Begleitung-Tab und
/// Trainer-Dashboard sowie Community-Feed-Formulierungen im Profil.
/// Trainer-1:1-Chat (DMs) ist davon unabhängig und bleibt aktiv.
const bool kCommunityEnabled = false;
