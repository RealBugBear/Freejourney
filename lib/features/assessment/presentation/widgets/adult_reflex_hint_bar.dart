import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// Neutral horizontal hint bar — greyscale + one primary tint.
/// Color is never the only information; pair with band text.
class AdultReflexHintBar extends StatelessWidget {
  const AdultReflexHintBar({
    super.key,
    required this.percent,
    this.height = 10,
  });

  /// 0–100, or null when insufficient data.
  final double? percent;
  final double height;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final value = ((percent ?? 0) / 100).clamp(0.0, 1.0);
    final fill = percent == null
        ? cs.outlineVariant
        : AppColors.primary.withValues(alpha: 0.55 + (value * 0.35));

    return Semantics(
      label: percent == null
          ? 'insufficient'
          : '${percent!.round()} percent',
      child: ClipRRect(
        borderRadius: BorderRadius.circular(height),
        child: SizedBox(
          height: height,
          child: Stack(
            fit: StackFit.expand,
            children: [
              ColoredBox(color: cs.surfaceContainerHighest),
              if (percent != null)
                FractionallySizedBox(
                  widthFactor: value,
                  alignment: Alignment.centerLeft,
                  child: ColoredBox(color: fill),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
