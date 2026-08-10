import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:corejourney/features/training/domain/services/rhythm_cue_player.dart';
import 'package:corejourney/features/training/domain/session/session_orchestrator.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('bundled rhythm cues are non-empty PCM mono WAV assets', () async {
    for (final cue in RhythmCue.values) {
      final data = await rootBundle.load(cue.bundleAssetKey);
      final bytes = data.buffer.asUint8List(
        data.offsetInBytes,
        data.lengthInBytes,
      );

      expect(bytes.length, greaterThan(44), reason: cue.assetKey);
      expect(_ascii(bytes, 0, 4), 'RIFF', reason: cue.assetKey);
      expect(_ascii(bytes, 8, 4), 'WAVE', reason: cue.assetKey);
      expect(_littleEndian16(bytes, 20), 1, reason: 'PCM ${cue.assetKey}');
      expect(_littleEndian16(bytes, 22), 1, reason: 'mono ${cue.assetKey}');
      expect(
        _littleEndian32(bytes, 24),
        44100,
        reason: 'sample rate ${cue.assetKey}',
      );
      expect(
        _littleEndian16(bytes, 34),
        16,
        reason: 'bit depth ${cue.assetKey}',
      );
    }
  });

  test('initialize preflights both assets and is idempotent', () async {
    final backend = _RecordingBackend();
    final probed = <String>[];
    final player = RhythmCuePlayer.forTesting(
      assetProbe: (bundleAssetKey) async {
        probed.add(bundleAssetKey);
        return true;
      },
      audioBackend: backend,
    );

    final first = await player.initialize();
    final second = await player.initialize();

    expect(first.isReady, isTrue);
    expect(second, same(first));
    expect(first.availableCues, RhythmCue.values);
    expect(first.missingCues, isEmpty);
    expect(first.initializationError, isNull);
    expect(probed, RhythmCue.values.map((cue) => cue.bundleAssetKey));
    expect(backend.initializeCalls, 1);
    expect(player.isReady, isTrue);

    await player.dispose();
  });

  test('missing asset keeps the player gated and never initializes audio',
      () async {
    final backend = _RecordingBackend();
    final player = RhythmCuePlayer.forTesting(
      assetProbe: (bundleAssetKey) async =>
          bundleAssetKey != RhythmCue.holdEnd.bundleAssetKey,
      audioBackend: backend,
    );

    final report = await player.initialize();
    await player.play(RhythmCue.arrive);

    expect(report.isReady, isFalse);
    expect(report.availableCues, [RhythmCue.arrive]);
    expect(report.missingCues, [RhythmCue.holdEnd]);
    expect(backend.initializeCalls, 0);
    expect(backend.playedAssetKeys, isEmpty);

    await player.dispose();
  });

  test('backend initialization failure is a closed preflight result', () async {
    final backend = _RecordingBackend()
      ..initializationError = StateError('audio unavailable');
    final player = RhythmCuePlayer.forTesting(
      assetProbe: (_) async => true,
      audioBackend: backend,
    );

    final report = await player.initialize();

    expect(report.isReady, isFalse);
    expect(report.availableCues, RhythmCue.values);
    expect(report.missingCues, isEmpty);
    expect(report.initializationError, contains('audio unavailable'));
    expect(player.isReady, isFalse);

    await player.dispose();
  });

  test('maps canonical session signals without owning a timeline', () async {
    final backend = _RecordingBackend();
    final player = RhythmCuePlayer.forTesting(
      assetProbe: (_) async => true,
      audioBackend: backend,
    );
    await player.initialize();

    await player.handleSignal(
      _signal(TrainingSessionSignalType.beat),
      tonesEnabled: true,
    );
    await player.handleSignal(
      _signal(TrainingSessionSignalType.phaseStarted),
      tonesEnabled: true,
    );
    await player.handleSignal(
      _signal(TrainingSessionSignalType.repetitionCompleted),
      tonesEnabled: true,
    );

    expect(backend.playedAssetKeys, [
      RhythmCue.arrive.assetKey,
      RhythmCue.holdEnd.assetKey,
    ]);

    await player.dispose();
  });

  test('disabled tones and pause signals stop instead of playing', () async {
    final backend = _RecordingBackend();
    final player = RhythmCuePlayer.forTesting(
      assetProbe: (_) async => true,
      audioBackend: backend,
    );
    await player.initialize();

    await player.handleSignal(
      _signal(TrainingSessionSignalType.beat),
      tonesEnabled: false,
    );
    await player.handleSignal(
      _signal(TrainingSessionSignalType.paused),
      tonesEnabled: true,
    );

    expect(backend.playedAssetKeys, isEmpty);
    expect(backend.stopCalls, 2);

    await player.dispose();
  });

  test('stop invalidates queued cues before stopping the backend', () async {
    final backend = _RecordingBackend()..holdFirstPlay();
    final player = RhythmCuePlayer.forTesting(
      assetProbe: (_) async => true,
      audioBackend: backend,
    );
    await player.initialize();

    final active = player.play(RhythmCue.arrive);
    await _flushAsync();
    final stale = player.play(RhythmCue.holdEnd);
    final stopped = player.stop();

    expect(backend.playedAssetKeys, [RhythmCue.arrive.assetKey]);
    backend.releaseFirstPlay();
    await Future.wait([active, stale, stopped]);

    expect(backend.playedAssetKeys, [RhythmCue.arrive.assetKey]);
    expect(backend.stopCalls, 1);

    await player.dispose();
  });

  test('runtime playback failure reports a safe interruption', () async {
    final backend = _RecordingBackend()
      ..playbackError = StateError('audio focus lost');
    var interruptions = 0;
    final player = RhythmCuePlayer.forTesting(
      assetProbe: (_) async => true,
      audioBackend: backend,
      onInterruption: () => interruptions++,
    );
    await player.initialize();

    await player.play(RhythmCue.arrive);

    expect(interruptions, 1);
    await player.dispose();
  });

  test('dispose is idempotent and prevents future initialization', () async {
    final backend = _RecordingBackend();
    final player = RhythmCuePlayer.forTesting(
      assetProbe: (_) async => true,
      audioBackend: backend,
    );
    await player.initialize();

    await player.dispose();
    await player.dispose();
    await player.play(RhythmCue.arrive);

    expect(player.isReady, isFalse);
    expect(backend.stopCalls, 1);
    expect(backend.disposeCalls, 1);
    expect(backend.playedAssetKeys, isEmpty);
    expect(player.initialize, throwsStateError);
  });
}

