import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/reflex_questionnaire.dart';

/// One axis on the radar chart.
class ReflexRadarScore {
  const ReflexRadarScore({
    required this.label,
    required this.shortLabel,
    required this.percent,
  });

  final String label;
  final String shortLabel;
  final double percent; // 0–100
}

/// Reusable radar / spider chart for reflex profiles.
///
/// [mini] suppresses labels and uses smaller dots — suitable for compact cards.
/// For the full result screen, pass [mini]: false.
class ReflexRadarChart extends StatelessWidget {
  const ReflexRadarChart({
    super.key,
    required this.scores,
    this.mini = false,
    this.color,
  });

  final List<ReflexRadarScore> scores;
  final bool mini;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    if (scores.length < 3) {
      return Center(
        child: Text(
          AppLocalizations.of(context).radarNotEnoughData,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
      );
    }

    final effectiveColor = color ?? AppColors.primary;
    final labelStyle = mini
        ? null
        : Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w700,
              height: 1.15,
            );

    return CustomPaint(
      painter: _ReflexRadarPainter(
        scores: scores,
        primaryColor: effectiveColor,
        gridColor: Theme.of(context).colorScheme.outlineVariant,
        labelStyle: labelStyle,
        mini: mini,
      ),
    );
  }
}

class _ReflexRadarPainter extends CustomPainter {
  const _ReflexRadarPainter({
    required this.scores,
    required this.primaryColor,
    required this.gridColor,
    this.labelStyle,
    this.mini = false,
  });

  final List<ReflexRadarScore> scores;
  final Color primaryColor;
  final Color gridColor;
  final TextStyle? labelStyle;
  final bool mini;

  // Band ring fills: green → yellow → orange → red (inside → outside)
  static const _bandFills = [
    Color(0x084CAF50),
    Color(0x08FFEB3B),
    Color(0x08FF9800),
    Color(0x08F44336),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final labelGap = mini ? 0.0 : 30.0;
    final radius = math.min(size.width, size.height) * (mini ? 0.40 : 0.32);
    final count = scores.length;

    // --- coloured band rings (filled polygons) ---
    for (var ring = 1; ring <= 4; ring++) {
      canvas.drawPath(
        _polygon(center, radius * ring / 4, count),
        Paint()
          ..color = _bandFills[ring - 1]
          ..style = PaintingStyle.fill,
      );
    }

    // --- grid outlines ---
    final gridPaint = Paint()
      ..color = gridColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.7;
    for (var ring = 1; ring <= 4; ring++) {
      canvas.drawPath(_polygon(center, radius * ring / 4, count), gridPaint);
    }
    for (var i = 0; i < count; i++) {
      canvas.drawLine(center, _pt(center, radius, i, count), gridPaint);
    }

    // --- data polygon: radial gradient fill ---
    final dataPath = _dataPolygon(center, radius);
    final gradientRect = Rect.fromCenter(
      center: center,
      width: size.width,
      height: size.height,
    );
    canvas.drawPath(
      dataPath,
      Paint()
        ..shader = RadialGradient(
          colors: [
            primaryColor.withValues(alpha: 0.40),
            primaryColor.withValues(alpha: 0.06),
          ],
        ).createShader(gradientRect)
        ..style = PaintingStyle.fill,
    );

    // --- data polygon: stroke ---
    canvas.drawPath(
      dataPath,
      Paint()
        ..color = primaryColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = mini ? 1.6 : 2.2
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round,
    );

    // --- value dots ---
    for (var i = 0; i < count; i++) {
      final vr = radius * (scores[i].percent.clamp(0, 100) / 100);
      final pt = _pt(center, vr, i, count);
      canvas.drawCircle(
        pt,
        mini ? 2.4 : 5.0,
        Paint()..color = primaryColor,
      );
      if (!mini) {
        canvas.drawCircle(pt, 2.2, Paint()..color = Colors.white);
      }
    }

    // --- labels (non-mini only) ---
    if (labelStyle != null) {
      for (var i = 0; i < count; i++) {
        final lp = _pt(center, radius + labelGap, i, count);
        final painter = TextPainter(
          text: TextSpan(text: scores[i].shortLabel, style: labelStyle),
          textAlign: TextAlign.center,
          textDirection: TextDirection.ltr,
          maxLines: 2,
        )..layout(maxWidth: 70);
        painter.paint(
          canvas,
          lp - Offset(painter.width / 2, painter.height / 2),
        );
      }
    }
  }

  Path _polygon(Offset center, double r, int count) {
    final path = Path();
    for (var i = 0; i < count; i++) {
      final p = _pt(center, r, i, count);
      i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
    }
    return path..close();
  }

  Path _dataPolygon(Offset center, double radius) {
    final path = Path();
    for (var i = 0; i < scores.length; i++) {
      final vr = radius * (scores[i].percent.clamp(0, 100) / 100);
      final p = _pt(center, vr, i, scores.length);
      i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
    }
    return path..close();
  }

  Offset _pt(Offset center, double r, int i, int count) {
    final angle = -math.pi / 2 + (math.pi * 2 * i / count);
    return Offset(
      center.dx + math.cos(angle) * r,
      center.dy + math.sin(angle) * r,
    );
  }

  @override
  bool shouldRepaint(covariant _ReflexRadarPainter old) =>
      old.scores != scores || old.primaryColor != primaryColor;
}

// ---------------------------------------------------------------------------
// Shared label helpers (used in result screen and progress card)
// ---------------------------------------------------------------------------

String reflexLabel(String key, [String locale = 'de']) {
  for (final reflex in PrimitiveReflex.values) {
    if (reflex.name == key) return reflex.label(locale);
  }
  return key;
}

String reflexShortLabel(String key, [String locale = 'de']) {
  for (final reflex in PrimitiveReflex.values) {
    if (reflex.name == key) return reflex.shortLabel(locale);
  }
  return key;
}

/// Converts assessment.scores map to a sorted list of [ReflexRadarScore].
List<ReflexRadarScore> radarScoresFromAssessment(
  Map<String, dynamic> scores, [
  String locale = 'de',
]) {
  final rows = <ReflexRadarScore>[];
  for (final entry in scores.entries) {
    final raw = entry.value;
    if (raw is! Map) continue;
    final percent = (raw['percent'] as num?)?.toDouble() ?? 0;
    rows.add(ReflexRadarScore(
      label: reflexLabel(entry.key, locale),
      shortLabel: reflexShortLabel(entry.key, locale),
      percent: percent,
    ));
  }
  rows.sort((a, b) => b.percent.compareTo(a.percent));
  return rows;
}
