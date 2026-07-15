import 'dart:async';
import 'dart:ui' as ui;
import 'dart:math' as math;

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';

enum RhythmPattern { v, i }

class RhythmConfig {
  final RhythmPattern pattern;
  final Duration interval;
  final int repetitions;
  final Duration? moveUp;
  final Duration? moveDown;
  final Duration? holdTop;
  final Duration? holdBottom;

  const RhythmConfig({
    required this.pattern,
    required this.interval,
    required this.repetitions,
    this.moveUp,
    this.moveDown,
    this.holdTop,
    this.holdBottom,
  });
}

class RhythmVisualizer extends StatefulWidget {
  final RhythmConfig config;
  final bool autoplay;
  final Duration autoplayDelay;
  final double height;
  final bool enableAudio;

  const RhythmVisualizer({
    super.key,
    required this.config,
    this.autoplay = false,
    this.autoplayDelay = Duration.zero,
    this.height = 220,
    this.enableAudio = true,
  });

  @override
  State<RhythmVisualizer> createState() => _RhythmVisualizerState();
}

class _RhythmVisualizerState extends State<RhythmVisualizer>
    with TickerProviderStateMixin {
  late final AnimationController _controller;
  AnimationController? _breathController;
  late Animation<Offset> _move;

  final _arrivePlayer = AudioPlayer();
  final _holdEndPlayer = AudioPlayer();
  late final Future<void> _audioReady;

  _RunState _runState = _RunState.idle;
  bool _disposed = false;

  int _repIndex = 0;
  int _segmentIndex = 0;

  Offset _current = const Offset(0, 0);
  Offset _target = const Offset(0, 0);

  _RhythmPhase _phase = _RhythmPhase.idle;

  Timer? _holdTimer;
  DateTime? _holdEndsAt;
  Duration _holdRemaining = Duration.zero;

  Duration _moveRemaining = Duration.zero;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this);
    _breathController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 240),
    );
    _move = const AlwaysStoppedAnimation(Offset(0, 0));
    _audioReady = _initAudio();
    _resetPositions();
    if (widget.autoplay) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (widget.autoplayDelay > Duration.zero) {
          Future<void>.delayed(widget.autoplayDelay, () {
            if (!mounted) return;
            _startNew();
          });
        } else {
          _startNew();
        }
      });
    }
  }

  @override
  void didUpdateWidget(RhythmVisualizer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.config.pattern != widget.config.pattern) {
      _stop(reset: true);
      _resetPositions();
      return;
    }

    if (oldWidget.config.repetitions != widget.config.repetitions ||
        oldWidget.config.moveUp != widget.config.moveUp ||
        oldWidget.config.moveDown != widget.config.moveDown ||
        oldWidget.config.holdTop != widget.config.holdTop ||
        oldWidget.config.holdBottom != widget.config.holdBottom) {
      _stop(reset: true);
      _resetPositions();
    }
  }

  void _resetPositions() {
    _repIndex = 0;
    _segmentIndex = 0;
    final anchors = _anchorsFor(widget.config.pattern);
    _current = widget.config.pattern == RhythmPattern.i
        ? anchors.bottom
        : anchors.center;
    _target = _current;
    _phase = _RhythmPhase.idle;
    _move = AlwaysStoppedAnimation(_current);
  }

  Future<void> _initAudio() async {
    try {
      final mixedAudioContext = AudioContextConfig(
        focus: AudioContextConfigFocus.mixWithOthers,
      ).build();
      await _arrivePlayer.setAudioContext(mixedAudioContext);
      await _holdEndPlayer.setAudioContext(mixedAudioContext);
      await _arrivePlayer.setReleaseMode(ReleaseMode.stop);
      await _holdEndPlayer.setReleaseMode(ReleaseMode.stop);
      await _arrivePlayer.setPlayerMode(PlayerMode.lowLatency);
      await _holdEndPlayer.setPlayerMode(PlayerMode.lowLatency);
    } catch (e) {
      // Don't crash the UI; just run silently if audio can't be initialized.
      debugPrint('[RhythmVisualizer] Failed to init audio: $e');
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _stop(reset: false);
    _controller.dispose();
    _breathController?.dispose();
    unawaited(_arrivePlayer.dispose());
    unawaited(_holdEndPlayer.dispose());
    super.dispose();
  }

  void _startNew() {
    if (_runState == _RunState.running) return;
    _stop(reset: true);
    setState(() {
      _resetPositions();
      _runState = _RunState.running;
    });
    unawaited(_playArrive());
    _startHoldFromCurrent();
  }

  void _pause() {
    if (_runState != _RunState.running) return;
    setState(() => _runState = _RunState.paused);

    // Pause hold timer, keeping remaining duration.
    final holdEndsAt = _holdEndsAt;
    if (_holdTimer != null && holdEndsAt != null) {
      _holdTimer?.cancel();
      _holdTimer = null;
      final remaining = holdEndsAt.difference(DateTime.now());
      _holdRemaining = remaining.isNegative ? Duration.zero : remaining;
      _holdEndsAt = null;
      _breathController?.stop();
      return;
    }

    // Pause movement, keeping remaining duration and current position.
    if (_isMovingPhase(_phase)) {
      _current = _move.value;
      final d = _controller.duration ?? Duration.zero;
      _moveRemaining = Duration(
        microseconds: (d.inMicroseconds * (1 - _controller.value)).round(),
      );
      if (_moveRemaining.isNegative) _moveRemaining = Duration.zero;
      _controller.stop();
      _breathController?.stop();
    }
  }

  void _resume() {
    if (_runState != _RunState.paused) return;
    setState(() => _runState = _RunState.running);

    if (_holdRemaining > Duration.zero && _isHoldingPhase(_phase)) {
      _startHoldFromCurrent(durationOverride: _holdRemaining);
      _holdRemaining = Duration.zero;
      return;
    }

    if (_moveRemaining > Duration.zero && _isMovingPhase(_phase)) {
      _startMoveTo(_target, durationOverride: _moveRemaining);
      _moveRemaining = Duration.zero;
      return;
    }

    // Fallback if we paused in an unexpected state.
    _advance();
  }

  void _stop({required bool reset}) {
    _holdTimer?.cancel();
    _holdTimer = null;
    _holdEndsAt = null;
    _holdRemaining = Duration.zero;
    _moveRemaining = Duration.zero;
    _controller.stop();
    _breathController?.stop();
    if (reset) {
      _runState = _RunState.idle;
      _phase = _RhythmPhase.idle;
      _segmentIndex = 0;
      _repIndex = 0;
    } else {
      _runState = _RunState.idle;
    }
  }

  void _advance() {
    if (_disposed || _runState != _RunState.running) return;

    if (_repIndex >= widget.config.repetitions) {
      setState(() => _runState = _RunState.idle);
      return;
    }

    final steps = _sequenceFor(widget.config.pattern);
    if (_segmentIndex >= steps.length) {
      _segmentIndex = 0;
      setState(() => _repIndex++);
      if (_repIndex >= widget.config.repetitions) {
        setState(() => _runState = _RunState.idle);
        return;
      }
    }

    final next = steps[_segmentIndex];
    _segmentIndex++;
    _startMoveTo(next);
  }

  void _startMoveTo(Offset next, {Duration? durationOverride}) {
    if (_disposed || _runState != _RunState.running) return;

    _target = next;
    final duration = durationOverride ?? _moveDurationFor(next);

    if (widget.config.pattern == RhythmPattern.i) {
      final isUp = _target.dy < _current.dy;
      _phase = isUp ? _RhythmPhase.movingUp : _RhythmPhase.movingDown;
    } else {
      _phase = _RhythmPhase.moving;
    }

    _move = Tween<Offset>(begin: _current, end: _target).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutCubic),
    );

    _controller
      ..duration = duration
      ..reset();

    void statusListener(AnimationStatus status) {
      if (status != AnimationStatus.completed) return;
      _controller.removeStatusListener(statusListener);
      if (_disposed || _runState != _RunState.running) return;
      _current = _target;
      unawaited(_playArrive());
      _startHoldFromCurrent();
    }

    _controller.addStatusListener(statusListener);
    _controller.forward();
    setState(() {});
  }

  Duration _moveDurationFor(Offset next) {
    if (widget.config.pattern != RhythmPattern.i) return widget.config.interval;
    final isUp = next.dy < _current.dy;
    return isUp
        ? (widget.config.moveUp ?? widget.config.interval)
        : (widget.config.moveDown ?? widget.config.interval);
  }

  void _startHoldFromCurrent({Duration? durationOverride}) {
    if (_disposed || _runState != _RunState.running) return;

    final holdDuration = durationOverride ?? _holdDurationForCurrent();
    _holdRemaining = Duration.zero;

    if (widget.config.pattern == RhythmPattern.i) {
      final anchors = _anchorsFor(widget.config.pattern);
      final nextPhase = _current == anchors.bottom
          ? _RhythmPhase.holdingBottom
          : _RhythmPhase.holdingTop;
      _phase = nextPhase;

      if (nextPhase == _RhythmPhase.holdingBottom) {
        final breath = _breathController;
        if (breath != null) {
          // Resume breath from its current value if we're resuming a paused hold.
          final currentValue = breath.value;
          breath.duration = holdDuration;
          if (currentValue == 0) {
            breath
              ..reset()
              ..forward();
          } else {
            breath.forward();
          }
        }
      } else {
        final breath = _breathController;
        if (breath != null) breath.value = 0;
      }
    } else {
      _phase = _RhythmPhase.holding;
    }

    _holdEndsAt = DateTime.now().add(holdDuration);
    _holdTimer?.cancel();
    _holdTimer = Timer(holdDuration, () async {
      if (_disposed || _runState != _RunState.running) return;
      _holdTimer = null;
      _holdEndsAt = null;
      await _playHoldEnd();
      if (_disposed || _runState != _RunState.running) return;
      _advance();
    });

    setState(() {});
  }

  Duration _holdDurationForCurrent() {
    if (widget.config.pattern == RhythmPattern.v) {
      // V pattern should feel continuous: keep only a short initial settle,
      // then remove endpoint pauses between moves.
      return _segmentIndex == 0
          ? const Duration(milliseconds: 350)
          : Duration.zero;
    }
    if (widget.config.pattern != RhythmPattern.i) return widget.config.interval;
    final anchors = _anchorsFor(widget.config.pattern);
    return _current == anchors.bottom
        ? (widget.config.holdBottom ?? widget.config.interval)
        : (widget.config.holdTop ?? widget.config.interval);
  }

  bool _isHoldingPhase(_RhythmPhase phase) {
    return phase == _RhythmPhase.holding ||
        phase == _RhythmPhase.holdingBottom ||
        phase == _RhythmPhase.holdingTop;
  }

  bool _isMovingPhase(_RhythmPhase phase) {
    return phase == _RhythmPhase.moving ||
        phase == _RhythmPhase.movingUp ||
        phase == _RhythmPhase.movingDown;
  }

  Future<void> _playArrive() async {
    if (!widget.enableAudio) return;
    try {
      await _audioReady;
      await _arrivePlayer.stop();
      await _arrivePlayer.play(
        AssetSource('sounds/rhythm_arrive.wav'),
        mode: PlayerMode.lowLatency,
      );
    } catch (e) {
      debugPrint('[RhythmVisualizer] Arrive sound failed: $e');
    }
  }

  Future<void> _playHoldEnd() async {
    if (!widget.enableAudio) return;
    try {
      await _audioReady;
      await _holdEndPlayer.stop();
      await _holdEndPlayer.play(
        AssetSource('sounds/rhythm_hold_end.wav'),
        mode: PlayerMode.lowLatency,
      );
    } catch (e) {
      debugPrint('[RhythmVisualizer] Hold-end sound failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final anchors = _anchorsFor(widget.config.pattern);
    final isLight = theme.brightness == Brightness.light;
    final pathColor = isLight
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
          height: widget.height,
          width: double.infinity,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final size = Size(constraints.maxWidth, constraints.maxHeight);
              final painter = _RhythmPainter(
                pattern: widget.config.pattern,
                anchors: anchors,
                color: pathColor,
              );

              return Stack(
                children: [
                  CustomPaint(size: size, painter: painter),
                  AnimatedBuilder(
                    animation: Listenable.merge(
                      [
                        _controller,
                        if (_breathController != null) _breathController!,
                      ],
                    ),
                    builder: (context, child) {
                      final breath = _breathController;
                      final pos = _move.value;
                      final pixel = _toPixel(pos, size);
                      final scale = _ballScale(
                        pattern: widget.config.pattern,
                        anchors: anchors,
                        t: _controller.value,
                        breathT: breath?.value ?? 0.0,
                      );
                      final particlePainter = _ParticlesPainter(
                        pattern: widget.config.pattern,
                        phase: _phase,
                        center: pixel,
                        inhaleT: _phase == _RhythmPhase.holdingBottom
                            ? (breath?.value ?? 0.0)
                            : 0.0,
                        exhaleT: _phase == _RhythmPhase.movingUp
                            ? _controller.value
                            : 0.0,
                        color: ballColor.withOpacity(isLight ? 0.75 : 0.65),
                      );

                      return Stack(
                        children: [
                          Positioned.fill(
                            child: IgnorePointer(
                              child: CustomPaint(
                                painter: particlePainter,
                                isComplex: true,
                              ),
                            ),
                          ),
                          Positioned(
                            left: pixel.dx - 14,
                            top: pixel.dy - 14,
                            child: Transform.scale(
                              scale: scale,
                              child: _Ball(
                                color: ballColor,
                                glow: glowColor,
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        _RepDots(
          count: widget.config.repetitions,
          filled: _repIndex.clamp(0, widget.config.repetitions),
          color: theme.colorScheme.primary,
        ),
        const SizedBox(height: 8),
        FilledButton.icon(
          onPressed: () {
            if (_runState == _RunState.running) {
              _pause();
            } else if (_runState == _RunState.paused) {
              _resume();
            } else {
              _startNew();
            }
          },
          icon: Icon(
            _runState == _RunState.running ? Icons.pause : Icons.play_arrow,
          ),
          label: Text(
            _runState == _RunState.running
                ? l10n.trainingPause
                : _runState == _RunState.paused
                    ? l10n.trainingResume
                    : l10n.trainingRestart,
          ),
        ),
      ],
    );
  }

  double _ballScale({
    required RhythmPattern pattern,
    required _Anchors anchors,
    required double t,
    required double breathT,
  }) {
    if (pattern != RhythmPattern.i) return 1.0;

    // Breathing cue for exercises 6/7:
    // - bottom: inhale (ball inflates)
    // - moving up: exhale (ball shrinks)
    // - moving down: neutral size
    // - top: stays smaller
    const bottomBig = 1.6;
    const topSmall = 0.9;
    const neutral = 1.0;

    switch (_phase) {
      case _RhythmPhase.holdingBottom:
        // Unten: von der kleinen Größe (wie oben) langsam zur großen
        // Atem-Kugel wachsen.
        return ui.lerpDouble(
              topSmall,
              bottomBig,
              Curves.easeOutCubic.transform(breathT),
            ) ??
            bottomBig;
      case _RhythmPhase.movingUp:
        return ui.lerpDouble(
                bottomBig, topSmall, Curves.easeInOut.transform(t)) ??
            topSmall;
      case _RhythmPhase.holdingTop:
        return topSmall;
      case _RhythmPhase.movingDown:
        // Beim Weg nach unten in der gleichen kleinen Größe bleiben.
        return topSmall;
      case _RhythmPhase.moving:
      case _RhythmPhase.holding:
      case _RhythmPhase.idle:
        return neutral;
    }
  }

  Offset _toPixel(Offset alignment, Size size) {
    final dx = (alignment.dx + 1) * 0.5 * size.width;
    final dy = (alignment.dy + 1) * 0.5 * size.height;
    return Offset(dx, dy);
  }

  List<Offset> _sequenceFor(RhythmPattern pattern) {
    final a = _anchorsFor(pattern);
    switch (pattern) {
      case RhythmPattern.v:
        return [
          a.left,
          a.center,
          a.right,
          a.center,
        ];
      case RhythmPattern.i:
        return [
          a.top,
          a.bottom,
        ];
    }
  }

  _Anchors _anchorsFor(RhythmPattern pattern) {
    switch (pattern) {
      case RhythmPattern.v:
        return const _Anchors(
          left: Offset(-0.85, 0.65),
          center: Offset(0.0, -0.45),
          right: Offset(0.85, 0.65),
          top: Offset(0.0, -0.45),
          bottom: Offset(0.0, 0.65),
        );
      case RhythmPattern.i:
        return const _Anchors(
          left: Offset(0.0, 0.7),
          center: Offset(0.0, 0.7),
          right: Offset(0.0, 0.7),
          top: Offset(0.0, -0.7),
          bottom: Offset(0.0, 0.7),
        );
    }
  }
}

enum _RunState { idle, running, paused }

class _ParticlesPainter extends CustomPainter {
  final RhythmPattern pattern;
  final _RhythmPhase phase;
  final Offset center;
  final double inhaleT;
  final double exhaleT;
  final Color color;

  _ParticlesPainter({
    required this.pattern,
    required this.phase,
    required this.center,
    required this.inhaleT,
    required this.exhaleT,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (pattern != RhythmPattern.i) return;

    final tIn = inhaleT.clamp(0.0, 1.0);
    final tOut = exhaleT.clamp(0.0, 1.0);
    if (tIn == 0.0 && tOut == 0.0) return;

    const count = 18;
    const baseRadius = 54.0;

    for (var i = 0; i < count; i++) {
      final seed = i * 9973;
      final angle = (seed % 360) * math.pi / 180.0;
      final jitter = ((seed % 17) - 8) * 0.9;
      final r0 = baseRadius + jitter;

      if (tIn > 0) {
        // Staggered inhale so particles "flow" into the ball.
        final delay = (i / count) * 0.55;
        final local = ((tIn - delay) / (1 - delay)).clamp(0.0, 1.0);
        final tt = Curves.easeOutCubic.transform(local);
        final r = ui.lerpDouble(r0, 0.0, tt) ?? 0.0;
        final p = center + Offset(math.cos(angle) * r, math.sin(angle) * r);
        final pr = ui.lerpDouble(1.6, 0.0, tt) ?? 0.0;
        final alpha = ((1 - local) * 0.85).clamp(0.0, 1.0);
        if (pr > 0 && alpha > 0) {
          canvas.drawCircle(p, pr, Paint()..color = color.withOpacity(alpha));
        }
      }

      if (tOut > 0) {
        // Continuous outward emission while moving up:
        // emulate a stream by looping particle "age" as time advances.
        const emitRate = 3.6; // particles-per-ascent cycle
        final age = (tOut * emitRate + (i / count)) % 1.0; // 0..1
        final tt = Curves.easeOutCubic.transform(age);
        final r = ui.lerpDouble(0.0, r0, tt) ?? r0;
        final p = center + Offset(math.cos(angle) * r, math.sin(angle) * r);
        final pr = ui.lerpDouble(1.6, 0.0, age) ?? 0.0;
        final alpha = ((1 - age) * 0.70).clamp(0.0, 1.0);
        if (pr > 0 && alpha > 0) {
          canvas.drawCircle(p, pr, Paint()..color = color.withOpacity(alpha));
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _ParticlesPainter oldDelegate) {
    return oldDelegate.center != center ||
        oldDelegate.inhaleT != inhaleT ||
        oldDelegate.exhaleT != exhaleT ||
        oldDelegate.color != color ||
        oldDelegate.phase != phase ||
        oldDelegate.pattern != pattern;
  }
}

class _Ball extends StatelessWidget {
  final Color color;
  final Color glow;

  const _Ball({required this.color, required this.glow});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        boxShadow: [
          BoxShadow(
            color: glow,
            blurRadius: 18,
            spreadRadius: 2,
          ),
        ],
      ),
    );
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
        final isOn = i < filled;
        return Container(
          width: 8,
          height: 8,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isOn ? color : color.withOpacity(0.25),
          ),
        );
      }),
    );
  }
}

class _Anchors {
  final Offset left;
  final Offset center;
  final Offset right;
  final Offset top;
  final Offset bottom;

  const _Anchors({
    required this.left,
    required this.center,
    required this.right,
    required this.top,
    required this.bottom,
  });
}

class _RhythmPainter extends CustomPainter {
  final RhythmPattern pattern;
  final _Anchors anchors;
  final Color color;

  const _RhythmPainter({
    required this.pattern,
    required this.anchors,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final fill = Paint()
      ..color = color.withOpacity(0.6)
      ..style = PaintingStyle.fill;

    Offset toPixel(Offset a) =>
        Offset((a.dx + 1) * 0.5 * size.width, (a.dy + 1) * 0.5 * size.height);

    if (pattern == RhythmPattern.v) {
      final left = toPixel(anchors.left);
      final center = toPixel(anchors.center);
      final right = toPixel(anchors.right);
      final path = Path()
        ..moveTo(left.dx, left.dy)
        ..lineTo(center.dx, center.dy)
        ..lineTo(right.dx, right.dy);
      canvas.drawPath(path, p);
      canvas.drawCircle(left, 4, fill);
      canvas.drawCircle(center, 4, fill);
      canvas.drawCircle(right, 4, fill);
    } else {
      final top = toPixel(anchors.top);
      final bottom = toPixel(anchors.bottom);
      canvas.drawLine(bottom, top, p);
      canvas.drawCircle(top, 4, fill);
      canvas.drawCircle(bottom, 4, fill);
    }
  }

  @override
  bool shouldRepaint(covariant _RhythmPainter oldDelegate) {
    return oldDelegate.pattern != pattern ||
        oldDelegate.color != color ||
        oldDelegate.anchors != anchors;
  }
}

enum _RhythmPhase {
  idle,
  moving,
  holding,
  movingUp,
  movingDown,
  holdingTop,
  holdingBottom,
}
