import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../config/launch_flags.dart';
import '../../../../core/navigation/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../assessment/presentation/providers/reflex_profile_provider.dart';
import '../../../premium/domain/entitlement.dart';
import '../../../premium/presentation/providers/premium_provider.dart';
import '../../../progress/presentation/providers/progress_provider.dart';
import '../../../trainer/presentation/providers/trainer_provider.dart';
import '../../domain/services/vorrunde_phase_service.dart';

class TrainingStartFlowScreen extends ConsumerStatefulWidget {
  const TrainingStartFlowScreen({super.key});

  @override
  ConsumerState<TrainingStartFlowScreen> createState() =>
      _TrainingStartFlowScreenState();
}

class _TrainingStartFlowScreenState
    extends ConsumerState<TrainingStartFlowScreen> {
  bool? _hadIsometricWithTrainer;
  bool _reflexProfileSkipped = false;
  bool _showTrainerWaitingOption = false;

  @override
  void initState() {
    super.initState();
    // T23: defensiver Entitlement-Guard — verhindert bei aktiver Paywall
    // den direkten Einstieg in ein gesperrtes Paket (Deep Link, alter
    // Navigations-Rest). Mit kPaywallEnabled=false vollständig inert.
    WidgetsBinding.instance.addPostFrameCallback((_) => _guardEntitlement());
  }

  void _guardEntitlement() {
    if (!kPaywallEnabled || !mounted) return;
    final entitlement =
        ref.read(entitlementProvider).valueOrNull ?? Entitlement.none;
    final unlocked = isPackageUnlocked(
      _packageId,
      entitlement: entitlement,
      now: DateTime.now(),
    );
    if (!unlocked) context.go(Routes.paywall);
  }

  String get _packageId {
    final extra = GoRouterState.of(context).extra;
    if (extra is Map<String, dynamic>) {
      return extra['packageId'] as String? ?? 'moro';
    }
    return extra as String? ?? ref.read(selectedPackageIdProvider);
  }

  Future<void> _startVorrunde() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;
    final subjectProfileId = ref.read(selectedSubjectProfileProvider)?.id;
    await ref.read(vorrundePhaseRepositoryProvider).start(
          userId: userId,
          subjectProfileId: subjectProfileId,
        );
    ref.invalidate(vorrundePhaseProvider(subjectProfileId));
    if (!mounted) return;
    context.push(Routes.trainingSession, extra: 'vorrunde');
  }

  Future<void> _skipVorrunde() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;
    final subjectProfileId = ref.read(selectedSubjectProfileProvider)?.id;
    await ref.read(vorrundePhaseRepositoryProvider).skip(
          userId: userId,
          subjectProfileId: subjectProfileId,
        );
    ref.invalidate(vorrundePhaseProvider(subjectProfileId));
  }

  Future<void> _confirmReflexSkip() async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.trainingProfileSkipTitle),
        content: Text(l10n.trainingProfileSkipBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.back),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.trainingContinue),
          ),
        ],
      ),
    );
    if (confirmed == true) setState(() => _reflexProfileSkipped = true);
  }

  void _continueAfterIsometric() {
    final hadTrainer = _hadIsometricWithTrainer;
    if (hadTrainer == null) return;

    final extra = {
      'packageId': _packageId,
      'hadIsometricWithTrainer': hadTrainer,
      if (_reflexProfileSkipped) 'reflexProfileStatus': 'skipped',
    };
    if (hadTrainer) {
      context.push(Routes.durationRecommendation, extra: extra);
    } else {
      context.push(Routes.trainerOnboardingPrompt, extra: extra);
    }
  }

  bool _hasMoroEnrollment() {
    final enrollments = ref.watch(allUserEnrollmentsProvider).valueOrNull ?? [];
    final subjectProfileId = ref.watch(selectedSubjectProfileProvider)?.id;
    return enrollments.any((enrollment) {
      if (enrollment.packageId != 'moro') return false;
      if (enrollment.status != 'active' && enrollment.status != 'completed') {
        return false;
      }
      return subjectProfileId == null ||
          enrollment.subjectProfileId == null ||
          enrollment.subjectProfileId == subjectProfileId;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final profile = ref.watch(selectedSubjectProfileProvider);
    final assessment =
        ref.watch(latestReflexProfileForSelectedSubjectProvider).valueOrNull;
    final phase = ref.watch(selectedVorrundePhaseProvider).valueOrNull;
    final connections =
        ref.watch(clientTrainerConnectionsProvider).valueOrNull ?? const [];
    final activeTrainer = connections.where((c) => c.isActive).firstOrNull;
    final pendingTrainer = connections.where((c) => c.isPending).firstOrNull;
    final canShowVorrunde = _packageId == 'moro' &&
        !_hasMoroEnrollment() &&
        (phase == null || phase.status == VorrundePhaseStatus.started);
    final shouldDecideVorrunde =
        canShowVorrunde && phase == null && !_reflexProfileSkipped;
    final readyForMoro = phase?.isReadyForMoro(DateTime.now()) ?? false;

    Widget body;
    if (shouldDecideVorrunde) {
      body = _VorrundeDecisionCard(
        onStart: _startVorrunde,
        onContinue: () async {
          await _skipVorrunde();
          if (mounted) setState(() {});
        },
      );
    } else if (assessment == null && !_reflexProfileSkipped) {
      body = _ReflexProfileStep(
        profileName: profile?.displayName ?? l10n.trainingActiveProfile,
        packageId: _packageId,
        onSkip: _confirmReflexSkip,
      );
    } else {
      body = _IsometricStep(
        profileName: profile?.displayName ?? l10n.trainingActiveProfile,
        packageId: _packageId,
        phase: phase,
        readyForMoro: readyForMoro,
        activeTrainerName: activeTrainer?.displayName,
        pendingTrainerName: pendingTrainer?.displayName,
        showTrainerWaitingOption: _showTrainerWaitingOption,
        hadIsometricWithTrainer: _hadIsometricWithTrainer,
        onSelect: (value) => setState(() => _hadIsometricWithTrainer = value),
        onFindTrainer: () async {
          setState(() => _showTrainerWaitingOption = true);
          await context.push(Routes.trainerDiscovery);
          ref.invalidate(clientTrainerConnectionsProvider);
        },
        onStartVorrunde: _startVorrunde,
        onContinue: _continueAfterIsometric,
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(l10n.trainingStartPackage)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          children: [
            _ProfileHeader(
              profileName: profile?.displayName ?? l10n.trainingActiveProfile,
            ),
            const SizedBox(height: 16),
            body,
          ],
        ),
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.profileName});

  final String profileName;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            const Icon(Icons.account_circle_outlined, color: AppColors.primary),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                l10n.trainingStartForProfile(profileName),
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VorrundeDecisionCard extends StatelessWidget {
  const _VorrundeDecisionCard({
    required this.onStart,
    required this.onContinue,
  });

  final VoidCallback onStart;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return _StepCard(
      icon: Icons.self_improvement_outlined,
      title: l10n.trainingWarmupBeforeMoroTitle,
      body: l10n.trainingWarmupBeforeMoroBody,
      children: [
        FilledButton.icon(
          onPressed: onStart,
          icon: const Icon(Icons.play_arrow_rounded),
          label: Text(l10n.trainingStartWarmup),
        ),
        const SizedBox(height: 10),
        TextButton(
          onPressed: onContinue,
          child: Text(l10n.trainingContinueWithPackage),
        ),
      ],
    );
  }
}

class _ReflexProfileStep extends StatelessWidget {
  const _ReflexProfileStep({
    required this.profileName,
    required this.packageId,
    required this.onSkip,
  });

  final String profileName;
  final String packageId;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return _StepCard(
      icon: Icons.analytics_outlined,
      title: l10n.trainingUseReflexProfile,
      body: l10n.trainingReflexProfileMissingBody(profileName),
      children: [
        FilledButton.icon(
          onPressed: () => context.push(Routes.reflexProfile, extra: packageId),
          icon: const Icon(Icons.fact_check_outlined),
          label: Text(l10n.trainingStartReflexProfile),
        ),
        const SizedBox(height: 10),
        TextButton(
          onPressed: onSkip,
          child: Text(l10n.trainingSkipDeliberately),
        ),
      ],
    );
  }
}

