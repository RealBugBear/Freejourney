import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../bootstrap/providers.dart';
import '../../../../core/navigation/app_router.dart';
import '../../../../core/onboarding/onboarding_hint_provider.dart';
import '../../../../core/settings/settings_provider.dart';
import '../../../../core/sync/sync_status.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../features/progress/presentation/providers/progress_provider.dart';
import '../../../../features/training/domain/models/training_session.dart'
    show TrainingSessionMode;
import '../../../../l10n/app_localizations.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  Future<void> _confirmRestartMoro(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final l10n = AppLocalizations.of(context);
    final enrollment = ref.read(activeEnrollmentProvider).valueOrNull;
    if (enrollment == null || enrollment.packageId == 'moro') return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.moroRestartTitle),
        content: Text(l10n.moroRestartBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.moroRestartConfirm),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    try {
      await restartMoroFromCurrentPackage(
        db: ref.read(databaseProvider),
        syncService: ref.read(syncServiceProvider),
        currentEnrollment: enrollment,
      );
      ref.read(selectedPackageIdProvider.notifier).select('moro');
      if (context.mounted) context.go(Routes.dashboard);
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.errorSaveFailed)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);
    final enrollment = ref.watch(activeEnrollmentProvider).valueOrNull;
    final showMoroRestart = ref.watch(moroCompletedProvider) &&
        enrollment != null &&
        enrollment.packageId != 'moro';

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settings)),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 32),
        children: [
          _SectionHeader(title: l10n.settingsTraining),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.trainingMode,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      l10n.settingsTrainingModeDescription,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: cs.onSurfaceVariant,
                          ),
                    ),
                    const SizedBox(height: 16),
                    _SegmentedRow<TrainingSessionMode>(
                      options: const [
                        TrainingSessionMode.tutorial,
                        TrainingSessionMode.routine,
                      ],
                      selected: settings.trainingMode,
                      label: (mode) => switch (mode) {
                        TrainingSessionMode.tutorial => l10n.tutorialMode,
                        TrainingSessionMode.routine => l10n.routineMode,
                      },
                      onChanged: notifier.setTrainingMode,
                    ),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: _SegmentedRow<TrainingFeedbackMode>(
              options: const [
                TrainingFeedbackMode.silent,
                TrainingFeedbackMode.haptic,
                TrainingFeedbackMode.voiceCues,
              ],
              selected: settings.feedbackMode,
              label: (mode) => switch (mode) {
                TrainingFeedbackMode.silent => l10n.silentMode,
                TrainingFeedbackMode.haptic => l10n.hapticMode,
                TrainingFeedbackMode.voiceCues => l10n.voiceCuesMode,
              },
              onChanged: notifier.setFeedbackMode,
            ),
          ),
          _SectionHeader(title: l10n.settingsReminders),
          SwitchListTile(
            title: Text(l10n.reminderEnabled),
            value: settings.remindersEnabled,
            activeThumbColor: AppColors.primary,
            onChanged: notifier.setRemindersEnabled,
          ),
          if (settings.remindersEnabled) ...[
            _TimePickerTile(
              label: '${l10n.reminderWindow} · ${l10n.reminderFrom}',
              time: settings.reminderStart,
              onChanged: notifier.setReminderStart,
            ),
            _TimePickerTile(
              label: '${l10n.reminderWindow} · ${l10n.reminderTo}',
              time: settings.reminderEnd,
              onChanged: notifier.setReminderEnd,
            ),
          ],
          _SectionHeader(title: l10n.settingsTheme),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: _SegmentedRow<String>(
              options: const ['de', 'en'],
              selected: settings.languageCode,
              label: (code) => code == 'de' ? 'Deutsch' : 'English',
              onChanged: notifier.setLanguage,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: _SegmentedRow<ThemeMode>(
              options: const [
                ThemeMode.system,
                ThemeMode.light,
                ThemeMode.dark,
              ],
              selected: settings.themeMode,
              label: (mode) => switch (mode) {
                ThemeMode.system => l10n.themeSystem,
                ThemeMode.light => l10n.themeLight,
                ThemeMode.dark => l10n.themeDark,
              },
              onChanged: notifier.setThemeMode,
            ),
          ),
          _SectionHeader(title: l10n.settingsAdvanced),
          ListTile(
            leading: const Icon(Icons.help_outline),
            title: Text(l10n.settingsResetIntroductions),
            subtitle: Text(l10n.settingsResetIntroductionsDescription),
            onTap: () async {
              await ref
                  .read(onboardingHintControllerProvider.notifier)
                  .resetAll();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(l10n.settingsResetIntroductionsSuccess),
                  ),
                );
              }
            },
          ),
          if (showMoroRestart)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Card(
                child: ListTile(
                  leading: const Icon(
                    Icons.replay_circle_filled_outlined,
                    color: AppColors.warning,
                  ),
                  title: Text(l10n.moroRestartSettingsTitle),
                  subtitle: Text(l10n.moroRestartSettingsSubtitle),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => _confirmRestartMoro(context, ref),
                ),
              ),
            ),
          const _SyncStatusTile(),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 4),
      child: Text(
        title.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: cs.onSurfaceVariant,
              letterSpacing: 0.8,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}

