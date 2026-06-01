# Release Hardening — Test Repair & Production DB Verification

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Get the test suite to 0 failures and verify the remote Supabase schema/history so the Vorrunde phase flow persists for real users.

**Architecture:** All 4 previously planned feature specs (Einstiegsbereiche, Relevante Angaben, Profile-Account Decoupling, Phase 1 Unified Assessment) are already fully implemented. The remaining gaps are: (1) a missing `user_preferences.dart` model file that causes production compile errors in `notification_service.dart` and `reminder_settings.dart`; (2) broken references in `logger_service.dart` to non-existent fields on `AppConfig`; (3) 3 stale test files referencing deleted modules; (4) 1 training-flow test that should be ported to the current notifier API; (5) 1 community test file with wrong UI text and no provider override; and (6) the `vorrunde_phases` migration SQL has been manually run in production and now needs schema verification plus migration-history repair/tracking.

**Tech Stack:** Flutter test, Dart, Supabase SQL Editor

---

## Current Test Failure Inventory

| File | Failure type | Root cause |
|------|-------------|-----------|
| `test/core/sync/sync_service_test.dart` | Compile | imports `lib/core/database/database_service.dart` — deleted |
| `test/core/feature_flags/feature_flag_service_test.dart` | Compile | imports `firebase_remote_config` — package removed |
| `test/core/logging/logger_service_test.dart` | Compile | uses `AppConfig.development` static factory — does not exist; `LoggerService` ctor itself uses `config.logLevel` / `config.environment.isDevelopment` / `_config.enableCrashReporting` — none of these exist on current `AppConfig` |
| `test/core/services/notification_service_test.dart` | Compile | imports `user_preferences.dart` — file deleted; but the test logic is sound and worth keeping once the model file is restored |
| `test/features/progress/streak_logic_test.dart` | Compile | imports `lib/features/progress/domain/services/progress_service.dart` — deleted |
| `test/features/training/training_flow_provider_test.dart` | Compile | imports deleted `ProgressService`, but `TrainingFlowNotifier` still exists and should be tested through its current constructor/API |
| `test/features/community/community_screen_test.dart` | Runtime | expects `find.text('Community')` but screen shows `'Erfahrungen'`; also lacks `chatChannelsProvider` override so it would hit real Supabase |

---

## File Map

| Action | Path |
|--------|------|
| Create | `lib/features/progress/domain/models/user_preferences.dart` |
| Modify | `lib/core/logging/logger_service.dart` |
| Modify | `test/core/logging/logger_service_test.dart` |
| Delete | `test/core/sync/sync_service_test.dart` |
| Delete | `test/core/feature_flags/feature_flag_service_test.dart` |
| Delete | `test/features/progress/streak_logic_test.dart` |
| Modify | `test/features/training/training_flow_provider_test.dart` |
| Modify | `test/features/community/community_screen_test.dart` |

---

## Task 1: Restore missing `user_preferences.dart`

**Files:**
- Create: `lib/features/progress/domain/models/user_preferences.dart`

`notification_service.dart:6` and `reminder_settings.dart:4` both import this file. It was deleted when progress models were refactored, but `NotificationService` still depends on `HabitWindow`, `QuietHours`, and `UserPreferences` for scheduling logic. The types must be recreated at the original path.

- [ ] **Step 1: Confirm the compile errors exist**

```bash
cd /Users/alexandermessinger/dev/claudvibes/corejourney/app
flutter analyze lib/core/services/notification_service.dart lib/core/reminders/reminder_settings.dart 2>&1 | grep -E "error|warning" | head -10
```

Expected: errors about `user_preferences.dart` not found or `HabitWindow`/`QuietHours`/`UserPreferences` undefined.

- [ ] **Step 2: Create `user_preferences.dart`**

Create `lib/features/progress/domain/models/user_preferences.dart` with this exact content:

