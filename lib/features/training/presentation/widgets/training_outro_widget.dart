import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/app_localizations.dart';

/// Completion presentation shown only after atomic persistence succeeded.
class TrainingOutroWidget extends StatelessWidget {
  const TrainingOutroWidget({
    super.key,
    required this.completedCount,
    required this.onContinue,
  });

  final int completedCount;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final content = Container(
      width: 108,
      height: 108,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.success.withValues(alpha: 0.15),
        border: Border.all(color: AppColors.success, width: 2),
      ),
      child: const Icon(
        Icons.check_rounded,
        color: AppColors.success,
        size: 56,
      ),
    );

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: MediaQuery.sizeOf(context).height - 64,
          ),
          child: Semantics(
            liveRegion: true,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: reduceMotion
                      ? content
                      : TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0.82, end: 1),
                          duration: const Duration(milliseconds: 420),
                          curve: Curves.easeOutBack,
                          builder: (_, scale, child) => Transform.scale(
                            scale: scale,
                            child: child,
                          ),
                          child: content,
                        ),
                ),
                const SizedBox(height: 32),
                Text(
                  l10n.sessionComplete,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  l10n.sessionCompleteSubtitle,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 17,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  l10n.trainingCompletedExerciseCount(completedCount),
                  style: const TextStyle(
                    color: AppColors.primaryLight,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 44),
                FilledButton(
                  onPressed: onContinue,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(58),
                  ),
                  child: Text(
                    l10n.done,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
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
}