class _SegmentedRow<T> extends StatelessWidget {
  const _SegmentedRow({
    required this.options,
    required this.selected,
    required this.label,
    required this.onChanged,
  });

  final List<T> options;
  final T selected;
  final String Function(T) label;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<T>(
      segments: options
          .map((option) => ButtonSegment<T>(
                value: option,
                label: Text(label(option)),
              ))
          .toList(),
      selected: {selected},
      onSelectionChanged: (selection) => onChanged(selection.first),
      style: SegmentedButton.styleFrom(
        selectedBackgroundColor: AppColors.primary,
        selectedForegroundColor: Colors.white,
        textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
      ),
    );
  }
}

class _SyncStatusTile extends ConsumerWidget {
  const _SyncStatusTile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    final status = ref.watch(syncStatusProvider).valueOrNull;
    final syncService = ref.read(syncServiceProvider);

    final (icon, color, label) = switch (status) {
      null => (Icons.sync, cs.onSurfaceVariant, l10n.loading),
      SyncStatus(isSyncing: true) => (
          Icons.sync,
          AppColors.primary,
          l10n.syncInProgress,
        ),
      SyncStatus(hasFailures: true) => (
          Icons.sync_problem,
          AppColors.error,
          l10n.syncStatusFailed(status.failedCount),
        ),
      SyncStatus(hasPending: true) => (
          Icons.sync_disabled,
          AppColors.warning,
          l10n.syncStatusPending(status.pendingCount),
        ),
      _ => (
          Icons.cloud_done_outlined,
          AppColors.success,
          l10n.syncStatusOk,
        ),
    };

    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(label),
      trailing: TextButton(
        onPressed: status?.isSyncing == true ? null : () => syncService.drain(),
        child: Text(l10n.syncNow),
      ),
    );
  }
}

class _TimePickerTile extends StatelessWidget {
  const _TimePickerTile({
    required this.label,
    required this.time,
    required this.onChanged,
  });

  final String label;
  final TimeOfDay time;
  final ValueChanged<TimeOfDay> onChanged;

  @override
  Widget build(BuildContext context) {
    final formatted =
        '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';

    return ListTile(
      title: Text(label),
      trailing: TextButton(
        onPressed: () async {
          final picked = await showTimePicker(
            context: context,
            initialTime: time,
            builder: (ctx, child) => MediaQuery(
              data: MediaQuery.of(ctx).copyWith(alwaysUse24HourFormat: true),
              child: child!,
            ),
          );
          if (picked != null) onChanged(picked);
        },
        child: Text(
          formatted,
          style: const TextStyle(
            color: AppColors.primary,
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}
