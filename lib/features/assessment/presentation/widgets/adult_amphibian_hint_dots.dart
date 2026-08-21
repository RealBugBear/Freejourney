import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// Two equal-weight dots for the amphibian card (§10.2b).
///
/// Same height and fill palette as [AdultReflexHintBar] so the card stays in
/// series with percent-bar cards. Filled = that item was a positive indication.
class AdultAmphibianHintDots extends StatelessWidget {
  const AdultAmphibianHintDots({
    super.key,
    required this.itemMatched,
    this.height = 10,
  });

  /// One entry per amphibian item (typically two).
  final List<bool> itemMatched;
  final double height;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final fill = AppColors.primary.withValues(alpha: 0.75);
    final empty = cs.surfaceContainerHighest;
    final matchedCount = itemMatched.where((m) => m).length;

    return Semantics(
      label: '$matchedCount of ${itemMatched.length} matching',
      child: SizedBox(
        height: height,
        child: Row(
          children: [
            for (var i = 0; i < itemMatched.length; i++) ...[
              if (i > 0) SizedBox(width: height * 0.8),
              Container(
                width: height,
                height: height,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: itemMatched[i] ? fill : empty,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
