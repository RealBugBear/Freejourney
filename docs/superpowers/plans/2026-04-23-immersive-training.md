# Immersive Training Redesign — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the existing training exercise flow with a fully hands-free, immersive experience: dark pendulum screen with a metronome beat system, auto-advancing reps, rich transition screens between exercises, and in-app music support.

**Architecture:** A new `ImmersiveSessionScreen` owns the full exercise loop (transition → exercise → transition → …). Each exercise runs in `ImmersiveExerciseScreen`, driven by a `MetronomeService` that owns timing + audio. `TrainingSessionScreen` keeps wakelock / session-saving / outro; it now routes straight into `ImmersiveSessionScreen` after the intro.

**Tech Stack:** Flutter, Riverpod, `audioplayers` 6.5.1, `shared_preferences`, `flutter_test` + `fake_async` (transitive, already present)

---

## File Map

| Action | Path | Responsibility |
|--------|------|----------------|
| Create | `lib/features/training/domain/services/metronome_service.dart` | Beat timer, audio, pause/resume |
| Create | `lib/core/training/transition_duration_settings.dart` | Persist inter-exercise countdown seconds |
| Create | `lib/core/training/in_app_music_settings.dart` | Persist selected in-app track + volume |
| Create | `lib/features/training/presentation/services/in_app_music_service.dart` | Ambient music playback |
| Create | `lib/features/training/presentation/widgets/pendulum_animation_widget.dart` | Pendulum that syncs to beat interval |
| Create | `lib/features/training/presentation/widgets/rep_segments_widget.dart` | N coloured segment bars for rep progress |
| Create | `lib/features/training/presentation/widgets/exercise_transition_widget.dart` | Between-exercise info screen (routine=auto, tutorial=button) |
| Create | `lib/features/training/presentation/widgets/music_picker_sheet.dart` | Bottom sheet: in-app track list + system music indicator |
| Create | `lib/features/training/presentation/screens/immersive_exercise_screen.dart` | Dark full-screen exercise with pendulum + beat |
| Create | `lib/features/training/presentation/screens/immersive_session_screen.dart` | Session loop: transition → exercise → … → done |
| Modify | `lib/features/training/presentation/screens/training_session_screen.dart` | Route to ImmersiveSessionScreen instead of old step widgets |
| Create | `test/features/training/metronome_service_test.dart` | Unit tests for MetronomeService logic |
| Create | `test/core/training/transition_duration_settings_test.dart` | Unit tests for settings helper |
| Create | `test/core/training/in_app_music_settings_test.dart` | Unit tests for settings helper |

---

## Task 1: MetronomeService

**Files:**
- Create: `lib/features/training/domain/services/metronome_service.dart`
- Test: `test/features/training/metronome_service_test.dart`

- [ ] **Step 1.1: Write failing test — holdRest emits 7 beats then allRepsComplete**

```dart
// test/features/training/metronome_service_test.dart
import 'package:corejourney/features/training/domain/models/exercise.dart';
import 'package:corejourney/features/training/domain/services/metronome_service.dart';
import 'package:flutter_test/flutter_test.dart';

// Minimal holdRest exercise fixture (1 rep, 7 beats, no audio in tests)
const _holdEx = Exercise(
  id: 'test_hold',
  packageId: 'test',
  sequenceNumber: 1,
  titleDe: 'Test', titleEn: 'Test',
  positionInstructionsDe: [], positionInstructionsEn: [],
  movementInstructionsDe: [], movementInstructionsEn: [],
  executionGuideDe: '', executionGuideEn: '',
  durationSeconds: 7, repetitions: 1,
  imagePath: '',
  rhythmType: RhythmType.holdRest,
  holdSeconds: 7, restSeconds: 3,
);

void main() {
  group('MetronomeService — holdRest', () {
    test('emits beats 1..7 then allRepsComplete for 1-rep exercise', () async {
      final svc = MetronomeService(
        tempoSeconds: 0.001,
        restDuration: Duration.zero,
        enableAudio: false,
      );

      final beats = <int>[];
      bool done = false;
      svc.beatStream.listen(beats.add);
      svc.allRepsComplete.listen((_) => done = true);

      await svc.startExercise(_holdEx);

      expect(beats, [1, 2, 3, 4, 5, 6, 7]);
      expect(done, isTrue);
      await svc.dispose();
    });

    test('emits repComplete between reps for multi-rep exercise', () async {
      const ex = Exercise(
        id: 'test_hold3',
        packageId: 'test',
        sequenceNumber: 1,
        titleDe: 'T', titleEn: 'T',
        positionInstructionsDe: [], positionInstructionsEn: [],
        movementInstructionsDe: [], movementInstructionsEn: [],
        executionGuideDe: '', executionGuideEn: '',
        durationSeconds: 7, repetitions: 3,
        imagePath: '',
        rhythmType: RhythmType.holdRest,
      );
      final svc = MetronomeService(
        tempoSeconds: 0.001,
        restDuration: Duration.zero,
        enableAudio: false,
      );

      int repCompleteCount = 0;
      bool done = false;
      svc.repComplete.listen((_) => repCompleteCount++);
      svc.allRepsComplete.listen((_) => done = true);

      await svc.startExercise(ex);

      expect(repCompleteCount, 3);
      expect(done, isTrue);
      await svc.dispose();
    });

    test('dispose cancels running exercise', () async {
      final svc = MetronomeService(
        tempoSeconds: 1.0, // slow — would take 7s normally
        restDuration: const Duration(seconds: 3),
        enableAudio: false,
      );

      bool done = false;
      svc.allRepsComplete.listen((_) => done = true);

      // Start but don't await — dispose immediately
      unawaited(svc.startExercise(_holdEx));
      await Future.delayed(const Duration(milliseconds: 10));
      await svc.dispose();

      // Give any lingering callbacks a moment
      await Future.delayed(const Duration(milliseconds: 20));
      expect(done, isFalse);
    });
  });

  group('MetronomeService — phased', () {
    test('emits phaseTransition between phases', () async {
      const ex = Exercise(
        id: 'test_phased',
        packageId: 'test',
        sequenceNumber: 1,
        titleDe: 'T', titleEn: 'T',
        positionInstructionsDe: [], positionInstructionsEn: [],
        movementInstructionsDe: [], movementInstructionsEn: [],
        executionGuideDe: '', executionGuideEn: '',
        durationSeconds: 6, repetitions: 1,
        imagePath: '',
        rhythmType: RhythmType.phased,
        phases: [
          ExercisePhase(labelDe: 'Hoch', labelEn: 'Up', durationSeconds: 3),
          ExercisePhase(labelDe: 'Runter', labelEn: 'Down', durationSeconds: 3),
        ],
      );
      final svc = MetronomeService(
        tempoSeconds: 0.001,
        restDuration: Duration.zero,
        enableAudio: false,
      );

      int transitionCount = 0;
      bool done = false;
      svc.phaseTransition.listen((_) => transitionCount++);
      svc.allRepsComplete.listen((_) => done = true);

      await svc.startExercise(ex);

      // 1 transition between 2 phases (not after last)
      expect(transitionCount, 1);
      expect(done, isTrue);
      await svc.dispose();
    });
  });
}
```

