import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../bootstrap/providers.dart';
import '../../../../core/navigation/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/error_retry_widget.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../progress/presentation/providers/progress_provider.dart';

enum _ScreenState { question, celebrating, extended }

class CompletionQuestionnaireScreen extends ConsumerStatefulWidget {
  final String enrollmentId;
  const CompletionQuestionnaireScreen({super.key, required this.enrollmentId});

  @override
  ConsumerState<CompletionQuestionnaireScreen> createState() =>
      _CompletionQuestionnaireScreenState();
}

class _CompletionQuestionnaireScreenState
    extends ConsumerState<CompletionQuestionnaireScreen> {
  _ScreenState _state = _ScreenState.question;
  bool _saving = false;
  String? _nextPackageId;
  String? _resumedPackageId;
  bool _wasMoroReactivation = false;

  Future<void> _onYes() async {
    setState(() => _saving = true);
    try {
      final enrollment = ref.read(activeEnrollmentProvider).valueOrNull;
      if (enrollment == null) return;

      final result = await completeEnrollment(
        db: ref.read(databaseProvider),
        syncService: ref.read(syncServiceProvider),
        enrollment: enrollment,
      );

      setState(() {
        _nextPackageId = result.nextPackageId;
        _resumedPackageId = result.resumedPackageId;
        _wasMoroReactivation = result.wasMoroReactivation;
        _state = _ScreenState.celebrating;
      });
    } catch (_) {
      if (mounted) {
        showErrorSnackBar(
            context, AppLocalizations.of(context).errorSaveFailed);
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _onNotYet() async {
    setState(() => _saving = true);
    try {
      final enrollment = ref.read(activeEnrollmentProvider).valueOrNull;
      if (enrollment == null) return;

      await extendEnrollment(
        db: ref.read(databaseProvider),
        syncService: ref.read(syncServiceProvider),
        enrollment: enrollment,
      );

      setState(() => _state = _ScreenState.extended);
    } catch (_) {
      if (mounted) {
        showErrorSnackBar(
            context, AppLocalizations.of(context).errorSaveFailed);
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _continueAfterCelebration() {
    if (_wasMoroReactivation) {
      final resumed = _resumedPackageId;
      if (resumed != null) {
        ref.read(selectedPackageIdProvider.notifier).select(resumed);
      }
      context.go(Routes.dashboard);
      return;
    }

    final next = _nextPackageId;
    if (next == null) {
      // Last package — back to dashboard
      context.go(Routes.dashboard);
      return;
    }

    // Update selected package and either start intake or show packages screen
    ref.read(selectedPackageIdProvider.notifier).select(next);

    if (freePackageIds.contains(next)) {
      // Free — go straight to intake for next package
      context.go(Routes.trainingStart, extra: next);
    } else {
      // Paid — go to packages screen (paywall coming later)
      context.go(Routes.packages);
    }
  }

  @override
  Widget build(BuildContext context) {
    return switch (_state) {
      _ScreenState.question => _buildQuestion(context),
      _ScreenState.celebrating => _buildCelebration(context),
      _ScreenState.extended => _buildExtended(context),
    };
  }

  Widget _buildQuestion(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.completionQuestionnaireTitle)),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 16),
              Text(
                l10n.completionPlaceholderQuestion,
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(height: 1.6),
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: _saving ? null : _onYes,
                child: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : Text(l10n.completionPass),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: _saving ? null : _onNotYet,
                child: Text(l10n.completionInsufficient),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCelebration(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final hasNext = _nextPackageId != null || _wasMoroReactivation;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                '⭐',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 80),
              ),
              const SizedBox(height: 32),
              Text(
                l10n.completionCelebrationTitle,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                _wasMoroReactivation
                    ? l10n.completionMoroReturnSubtitle
                    : l10n.completionCelebrationSubtitle,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      height: 1.5,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              ElevatedButton(
                onPressed: _continueAfterCelebration,
                child: Text(
                  hasNext
                      ? (_wasMoroReactivation
                          ? l10n.completionBackToInterruptedPackage
                          : l10n.completionNextPackage)
                      : l10n.completionBackToDashboard,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExtended(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                '💪',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 80),
              ),
              const SizedBox(height: 32),
              Text(
                l10n.completionExtendedTitle,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                l10n.completionExtendedSubtitle,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      height: 1.5,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              ElevatedButton(
                onPressed: () => context.go(Routes.dashboard),
                child: Text(l10n.completionBackToDashboard),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
