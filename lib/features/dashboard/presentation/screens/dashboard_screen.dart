import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' hide Column;
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../bootstrap/providers.dart';
import '../../../../app.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/navigation/app_router.dart';
import '../../../../core/onboarding/onboarding_hint_gate.dart';
import '../../../../core/onboarding/onboarding_hint_provider.dart';
import '../../../../core/training/routine_tip_settings.dart';
import '../../../../core/training/training_anchor_settings.dart';
import '../../../../core/notifications/notification_service.dart';
import '../../../../core/settings/settings_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/time/app_clock_provider.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../chat/presentation/providers/chat_providers.dart';
import '../../../chat/presentation/widgets/direct_messages_action.dart';
import '../../../mood/presentation/providers/mood_provider.dart';
import '../../../mood/presentation/widgets/mood_checkin_sheet.dart';
import '../../../mood/presentation/widgets/training_experience_sheet.dart';
import '../../../training/domain/models/exercise.dart';
import '../../../training/domain/models/training_session.dart';
import '../../../training/domain/services/experience_prompt_service.dart';
import '../../../training/domain/services/vorrunde_phase_service.dart';
import '../../../training/presentation/providers/training_flow_provider.dart';
import '../../../training/presentation/apply_training_anchor.dart';
import '../../../training/presentation/screens/training_session_screen.dart';
import '../../../training/presentation/widgets/training_anchor_sheet.dart';
import '../../../consent/presentation/providers/consent_provider.dart';
import '../../../assessment/presentation/providers/reflex_profile_provider.dart';
import '../../../profile/presentation/providers/profile_provider.dart';
import '../../../../core/sync/sync_service.dart';
import '../../../progress/domain/streak/streak_credits.dart';
import '../../../progress/presentation/providers/progress_provider.dart';
import '../../../progress/presentation/providers/streak_provider.dart';
import '../../../progress/presentation/widgets/streak_row.dart';
import '../../../training/presentation/widgets/joint_training_sheet.dart';
import '../../../trainer/presentation/providers/trainer_provider.dart';