- [ ] **Step 1.2: Run — confirm FAIL**

```bash
cd /Users/alexandermessinger/dev/claudvibes/reflexjourney
flutter test test/features/training/metronome_service_test.dart
```
Expected: error — `MetronomeService` not found.

- [ ] **Step 1.3: Create MetronomeService**

```dart
// lib/features/training/domain/services/metronome_service.dart
import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

import '../models/exercise.dart';

class MetronomeService {
  double tempoSeconds;
  final Duration restDuration;
  final bool enableAudio;

  bool _cancelled = false;
  bool _paused = false;

  final _beatCtrl = StreamController<int>.broadcast();
  final _repIdxCtrl = StreamController<int>.broadcast();
  final _repCompleteCtrl = StreamController<void>.broadcast();
  final _allRepsCompleteCtrl = StreamController<void>.broadcast();
  final _phaseTransitionCtrl = StreamController<void>.broadcast();

  AudioPlayer? _beatPlayer;
  AudioPlayer? _transitionPlayer;

  MetronomeService({
    this.tempoSeconds = 1.0,
    this.restDuration = const Duration(seconds: 3),
    this.enableAudio = true,
  });

  Stream<int> get beatStream => _beatCtrl.stream;
  Stream<int> get repIndexStream => _repIdxCtrl.stream;
  Stream<void> get repComplete => _repCompleteCtrl.stream;
  Stream<void> get allRepsComplete => _allRepsCompleteCtrl.stream;
  Stream<void> get phaseTransition => _phaseTransitionCtrl.stream;

  Future<void> _initAudio() async {
    if (!enableAudio) return;
    final ctx = AudioContextConfig(
      focus: AudioContextConfigFocus.mixWithOthers,
    ).build();
    _beatPlayer = AudioPlayer();
    _transitionPlayer = AudioPlayer();
    await _beatPlayer!.setAudioContext(ctx);
    await _transitionPlayer!.setAudioContext(ctx);
    await _beatPlayer!.setReleaseMode(ReleaseMode.stop);
    await _transitionPlayer!.setReleaseMode(ReleaseMode.stop);
    await _beatPlayer!.setPlayerMode(PlayerMode.lowLatency);
    await _transitionPlayer!.setPlayerMode(PlayerMode.lowLatency);
  }

  Future<void> startExercise(Exercise ex) async {
    _cancelled = false;
    _paused = false;
    await _initAudio();
    final reps = ex.repetitions;

    for (int repIdx = 0; repIdx < reps; repIdx++) {
      if (_cancelled) return;
      if (!_repIdxCtrl.isClosed) _repIdxCtrl.add(repIdx);

      if (ex.rhythmType == RhythmType.holdRest) {
        await _runHoldRestRep();
      } else {
        await _runPhasedRep(ex);
      }
      if (_cancelled) return;

      _emit(_repCompleteCtrl);
      _playTransition();

      if (repIdx < reps - 1) {
        await _sleep(restDuration);
      }
    }

    if (!_cancelled) _emit(_allRepsCompleteCtrl);
  }

  Future<void> _runHoldRestRep() async {
    for (int beat = 1; beat <= 7; beat++) {
      if (_cancelled) return;
      _emit(_beatCtrl, beat);
      _playBeat();
      await _sleep(Duration(milliseconds: (tempoSeconds * 1000).round()));
    }
  }

  Future<void> _runPhasedRep(Exercise ex) async {
    int beatInRep = 0;
    for (int pi = 0; pi < ex.phases.length; pi++) {
      if (_cancelled) return;
      final phase = ex.phases[pi];
      final beatsInPhase =
          (phase.durationSeconds / tempoSeconds).round().clamp(1, 99);
      for (int bi = 0; bi < beatsInPhase; bi++) {
        if (_cancelled) return;
        beatInRep++;
        _emit(_beatCtrl, beatInRep);
        _playBeat();
        await _sleep(Duration(milliseconds: (tempoSeconds * 1000).round()));
      }
      // Fire phase transition between phases (not after last)
      if (pi < ex.phases.length - 1 && !_cancelled) {
        _emit(_phaseTransitionCtrl);
        _playTransition();
      }
    }
  }

  Future<void> _sleep(Duration d) async {
    final end = DateTime.now().add(d);
    while (!_cancelled) {
      while (_paused && !_cancelled) {
        await Future.delayed(const Duration(milliseconds: 50));
      }
      if (_cancelled) return;
      final remaining = end.difference(DateTime.now());
      if (remaining <= Duration.zero) break;
      final chunk = remaining > const Duration(milliseconds: 50)
          ? const Duration(milliseconds: 50)
          : remaining;
      await Future.delayed(chunk);
    }
  }

  void _emit<T>(StreamController<T> ctrl, [T? value]) {
    if (ctrl.isClosed) return;
    if (value is int) {
      (ctrl as StreamController<int>).add(value);
    } else {
      (ctrl as StreamController<void>).add(null);
    }
  }

  void _playBeat() {
    if (!enableAudio || _beatPlayer == null) return;
    _beatPlayer!
        .play(AssetSource('sounds/rhythm_arrive.wav'),
            mode: PlayerMode.lowLatency)
        .ignore();
  }

  void _playTransition() {
    if (!enableAudio || _transitionPlayer == null) return;
    _transitionPlayer!
        .play(AssetSource('sounds/rhythm_hold_end.wav'),
            mode: PlayerMode.lowLatency)
        .ignore();
  }

  Future<void> pause() async => _paused = true;
  Future<void> resume() async => _paused = false;

  Future<void> dispose() async {
    _cancelled = true;
    if (enableAudio) {
      await _beatPlayer?.dispose();
      await _transitionPlayer?.dispose();
    }
    for (final c in [
      _beatCtrl,
      _repIdxCtrl,
      _repCompleteCtrl,
      _allRepsCompleteCtrl,
      _phaseTransitionCtrl,
    ]) {
      if (!c.isClosed) await c.close();
    }
  }
}
```

- [ ] **Step 1.4: Run — confirm PASS**

```bash
flutter test test/features/training/metronome_service_test.dart
```
Expected: All 4 tests pass.

- [ ] **Step 1.5: Commit**

```bash
git add lib/features/training/domain/services/metronome_service.dart \
        test/features/training/metronome_service_test.dart
git commit -m "feat(training): add MetronomeService with beat/phase/rep streams

Co-Authored-By: Claude Sonnet 4.6 <noreply@anthropic.com>"
```

---

## Task 2: Settings Helpers

**Files:**
- Create: `lib/core/training/transition_duration_settings.dart`
- Create: `lib/core/training/in_app_music_settings.dart`
- Test: `test/core/training/transition_duration_settings_test.dart`
- Test: `test/core/training/in_app_music_settings_test.dart`

