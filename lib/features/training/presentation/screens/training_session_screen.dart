import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../../../../bootstrap/providers.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/navigation/app_router.dart';
import '../../../../core/notifications/notification_service.dart';
import '../../../../core/settings/settings_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/training/routine_tip_settings.dart';
import '../../../../core/training/training_familiarity_settings.dart';
import '../../../../core/training/training_session_checkpoint_store.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../assessment/presentation/providers/reflex_profile_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../mood/presentation/widgets/training_experience_sheet.dart';
import '../../../progress/presentation/providers/progress_provider.dart';
import '../../data/repositories/training_completion_repository.dart';
import '../../domain/models/exercise.dart';
import '../../domain/models/training_session.dart';
import '../../domain/services/experience_prompt_service.dart';
import '../../domain/services/vorrunde_phase_service.dart';
import '../../domain/session/session_orchestrator.dart';
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
  static const _uuid = Uuid();

  _TrainingPhase _phase = _TrainingPhase.intro;
  List<String> _completedExerciseIds = [];
  List<Exercise> _sessionExercises = const [];
  TrainingSessionState? _restoredState;
  TrainingSessionMode? _sessionMode;
  EnrollmentsTableData? _sessionEnrollment;
  String? _sessionId;
  String? _sessionUserId;
  String? _sessionProfileId;
  String? _sessionContentVersion;
  int? _familiarityCount;
  int _sessionFamiliarityCount = 0;
  String? _familiarityLoadVersion;
  bool _isStarting = false;
  bool _reachedPackageEnd = false;

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

  Future<void> _startSession(TrainingFlowState state) async {
    if (_isStarting) return;
    final l10n = AppLocalizations.of(context);
    if (!state.hasContent || state.contentVersion == null) {
      await _showPreflightError(
        l10n.trainingContentUnavailableTitle,
        l10n.trainingContentUnavailableBody,
      );
      return;
    }

    setState(() => _isStarting = true);
    try {
      final userId =
          ref.read(authStateProvider).valueOrNull?.session?.user.id ??
              Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) {
        await _showPreflightError(
          l10n.trainingContentUnavailableTitle,
          l10n.trainingSignInRequired,
        );
        return;
      }

      final db = ref.read(databaseProvider);
      final requestedProfileId = ref.read(selectedSubjectProfileProvider)?.id;
      final enrollment = await _findActiveEnrollment(
        db: db,
        userId: userId,
        subjectProfileId: requestedProfileId,
      );
      if (enrollment == null) {
        await _showPreflightError(
          l10n.trainingContentUnavailableTitle,
          l10n.trainingEnrollmentMissing,
        );
        return;
      }

      final progressRows = await (db.select(db.progressEntriesTable)
            ..where((table) => table.enrollmentId.equals(enrollment.id)))
          .get();
      if (progressRows.length != 1) {
        await _showPreflightError(
          l10n.trainingContentUnavailableTitle,
          l10n.trainingProgressMissing,
        );
        return;
      }
      final progress = progressRows.single;
      if (progress.lastDisclaimerAcceptedAt == null) {
        final accepted = await _askToAcceptDisclaimer();
        if (!mounted || !accepted) return;
        await TrainingCompletionRepository(db).acceptDisclaimer(
          progressId: progress.id,
          userId: userId,
          acceptedAt: DateTime.now(),
        );
        unawaited(ref.read(syncServiceProvider).drain());
      }

      final profileId = enrollment.subjectProfileId ?? 'self:$userId';
      final contentVersion = state.contentVersion!;
      final prefs = await SharedPreferences.getInstance();
      final checkpointStore = TrainingSessionCheckpointStore(prefs);
      final familiarityCount = TrainingFamiliaritySettings.completedSessions(
        prefs,
        profileId: profileId,
        packageId: widget.packageId,
        contentVersion: contentVersion,
      );
      var restored = checkpointStore.load(
        profileId: profileId,
        packageId: widget.packageId,
        contentVersion: contentVersion,
      );

      if (restored != null) {
        final resume = await _askToResumeSession();
        if (!mounted) return;
        if (!resume) {
          await checkpointStore.clear(
            profileId: profileId,
            packageId: widget.packageId,
            contentVersion: contentVersion,
          );
          restored = null;
        }
      }

      final exercises = List<Exercise>.unmodifiable(state.exercises);
      final mode = restored?.mode ??
          (familiarityCount < 2 ? TrainingSessionMode.tutorial : state.mode);
      setState(() {
        _sessionExercises = exercises;
        _sessionMode = mode;
        _sessionEnrollment = enrollment;
        _sessionUserId = userId;
        _sessionProfileId = profileId;
        _sessionContentVersion = contentVersion;
        _sessionId = restored?.sessionId ?? _uuid.v4();
        _restoredState = restored;
        _familiarityCount = familiarityCount;
        _sessionFamiliarityCount = familiarityCount;
        _phase = _TrainingPhase.session;
      });
    } finally {
      if (mounted) setState(() => _isStarting = false);
    }
  }

  Future<EnrollmentsTableData?> _findActiveEnrollment({
    required AppDatabase db,
    required String userId,
    required String? subjectProfileId,
  }) async {
    final rows = await (db.select(db.enrollmentsTable)
          ..where((table) => table.userId.equals(userId))
          ..where((table) => table.packageId.equals(widget.packageId))
          ..where((table) => subjectProfileId == null
              ? table.subjectProfileId.isNull()
              : table.subjectProfileId.equals(subjectProfileId))
          ..where((table) => table.status.equals('active'))
          ..limit(1))
        .get();
    return rows.firstOrNull;
  }

  void _ensureFamiliarityLoaded(TrainingFlowState state) {
    final version = state.contentVersion;
    if (!state.hasContent ||
        version == null ||
        _familiarityLoadVersion == version) {
      return;
    }
    _familiarityLoadVersion = version;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_loadFamiliarity(version));
    });
  }

  Future<void> _loadFamiliarity(String contentVersion) async {
    final userId = ref.read(authStateProvider).valueOrNull?.session?.user.id ??
        Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;
    final enrollment = await _findActiveEnrollment(
      db: ref.read(databaseProvider),
      userId: userId,
      subjectProfileId: ref.read(selectedSubjectProfileProvider)?.id,
    );
    if (enrollment == null) return;
    final profileId = enrollment.subjectProfileId ?? 'self:$userId';
    final prefs = await SharedPreferences.getInstance();
    final count = TrainingFamiliaritySettings.completedSessions(
      prefs,
      profileId: profileId,
      packageId: widget.packageId,
      contentVersion: contentVersion,
    );
    if (!mounted || _familiarityLoadVersion != contentVersion) return;
    setState(() => _familiarityCount = count);
    if (count < 2) {
      ref
          .read(trainingFlowProvider(widget.packageId).notifier)
          .setMode(TrainingSessionMode.tutorial);
    }
  }

  Future<bool> _askToResumeSession() async {
    final l10n = AppLocalizations.of(context);
    return await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (dialogContext) => AlertDialog(
            title: Text(l10n.trainingResumeSessionTitle),
            content: Text(l10n.trainingResumeSessionBody),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: Text(l10n.trainingStartOver),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: Text(l10n.trainingResumeSession),
              ),
            ],
          ),
        ) ??
        false;
  }

  Future<bool> _askToAcceptDisclaimer() async {
    return await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (dialogContext) => DisclaimerDialog(
            onAccept: () => Navigator.pop(dialogContext, true),
          ),
        ) ??
        false;
  }

  Future<void> _showPreflightError(String title, String body) {
    return showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(Icons.error_outline, color: AppColors.error),
        title: Text(title),
        content: Text(body),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(AppLocalizations.of(context).back),
          ),
        ],
      ),
    );
  }

  Future<void> _persistCompletion(TrainingSessionState state) async {
    final l10n = AppLocalizations.of(context);
    final db = ref.read(databaseProvider);
    final enrollment = _sessionEnrollment;
    final userId = _sessionUserId;
    final sessionId = _sessionId;
    final profileId = _sessionProfileId;
    final contentVersion = _sessionContentVersion;
    if (enrollment == null ||
        userId == null ||
        sessionId == null ||
        profileId == null ||
        contentVersion == null ||
        state.sessionId != sessionId) {
      throw const TrainingCompletionException(
        TrainingCompletionErrorCode.invalidArgument,
        'The active training preflight is incomplete.',
      );
    }

    if (widget.packageId == 'vorrunde') {
      final progress = await (db.select(db.progressEntriesTable)
            ..where((table) => table.enrollmentId.equals(enrollment.id)))
          .getSingleOrNull();
      if (progress == null) {
        throw const TrainingCompletionException(
          TrainingCompletionErrorCode.missingProgress,
          'The warm-up enrollment has no progress entry.',
        );
      }
      await saveVorrundeRegulationSession(
        db: db,
        syncService: ref.read(syncServiceProvider),
        enrollment: enrollment,
        progress: progress,
        completedExerciseIds: state.completedExerciseIds,
      );
    } else {
      final repository = TrainingCompletionRepository(db);
      final completedAt = DateTime.now();
      final companionRequests = await _buildCompanionCompletionRequests(
        db: db,
        userId: userId,
        parentSessionId: sessionId,
        completedExerciseIds: state.completedExerciseIds,
        completedAt: completedAt,
      );
      await repository.completeSessionsAtomically(
        requests: [
          TrainingCompletionRequest(
            sessionId: sessionId,
            userId: userId,
            enrollmentId: enrollment.id,
            completedExerciseIds: state.completedExerciseIds,
            completedAt: completedAt,
          ),
          ...companionRequests,
        ],
      );

      final updatedProgress = await (db.select(db.progressEntriesTable)
            ..where((table) => table.enrollmentId.equals(enrollment.id)))
          .getSingle();
      final totalDays = (enrollment.assignedDurationWeeks * 7).clamp(1, 3650);
      _reachedPackageEnd = updatedProgress.currentDay >= totalDays;
    }

    final prefs = await SharedPreferences.getInstance();
    await TrainingFamiliaritySettings.recordCompletion(
      prefs,
      profileId: profileId,
      packageId: widget.packageId,
      contentVersion: contentVersion,
      sessionId: sessionId,
    );

    final settings = ref.read(settingsProvider);
    if (settings.remindersEnabled) {
      try {
        await NotificationService.instance.suppressTodayAndReschedule(
          startMinutes: settings.reminderStartMinutes,
          title: l10n.reminderSessionTitle,
          body: l10n.trainingReminderSessionBody,
        );
      } on Object catch (error) {
        debugPrint('Training reminder reschedule failed: $error');
      }
    }
    unawaited(ref.read(syncServiceProvider).drain());
  }

  Future<List<TrainingCompletionRequest>> _buildCompanionCompletionRequests({
    required AppDatabase db,
    required String userId,
    required String parentSessionId,
    required List<String> completedExerciseIds,
    required DateTime completedAt,
  }) async {
    final requests = <TrainingCompletionRequest>[];
    for (final subjectProfileId in widget.companionSubjectProfileIds.toSet()) {
      final enrollment = await (db.select(db.enrollmentsTable)
            ..where((table) => table.userId.equals(userId))
            ..where(
              (table) => table.subjectProfileId.equals(subjectProfileId),
            )
            ..where((table) => table.packageId.equals(widget.packageId))
            ..where((table) => table.status.equals('active'))
            ..limit(1))
          .getSingleOrNull();
      if (enrollment == null) {
        throw TrainingCompletionException(
          TrainingCompletionErrorCode.missingEnrollment,
          'No active enrollment exists for companion "$subjectProfileId".',
        );
      }

      requests.add(
        TrainingCompletionRequest(
          sessionId: _uuid.v5(
            Namespace.url.value,
            '$parentSessionId:$subjectProfileId',
          ),
          userId: userId,
          enrollmentId: enrollment.id,
          completedExerciseIds: completedExerciseIds,
          completedAt: completedAt,
        ),
      );
    }
    return List.unmodifiable(requests);
  }

  Future<void> _handleOutroContinue() async {
    if (widget.packageId == 'vorrunde') {
      await _handleVorrundeOutroContinue();
      return;
    }

    if (_reachedPackageEnd && mounted) {
      await _showPackageCompletionReachedDialog();
    }
    if (!mounted) return;

    final enrollment = _sessionEnrollment;
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
    if (mounted) context.pop();
  }

  Future<void> _handleVorrundeOutroContinue() async {
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

    final enrollment = _sessionEnrollment;
    if (enrollment != null) {
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

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        if (_phase == _TrainingPhase.session) return;
        final shouldPop = await _onWillPop();
        if (shouldPop && context.mounted) context.go(Routes.dashboard);
      },
      child: Scaffold(
        backgroundColor: AppColors.backgroundDark,
        body: SafeArea(
          child: Stack(
            children: [
              _buildCurrentStep(flowState),
              if (_isStarting)
                const Positioned.fill(
                  child: ColoredBox(
                    color: Color(0x99000000),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                ),
              if (_phase != _TrainingPhase.session)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Semantics(
                    button: true,
                    label: AppLocalizations.of(context).trainingExitTooltip,
                    child: IconButton(
                      tooltip: AppLocalizations.of(context).trainingExitTooltip,
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () async {
                        final router = GoRouter.of(context);
                        final shouldLeave = await _onWillPop();
                        if (shouldLeave && mounted) {
                          router.go(Routes.dashboard);
                        }
                      },
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentStep(TrainingFlowState state) {
    if (_phase == _TrainingPhase.intro) {
      _ensureFamiliarityLoaded(state);
    }
    if (_phase == _TrainingPhase.intro && !state.hasContent) {
      final l10n = AppLocalizations.of(context);
      return Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.inventory_2_outlined,
                  color: AppColors.warning,
                  size: 64,
                ),
                const SizedBox(height: 18),
                Text(
                  l10n.trainingContentUnavailableTitle,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  l10n.trainingContentUnavailableBody,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    switch (_phase) {
      case _TrainingPhase.intro:
        return TrainingIntroWidget(
          exercise: state.currentExercise,
          exerciseIndex: state.currentExerciseIndex,
          totalExercises: state.totalExercises,
          mode: state.mode,
          isDuo: widget.companionSubjectProfileIds.isNotEmpty,
          completedSessions: _familiarityCount,
          contentNotice: state.isCachePending
              ? AppLocalizations.of(context).trainingContentChecking
              : state.contentIssue == null
                  ? null
                  : AppLocalizations.of(context).trainingOfflineSnapshotNotice,
          routineEnabled: (_familiarityCount ?? 0) >= 2,
          onStart: () => unawaited(_startSession(state)),
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
          exercises: _sessionExercises,
          mode: _sessionMode!,
          packageId: widget.packageId,
          contentVersion: _sessionContentVersion!,
          sessionId: _sessionId!,
          profileId: _sessionProfileId!,
          restoredState: _restoredState,
          completedSessions: _sessionFamiliarityCount,
          companionSubjectProfileIds: widget.companionSubjectProfileIds,
          persistCompletion: _persistCompletion,
          onCompleted: (completedState) {
            setState(() {
              _completedExerciseIds = completedState.completedExerciseIds;
              _phase = _TrainingPhase.outro;
            });
          },
          onCancelled: () {
            setState(() {
              _restoredState = null;
              _phase = _TrainingPhase.intro;
            });
          },
        );

      case _TrainingPhase.outro:
        return TrainingOutroWidget(
          completedCount: _completedExerciseIds.length,
          onContinue: () => unawaited(_handleOutroContinue()),
        );
    }
  }
}
