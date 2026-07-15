import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';

class ParallelLinesVisualizer extends StatefulWidget {
  final Duration moveDuration;
  final Duration holdDuration;
  final int repetitions;
  final bool simultaneous;
  final bool autoplay;

  const ParallelLinesVisualizer({
    super.key,
    required this.moveDuration,
    required this.holdDuration,
    required this.repetitions,
    required this.simultaneous,
    this.autoplay = true,
  });

  @override
  State<ParallelLinesVisualizer> createState() =>
      _ParallelLinesVisualizerState();
}

class _ParallelLinesVisualizerState extends State<ParallelLinesVisualizer>
    with SingleTickerProviderStateMixin {
  static const double _leftX = -0.85;
  static const double _rightX = 0.85;

  late final AnimationController _controller;
  bool _running = false;
  bool _disposed = false;

  int _rep = 0;

  // Normalized positions [-1..1]
  double _aX = _rightX;
  double _bX = _rightX;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this);
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
    setState(() => _running = true);
    _rep = 0;
    _aX = _rightX;
    _bX = _rightX;

    while (_running && !_disposed && _rep < widget.repetitions) {
      await Future.delayed(widget.holdDuration);
      if (!_running || _disposed) break;

      if (widget.simultaneous) {
        await _moveBoth(to: _leftX);
        if (!_running || _disposed) break;
        await Future.delayed(widget.holdDuration);
        await _moveBoth(to: _rightX);
        if (!_running || _disposed) break;
        await Future.delayed(widget.holdDuration);
      } else {
        await _moveOne(isA: true, to: _leftX);
        if (!_running || _disposed) break;
        await Future.delayed(widget.holdDuration);
        await _moveOne(isA: true, to: _rightX);
        if (!_running || _disposed) break;
        await Future.delayed(widget.holdDuration);

        await _moveOne(isA: false, to: _leftX);
        if (!_running || _disposed) break;
        await Future.delayed(widget.holdDuration);
        await _moveOne(isA: false, to: _rightX);
        if (!_running || _disposed) break;
        await Future.delayed(widget.holdDuration);
      }

      if (!mounted) break;
      setState(() => _rep++);
    }

    if (!_disposed && mounted) {
      setState(() => _running = false);
    }
  }

  Future<void> _moveOne({required bool isA, required double to}) async {
    final from = isA ? _aX : _bX;
    _controller
      ..duration = widget.moveDuration
      ..reset();
    final animation = Tween<double>(begin: from, end: to).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutCubic),
    );
    void listener() {
      if (!_running || _disposed) return;
      setState(() {
        if (isA) {
          _aX = animation.value;
        } else {
          _bX = animation.value;
        }
      });
    }

    animation.addListener(listener);
    await _controller.forward();
    animation.removeListener(listener);
    if (isA) {
      _aX = to;
    } else {
      _bX = to;
    }
  }

  Future<void> _moveBoth({required double to}) async {
    final fromA = _aX;
    final fromB = _bX;
    _controller
      ..duration = widget.moveDuration
      ..reset();
    final aAnim = Tween<double>(begin: fromA, end: to).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutCubic),
    );
    final bAnim = Tween<double>(begin: fromB, end: to).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutCubic),
    );
    void listener() {
      if (!_running || _disposed) return;
      setState(() {
        _aX = aAnim.value;
        _bX = bAnim.value;
      });
    }

    _controller.addListener(listener);
    await _controller.forward();
    _controller.removeListener(listener);
    _aX = to;
    _bX = to;
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
            painter: _ParallelLinesPainter(
              aX: _aX,
              bX: _bX,
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

class _ParallelLinesPainter extends CustomPainter {
  final double aX;
  final double bX;
  final Color lineColor;
  final Color ballColor;
  final Color glowColor;

  _ParallelLinesPainter({
    required this.aX,
    required this.bX,
    required this.lineColor,
    required this.ballColor,
    required this.glowColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final yTop = size.height * 0.38;
    final yBottom = size.height * 0.62;
    final left = size.width * 0.12;
    final right = size.width * 0.88;

    final paintLine = Paint()
      ..color = lineColor
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(left, yTop), Offset(right, yTop), paintLine);
    canvas.drawLine(Offset(left, yBottom), Offset(right, yBottom), paintLine);

    Offset toPx(double xNorm, double y) {
      final t = (xNorm + 1) * 0.5;
      return Offset(ui.lerpDouble(left, right, t)!, y);
    }

    _drawBall(canvas, toPx(aX, yTop));
    _drawBall(canvas, toPx(bX, yBottom));
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
  bool shouldRepaint(covariant _ParallelLinesPainter oldDelegate) {
    return oldDelegate.aX != aX ||
        oldDelegate.bX != bX ||
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