- [ ] **Step 2.1: Write failing tests**

```dart
// test/core/training/transition_duration_settings_test.dart
import 'package:corejourney/core/training/transition_duration_settings.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('TransitionDurationSettings', () {
    test('returns default 10 when not set', () async {
      final prefs = await SharedPreferences.getInstance();
      expect(TransitionDurationSettings.durationSeconds(prefs), 10);
    });

    test('returns persisted value', () async {
      final prefs = await SharedPreferences.getInstance();
      await TransitionDurationSettings.setDurationSeconds(prefs, 15);
      expect(TransitionDurationSettings.durationSeconds(prefs), 15);
    });

    test('clamps to valid range 5..30', () async {
      final prefs = await SharedPreferences.getInstance();
      await TransitionDurationSettings.setDurationSeconds(prefs, 99);
      expect(TransitionDurationSettings.durationSeconds(prefs), 30);
      await TransitionDurationSettings.setDurationSeconds(prefs, 1);
      expect(TransitionDurationSettings.durationSeconds(prefs), 5);
    });
  });
}
```

```dart
// test/core/training/in_app_music_settings_test.dart
import 'package:corejourney/core/training/in_app_music_settings.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('InAppMusicSettings', () {
    test('selectedTrack returns null when not set', () async {
      final prefs = await SharedPreferences.getInstance();
      expect(InAppMusicSettings.selectedTrack(prefs), isNull);
    });

    test('persists selected track', () async {
      final prefs = await SharedPreferences.getInstance();
      await InAppMusicSettings.setSelectedTrack(prefs, 'ambient_flow');
      expect(InAppMusicSettings.selectedTrack(prefs), 'ambient_flow');
    });

    test('volume defaults to 0.7', () async {
      final prefs = await SharedPreferences.getInstance();
      expect(InAppMusicSettings.volume(prefs), 0.7);
    });

    test('clears track when set to null', () async {
      final prefs = await SharedPreferences.getInstance();
      await InAppMusicSettings.setSelectedTrack(prefs, 'ambient_flow');
      await InAppMusicSettings.setSelectedTrack(prefs, null);
      expect(InAppMusicSettings.selectedTrack(prefs), isNull);
    });
  });
}
```

- [ ] **Step 2.2: Run — confirm FAIL**

```bash
flutter test test/core/training/transition_duration_settings_test.dart \
             test/core/training/in_app_music_settings_test.dart
```

- [ ] **Step 2.3: Create TransitionDurationSettings**

```dart
// lib/core/training/transition_duration_settings.dart
import 'package:shared_preferences/shared_preferences.dart';

class TransitionDurationSettings {
  static const _key = 'training_transition_duration_seconds';
  static const _default = 10;
  static const _min = 5;
  static const _max = 30;

  static int durationSeconds(SharedPreferences prefs) {
    return (prefs.getInt(_key) ?? _default).clamp(_min, _max);
  }

  static Future<void> setDurationSeconds(
    SharedPreferences prefs,
    int seconds,
  ) {
    return prefs.setInt(_key, seconds.clamp(_min, _max));
  }
}
```

- [ ] **Step 2.4: Create InAppMusicSettings**

```dart
// lib/core/training/in_app_music_settings.dart
import 'package:shared_preferences/shared_preferences.dart';

class InAppMusicSettings {
  static const _trackKey = 'training_in_app_music_track';
  static const _volumeKey = 'training_in_app_music_volume';
  static const _defaultVolume = 0.7;

  static String? selectedTrack(SharedPreferences prefs) {
    return prefs.getString(_trackKey);
  }

  static Future<void> setSelectedTrack(
    SharedPreferences prefs,
    String? track,
  ) {
    if (track == null) return prefs.remove(_trackKey);
    return prefs.setString(_trackKey, track);
  }

  static double volume(SharedPreferences prefs) {
    return prefs.getDouble(_volumeKey) ?? _defaultVolume;
  }

  static Future<void> setVolume(SharedPreferences prefs, double volume) {
    return prefs.setDouble(_volumeKey, volume.clamp(0.0, 1.0));
  }
}
```

- [ ] **Step 2.5: Run — confirm PASS**

```bash
flutter test test/core/training/transition_duration_settings_test.dart \
             test/core/training/in_app_music_settings_test.dart
```
Expected: 7 tests pass.

- [ ] **Step 2.6: Commit**

```bash
git add lib/core/training/transition_duration_settings.dart \
        lib/core/training/in_app_music_settings.dart \
        test/core/training/transition_duration_settings_test.dart \
        test/core/training/in_app_music_settings_test.dart
git commit -m "feat(training): add transition duration and in-app music settings

Co-Authored-By: Claude Sonnet 4.6 <noreply@anthropic.com>"
```

---

## Task 3: PendulumAnimationWidget + RepSegmentsWidget

**Files:**
- Create: `lib/features/training/presentation/widgets/pendulum_animation_widget.dart`
- Create: `lib/features/training/presentation/widgets/rep_segments_widget.dart`

- [ ] **Step 3.1: Create PendulumAnimationWidget**

The pendulum swings left ↔ right with period = `2 × beatInterval` (one full swing = two beats). When `isActive` is false (rest/pause) the animation dims and stops.

```dart
// lib/features/training/presentation/widgets/pendulum_animation_widget.dart
import 'package:flutter/material.dart';

class PendulumAnimationWidget extends StatefulWidget {
  final Duration beatInterval;
  final bool isActive;

  const PendulumAnimationWidget({
    super.key,
    required this.beatInterval,
    this.isActive = true,
  });

  @override
  State<PendulumAnimationWidget> createState() =>
      _PendulumAnimationWidgetState();
}

class _PendulumAnimationWidgetState extends State<PendulumAnimationWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _angle; // -0.45 to 0.45 radians

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: widget.beatInterval * 2, // full swing = 2 beats
    );
    _angle = Tween<double>(begin: -0.45, end: 0.45).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
    if (widget.isActive) _ctrl.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(PendulumAnimationWidget old) {
    super.didUpdateWidget(old);
    if (old.beatInterval != widget.beatInterval) {
      _ctrl.duration = widget.beatInterval * 2;
    }
    if (widget.isActive && !_ctrl.isAnimating) {
      _ctrl.repeat(reverse: true);
    } else if (!widget.isActive && _ctrl.isAnimating) {
      _ctrl.stop();
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final opacity = widget.isActive ? 1.0 : 0.35;
    return Opacity(
      opacity: opacity,
      child: SizedBox(
        width: 80,
        height: 100,
        child: AnimatedBuilder(
          animation: _angle,
          builder: (context, _) => CustomPaint(
            painter: _PendulumPainter(angle: _angle.value),
          ),
        ),
      ),
    );
  }
}

class _PendulumPainter extends CustomPainter {
  final double angle;
  const _PendulumPainter({required this.angle});

  @override
  void paint(Canvas canvas, Size size) {
    final pivot = Offset(size.width / 2, 0);
    final armLength = size.height * 0.72;
    final bobCenter = Offset(
      pivot.dx + armLength * angle,
      pivot.dy + armLength * (1 - angle.abs() * 0.05),
    );

    // Pivot dot
    canvas.drawCircle(pivot, 4,
        Paint()..color = const Color(0xFFa5b4fc).withOpacity(0.5));

    // Arm
    canvas.drawLine(
      pivot,
      bobCenter,
      Paint()
        ..color = const Color(0xFFa5b4fc).withOpacity(0.6)
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round,
    );

    // Bob with glow
    canvas.drawCircle(
      bobCenter,
      11,
      Paint()
        ..color = const Color(0xFFa5b4fc).withOpacity(0.25)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
    );
    canvas.drawCircle(bobCenter, 7, Paint()..color = const Color(0xFFa5b4fc));
  }

  @override
  bool shouldRepaint(_PendulumPainter old) => old.angle != angle;
}
```

