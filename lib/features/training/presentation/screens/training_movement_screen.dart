import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../l10n/app_localizations.dart';
import '../../domain/models/exercise.dart';
import '../widgets/animated_progress_bar.dart';
import '../widgets/exercise_image_widget.dart';

class TrainingMovementScreen extends ConsumerWidget {
  final Exercise exercise;
  final VoidCallback onContinue;

  const TrainingMovementScreen({
    super.key,
    required this.exercise,
    required this.onContinue,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).languageCode;
    final movementInstructions = exercise.movementInstructions(locale);
    final hints = exercise.hints(locale);
    final currentStep = (exercise.exerciseNumber - 1) * 3 + 2;
    const totalSteps = 21;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).maybePop(),
          tooltip: l10n.back,
        ),
        // Slim progress bar
        title: Semantics(
          label: l10n.trainingProgressSemantics(currentStep, totalSteps),
          child: AnimatedProgressBar(
            currentStep: currentStep,
            totalSteps: totalSteps,
            compact: true,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => _showCancelDialog(context),
            tooltip: l10n.trainingExitTooltip,
          ),
        ],
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              theme.colorScheme.primaryContainer.withOpacity(0.3),
              theme.colorScheme.secondaryContainer.withOpacity(0.2),
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Small reference image - top right
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: theme.colorScheme.onPrimaryContainer
                              .withOpacity(0.12),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 8,
                            spreadRadius: 1,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12.5),
                        child: ExerciseImageWidget(
                          exercise: exercise,
                          width: 140,
                          height: 140,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ],
                ),

                // Movement Instructions - THE FOCUS!
                Expanded(
                  child: ListView.separated(
                    itemCount: movementInstructions.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 28),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    itemBuilder: (context, index) {
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Elegant bullet
                          Container(
                            margin: const EdgeInsets.only(top: 10),
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: [
                                  theme.colorScheme.primary,
                                  theme.colorScheme.primary.withOpacity(0.7),
                                ],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: theme.colorScheme.primary
                                      .withOpacity(0.3),
                                  blurRadius: 4,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 20),
                          // Large, readable instruction text
                          Expanded(
                            child: Text(
                              movementInstructions[index],
                              style: theme.textTheme.headlineSmall?.copyWith(
                                height: 1.7,
                                fontWeight: FontWeight.w400,
                                fontSize: 22,
                                letterSpacing: 0.2,
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),

                // Hints Section (if available) - Compact
                if (hints != null && hints.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.orange.withOpacity(0.25),
                        width: 1.5,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.lightbulb_outline,
                              color: Colors.orange[700],
                              size: 18,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              l10n.trainingHintTitle,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: Colors.orange[700],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ...hints.map((hint) => Padding(
                              padding: const EdgeInsets.only(top: 3),
                              child: Text(
                                '• $hint',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.orange[900],
                                ),
                              ),
                            )),
                      ],
                    ),
                  ),
                ],

                // Repetitions - Very minimal
                const SizedBox(height: 8),
                Text(
                  l10n.trainingRepetitionCount(exercise.repetitions),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.45),
                    fontSize: 11,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 20),

                // Continue Button - Prominent
                SizedBox(
                  width: double.infinity,
                  height: 76,
                  child: Semantics(
                    button: true,
                    label: l10n.trainingStartExercise,
                    child: FilledButton(
                      onPressed: onContinue,
                      style: FilledButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: theme.colorScheme.onPrimary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 2,
                      ),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              l10n.trainingStartExercise,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(width: 10),
                            const Icon(Icons.play_arrow, size: 30),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showCancelDialog(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.trainingAbortTitle),
        content: Text(l10n.trainingAbortBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.trainingAbortStay),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog
              Navigator.of(context).pop(); // Close training
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: Text(l10n.trainingAbortConfirm),
          ),
        ],
      ),
    );
  }
}