```dart
import 'package:flutter/material.dart';

class HabitWindow {
  final TimeOfDay start;
  final TimeOfDay end;
  final String? locationLabel;

  const HabitWindow({
    required this.start,
    required this.end,
    this.locationLabel,
  });
}

class QuietHours {
  final TimeOfDay start;
  final TimeOfDay end;

  const QuietHours({
    required this.start,
    required this.end,
  });
}

class UserPreferences {
  final List<HabitWindow> preferredWindows;
  final QuietHours quietHours;
  final String timezone;
  final bool locationConsent;
  final bool dailyReminderEnabled;
  final bool midweekCheckinEnabled;
  final bool locationNudgesEnabled;
  final bool silentMode;

  const UserPreferences({
    required this.preferredWindows,
    required this.quietHours,
    required this.timezone,
    required this.locationConsent,
    required this.dailyReminderEnabled,
    required this.midweekCheckinEnabled,
    required this.locationNudgesEnabled,
    required this.silentMode,
  });
}
```

- [ ] **Step 3: Verify the compile errors are gone**

```bash
cd /Users/alexandermessinger/dev/claudvibes/corejourney/app
flutter analyze lib/core/services/notification_service.dart lib/core/reminders/reminder_settings.dart 2>&1 | grep -E "error" | head -10
```

Expected: no errors for these two files.

- [ ] **Step 4: Commit**

```bash
cd /Users/alexandermessinger/dev/claudvibes/corejourney/app
git add lib/features/progress/domain/models/user_preferences.dart
git commit -m "fix: restore user_preferences.dart (HabitWindow, QuietHours, UserPreferences)"
```

---

## Task 2: Fix `logger_service.dart` and its test

**Files:**
- Modify: `lib/core/logging/logger_service.dart`
- Modify: `test/core/logging/logger_service_test.dart`

`logger_service.dart` references three things that do not exist on current `AppConfig`:
- `config.logLevel` (no such field)
- `config.environment.isDevelopment` (getter is on `AppConfig`, not on `AppEnvironment` enum)
- `_config.enableCrashReporting` (no such field)

The test uses `AppConfig.development` and `AppConfig.production` static factories that never existed.

- [ ] **Step 1: Confirm the logger itself fails to analyze**

```bash
cd /Users/alexandermessinger/dev/claudvibes/corejourney/app
flutter analyze lib/core/logging/logger_service.dart 2>&1 | grep error | head -10
```

Expected: errors on `config.logLevel`, `config.environment.isDevelopment`, `_config.enableCrashReporting`.

- [ ] **Step 2: Fix `lib/core/logging/logger_service.dart`**

Replace the three broken field accesses. The changes are:
1. `AppLogLevel.fromString(config.logLevel)` → `config.isDevelopment ? AppLogLevel.debug : AppLogLevel.error`
2. `config.environment.isDevelopment` → `config.isDevelopment`
3. `_config.enableCrashReporting` (appears twice in `error()` and `fatal()`) → `_config.isProduction`

The complete fixed constructor and error-reporting block:

```dart
LoggerService({
  required AppConfig config,
})  : _config = config,
      _minLevel = config.isDevelopment ? AppLogLevel.debug : AppLogLevel.error,
      _logger = Logger(
        printer: config.isDevelopment
            ? PrettyPrinter(
                methodCount: 2,
                errorMethodCount: 8,
                lineLength: 120,
                colors: true,
                printEmojis: true,
                dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart,
              )
            : SimplePrinter(
                colors: false,
              ),
        level: (config.isDevelopment ? AppLogLevel.debug : AppLogLevel.error)
            .toLoggerLevel(),
      );
```

Replace both occurrences of `_config.enableCrashReporting` with `_config.isProduction`:

```dart
// In error():
if (_config.isProduction && error != null) {
  _reportError(error, stackTrace, message, data);
}

// In fatal():
if (_config.isProduction && error != null) {
  _reportError(error, stackTrace, message, data, fatal: true);
}
```