- [ ] **Step 3.2: Create RepSegmentsWidget**

```dart
// lib/features/training/presentation/widgets/rep_segments_widget.dart
import 'package:flutter/material.dart';

class RepSegmentsWidget extends StatelessWidget {
  final int totalReps;
  final int completedReps; // reps fully done
  final double beatProgress; // 0.0..1.0 progress within current active rep

  const RepSegmentsWidget({
    super.key,
    required this.totalReps,
    required this.completedReps,
    this.beatProgress = 0.0,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(totalReps, (i) {
        final isDone = i < completedReps;
        final isActive = i == completedReps;
        return Container(
          width: (totalReps > 4) ? 20 : 28,
          height: 4,
          margin: const EdgeInsets.symmetric(horizontal: 3),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(2),
            color: isDone
                ? const Color(0xFF6366f1)
                : Colors.white.withOpacity(0.1),
          ),
          child: isActive
              ? FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: beatProgress.clamp(0.0, 1.0),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(2),
                      color: const Color(0xFF6366f1),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x996366f1),
                          blurRadius: 6,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),
                )
              : null,
        );
      }),
    );
  }
}
```

- [ ] **Step 3.3: Smoke test — run existing suite to confirm no regressions**

```bash
flutter test
```
Expected: all existing tests pass, no new failures.

- [ ] **Step 3.4: Commit**

```bash
git add lib/features/training/presentation/widgets/pendulum_animation_widget.dart \
        lib/features/training/presentation/widgets/rep_segments_widget.dart
git commit -m "feat(training): add PendulumAnimationWidget and RepSegmentsWidget

Co-Authored-By: Claude Sonnet 4.6 <noreply@anthropic.com>"
```

---

## Task 4: ExerciseTransitionWidget

**Files:**
- Create: `lib/features/training/presentation/widgets/exercise_transition_widget.dart`

This screen is shown **before every exercise** (including the first). Both modes show full exercise info. Routine mode adds a countdown ring and full-screen tap zone; tutorial mode shows a start button.

- [ ] **Step 4.1: Create ExerciseTransitionWidget**

```dart
// lib/features/training/presentation/widgets/exercise_transition_widget.dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../domain/models/exercise.dart';

class ExerciseTransitionWidget extends StatefulWidget {
  final Exercise exercise;
  final int exerciseIndex;     // 0-based
  final int totalExercises;
  final bool isRoutineMode;
  final int transitionDurationSeconds; // countdown length for routine
  final String locale;         // 'de' or 'en'
  final VoidCallback onStart;

  const ExerciseTransitionWidget({
    super.key,
    required this.exercise,
    required this.exerciseIndex,
    required this.totalExercises,
    required this.isRoutineMode,
    required this.transitionDurationSeconds,
    required this.locale,
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
    if (widget.isRoutineMode) {
      _countdown = widget.transitionDurationSeconds;
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (!mounted) return;
        setState(() => _countdown--);
        if (_countdown <= 0) {
          _timer?.cancel();
          widget.onStart();
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
    HapticFeedback.mediumImpact();
    widget.onStart();
  }

  @override
  Widget build(BuildContext context) {
    final ex = widget.exercise;
    final loc = widget.locale;

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Exercise image
        AspectRatio(
          aspectRatio: 16 / 9,
          child: Image.asset(
            ex.imagePath,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              color: Colors.white.withOpacity(0.05),
              alignment: Alignment.center,
              child: const Icon(Icons.image_not_supported_outlined,
                  color: Colors.white38, size: 40),
            ),
          ),
        ),

        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Number + title
                Text(
                  'Übung ${widget.exerciseIndex + 1} von ${widget.totalExercises}',
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

                // Chips
                Wrap(
                  spacing: 8,
                  children: [
                    _chip('${ex.repetitions}× Wdh.'),
                    _chip('${ex.holdSeconds} Sek / Rep'),
                  ],
                ),
                const SizedBox(height: 14),

                // Position
                _sectionLabel('Position'),
                ...ex.positionInstructions(loc).map(_bullet),
                const SizedBox(height: 10),

                // Movement
                _sectionLabel('Bewegung'),
                ...ex.movementInstructions(loc).map(_bullet),
                const SizedBox(height: 10),

                // Execution guide
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
              ],
            ),
          ),
        ),

        // CTA area
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          child: widget.isRoutineMode
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Startet in $_countdown s',
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.5), fontSize: 13),
                    ),
                    FilledButton(
                      onPressed: _startNow,
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF6366f1),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Jetzt starten'),
                    ),
                  ],
                )
              : SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: FilledButton.icon(
                    onPressed: _startNow,
                    icon: const Icon(Icons.play_arrow),
                    label: const Text(
                      'Übung starten',
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold),
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

    // In routine mode: wrap in GestureDetector so whole screen taps skip countdown
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
            style:
                const TextStyle(color: Color(0xFFa5b4fc), fontSize: 11, fontWeight: FontWeight.w700)),
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
```

- [ ] **Step 4.2: Smoke test**

```bash
flutter test
```
Expected: all existing tests pass.

- [ ] **Step 4.3: Commit**

```bash
git add lib/features/training/presentation/widgets/exercise_transition_widget.dart
git commit -m "feat(training): add ExerciseTransitionWidget (routine=auto, tutorial=button)

Co-Authored-By: Claude Sonnet 4.6 <noreply@anthropic.com>"
```

---

## Task 5: ImmersiveExerciseScreen

**Files:**
- Create: `lib/features/training/presentation/screens/immersive_exercise_screen.dart`

This screen manages one exercise from first beat to last rep. It creates + owns the `MetronomeService`, streams state into the UI, and calls `onComplete` when done.

- [ ] **Step 5.1: Create ImmersiveExerciseScreen**

