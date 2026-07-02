#!/usr/bin/env bash
set -euo pipefail

echo "== Reflex Journey Release Readiness =="

echo ""
echo "1) Static analysis (critical modules)"
flutter analyze \
  lib/features/dashboard/presentation/screens/dashboard_screen.dart \
  lib/features/progress/domain/services/progress_service.dart \
  lib/core/sync/sync_service.dart \
  lib/core/services/notification_service.dart \
  lib/features/settings/presentation/screens/settings_screen.dart \
  lib/features/training/presentation/screens/training_flow_screen.dart \
  lib/features/training/presentation/services/training_feedback_service.dart

echo ""
echo "2) Regression tests (progress + reminders + sync + notifications)"
flutter test \
  test/features/progress/streak_logic_test.dart \
  test/core/services/notification_service_test.dart \
  test/core/sync/sync_service_test.dart

echo ""
echo "3) Smoke note"
echo "Run manual smoke on iOS + Android (hands-free, reminders, offline sync, dashboard)."

echo ""
echo "Release readiness checks passed."
