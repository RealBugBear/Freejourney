/// Compile-time launch gates — Founder-Entscheidungen D1/D2 vom 2026-07-06.
///
/// Bewusst simple Konstanten (kein Remote-Config, keine DI): Ein Flag auf
/// `true` stellt die versteckte Oberfläche vollständig und unverändert
/// wieder her. Der dahinterliegende Code bleibt kompiliert und getestet —
/// er schläft nur.
///
/// Eng begrenzte Ausnahme (PM-D12, Founder-Go 2026-07-19): Nur bezahlte
/// `premium`-/`studio`-Flächen dürfen zusätzlich serverseitige
/// `sales_rollout`-/`feature_rollout`-Zustände lesen. Das ist keine allgemeine
/// Remote-Config: Clients schreiben nie, fehlende Konfiguration stoppt neue
/// Verkäufe und lässt bestehenden gültigen Zugang unverändert. Für alle
/// anderen Features bleiben diese Compile-Flags die einzige Gate-Mechanik.
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
/// (effektiver serverseitiger Multi-Grant-Status; die
/// `profiles.is_premium`-Felder bleiben nur Legacy-Projektion); Paketübergang
/// und gesperrte Pakete führen zum Paywall-Screen
/// (Trio: Monat/Jahr/Lifetime).
///
/// VOR Aktivierung MÜSSEN vorliegen: R8-Trigger (Founder), Bestandsschutz-
/// Kommunikation, AGB/Widerruf (Anwalts-Baustein 8), T25 (RevenueCat/IAP,
/// echter Kaufweg) und alle erforderlichen T25-Migrationen live angewendet.
const bool kPaywallEnabled = false;

/// Nutzer-zu-Nutzer-Einladungen + Wirkungs-Visual (MVP Stufe 1).
///
/// Gated (nur App-Oberfläche): Route `/einladen`, Route `/einladung`
/// (Einlösen), Einstellungs-Eintrag „Freunde einladen“, Onboarding-Schritt
/// nach Einstiegsbereichen, Impulse I1/I2.
/// Datenbank-Trigger, Website-Zielseite und Deep-Link-Landing (inkl.
/// `PendingInviteStore`) zählen unabhängig von diesem Flag.
///
/// Flag AUS = Oberfläche unerreichbar (Redirect aufs Dashboard).
/// Flag AN = Einladen-Screen, Einlösen und Impulse sichtbar.
///
/// VOR Aktivierung: Migration `2026082105_referral_program` live,
/// Phase-5 Deep Links auf iPhone + Android grün, Datenschutzerklärung
/// um „Einladungsbeziehung“ ergänzt, AASA-Pfade `/einladung` live.
const bool kInviteEnabled = false;

/// Impuls I2 (Golden-Day) — gebaut/testbar, zum Start aus (D9).
///
/// Nur wirksam wenn zusätzlich [kInviteEnabled] true ist. I1 hängt nicht an
/// dieser Konstante.
const bool kInviteImpulseI2Enabled = false;

/// Adult-Selbstauskunfts-Fragebogen (`adult_v3`, P2.A).
///
/// Gated: For-Whom-Karte „Für mich selbst“ (statt Coming-Soon), Auswahl der
/// Adult-Definition in `ReflexProfileScreen`, Filtermodul „Deine
/// Lebenssituation“, vier Antwortflächen (Ja/Nein/?/n. z.), Altersgate ≥ 16,
/// Zusammenfassung vor Absenden, Adult-Draft-Meta
/// (`filter_answers` / `superseded_item_ids`), Safety-Hinweisdialog
/// (Phase 6). Ergebnis-UI ist Phase 7; Movement-/Hard-Gate sind eigene Flags.
///
/// Flag AUS = Adult-Pfad zeigt weiterhin Coming-Soon.
/// Flag AN = vollständiger Adult-Fragebogen inkl. Adult-Ergebnisschirm
/// (Movement/Hard-Gate weiter über ihre eigenen Flags).
///
/// Plan §15.1: erst true, wenn der Adult-Ergebnisschirm (Phase 7) steht —
/// hier freigeschaltet zusammen mit dem Ergebnis-UI-Commit.
const bool kAdultReflexQuestionnaireEnabled = true;

/// Freiwillige Adult-Bewegungsprüfungen (s005/s006, P2.A Phase 6).
///
/// Gated: Sichtbarkeit der Movement-Items im Adult-Fragebogen, optionales
/// Movement-Modul nach dem Safety-Kapitel, inverse Scoring dieser Items in
/// der Adult-Engine, Intro-Text vor dem Bewegungsteil, und der
/// Safety-Hinweis-Schlusssatz zu „gekennzeichneten Übungen“.
///
/// Flag AUS = Movement unsichtbar und implizit übersprungen;
/// `possibleCount` ohne Movement-Items; Safety-Hinweis ohne Schlusssatz.
/// Flag AN = Movement nach Safety erreichbar (nach Expertenfreigabe).
///
/// VOR Aktivierung: Expertenfreigabe der Prüfblätter
/// (`Reflexprofil_Sicherheitspruefung_Experten.docx`), Copy-Abnahme und
/// Store-/QA-Freigabe von [kAdultReflexQuestionnaireEnabled].
const bool kAdultMovementChecksEnabled = false;

/// Harte Adult-Safety-Sperren (Stufe A/B/C, Trainingsstopp) — P2.A Phase 6.
///
/// Gated (wenn später freigegeben): automatische Trainingssperre,
/// Stufen-Mapping Frage→A/B/C, und alle UI-/Persistenzpfade, die Zugang
/// zu Übungen oder Movement an eine Safety-Stufe koppeln.
///
/// Flag AUS = nur neutrale situationsbezogene Hinweise („Hinweis gelesen.“);
/// keine Sperre, keine Stufen, keine Notfallnummern.
/// Flag AN = Hard-Gate-Logik (erst nach Expertenfreigabe der Stufen-
/// Zuordnung und ggf. Migration neuer `safety_status`-Werte).
///
/// VOR Aktivierung: Freigabe Expertendokument §3/§11.1 und Migration
/// neuer Status-Werte falls nötig.
const bool kAdultSafetyHardGateEnabled = false;