```dart
// lib/features/training/presentation/screens/immersive_exercise_screen.dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/training/adaptive_tempo_settings.dart';
import '../../../../core/training/in_app_music_settings.dart';
import '../../../../core/training/training_feedback_settings.dart';
import '../../domain/models/exercise.dart';
import '../../domain/services/metronome_service.dart';
import '../widgets/music_picker_sheet.dart';
import '../widgets/pendulum_animation_widget.dart';
import '../widgets/rep_segments_widget.dart';

class ImmersiveExerciseScreen extends StatefulWidget {
  final Exercise exercise;
  final int exerciseIndex;   // 0-based
  final int totalExercises;
  final bool isRoutineMode;
  final VoidCallback onComplete;

  const ImmersiveExerciseScreen({
    super.key,
    required this.exercise,
    required this.exerciseIndex,
    required this.totalExercises,
    required this.isRoutineMode,
    required this.onComplete,
  });

  @override
  State<ImmersiveExerciseScreen> createState() =>
      _ImmersiveExerciseScreenState();
}

class _ImmersiveExerciseScreenState extends State<ImmersiveExerciseScreen> {
  MetronomeService? _metronome;
  final _subs = <StreamSubscription>[];

  int _currentBeat = 0;
  int _currentRepIndex = 0;
  bool _isResting = false;
  bool _isPaused = false;
  bool _musicActive = false;

  double _tempoSeconds = 1.0;
  TrainingFeedbackMode _feedbackMode = TrainingFeedbackMode.voiceAndCues;
  static const double _stepSize = 0.5;

  @override
  void initState() {
    super.initState();
    _loadSettingsAndStart();
  }

  Future<void> _loadSettingsAndStart() async {
    final prefs = await SharedPreferences.getInstance();
    final feedback = TrainingFeedbackSettings.feedbackMode(prefs);
    final persistedTempo = AdaptiveTempoSettings.tempoForExerciseOrNull(
        prefs, widget.exercise.sequenceNumber);
    final musicTrack = InAppMusicSettings.selectedTrack(prefs);

    if (!mounted) return;
    setState(() {
      _feedbackMode = feedback;
      _tempoSeconds = persistedTempo ?? 1.0;
      _musicActive = musicTrack != null;
    });
    _startMetronome();
  }

  void _startMetronome() {
    final enableAudio = _feedbackMode != TrainingFeedbackMode.silent;
    final svc = MetronomeService(
      tempoSeconds: _tempoSeconds,
      restDuration: const Duration(seconds: 3),
      enableAudio: enableAudio,
    );
    _metronome = svc;

    _subs.add(svc.beatStream.listen((beat) {
      if (mounted) setState(() { _currentBeat = beat; _isResting = false; });
      if (_feedbackMode == TrainingFeedbackMode.hapticOnly) {
        HapticFeedback.lightImpact();
      }
    }));

    _subs.add(svc.repIndexStream.listen((idx) {
      if (mounted) setState(() => _currentRepIndex = idx);
    }));

    _subs.add(svc.repComplete.listen((_) {
      if (mounted) {
        setState(() => _isResting = true);
        if (_feedbackMode != TrainingFeedbackMode.silent) {
          HapticFeedback.mediumImpact();
        }
      }
    }));

    _subs.add(svc.allRepsComplete.listen((_) async {
      if (!mounted) return;
      if (_feedbackMode != TrainingFeedbackMode.silent) {
        HapticFeedback.heavyImpact();
      }
      // Persist tempo
      final prefs = await SharedPreferences.getInstance();
      await AdaptiveTempoSettings.saveTempoForExercise(
        prefs,
        exerciseNumber: widget.exercise.sequenceNumber,
        tempoSeconds: _tempoSeconds,
      );
      if (mounted) widget.onComplete();
    }));

    unawaited(svc.startExercise(widget.exercise));
  }

  @override
  void dispose() {
    for (final s in _subs) { s.cancel(); }
    _metronome?.dispose();
    super.dispose();
  }

  Future<void> _togglePause() async {
    if (_isPaused) {
      await _metronome?.resume();
    } else {
      await _metronome?.pause();
    }
    if (mounted) setState(() => _isPaused = !_isPaused);
    HapticFeedback.selectionClick();
  }

  void _changeTempo(double delta) {
    final newTempo = (_tempoSeconds + delta).clamp(0.5, 3.0);
    final snapped = (newTempo / _stepSize).round() * _stepSize;
    setState(() => _tempoSeconds = snapped);
    _metronome?.tempoSeconds = snapped;
    HapticFeedback.selectionClick();
  }

  void _cycleFeedbackMode() async {
    final next = switch (_feedbackMode) {
      TrainingFeedbackMode.voiceAndCues => TrainingFeedbackMode.hapticOnly,
      TrainingFeedbackMode.hapticOnly => TrainingFeedbackMode.silent,
      TrainingFeedbackMode.silent => TrainingFeedbackMode.voiceAndCues,
    };
    final prefs = await SharedPreferences.getInstance();
    await TrainingFeedbackSettings.setFeedbackMode(prefs, next);
    if (mounted) setState(() => _feedbackMode = next);
    HapticFeedback.selectionClick();
  }

  void _openMusicPicker() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF12121e),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => MusicPickerSheet(
        onMusicActiveChanged: (active) {
          if (mounted) setState(() => _musicActive = active);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ex = widget.exercise;
    final beatsPerRep = 7;
    final beatProgress = beatsPerRep > 0 ? _currentBeat / beatsPerRep : 0.0;
    final sessionProgress =
        (widget.exerciseIndex) / widget.totalExercises.toDouble();
    final locale = Localizations.localeOf(context).languageCode;
    final cueWord = _isResting
        ? 'Pause...'
        : (ex.holdCueDe.isNotEmpty ? ex.holdCueDe : 'Halten');
    final beatInterval =
        Duration(milliseconds: (_tempoSeconds * 1000).round());

    return Scaffold(
      backgroundColor: const Color(0xFF080810),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Übung ${widget.exerciseIndex + 1} · ${widget.totalExercises} gesamt',
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.3),
                        fontSize: 10,
                        letterSpacing: 0.12),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6366f1).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                          color: const Color(0xFF6366f1).withOpacity(0.3)),
                    ),
                    child: Text(
                      widget.isRoutineMode ? 'Routine' : 'Tutorial',
                      style: const TextStyle(
                          color: Color(0xFFa5b4fc),
                          fontSize: 9,
                          fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            ),

            // Session progress bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(1),
                child: LinearProgressIndicator(
                  value: sessionProgress,
                  minHeight: 2,
                  backgroundColor: Colors.white.withOpacity(0.08),
                  color: const Color(0xFF6366f1).withOpacity(0.6),
                ),
              ),
            ),

            // Center
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  PendulumAnimationWidget(
                    beatInterval: beatInterval,
                    isActive: !_isResting && !_isPaused,
                  ),
                  const SizedBox(height: 16),

                  // Big beat number
                  Text(
                    _isResting ? '$_currentBeat' : '$_currentBeat',
                    style: TextStyle(
                      color: _isResting
                          ? const Color(0xFFa5b4fc).withOpacity(0.4)
                          : const Color(0xFFa5b4fc),
                      fontSize: 64,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -2,
                      shadows: _isResting
                          ? []
                          : [
                              const Shadow(
                                color: Color(0x66a5b4fc),
                                blurRadius: 30,
                              )
                            ],
                    ),
                  ),
                  Text(
                    _isResting ? 'Pause' : 'von 7 Schlägen',
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.25), fontSize: 11),
                  ),
                  const SizedBox(height: 12),

                  // Cue word
                  Text(
                    cueWord.toUpperCase(),
                    style: TextStyle(
                      color: _isResting
                          ? Colors.white.withOpacity(0.3)
                          : Colors.white.withOpacity(0.85),
                      fontSize: _isResting ? 14 : 18,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.08,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Rep segments
                  RepSegmentsWidget(
                    totalReps: ex.repetitions,
                    completedReps: _currentRepIndex,
                    beatProgress: beatProgress,
                  ),
                  const SizedBox(height: 8),

                  // Exercise title
                  Text(
                    ex.title(locale),
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.3), fontSize: 11),
                  ),
                ],
              ),
            ),

            // Controls
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Column(
                children: [
                  // Tempo row
                  Row(
                    children: [
                      Expanded(child: _tempoBtn('−', () => _changeTempo(_stepSize))),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 2,
                        child: Container(
                          height: 36,
                          decoration: BoxDecoration(
                            color: const Color(0xFF6366f1).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                                color:
                                    const Color(0xFF6366f1).withOpacity(0.2)),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            '${_tempoSeconds.toStringAsFixed(_tempoSeconds.truncateToDouble() == _tempoSeconds ? 0 : 1)}s / Schlag',
                            style: const TextStyle(
                                color: Color(0xFFa5b4fc),
                                fontSize: 12,
                                fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(child: _tempoBtn('+', () => _changeTempo(-_stepSize))),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Icon controls row
                  Row(
                    children: [
                      Expanded(
                        child: _iconBtn(
                          _musicActive ? '♫' : '♪',
                          _musicActive ? 'Musik an' : 'Musik',
                          _openMusicPicker,
                          active: _musicActive,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _iconBtn(
                          _feedbackLabel(_feedbackMode),
                          _feedbackLabel(_feedbackMode),
                          _cycleFeedbackMode,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _iconBtn(
                          _isPaused ? '▶' : '⏸',
                          _isPaused ? 'Weiter' : 'Pause',
                          _togglePause,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tempoBtn(String label, VoidCallback onTap) => GestureDetector(
        onTap: onTap,
        child: Container(
          height: 36,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.06),
            borderRadius: BorderRadius.circular(10),
            border:
                Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          alignment: Alignment.center,
          child: Text(label,
              style: TextStyle(
                  color: Colors.white.withOpacity(0.6),
                  fontSize: 18,
                  fontWeight: FontWeight.w700)),
        ),
      );

  Widget _iconBtn(String icon, String label, VoidCallback onTap,
      {bool active = false}) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          height: 32,
          decoration: BoxDecoration(
            color: active
                ? const Color(0xFF22c55e).withOpacity(0.1)
                : Colors.white.withOpacity(0.04),
            borderRadius: BorderRadius.circular(9),
            border: Border.all(
                color: active
                    ? const Color(0xFF22c55e).withOpacity(0.3)
                    : Colors.white.withOpacity(0.08)),
          ),
          alignment: Alignment.center,
          child: Text(
            '$icon $label',
            style: TextStyle(
                color: active
                    ? const Color(0xFF86efac)
                    : Colors.white.withOpacity(0.4),
                fontSize: 9,
                fontWeight: FontWeight.w600),
          ),
        ),
      );

  String _feedbackLabel(TrainingFeedbackMode mode) => switch (mode) {
        TrainingFeedbackMode.voiceAndCues => '🔊',
        TrainingFeedbackMode.hapticOnly => '📳',
        TrainingFeedbackMode.silent => '🔇',
      };
}
```

