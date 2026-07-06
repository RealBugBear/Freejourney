# T13 — Trainer-Discovery fertig bauen: „make it work“ (2026-07-06)

Befund nach Lese-Phase (Deltas gegenüber dem Task-Prompt):
- Standortfreier Fallback existiert **schon** (Default `_showAllTrainers=true`,
  RPC `list_public_trainers` ohne Koordinaten) — Punkt 3 des Prompts ist damit
  „verifizieren + sauber einbinden“, kein Neubau.
- Hauptverstoß: `_fetchLocation()` läuft in `initState` → Standort-Abfrage beim
  Screen-Öffnen statt nutzerinitiiert.
- `Geolocator` wird statisch aufgerufen → für Tests nicht mockbar → kleine
  injizierbare `LocationService`-Abstraktion nötig.
- Diverse hartkodierte deutsche Strings (App ist zweisprachig) → l10n-Keys.
- flutter_map 7.x → `RichAttributionWidget` verfügbar; url_launcher vorhanden.
- `connectivityProvider` (Stream<bool>) existiert in `lib/core/sync/` → für
  Offline-Banner auf der Karte wiederverwendbar.

## Standort-Datenfluss (Analyse-Ergebnis, wird als Doc persistiert)
- Abruf nur in TrainerDiscoveryScreen; Ziel: nur nach Nutzer-Tap.
- Koordinaten verlassen das Gerät NUR im Umkreis-Modus als Parameter der RPC
  `find_trainers_nearby(lat, lng, radius_km)` (Supabase EU). Funktion ist
  `LANGUAGE sql STABLE` → kann per Postgres-Semantik nicht schreiben →
  transiente Nutzung in der Query, keine Speicherung. „Alle“-Modus sendet
  keine Koordinaten. Lokal: nur Widget-State, keine DB.
- OSM-Tileserver erhält IP + Kachelkoordinaten (grobes Sichtgebiet) + UA
  `de.reflexjourney.app`.
- Trainer-Positionen serverseitig verrauscht (`_jitter_location`, ~1000 m).

## Schritte

- [x] 1. `docs/STANDORT_DATENFLUSS_T13.md` schreiben (Input T12/T05/P0.6)
- [x] 2. l10n-Keys DE+EN für alle neuen Zustände + gen-l10n
- [x] 3. `LocationService`-Abstraktion (`lib/features/trainer/data/services/`)
      mit Ergebnis-Typ (granted/denied/deniedForever/serviceDisabled/error)
      + Riverpod-Provider; Timeout beim Positionsabruf
- [x] 4. Screen-Umbau: kein Standort in initState; „Umkreis“-Tap → CTA-Karte
      („Standort verwenden“, Hinweis „nur für diese Suche, nicht gespeichert“);
      alle 4 Permission-Zweige mit gestalteter Notice (+ Einstellungen-Buttons);
      Fallback „Alle“ bleibt immer nutzbar
- [x] 5. Empty-States gestaltet (global: „Noch keine Trainer freigeschaltet“
      + CTA zurück; Umkreis: „Keine Trainer in deiner Nähe“ + CTA „Alle“)
- [x] 6. RPC-Fehler → gestalteter Error-State mit Retry (Provider invalidate);
      Offline-Banner auf Karte via connectivityProvider
- [x] 7. OSM-Attribution auf Discovery-Karte UND Picker-Karte (tappbar →
      openstreetmap.org/copyright)
- [x] 8. Tests: Screen-Zustände mit Fake-LocationService + Fake-Repo (alle
      Zweige, Empty global/nearby, Fehler+Retry, kein Standort-Call ohne Tap)
- [x] 9. `flutter analyze` + volle Suite + `make release-readiness-mobile`
- [x] 10. Screenshot-Serie aller Zustände per Widget-Test-Harness (T04-Muster)
      → docs/evidence/T13/; Harness danach entfernen
- [x] 11. Prod-Build `--no-codesign`
- [x] 12. Backlog/Tracker/Evidenz aktualisieren, Commit(s) mit Dateiliste

Nicht-Ziele (aus Prompt): kein Tile-Provider-Wechsel, keine Live-Testdaten,
RLS/RPCs nicht anfassen, Trainer-Onboarding-Flow unangetastet (nur Picker-
Attribution), kein Redesign der Profilseiten.

Offen nach Task: on-device-Durchlauf (Founder-Gerät) — reitet mit T17/R2-Sitzung.
