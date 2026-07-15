import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/models/exercise.dart';
import '../../domain/models/training_session.dart';
import 'exercise_image_widget.dart';

class TrainingIntroWidget extends StatelessWidget {
  final Exercise exercise;
  final int exerciseIndex;
  final int totalExercises;
  final TrainingSessionMode mode;
  final bool isDuo;
  final VoidCallback onStart;
  final ValueChanged<TrainingSessionMode> onModeChanged;

  const TrainingIntroWidget({
    super.key,
    required this.exercise,
    required this.exerciseIndex,
    required this.totalExercises,
    required this.mode,
    this.isDuo = false,
    required this.onStart,
    required this.onModeChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).languageCode;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${exerciseIndex + 1} / $totalExercises',
                  style: const TextStyle(
                    color: AppColors.primaryLight,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),

          // Exercise image
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: ExerciseImageWidget(
                exercise: exercise,
                isDuo: isDuo,
                fit: BoxFit.contain,
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Title
          Text(
            exercise.title(locale),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.trainingDurationAndRepetitions(
              exercise.durationSeconds,
              exercise.repetitions,
            ),
            style: const TextStyle(
                color: AppColors.textSecondaryDark, fontSize: 15),
          ),
          const SizedBox(height: 24),

          // Inline mode toggle
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => onModeChanged(TrainingSessionMode.tutorial),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: mode == TrainingSessionMode.tutorial
                          ? AppColors.primary
                          : Colors.transparent,
                      border: Border.all(
                        color: mode == TrainingSessionMode.tutorial
                            ? AppColors.primary
                            : AppColors.surfaceDarkElevated,
                      ),
                      borderRadius: const BorderRadius.horizontal(
                          left: Radius.circular(10)),
                    ),
                    child: Column(
                      children: [
                        Text(
                          l10n.tutorialMode,
                          style: TextStyle(
                            color: mode == TrainingSessionMode.tutorial
                                ? Colors.white
                                : AppColors.textSecondaryDark,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          l10n.trainingTutorialSubtitle,
                          style: TextStyle(
                            color: mode == TrainingSessionMode.tutorial
                                ? Colors.white
                                : AppColors.textDisabledDark,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () => onModeChanged(TrainingSessionMode.routine),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: mode == TrainingSessionMode.routine
                          ? AppColors.primary
                          : Colors.transparent,
                      border: Border.all(
                        color: mode == TrainingSessionMode.routine
                            ? AppColors.primary
                            : AppColors.surfaceDarkElevated,
                      ),
                      borderRadius: const BorderRadius.horizontal(
                          right: Radius.circular(10)),
                    ),
                    child: Column(
                      children: [
                        Text(
                          l10n.routineMode,
                          style: TextStyle(
                            color: mode == TrainingSessionMode.routine
                                ? Colors.white
                                : AppColors.textSecondaryDark,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          l10n.trainingRoutineSubtitle,
                          style: TextStyle(
                            color: mode == TrainingSessionMode.routine
                                ? Colors.white
                                : AppColors.textDisabledDark,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          ElevatedButton(
            onPressed: onStart,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 18),
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.textPrimary,
            ),
            child: Text(
              l10n.startTraining,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
