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

Open, in order:

- [ ] **Re-run the full mobile gate.** 18 files were edited after the last run;
      nothing in the tree is currently verified. Blocks everything else.
- [ ] Backup/restore rehearsal: `scripts/local_restore_probe.py` aborts — needs an
      empty synthetic local auth database, or documented infrastructure.
- [ ] Admin transitive PostCSS advisory in `../corejourney/admin-web` (unverified).
- [ ] Analyzer: 117 `info` issues, non-blocking.

No commit beyond the checkpoint / no push / no live apply.
