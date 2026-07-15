import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';

class ArcSwapVisualizer extends StatefulWidget {
  final Duration interval;
  final Duration? holdDuration;
  final int repetitions;
  final bool autoplay;

  const ArcSwapVisualizer({
    super.key,
    required this.interval,
    this.holdDuration,
    required this.repetitions,
    this.autoplay = true,
  });

  @override
  State<ArcSwapVisualizer> createState() => _ArcSwapVisualizerState();
}

class _ArcSwapVisualizerState extends State<ArcSwapVisualizer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool _running = false;
  bool _disposed = false;

  int _rep = 0;
  bool _aTurn = true;
  double _t = 0.0;
  _Phase _phase = _Phase.idle;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this);
    _controller.addListener(() {
      if (!_running || _disposed) return;
      setState(() => _t = _controller.value);
    });
    if (widget.autoplay) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        unawaited(_run());
      });
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _running = false;
    _controller.dispose();
    super.dispose();
  }

  Future<void> _run() async {
    if (_running) return;
    setState(() {
      _running = true;
      _rep = 0;
      _aTurn = true;
      _phase = _Phase.idle;
      _t = 0.0;
    });

    while (_running && !_disposed && _rep < widget.repetitions) {
      await _move(_Phase.movingToOther);
      if (!_running || _disposed) break;
      await _hold(_Phase.holdingOnOther);
      if (!_running || _disposed) break;
      await _move(_Phase.movingBack);
      if (!_running || _disposed) break;
      await _hold(_Phase.holdingAtHome);
      if (!_running || _disposed) break;

      // Switch actor after full arc cycle.
      _aTurn = !_aTurn;
      if (_aTurn) {
        setState(() => _rep++);
      }
    }

    if (!_disposed && mounted) {
      setState(() {
        _running = false;
        _phase = _Phase.idle;
        _t = 0.0;
      });
    }
  }

  Future<void> _move(_Phase nextPhase) async {
    setState(() {
      _phase = nextPhase;
      _t = 0.0;
    });
    _controller
      ..duration = widget.interval
      ..reset();
    await _controller.forward();
  }

  Future<void> _hold(_Phase holdPhase) async {
    setState(() => _phase = holdPhase);
    await Future.delayed(widget.holdDuration ?? widget.interval);
  }

  void _stop() {
    _running = false;
    _controller.stop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final isLight = theme.brightness == Brightness.light;
    final lineColor = isLight
        ? theme.colorScheme.primary.withOpacity(0.25)
        : Colors.white.withOpacity(0.20);
    final ballColor = isLight ? theme.colorScheme.primary : Colors.white;
    final glowColor = isLight
        ? theme.colorScheme.primary.withOpacity(0.35)
        : Colors.white.withOpacity(0.35);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 180,
          width: double.infinity,
          child: CustomPaint(
            painter: _ArcSwapPainter(
              phase: _phase,
              t: _t,
              aTurn: _aTurn,
              lineColor: lineColor,
              ballColor: ballColor,
              glowColor: glowColor,
            ),
          ),
        ),
        const SizedBox(height: 12),
        _RepDots(
            count: widget.repetitions,
            filled: _rep,
            color: theme.colorScheme.primary),
        const SizedBox(height: 8),
        FilledButton.icon(
          onPressed: () {
            if (_running) {
              setState(_stop);
            } else {
              unawaited(_run());
            }
          },
          icon: Icon(_running ? Icons.pause : Icons.play_arrow),
          label: Text(
            _running ? l10n.trainingPause : l10n.trainingRestart,
          ),
        ),
      ],
    );
  }
}

enum _Phase { idle, movingToOther, holdingOnOther, movingBack, holdingAtHome }

class _ArcSwapPainter extends CustomPainter {
  final _Phase phase;
  final double t;
  final bool aTurn;
  final Color lineColor;
  final Color ballColor;
  final Color glowColor;

  _ArcSwapPainter({
    required this.phase,
    required this.t,
    required this.aTurn,
    required this.lineColor,
    required this.ballColor,
    required this.glowColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Bring the two balls closer together.
    final left = Offset(size.width * 0.38, size.height * 0.62);
    final right = Offset(size.width * 0.62, size.height * 0.62);

    // Land on the other ball at ~2 o'clock / 10 o'clock (tangent-ish, less overlap).
    const landingDx = 14.0;
    const landingDy = -24.0;
    final landOnRight = right + const Offset(landingDx, landingDy);
    final landOnLeft = left + const Offset(-landingDx, landingDy);
    final landingOffset = aTurn
        ? const Offset(landingDx, landingDy) // onto right ball (2 o'clock)
        : const Offset(-landingDx, landingDy); // onto left ball (10 o'clock)

    final start = aTurn ? left : right;
    final endBase = aTurn ? right : left;
    final endLanding = endBase + landingOffset;
    final center = Offset(size.width * 0.50, size.height * 0.18);
    final bias = size.width * 0.08;
    final control =
        aTurn ? center.translate(bias, 0) : center.translate(-bias, 0);

    // Draw guide paths (∞-like, rotated 8 feel): two inverted U curves with opposite lean.
    final guidePaint = Paint()
      ..color = lineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;
    final guideA = Path()
      ..moveTo(left.dx, left.dy)
      ..quadraticBezierTo(
          center.dx + bias, center.dy, landOnRight.dx, landOnRight.dy);
    final guideB = Path()
      ..moveTo(right.dx, right.dy)
      ..quadraticBezierTo(
          center.dx - bias, center.dy, landOnLeft.dx, landOnLeft.dy);
    canvas.drawPath(guideA, guidePaint);
    canvas.drawPath(guideB, guidePaint);

    Offset mover = start;

    if (phase == _Phase.movingToOther) {
      mover =
          _quad(start, control, endLanding, Curves.easeInOutCubic.transform(t));
    } else if (phase == _Phase.movingBack) {
      mover =
          _quad(endLanding, control, start, Curves.easeInOutCubic.transform(t));
    } else if (phase == _Phase.holdingOnOther) {
      mover = endLanding;
    } else if (phase == _Phase.holdingAtHome) {
      mover = start;
    }

    // Draw the stationary ball (always on its base spot).
    _drawBall(canvas, aTurn ? right : left);

    // Draw the moving ball (path already lands on the 2/10 o'clock point).
    _drawBall(canvas, mover);
  }

  Offset _quad(Offset p0, Offset p1, Offset p2, double t) {
    final u = 1 - t;
    return (p0 * (u * u)) + (p1 * (2 * u * t)) + (p2 * (t * t));
  }

  void _drawBall(Canvas canvas, Offset center) {
    final glow = Paint()
      ..color = glowColor
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14);
    canvas.drawCircle(center, 18, glow);
    final fill = Paint()..color = ballColor;
    canvas.drawCircle(center, 14, fill);
  }

  @override
  bool shouldRepaint(covariant _ArcSwapPainter oldDelegate) {
    return oldDelegate.phase != phase ||
        oldDelegate.t != t ||
        oldDelegate.aTurn != aTurn ||
        oldDelegate.lineColor != lineColor ||
        oldDelegate.ballColor != ballColor ||
        oldDelegate.glowColor != glowColor;
  }
}

class _RepDots extends StatelessWidget {
  final int count;
  final int filled;
  final Color color;

  const _RepDots({
    required this.count,
    required this.filled,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (i) {
        final isFilled = i < filled;
        return Container(
          width: 10,
          height: 10,
          margin: EdgeInsets.only(left: i == 0 ? 0 : 8),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isFilled ? color : color.withOpacity(0.22),
          ),
        );
      }),
    );
  }
}
