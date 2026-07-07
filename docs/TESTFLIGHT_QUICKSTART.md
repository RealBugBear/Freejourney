# TestFlight Quickstart — Reflex Journey

Stand: 2026-07-07 (T20; die frühere Fassung nannte die alte Bundle-ID,
GitHub-Pages-Hosting und Pfade unter `/dev/corejourney` — alles obsolet).

## Ist-Zustand (was schon existiert)

- Apple-Developer-Account aktiv, Team-ID `5X6VFP7F58`.
- Bundle-IDs registriert (2026-07-03): `de.reflexjourney.app` (+ `.dev`,
  `.staging`), je mit Associated Domains + Push.
- APNs-Key in Firebase (`corejourney-prod`) für alle drei iOS-Apps
  hinterlegt.
- Flavors/Schemes funktionieren (`production` → `lib/main_production.dart`).
- `ITSAppUsesNonExemptEncryption=false` gesetzt (T09) → keine
  Export-Compliance-Rückfrage pro Build.

## Noch offen, bevor der erste Upload möglich ist

1. **ASC-App-Record anlegen** unter `de.reflexjourney.app`
   (Founder-Klickarbeit, 🔶 R4 — Empfehlung: Claude-in-Chrome-Sitzung).
   Backlog P3 führt die zugehörigen Pflicht-Formulare (Altersfreigabe NEU,
   Nutrition Labels aus `docs/PRIVACY_LABELS_DRAFT.md`, EU-Trader-Status).
2. Datenschutz-URL live (`reflexjourney.app/datenschutz`, nach P0.6).

## Upload-Ablauf (pro Build)

```bash
make bump-build            # Pflicht: Build-Nummer auf heute+NN (T16)
make testflight            # baut IPA (production-Flavor) und öffnet Transporter
```

`make testflight` nutzt `ios/ExportOptions.plist` und übergibt Version +
Build-Nummer aus `pubspec.yaml`. Alternativ Xcode: Product → Archive →
Distribute (Scheme `production`).

Nach dem Upload in ASC: Build erscheint unter TestFlight (Verarbeitung
~10–30 Min.), beim **ersten** Build von T22 den `aps-environment`-Check
machen (Tracker T22). Interne Tester (bis 100, sofort): Nutzer mit
App-Store-Connect-Zugang hinzufügen. Externe Tester brauchen eine eigene
Beta-Review durch Apple.

## Stolperfallen

- Ohne `make bump-build` lehnt ASC den Upload ab (Build-Nummer nicht höher).
- Signing: Xcode „Automatically manage signing“ mit dem Team `5X6VFP7F58`.
- Der Prod-Build spricht die Live-Supabase-Instanz an — Testkonten nur mit
  Wegwerf-Adressen (E-Mail-Bestätigung ist AN).
