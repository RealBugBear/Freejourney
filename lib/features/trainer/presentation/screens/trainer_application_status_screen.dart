import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/navigation/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/models/trainer_application.dart';
import '../providers/trainer_application_provider.dart';
import '../providers/trainer_provider.dart'
    show activateTrainerRole, userRoleProvider;

class TrainerApplicationStatusScreen extends ConsumerWidget {
  const TrainerApplicationStatusScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final applicationAsync = ref.watch(ownTrainerApplicationProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.trainerApplicationTitle)),
      body: applicationAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => _ErrorState(
          message: e.toString(),
          onRetry: () => ref.invalidate(ownTrainerApplicationProvider),
        ),
        data: (application) {
          if (application == null) {
            return _NoApplicationState(
              onStart: () => context.go(Routes.trainerApplicationIntro),
            );
          }

          return RefreshIndicator(
            onRefresh: () async =>
                ref.invalidate(ownTrainerApplicationProvider),
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Text(
                  application.statusLabel(l10n),
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  _statusBody(l10n, application.status),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 20),
                _CheckRow(
                  checked: true,
                  title: l10n.trainerApplicationSubmittedStep,
                ),
                _CheckRow(
                  checked: application.hasBackgroundCheck,
                  title: l10n.trainerApplicationBgCheckStep,
                ),
                _CheckRow(
                  checked: application.activationCode != null,
                  title: l10n.trainerApplicationCodeStep,
                ),
                if (application.reviewChannelId != null) ...[
                  const SizedBox(height: 20),
                  OutlinedButton.icon(
                    onPressed: () => context.push(
                      Routes.dmChannel.replaceFirst(
                        ':channelId',
                        application.reviewChannelId!,
                      ),
                    ),
                    icon: const Icon(Icons.chat_bubble_outline),
                    label: Text(l10n.trainerApplicationOpenReview),
                  ),
                ],
                if (application.activationCode != null) ...[
                  const SizedBox(height: 20),
                  FilledButton.icon(
                    onPressed: () async {
                      final err = await activateTrainerRole(
                          application.activationCode!);
                      if (err != null) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(err)),
                          );
                        }
                        return;
                      }
                      ref.invalidate(userRoleProvider);
                      ref.invalidate(ownTrainerApplicationProvider);
                      if (context.mounted) {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (context.mounted) {
                            context.go(Routes.trainerDashboard);
                          }
                        });
                      }
                    },
                    icon: const Icon(Icons.verified_outlined),
                    label: Text(l10n.trainerApplicationActivate),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  String _statusBody(
    AppLocalizations l10n,
    TrainerApplicationStatus status,
  ) {
    return switch (status) {
      TrainerApplicationStatus.approved => l10n.trainerApplicationApprovedBody,
      TrainerApplicationStatus.rejected => l10n.trainerApplicationRejectedBody,
      TrainerApplicationStatus.needsMoreInfo =>
        l10n.trainerApplicationNeedsInfoBody,
      _ => l10n.trainerApplicationInReviewBody,
    };
  }
}

class _CheckRow extends StatelessWidget {
  const _CheckRow({required this.checked, required this.title});
  final bool checked;
  final String title;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        checked ? Icons.check_circle : Icons.radio_button_unchecked,
        color: checked
            ? AppColors.success
            : Theme.of(context).colorScheme.onSurfaceVariant,
      ),
      title: Text(title),
    );
  }
}

class _NoApplicationState extends StatelessWidget {
  const _NoApplicationState({required this.onStart});
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.assignment_outlined, size: 56),
            const SizedBox(height: 12),
            Text(l10n.trainerApplicationNoneTitle),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: onStart,
              child: Text(l10n.trainerApplicationStart),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            TextButton(onPressed: onRetry, child: Text(l10n.retry)),
          ],
        ),
      ),
    );
  }
}