- [ ] **Step 5.2: Smoke test**

```bash
flutter test
```
Expected: all existing tests still pass.

- [ ] **Step 5.3: Commit**

```bash
git add lib/features/training/presentation/screens/immersive_exercise_screen.dart
git commit -m "feat(training): add ImmersiveExerciseScreen with MetronomeService integration

Co-Authored-By: Claude Sonnet 4.6 <noreply@anthropic.com>"
```

---

## Task 6: InAppMusicService + MusicPickerSheet

**Files:**
- Create: `lib/features/training/presentation/services/in_app_music_service.dart`
- Create: `lib/features/training/presentation/widgets/music_picker_sheet.dart`

**Note on audio assets:** 3–5 ambient tracks must be placed at `assets/sounds/music/` and listed in `pubspec.yaml` under `flutter: assets:`. Use `.mp3` format. Placeholder entry: `assets/sounds/music/ambient_flow.mp3`. This step creates the infrastructure; actual audio files are added separately.

- [ ] **Step 6.1: Create InAppMusicService**

```dart
// lib/features/training/presentation/services/in_app_music_service.dart
import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/training/in_app_music_settings.dart';

/// Each entry: (assetKey, displayName)
const List<(String, String)> kInAppTracks = [
  ('sounds/music/ambient_flow.mp3', 'Ambient Flow'),
  ('sounds/music/stille_natur.mp3', 'Stille Natur'),
  ('sounds/music/tiefe_toene.mp3', 'Tiefe Töne'),
];

class InAppMusicService {
  final _player = AudioPlayer();
  bool _initialized = false;
  String? _currentTrack;

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;
    try {
      final ctx = AudioContextConfig(
        focus: AudioContextConfigFocus.mixWithOthers,
      ).build();
      await _player.setAudioContext(ctx);
      await _player.setReleaseMode(ReleaseMode.loop);
      await _player.setVolume(0.7);
    } catch (e) {
      debugPrint('[InAppMusicService] init error: $e');
    }
  }

  Future<void> loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final track = InAppMusicSettings.selectedTrack(prefs);
    final vol = InAppMusicSettings.volume(prefs);
    if (track != null) {
      await play(track, volume: vol);
    }
  }

  String? get currentTrack => _currentTrack;

  Future<void> play(String assetKey, {double volume = 0.7}) async {
    try {
      await init();
      _currentTrack = assetKey;
      await _player.setVolume(volume);
      await _player.play(AssetSource(assetKey));
    } catch (e) {
      debugPrint('[InAppMusicService] play error: $e');
    }
  }

  Future<void> stop() async {
    _currentTrack = null;
    await _player.stop();
  }

  Future<void> setVolume(double volume) async {
    await _player.setVolume(volume.clamp(0.0, 1.0));
  }

  Future<void> dispose() async {
    await _player.dispose();
  }
}
```

- [ ] **Step 6.2: Create MusicPickerSheet**

