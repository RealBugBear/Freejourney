# Privacy Nutrition Labels — Entwurf v2 (T12)

Stand: 2026-07-07. Ersetzt den Roadmap-§3.3-Entwurf (der Standort und
Device-Token nicht kannte und „Nutzungsdaten“ ohne Beleg deklarierte).
Jede Zeile hat einen Code-/Tabellen-Beleg. Der Founder trägt die Werte in
ASC (App Privacy) bzw. Play Console (Data Safety) ein — **erst nach
Gegenlesen mit der finalen Datenschutzerklärung (P0.6)**.

Grundsatz (Apple): „Erhoben“ (collected) ist jede Übertragung an einen
Server, auch ohne Speicherung. „Verknüpft“ (linked) heißt der Identität
zuordenbar (Konto). **Tracking = Nein** (kein Werbe-/Broker-Datenfluss,
kein Ad-SDK — Beleg: pubspec ohne Ads/Analytics-SDKs).

## Apple App Privacy (ASC)

| Apple-Datentyp | Erhoben? | Verknüpft? | Tracking | Zweck | Beleg |
|---|---|---|---|---|---|
| Contact Info → Email Address | Ja | Ja | Nein | App-Funktionalität (Konto) | Supabase Auth; `profiles` |
| Contact Info → Name | Ja | Ja | Nein | App-Funktionalität | `profiles.display_name` (Anzeigename), `reflex_subject_profiles` (Kinderprofil-Name, vom Kontoinhaber angelegt) |
| Health & Fitness → Health | Ja | Ja | Nein | App-Funktionalität | `training_sessions`, `progress_entries`, `intake`/`reflex_profile_assessments`, `mood_checkins` — reflexbezogene Trainings-/Befindlichkeitsdaten |
| User Content → Other User-Generated Content | Ja | Ja | Nein | App-Funktionalität | `journal_entries`, `chat_messages` (Trainer-1:1), `experience_shares` (UI versteckt D1=A, Tabelle bleibt beschreibbar über Alt-Clients → deklarieren) |
| Identifiers → User ID | Ja | Ja | Nein | App-Funktionalität | Supabase-UUID in allen nutzerbezogenen Tabellen |
| Identifiers → Device ID | Ja | Ja | Nein | App-Funktionalität (Push) | FCM-Token → `device_tokens` (user_id-verknüpft, 4 Policies live) |
| Location → Precise Location | Ja | Nein* | Nein | App-Funktionalität (Trainer-Suche) | `docs/STANDORT_DATENFLUSS_T13.md`: nur nutzerinitiiert, transient als RPC-Parameter (`find_trainers_nearby` = `STABLE`, keine Speicherung) |
| Diagnostics → Crash Data | Ja | Nein | Nein | App-Funktionalität | T15: Sentry, `sendDefaultPii=false`, kein User-Kontext, nur Fehlertyp/Stacktrace/Gerät |
| Sonstige Daten (Other Data) | Ja | Ja | Nein | App-Funktionalität | Geburtsdatum im Kinderprofil (`reflex_subject_profiles`), Einstiegsbereich, Geräteinfo (OS/App-Version) |

\* Standort: Die Anfrage läuft zwar authentifiziert (JWT), aber es wird
nichts gespeichert/einer Identität zugeordnet abgelegt. Empfehlung:
„Not linked“ deklarieren UND den Sachverhalt transparent in die
Review-Notes schreiben (T14) — konservativere Alternative wäre „linked“;
finale Einordnung mit Anwalt (P0.6) gegenlesen.

**Nicht deklariert (mit Begründung):**
- Usage Data / Product Interaction — kein Analytics-SDK, keine
  Interaktions-Telemetrie (pubspec-Review 2026-07-07; Roadmap-Entwurf
  hatte das fälschlich drin).
- Photos/Videos, Kamera-/Mikrofondaten — kein `image_picker`/Upload-Pfad
  in der App; Video-Calls deaktiviert (D2=A). Permissions sind deklariert,
  aber es fließen keine Daten.
- Purchases/Financial — Launch kostenlos, kein IAP (8.4).
- Contacts, Browsing/Search History, Sensitive Info (Apple-Definition) — nicht verarbeitet.

