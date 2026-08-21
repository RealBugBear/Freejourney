import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// One deterministic branch. Left tips only from left trunk origins; right
/// tips only from right. [trunkT] is 0 at the base, 1 at the tip.
class ImpactTreeBranch {
  const ImpactTreeBranch({
    required this.trunkT,
    required this.left,
    required this.tip,
  });

  final double trunkT;
  final bool left;
  final Offset tip;
}

/// Fixed branch layout for the impact tree (deterministic for golden tests).
class ImpactTreeLayout {
  ImpactTreeLayout._();

  static const int maxVisibleBranches = 12;

  /// After 12 branches, growth continues only via canopy densification.
  /// Tier 0: ≤12 · tier 1: 13–24 · tier 2: ≥25.
  static int crownTier(int activatedCount) {
    if (activatedCount <= 12) return 0;
    if (activatedCount < 25) return 1;
    return 2;
  }

  static const Offset trunkBase = Offset(0.50, 0.92);
  static const Offset trunkTip = Offset(0.50, 0.36);

  /// Compact seedling: short stem + two leaves forming a soft Y.
  static const Offset sproutBase = Offset(0.50, 0.68);
  static const Offset sproutBend = Offset(0.45, 0.50);
  static const Offset sproutTip = Offset(0.50, 0.36);
  static const Offset sproutLeafLeft = Offset(0.36, 0.30);
  static const Offset sproutLeafRight = Offset(0.64, 0.30);

  /// Staggered origins climbing the trunk. Tips stay on their own side.
  static const List<ImpactTreeBranch> branches = [
    ImpactTreeBranch(trunkT: 0.14, left: true, tip: Offset(0.22, 0.74)),
    ImpactTreeBranch(trunkT: 0.20, left: false, tip: Offset(0.78, 0.72)),
    ImpactTreeBranch(trunkT: 0.28, left: true, tip: Offset(0.16, 0.62)),
    ImpactTreeBranch(trunkT: 0.34, left: false, tip: Offset(0.84, 0.60)),
    ImpactTreeBranch(trunkT: 0.42, left: true, tip: Offset(0.18, 0.50)),
    ImpactTreeBranch(trunkT: 0.48, left: false, tip: Offset(0.82, 0.48)),
    ImpactTreeBranch(trunkT: 0.56, left: true, tip: Offset(0.24, 0.40)),
    ImpactTreeBranch(trunkT: 0.62, left: false, tip: Offset(0.76, 0.38)),
    ImpactTreeBranch(trunkT: 0.70, left: true, tip: Offset(0.30, 0.30)),
    ImpactTreeBranch(trunkT: 0.76, left: false, tip: Offset(0.70, 0.28)),
    ImpactTreeBranch(trunkT: 0.84, left: true, tip: Offset(0.36, 0.22)),
    ImpactTreeBranch(trunkT: 0.88, left: false, tip: Offset(0.64, 0.20)),
  ];
}

/// Paints a quiet growing tree. No randomness — [branchCount] and [crownTier]
/// alone drive the image. [revealProgress] (0…1) animates only the newest
/// branch when the count just increased.
class ImpactTreePainter extends CustomPainter {
  ImpactTreePainter({
    required this.branchCount,
    required this.crownTier,
    required this.revealProgress,
    required this.trunkColor,
    required this.branchColor,
    required this.canopyColor,
  })  : assert(branchCount >= 0),
        assert(crownTier >= 0 && crownTier <= 2),
        assert(revealProgress >= 0 && revealProgress <= 1);

  final int branchCount;

  /// 0 ≤12 activations, 1 = 13–24, 2 = ≥25. Caps canopy densification.
  final int crownTier;
  final double revealProgress;
  final Color trunkColor;
  final Color branchColor;
  final Color canopyColor;

  @override
  void paint(Canvas canvas, Size size) {
    final visible = branchCount.clamp(0, ImpactTreeLayout.maxVisibleBranches);
    if (visible == 0) {
      _paintSprout(canvas, size);
      return;
    }

    final trunkPaint = Paint()
      ..color = trunkColor
      ..strokeWidth = size.shortestSide * 0.05
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final base = _scale(ImpactTreeLayout.trunkBase, size);
    final tip = _scale(ImpactTreeLayout.trunkTip, size);
    canvas.drawLine(base, tip, trunkPaint);

    final branchPaint = Paint()
      ..color = branchColor
      ..strokeWidth = size.shortestSide * 0.022
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final leafPaint = Paint()
      ..color = canopyColor
      ..style = PaintingStyle.fill;

    for (var i = 0; i < visible; i++) {
      final isNewest = i == visible - 1 && revealProgress < 1;
      final t = isNewest ? revealProgress : 1.0;
      if (t <= 0) continue;

      final spec = ImpactTreeLayout.branches[i];
      final side = spec.left ? -1.0 : 1.0;
      // Origin climbs the trunk; slight lateral offset keeps roots on-side.
      final origin = Offset.lerp(base, tip, spec.trunkT)! +
          Offset(side * size.width * 0.025, 0);
      final end = _scale(spec.tip, size);

      // Cubic: go out first, then gently up to the tip — never crosses midline.
      final c1 = Offset(
        origin.dx + side * size.width * 0.16,
        origin.dy - size.height * 0.02,
      );
      final c2 = Offset(
        end.dx - side * size.width * 0.04,
        end.dy + size.height * 0.06,
      );

      final drawnC1 = Offset.lerp(origin, c1, t)!;
      final drawnC2 = Offset.lerp(origin, c2, t)!;
      final drawnEnd = Offset.lerp(origin, end, t)!;

      final path = Path()
        ..moveTo(origin.dx, origin.dy)
        ..cubicTo(
          drawnC1.dx,
          drawnC1.dy,
          drawnC2.dx,
          drawnC2.dy,
          drawnEnd.dx,
          drawnEnd.dy,
        );
      canvas.drawPath(path, branchPaint);

      if (t > 0.5) {
        final leafT = ((t - 0.5) / 0.5).clamp(0.0, 1.0);
        _drawLeaf(
          canvas,
          drawnEnd,
          size.shortestSide * 0.038 * leafT,
          leafPaint,
          angle: side * 0.9,
        );
      }
    }

    _paintCrown(canvas, tip, size, crownTier);
  }

