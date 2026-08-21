# Invite Phase 7 — Website landing (`/einladung`)

**Repo:** `corejourney/reflexjourney-app-site` (outer git root `corejourney`, branch `website-v1`)  
**Date:** 2026-08-21 (corrected after review; post-launch store task documented)  
**Scope:** DE/EN invite landing, `?c=` code, SelfCheck reuse, anonymous landing RPC, noindex + sitemap exclude. No Stage-2 reward copy. App flag and live DB unchanged.

## Delivered

| Item | Location |
|---|---|
| DE / EN pages | `src/pages/einladung.astro`, `en/einladung.astro` |
| Shared content | `src/content-pages/EinladungPage.astro` |
| Landing controller | `src/lib/inviteLanding.ts` (URL-only code; stale storage cleared) |
| Safe storage | `src/lib/safeSessionStorage.ts` (invite + SelfCheck) |
| SelfCheck | optional `hideDefaultResultCtas` + `result-ctas` slot; default page unchanged |
| Landing counter | soft-fail `log_invite_landing_view` only when current `?c=` is well-formed |
| noindex + sitemap | confirmed in build |

## Pre-launch store CTA (approved)

Die App ist **noch nicht öffentlich** im Apple App Store und Google Play Store.
Deshalb bleiben die ehrlichen Pre-Launch-Texte („noch nicht im Store“) und der
**Wartelisten-CTA** bestehen. Keine Platzhalter-Store-URLs, keine TestFlight-
oder Internal-Testing-Links auf der öffentlichen Website.

## Post-Launch-Aufgabe — Store-Buttons auf der Einladungsseite

**Status:** ausdrücklich **Post-Launch** (nicht MVP Phase 7).  
**Tracked also:** `WEBSITE_BACKLOG.md` → **W-024**, `FOUNDER_TODO.md` → F9.6, Spec §13/§14.

Checklist after public store availability:

1. Apple-ID in App Store Connect ermitteln
2. Öffentliche iOS-URL hinterlegen: `https://apps.apple.com/app/id<APPLE_ID>`
3. Öffentliche Android-URL hinterlegen: `https://play.google.com/store/apps/details?id=de.reflexjourney.app`
4. URLs als **zentrale Website-Konstanten** in `src/config.ts` (nicht hardcodiert in Astro-Komponenten)
5. Auf echten Geräten nach Veröffentlichung prüfen
6. Auf der Einladungsergebnisseite **getrennte, lokalisierte** App-Store- und Google-Play-Buttons anzeigen
7. Wartelisten-CTA nur verwenden, solange keine öffentlichen Store-URLs konfiguriert sind
8. Pre-Launch-Text „noch nicht im Store“ nach Veröffentlichung entfernen
9. DE und EN gemeinsam aktualisieren
10. Tests ergänzen: konfigurierte Store-URLs **und** Pre-Launch-Fallback

## Verification (observed)

```text
npm run test:aasa
npm run test:invite-code   # helper + landing controller
npm run check:i18n
npm run build
npm run test:invite-pages  # built HTML: selbstcheck vs einladung CTAs
```

## Non-goals (honoured)

- No reward / Stufe-2 copy
- `kInviteEnabled` untouched
- No live migration / Edge deploy / `git push`
- No placeholder / TestFlight / internal-testing store links
