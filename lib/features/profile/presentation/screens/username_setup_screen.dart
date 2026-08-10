import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/launch_flags.dart';
import '../../../../core/navigation/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../assessment/presentation/providers/reflex_profile_provider.dart';
import '../../../onboarding/presentation/widgets/pre_payoff_step_dots.dart';
import '../providers/profile_provider.dart';

class UsernameSetupScreen extends ConsumerStatefulWidget {
  const UsernameSetupScreen({super.key});

  @override
  ConsumerState<UsernameSetupScreen> createState() =>
      _UsernameSetupScreenState();
}

class _UsernameSetupScreenState extends ConsumerState<UsernameSetupScreen> {
  final _controller = TextEditingController();
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String? _validate(String value) {
    final l10n = AppLocalizations.of(context);
    final trimmed = value.trim();
    if (trimmed.isEmpty) return l10n.profileContactNameRequired;
    if (trimmed.length < 2) return l10n.profileMinimumCharacters(2);
    if (trimmed.length > 50) return l10n.profileMaximumCharacters(50);
    if (trimmed.contains('@')) return l10n.profileAtNotAllowed;
    return null;
  }

  Future<void> _save() async {
    final trimmed = _controller.text.trim();
    final validationError = _validate(trimmed);
    if (validationError != null) {
      setState(() => _error = validationError);
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ref.read(profileProvider.notifier).save(displayName: trimmed);
      if (!mounted) return;

      // No subject profiles yet → Für-wen, then Reflex Profile (payoff).
      // Entry-points stay optional / post-payoff (non-blocking).
      final profiles = await ref.read(allReflexSubjectProfilesProvider.future);
      if (!mounted) return;
      if (profiles.isEmpty) {
        context.go(Routes.onboardingForWhom);
      } else {
        context.go(Routes.dashboard);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _error = AppLocalizations.of(context).errorSaveFailed);
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go(Routes.consent),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const PrePayoffStepDots(currentStep: 3),
              const SizedBox(height: 28),
              const Spacer(),
              Text(
                l10n.profileContactNameQuestion,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 10),
              Text(
                kCommunityEnabled
                    ? l10n.profileContactNameDiscoverBodyWithCommunity
                    : l10n.profileContactNameDiscoverBody,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 28),
              TextField(
                controller: _controller,
                autofocus: true,
                textCapitalization: TextCapitalization.words,
                onChanged: (_) => setState(() => _error = null),
                onSubmitted: (_) => _save(),
                decoration: InputDecoration(
                  hintText: l10n.profileContactNameHint,
                  errorText: _error,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.textPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _saving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : Text(
                          l10n.continueAction,
                          style: const TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 16),
                        ),
                ),
              ),
              const Spacer(flex: 2),
            ],
          ),
        ),
      ),
    );
  }
}
