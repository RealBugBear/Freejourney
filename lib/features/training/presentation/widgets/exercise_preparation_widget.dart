import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/models/exercise.dart';

class ExercisePreparationWidget extends StatelessWidget {
  final Exercise exercise;
  final VoidCallback onReady;

  const ExercisePreparationWidget({
    super.key,
    required this.exercise,
    required this.onReady,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).languageCode;
    final movements = exercise.movementInstructions(locale);
    final hints = exercise.hints(locale);

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              _Chip(label: l10n.exerciseMovement, color: AppColors.primary),
              if (hints != null && hints.isNotEmpty) ...[
                const SizedBox(width: 8),
                _Chip(label: l10n.exerciseHints, color: AppColors.moodGold),
              ],
            ],
          ),
          const SizedBox(height: 16),
          Text(
            exercise.title(locale),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ...movements.map((step) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 5),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.circle,
                                size: 7, color: AppColors.primaryLight),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(step,
                                  style: const TextStyle(
                                      color: Colors.white, fontSize: 15)),
                            ),
                          ],
                        ),
                      )),
                  if (hints != null && hints.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    ...hints.map((hint) => Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.moodGold.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                                color:
                                    AppColors.moodGold.withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.lightbulb_outline,
                                  color: AppColors.moodGold, size: 16),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(hint,
                                    style: const TextStyle(
                                        color: Colors.white70, fontSize: 14)),
                              ),
                            ],
                          ),
                        )),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: onReady,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 18),
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.textPrimary,
            ),
            child: Text(l10n.next,
                style:
                    const TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final Color color;
  const _Chip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        border: Border.all(color: color),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }
}