- [ ] **Step 3: Fix `test/core/logging/logger_service_test.dart`**

Replace all occurrences of `AppConfig.development` and `AppConfig.production` with proper constructor calls. The full replacement content:

```dart
import 'package:flutter_test/flutter_test.dart';

import 'package:corejourney/config/app_config.dart';
import 'package:corejourney/core/logging/logger_service.dart';

class TestException implements Exception {
  final String message;
  TestException(this.message);
  @override
  String toString() => message;
}

AppConfig _devConfig() => const AppConfig(
      environment: AppEnvironment.development,
      supabaseUrl: 'https://test.supabase.co',
      supabaseAnonKey: 'test_anon_key',
      revenueCatApiKey: 'test_rc_key',
    );

AppConfig _prodConfig() => const AppConfig(
      environment: AppEnvironment.production,
      supabaseUrl: 'https://test.supabase.co',
      supabaseAnonKey: 'test_anon_key',
      revenueCatApiKey: 'test_rc_key',
    );

void main() {
  group('LoggerService', () {
    late LoggerService logger;

    group('Development Environment', () {
      setUp(() {
        logger = LoggerService(config: _devConfig());
      });

      test('logs debug messages in development', () {
        expect(
          () => logger.debug('Test debug message', data: {'key': 'value'}),
          returnsNormally,
        );
      });

      test('logs info messages in development', () {
        expect(
          () => logger.info('Test info message'),
          returnsNormally,
        );
      });

      test('logs warning messages in development', () {
        expect(
          () => logger.warning('Test warning', error: TestException('test')),
          returnsNormally,
        );
      });

      test('logs error messages in development', () {
        expect(
          () => logger.error(
            'Test error',
            error: TestException('test'),
            stackTrace: StackTrace.current,
          ),
          returnsNormally,
        );
      });

      test('formats message with structured data', () {
        expect(
          () => logger.info('User action', data: {
            'action': 'button_click',
            'screen': 'home',
            'timestamp': DateTime.now().toIso8601String(),
          }),
          returnsNormally,
        );
      });
    });

    group('Production Environment', () {
      setUp(() {
        logger = LoggerService(config: _prodConfig());
      });

      test('should not log debug in production', () {
        expect(
          () => logger.debug('Should not appear'),
          returnsNormally,
        );
      });

      test('should not log info in production', () {
        expect(
          () => logger.info('Should not appear'),
          returnsNormally,
        );
      });

      test('should log error in production', () {
        expect(
          () => logger.error('Important error'),
          returnsNormally,
        );
      });

      test('should always log fatal errors', () {
        expect(
          () => logger.fatal('Fatal error', error: TestException('critical')),
          returnsNormally,
        );
      });
    });

    group('Scoped Logger', () {
      setUp(() {
        logger = LoggerService(config: _devConfig());
      });

      test('creates scoped logger with tag', () {
        final scopedLogger = logger.scope('TestScope');
        expect(
          () => scopedLogger.info('Test message'),
          returnsNormally,
        );
      });

      test('scoped logger includes tag in messages', () {
        final scopedLogger = logger.scope('Authentication');
        expect(
          () => scopedLogger.debug('Login attempted', data: {'userId': '123'}),
          returnsNormally,
        );
      });
    });

    group('Convenience Methods', () {
      setUp(() {
        logger = LoggerService(config: _devConfig());
      });

      test('logAction formats user actions correctly', () {
        expect(
          () => logger.logAction('button_click', parameters: {
            'button': 'submit',
            'screen': 'login',
          }),
          returnsNormally,
        );
      });

      test('logScreen logs screen views', () {
        expect(
          () => logger.logScreen('HomeScreen', parameters: {
            'source': 'navigation',
          }),
          returnsNormally,
        );
      });
    });

    group('Error Handling', () {
      setUp(() {
        logger = LoggerService(config: _devConfig());
      });

      test('handles null error gracefully', () {
        expect(
          () => logger.error('Error without exception'),
          returnsNormally,
        );
      });

      test('handles null stack trace', () {
        expect(
          () => logger.error('Error', error: TestException('test')),
          returnsNormally,
        );
      });

      test('handles empty structured data', () {
        expect(
          () => logger.info('Message', data: {}),
          returnsNormally,
        );
      });
    });
  });
}
```

