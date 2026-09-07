# Invite — final (post Phase-8 soft-fail fix)

- [x] Admin Missing-RPC soft-fail narrowed (PGRST202 / „Could not find the function“ only)
- [x] Metrics merge unit tests (6)
- [x] `conv_redeem_per_landing` in invite primary signals
- [x] Full invite verification (app / site / admin)
- [x] Handoff `docs/evidence/invite-final/README.md`

No commit / push / live apply.

# Production readiness — status 2026-09-06

Full state, evidence and open items: `PRODUCTION_READINESS.md`. Read that first.
Local engineering and audits authorized; production mutation, deployment,
publication and pushes remain excluded.

- [x] Architecture, baseline and evidence recorded in PRODUCTION_READINESS.md.
- [x] Sync/session/data-integrity defects repaired with 24 regression tests.
- [x] Backend: ownership guard + notification recovery migrations, DB tests (261),
      bounded queue concurrency evidence.
- [x] Media: 22-video manifest, validator, release script, delivery spec, tests.
- [x] Web: admin/auth audit and reset/callback fixes — see
      `../corejourney/docs/PRODUCTION_READINESS_WEB.md`.
- [x] Platform builds: iOS release and Android production release.
- [x] WIP checkpoint committed in both repositories (no push).

- [x] 2026-09-06 — Mobile gate components passed: 1,302 i18n keys, 117 analyzer
      infos / 0 warnings / 0 errors, 722 tests. Two full-gate invocations; after
      the fixture fix, only the failed test stage was resumed. Evidence:
      `mobile-20260906-session-final.log`, `mobile-tests-20260906-session-final.log`.
- [x] 2026-09-06 — Local restore probe completed: schema/data/GraphQL definition,
      owner/cross-account RLS and cleanup passed. Evidence:
      `restore-20260906-session-final.log`, `restore-cleanup-20260906-session.log`.

Open, in order:

- [x] 2026-09-06 — Clean `make release-readiness-mobile` invocation: `GATE_EXIT=0`,
      722 tests, 1,302 i18n keys. Evidence: `gate-20260906-clean-run.log`.
- [x] 2026-09-06 — Ownership migration validated: 67-migration chain replayed from
      scratch (exit 0, 0 errors) and `supabase test db --local` → `Result: PASS`
      (261 tests). Trigger md5 matches the repo migration, attached to 9 tables.
      Evidence: `db-reset-20260906-verify.log`, `db-tests-20260906-postreset.log`.
- [x] 2026-09-06 — Duplicated `!docs/evidence/**/*.log` line removed from `.gitignore`.
- [x] 2026-09-07 — Admin PostCSS override verified unchanged: admin typecheck,
      lint, metrics tests (6/6), build (21/21 static pages), plus site check
      (72 files, 0 errors/warnings/hints) and build (35 pages) all exited 0.
      Both audits: `found 0 vulnerabilities` per verified 2026-09-07 task context
      (prior evidence; not rerun). Next resolves PostCSS 8.5.28. Evidence:
      `../corejourney/docs/evidence/postcss-override/README.md` and
      `../corejourney/docs/PRODUCTION_READINESS_WEB.md`.
- [ ] Analyzer: 117 `info` issues, non-blocking.
- [ ] Rebuild release binaries before any store submission (last built 2026-09-05/06).

Engineering no longer blocks launch. Critical path is founder-owned: P0.6 (lawyer),
the 22 exercise videos + expert approval, the on-device session, store metadata.

No commit beyond the checkpoint / no push / no live apply.

## Scoped verification session — 2026-09-06

- [x] Regenerated stale localization getters, removed unused import, initialized
      missing shared-preferences test mock; focused checks and all gate stages passed.
- [x] Started restore only after mobile checks were green; fixed local admin
      authentication and GraphQL schema/ACL restoration, then completed the probe.
- [x] Updated PRODUCTION_READINESS.md with observed outputs, local prerequisites,
      verification limits and the exact next step.

- [ ] 2026-09-07 — Web maintenance follow-up: `next lint` deprecation notice and metrics-test `MODULE_TYPELESS_PACKAGE_JSON` warning; all checks pass, no change required for PostCSS (evidence: `../corejourney/docs/evidence/postcss-override/`).
