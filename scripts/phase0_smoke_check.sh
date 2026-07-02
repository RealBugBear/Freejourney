#!/usr/bin/env bash
set -euo pipefail

echo "== Reflex Journey Phase 0 Smoke =="
echo ""
echo "Automated gate:"
./scripts/release_readiness.sh

echo ""
echo "Manual iOS smoke cases (Roadmap Phase 0):"
echo "  [P0-01] Single reminder only (no duplicates after repeated settings saves)"
echo "  [P0-02] Training completion visible immediately on dashboard"
echo "  [P0-03] App restart keeps dashboard consistency"
echo "  [P0-04] Midnight edge-case (before/after day boundary)"
echo "  [P0-05] Offline completion updates local dashboard"
echo "  [P0-06] Reconnect drains sync queue to 0 without data loss"
echo "  [P0-07] Training today pushes reminder to next day"
echo "  [P0-08] Quiet-hours overlap prevents reminder scheduling"

echo ""
echo "Reference checklist: docs/PHASE0_SMOKE_CHECKLIST.md"
