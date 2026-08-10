import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/models/exercise.dart';
import '../../domain/models/training_session.dart';
import 'exercise_image_widget.dart';

class TrainingIntroWidget extends StatelessWidget {
  const TrainingIntroWidget({
    super.key,
    required this.exercise,
    required this.exerciseIndex,
    required this.totalExercises,
    required this.mode,
    this.isDuo = false,
    this.completedSessions,
    this.contentNotice,
    required this.routineEnabled,
    required this.onStart,
    required this.onModeChanged,
  });

  final Exercise exercise;
  final int exerciseIndex;
  final int totalExercises;
  final TrainingSessionMode mode;
  final bool isDuo;
  final int? completedSessions;
  final String? contentNotice;
  final bool routineEnabled;
  final VoidCallback onStart;
  final ValueChanged<TrainingSessionMode> onModeChanged;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final landscape = constraints.maxWidth >= 760 &&
            constraints.maxWidth > constraints.maxHeight;
        final image = _image(context);
        final details = _details(context);
        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 36),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 960),
                child: landscape
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(child: image),
                          const SizedBox(width: 32),
                          Expanded(child: details),
                        ],
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          image,
                          const SizedBox(height: 24),
                          details,
                        ],
                      ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _image(BuildContext context) {
    return Semantics(
      label: exercise.title(Localizations.localeOf(context).languageCode),
      image: true,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 180, maxHeight: 300),
        child: AspectRatio(
          aspectRatio: 4 / 3,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.04),
                border: Border.all(color: Colors.white12),
              ),
              child: ExerciseImageWidget(
                exercise: exercise,
                isDuo: isDuo,
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _details(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          header: true,
          child: Text(
            l10n.trainingIntroTitle,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 30,
              height: 1.12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          l10n.trainingIntroDescription,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 17,
            height: 1.45,
          ),
        ),
        const SizedBox(height: 14),
        if (contentNotice case final notice?) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white24),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.offline_pin_outlined,
                  color: AppColors.primaryLight,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    notice,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
        ],
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _chip(l10n.trainingIntroMovementCount),
            _chip(l10n.trainingIntroDuration),
          ],
        ),
        const SizedBox(height: 20),
        if (completedSessions case final count?)
          _familiarityBanner(context, count),
        const SizedBox(height: 20),
        Text(
          l10n.trainingMode,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 17,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _modeOption(
                context,
                mode: TrainingSessionMode.tutorial,
                title: l10n.tutorialMode,
                subtitle: l10n.trainingTutorialSubtitle,
                selected: mode == TrainingSessionMode.tutorial,
                enabled: true,
                reduceMotion: reduceMotion,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _modeOption(
                context,
                mode: TrainingSessionMode.routine,
                title: l10n.routineMode,
                subtitle: routineEnabled
                    ? l10n.trainingRoutineSubtitle
                    : l10n.trainingRoutineLocked,
                selected: mode == TrainingSessionMode.routine,
                enabled: routineEnabled,
                reduceMotion: reduceMotion,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        FilledButton.icon(
          onPressed: onStart,
          icon: const Icon(Icons.play_arrow_rounded),
          label: Text(l10n.startTraining),
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(58),
            textStyle: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }

  Widget _modeOption(
    BuildContext context, {
    required TrainingSessionMode mode,
    required String title,
    required String subtitle,
    required bool selected,
    required bool enabled,
    required bool reduceMotion,
  }) {
    return Semantics(
      button: true,
      selected: selected,
      enabled: enabled,
      label: '$title. $subtitle',
      child: AnimatedOpacity(
        opacity: enabled ? 1 : 0.55,
        duration:
            reduceMotion ? Duration.zero : const Duration(milliseconds: 180),
        child: Material(
          color: selected
              ? AppColors.primary
              : Colors.white.withValues(alpha: 0.04),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(
              color: selected ? AppColors.primaryLight : Colors.white24,
            ),
          ),
          child: InkWell(
            onTap: enabled ? () => onModeChanged(mode) : null,
            borderRadius: BorderRadius.circular(14),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 76),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (!enabled) ...[
                          const Icon(Icons.lock_outline, size: 17),
                          const SizedBox(width: 5),
                        ],
                        Flexible(
                          child: Text(
                            title,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _familiarityBanner(BuildContext context, int count) {
    final l10n = AppLocalizations.of(context);
    final (icon, title, body, color) = switch (count) {
      0 => (
          Icons.school_outlined,
          l10n.trainingLearningFirstTitle,
          l10n.trainingLearningFirstBody,
          AppColors.primaryLight,
        ),
      1 => (
          Icons.refresh_rounded,
          l10n.trainingLearningSecondTitle,
          l10n.trainingLearningSecondBody,
          AppColors.primaryLight,
        ),
      _ => (
          Icons.auto_awesome_outlined,
          l10n.trainingRoutineReadyTitle,
          l10n.trainingRoutineReadyBody,
          AppColors.success,
        ),
    };
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: color,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  body,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(String label) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: Colors.white24),
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
}