class _IsometricStep extends StatelessWidget {
  const _IsometricStep({
    required this.profileName,
    required this.packageId,
    required this.phase,
    required this.readyForMoro,
    required this.activeTrainerName,
    required this.pendingTrainerName,
    required this.showTrainerWaitingOption,
    required this.hadIsometricWithTrainer,
    required this.onSelect,
    required this.onFindTrainer,
    required this.onStartVorrunde,
    required this.onContinue,
  });

  final String profileName;
  final String packageId;
  final VorrundePhase? phase;
  final bool readyForMoro;
  final String? activeTrainerName;
  final String? pendingTrainerName;
  final bool showTrainerWaitingOption;
  final bool? hadIsometricWithTrainer;
  final ValueChanged<bool> onSelect;
  final VoidCallback onFindTrainer;
  final VoidCallback onStartVorrunde;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final phaseStarted = phase?.status == VorrundePhaseStatus.started;
    return _StepCard(
      icon: Icons.groups_2_outlined,
      title: l10n.trainingIsometricPartnerTitle,
      body: l10n.trainingIsometricPartnerQuestion(profileName),
      children: [
        if (phaseStarted && !readyForMoro) ...[
          _InlineInfo(text: l10n.trainingWarmupStillRunning),
          const SizedBox(height: 12),
        ],
        if (phaseStarted && readyForMoro) ...[
          _InlineInfo(text: l10n.trainingWarmupReady),
          const SizedBox(height: 12),
        ],
        _ChoiceButton(
          label: l10n.yes,
          selected: hadIsometricWithTrainer == true,
          onTap: () => onSelect(true),
        ),
        const SizedBox(height: 10),
        _ChoiceButton(
          label: l10n.no,
          selected: hadIsometricWithTrainer == false,
          onTap: () => onSelect(false),
        ),
        if (hadIsometricWithTrainer == false) ...[
          const SizedBox(height: 14),
          if (activeTrainerName != null)
            _InlineInfo(
              text: l10n.trainingConnectedWithoutIsometric(activeTrainerName!),
            )
          else if (pendingTrainerName != null)
            _InlineInfo(
              text: l10n.trainingTrainerRequestPending(pendingTrainerName!),
            )
          else
            OutlinedButton.icon(
              onPressed: onFindTrainer,
              icon: const Icon(Icons.travel_explore_outlined),
              label: Text(l10n.trainingFindTrainer),
            ),
          if (showTrainerWaitingOption || pendingTrainerName != null) ...[
            const SizedBox(height: 10),
            _InlineInfo(text: l10n.trainingWarmupWhileWaitingBody),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: onStartVorrunde,
              icon: const Icon(Icons.self_improvement_outlined),
              label: Text(l10n.trainingUseWarmup),
            ),
          ],
        ],
        const SizedBox(height: 20),
        FilledButton(
          onPressed: hadIsometricWithTrainer == null ? null : onContinue,
          child: Text(l10n.trainerOnboardingContinueAfterRequest),
        ),
      ],
    );
  }
}

class _StepCard extends StatelessWidget {
  const _StepCard({
    required this.icon,
    required this.title,
    required this.body,
    required this.children,
  });

  final IconData icon;
  final String title;
  final String body;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(icon, color: AppColors.primary, size: 34),
            const SizedBox(height: 12),
            Text(
              title,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              body,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: cs.onSurfaceVariant,
                    height: 1.45,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 22),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _ChoiceButton extends StatelessWidget {
  const _ChoiceButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        backgroundColor:
            selected ? AppColors.primary.withValues(alpha: 0.08) : null,
        side: BorderSide(
          color: selected ? AppColors.primary : AppColors.divider,
          width: selected ? 2 : 1,
        ),
        padding: const EdgeInsets.symmetric(vertical: 15),
      ),
      child: Text(label),
    );
  }
}

class _InlineInfo extends StatelessWidget {
  const _InlineInfo({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Text(
          text,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(height: 1.35),
        ),
      ),
    );
  }
}
