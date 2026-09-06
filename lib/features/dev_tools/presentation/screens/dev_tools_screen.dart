import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../../../config/internal_tester.dart';
import '../../../../bootstrap/providers.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/monitoring/sentry_service.dart';
import '../../../../core/time/app_clock_provider.dart';
import '../../../../features/progress/presentation/providers/progress_provider.dart';
import '../../../../features/progress/presentation/providers/streak_provider.dart';

const _uuid = Uuid();

class DevToolsScreen extends ConsumerWidget {
  const DevToolsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentEmail = Supabase.instance.client.auth.currentUser?.email ?? '';
    final isInternalTester = isInternalTesterEmail(currentEmail);
    if (!isInternalTester) {
      return const Scaffold(body: Center(child: Text('Not available')));
    }

    final progress = ref.watch(activeProgressProvider).valueOrNull;
    final enrollment = ref.watch(activeEnrollmentProvider).valueOrNull;
    final completionReady = ref.watch(completionReadyProvider);
    final appClock = ref.watch(appClockProvider);
    final simulatedNow = appClock.now();
    final offset = appClock.offset;

    final totalDays = (enrollment?.assignedDurationWeeks ?? 8) * 7;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dev Tools'),
        backgroundColor: Colors.deepOrange,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Status Card ──────────────────────────────────────────────────
            _SectionCard(
              title: 'Current State',
              color: Colors.deepOrange.shade50,
              children: [
                _StatusRow(
                  'Internal Tester',
                  currentEmail,
                ),
                const Divider(),
                _StatusRow(
                  'Current Day',
                  progress != null
                      ? '${progress.currentDay} / $totalDays'
                      : '—',
                ),
                _StatusRow(
                  'Target Completion',
                  enrollment != null
                      ? _formatDate(enrollment.targetCompletionDate)
                      : '—',
                ),
                _StatusRow(
                  'Completion Ready',
                  completionReady ? '✅ YES — Banner visible' : '❌ No',
                  valueColor: completionReady ? Colors.green : Colors.grey,
                ),
                _StatusRow(
                  'Daily Streak',
                  '${ref.watch(streakViewProvider).valueOrNull?.length ?? 0}',
                ),
                _StatusRow(
                  'Package',
                  enrollment?.packageId ?? '—',
                ),
                _StatusRow(
                  'Enrollment Status',
                  enrollment?.status ?? '—',
                ),
                if (progress == null || enrollment == null) ...[
                  const Divider(),
                  Text(
                    'Kein aktives Training gefunden. Melde dich mit dem Test-Account an oder starte ein Trainingspaket, dann werden die Simulations-Buttons aktiv.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade700,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 16),

            // ── Day Simulation ────────────────────────────────────────────────
            _SectionCard(
              title: 'Simulate Days',
              color: Colors.blue.shade50,
              children: [
                Text(
                  'Each button adds fake completed sessions. Does NOT go through the training UI.',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
                if (offset != Duration.zero) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Simulated date: ${_formatIsoDate(simulatedNow)} (${_formatOffsetLabel(offset)})',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.blue.shade800,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _ActionButton(
                        label: '+1 Tag',
                        icon: Icons.looks_one_outlined,
                        color: Colors.blue,
                        onPressed: progress != null && enrollment != null
                            ? () => _advanceDays(
                                context, ref, progress, enrollment, 1)
                            : null,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _ActionButton(
                        label: '+7 Tage',
                        icon: Icons.calendar_view_week,
                        color: Colors.blue,
                        onPressed: progress != null && enrollment != null
                            ? () => _advanceDays(
                                context, ref, progress, enrollment, 7)
                            : null,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _ActionButton(
                        label: '+30 Tage',
                        icon: Icons.calendar_month,
                        color: Colors.blueAccent,
                        onPressed: progress != null && enrollment != null
                            ? () => _advanceDays(
                                context, ref, progress, enrollment, 30)
                            : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: offset == Duration.zero
                        ? null
                        : () => ref.read(appClockProvider).reset(),
                    icon: const Icon(Icons.restore),
                    label: const Text('Reset Clock'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // ── Completion Banner ─────────────────────────────────────────────
            _SectionCard(
              title: 'Completion Banner',
              color: Colors.green.shade50,
              children: [
                Text(
                  'Sets target_completion_date to today → Banner appears on dashboard.',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 12),
                _ActionButton(
                  label: 'Target = Heute (Banner zeigen)',
                  icon: Icons.flag_outlined,
                  color: Colors.green,
                  onPressed: enrollment != null
                      ? () => _setTargetToToday(context, ref, enrollment)
                      : null,
                ),
                const SizedBox(height: 8),
                _ActionButton(
                  label: 'Target +7 Tage (Banner verstecken)',
                  icon: Icons.schedule,
                  color: Colors.grey.shade600,
                  onPressed: enrollment != null
                      ? () => _extendTarget(context, ref, enrollment, 7)
                      : null,
                ),
              ],
            ),
            const SizedBox(height: 16),

            // ── Reset ─────────────────────────────────────────────────────────
            _SectionCard(
              title: 'Reset',
              color: Colors.red.shade50,
              children: [
                Text(
                  'Setzt Fortschritt zurück ohne den Account zu löschen.',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 12),
                _ActionButton(
                  label: 'Fortschritt → Tag 1',
                  icon: Icons.restart_alt,
                  color: Colors.orange,
                  onPressed: progress != null && enrollment != null
                      ? () => _resetToDay1(context, ref, progress, enrollment)
                      : null,
                ),
                const SizedBox(height: 8),
                _ActionButton(
                  label: 'Alle Sessions löschen',
                  icon: Icons.delete_sweep_outlined,
                  color: Colors.red,
                  onPressed: enrollment != null
                      ? () => _deleteAllSessions(context, ref, enrollment)
                      : null,
                ),
              ],
            ),
            const SizedBox(height: 16),
            // ── Diagnostics (T15) ────────────────────────────────────────────
            _SectionCard(
              title: 'Diagnostics',
              color: Colors.purple.shade50,
              children: [
                Text(
                  'Sentry: ${SentryService.isActive ? "aktiv" : "inaktiv (kein SENTRY_DSN in der Env-Datei)"}',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 12),
                _ActionButton(
                  label: 'Test-Crash an Sentry senden',
                  icon: Icons.bug_report_outlined,
                  color: Colors.purple,
                  onPressed: () => _sendSentryTestCrash(context),
                ),
              ],
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Future<void> _sendSentryTestCrash(BuildContext context) async {
    await SentryService.captureException(
      StateError('Sentry test crash — Dev Tools (T15 verification)'),
      StackTrace.current,
    );
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          SentryService.isActive
              ? 'Test-Event gesendet — im Sentry-Dashboard prüfen.'
              : 'Sentry ist inaktiv (kein SENTRY_DSN) — nichts gesendet.',
        ),
      ),
    );
  }

  // ── Actions ────────────────────────────────────────────────────────────────

  Future<void> _advanceDays(
    BuildContext context,
    WidgetRef ref,
    ProgressEntriesTableData progress,
    EnrollmentsTableData enrollment,
    int days,
  ) async {
    final db = ref.read(databaseProvider);
    final syncService = ref.read(syncServiceProvider);
    final clock = ref.read(appClockProvider);
    final userId = progress.userId;
    final now = clock.now();

    // Insert fake training sessions for each day, going backwards from yesterday
    for (int i = days; i >= 1; i--) {
      final fakeDate = DateTime(now.year, now.month, now.day - i);
      final sessionId = _uuid.v4();
      await db.into(db.trainingSessionsTable).insertOnConflictUpdate(
            TrainingSessionsTableCompanion.insert(
              id: sessionId,
              userId: userId,
              enrollmentId: enrollment.id,
              sessionDate: fakeDate,
              dayNumber: progress.currentDay + (days - i),
              completedExerciseIds: '[]',
              isCompleted: const drift.Value(true),
              completedAt: drift.Value(fakeDate),
            ),
          );
      await syncService.enqueueUpsert(
        tableName: 'training_sessions',
        recordId: sessionId,
        payload: {
          'id': sessionId,
          'user_id': userId,
          'enrollment_id': enrollment.id,
          'session_date': fakeDate.toIso8601String().substring(0, 10),
          'day_number': progress.currentDay + (days - i),
          'completed_exercise_ids': <String>[],
          'is_completed': true,
          'completed_at': fakeDate.toIso8601String(),
        },
      );
    }

    // Update progress entry
    final newDay = progress.currentDay + days;
    final fakeLastActivity = DateTime(now.year, now.month, now.day - 1);
    await (db.update(db.progressEntriesTable)
          ..where((t) => t.id.equals(progress.id)))
        .write(ProgressEntriesTableCompanion(
      currentDay: drift.Value(newDay),
      lastActivityDate: drift.Value(fakeLastActivity),
      totalSessionsSinceDisclaimer:
          drift.Value(progress.totalSessionsSinceDisclaimer + days),
      needsSync: const drift.Value(true),
      updatedAt: drift.Value(now),
    ));

    await syncService.enqueueUpsert(
      tableName: 'progress_entries',
      recordId: progress.id,
      payload: {
        'id': progress.id,
        'user_id': userId,
        'enrollment_id': enrollment.id,
        'current_day': newDay,
        'last_activity_date':
            fakeLastActivity.toIso8601String().substring(0, 10),
      },
    );

    clock.setOffset(clock.offset + Duration(days: days));

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text('+$days Tag${days > 1 ? 'e' : ''} simuliert → Tag $newDay'),
          backgroundColor: Colors.blue,
        ),
      );
    }
  }

  Future<void> _setTargetToToday(
    BuildContext context,
    WidgetRef ref,
    EnrollmentsTableData enrollment,
  ) async {
    final db = ref.read(databaseProvider);
    final syncService = ref.read(syncServiceProvider);
    final today = DateTime.now();

    await (db.update(db.enrollmentsTable)
          ..where((t) => t.id.equals(enrollment.id)))
        .write(EnrollmentsTableCompanion(
      targetCompletionDate: drift.Value(today),
      needsSync: const drift.Value(true),
      updatedAt: drift.Value(today),
    ));

    await syncService.enqueueUpsert(
      tableName: 'enrollments',
      recordId: enrollment.id,
      payload: {
        'id': enrollment.id,
        'target_completion_date': today.toIso8601String(),
      },
    );

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Completion Banner ist jetzt sichtbar'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _extendTarget(
    BuildContext context,
    WidgetRef ref,
    EnrollmentsTableData enrollment,
    int days,
  ) async {
    final db = ref.read(databaseProvider);
    final syncService = ref.read(syncServiceProvider);
    final newTarget = enrollment.targetCompletionDate.add(Duration(days: days));
    final now = DateTime.now();

    await (db.update(db.enrollmentsTable)
          ..where((t) => t.id.equals(enrollment.id)))
        .write(EnrollmentsTableCompanion(
      targetCompletionDate: drift.Value(newTarget),
      needsSync: const drift.Value(true),
      updatedAt: drift.Value(now),
    ));

    await syncService.enqueueUpsert(
      tableName: 'enrollments',
      recordId: enrollment.id,
      payload: {
        'id': enrollment.id,
        'target_completion_date': newTarget.toIso8601String(),
      },
    );

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Target +$days Tage → ${_formatDate(newTarget)}'),
          backgroundColor: Colors.grey.shade700,
        ),
      );
    }
  }

  Future<void> _resetToDay1(
    BuildContext context,
    WidgetRef ref,
    ProgressEntriesTableData progress,
    EnrollmentsTableData enrollment,
  ) async {
    final db = ref.read(databaseProvider);
    final syncService = ref.read(syncServiceProvider);
    final now = DateTime.now();

    await (db.update(db.progressEntriesTable)
          ..where((t) => t.id.equals(progress.id)))
        .write(ProgressEntriesTableCompanion(
      currentDay: const drift.Value(1),
      lastActivityDate: const drift.Value(null),
      totalSessionsSinceDisclaimer: const drift.Value(0),
      needsSync: const drift.Value(true),
      updatedAt: drift.Value(now),
    ));

    await syncService.enqueueUpsert(
      tableName: 'progress_entries',
      recordId: progress.id,
      payload: {
        'id': progress.id,
        'user_id': progress.userId,
        'enrollment_id': enrollment.id,
        'current_day': 1,
        'last_activity_date': null,
      },
    );

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🔄 Fortschritt zurückgesetzt auf Tag 1'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  Future<void> _deleteAllSessions(
    BuildContext context,
    WidgetRef ref,
    EnrollmentsTableData enrollment,
  ) async {
    final db = ref.read(databaseProvider);

    await (db.delete(db.trainingSessionsTable)
          ..where((t) => t.enrollmentId.equals(enrollment.id)))
        .go();

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🗑 Alle Sessions für dieses Enrollment gelöscht'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  String _formatDate(DateTime dt) =>
      '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}.${dt.year}';

  String _formatIsoDate(DateTime dt) =>
      '${dt.year.toString().padLeft(4, '0')}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';

  String _formatOffsetLabel(Duration offset) {
    final days = offset.inDays;
    if (days == 0) return 'today';
    final absDays = days.abs();
    final suffix = absDays == 1 ? 'day' : 'days';
    final sign = days > 0 ? '+' : '-';
    return '$sign$absDays $suffix';
  }
}

// ── Reusable Widgets ──────────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  final String title;
  final Color color;
  final List<Widget> children;

  const _SectionCard({
    required this.title,
    required this.color,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black12),
      ),
      padding: const EdgeInsets.all(16),
      child: DefaultTextStyle.merge(
        style: TextStyle(color: Colors.grey.shade900),
        child: IconTheme.merge(
          data: IconThemeData(color: Colors.grey.shade800),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 12),
              ...children,
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _StatusRow(this.label, this.value, {this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          SizedBox(
            width: 150,
            child: Text(label,
                style: TextStyle(fontSize: 13, color: Colors.grey.shade700)),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: valueColor ?? Colors.grey.shade900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback? onPressed;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label, style: const TextStyle(fontSize: 13)),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        disabledBackgroundColor: Colors.grey.shade300,
        foregroundColor: Colors.white,
        disabledForegroundColor: Colors.grey.shade700,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}
