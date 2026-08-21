import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import 'impact_tree_painter.dart';

/// Card showing the aggregated impact tree for the inviter.
///
/// [activatedCount] drives headline + semantics. At most 12 branches are
/// drawn (see [ImpactTreeLayout.maxVisibleBranches]); the label never
/// mentions a branch count.
class ImpactTreeCard extends StatefulWidget {
  const ImpactTreeCard({
    super.key,
    required this.activatedCount,
    this.previousActivatedCount,
    this.height = 220,
  });

  final int activatedCount;

  /// When non-null and lower than [activatedCount], the newest branch grows in.
  final int? previousActivatedCount;
  final double height;

  @override
  State<ImpactTreeCard> createState() => _ImpactTreeCardState();
}

class _ImpactTreeCardState extends State<ImpactTreeCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _maybeAnimate();
  }

  @override
  void didUpdateWidget(covariant ImpactTreeCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.activatedCount != widget.activatedCount ||
        oldWidget.previousActivatedCount != widget.previousActivatedCount) {
      _maybeAnimate();
    }
  }

  void _maybeAnimate() {
    final previous = widget.previousActivatedCount;
    final shouldGrow = previous != null &&
        widget.activatedCount > previous &&
        widget.activatedCount > 0;
    if (!shouldGrow) {
      _controller.value = 1;
      return;
    }
    _controller.forward(from: 0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colors = impactTreeColors(theme.brightness);
    final count = widget.activatedCount;
    final visibleBranches = count.clamp(0, ImpactTreeLayout.maxVisibleBranches);
    final crownTier = ImpactTreeLayout.crownTier(count);
    final disableAnimations = MediaQuery.disableAnimationsOf(context);

    final headline = count == 0
        ? l10n.inviteTreeHeadlineZero
        : l10n.inviteTreeHeadline(count);

    // At zero, include the empty hint so AT users hear why a branch will grow.
    final semanticsLabel = count == 0
        ? '$headline. ${l10n.inviteTreeEmptyHint}'
        : l10n.inviteTreeSemantics(count);

    return Semantics(
      label: semanticsLabel,
      excludeSemantics: true,
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                headline,
                style: theme.textTheme.titleMedium,
              ),
              if (count == 0) ...[
                const SizedBox(height: 8),
                Text(
                  l10n.inviteTreeEmptyHint,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
              const SizedBox(height: 12),
              SizedBox(
                height: widget.height,
                width: double.infinity,
                child: ExcludeSemantics(
                  child: AnimatedBuilder(
                    animation: _controller,
                    builder: (context, _) {
                      final progress =
                          disableAnimations ? 1.0 : _controller.value;
                      return CustomPaint(
                        painter: ImpactTreePainter(
                          branchCount: visibleBranches,
                          crownTier: crownTier,
                          revealProgress: progress,
                          trunkColor: colors.trunk,
                          branchColor: colors.branch,
                          canopyColor: colors.canopy,
                        ),
                        child: const SizedBox.expand(),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
