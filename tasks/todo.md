# T25.0 — Multi-Grant-/Benefit-Code-Fundament (2026-07-19)

## Plan

- [x] 1. Founder-Go PM-D1–PM-D12 + TS-6–TS-11 datiert in den kanonischen Trackern dokumentieren; T25.0 auf 🔄 setzen und PM-D12-Regelausnahme in `CLAUDE.md`/`launch_flags.dart` präzisieren.
- [x] 2. Additive, idempotente Migration für Grant-Ledger, Benefit-Kampagnen/-Codes/-Einlösungen, getrennte Rollouts, effektiven Status und transaktionale Legacy-Projektion erstellen.
- [x] 3. T24-Bestand sicher backfillen und den Legacy-RPC kompatibel auf HMAC-Benefit-Codes erweitern; mehrere Grants, Limits, Rollen, Laufzeiten und Campaign-Stopp korrekt behandeln.
- [x] 4. `redeem-access-code` ohne Deploy auf Legacy+HMAC-Pfade weiterentwickeln; keine Codes/PII loggen und neutrale Grant-/Offer-Antworten liefern.
- [x] 5. Premium-Domain/Repository auf effektive Premium- und Studio-Entitlements, Grant-Ursprung und bounded Offline-Cache erweitern; bestehender T23-Paketfluss bleibt kompatibel.
- [x] 6. Pflichtmatrix lokal testen: Grant-Kombinationen, Ablauf/Refund, Premium+Studio, Backfill zweimal, Campaignlimits/Rollen, Rollouts und negative Client-Schreibversuche.
- [x] 7. `supabase db reset --local`, SQL/RLS-Tests, Deno-Checks/-Tests, Flutter-Tests/Analyze und `make release-readiness-mobile` ausführen; Ergebnisse erst danach als Evidenz eintragen.
- [x] 8. `docs/evidence/T25.0/`, Masterstatus, Launch-Tracker/Backlog und Rollback-/Live-Apply-Plan aktualisieren; bewusste Dateiliste lokal committen, kein Push/Deploy/Live-DDL.

## Review

✅ 2026-07-19 lokal abgeschlossen. Migration, Edge Function und Flutter-
Integration sind implementiert und mit Full Replay, 95 pgTAP-Tests, einem
echten Zwei-Konten-Concurrency-Test, 12 Edge-Function-Tests, 43 fokussierten
Flutter-Tests sowie der vollständigen 310-Test-Release-Suite belegt. Keine Live-DDL,
kein Deploy, keine Portaländerung, keine Kampagnen-/Sales-Aktivierung und kein
Push. Evidenz und Rollback: `docs/evidence/T25.0/README.md`.
