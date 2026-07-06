# T13 — Screenshot-Evidenz Trainer-Discovery (2026-07-06)

Erzeugt per temporärem Widget-Test-Harness (T04/T06-Muster: echte Fonts via
FontLoader aus dem Flutter-SDK-Cache, Roboto als Poppins-Ersatz, weil
google_fonts in Tests nicht nachladen kann; Harness nach dem Lauf entfernt).

**Hinweis Kartenkacheln:** In der Test-Umgebung gibt es kein Netz — die
OSM-Kacheln bleiben grau. Layout, Marker, Attribution („flutter_map | ©
OpenStreetMap contributors“, tappbar → openstreetmap.org/copyright) und
Offline-Banner sind trotzdem belegt. Kachel-Rendering mit echtem Netz wird
im on-device-Durchlauf (Founder-Gerätesitzung, zusammen mit T17) bestätigt.

| Datei | Zustand |
|-------|---------|
| 01_erstoeffnen_karte_attribution | Erst-Öffnen: „Alle“-Modus, Karte, Attribution — KEIN Standort-Abruf |
| 02_liste_mit_trainern | Listen-Tab mit Suchfeld und Trainern |
| 03_empty_global_launch_realitaet | 0 freigeschaltete Trainer (Launch-Realität): gestalteter Empty-State + CTA |
| 04_umkreis_standort_cta | Umkreis gewählt: nutzerinitiierter Standort-CTA mit Datenschutz-Hinweis |
| 05_umkreis_ergebnis_slider_liste | Standort erteilt: Radius-Slider + Umkreis-Ergebnis |
| 06_umkreis_leer | Umkreis ohne Treffer: eigener Empty-State, CTA „Alle Trainer anzeigen“ |
| 07_permission_verweigert | Zweig (b): abgelehnt — Hinweis + Retry, Fallback-Liste bleibt |
| 08_permission_dauerhaft_verweigert | Zweig (c): dauerhaft abgelehnt — „Einstellungen öffnen“ |
| 09_ortungsdienste_aus | Zweig (d): Ortungsdienste systemweit aus — „Ortungs-Einstellungen“ |
| 10_standort_fehler | Fehler/Timeout beim Abruf — Hinweis + Retry |
| 11_ladefehler_retry | RPC-/Netzfehler: gestalteter Error-State mit „Erneut versuchen“ |
| 12_karte_offline_banner | Offline: Banner über der Karte statt kommentarloser Kachelwüste |
| 13_picker_attribution | Trainer-Onboarding-Location-Picker: OSM-Attribution ergänzt |
