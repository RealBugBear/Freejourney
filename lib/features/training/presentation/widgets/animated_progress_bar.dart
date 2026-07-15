import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';

/// Animated progress bar with milestone indicators
/// Shows progress with encouraging visual feedback
class AnimatedProgressBar extends StatefulWidget {
  final int currentStep;
  final int totalSteps;
  final Duration animationDuration;
  final bool compact; // New: for AppBar version
  final bool minimal; // Visual-only (no text/emoji)

  const AnimatedProgressBar({
    super.key,
    required this.currentStep,
    required this.totalSteps,
    this.animationDuration = const Duration(milliseconds: 800),
    this.compact = false,
    this.minimal = false,
  });

  @override
  State<AnimatedProgressBar> createState() => _AnimatedProgressBarState();
}

class _AnimatedProgressBarState extends State<AnimatedProgressBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _progressAnimation;
  double _previousProgress = 0.0;

  @override
  void initState() {
    super.initState();

    // Start from previous step to create smooth expanding animation
    // when navigating between screens
    final previousStep = (widget.currentStep - 1).clamp(0, widget.totalSteps);
    _previousProgress = previousStep / widget.totalSteps;

    _controller = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );

    _updateAnimation();
  }

  @override
  void didUpdateWidget(AnimatedProgressBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentStep != widget.currentStep ||
        oldWidget.totalSteps != widget.totalSteps) {
      _updateAnimation();
    }
  }

  void _updateAnimation() {
    final targetProgress = widget.currentStep / widget.totalSteps;
    _progressAnimation = Tween<double>(
      begin: _previousProgress,
      end: targetProgress,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));

    // Reset and forward to animate from previous to target progress
    _controller.reset();
    _controller.forward();
    _previousProgress = targetProgress;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final progress = widget.currentStep / widget.totalSteps;

    if (widget.minimal) {
      return AnimatedBuilder(
        animation: _progressAnimation,
        builder: (context, child) {
          return Container(
            height: 8,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.18),
              borderRadius: BorderRadius.circular(99),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: _progressAnimation.value.clamp(0, 1),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
          );
        },
      );
    }

    // Compact mode for AppBar
    if (widget.compact) {
      return SizedBox(
        width: 120,
        child: AnimatedBuilder(
          animation: _progressAnimation,
          builder: (context, child) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Just the bar
                Container(
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.onSurface.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: _progressAnimation.value,
                    child: Container(
                      decoration: BoxDecoration(
                        color: _getProgressColor(_progressAnimation.value),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                // Just percentage
                Text(
                  '${(progress * 100).toInt()}%',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            );
          },
        ),
      );
    }

    // Full version (existing code)
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Encouraging message
        AnimatedBuilder(
          animation: _progressAnimation,
          builder: (context, child) {
            return Text(
              _getEncouragingMessage(progress, l10n),
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: _getProgressColor(progress),
              ),
              textAlign: TextAlign.center,
            );
          },
        ),
        const SizedBox(height: 12),

        // Progress bar with milestones
        Stack(
          children: [
            // Background track
            Container(
              height: 12,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(6),
              ),
            ),

            // Animated progress fill
            AnimatedBuilder(
              animation: _progressAnimation,
              builder: (context, child) {
                return FractionallySizedBox(
                  widthFactor: _progressAnimation.value,
                  child: Container(
                    height: 12,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          _getProgressColor(_progressAnimation.value),
                          _getProgressColor(_progressAnimation.value)
                              .withOpacity(0.7),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(6),
                      boxShadow: [
                        BoxShadow(
                          color: _getProgressColor(_progressAnimation.value)
                              .withOpacity(0.4),
                          blurRadius: 8,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),

            // Milestone markers
            ..._buildMilestoneMarkers(theme),
          ],
        ),

        const SizedBox(height: 8),

        // Step counter
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              l10n.trainingProgressStepCounter(
                widget.currentStep,
                widget.totalSteps,
              ),
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              l10n.trainingProgressPercentComplete(
                (progress * 100).toInt(),
              ),
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: _getProgressColor(progress),
              ),
            ),
          ],
        ),
      ],
    );
  }

  List<Widget> _buildMilestoneMarkers(ThemeData theme) {
    final milestones = [0.25, 0.5, 0.75, 1.0];
    final progress = widget.currentStep / widget.totalSteps;

    return milestones.map((milestone) {
      final isPassed = progress >= milestone;
      return Positioned(
        left: milestone * MediaQuery.of(context).size.width * 0.95 - 8,
        child: Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color:
                isPassed ? _getMilestoneColor(milestone) : Colors.grey.shade300,
            border: Border.all(
              color: Colors.white,
              width: 2,
            ),
            boxShadow: isPassed
                ? [
                    BoxShadow(
                      color: _getMilestoneColor(milestone).withOpacity(0.5),
                      blurRadius: 4,
                      spreadRadius: 1,
                    ),
                  ]
                : null,
          ),
          child: isPassed
              ? Icon(
                  Icons.check,
                  size: 10,
                  color: Colors.white,
                )
              : null,
        ),
      );
    }).toList();
  }

  Color _getProgressColor(double progress) {
    if (progress >= 0.75)
      return const Color(0xFF4CAF50); // Green - almost done!
    if (progress >= 0.5) return const Color(0xFF2196F3); // Blue - halfway
    if (progress >= 0.25)
      return const Color(0xFFFF9800); // Orange - getting started
    return const Color(0xFF9C27B0); // Purple - just started
  }

  Color _getMilestoneColor(double milestone) {
    if (milestone >= 0.75) return const Color(0xFFFFD700); // Gold
    if (milestone >= 0.5) return const Color(0xFF4CAF50); // Green
    if (milestone >= 0.25) return const Color(0xFF2196F3); // Blue
    return const Color(0xFF9C27B0); // Purple
  }

  String _getEncouragingMessage(
    double progress,
    AppLocalizations l10n,
  ) {
    if (progress >= 0.9) return l10n.trainingProgressAlmostThere;
    if (progress >= 0.75) return l10n.trainingProgressGreat;
    if (progress >= 0.5) return l10n.trainingProgressHalfway;
    if (progress >= 0.25) return l10n.trainingProgressKeepGoing;
    return l10n.trainingProgressLetsGo;
  }
}