```dart
// lib/features/training/presentation/widgets/music_picker_sheet.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/training/in_app_music_settings.dart';
import '../services/in_app_music_service.dart';

class MusicPickerSheet extends StatefulWidget {
  final void Function(bool active) onMusicActiveChanged;

  const MusicPickerSheet({super.key, required this.onMusicActiveChanged});

  @override
  State<MusicPickerSheet> createState() => _MusicPickerSheetState();
}

class _MusicPickerSheetState extends State<MusicPickerSheet> {
  final _svc = InAppMusicService();
  String? _selected;
  double _volume = 0.7;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _selected = InAppMusicSettings.selectedTrack(prefs);
      _volume = InAppMusicSettings.volume(prefs);
    });
  }

  Future<void> _selectTrack(String? assetKey) async {
    final prefs = await SharedPreferences.getInstance();
    await InAppMusicSettings.setSelectedTrack(prefs, assetKey);
    if (assetKey == null) {
      await _svc.stop();
    } else {
      await _svc.play(assetKey, volume: _volume);
    }
    if (!mounted) return;
    setState(() => _selected = assetKey);
    widget.onMusicActiveChanged(assetKey != null);
  }

  Future<void> _setVolume(double v) async {
    final prefs = await SharedPreferences.getInstance();
    await InAppMusicSettings.setVolume(prefs, v);
    await _svc.setVolume(v);
    if (!mounted) return;
    setState(() => _volume = v);
  }

  @override
  void dispose() {
    _svc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Musik',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w800)),
          const SizedBox(height: 16),

          // Off option
          _trackTile(null, 'Aus'),
          const SizedBox(height: 2),
          const Divider(color: Colors.white12),
          const SizedBox(height: 2),

          // In-app tracks
          ...kInAppTracks.map((t) => _trackTile(t.$1, t.$2)),

          const SizedBox(height: 12),

          // Volume slider (only when a track is selected)
          if (_selected != null) ...[
            Text('Lautstärke',
                style: TextStyle(
                    color: Colors.white.withOpacity(0.4),
                    fontSize: 11,
                    letterSpacing: 0.1)),
            Slider(
              value: _volume,
              onChanged: _setVolume,
              activeColor: const Color(0xFF6366f1),
              inactiveColor: Colors.white12,
            ),
          ],

          // System music indicator
          const Divider(color: Colors.white12),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.music_note, color: Colors.white38, size: 16),
              const SizedBox(width: 8),
              Text(
                'Eigene Musik (Spotify etc.) läuft weiter — Töne mischen sich darunter.',
                style: TextStyle(
                    color: Colors.white.withOpacity(0.35), fontSize: 11),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _trackTile(String? assetKey, String label) {
    final isSelected = _selected == assetKey;
    return InkWell(
      onTap: () => _selectTrack(assetKey),
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: isSelected
                  ? const Color(0xFF6366f1)
                  : Colors.white.withOpacity(0.3),
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(label,
                  style: TextStyle(
                      color: isSelected
                          ? Colors.white
                          : Colors.white.withOpacity(0.6),
                      fontSize: 15,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.w400)),
            ),
            if (isSelected)
              const Icon(Icons.volume_up, color: Color(0xFF6366f1), size: 16),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 6.3: Add placeholder music asset directory to pubspec.yaml**

Open `pubspec.yaml`. Under `flutter: assets:`, add:
```yaml
    - assets/sounds/music/
```
Then create the directory (it needs at least one file to be valid):
```bash
mkdir -p /Users/alexandermessinger/dev/claudvibes/reflexjourney/assets/sounds/music
# Add a placeholder file so the directory exists in git
touch /Users/alexandermessinger/dev/claudvibes/reflexjourney/assets/sounds/music/.gitkeep
```

- [ ] **Step 6.4: Smoke test**

```bash
flutter test
```
Expected: all tests pass.

- [ ] **Step 6.5: Commit**

```bash
git add lib/features/training/presentation/services/in_app_music_service.dart \
        lib/features/training/presentation/widgets/music_picker_sheet.dart \
        assets/sounds/music/.gitkeep \
        pubspec.yaml
git commit -m "feat(training): add InAppMusicService and MusicPickerSheet

Co-Authored-By: Claude Sonnet 4.6 <noreply@anthropic.com>"
```

---

## Task 7: ImmersiveSessionScreen

**Files:**
- Create: `lib/features/training/presentation/screens/immersive_session_screen.dart`

Manages the full exercise loop: transition → exercise → transition → … → done. Calls `onComplete(completedIds)` after the last exercise.

- [ ] **Step 7.1: Create ImmersiveSessionScreen**

```dart
// lib/features/training/presentation/screens/immersive_session_screen.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/training/transition_duration_settings.dart';
import '../../domain/models/exercise.dart';
import '../widgets/exercise_transition_widget.dart';
import 'immersive_exercise_screen.dart';

enum _Phase { transition, exercise }

class ImmersiveSessionScreen extends StatefulWidget {
  final List<Exercise> exercises;
  final bool isRoutineMode;
  final void Function(List<String> completedExerciseIds) onComplete;

  const ImmersiveSessionScreen({
    super.key,
    required this.exercises,
    required this.isRoutineMode,
    required this.onComplete,
  });

  @override
  State<ImmersiveSessionScreen> createState() => _ImmersiveSessionScreenState();
}

class _ImmersiveSessionScreenState extends State<ImmersiveSessionScreen> {
  int _exerciseIndex = 0;
  _Phase _phase = _Phase.transition;
  final List<String> _completedIds = [];
  int _transitionDuration = 10;

  @override
  void initState() {
    super.initState();
    _loadTransitionDuration();
  }

