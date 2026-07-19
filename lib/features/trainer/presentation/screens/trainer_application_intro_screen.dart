import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/navigation/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/app_localizations.dart';

class TrainerApplicationIntroScreen extends StatelessWidget {
  const TrainerApplicationIntroScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.trainerBecomeTitle)),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Icon(
            Icons.verified_user_outlined,
            size: 64,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 20),
          Text(
            l10n.trainerBecomeHeadline,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 12),
          Text(l10n.trainerBecomeBody),
          const SizedBox(height: 20),
          _RequirementTile(
            icon: Icons.work_outline,
            title: l10n.trainerBecomeBackgroundTitle,
            body: l10n.trainerBecomeBackgroundBody,
          ),
          _RequirementTile(
            icon: Icons.admin_panel_settings_outlined,
            title: l10n.trainerBecomeBgCheckTitle,
            body: l10n.trainerBecomeBgCheckBody,
          ),
          _RequirementTile(
            icon: Icons.chat_bubble_outline,
            title: l10n.trainerBecomeReviewTitle,
            body: l10n.trainerBecomeReviewBody,
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.warning.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(l10n.trainerBecomeImportant),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () => context.push(Routes.trainerApplicationForm),
            icon: const Icon(Icons.arrow_forward),
            label: Text(l10n.trainerApplicationStart),
          ),
        ],
      ),
    );
  }
}

class _RequirementTile extends StatelessWidget {
  const _RequirementTile({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 4),
                Text(body, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