- [ ] **Step 4: Run the logger test**

```bash
cd /Users/alexandermessinger/dev/claudvibes/corejourney/app
flutter test test/core/logging/logger_service_test.dart -v
```

Expected: all tests pass.

- [ ] **Step 5: Commit**

```bash
cd /Users/alexandermessinger/dev/claudvibes/corejourney/app
git add lib/core/logging/logger_service.dart test/core/logging/logger_service_test.dart
git commit -m "fix: update LoggerService to use AppConfig.isDevelopment/isProduction; fix test constructors"
```

---

Also update the stale comment `/// Custom log levels matching AppConfig.logLevel` to `/// Custom log levels used by LoggerService`.

## Task 3: Delete 3 stale tests and port `training_flow_provider_test`

**Files:**
- Delete: `test/core/sync/sync_service_test.dart`
- Delete: `test/core/feature_flags/feature_flag_service_test.dart`
- Delete: `test/features/progress/streak_logic_test.dart`
- Modify: `test/features/training/training_flow_provider_test.dart`

The sync, feature-flag, and old progress tests reference modules that were refactored away. The training-flow test also imports a deleted `ProgressService`, but the behavior it asserts is still valuable because `TrainingFlowNotifier` exists with a newer constructor and state model.

- [ ] **Step 1: Confirm stale tests still fail to compile**

```bash
cd /Users/alexandermessinger/dev/claudvibes/corejourney/app
flutter test test/core/sync/sync_service_test.dart --reporter=compact 2>&1 | tail -3
flutter test test/core/feature_flags/feature_flag_service_test.dart --reporter=compact 2>&1 | tail -3
flutter test test/features/progress/streak_logic_test.dart --reporter=compact 2>&1 | tail -3
```

Expected: each prints a compilation error referencing a missing import.

- [ ] **Step 2: Delete the 3 stale files**

```bash
cd /Users/alexandermessinger/dev/claudvibes/corejourney/app
rm test/core/sync/sync_service_test.dart
rm test/core/feature_flags/feature_flag_service_test.dart
rm test/features/progress/streak_logic_test.dart
```

- [ ] **Step 3: Replace `test/features/training/training_flow_provider_test.dart`**