  Future<void> _loadTransitionDuration() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _transitionDuration =
          TransitionDurationSettings.durationSeconds(prefs);
    });
  }

  void _onTransitionComplete() {
    setState(() => _phase = _Phase.exercise);
  }

  void _onExerciseComplete() {
    final ex = widget.exercises[_exerciseIndex];
    _completedIds.add(ex.id);

    if (_exerciseIndex >= widget.exercises.length - 1) {
      widget.onComplete(_completedIds);
    } else {
      setState(() {
        _exerciseIndex++;
        _phase = _Phase.transition;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.exercises.isEmpty) {
      return const SizedBox.shrink();
    }

    final exercise = widget.exercises[_exerciseIndex];
    final locale = Localizations.localeOf(context).languageCode;

    return switch (_phase) {
      _Phase.transition => ExerciseTransitionWidget(
          key: ValueKey('transition_$_exerciseIndex'),
          exercise: exercise,
          exerciseIndex: _exerciseIndex,
          totalExercises: widget.exercises.length,
          isRoutineMode: widget.isRoutineMode,
          transitionDurationSeconds: _transitionDuration,
          locale: locale,
          onStart: _onTransitionComplete,
        ),
      _Phase.exercise => ImmersiveExerciseScreen(
          key: ValueKey('exercise_$_exerciseIndex'),
          exercise: exercise,
          exerciseIndex: _exerciseIndex,
          totalExercises: widget.exercises.length,
          isRoutineMode: widget.isRoutineMode,
          onComplete: _onExerciseComplete,
        ),
    };
  }
}
```

- [ ] **Step 7.2: Smoke test**

```bash
flutter test
```
Expected: all tests pass.

- [ ] **Step 7.3: Commit**

```bash
git add lib/features/training/presentation/screens/immersive_session_screen.dart
git commit -m "feat(training): add ImmersiveSessionScreen (exercise loop with transitions)

Co-Authored-By: Claude Sonnet 4.6 <noreply@anthropic.com>"
```

---

## Task 8: Wire TrainingSessionScreen

**Files:**
- Modify: `lib/features/training/presentation/screens/training_session_screen.dart`

Replace the old step-based flow with `ImmersiveSessionScreen`. Keep wakelock, outro, session-saving, cancel dialog, and disclaimer unchanged.

- [ ] **Step 8.1: Replace _buildCurrentStep internals**

In `training_session_screen.dart`:

1. Add new enum at top of file (before the class):
```dart
enum _TrainingPhase { intro, session, outro }
```

2. Add to `_TrainingSessionScreenState`:
```dart
_TrainingPhase _phase = _TrainingPhase.intro;
List<String> _completedExerciseIds = [];
```

3. Replace `_buildCurrentStep` entirely:
```dart
Widget _buildCurrentStep(TrainingFlowState state, String pkg) {
  // Disclaimer overlay handled separately (existing logic kept)
  switch (_phase) {
    case _TrainingPhase.intro:
      return TrainingIntroWidget(
        exercise: state.currentExercise,
        exerciseIndex: state.currentExerciseIndex,
        totalExercises: state.totalExercises,
        mode: state.mode,
        onStart: () => setState(() => _phase = _TrainingPhase.session),
      );

    case _TrainingPhase.session:
      return ImmersiveSessionScreen(
        exercises: state.exercises,
        isRoutineMode: state.mode == TrainingSessionMode.routine,
        onComplete: (ids) {
          setState(() {
            _completedExerciseIds = ids;
            _phase = _TrainingPhase.outro;
          });
        },
      );

    case _TrainingPhase.outro:
      // Build a fake completed state for the existing outro widget
      final completedState = state.copyWith(
        completedExerciseIds: _completedExerciseIds,
        isComplete: true,
        step: TrainingFlowStep.outro,
      );
      return TrainingOutroWidget(
        completedCount: _completedExerciseIds.length,
        onContinue: () => _handleOutroContinue(completedState),
      );
  }
}
```

4. Add import at top of file:
```dart
import 'immersive_session_screen.dart';
```

5. Remove unused imports for old step widgets that are now unreachable (keep ExerciseVideoWidget etc. if tutorial mode still uses them via the existing intro flow — otherwise remove):
   - Keep: `training_intro_widget.dart`, `training_outro_widget.dart`, `disclaimer_dialog.dart`
   - Remove: `exercise_movement_widget.dart`, `exercise_position_widget.dart`, `exercise_preparation_widget.dart`, `exercise_rest_widget.dart`, `exercise_video_widget.dart` (if no longer referenced)

- [ ] **Step 8.2: Run all tests**

```bash
flutter test
```
Expected: all existing tests pass. If `training_flow_provider_test.dart` references old step names that no longer compile, update or delete that test file (the provider itself is unchanged — only `TrainingSessionScreen` changed).

- [ ] **Step 8.3: Run the app and manually verify**

```bash
make run
```

Walk through:
1. Open a training session (Moro or Spinal Galant)
2. Verify intro screen appears
3. Tap start → transition screen appears with exercise image + position + movement + exec guide
4. In routine: countdown visible, tapping anywhere skips it
5. Exercise starts: dark screen, pendulum animates, beat number counts 1→7
6. After 7 beats: rep segment fills, brief pause shows "Pause..."
7. After all reps: transition to next exercise
8. Tempo −/+ buttons change beat speed
9. Last exercise complete → outro screen

- [ ] **Step 8.4: Commit**

```bash
git add lib/features/training/presentation/screens/training_session_screen.dart
git commit -m "feat(training): wire TrainingSessionScreen to ImmersiveSessionScreen

Co-Authored-By: Claude Sonnet 4.6 <noreply@anthropic.com>"
```

---

## Self-Review Checklist

**Spec coverage:**
- [x] Beat system 1s/beat, 7 beats per holdRest rep → Task 1 MetronomeService
- [x] Phased exercises: beat per second + phase-transition tone → Task 1 `_runPhasedRep`
- [x] `exercise.repetitions` always used, never hardcoded → Task 1 + Task 5
- [x] Rep segments adapt to 3 or 6 reps → Task 3 RepSegmentsWidget
- [x] halfwaySwitch not explicitly implemented as a screen announcement — **GAP**: add a `phaseAnnouncement` stream or a side-effect in `ImmersiveExerciseScreen` that fires haptic + shows "Wechsel!" text at rep index 3 for exercises where `halfwaySwitch == true`
- [x] Transition screen: image + name + position + movement + exec guide → Task 4
- [x] Routine: auto-countdown (10s configurable) + full-screen tap → Task 4
- [x] Tutorial: button only → Task 4
- [x] Tempo adjustable in 0.5s steps → Task 5
- [x] Feedback mode cycle → Task 5
- [x] Music: system (mixWithOthers already in audioplayers init) → Task 5 + 6
- [x] Music: in-app picker + persistence → Task 6
- [x] Session loop with `onComplete(completedIds)` → Task 7
- [x] Wire to TrainingSessionScreen → Task 8
- [x] Transition duration configurable → Task 2 + Task 7

**halfwaySwitch gap fix** — add to Task 5 (`ImmersiveExerciseScreen`) in the `repComplete` listener:

```dart
_subs.add(svc.repComplete.listen((_) {
  if (mounted) {
    final rep = _currentRepIndex + 1; // rep just completed (1-based)
    final isHalfway = widget.exercise.halfwaySwitch &&
        widget.exercise.repetitions == 6 &&
        rep == 3;
    setState(() {
      _isResting = true;
      _halfwayAnnounce = isHalfway;  // new bool state field
    });
    if (isHalfway && _feedbackMode != TrainingFeedbackMode.silent) {
      HapticFeedback.heavyImpact();
    }
  }
}));
```

Add `bool _halfwayAnnounce = false;` to state. In the cue-word Text, check: `if (_halfwayAnnounce) 'WECHSEL!' else ...`. Reset `_halfwayAnnounce = false` in the beatStream listener.

**Placeholder check:** No TBDs or TODOs in code steps. Music audio files (`assets/sounds/music/*.mp3`) are noted as needing to be added separately.

**Type consistency:** `MetronomeService.tempoSeconds` is mutable (`double tempoSeconds` — not `final`) — confirmed consistent across Task 1 and Task 5 where `_metronome?.tempoSeconds = snapped` is called.
