import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:drift/drift.dart' as drift;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../../../../core/navigation/app_router.dart';
import '../../../../core/training/routine_tip_settings.dart';

import '../../../../bootstrap/providers.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/notifications/notification_service.dart';
import '../../../../core/sync/sync_service.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../../core/settings/settings_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../mood/presentation/widgets/training_experience_sheet.dart';
import '../../domain/services/experience_prompt_service.dart';
import '../../domain/services/vorrunde_phase_service.dart';
import '../../domain/models/training_session.dart';
import '../../../progress/presentation/providers/progress_provider.dart';
import '../../../assessment/presentation/providers/reflex_profile_provider.dart';
import '../providers/training_flow_provider.dart';
import '../widgets/disclaimer_dialog.dart';
import '../widgets/training_intro_widget.dart';
import '../widgets/training_outro_widget.dart';
import 'immersive_session_screen.dart';

enum _TrainingPhase { intro, session, outro }

class TrainingSessionLaunchArgs {
  const TrainingSessionLaunchArgs({
    required this.packageId,
    this.companionSubjectProfileIds = const [],
  });

  final String packageId;
  final List<String> companionSubjectProfileIds;
}

class TrainingSessionScreen extends ConsumerStatefulWidget {
  final String packageId;
  final List<String> companionSubjectProfileIds;

  const TrainingSessionScreen({
    super.key,
    this.packageId = 'moro',
    this.companionSubjectProfileIds = const [],
  });

  @override
  ConsumerState<TrainingSessionScreen> createState() =>
      _TrainingSessionScreenState();
}

class _TrainingSessionScreenState extends ConsumerState<TrainingSessionScreen> {
  _TrainingPhase _phase = _TrainingPhase.intro;
  List<String> _completedExerciseIds = [];

  @override
  void initState() {
    super.initState();
    WakelockPlus.enable();
  }

  @override
  void dispose() {
    WakelockPlus.disable();
    super.dispose();
  }

  Future<void> _handleOutroContinue(TrainingFlowState state) async {
    final l10n = AppLocalizations.of(context);
    if (widget.packageId == 'vorrunde') {
      await _handleVorrundeOutroContinue(state);
      return;
    }

    // Save session + update progress in background.
    //
    // IMPORTANT: Do NOT use activeEnrollmentProvider here — it is keyed to
    // selectedPackageIdProvider, which may differ from widget.packageId if the
    // user has multiple packages. Query the DB directly for this package.
    final db = ref.read(databaseProvider);
    final syncService = ref.read(syncServiceProvider);
    final userId = ref.read(authStateProvider).valueOrNull?.session?.user.id ??
        Supabase.instance.client.auth.currentUser?.id;
    final subjectProfileId = ref.read(selectedSubjectProfileProvider)?.id;

    EnrollmentsTableData? enrollment;
    ProgressEntriesTableData? progress;

    if (userId != null) {
      final rows = await (db.select(db.enrollmentsTable)
            ..where((t) => t.userId.equals(userId))
            ..where((t) => t.packageId.equals(widget.packageId))
            ..where((t) => subjectProfileId == null
                ? t.subjectProfileId.isNull()
                : (t.subjectProfileId.equals(subjectProfileId) |
                    t.subjectProfileId.isNull()))
            ..where((t) => t.status.equals('active'))
            ..orderBy([
              (t) => drift.OrderingTerm(
                    expression:
                        t.subjectProfileId.equals(subjectProfileId ?? ''),
                    mode: drift.OrderingMode.desc,
                  ),
            ])
            ..limit(1))
          .get();
      enrollment = rows.firstOrNull;
      if (enrollment != null) {
        progress = await (db.select(db.progressEntriesTable)
              ..where((t) => t.enrollmentId.equals(enrollment!.id))
              ..limit(1))
            .getSingleOrNull();
      }
    }

    var reachedPackageEnd = false;
    if (enrollment != null && progress != null) {
      final totalDays = (enrollment.assignedDurationWeeks * 7).clamp(1, 3650);
      reachedPackageEnd = progress.currentDay >= totalDays;
      await saveCompletedSession(
        db: db,
        syncService: syncService,
        enrollment: enrollment,
        progress: progress,
        completedExerciseIds: state.completedExerciseIds,
      );
      await _saveCompanionSessions(
        db: db,
        syncService: syncService,
        userId: userId,
        completedExerciseIds: state.completedExerciseIds,
      );
    }

    // Suppress today's training reminder since the session is done.
    final settings = ref.read(settingsProvider);
    if (settings.remindersEnabled) {
      await NotificationService.instance.suppressTodayAndReschedule(
        startMinutes: settings.reminderStartMinutes,
        titleDe: l10n.reminderSessionTitle,
        bodyDe: l10n.trainingReminderSessionBody,
      );
    }

    if (!mounted) return;

    if (reachedPackageEnd) {
      await _showPackageCompletionReachedDialog();
    }

    if (!mounted) return;

    // One combined experience prompt per day (mood + text + optional share).
    if (enrollment != null) {
      final shouldShow = await ExperiencePromptService.shouldShow();
      if (shouldShow && mounted) {
        await showTrainingExperienceSheet(
          context,
          enrollmentId: enrollment.id,
          packageId: widget.packageId,
        );
      }
    }

    if (!mounted) return;

    final prefs = await SharedPreferences.getInstance();
    await RoutineTipSettings.incrementSessionCount(prefs);

    if (!mounted) return;
    context.pop();
  }