```dart
import 'package:flutter_test/flutter_test.dart';

import 'package:corejourney/features/training/domain/models/exercise.dart';
import 'package:corejourney/features/training/domain/models/training_session.dart';
import 'package:corejourney/features/training/presentation/providers/training_flow_provider.dart';

Exercise _exercise(String id, int sequenceNumber) => Exercise(
      id: id,
      packageId: 'moro',
      sequenceNumber: sequenceNumber,
      titleDe: 'Uebung $sequenceNumber',
      titleEn: 'Exercise $sequenceNumber',
      positionInstructionsDe: const ['Position'],
      positionInstructionsEn: const ['Position'],
      movementInstructionsDe: const ['Bewegung'],
      movementInstructionsEn: const ['Movement'],
      executionGuideDe: 'Anleitung',
      executionGuideEn: 'Guide',
      durationSeconds: 30,
      repetitions: 1,
      imagePath: 'assets/test.png',
    );

void main() {
  final exercises = [_exercise('one', 1), _exercise('two', 2)];

  TrainingFlowNotifier notifier({
    TrainingSessionMode mode = TrainingSessionMode.tutorial,
    bool requiresDisclaimer = false,
  }) {
    return TrainingFlowNotifier(
      exercises: exercises,
      mode: mode,
      requiresDisclaimer: requiresDisclaimer,
    );
  }

  group('TrainingFlowNotifier regression', () {
    test('routine starts movement after intro', () {
      final flow = notifier(mode: TrainingSessionMode.routine);

      expect(flow.state.step, TrainingFlowStep.intro);

      flow.startSession();

      expect(flow.state.mode, TrainingSessionMode.routine);
      expect(flow.state.step, TrainingFlowStep.movement);
      expect(flow.state.currentExerciseIndex, 0);
    });

    test('tutorial starts with video and advances to position', () {
      final flow = notifier();

      flow.startSession();
      expect(flow.state.step, TrainingFlowStep.video);

      flow.videoReady();
      expect(flow.state.step, TrainingFlowStep.position);
      expect(flow.state.currentExerciseIndex, 0);
    });

    test('tutorial readiness steps reach movement', () {
      final flow = notifier();

      flow.startSession();
      flow.videoReady();
      flow.positionReady();
      expect(flow.state.step, TrainingFlowStep.preparation);

      flow.preparationReady();
      expect(flow.state.step, TrainingFlowStep.movement);
    });

    test('non-last exercise completion moves to rest and next exercise', () {
      final flow = notifier(mode: TrainingSessionMode.routine);

      flow.startSession();
      flow.exerciseComplete();

      expect(flow.state.completedExerciseIds, ['one']);
      expect(flow.state.currentExerciseIndex, 1);
      expect(flow.state.step, TrainingFlowStep.rest);
      expect(flow.state.isComplete, isFalse);
    });

    test('last exercise completion moves to outro and marks complete', () {
      final flow = notifier(mode: TrainingSessionMode.routine);

      flow.startSession();
      flow.exerciseComplete();
      flow.restComplete();
      flow.exerciseComplete();

      expect(flow.state.completedExerciseIds, ['one', 'two']);
      expect(flow.state.step, TrainingFlowStep.outro);
      expect(flow.state.isComplete, isTrue);
    });

    test('disclaimer starts before intro when required', () {
      final flow = notifier(requiresDisclaimer: true);

      expect(flow.state.showDisclaimer, isTrue);
      expect(flow.state.step, TrainingFlowStep.disclaimer);

      flow.acceptDisclaimer();

      expect(flow.state.showDisclaimer, isFalse);
      expect(flow.state.step, TrainingFlowStep.intro);
    });
  });
}
```

- [ ] **Step 4: Run the ported training-flow test**

```bash
cd /Users/alexandermessinger/dev/claudvibes/corejourney/app
flutter test test/features/training/training_flow_provider_test.dart -v
```

Expected: all tests pass.

- [ ] **Step 5: Commit**

```bash
cd /Users/alexandermessinger/dev/claudvibes/corejourney/app
git add \
  test/core/sync/sync_service_test.dart \
  test/core/feature_flags/feature_flag_service_test.dart \
  test/features/progress/streak_logic_test.dart
git add \
  test/features/training/training_flow_provider_test.dart
git commit -m "test: remove stale tests and port training flow coverage"
```

---

## Task 4: Fix community_screen_test

**Files:**
- Modify: `test/features/community/community_screen_test.dart`

Two problems: (1) expects `find.text('Community')` but AppBar title is now `'Erfahrungen'`; (2) no `chatChannelsProvider` override so the test would hit real Supabase and hang/fail. The correct pattern comes from `test/features/chat/dm_screen_test.dart` which overrides `chatChannelsProvider` with `Future.value([])`.

- [ ] **Step 1: Run the failing test to confirm the errors**

```bash
cd /Users/alexandermessinger/dev/claudvibes/corejourney/app
flutter test test/features/community/community_screen_test.dart -v 2>&1 | grep -E "Expected|Actual|Failed|Error" | head -10
```

Expected: failure about missing `'Community'` text.

