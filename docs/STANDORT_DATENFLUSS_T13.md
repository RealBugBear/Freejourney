# Standort-Datenfluss — Trainer-Discovery (T13)

Stand: 2026-07-06 (Code-Analyse + Migrations-Review; Quellenangaben unten).
Zweck: wörtlich verwendbarer Input für Privacy Nutrition Labels (T12),
Consent-Screen (T05) und den Anwaltsauftrag (P0.6).

## Kurzfassung (für Anwalt/Labels)

Die App fragt den Gerätestandort **ausschließlich** in der Trainer-Suche ab,
**nur nach explizitem Nutzer-Tap** („Standort verwenden“), mit
When-In-Use-Berechtigung. Die Koordinaten werden **nicht gespeichert** —
weder lokal noch serverseitig — sondern einmalig als Parameter einer
Datenbank-Suchfunktion verwendet (Supabase, EU-Region Irland) und danach
verworfen. Ohne Standort-Freigabe ist die Trainer-Suche voll nutzbar
(Liste aller Trainer ohne Umkreisfilter). Beim Anzeigen der Karte werden
Kartenkacheln vom Server der OpenStreetMap Foundation geladen; dieser
erhält dabei technisch bedingt die IP-Adresse und die angeforderten
Kachelkoordinaten (= grobes Kartengebiet, nicht der präzise Standort).

## Detail

1. **Auslöser:** Nur `TrainerDiscoveryScreen` (Route `/trainers`). Der Abruf
   passiert erst, wenn der Nutzer den Umkreis-Modus wählt und den Button
   „Standort verwenden“ antippt (seit T13; vorher lief er beim Screen-Öffnen).
   Kein anderer Code-Pfad ruft `Geolocator.getCurrentPosition` auf
   (repo-weiter Grep, 2026-07-06).
2. **Berechtigung:** iOS `NSLocationWhenInUseUsageDescription` /
   Android `ACCESS_FINE_LOCATION`+`ACCESS_COARSE_LOCATION` — nur While-in-Use;
   der Always-Key wird mit T09 aus der Info.plist entfernt.
3. **Übertragung:** Nur im Umkreis-Modus gehen `lat`/`lng`/`radius_km` als
   Parameter an die Postgres-RPC `find_trainers_nearby` (Supabase-Projekt,
   EU/Irland). Die Funktion ist `LANGUAGE sql STABLE` — sie kann per
   Postgres-Semantik keine Daten schreiben; die Koordinaten werden also
   transient in der Abfrage benutzt und nicht persistiert. Es existiert
   keine Tabelle/Spalte, die Nutzerkoordinaten aufnimmt (Schema-Review).
   Standard-Serverlogs des API-Gateways können Requests kurzzeitig
   erfassen (übliche Infrastruktur-Logs von Supabase; für die
   Datenschutzerklärung als Verarbeitung durch den Auftragsverarbeiter
   Supabase abgedeckt).
4. **Kein Versand im Standardmodus:** Der Default-Modus „Alle“ nutzt die RPC
   `list_public_trainers()` — ohne jegliche Standortparameter.
5. **Lokal:** Koordinaten leben nur im Widget-State (RAM) für die Dauer der
   Suche; kein Schreiben in die lokale Drift-DB, keine Persistenz.
6. **Kartenkacheln (Dritter):** Beide Karten (Trainer-Suche,
   Standort-Picker im Trainer-Onboarding) laden Kacheln von
   `tile.openstreetmap.org` (OpenStreetMap Foundation, UK). Der Tileserver
   erhält: IP-Adresse, angeforderte Kacheln (Zoom/x/y → grobes Sichtgebiet)
   und den App-User-Agent `de.reflexjourney.app`. Kein Auth-Kontext, keine
   Nutzer-ID. → OSMF gehört als Empfänger in Datenschutzerklärung + Labels.
7. **Trainer-Seite (zur Einordnung):** Trainer-Standorte werden serverseitig
   vor der Veröffentlichung verrauscht (`_jitter_location`, Standard ~1000 m,
   Spalten `location_private`/`location_public` getrennt); Nutzer sehen nie
   die präzise Trainer-Adresse.

## Konsequenzen für T12 (Nutrition Labels)

- Apple-Datentyp „Standort (präzise)“: **erhoben** im Apple-Sinn (Transit zum
  Server im Umkreis-Modus), **nicht mit Identität verknüpft gespeichert**,
  **kein Tracking**, Zweck: App-Funktionalität. Deklaration als
  „Precise Location — collected, not linked, no tracking“ mit Anmerkung
  in den Review-Notes, dass keine Speicherung erfolgt.
- Play Data Safety: „Standort — erhoben, nicht geteilt, nicht gespeichert
  (ephemeral processing), verschlüsselt übertragen, optional (Feature
  funktioniert ohne)“.

## Konsequenzen für T05 (Consent) — belegte Formulierung

> „Dein Standort wird nur auf deine Anfrage für die Trainer-Suche verwendet
> und nicht gespeichert.“ — belegt durch Punkte 1, 3, 5.

Zusätzlich in die AV-/Empfängerliste: OpenStreetMap Foundation (Karten-Kacheln).

## Quellen

- `lib/features/trainer/presentation/screens/trainer_discovery_screen.dart`
- `lib/features/trainer/data/services/location_service.dart` (neu, T13)
- `supabase/migrations/2026042901_find_trainers_nearby_backfill.sql`
  (RPC-Definition inkl. `STABLE`, `_jitter_location`)
- `supabase/migrations/2026050502_list_public_trainers.sql`
- Grep `Geolocator\.` über `lib/` (einziger Treffer-Cluster: Trainer-Discovery)
