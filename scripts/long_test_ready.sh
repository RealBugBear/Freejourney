#!/usr/bin/env bash
set -euo pipefail

echo "== Reflex Journey Long Test Ready =="
echo ""
echo "1) Automated quality gate"
./scripts/release_readiness.sh

echo ""
echo "2) Phase-0 smoke prompt"
./scripts/phase0_smoke_check.sh

echo ""
echo "3) Long test plan"
echo "Run the multi-day checklist in:"
echo "  docs/LONG_TEST_PHASE_PLAN.md"

echo ""
echo "Long-test readiness checks passed."
