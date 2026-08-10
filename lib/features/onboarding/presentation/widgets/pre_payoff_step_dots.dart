import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// Thin 4-dot progress for the pre-payoff onboarding path.
///
/// [currentStep] is **1-based**:
/// 1 = Account, 2 = Consent, 3 = Kontaktname, 4 = Für-wen.
/// Dots `1..currentStep` are filled (e.g. Consent shows two filled dots).
class PrePayoffStepDots extends StatelessWidget {
  const PrePayoffStepDots({
    super.key,
    required this.currentStep,
    this.caption,
    this.totalSteps = 4,
  }) : assert(currentStep >= 1 && currentStep <= totalSteps);

  /// 1-based index of the active pre-payoff step.
  final int currentStep;

  /// Optional tiny caption under the dots (keep short — no roadmap chrome).
  final String? caption;

  final int totalSteps;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 1; i <= totalSteps; i++) ...[
              if (i > 1) const SizedBox(width: 8),
              _Dot(filled: i <= currentStep),
            ],
          ],
        ),
        if (caption != null && caption!.trim().isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            caption!,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ],
      ],
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.filled});

  final bool filled;

  @override
  Widget build(BuildContext context) {
    final outline = Theme.of(context).colorScheme.outlineVariant;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: filled ? AppColors.primary : Colors.transparent,
        border: Border.all(
          color: filled ? AppColors.primary : outline,
          width: 1.25,
        ),
      ),
    );
  }
}
