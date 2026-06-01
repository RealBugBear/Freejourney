import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../bootstrap/providers.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/navigation/app_router.dart';
import '../../../../core/onboarding/onboarding_hint_gate.dart';
import '../../../../core/onboarding/onboarding_hint_provider.dart';
import '../../../../core/training/routine_tip_settings.dart';
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
import '../../../training/presentation/screens/training_session_screen.dart';
import '../../../consent/presentation/providers/consent_provider.dart';
import '../../../assessment/presentation/providers/reflex_profile_provider.dart';
import '../../../profile/presentation/providers/profile_provider.dart';
import '../../../progress/presentation/providers/progress_provider.dart';
import '../../../trainer/presentation/providers/trainer_provider.dart';

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
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkRoutineTip());
  }

  Future<void> _checkRoutineTip() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    if (RoutineTipSettings.shouldShowTip(prefs)) {
      await RoutineTipSettings.markTipShown(prefs);
      if (!mounted) return;
      _showRoutineTip();
    }
  }

  void _showRoutineTip() {
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
            const Text(
              'Du kennst die Übungen jetzt',
              style: TextStyle(
                color: AppColors.textPrimaryDark,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Probiere den Routine-Modus — er führt dich komplett '
              'hands-free per Audio durch das Training.',
              style: TextStyle(
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
              child: const Text('Verstanden'),
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

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Einheit eintragen'),
        content: const Text(
          'Die heutige Einheit wird eingetragen. Danach kannst du direkt nachspüren und eine Beobachtung festhalten.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Abbrechen'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Heute geübt eintragen'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      final db = ref.read(databaseProvider);
      final syncService = ref.read(syncServiceProvider);

      await saveCompletedSession(
        db: db,
        syncService: syncService,
        enrollment: enrollment,
        progress: progress,
        completedExerciseIds: const [],
      );

      final settings = ref.read(settingsProvider);
      if (settings.remindersEnabled) {
        final isDE = settings.languageCode == 'de';
        await NotificationService.instance.suppressTodayAndReschedule(
          startMinutes: settings.reminderStartMinutes,
          titleDe: isDE ? 'Zeit für deine Einheit' : 'Time for your unit',
          bodyDe: isDE
              ? 'Nimm dir Zeit für deine heutige Einheit.'
              : "Take time for today's unit.",
        );
      }

      if (!mounted) return;

      // Show experience prompt (once per day).
      final shouldShow = await ExperiencePromptService.shouldShow();
      if (shouldShow && mounted) {
        final packageId = ref.read(selectedPackageIdProvider);
        await showTrainingExperienceSheet(
          context,
          enrollmentId: enrollment.id,
          packageId: packageId,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Die heutige Einheit wurde eingetragen.'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Die Einheit konnte nicht eingetragen werden: $e'),
          ),
        );
      }
    }
  }

  Future<void> _beginUnit(TrainingSessionMode mode) async {
    ref.read(settingsProvider.notifier).setTrainingMode(mode);
    final packageId = ref.read(selectedPackageIdProvider);
    final companionSubjectProfileIds = await _askForJointTrainingProfiles(
      packageId: packageId,
    );
    if (!mounted) return;
    context.push(
      Routes.trainingSession,
      extra: TrainingSessionLaunchArgs(
        packageId: packageId,
        companionSubjectProfileIds: companionSubjectProfileIds,
      ),
    );
  }

  Future<List<String>> _askForJointTrainingProfiles({
    required String packageId,
  }) async {
    final activeProfile = ref.read(selectedSubjectProfileProvider);
    if (activeProfile == null || activeProfile.profileType != 'child') {
      return const [];
    }

    final profiles =
        ref.read(allReflexSubjectProfilesProvider).valueOrNull ?? const [];
    final childProfiles = profiles
        .where((profile) =>
            profile.profileType == 'child' && profile.id != activeProfile.id)
        .toList();
    if (childProfiles.isEmpty) return const [];

    final db = ref.read(databaseProvider);
    final candidates = <_JointTrainingCandidate>[];
    for (final profile in childProfiles) {
      final enrollment = await (db.select(db.enrollmentsTable)
            ..where((t) => t.subjectProfileId.equals(profile.id))
            ..where((t) => t.packageId.equals(packageId))
            ..where((t) => t.status.equals('active'))
            ..limit(1))
          .getSingleOrNull();
      if (enrollment == null) continue;

      final progress = await (db.select(db.progressEntriesTable)
            ..where((t) => t.enrollmentId.equals(enrollment.id))
            ..limit(1))
          .getSingleOrNull();
      if (progress == null || _isCompletedToday(progress, DateTime.now())) {
        continue;
      }
      candidates.add(_JointTrainingCandidate(profile: profile));
    }

    if (candidates.isEmpty || !mounted) return const [];
    return await _showJointTrainingDialog(candidates) ?? const [];
  }

  Future<List<String>?> _showJointTrainingDialog(
    List<_JointTrainingCandidate> candidates,
  ) async {
    var selectedIds = candidates.map((c) => c.profile.id).toSet();

    return showDialog<List<String>>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return AlertDialog(
            title: const Text('Zusammen trainieren?'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Diese Kinder haben dasselbe aktive Paket. Soll die Einheit nach dem Training auch für sie eingetragen werden?',
                ),
                const SizedBox(height: 12),
                for (final candidate in candidates)
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    value: selectedIds.contains(candidate.profile.id),
                    title: Text(candidate.profile.displayName),
                    controlAffinity: ListTileControlAffinity.leading,
                    onChanged: (value) {
                      setDialogState(() {
                        if (value == true) {
                          selectedIds.add(candidate.profile.id);
                        } else {
                          selectedIds.remove(candidate.profile.id);
                        }
                      });
                    },
                  ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, const <String>[]),
                child: const Text('Nur dieses Profil'),
              ),
              FilledButton(
                onPressed: selectedIds.isEmpty
                    ? null
                    : () => Navigator.pop(ctx, selectedIds.toList()),
                child: const Text('Gemeinsam eintragen'),
              ),
            ],
          );
        },
      ),
    );
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
    ref.listen<AsyncValue<bool>>(hasSeenAnalysisPlaceholderProvider, (_, next) {
      if (!next.isLoading) _maybeRedirectOnboarding();
    });
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
    final sessionsThisWeek = ref.watch(thisWeekSessionsProvider).valueOrNull ??
        const <TrainingSessionsTableData>[];
    final didVorrundeToday =
        ref.watch(todayVorrundeSessionProvider).valueOrNull ?? false;
    final proposals =
        ref.watch(traineeProposalsProvider).valueOrNull ?? const [];
    final unreadDm = ref.watch(unreadDmCountProvider);

    final currentEmail = Supabase.instance.client.auth.currentUser?.email ?? '';
    // Dev tools are reserved for internal @corejourney.dev accounts.
    final showDevTools = currentEmail.endsWith('@corejourney.dev');

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
            tooltip: 'Einstellungen',
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
                  packageName: _packageName(packageId),
                  currentDay: progress?.currentDay ?? 1,
                  totalDays: ((enrollment?.assignedDurationWeeks ?? 8) * 7)
                      .clamp(1, 3650),
                  movementCount: flowState.totalExercises,
                  estimatedMinutes: _estimatedMinutes(flowState.exercises),
                  now: now,
                  sessionsThisWeek: sessionsThisWeek,
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

  static String _packageName(String packageId) {
    switch (packageId) {
      case 'spinal_galant':
        return 'Spinaler Galant';
      case 'tlr':
        return 'TLR';
      case 'babkin':
        return 'Babkin';
      case 'such_saug':
        return 'Such-Saug';
      case 'atnr':
        return 'ATNR';
      case 'stnr':
        return 'STNR';
      case 'babinski':
        return 'Babinski';
      case 'landau':
        return 'Landau';
      case 'moro':
      default:
        return 'Moro';
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

class _JointTrainingCandidate {
  const _JointTrainingCandidate({required this.profile});

  final ReflexSubjectProfile profile;
}

class _DailyUnitCard extends StatelessWidget {
  const _DailyUnitCard({
    required this.packageName,
    required this.currentDay,
    required this.totalDays,
    required this.movementCount,
    required this.estimatedMinutes,
    required this.now,
    required this.sessionsThisWeek,
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
  final List<TrainingSessionsTableData> sessionsThisWeek;
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
                        'Heute',
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        showVorrundePrimary
                            ? 'Vorrunde'
                            : hasActivePackage
                                ? '$packageName Paket'
                                : 'Noch kein aktives Paket',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                if (completedToday)
                  const _StatusChip(
                    icon: Icons.check_circle_outline,
                    label: 'Heute abgeschlossen',
                  ),
              ],
            ),
            const SizedBox(height: 12),
            if (showVorrundePrimary) ...[
              Text(
                vorrundeReadyForMoro
                    ? 'Die vier Wochen Vorrunde sind erreicht. Du kannst jetzt Moro starten.'
                    : 'Die Vorrunde bereitet dich rhythmisch auf Moro vor. Du kannst sie fortsetzen oder jederzeit mit Moro starten.',
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
                      ? 'Jetzt Moro starten'
                      : 'Vorrunde fortsetzen',
                ),
              ),
              if (!vorrundeReadyForMoro) ...[
                const SizedBox(height: 10),
                TextButton(
                  onPressed: onStartTrainingFlow,
                  child: const Text('Trotzdem Moro starten'),
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
                    label: 'Tag $currentDay von $totalDays',
                  ),
                  _InfoChip(
                    icon: Icons.self_improvement,
                    label: '$movementCount Bewegungen',
                  ),
                  _InfoChip(
                    icon: Icons.schedule_outlined,
                    label: 'ca. $estimatedMinutes Min.',
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _WeeklyRegularityStrip(
                now: now,
                sessions: sessionsThisWeek,
              ),
              const SizedBox(height: 12),
              Text(
                'Die Bewegungen bleiben bewusst gleich. Regelmäßigkeit ist wichtiger als Intensität.',
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
                  label: const Text('Einheit beginnen'),
                ),
                const SizedBox(height: 10),
              ],
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onObservation,
                      icon: const Icon(Icons.edit_note_outlined),
                      label: const Text('Erfahrung dokumentieren'),
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
                        completedToday ? 'Heute erledigt' : 'Einheit eintragen',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: onBeginRoutine,
                icon: const Icon(Icons.timer_outlined),
                label: const Text('Routine-Modus'),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: onBeginVorrunde,
                icon: const Icon(Icons.self_improvement_outlined),
                label: const Text('Vorrunde zur Beruhigung'),
              ),
              if (didVorrundeToday) ...[
                const SizedBox(height: 8),
                Text(
                  completedToday
                      ? 'Heute Pakettraining und Vorrunde gemacht'
                      : 'Heute Vorrunde gemacht',
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
                'Leg dein erstes Reflexprofil an, um loszulegen.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: onCreateProfile,
                icon: const Icon(Icons.person_add_outlined),
                label: const Text('Erstes Profil anlegen'),
              ),
            ] else ...[
              Text(
                'Du hast ein Profil angelegt. Starte jetzt ein Paket, um deinen Rhythmus aufzubauen.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: onStartPackage,
                icon: const Icon(Icons.playlist_add_check_outlined),
                label: const Text('Paket starten'),
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

  static const _impulses = [
    'Heute zählt nicht Perfektion, sondern Regelmäßigkeit.',
    'Beobachte, ohne zu bewerten.',
    'Langsam und regelmäßig ist genug.',
    'Hier ist dein nächster ruhiger Schritt.',
    'Nimm wahr, was heute da ist.',
    'Ruhiger Rhythmus gibt dem Körper Orientierung.',
    'Eine kurze Einheit ist besser als Druck.',
  ];

  @override
  Widget build(BuildContext context) {
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
                _impulses[(weekday - 1).clamp(0, _impulses.length - 1)],
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WeeklyRegularityStrip extends StatelessWidget {
  const _WeeklyRegularityStrip({required this.now, required this.sessions});

  final DateTime now;
  final List<TrainingSessionsTableData> sessions;

  @override
  Widget build(BuildContext context) {
    final weekStart = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: now.weekday - 1));
    final completedWeekdays = {
      for (final session in sessions) session.sessionDate.weekday,
    };

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Diese Woche',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const Spacer(),
                Text(
                  '${completedWeekdays.length}/7 geübt',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: List.generate(7, (index) {
                final day = weekStart.add(Duration(days: index));
                final complete = completedWeekdays.contains(day.weekday);
                final isToday = day.year == now.year &&
                    day.month == now.month &&
                    day.day == now.day;
                return Expanded(
                  child: Column(
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        width: 18,
                        height: 18,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: complete
                              ? AppColors.primary
                              : Theme.of(context)
                                  .colorScheme
                                  .surfaceContainerHighest,
                          border: Border.all(
                            color: isToday
                                ? AppColors.primary
                                : Theme.of(context).dividerColor,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _weekdayLabel(index),
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                    ],
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  static String _weekdayLabel(int index) {
    const labels = ['Mo', 'Di', 'Mi', 'Do', 'Fr', 'Sa', 'So'];
    return labels[index];
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

    final title = proposalCount > 0
        ? '$proposalCount Terminvorschlag${proposalCount == 1 ? '' : 'e'} offen'
        : '$unreadMessages neue Nachricht${unreadMessages == 1 ? '' : 'en'}';

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
                        count == 1
                            ? 'Neuer Terminvorschlag'
                            : '$count neue Terminvorschläge',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$trainerName hat dir Termine vorgeschlagen.',
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
    final title = selected?.displayName ?? 'Heute';

    return PopupMenuButton<String>(
      tooltip: 'Profil wechseln',
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
                    profile.profileType == 'adult_self' ? 'Ich' : 'Kind',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
            ),
          const PopupMenuDivider(),
          const PopupMenuItem<String>(
            value: '__add_profile',
            child: Row(
              children: [
                Icon(Icons.add),
                SizedBox(width: 10),
                Text('Profil hinzufügen'),
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
