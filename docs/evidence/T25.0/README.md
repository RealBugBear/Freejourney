# T25.0 — lokale Implementierungs- und Verifikationsevidenz

**Datum:** 2026-07-19
**Status:** ✅ lokal implementiert und verifiziert
**Nicht erfolgt:** Live-DDL, Function-Deploy, Secret-Änderung, RevenueCat-/Store-/
Portal-Mutation, Kampagnen- oder Sales-Aktivierung, `git push`

## Freigabe und Scope

Founder-Freigabe in dieser Session:

> „GO PM-D1 bis PM-D12 und TS-6 bis TS-11 wie empfohlen. Preise, TS-8 und die
> finalen Free-MVP-Daten bleiben bis Research/Pilotplanung Hypothesen.
> Live-/Portal-/Aktivierungsgates bleiben separat.“

Umgesetzt wurde ausschließlich T25.0: das additive Multi-Grant-/Benefit-Code-
Fundament. T25.1–T25.5, Studio P0–P4B, Live-Apply, Deploy und Aktivierung waren
nicht Teil dieser Session.

## Implementiertes Ergebnis

- Additives Grant-Ledger für parallele `premium`- und `studio`-Zugänge mit
  permanenten, befristeten und festen Enddaten sowie getrennten Ursprüngen.
- Benefit-Kampagnen, HMAC-only Codes, atomare Einlösungen, Account-/Code-/
  Kampagnenlimits, Rollenprüfung und nicht rückwirkender Kampagnenstopp.
  Neue Kampagnen sind ohne separate Aktivierungsaktion standardmäßig inaktiv;
  noch nicht unterstützte Eligibility-Regeln werden fail-closed abgewiesen.
- Getrennte `sales_rollout`- und `feature_rollout`-Zustände. Ein Sales-Stopp
  entzieht keinen bestehenden Zugang; fehlende Sales-Konfiguration ist aus,
  fehlende Feature-Konfiguration verändert bestehenden Zugriff nicht.
- Effektive Entitlement-RPC und transaktionale Legacy-Projektion auf die
  bestehenden Profilfelder; mehrere Grants löschen oder überschreiben sich
  nicht gegenseitig.
- Idempotenter T24-/Profil-Backfill einschließlich bereits abgelaufener
  befristeter Zugänge, ohne diese fälschlich permanent zu machen.
- Kompatibler `redeem-access-code`-Pfad: neue Codes werden zuerst per HMAC
  gesucht und nie im Klartext an den neuen RPC gesendet; Raw-Retry gibt es nur
  für einen eindeutigen HMAC-Miss des alten T24-Pfads.
- Erfolgreiche neue Einlösungen sind sicher wiederholbar, ohne Grants oder
  Limits doppelt zu verbrauchen. Store-Offer-Resultate snapshotten Plattform,
  Offer-Referenz und Entitlement, statt spätere Kampagnenänderungen zu erben.
- Flutter-Domain/Repository für effektive Premium-/Studio-Zugänge, typisierte
  Ursprünge und einen maximal 72 Stunden alten Offline-Cache, der niemals über
  `expires_at` hinaus gilt.
- Die vorhandene Code-Einlöse-UI wurde minimal benefit-aware erweitert. Interne
  Grants versprechen ausdrücklich kein Abo/keine automatische Belastung;
  Store-Angebote behaupten keinen bereits gewährten Zugang. Es entstand keine
  neue Route und kein aktivierter Paywall-/Store-Flow.

## Security und Privacy

- Alle neuen Tabellen haben RLS; App-Clients können Grant-, Code-, Kampagnen-
  und Redemption-Daten nicht schreiben. Eigene Reads sind auf erforderliche
  Grant-/Redemption-Sichten begrenzt.
- Die Redemption-RPC ist nur für `service_role` ausführbar. Limits werden in
  derselben Transaktion und unter Sperre geprüft; der echte Paralleltest belegt
  die atomare Kampagnengrenze.
- Codes werden ausschließlich als keyed HMAC-Digest gespeichert. Request-Body
  (4 KiB), normalisierter Code (256 Zeichen), Secret-Stärke und Antwortshape
  werden fail-closed validiert; weder Code noch PII werden geloggt.
- Nach Accountlöschung bleibt nur eine anonyme Verbrauchs-/Auditzeile erhalten:
  kein User-Link und kein Account-Hash. Damit bleiben Gesamtlimits belastbar,
  ohne eine neue pseudonyme Kontokennung aufzubewahren.
- Direkte Profil-Selbstfreischaltung bleibt auch bei verschachtelten Writes
  blockiert. Store-Offer-Referenzen müssen nichtleer und whitespace-bereinigt
  sein. Malforme RPC-/Cache-/Edge-Antworten gewähren keinen Zugang.
- Non-2xx-Function-Antworten werden trotz geworfener `FunctionException`
  stabil auf Domainfehler abgebildet. Die App setzt keinen möglicherweise
  veralteten Authorization-Header, sondern nutzt den Refresh-fähigen
  Supabase-Transport.
