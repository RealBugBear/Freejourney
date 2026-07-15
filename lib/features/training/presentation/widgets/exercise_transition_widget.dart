// lib/features/training/presentation/widgets/exercise_transition_widget.dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../l10n/app_localizations.dart';
import '../../domain/models/exercise.dart';
import 'exercise_image_widget.dart';
import 'exercise_video_widget.dart';

class ExerciseTransitionWidget extends StatefulWidget {
  final Exercise exercise;
  final int exerciseIndex; // 0-based
  final int totalExercises;
  final bool isRoutineMode;
  final int transitionDurationSeconds; // countdown length for routine
  final String packageId;
  final bool isFirstRun;
  final String locale; // 'de' or 'en'
  final bool isDuo;
  final bool enableCountdown;
  final VoidCallback onStart;

  const ExerciseTransitionWidget({
    super.key,
    required this.exercise,
    required this.exerciseIndex,
    required this.totalExercises,
    required this.isRoutineMode,
    required this.transitionDurationSeconds,
    required this.packageId,
    required this.isFirstRun,
    required this.locale,
    this.isDuo = false,
    this.enableCountdown = true,
    required this.onStart,
  });

  @override
  State<ExerciseTransitionWidget> createState() =>
      _ExerciseTransitionWidgetState();
}

class _ExerciseTransitionWidgetState extends State<ExerciseTransitionWidget> {
  int _countdown = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    if (widget.isRoutineMode && widget.enableCountdown) {
      _countdown = widget.transitionDurationSeconds;
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (!mounted) return;
        if (_countdown <= 1) {
          _timer?.cancel();
          setState(() => _countdown = 0);
          widget.onStart();
        } else {
          setState(() => _countdown--);
        }
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startNow() {
    _timer?.cancel();
    setState(() => _countdown = 0);
    HapticFeedback.mediumImpact();
    widget.onStart();
  }

  void _showVideo(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.black,
      builder: (sheetContext) => SizedBox(
        height: MediaQuery.of(context).size.height * 0.6,
        child: ExerciseVideoWidget(
          exercise: widget.exercise,
          onReady: () => Navigator.of(sheetContext).pop(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final ex = widget.exercise;
    final loc = widget.locale;
    final positionInstructions =
        ex.positionInstructionsFor(loc, duo: widget.isDuo);
    final movementInstructions =
        ex.movementInstructionsFor(loc, duo: widget.isDuo);

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Exercise image with optional video button overlay
        Stack(
          children: [
            AspectRatio(
              aspectRatio: 16 / 9,
              child: ExerciseImageWidget(
                exercise: ex,
                isDuo: widget.isDuo,
                fit: BoxFit.cover,
              ),
            ),
            if (!widget.isFirstRun &&
                (ex.videoPath != null || ex.videoUrl != null) &&
                !widget.isRoutineMode)
              Positioned(
                bottom: 8,
                right: 8,
                child: GestureDetector(
                  onTap: () => _showVideo(context),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.75),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.white24),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.play_arrow,
                          color: Colors.white70,
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Text(l10n.trainingVideo,
                            style: const TextStyle(
                                color: Colors.white70, fontSize: 12)),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),

        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.trainingExerciseOfTotal(
                    widget.exerciseIndex + 1,
                    widget.totalExercises,
                  ),
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.4),
                    fontSize: 11,
                    letterSpacing: 0.12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  ex.title(loc),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  children: [
                    _chip(l10n.trainingRepetitionsAbbreviated(ex.repetitions)),
                    _chip(l10n.trainingSecondsPerRep(ex.holdSeconds)),
                  ],
                ),
                const SizedBox(height: 14),
                _sectionLabel(l10n.trainingPositionLabel),
                ...positionInstructions.map(_bullet),
                const SizedBox(height: 10),
                _sectionLabel(l10n.exerciseMovement),
                ...movementInstructions.map(_bullet),
                const SizedBox(height: 10),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6366f1).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: const Color(0xFF6366f1).withOpacity(0.25),
                    ),
                  ),
                  child: Text(
                    '"${ex.executionGuide(loc)}"',
                    style: const TextStyle(
                      color: Color(0xFFa5b4fc),
                      fontSize: 13,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
                // First-run video (Tutorial mode only)
                if (widget.isFirstRun &&
                    ex.videoPath != null &&
                    !widget.isRoutineMode) ...[
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: SizedBox(
                      height: 220,
                      child: ExerciseVideoWidget(
                        exercise: ex,
                        onReady: () {},
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),

        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          child: widget.isRoutineMode
              ? widget.enableCountdown
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          l10n.trainingStartsInSeconds(_countdown),
                          style: TextStyle(
                              color: Colors.white.withOpacity(0.5),
                              fontSize: 13),
                        ),
                        FilledButton(
                          onPressed: _startNow,
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF6366f1),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                          child: Text(l10n.trainingStartNow),
                        ),
                      ],
                    )
                  : Text(
                      l10n.trainingAnnouncementPlaying,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.5),
                        fontSize: 13,
                      ),
                    )
              : SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: FilledButton.icon(
                    onPressed: _startNow,
                    icon: const Icon(Icons.play_arrow),
                    label: Text(
                      l10n.trainingStartExercise,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF6366f1),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
        ),
      ],
    );

    if (widget.isRoutineMode) {
      return GestureDetector(
        onTap: _startNow,
        child: Container(
          color: const Color(0xFF0a0a12),
          child: content,
        ),
      );
    }
    return Container(
      color: const Color(0xFF0f0f18),
      child: content,
    );
  }

  Widget _chip(String label) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFF6366f1).withOpacity(0.12),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
              color: const Color(0xFF6366f1).withOpacity(0.3), width: 1),
        ),
        child: Text(label,
            style: const TextStyle(
                color: Color(0xFFa5b4fc),
                fontSize: 11,
                fontWeight: FontWeight.w700)),
      );

  Widget _sectionLabel(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Text(text,
            style: TextStyle(
                color: Colors.white.withOpacity(0.3),
                fontSize: 9,
                letterSpacing: 0.12,
                fontWeight: FontWeight.w700)),
      );

  Widget _bullet(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 3),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 5,
              height: 5,
              margin: const EdgeInsets.only(top: 6, right: 8),
              decoration: const BoxDecoration(
                  shape: BoxShape.circle, color: Color(0xFF6366f1)),
            ),
            Expanded(
              child: Text(text,
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.75), fontSize: 13)),
            ),
          ],
        ),
      );
}