  Future<void> _handleVorrundeOutroContinue(TrainingFlowState state) async {
    final userId = ref.read(authStateProvider).valueOrNull?.session?.user.id ??
        Supabase.instance.client.auth.currentUser?.id;
    final subjectProfileId = ref.read(selectedSubjectProfileProvider)?.id;
    if (userId != null) {
      final repo = ref.read(vorrundePhaseRepositoryProvider);
      final phase = await repo.fetch(
        userId: userId,
        subjectProfileId: subjectProfileId,
      );
      if (phase == null) {
        await repo.start(userId: userId, subjectProfileId: subjectProfileId);
      } else if (phase.status == VorrundePhaseStatus.started &&
          phase.isReadyForMoro(DateTime.now())) {
        await repo.complete(userId: userId, subjectProfileId: subjectProfileId);
      }
      ref.invalidate(vorrundePhaseProvider(subjectProfileId));
    }

    final enrollment = ref.read(activeEnrollmentProvider).valueOrNull;
    final progress = ref.read(activeProgressProvider).valueOrNull;
    if (enrollment != null && progress != null) {
      await saveVorrundeRegulationSession(
        db: ref.read(databaseProvider),
        syncService: ref.read(syncServiceProvider),
        enrollment: enrollment,
        progress: progress,
        completedExerciseIds: state.completedExerciseIds,
      );
      final shouldShow = await ExperiencePromptService.shouldShow();
      if (shouldShow && mounted) {
        await showTrainingExperienceSheet(
          context,
          enrollmentId: enrollment.id,
          packageId: 'vorrunde',
        );
      }
    }

    if (!mounted) return;
    context.go(Routes.trainingStart, extra: 'moro');
  }

  Future<void> _saveCompanionSessions({
    required AppDatabase db,
    required SyncService syncService,
    required String? userId,
    required List<String> completedExerciseIds,
  }) async {
    if (userId == null || widget.companionSubjectProfileIds.isEmpty) return;

    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);