/// Records a training day for each of [subjectProfileIds] (spec §7.2, D12).
///
/// A profile that already has a finished session today is skipped, so a second
/// tap cannot inflate anybody's series.
Future<void> logTrainingDayForProfiles({
  required AppDatabase db,
  required SyncService? syncService,
  required String userId,
  required String packageId,
  required List<String> subjectProfileIds,
  required DateTime now,
}) async {
  final today = dateOnly(now);

  for (final subjectProfileId in subjectProfileIds) {
    final enrollment = await (db.select(db.enrollmentsTable)
          ..where((t) => t.subjectProfileId.equals(subjectProfileId))
          ..where((t) => t.packageId.equals(packageId))
          ..where((t) => t.status.equals('active'))
          ..limit(1))
        .getSingleOrNull();
    if (enrollment == null) continue;

    final progress = await (db.select(db.progressEntriesTable)
          ..where((t) => t.enrollmentId.equals(enrollment.id))
          ..limit(1))
        .getSingleOrNull();
    if (progress == null) continue;

    final already = await (db.select(db.trainingSessionsTable)
          ..where((t) => t.subjectProfileId.equals(subjectProfileId))
          ..where((t) => t.isCompleted.equals(true))
          ..where((t) => t.sessionDate.isBiggerOrEqualValue(today))
          ..where((t) => t.sessionDate.isSmallerThanValue(nextDay(today)))
          ..limit(1))
        .getSingleOrNull();
    if (already != null) continue;

    await saveCompletedSession(
      db: db,
      syncService: syncService,
      enrollment: enrollment,
      progress: progress,
      completedExerciseIds: const [],
      userId: userId,
      now: now,
    );
  }
}

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  bool _onboardingCheckDone = false;
  bool _usernameCheckDone = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkOneTimePrompts());
  }

  Future<void> _checkOneTimePrompts() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;

    // At most one sheet per return. The anchor question comes first because it
    // belongs to the moment right after the first session; the routine tip
    // only becomes due from the second session on, so in practice they never
    // compete — the guard is here so a future change cannot stack them.
    if (TrainingAnchorSettings.shouldAsk(prefs)) {
      await TrainingAnchorSettings.markAsked(prefs);
      if (!mounted) return;
      await _askTrainingAnchor();
      return;
    }

    if (RoutineTipSettings.shouldShowTip(prefs)) {
      await RoutineTipSettings.markTipShown(prefs);
      if (!mounted) return;
      _showRoutineTip();
    }
  }

  Future<void> _askTrainingAnchor() async {
    final profile = ref.read(selectedSubjectProfileProvider);
    final result = await showTrainingAnchorSheet(
      context,
      isAdultSelf: profile?.profileType == 'adult_self',
    );
    if (result == null || !mounted) return;
    await applyTrainingAnchor(ref, result);
  }

  void _showRoutineTip() {
    final l10n = AppLocalizations.of(context);
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surfaceDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.dashboardRoutineTipTitle,
              style: const TextStyle(
                color: AppColors.textPrimaryDark,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.dashboardRoutineTipBody,
              style: const TextStyle(
                color: AppColors.textSecondaryDark,
                fontSize: 14,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 20),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.textPrimary,
              ),
              onPressed: () => Navigator.pop(context),
              child: Text(l10n.gotIt),
            ),
          ],
        ),
      ),
    );
  }

  void _maybeRedirectOnboarding() {
    if (_onboardingCheckDone) return;

    // Step 1: Consent — always first.
    final consent = ref.read(hasConsentedProvider);
    if (consent.isLoading) return;
    if (consent.hasError || consent.value != true) {
      _onboardingCheckDone = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        context.go(Routes.consent);
      });
      return;
    }

    // Step 2: Kontaktname.
    if (!_usernameCheckDone) {
      final profileAsync = ref.read(profileProvider);
      if (profileAsync.isLoading) return;
      _usernameCheckDone = true;
      final displayName = profileAsync.valueOrNull?.displayName?.trim();
      if (displayName == null || displayName.isEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) context.go(Routes.usernameSetup);
        });
        return;
      }
    }

    // Package selection is intentionally not an onboarding gate. Users start it
    // explicitly from the dashboard when they are ready.
    _onboardingCheckDone = true;
  }

  bool _isCompletedToday(ProgressEntriesTableData? progress, DateTime now) {
    final lastActivity = progress?.lastActivityDate;
    if (lastActivity == null) return false;
    return lastActivity.year == now.year &&
        lastActivity.month == now.month &&
        lastActivity.day == now.day;
  }

  Future<void> _markTodayComplete({
    required EnrollmentsTableData? enrollment,
    required ProgressEntriesTableData? progress,
  }) async {
    if (enrollment == null || progress == null) return;

    final now = ref.read(appClockProvider).now();
    if (_isCompletedToday(progress, now)) return;

    final activeProfile = ref.read(selectedSubjectProfileProvider);
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (activeProfile == null || userId == null) return;

    final l10n = AppLocalizations.of(context);
    final packageId = ref.read(selectedPackageIdProvider);

    // D12: the picker replaces the old confirmation — one question, not two.
    final companions = await _askForJointTrainingProfiles(
      packageId: packageId,
      confirmLabel: l10n.dashboardLogUnitConfirm,
    );
    if (companions == null || !mounted) return;

    if (companions.isEmpty) {
      // Nobody else could join: keep the plain confirmation.
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(l10n.dashboardLogUnitTitle),
          content: Text(l10n.dashboardLogUnitBody),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(l10n.cancel),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(l10n.dashboardLogUnitConfirm),
            ),
          ],
        ),
      );
      if (confirmed != true || !mounted) return;
    }

    try {
      await logTrainingDayForProfiles(
        db: ref.read(databaseProvider),
        syncService: ref.read(syncServiceProvider),
        userId: userId,
        packageId: packageId,
        subjectProfileIds: [activeProfile.id, ...companions],
        now: now,
      );
      ref.invalidate(streakViewProvider);

      final settings = ref.read(settingsProvider);
      if (settings.remindersEnabled) {
        await NotificationService.instance.suppressTodayAndReschedule(
          startMinutes: settings.reminderStartMinutes,
          title: l10n.reminderSessionTitle,
          body: l10n.reminderSessionBody,
        );
        await syncStreakNotices(ref);
      }

      if (!mounted) return;

      // Show experience prompt (once per day).
      final shouldShow = await ExperiencePromptService.shouldShow();
      if (shouldShow && mounted) {
        await showTrainingExperienceSheet(
          context,
          enrollmentId: enrollment.id,
          packageId: packageId,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.dashboardLogUnitSuccess),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.dashboardLogUnitError('$e')),
          ),
        );
      }
    }
  }

  Future<void> _beginUnit(TrainingSessionMode mode) async {
    ref.read(settingsProvider.notifier).setTrainingMode(mode);
    final packageId = ref.read(selectedPackageIdProvider);
    final companions = await _askForJointTrainingProfiles(
      packageId: packageId,
      confirmLabel: AppLocalizations.of(context).dashboardJointTrainingTogether,
    );
    if (companions == null || !mounted) return;
    context.push(
      Routes.trainingSession,
      extra: TrainingSessionLaunchArgs(
        packageId: packageId,
        companionSubjectProfileIds: companions,
      ),
    );
  }

  /// Returns the chosen companion ids, `const []` when nobody could join, and
  /// `null` when the user backed out of the sheet. Task 12 needs those two
  /// cases kept apart.
  Future<List<String>?> _askForJointTrainingProfiles({
    required String packageId,
    required String confirmLabel,
  }) async {
    final activeProfile = ref.read(selectedSubjectProfileProvider);
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (activeProfile == null || userId == null) return const [];

    // D13: every profile with a running enrollment, the adult one included —
    // the old version bailed out unless the active profile was a child.
    final profiles =
        ref.read(allReflexSubjectProfilesProvider).valueOrNull ?? const [];
    final others =
        profiles.where((profile) => profile.id != activeProfile.id).toList();
    if (others.isEmpty) return const [];

    final db = ref.read(databaseProvider);
    final today = dateOnly(ref.read(appClockProvider).now());
    final candidates = <JointTrainingCandidate>[];

    for (final profile in others) {
      final enrollment = await (db.select(db.enrollmentsTable)
            ..where((t) => t.subjectProfileId.equals(profile.id))
            ..where((t) => t.packageId.equals(packageId))
            ..where((t) => t.status.equals('active'))
            ..limit(1))
          .getSingleOrNull();
      if (enrollment == null) continue;

      final trainedToday = await (db.select(db.trainingSessionsTable)
            ..where((t) => t.subjectProfileId.equals(profile.id))
            ..where((t) => t.isCompleted.equals(true))
            ..where((t) => t.sessionDate.isBiggerOrEqualValue(today))
            ..where((t) => t.sessionDate.isSmallerThanValue(nextDay(today)))
            ..limit(1))
          .getSingleOrNull();
      if (trainedToday != null) continue;

      candidates.add(JointTrainingCandidate(profile: profile));
    }
    if (candidates.isEmpty || !mounted) return const [];

    // D14: start from whoever took part last time.
    final prefs = await SharedPreferences.getInstance();
    final key = 'joint_training_selection_${userId}_$packageId';
    final remembered = prefs.getStringList(key) ?? const <String>[];
    final preselected =
        defaultJointSelection(candidates: candidates, remembered: remembered);

    if (!mounted) return const [];
    final selected = await showJointTrainingSheet(
      context,
      candidates: candidates,
      preselected: preselected.toSet(),
      confirmLabel: confirmLabel,
    );
    if (selected == null) return null;

    await prefs.setStringList(key, selected);
    return selected;
  }

  void _openObservation(String? enrollmentId) {
    if (enrollmentId == null) return;
    showMoodCheckinSheet(
      context,
      enrollmentId: enrollmentId,
      subjectProfileId: ref.read(selectedSubjectProfileProvider)?.id,
      onSaved: () {
        ref.invalidate(moodDailyAggregatesProvider);
        ref.invalidate(moodNotesProvider);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Case 1: providers already resolved before this widget built
    _maybeRedirectOnboarding();

    // Case 2: providers resolve after first build
    ref.listen<AsyncValue<bool>>(hasConsentedProvider, (_, next) {
      if (!next.isLoading) _maybeRedirectOnboarding();
    });
    // Profile load completing after consent triggers the Kontaktname check.
    ref.listen(profileProvider, (_, next) {
      if (!next.isLoading) _maybeRedirectOnboarding();
    });
    ref.listen<AsyncValue<EnrollmentsTableData?>>(activeEnrollmentProvider,
        (_, next) {
      if (!next.isLoading) _maybeRedirectOnboarding();
    });

    final progress = ref.watch(activeProgressProvider).valueOrNull;
    final enrollment = ref.watch(activeEnrollmentProvider).valueOrNull;
    final profilesAsync = ref.watch(allReflexSubjectProfilesProvider);
    final hasProfile =
        profilesAsync.valueOrNull?.isNotEmpty; // null while loading
    final now = ref.watch(appClockProvider).now();
    final completedToday = _isCompletedToday(progress, now);
    final packageId = ref.watch(selectedPackageIdProvider);
    final subjectProfileId = ref.watch(selectedSubjectProfileProvider)?.id;
    final vorrundePhase =
        ref.watch(vorrundePhaseProvider(subjectProfileId)).valueOrNull;
    final vorrundeReadyForMoro = vorrundePhase?.isReadyForMoro(now) ?? false;
    final showVorrundePrimary = enrollment == null &&
        vorrundePhase?.status == VorrundePhaseStatus.started;
    final flowState = ref.watch(trainingFlowProvider(packageId));
    final didVorrundeToday =
        ref.watch(todayVorrundeSessionProvider).valueOrNull ?? false;
    final proposals =
        ref.watch(traineeProposalsProvider).valueOrNull ?? const [];
    final unreadDm = ref.watch(unreadDmCountProvider);

    final currentEmail = Supabase.instance.client.auth.currentUser?.email ?? '';
    // Dev tools are reserved for internal @reflexjourney.de accounts.
    final showDevTools = currentEmail.endsWith('@reflexjourney.de');

    return Scaffold(
      appBar: AppBar(
        title: const _DashboardProfileTitle(),
        actions: [
          const DirectMessagesAction(),
          if (showDevTools)
            TextButton(
              onPressed: () => context.push(Routes.devTools),
              child: const Text(
                'DEV',
                style: TextStyle(
                  color: Colors.deepOrange,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: AppLocalizations.of(context).settings,
            onPressed: () => context.push(Routes.settings),
          ),
        ],
      ),
      body: OnboardingHintGate(
        hint: AppOnboardingHint.dashboard,
        child: SafeArea(
          child: RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(activeProgressProvider);
              ref.invalidate(thisWeekSessionsProvider);
              ref.invalidate(moodDailyAggregatesProvider);
              ref.invalidate(moodNotesProvider);
              ref.invalidate(traineeProposalsProvider);
            },
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              children: [
                const _CompletionQuestionnaireBanner(),
                const _AppointmentProposalBanner(),
                _DailyUnitCard(
                  packageName:
                      _packageName(AppLocalizations.of(context), packageId),
                  currentDay: progress?.currentDay ?? 1,
                  totalDays: ((enrollment?.assignedDurationWeeks ?? 8) * 7)
                      .clamp(1, 3650),
                  movementCount: flowState.totalExercises,
                  estimatedMinutes: _estimatedMinutes(flowState.exercises),
                  now: now,
                  completedToday: completedToday,
                  hasActivePackage: enrollment != null,
                  showVorrundePrimary: showVorrundePrimary,
                  vorrundeReadyForMoro: vorrundeReadyForMoro,
                  didVorrundeToday: didVorrundeToday,
                  hasProfile: hasProfile,
                  onBeginGuided: () => _beginUnit(TrainingSessionMode.tutorial),
                  onBeginRoutine: () => _beginUnit(TrainingSessionMode.routine),
                  onObservation: () => _openObservation(enrollment?.id),
                  onManualComplete:
                      enrollment == null || progress == null || completedToday
                          ? null
                          : () => _markTodayComplete(
                                enrollment: enrollment,
                                progress: progress,
                              ),
                  onStartPackage: () => context.push(
                    Routes.trainingStart,
                    extra: packageId,
                  ),
                  onStartTrainingFlow: () => context.push(
                    Routes.trainingStart,
                    extra: packageId,
                  ),
                  onBeginVorrunde: () => context.push(
                    Routes.trainingSession,
                    extra: 'vorrunde',
                  ),
                  onCreateProfile: () => context.push(Routes.onboardingForWhom),
                ),
                const SizedBox(height: 16),
                _DailyImpulseCard(weekday: now.weekday),
                const SizedBox(height: 16),
                _BegleitungNoticeCard(
                  unreadMessages: unreadDm,
                  proposalCount: proposals.length,
                  onOpen: () => context.push(Routes.accompaniment),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static String _packageName(AppLocalizations l10n, String packageId) {
    switch (packageId) {
      case 'spinal_galant':
        return l10n.packageShortSpinalGalant;
      case 'tlr':
        return l10n.packageShortTlr;
      case 'babkin':
        return l10n.packageShortBabkin;
      case 'such_saug':
        return l10n.packageShortSuchSaug;
      case 'atnr':
        return l10n.packageShortAtnr;
      case 'stnr':
        return l10n.packageShortStnr;
      case 'babinski':
        return l10n.packageShortBabinski;
      case 'landau':
        return l10n.packageShortLandau;
      case 'moro':
      default:
        return l10n.packageShortMoro;
    }
  }

  static int _estimatedMinutes(List<Exercise> exercises) {
    final seconds = exercises.fold<int>(
      0,
      (sum, exercise) => sum + exercise.durationSeconds,
    );
    final transitionSeconds = exercises.length * 25;
    return ((seconds + transitionSeconds) / 60).ceil().clamp(1, 120);
  }
}

class _DailyUnitCard extends StatelessWidget {
  const _DailyUnitCard({
    required this.packageName,
    required this.currentDay,
    required this.totalDays,
    required this.movementCount,
    required this.estimatedMinutes,
    required this.now,
    required this.completedToday,
    required this.hasActivePackage,
    required this.showVorrundePrimary,
    required this.vorrundeReadyForMoro,
    required this.didVorrundeToday,
    required this.hasProfile,
    required this.onBeginGuided,
    required this.onBeginRoutine,
    required this.onObservation,
    required this.onManualComplete,
    required this.onStartPackage,
    required this.onStartTrainingFlow,
    required this.onBeginVorrunde,
    required this.onCreateProfile,
  });

  final String packageName;
  final int currentDay;
  final int totalDays;
  final int movementCount;
  final int estimatedMinutes;
  final DateTime now;
  final bool completedToday;
  final bool hasActivePackage;
  final bool showVorrundePrimary;
  final bool vorrundeReadyForMoro;
  final bool didVorrundeToday;
  final bool? hasProfile;
  final VoidCallback onBeginGuided;
  final VoidCallback onBeginRoutine;
  final VoidCallback onObservation;
  final VoidCallback? onManualComplete;
  final VoidCallback onStartPackage;
  final VoidCallback onStartTrainingFlow;
  final VoidCallback onBeginVorrunde;
  final VoidCallback onCreateProfile;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final progress = (currentDay / totalDays).clamp(0.0, 1.0);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.today,
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        showVorrundePrimary
                            ? l10n.dashboardVorrunde
                            : hasActivePackage
                                ? l10n.dashboardPackageHeadline(packageName)
                                : l10n.dashboardNoActivePackage,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                if (completedToday)
                  _StatusChip(
                    icon: Icons.check_circle_outline,
                    label: l10n.dashboardCompletedToday,
                  ),
              ],
            ),
            const SizedBox(height: 12),
            if (showVorrundePrimary) ...[
              Text(
                vorrundeReadyForMoro
                    ? l10n.dashboardVorrundeReady
                    : l10n.dashboardVorrundeIntro,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 14),
              FilledButton.icon(
                onPressed: vorrundeReadyForMoro
                    ? onStartTrainingFlow
                    : onBeginVorrunde,
                icon: Icon(vorrundeReadyForMoro
                    ? Icons.playlist_add_check_outlined
                    : Icons.play_arrow_rounded),
                label: Text(
                  vorrundeReadyForMoro
                      ? l10n.dashboardStartMoroNow
                      : l10n.dashboardContinueVorrunde,
                ),
              ),
              if (!vorrundeReadyForMoro) ...[
                const SizedBox(height: 10),
                TextButton(
                  onPressed: onStartTrainingFlow,
                  child: Text(l10n.dashboardStartMoroAnyway),
                ),
              ],
            ] else if (hasActivePackage) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 7,
                  backgroundColor: theme.colorScheme.surfaceContainerHighest,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _InfoChip(
                    icon: Icons.calendar_today_outlined,
                    label: l10n.dashboardDayOfTotal(currentDay, totalDays),
                  ),
                  _InfoChip(
                    icon: Icons.self_improvement,
                    label: l10n.dashboardMovementCount(movementCount),
                  ),
                  _InfoChip(
                    icon: Icons.schedule_outlined,
                    label: l10n.dashboardEstimatedMinutes(estimatedMinutes),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Consumer(
                builder: (context, ref, _) {
                  final view = ref.watch(streakViewProvider).valueOrNull;
                  if (view == null) return const SizedBox.shrink();
                  return StreakRow(
                    view: view,
                    today: now,
                    // Re-evaluating clears newlyRescued, because the credit is
                    // already persisted — that is the dismissal.
                    onDismissRescueNotice: () =>
                        ref.invalidate(streakViewProvider),
                  );
                },
              ),
              const SizedBox(height: 12),
              Text(
                l10n.dashboardRegularityNote,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 14),
              if (!completedToday) ...[
                FilledButton.icon(
                  onPressed: onBeginGuided,
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: Text(l10n.dashboardBeginUnit),
                ),
                const SizedBox(height: 10),
              ],
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onObservation,
                      icon: const Icon(Icons.edit_note_outlined),
                      label: Text(l10n.dashboardDocumentExperience),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: completedToday ? null : onManualComplete,
                      icon: Icon(
                        completedToday
                            ? Icons.check_circle
                            : Icons.check_circle_outline,
                      ),
                      label: Text(
                        completedToday
                            ? l10n.dashboardDoneToday
                            : l10n.dashboardLogUnitTitle,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: onBeginRoutine,
                icon: const Icon(Icons.timer_outlined),
                label: Text(l10n.dashboardRoutineModeButton),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: onBeginVorrunde,
                icon: const Icon(Icons.self_improvement_outlined),
                label: Text(l10n.dashboardVorrundeCalm),
              ),
              if (didVorrundeToday) ...[
                const SizedBox(height: 8),
                Text(
                  completedToday
                      ? l10n.dashboardDidBothToday
                      : l10n.dashboardDidVorrundeToday,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ] else if (hasProfile == null) ...[
              const SizedBox(height: 16),
              const LinearProgressIndicator(),
            ] else if (!hasProfile!) ...[
              Text(
                l10n.dashboardCreateFirstProfileHint,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: onCreateProfile,
                icon: const Icon(Icons.person_add_outlined),
                label: Text(l10n.dashboardCreateFirstProfile),
              ),
            ] else ...[
              Text(
                l10n.dashboardStartPackageHint,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: onStartPackage,
                icon: const Icon(Icons.playlist_add_check_outlined),
                label: Text(l10n.dashboardStartPackage),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _DailyImpulseCard extends StatelessWidget {
  const _DailyImpulseCard({required this.weekday});

  final int weekday;

  static List<String> _impulses(AppLocalizations l10n) => [
        l10n.dashboardImpulseRegularity,
        l10n.dashboardImpulseObserve,
        l10n.dashboardImpulseSlowIsEnough,
        l10n.dashboardImpulseNextStep,
        l10n.dashboardImpulsePerceive,
        l10n.dashboardImpulseRhythm,
        l10n.dashboardImpulseShortUnit,
      ];

  @override
  Widget build(BuildContext context) {
    final impulses = _impulses(AppLocalizations.of(context));
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            const Icon(Icons.spa_outlined, color: AppColors.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                impulses[(weekday - 1).clamp(0, impulses.length - 1)],
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BegleitungNoticeCard extends StatelessWidget {
  const _BegleitungNoticeCard({
    required this.unreadMessages,
    required this.proposalCount,
    required this.onOpen,
  });

  final int unreadMessages;
  final int proposalCount;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    if (unreadMessages == 0 && proposalCount == 0) {
      return const SizedBox.shrink();
    }

    final l10n = AppLocalizations.of(context);
    final title = proposalCount > 0
        ? l10n.dashboardProposalsOpen(proposalCount)
        : l10n.dashboardNewMessages(unreadMessages);

    return Material(
      color: AppColors.primary.withValues(alpha: 0.09),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onOpen,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              const Icon(Icons.handshake_outlined, color: AppColors.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: AppColors.primary),
            const SizedBox(width: 5),
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(icon, size: 16),
      label: Text(label),
      visualDensity: VisualDensity.compact,
      side: BorderSide(color: Theme.of(context).dividerColor),
    );
  }
}

class _CompletionQuestionnaireBanner extends ConsumerWidget {
  const _CompletionQuestionnaireBanner();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ready = ref.watch(completionReadyProvider);
    final enrollment = ref.watch(activeEnrollmentProvider).valueOrNull;
    if (!ready || enrollment == null) return const SizedBox.shrink();

    final l10n = AppLocalizations.of(context);
    return Material(
      color: AppColors.primary.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => context.push(
          Routes.completionQuestionnaire,
          extra: enrollment.id,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.emoji_events_outlined,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      l10n.completionBannerTitle,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      l10n.completionBannerSubtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                            height: 1.25,
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right_rounded),
            ],
          ),
        ),
      ),
    );
  }
}

class _AppointmentProposalBanner extends ConsumerWidget {
  const _AppointmentProposalBanner();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final proposalsAsync = ref.watch(traineeProposalsProvider);
    final proposals = proposalsAsync.valueOrNull ?? const [];

    if (proposals.isEmpty) return const SizedBox.shrink();

    final count = proposals.length;
    final trainerName = proposals.first.traineeName;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => context.push(Routes.appointmentProposals),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.event_available_outlined,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        AppLocalizations.of(context)
                            .dashboardProposalBannerTitle(count),
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        AppLocalizations.of(context)
                            .dashboardProposalBannerBody(trainerName),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.chevron_right_rounded),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DashboardProfileTitle extends ConsumerWidget {
  const _DashboardProfileTitle();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profilesAsync = ref.watch(allReflexSubjectProfilesProvider);
    final selected = ref.watch(selectedSubjectProfileProvider);
    final l10n = AppLocalizations.of(context);
    final title = selected?.displayName ?? l10n.today;

    return PopupMenuButton<String>(
      tooltip: l10n.dashboardSwitchProfile,
      enabled: profilesAsync.valueOrNull?.isNotEmpty ?? false,
      onSelected: (value) {
        if (value == '__add_profile') {
          context.push(Routes.onboardingForWhom);
          return;
        }
        ref.read(selectedSubjectProfileIdProvider.notifier).select(value);
      },
      itemBuilder: (context) {
        final profiles = profilesAsync.valueOrNull ?? const [];
        return [
          for (final profile in profiles)
            PopupMenuItem<String>(
              value: profile.id,
              child: Row(
                children: [
                  Icon(
                    selected?.id == profile.id
                        ? Icons.radio_button_checked
                        : Icons.radio_button_unchecked,
                    size: 18,
                    color: selected?.id == profile.id
                        ? AppColors.primary
                        : Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 10),
                  Expanded(child: Text(profile.displayName)),
                  const SizedBox(width: 8),
                  Text(
                    profile.profileType == 'adult_self'
                        ? l10n.profileBadgeSelf
                        : l10n.profileBadgeChild,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
            ),
          const PopupMenuDivider(),
          PopupMenuItem<String>(
            value: '__add_profile',
            child: Row(
              children: [
                const Icon(Icons.add),
                const SizedBox(width: 10),
                Text(l10n.dashboardAddProfile),
              ],
            ),
          ),
        ];
      },
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.asset(
              'assets/images/brand/free.png',
              width: 28,
              height: 28,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 2),
          const Icon(Icons.keyboard_arrow_down_rounded, size: 20),
        ],
      ),
    );
  }
}