  void _paintSprout(Canvas canvas, Size size) {
    final stemPaint = Paint()
      ..color = trunkColor
      ..strokeWidth = size.shortestSide * 0.044
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final base = _scale(ImpactTreeLayout.sproutBase, size);
    final bend = _scale(ImpactTreeLayout.sproutBend, size);
    final tip = _scale(ImpactTreeLayout.sproutTip, size);

    final stem = Path()
      ..moveTo(base.dx, base.dy)
      ..quadraticBezierTo(bend.dx, bend.dy, tip.dx, tip.dy);
    canvas.drawPath(stem, stemPaint);

    final leafPaint = Paint()
      ..color = canopyColor
      ..style = PaintingStyle.fill;
    final petiolePaint = Paint()
      ..color = branchColor
      ..strokeWidth = size.shortestSide * 0.022
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final left = _scale(ImpactTreeLayout.sproutLeafLeft, size);
    final right = _scale(ImpactTreeLayout.sproutLeafRight, size);
    canvas.drawLine(tip, left, petiolePaint);
    canvas.drawLine(tip, right, petiolePaint);

    final leafR = size.shortestSide * 0.07;
    _drawLeaf(canvas, left, leafR, leafPaint, angle: -1.0);
    _drawLeaf(canvas, right, leafR, leafPaint, angle: 1.0);
  }

  void _paintCrown(Canvas canvas, Offset tip, Size size, int tier) {
    final paint = Paint()
      ..color = canopyColor.withValues(alpha: 0.92)
      ..style = PaintingStyle.fill;
    final r = size.shortestSide;
    final scale = 1.0 + tier * 0.12;
    final c = tip + Offset(0, -r * (0.045 + tier * 0.01));

    // Base triad — always present once any branch exists.
    canvas.drawCircle(c, r * 0.075 * scale, paint);
    canvas.drawCircle(
      c + Offset(-r * 0.055 * scale, r * 0.02),
      r * 0.055 * scale,
      paint,
    );
    canvas.drawCircle(
      c + Offset(r * 0.055 * scale, r * 0.02),
      r * 0.055 * scale,
      paint,
    );

    if (tier >= 1) {
      // First densification: fill gaps above and beside the triad.
      canvas.drawCircle(
        c + Offset(0, -r * 0.05 * scale),
        r * 0.05 * scale,
        paint,
      );
      canvas.drawCircle(
        c + Offset(-r * 0.09 * scale, -r * 0.01),
        r * 0.045 * scale,
        paint,
      );
      canvas.drawCircle(
        c + Offset(r * 0.09 * scale, -r * 0.01),
        r * 0.045 * scale,
        paint,
      );
    }

    if (tier >= 2) {
      // Second densification: outer halo, still a compact crown.
      canvas.drawCircle(
        c + Offset(-r * 0.12 * scale, r * 0.035),
        r * 0.04 * scale,
        paint,
      );
      canvas.drawCircle(
        c + Offset(r * 0.12 * scale, r * 0.035),
        r * 0.04 * scale,
        paint,
      );
      canvas.drawCircle(
        c + Offset(0, r * 0.05 * scale),
        r * 0.042 * scale,
        paint,
      );
      canvas.drawCircle(
        c + Offset(-r * 0.06 * scale, -r * 0.055 * scale),
        r * 0.038 * scale,
        paint,
      );
      canvas.drawCircle(
        c + Offset(r * 0.06 * scale, -r * 0.055 * scale),
        r * 0.038 * scale,
        paint,
      );
    }
  }

  void _drawLeaf(
    Canvas canvas,
    Offset center,
    double radius,
    Paint paint, {
    double angle = 0,
  }) {
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(angle);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset.zero,
        width: radius * 1.9,
        height: radius * 1.2,
      ),
      paint,
    );
    canvas.restore();
  }

  Offset _scale(Offset n, Size size) =>
      Offset(n.dx * size.width, n.dy * size.height);

  @override
  bool shouldRepaint(covariant ImpactTreePainter oldDelegate) {
    return oldDelegate.branchCount != branchCount ||
        oldDelegate.crownTier != crownTier ||
        oldDelegate.revealProgress != revealProgress ||
        oldDelegate.trunkColor != trunkColor ||
        oldDelegate.branchColor != branchColor ||
        oldDelegate.canopyColor != canopyColor;
  }
}

/// Theme-aware colors for the impact tree.
({Color trunk, Color branch, Color canopy}) impactTreeColors(
  Brightness brightness,
) {
  if (brightness == Brightness.dark) {
    return (
      trunk: AppColors.primaryLight,
      branch: AppColors.primaryOnDark,
      canopy: AppColors.primaryLight,
    );
  }
  return (
    trunk: AppColors.primaryDark,
    branch: AppColors.primary,
    canopy: AppColors.primaryLight,
  );
}
