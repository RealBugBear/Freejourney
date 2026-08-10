import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// A deterministic, code-rendered movement guide for the seven Moro exercises.
///
/// The widget deliberately owns no timer, ticker, or animation controller.
/// Its pose is a pure projection of the canonical session timeline supplied by
/// the caller. This keeps the visual, spoken cues, and haptics on one clock.
class ExerciseMotionVisualizer extends StatelessWidget {
  static const Set<String> supportedExerciseIds = {
    'moro_ex1',
    'moro_ex2',
    'moro_ex3',
    'moro_ex4',
    'moro_ex5',
    'moro_ex6',
    'moro_ex7',
  };

  ExerciseMotionVisualizer({
    super.key,
    required this.exerciseId,
    required this.phaseIndex,
    required this.repetitionIndex,
    required this.phaseProgress,
    required this.reducedMotion,
  }) {
    if (!supportedExerciseIds.contains(exerciseId)) {
      throw ArgumentError.value(
        exerciseId,
        'exerciseId',
        'ExerciseMotionVisualizer only supports the seven Moro exercises.',
      );
    }
  }

  final String exerciseId;
  final int phaseIndex;
  final int repetitionIndex;
  final double phaseProgress;
  final bool reducedMotion;

  @override
  Widget build(BuildContext context) {
    final languageCode = Localizations.localeOf(context).languageCode;
    final isGerman = languageCode.toLowerCase().startsWith('de');
    final safePhase = _phaseFor(exerciseId, phaseIndex);
    final safeRepetition = math.max(0, repetitionIndex);
    final timelineProgress = _normalizedProgress(phaseProgress);

    // A reduced-motion frame communicates the phase target without moving on
    // every timeline tick. Phase changes still produce a meaningful new pose.
    final visualProgress = reducedMotion ? 1.0 : timelineProgress;
    final description = _semanticDescription(
      exerciseId: exerciseId,
      phaseIndex: safePhase,
      repetitionIndex: safeRepetition,
      isGerman: isGerman,
    );
    final progressStep = ((timelineProgress * 4).round() * 25).clamp(0, 100);
    final semanticValue = isGerman
        ? 'Wiederholung ${safeRepetition + 1}, $progressStep Prozent'
        : 'Repetition ${safeRepetition + 1}, $progressStep percent';

    return Semantics(
      key: const ValueKey('exercise-motion-semantics'),
      container: true,
      image: true,
      label: description,
      value: semanticValue,
      child: ExcludeSemantics(
        child: RepaintBoundary(
          child: Center(
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: CustomPaint(
                key: const ValueKey('exercise-motion-canvas'),
                painter: _MoroMotionPainter(
                  exerciseId: exerciseId,
                  phaseIndex: safePhase,
                  repetitionIndex: safeRepetition,
                  phaseProgress: visualProgress,
                  reducedMotion: reducedMotion,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

double _normalizedProgress(double progress) {
  if (!progress.isFinite) return 0;
  return progress.clamp(0.0, 1.0);
}

int _phaseFor(String exerciseId, int phaseIndex) {
  final phaseCount = switch (exerciseId) {
    'moro_ex1' => 3,
    'moro_ex2' || 'moro_ex3' || 'moro_ex6' || 'moro_ex7' => 2,
    'moro_ex4' || 'moro_ex5' => 4,
    _ => 1,
  };
  return phaseIndex.clamp(0, phaseCount - 1);
}

String _semanticDescription({
  required String exerciseId,
  required int phaseIndex,
  required int repetitionIndex,
  required bool isGerman,
}) {
  const titles = <String, String>{
    'moro_ex1': 'Moro 5',
    'moro_ex2': 'Moro 3',
    'moro_ex3': 'Moro 4',
    'moro_ex4': 'Moro 1',
    'moro_ex5': 'Moro 2',
    'moro_ex6': 'Moro 6',
    'moro_ex7': 'Moro 7',
  };
  const phasesDe = <String, List<String>>{
    'moro_ex1': ['Bein anheben', 'Halten', 'Bein ablegen'],
    'moro_ex2': ['Fuß hochgleiten', 'Fuß zurückgleiten'],
    'moro_ex3': ['Füße heranziehen', 'Füße zurückführen'],
    'moro_ex4': [
      'Knie nach rechts',
      'Knie zur Mitte',
      'Knie nach links',
      'Knie zur Mitte',
    ],
    'moro_ex5': ['Ausatmen', 'Oberkörper anheben', 'Halten', 'Ablegen'],
    'moro_ex6': ['Gegendruck halten', 'Pause'],
    'moro_ex7': ['Überkreuzten Gegendruck halten', 'Pause'],
  };
  const phasesEn = <String, List<String>>{
    'moro_ex1': ['Raise leg', 'Hold', 'Lower leg'],
    'moro_ex2': ['Slide foot up', 'Slide foot back'],
    'moro_ex3': ['Draw feet in', 'Return feet'],
    'moro_ex4': [
      'Knees to the right',
      'Knees to centre',
      'Knees to the left',
      'Knees to centre',
    ],
    'moro_ex5': ['Exhale', 'Raise upper body', 'Hold', 'Lower'],
    'moro_ex6': ['Hold counterpressure', 'Rest'],
    'moro_ex7': ['Hold crossed counterpressure', 'Rest'],
  };

  final phase = (isGerman ? phasesDe : phasesEn)[exerciseId]![phaseIndex];
  final alternatesSide = exerciseId == 'moro_ex1' || exerciseId == 'moro_ex2';
  final side = repetitionIndex.isEven
      ? (isGerman ? 'rechte Seite' : 'right side')
      : (isGerman ? 'linke Seite' : 'left side');
  final sideSuffix = alternatesSide ? ', $side' : '';
  final guide = isGerman ? 'Bewegungsvorschau' : 'movement guide';
  return '${titles[exerciseId]}, $guide: $phase$sideSuffix';
}

class _MoroMotionPainter extends CustomPainter {
  const _MoroMotionPainter({
    required this.exerciseId,
    required this.phaseIndex,
    required this.repetitionIndex,
    required this.phaseProgress,
    required this.reducedMotion,
  });

  final String exerciseId;
  final int phaseIndex;
  final int repetitionIndex;
  final double phaseProgress;
  final bool reducedMotion;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;

    final drawing = _MotionDrawing(canvas, size, reducedMotion: reducedMotion);
    drawing.drawSurface();

    switch (exerciseId) {
      case 'moro_ex1':
        _paintCrossLegLift(drawing);
      case 'moro_ex2':
        _paintHalfFrog(drawing);
      case 'moro_ex3':
        _paintFrog(drawing);
      case 'moro_ex4':
        _paintKneeDrops(drawing);
      case 'moro_ex5':
        _paintRollUp(drawing);
      case 'moro_ex6':
        _paintCounterpressure(drawing, crossed: false);
      case 'moro_ex7':
        _paintCounterpressure(drawing, crossed: true);
    }
  }

  void _paintCrossLegLift(_MotionDrawing d) {
    final pose = switch (phaseIndex) {
      0 => phaseProgress,
      1 => 1.0,
      _ => 1 - phaseProgress,
    };
    final movingRight = repetitionIndex.isEven;
    double mirror(double x) => movingRight ? x : 1 - x;

    d.drawSupineUpperBody();
    final stableHip = d.point(mirror(.46), .52);
    final stableKnee = d.point(mirror(.45), .70);
    final stableFoot = d.point(mirror(.44), .88);
    d.limb([stableHip, stableKnee, stableFoot]);

    final movingHip = d.point(mirror(.54), .52);
    final knee = Offset.lerp(
      d.point(mirror(.55), .70),
      d.point(mirror(.59), .62),
      pose,
    )!;
    final foot = Offset.lerp(
      d.point(mirror(.56), .88),
      d.point(mirror(.45), .72),
      pose,
    )!;
    final guideStart = d.point(mirror(.56), .86);
    final guideEnd = d.point(mirror(.46), .70);
    if (phaseIndex == 0) {
      d.guideArrow(guideStart, guideEnd);
    } else if (phaseIndex == 2) {
      d.guideArrow(guideEnd, guideStart);
    } else {
      d.stabilityMark(foot);
    }
    d.limb([movingHip, knee, foot], active: true);
    d.joint(foot, active: true);
  }

  void _paintHalfFrog(_MotionDrawing d) {
    final pose = phaseIndex == 0 ? phaseProgress : 1 - phaseProgress;
    final movingRight = repetitionIndex.isEven;
    double mirror(double x) => movingRight ? x : 1 - x;

    d.drawSupineUpperBody();
    final stableHip = d.point(mirror(.46), .52);
    final stableFoot = d.point(mirror(.45), .89);
    d.limb([stableHip, d.point(mirror(.45), .70), stableFoot]);

    final movingHip = d.point(mirror(.54), .52);
    final knee = Offset.lerp(
      d.point(mirror(.55), .70),
      d.point(mirror(.68), .69),
      pose,
    )!;
    final foot = Offset.lerp(
      d.point(mirror(.56), .89),
      d.point(mirror(.48), .68),
      pose,
    )!;
    final guideStart = d.point(mirror(.55), .86);
    final guideEnd = d.point(mirror(.48), .66);
    d.guideArrow(
      phaseIndex == 0 ? guideStart : guideEnd,
      phaseIndex == 0 ? guideEnd : guideStart,
    );
    d.limb([movingHip, knee, foot], active: true);
    d.joint(knee, active: true);
    d.joint(foot, active: true);
  }

  void _paintFrog(_MotionDrawing d) {
    final pose = phaseIndex == 0 ? phaseProgress : 1 - phaseProgress;
    d.drawSupineUpperBody();

    final leftKnee = Offset.lerp(
      d.point(.46, .70),
      d.point(.29, .68),
      pose,
    )!;
    final rightKnee = Offset.lerp(
      d.point(.54, .70),
      d.point(.71, .68),
      pose,
    )!;
    final leftFoot = Offset.lerp(
      d.point(.47, .89),
      d.point(.49, .72),
      pose,
    )!;
    final rightFoot = Offset.lerp(
      d.point(.53, .89),
      d.point(.51, .72),
      pose,
    )!;

    final leftGuideStart = d.point(.43, .86);
    final leftGuideEnd = d.point(.48, .70);
    final rightGuideStart = d.point(.57, .86);
    final rightGuideEnd = d.point(.52, .70);
    d.guideArrow(
      phaseIndex == 0 ? leftGuideStart : leftGuideEnd,
      phaseIndex == 0 ? leftGuideEnd : leftGuideStart,
    );
    d.guideArrow(
      phaseIndex == 0 ? rightGuideStart : rightGuideEnd,
      phaseIndex == 0 ? rightGuideEnd : rightGuideStart,
    );
    d.limb([d.point(.46, .52), leftKnee, leftFoot], active: true);
    d.limb([d.point(.54, .52), rightKnee, rightFoot], active: true);
    d.line(leftFoot, rightFoot, active: true);
  }

  void _paintKneeDrops(_MotionDrawing d) {
    final direction = switch (phaseIndex) {
      0 => phaseProgress,
      1 => 1 - phaseProgress,
      2 => -phaseProgress,
      _ => -(1 - phaseProgress),
    };

    d.drawSupineUpperBody();
    final kneeShift = direction * .18;
    final ankleShift = direction * .10;
    final leftKnee = d.point(.46 + kneeShift, .66 + direction.abs() * .03);
    final rightKnee = d.point(.54 + kneeShift, .66 + direction.abs() * .03);
    final leftFoot = d.point(.43 + ankleShift, .82);
    final rightFoot = d.point(.57 + ankleShift, .82);

    final center = d.point(.50, .62);
    final right = d.point(.72, .66);
    final left = d.point(.28, .66);
    final (arrowStart, arrowEnd) = switch (phaseIndex) {
      0 => (center, right),
      1 => (right, center),
      2 => (center, left),
      _ => (left, center),
    };
    d.guideArrow(arrowStart, arrowEnd);
    d.limb([d.point(.46, .52), leftKnee, leftFoot], active: true);
    d.limb([d.point(.54, .52), rightKnee, rightFoot], active: true);
    d.line(leftKnee, rightKnee, active: true);
    d.stabilityMark(d.point(.50, .52));
  }

  void _paintRollUp(_MotionDrawing d) {
    final pose = switch (phaseIndex) {
      0 => phaseProgress * .12,
      1 => phaseProgress,
      2 => 1.0,
      _ => 1 - phaseProgress,
    };
    final head = Offset.lerp(d.point(.50, .17), d.point(.50, .36), pose)!;
    final shoulder = Offset.lerp(
      d.point(.50, .30),
      d.point(.50, .41),
      pose,
    )!;
    final hip = d.point(.50, .53);

    d.head(head, active: true);
    d.torsoCurve(head, shoulder, hip, active: true);
    final armOriginLeft = Offset.lerp(
      d.point(.43, .31),
      d.point(.43, .43),
      pose,
    )!;
    final armOriginRight = Offset.lerp(
      d.point(.57, .31),
      d.point(.57, .43),
      pose,
    )!;
    d.limb([armOriginLeft, d.point(.38, .50), d.point(.38, .63)]);
    d.limb([armOriginRight, d.point(.62, .50), d.point(.62, .63)]);
    d.limb([
      d.point(.46, .53),
      d.point(.42, .68),
      d.point(.42, .83),
    ]);
    d.limb([
      d.point(.54, .53),
      d.point(.58, .68),
      d.point(.58, .83),
    ]);
    if (phaseIndex == 1) {
      d.guideArrow(d.point(.50, .22), d.point(.50, .38));
    } else if (phaseIndex == 3) {
      d.guideArrow(d.point(.50, .38), d.point(.50, .22));
    } else if (phaseIndex == 2) {
      d.stabilityMark(head);
    }
    d.breathMark(d.point(.57, .24), intensity: 1 - phaseProgress * .5);
  }

  void _paintCounterpressure(
    _MotionDrawing d, {
    required bool crossed,
  }) {
    final isRest = phaseIndex == 1;
    final intensity = isRest ? 0.12 : math.max(.28, phaseProgress);
    final switchedCross = repetitionIndex >= 3;
    final head = d.point(.50, crossed ? .22 : .18);
    d.head(head, active: crossed && !isRest);
    d.torsoCurve(head, d.point(.50, .31), d.point(.50, .52));

    final leftHip = d.point(.46, .52);
    final rightHip = d.point(.54, .52);
    final leftKnee = d.point(.39, .68);
    final rightKnee = d.point(.61, .68);
    final leftFoot = d.point(.40, .84);
    final rightFoot = d.point(.60, .84);
    d.limb([leftHip, leftKnee, leftFoot]);
    d.limb([rightHip, rightKnee, rightFoot]);

    final leftHandTarget = crossed ? d.point(.58, .61) : d.point(.58, .67);
    final rightHandTarget = crossed ? d.point(.42, .61) : d.point(.42, .67);
    final leftArm = [
      d.point(.42, .34),
      d.point(.46, .45),
      switchedCross ? rightHandTarget : leftHandTarget,
    ];
    final rightArm = [
      d.point(.58, .34),
      d.point(.54, .45),
      switchedCross ? leftHandTarget : rightHandTarget,
    ];

    if (switchedCross) {
      d.limb(leftArm, active: !isRest, intensity: intensity);
      d.limb(rightArm, active: !isRest, intensity: intensity + .15);
    } else {
      d.limb(rightArm, active: !isRest, intensity: intensity);
      d.limb(leftArm, active: !isRest, intensity: intensity + .15);
    }
    d.joint(leftArm.last, active: !isRest);
    d.joint(rightArm.last, active: !isRest);

    if (!isRest) {
      d.forcePair(
        d.point(.43, .61),
        d.point(.43, crossed ? .52 : .56),
        intensity: intensity,
      );
      d.forcePair(
        d.point(.57, .61),
        d.point(.57, crossed ? .52 : .56),
        intensity: intensity,
      );
      d.breathMark(d.point(.59, .24), intensity: intensity);
    }
  }

  @override
  bool shouldRepaint(covariant _MoroMotionPainter oldDelegate) {
    return oldDelegate.exerciseId != exerciseId ||
        oldDelegate.phaseIndex != phaseIndex ||
        oldDelegate.repetitionIndex != repetitionIndex ||
        oldDelegate.phaseProgress != phaseProgress ||
        oldDelegate.reducedMotion != reducedMotion;
  }
}

class _MotionDrawing {
  _MotionDrawing(
    this.canvas,
    this.size, {
    required this.reducedMotion,
  }) : stroke = math.max(2.2, size.shortestSide * .025);

  final Canvas canvas;
  final Size size;
  final bool reducedMotion;
  final double stroke;

  Offset point(double x, double y) => Offset(size.width * x, size.height * y);

  void drawSurface() {
    final bounds = Offset.zero & size;
    canvas.drawRRect(
      RRect.fromRectAndRadius(bounds, Radius.circular(size.shortestSide * .08)),
      Paint()..color = AppColors.surfaceDark,
    );
    final mat = Rect.fromLTWH(
      size.width * .23,
      size.height * .05,
      size.width * .54,
      size.height * .90,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(mat, Radius.circular(size.shortestSide * .12)),
      Paint()..color = AppColors.primary.withValues(alpha: .06),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(mat, Radius.circular(size.shortestSide * .12)),
      Paint()
        ..color = AppColors.primaryLight.withValues(alpha: .20)
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(1, stroke * .35),
    );
  }

  void drawSupineUpperBody() {
    head(point(.50, .17));
    torsoCurve(point(.50, .20), point(.50, .31), point(.50, .52));
    limb([point(.43, .31), point(.37, .46), point(.36, .64)]);
    limb([point(.57, .31), point(.63, .46), point(.64, .64)]);
  }

  void head(Offset center, {bool active = false}) {
    canvas.drawCircle(
      center,
      stroke * 2.1,
      Paint()
        ..color = active ? AppColors.primaryOnDark : AppColors.textPrimaryDark
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke * .72,
    );
  }

  void torsoCurve(
    Offset head,
    Offset shoulder,
    Offset hip, {
    bool active = false,
  }) {
    final paint = _bodyPaint(active: active);
    canvas.drawLine(
      Offset(head.dx, head.dy + stroke * 2.3),
      shoulder,
      paint,
    );
    canvas.drawLine(
      Offset(shoulder.dx - size.width * .07, shoulder.dy),
      Offset(shoulder.dx + size.width * .07, shoulder.dy),
      paint,
    );
    final path = Path()
      ..moveTo(shoulder.dx, shoulder.dy)
      ..quadraticBezierTo(
        shoulder.dx,
        (shoulder.dy + hip.dy) / 2,
        hip.dx,
        hip.dy,
      );
    canvas.drawPath(path, paint);
    canvas.drawLine(
      Offset(hip.dx - size.width * .04, hip.dy),
      Offset(hip.dx + size.width * .04, hip.dy),
      paint,
    );
  }

  void limb(
    List<Offset> points, {
    bool active = false,
    double intensity = 1,
  }) {
    if (points.length < 2) return;
    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (final point in points.skip(1)) {
      path.lineTo(point.dx, point.dy);
    }
    canvas.drawPath(
      path,
      _bodyPaint(active: active, intensity: intensity),
    );
    for (final point in points.skip(1).take(points.length - 2)) {
      joint(point, active: active);
    }
  }

  void line(Offset start, Offset end, {bool active = false}) {
    canvas.drawLine(start, end, _bodyPaint(active: active));
  }

  void joint(Offset center, {bool active = false}) {
    canvas.drawCircle(
      center,
      stroke * .72,
      Paint()
        ..color = active ? AppColors.primaryOnDark : AppColors.textPrimaryDark,
    );
  }

  void guideArrow(Offset start, Offset end) {
    final color = AppColors.primaryLight.withValues(alpha: .72);
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke * .50
      ..strokeCap = StrokeCap.round;
    final path = Path()
      ..moveTo(start.dx, start.dy)
      ..quadraticBezierTo(
        (start.dx + end.dx) / 2 + (end.dy - start.dy) * .10,
        (start.dy + end.dy) / 2,
        end.dx,
        end.dy,
      );
    canvas.drawPath(path, paint);
    _arrowHead(end, end - start, color);
  }

  void forcePair(
    Offset start,
    Offset end, {
    required double intensity,
  }) {
    final alpha = (.35 + intensity * .55).clamp(0.0, 1.0);
    final color = AppColors.primaryOnDark.withValues(alpha: alpha);
    final paint = Paint()
      ..color = color
      ..strokeWidth = stroke * (.45 + intensity * .25)
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(start, end, paint);
    _arrowHead(end, end - start, color);
    final oppositeStart = Offset(start.dx, start.dy + stroke * 1.6);
    final oppositeEnd = Offset(end.dx, end.dy + stroke * 1.6);
    canvas.drawLine(oppositeEnd, oppositeStart, paint);
    _arrowHead(oppositeStart, oppositeStart - oppositeEnd, color);
  }

  void stabilityMark(Offset center) {
    final paint = Paint()
      ..color = AppColors.primaryLight.withValues(alpha: .75)
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke * .45;
    canvas.drawCircle(center, stroke * 2.2, paint);
    canvas.drawLine(
      center.translate(-stroke * 2.8, 0),
      center.translate(stroke * 2.8, 0),
      paint,
    );
  }

  void breathMark(Offset origin, {required double intensity}) {
    final safeIntensity = intensity.clamp(0.0, 1.0);
    final paint = Paint()
      ..color =
          AppColors.primaryLight.withValues(alpha: .28 + safeIntensity * .45)
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke * .38
      ..strokeCap = StrokeCap.round;
    for (var index = 0; index < 3; index++) {
      final y = origin.dy + index * stroke * 1.5;
      final length = stroke * (2.2 + index * .9) * safeIntensity;
      canvas.drawArc(
        Rect.fromCenter(
          center: Offset(origin.dx + length * .5, y),
          width: math.max(stroke, length),
          height: stroke * 1.4,
        ),
        -math.pi * .28,
        math.pi * .56,
        false,
        paint,
      );
    }
  }

  Paint _bodyPaint({required bool active, double intensity = 1}) {
    final safeIntensity = intensity.clamp(0.0, 1.0);
    return Paint()
      ..color = active
          ? AppColors.primaryOnDark.withValues(
              alpha: .45 + safeIntensity * .55,
            )
          : AppColors.textPrimaryDark.withValues(alpha: .82)
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke * (active ? 1.05 : .82)
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
  }

  void _arrowHead(Offset tip, Offset direction, Color color) {
    if (direction.distanceSquared == 0) return;
    final angle = math.atan2(direction.dy, direction.dx);
    final length = stroke * 2.1;
    final left = tip -
        Offset(
          math.cos(angle - math.pi / 5) * length,
          math.sin(angle - math.pi / 5) * length,
        );
    final right = tip -
        Offset(
          math.cos(angle + math.pi / 5) * length,
          math.sin(angle + math.pi / 5) * length,
        );
    canvas.drawPath(
      Path()
        ..moveTo(tip.dx, tip.dy)
        ..lineTo(left.dx, left.dy)
        ..lineTo(right.dx, right.dy)
        ..close(),
      Paint()..color = color,
    );
  }
}