## Google Play Data Safety

| Kategorie | Erhoben | Geteilt | Verarbeitung | Löschbar | Beleg |
|---|---|---|---|---|---|
| Persönliche Daten → E-Mail, Name | Ja | Nein | verschlüsselt übertragen, Konto-gebunden | Ja (In-App-Kontolöschung) | wie oben |
| Gesundheit & Fitness → Gesundheitsdaten | Ja | Nein | verschlüsselt, Konto-gebunden | Ja | wie oben |
| Nachrichten → Sonstige In-App-Nachrichten | Ja | Nein | Trainer-1:1-Chat | Ja | `chat_messages` |
| App-Aktivität → Von Nutzern generierte Inhalte | Ja | Nein | Journal/Erfahrungen | Ja | `journal_entries`, `experience_shares` |
| Standort → Genauer Standort | Ja | Nein | **ephemer** (nicht gespeichert), optional — Feature funktioniert ohne | entfällt (nicht gespeichert) | T13-Doku |
| Geräte-/andere IDs | Ja | Nein | FCM-Token für Push | Ja (mit Konto) | `device_tokens` |
| App-Info & Leistung → Absturzprotokolle | Ja | Nein | Sentry EU, anonymisiert | — | T15 |

„Geteilt“ = Nein: Übermittlung an Auftragsverarbeiter (Supabase, Google/FCM,
Resend, Sentry) gilt bei Play als „Verarbeitung im Auftrag“, nicht als
Sharing; OSMF-Kartenabruf ist Service-Provider-Zugriff (IP/Kartengebiet,
kein Nutzerdatensatz).

## Gegenprobe SDKs ↔ Labels

| SDK/Plugin | Datenfluss | Label |
|---|---|---|
| supabase_flutter | alle Konto-/Inhaltsdaten (EU) | E-Mail, Name, Health, User Content, User ID |
| firebase_messaging | FCM-Token, Push-Zustellung | Device ID |
| geolocator | Gerätestandort → nur RPC-Parameter | Precise Location (ephemer) |
| sentry_flutter | Crash-Events ohne PII | Crash Data |
| flutter_map (OSM-Tiles) | IP + Kachelkoordinaten an OSMF | kein eigener Datentyp; in Datenschutzerklärung als Empfänger |
| agora_rtc_engine | im Bundle, UI deaktiviert (D2=A) → kein Datenfluss | keine Deklaration |
| audioplayers / flutter_local_notifications | rein lokal | keine |
| connectivity_plus / package_info_plus / shared_preferences / drift | rein lokal | keine |

## Gegenprobe Tabellen (Grep `.from('…')` 2026-07-07)

appointment_subject_profiles, appointments, chat_channel_members,
chat_channels, chat_messages, enrollments, exercises (Content, nicht
nutzerbezogen), experience_shares, journal_entries, mood_checkins,
profiles, progress_entries, reflex_profile_assessments,
reflex_profile_trainer_shares, reflex_subject_profile_notes,
reflex_subject_profiles, trainer_applications,
trainer_client_relationships, trainer_invite_codes, trainer_profiles,
training_sessions, user_consents, user_reminder_preferences, video_calls
(inaktiv, D2=A), vorrunde_phases (Content) — alle nutzerbezogenen Tabellen
sind oben einem Datentyp zugeordnet; Trainer-seitige Tabellen
(applications/profiles inkl. Kontakt-/Standortdaten der **Trainer**)
betreffen das Trainer-Onboarding und sind über Name/E-Mail/Standort-Zeilen
abgedeckt (`upsert_trainer_location`: Trainer-Standort wird — anders als
der Nutzer-Standort — gespeichert, serverseitig verrauscht veröffentlicht).

## Konsistenz

- Consent-Entwurf (T05): deckungsgleich — AV-Liste Supabase/FCM/Resend/
  Sentry + OSMF als Empfänger; Standort-Passage identisch zur T13-Doku.
- Offen vor dem ASC-Eintrag: Finale Datenschutzerklärung (P0.6) gegenlesen;
  Standort-„linked“-Frage (Fußnote oben) mit Anwalt klären.