class _RecordingBackend implements RhythmCueAudioBackend {
  final List<String> playedAssetKeys = [];
  int initializeCalls = 0;
  int stopCalls = 0;
  int disposeCalls = 0;
  Object? initializationError;
  Object? playbackError;
  Completer<void>? _firstPlayGate;

  void holdFirstPlay() {
    _firstPlayGate = Completer<void>();
  }

  void releaseFirstPlay() {
    final gate = _firstPlayGate;
    if (gate == null || gate.isCompleted) {
      throw StateError('First play is not held.');
    }
    gate.complete();
    _firstPlayGate = null;
  }

  @override
  Future<void> initialize() async {
    initializeCalls += 1;
    final error = initializationError;
    if (error != null) throw error;
  }

  @override
  Future<void> playAsset(String assetKey) async {
    playedAssetKeys.add(assetKey);
    final error = playbackError;
    if (error != null) throw error;
    await _firstPlayGate?.future;
  }

  @override
  Future<void> stop() async {
    stopCalls += 1;
  }

  @override
  Future<void> dispose() async {
    disposeCalls += 1;
  }
}

TrainingSessionSignal _signal(TrainingSessionSignalType type) {
  return TrainingSessionSignal(
    type: type,
    exerciseIndex: 0,
    repetitionIndex: 0,
    phaseIndex: 0,
    beat: type == TrainingSessionSignalType.beat ? 1 : null,
  );
}

String _ascii(Uint8List bytes, int offset, int length) {
  return ascii.decode(bytes.sublist(offset, offset + length));
}

int _littleEndian16(Uint8List bytes, int offset) {
  return ByteData.sublistView(bytes).getUint16(offset, Endian.little);
}

int _littleEndian32(Uint8List bytes, int offset) {
  return ByteData.sublistView(bytes).getUint32(offset, Endian.little);
}

Future<void> _flushAsync() async {
  await Future<void>.delayed(Duration.zero);
  await Future<void>.delayed(Duration.zero);
}