- Die unabhängigen Schlussreviews für Backend/Security/Privacy sowie
  Flutter/Edge fanden nach den Korrekturen keine offenen P1- oder P2-Befunde.

## Beobachtete Verifikation

| Check | Beobachtetes Ergebnis |
|---|---|
| `supabase db reset --local` | kompletter Replay aller Migrationen inklusive `2026071901_multi_grant_entitlements.sql` erfolgreich |
| pgTAP T25.0 | 95/95 erfolgreich |
| echter Zwei-Konten-Concurrency-Test | 1/1 erfolgreich; bei Kampagnenlimit 1 genau ein Erfolg, ein Limitfehler und eine Redemption-Zeile |
| synthetische Testdaten-Bereinigung | erfolgreich: 0 Test-Accounts, 0 Test-Kampagnen, 0 Test-Redemptions verblieben |
| Deno Format + Typecheck | erfolgreich |
| Edge-Function-Tests | 12/12 erfolgreich |
| fokussierter Flutter-Analyze | keine Issues |
| fokussierte Flutter-Tests | 43/43 erfolgreich |
| `flutter gen-l10n` | erfolgreich; generierte Dateien aktuell |
| `make release-readiness-mobile` | erfolgreich: 1.141/1.141 i18n-Schlüssel, Analyzer ohne Fehler/Warnungen (101 bestehende Infos), 310/310 Flutter-Tests |
| `supabase db lint --local` | Exit 0; nur vorbestehende PostGIS-/Legacy-Funktionsbefunde, kein T25.0-Befund |

Die vollständige Flutter-Suite meldete die bekannten, nicht fatalen OSM-
Netzwerkdiagnosen in Karten-Widgettests. Ein Produktions-iOS-Build war nach der
bestehenden Gate-Regel nicht erforderlich: kein Compile-Flag-Wert, Manifest,
Build-Config oder natives Produktions-Wiring wurde geändert.

## Manuelle Restverifikation vor irgendeinem Live-/Pilot-Go

- Altes T24-Codeformat und neues HMAC-Codeformat auf echten DE-/EN-Geräten
  durchspielen; Premium, Studio, Rollenfehler, Ablauf und Offline-Neustart.
- Bestehenden Einlöse-Dialog in Light/Dark, bei 150 % Text und mit mindestens
  44-Pixel-Touchzielen prüfen; der automatisierte DE-/EN-Widgettest deckt
  150 % und 44 Pixel bereits ab.
- Kompatibilität einer alten App-Version mit Premium-Codes prüfen. Studio- und
  Store-Offer-Kampagnen dürfen erst nach Verbreitung des benefit-aware Builds
  aktiviert werden, weil alte Clients jeden Erfolg als Premium interpretieren.
- Vor Live-DDL einen aktuellen read-only Schema-/RLS-/Funktionsdump und einen
  Wiederherstellungspunkt erstellen; danach RLS, Grants, Backfill und Legacy-
  RPC zunächst ohne aktive neue Kampagne prüfen.

## Live-Apply, Blast Radius und Rollback

Jeder folgende Schritt braucht einen eigenen Founder-Go: Migration live
anwenden, HMAC-Secret setzen, Edge Function deployen, Kampagne aktivieren,
Sales freigeben, Portal/Store verdrahten und Pilot/Nutzerzugang aktivieren.

Der Live-Blast-Radius eines späteren Schema-Apply umfasst neue Tabellen,
Policies, Trigger/RPCs, den idempotenten Profil-/T24-Backfill und die bestehende
Legacy-Projektion. Die Migration ist additiv; ohne aktive Kampagne und bei
fehlendem `sales_rollout` bleibt Verkauf aus.

Rollback-/Incident-Reihenfolge:

1. Sales aus lassen bzw. ausschalten; betroffene Kampagne/Codes deaktivieren.
2. Bei einem Edge-Problem auf die T24-Function zurückrollen; die kompatiblen
   Default-Argumente und das additive Schema können bestehen bleiben.
3. Compile-Paywall-Flag unverändert `false` lassen. Feature-Incident-Schalter
   ist getrennt vom Sales-Schalter und darf nur gezielt genutzt werden.
4. Bereits gewährte Grants bei einem Kampagnenstopp nicht pauschal widerrufen;
   Einzelwiderruf nur als eigener, auditierter Support-/Refund-Vorgang.
5. Nach realen Redemptions keine Tabellen destruktiv droppen. Bei notwendigem
   DB-Rollback zuerst Zugriffe stoppen, Daten sichern und eine vorwärtsgerichtete
   Korrekturmigration verwenden.

Preise, TS-8 und die finalen Free-MVP-Daten sind weiterhin Hypothesen. Der
nächste ausführbare Repository-Punkt ist Studio P0; T25.1 bleibt bis X3
RevenueCat blockiert.