- [ ] **Step 2: Replace the full contents of `test/features/community/community_screen_test.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:corejourney/features/community/presentation/screens/community_screen.dart';
import 'package:corejourney/features/chat/presentation/providers/chat_providers.dart';

void main() {
  testWidgets('CommunityScreen renders Erfahrungen title and empty state',
      (tester) async {
    final router = GoRouter(
      routes: [GoRoute(path: '/', builder: (_, __) => const CommunityScreen())],
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          chatChannelsProvider.overrideWith((_) => Future.value([])),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Erfahrungen'), findsWidgets);
    expect(find.text('Noch keine geteilten Erfahrungen'), findsOneWidget);
  });
}
```

- [ ] **Step 3: Run the test**

```bash
cd /Users/alexandermessinger/dev/claudvibes/corejourney/app
flutter test test/features/community/community_screen_test.dart -v
```

Expected: 1 test passes.

- [ ] **Step 4: Commit**

```bash
cd /Users/alexandermessinger/dev/claudvibes/corejourney/app
git add test/features/community/community_screen_test.dart
git commit -m "fix: update community_screen_test — Erfahrungen title, chatChannelsProvider override"
```

---

## Task 5: Verify 0 failing tests

- [ ] **Step 1: Run full test suite**

```bash
cd /Users/alexandermessinger/dev/claudvibes/corejourney/app
flutter test --reporter=compact 2>&1 | tail -10
```

Expected: `All tests passed!` (integration_test/app_test.dart is excluded from unit runs automatically).

If any tests still fail, diagnose and fix before continuing to Task 6.

---

## Task 6: Verify `vorrunde_phases` production migration and history

**What:** `supabase/migrations/20260522_create_vorrunde_phases.sql` creates the `vorrunde_phases` table with RLS, indexes, and an `updated_at` trigger. The migration SQL was manually run against production project `sxvpiggednbftfqeokyd` on 2026-06-01. Now verify the schema and make sure Supabase migration history is repaired/tracked. Without the table or with broken RLS, `VorrundePhaseService` may silently fall back to local cache and fail to persist rows remotely.

**Migration tracking note:** Pasting into the Supabase SQL Editor bypasses the Supabase CLI migration history (`supabase_migrations.schema_migrations`). This means `supabase db push` may try to re-apply this migration in the future. Prefer CLI repair if the project is linked:

```bash
cd /Users/alexandermessinger/dev/claudvibes/corejourney/app
supabase migration repair --status applied 20260522
```

- [ ] **Step 1: Open the Supabase SQL Editor**

Go to: https://supabase.com/dashboard/project/sxvpiggednbftfqeokyd/sql/new

- [ ] **Step 2: Verify the table, policies, indexes, and trigger**

Run this verification query in the SQL Editor:

```sql
-- Should return 1 row
SELECT table_name
FROM information_schema.tables
WHERE table_schema = 'public'
  AND table_name = 'vorrunde_phases';

-- Should return 4 rows (DELETE, INSERT, SELECT, UPDATE)
SELECT policyname, cmd
FROM pg_policies
WHERE schemaname = 'public'
  AND tablename = 'vorrunde_phases'
ORDER BY cmd;

-- Should return 3 indexes
SELECT indexname
FROM pg_indexes
WHERE schemaname = 'public'
  AND tablename = 'vorrunde_phases'
ORDER BY indexname;

-- Should return 1 row: trg_vorrunde_phases_updated_at
SELECT trigger_name
FROM information_schema.triggers
WHERE event_object_schema = 'public'
  AND event_object_table = 'vorrunde_phases'
ORDER BY trigger_name;
```

Expected:
- 1 row: `vorrunde_phases`
- 4 policies: one each for DELETE, INSERT, SELECT, UPDATE
- 3 indexes: `idx_vorrunde_phases_status`, `idx_vorrunde_phases_user_null_subject`, `idx_vorrunde_phases_user_subject`
- 1 trigger: `trg_vorrunde_phases_updated_at`

