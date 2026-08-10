import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

class RepSegmentsWidget extends StatelessWidget {
  final int totalReps;
  final int completedReps; // fully done reps
  final double beatProgress; // 0.0..1.0 fill of the active rep

  const RepSegmentsWidget({
    super.key,
    required this.totalReps,
    required this.completedReps,
    this.beatProgress = 0.0,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(totalReps, (i) {
        final isDone = i < completedReps;
        final isActive = i == completedReps;
        return Container(
          width: (totalReps > 4) ? 20 : 28,
          height: 4,
          margin: const EdgeInsets.symmetric(horizontal: 3),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(2),
            color: isDone
                ? AppColors.primaryLight
                : Colors.white.withValues(alpha: 0.1),
          ),
          child: isActive
              ? FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: beatProgress.clamp(0.0, 1.0),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(2),
                      color: AppColors.primaryLight,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primaryLight.withValues(alpha: 0.6),
                          blurRadius: 6,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),
                )
              : null,
        );
      }),
    );
  }
}
