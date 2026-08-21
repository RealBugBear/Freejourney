# Phase 0 — Linkarchitektur verifizieren

**Datum der Prüfung:** 2026-08-21  
**Geprüft von:** Agent (Live-HTTP); Gerätetest (Punkt 4) offen für Auftraggeber  
**Domain:** `https://reflexjourney.app`

---

## 1. Apple App Site Association (AASA)

| Prüfung | Ergebnis |
|---|---|
| URL | `https://reflexjourney.app/.well-known/apple-app-site-association` |
| HTTP-Status | **200** |
| Content-Type | **application/json** |
| AppID `de.reflexjourney.app` | vorhanden (`5X6VFP7F58.de.reflexjourney.app`) |
| AppID `.staging` | vorhanden (`5X6VFP7F58.de.reflexjourney.app.staging`) |
| AppID `.dev` | vorhanden (`5X6VFP7F58.de.reflexjourney.app.dev`) |

Aktuelle `paths` (alle drei AppIDs): nur `/auth/*`.  
Für Phase 5 müssen `/einladung`, `/einladung/*`, `/en/einladung`, `/en/einladung/*` ergänzt werden — das ist erwartet und blockiert Phase 0 nicht.

**Befund: bestanden**

---

## 2. Android Asset Links

| Prüfung | Ergebnis |
|---|---|
| URL | `https://reflexjourney.app/.well-known/assetlinks.json` |
| HTTP-Status | **200** |
| Package `de.reflexjourney.app` | vorhanden |
| Package `.staging` / `.dev` | ebenfalls vorhanden |

Relation: `delegate_permission/common.handle_all_urls` (alle URLs der Domain).

**Befund: bestanden**

---

## 3. Website (Selbstcheck-Seiten)

| URL | HTTP-Status |
|---|---|
| `https://reflexjourney.app/selbstcheck` | **200** |
| `https://reflexjourney.app/en/selbstcheck` | **200** |

Die Domain liefert nicht nur die Well-Known-Dateien, sondern auch die Website.

**Befund: bestanden**

---

## 4. Universal Link auf echten Geräten

| Prüfung | Ergebnis |
|---|---|
| iPhone: `https://reflexjourney.app/auth/reset-password` öffnet die App | **manuelle Geräteprüfung ausstehend** |
| Android: derselbe Link öffnet die App | **manuelle Geräteprüfung ausstehend** |

Punkt 4 prüft nur die bestehende Linkarchitektur (`/auth/*`). Er blockiert die datenbank- und appinternen Phasen 1–4 **nicht**.

Die entscheidende End-to-End-Prüfung erfolgt in **Phase 5** nach Erweiterung von AASA, Android-Manifest und App-Routing mit:

`https://reflexjourney.app/einladung?c=<TESTCODE>`

Phase 5 und der Rollout gelten ohne erfolgreiche Tests auf iPhone und Android **nicht** als abgeschlossen.

---

## Gesamtergebnis Phase 0

| # | Prüfung | Status |
|---|---|---|
| 1 | AASA | bestanden |
| 2 | Asset Links | bestanden |
| 3 | Selbstcheck-Seiten | bestanden |
| 4 | Gerätetest Universal Link | manuelle Geräteprüfung ausstehend (blockiert Phasen 1–4 nicht) |

HTTP-Punkte 1–3 sind grün. Phasen 1–4 dürfen beginnen. End-to-End-Freigabe bleibt an Phase 5 gebunden.