If the table or required objects are missing, re-run the full contents of `supabase/migrations/20260522_create_vorrunde_phases.sql` in the SQL Editor, then repeat this verification.

- [ ] **Step 3: Check migration-history table shape before any manual insert**

Run:

```sql
SELECT column_name, data_type
FROM information_schema.columns
WHERE table_schema = 'supabase_migrations'
  AND table_name = 'schema_migrations'
ORDER BY ordinal_position;

SELECT version, name
FROM supabase_migrations.schema_migrations
WHERE version = '20260522';
```

Expected:
- If a row for `20260522` already exists, do nothing.
- If no row exists, prefer running `supabase migration repair --status applied 20260522` locally.
- Only if CLI repair is unavailable, insert a tracking row manually after confirming the table has compatible `version`, `name`, and `statements` columns:

```sql
INSERT INTO supabase_migrations.schema_migrations (version, name, statements)
VALUES (
  '20260522',
  'create_vorrunde_phases',
  ARRAY['-- applied via SQL Editor 2026-06-01']
)
ON CONFLICT DO NOTHING;
```

- [ ] **Step 4: Verify migration history is tracked**

```sql
SELECT version, name
FROM supabase_migrations.schema_migrations
WHERE version = '20260522';
```

Expected: 1 row for `20260522` / `create_vorrunde_phases`.

---

## Task 7: Smoke test Vorrunde flow on device with DB verification

**Note on swallowed errors:** `VorrundePhaseService` catches Supabase errors and returns a fallback value. A "no crash" smoke test passes even when DB writes fail silently. The SQL verification query below catches this.

- [ ] **Step 1: Launch app on simulator**

```bash
cd /Users/alexandermessinger/dev/claudvibes/corejourney/app
make run-sim
```

- [ ] **Step 2: Verify Vorrunde CTA is visible**

Log in with an account that has no active enrollment.

On the dashboard, verify one of:
- The Vorrunde primary CTA is shown (if Vorrunde phase is in `started` status)
- The normal "Paket starten" CTA is shown (if no vorrunde phase row exists yet)

Neither case should crash or show an error.

- [ ] **Step 3: Tap the training CTA**

`TrainingStartFlowScreen` should open and offer the Vorrunde recommendation step (for a Moro package). No crash, no "table not found" in logs.

- [ ] **Step 4: Confirm DB row was written**

After tapping through the start flow, run this in the Supabase SQL Editor to verify the row was persisted (replace `<user-id>` with the test account's auth UUID from the Supabase Auth dashboard):

```sql
SELECT id, user_id, subject_profile_id, status, first_started_at, created_at
FROM vorrunde_phases
WHERE user_id = '<user-id>'
ORDER BY created_at DESC
LIMIT 5;
```

Expected: at least 1 row with `status = 'started'` and a non-null `first_started_at`. If 0 rows: the service wrote silently to the local cache only, the insert hit the wrong table/constraint, or the RLS insert policy is misconfigured. Check app logs, Supabase API/Postgres logs, and the authenticated user's UUID.

---

## Done

After Task 7, the app is in a clean state:

- Test suite: 0 failures
- Production code: no missing imports, no broken `AppConfig` references
- Production DB: `vorrunde_phases` table with RLS active, migration history repaired/tracked
- Vorrunde phase flow: functional end-to-end with verified DB persistence

### What comes next

**Content (no code needed):**
- Upload professional exercise images/videos to the `exercise-media` Supabase Storage bucket
- Set `image_url`, `duo_image_url`, `video_url` on each exercise row via SQL UPDATE

**Features (code needed):**
- Push notification permission pre-prompt (educate user before OS dialog fires)
- App Store metadata, screenshots, privacy policy URL
- Trainer feature stabilization (appointments, chat, video call polish)