    for (final subjectProfileId in widget.companionSubjectProfileIds) {
      final enrollment = await (db.select(db.enrollmentsTable)
            ..where((t) => t.userId.equals(userId))
            ..where((t) => t.subjectProfileId.equals(subjectProfileId))
            ..where((t) => t.packageId.equals(widget.packageId))
            ..where((t) => t.status.equals('active'))
            ..limit(1))
          .getSingleOrNull();
      if (enrollment == null) continue;

      final progress = await (db.select(db.progressEntriesTable)
            ..where((t) => t.enrollmentId.equals(enrollment.id))
            ..limit(1))
          .getSingleOrNull();
      if (progress == null) continue;

      final lastActivity = progress.lastActivityDate;
      final completedToday = lastActivity != null &&
          lastActivity.year == todayDate.year &&
          lastActivity.month == todayDate.month &&
          lastActivity.day == todayDate.day;
      if (completedToday) continue;

      await saveCompletedSession(
        db: db,
        syncService: syncService,
        enrollment: enrollment,
        progress: progress,
        completedExerciseIds: completedExerciseIds,
      );
    }
  }

  Future<void> _showPackageCompletionReachedDialog() async {
    final l10n = AppLocalizations.of(context);
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        icon: const Icon(
          Icons.emoji_events_outlined,
          color: AppColors.primary,
          size: 44,
        ),
        title: Text(l10n.completionReachedTitle),
        content: Text(l10n.completionReachedBody),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.completionBackToDashboard),
          ),
        ],
      ),
    );
  }

  Future<bool> _onWillPop() async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.cancel),
        content: Text(l10n.trainingSessionExitUnsaved),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.back),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: Text(l10n.cancel),
          ),
        ],
      ),
    );
    return confirmed ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final pkg = widget.packageId;
    final flowState = ref.watch(trainingFlowProvider(pkg));

    // Show disclaimer as dialog overlay
    if (flowState.showDisclaimer) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => DisclaimerDialog(
            onAccept: () {
              Navigator.of(context).pop();
              ref.read(trainingFlowProvider(pkg).notifier).acceptDisclaimer();
            },
          ),
        );
      });
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final shouldPop = await _onWillPop();
        if (shouldPop && context.mounted) context.go(Routes.dashboard);
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: Stack(
            children: [
              _buildCurrentStep(flowState),
              // Close button — always visible top-right
              Positioned(
                top: 8,
                right: 8,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white60),
                  onPressed: () async {
                    final router = GoRouter.of(context);
                    final shouldLeave = await _onWillPop();
                    if (shouldLeave && mounted) {
                      router.go(Routes.dashboard);
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentStep(TrainingFlowState state) {
    switch (_phase) {
      case _TrainingPhase.intro:
        return TrainingIntroWidget(
          exercise: state.currentExercise,
          exerciseIndex: state.currentExerciseIndex,
          totalExercises: state.totalExercises,
          mode: state.mode,
          isDuo: widget.companionSubjectProfileIds.isNotEmpty,
          onStart: () => setState(() => _phase = _TrainingPhase.session),
          onModeChanged: (newMode) {
            // Update the flow state so the toggle visually switches immediately.
            ref
                .read(trainingFlowProvider(widget.packageId).notifier)
                .setMode(newMode);
            // Also persist to settings so the next session starts in the chosen mode.
            ref.read(settingsProvider.notifier).setTrainingMode(newMode);
          },
        );

      case _TrainingPhase.session:
        return ImmersiveSessionScreen(
          exercises: state.exercises,
          isRoutineMode: state.mode == TrainingSessionMode.routine,
          packageId: widget.packageId,
          companionSubjectProfileIds: widget.companionSubjectProfileIds,
          onComplete: (ids) {
            setState(() {
              _completedExerciseIds = ids;
              _phase = _TrainingPhase.outro;
            });
          },
        );

      case _TrainingPhase.outro:
        final completedState = state.copyWith(
          completedExerciseIds: _completedExerciseIds,
          isComplete: true,
          step: TrainingFlowStep.outro,
        );
        return TrainingOutroWidget(
          completedCount: _completedExerciseIds.length,
          onContinue: () => _handleOutroContinue(completedState),
        );
    }
  }
}
