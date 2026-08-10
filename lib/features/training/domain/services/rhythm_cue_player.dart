import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../session/session_orchestrator.dart';

enum RhythmCue {
  arrive('sounds/rhythm_arrive.wav'),
  holdEnd('sounds/rhythm_hold_end.wav');

  const RhythmCue(this.assetKey);

  final String assetKey;

  String get bundleAssetKey => 'assets/$assetKey';
}

typedef RhythmCueAssetProbe = Future<bool> Function(String bundleAssetKey);
typedef RhythmCueInterruptionHandler = void Function();

abstract interface class RhythmCueAudioBackend {
  Future<void> initialize();

  Future<void> playAsset(String assetKey);

  Future<void> stop();

  Future<void> dispose();
}

class RhythmCuePreflightReport {
  const RhythmCuePreflightReport({
    required this.availableCues,
    required this.missingCues,
    this.initializationError,
  });

  final List<RhythmCue> availableCues;
  final List<RhythmCue> missingCues;
  final String? initializationError;

  bool get isReady =>
      availableCues.length == RhythmCue.values.length &&
      missingCues.isEmpty &&
      initializationError == null;
}

/// Plays rhythm markers in response to the canonical session signal stream.
///
/// This service owns no timer, ticker, stream, beat counter, or session state.
/// The [SessionOrchestrator] remains the only timeline. Callers forward its
/// emitted signals through [handleSignal].
class RhythmCuePlayer {
  RhythmCuePlayer({
    RhythmCueInterruptionHandler? onInterruption,
  })  : _assetProbe = _probeRootBundleAsset,
        _onInterruption = onInterruption,
        _audioBackend = _AudioplayersRhythmCueBackend();

  @visibleForTesting
  RhythmCuePlayer.forTesting({
    required RhythmCueAssetProbe assetProbe,
    required RhythmCueAudioBackend audioBackend,
    RhythmCueInterruptionHandler? onInterruption,
  })  : _assetProbe = assetProbe,
        _onInterruption = onInterruption,
        _audioBackend = audioBackend;

  final RhythmCueAssetProbe _assetProbe;
  final RhythmCueInterruptionHandler? _onInterruption;
  final RhythmCueAudioBackend _audioBackend;

  Future<RhythmCuePreflightReport>? _initializationFuture;
  Future<void> _operationTail = Future.value();
  RhythmCuePreflightReport? _lastPreflight;
  bool _isReady = false;
  bool _disposed = false;
  int _generation = 0;

  bool get isReady => _isReady;

  RhythmCuePreflightReport? get lastPreflight => _lastPreflight;

  Future<RhythmCuePreflightReport> initialize() {
    if (_disposed) {
      throw StateError('RhythmCuePlayer has been disposed.');
    }
    final cached = _lastPreflight;
    if (_isReady && cached != null) return Future.value(cached);
    final inFlight = _initializationFuture;
    if (inFlight != null) return inFlight;

    final future = _runInitialization();
    _initializationFuture = future;
    return future.whenComplete(() {
      if (identical(_initializationFuture, future)) {
        _initializationFuture = null;
      }
    });
  }

  /// Maps only state-machine signals that have a rhythm sound contract.
  ///
  /// `beat` plays [RhythmCue.arrive], `repetitionCompleted` plays
  /// [RhythmCue.holdEnd], and pause/cancel signals stop active or queued cues.
  Future<void> handleSignal(
    TrainingSessionSignal signal, {
    required bool tonesEnabled,
  }) {
    if (_disposed) return Future.value();
    if (signal.type == TrainingSessionSignalType.paused ||
        signal.type == TrainingSessionSignalType.cancelled) {
      return stop();
    }
    if (!tonesEnabled) return stop();

    return switch (signal.type) {
      TrainingSessionSignalType.beat => play(RhythmCue.arrive),
      TrainingSessionSignalType.repetitionCompleted => play(RhythmCue.holdEnd),
      _ => Future.value(),
    };
  }

  /// Plays one caller-selected cue without introducing scheduling semantics.
  Future<void> play(RhythmCue cue) {
    if (_disposed || !_isReady) return Future.value();
    final generation = _generation;
    return _enqueue(() async {
      if (_disposed || !_isReady || generation != _generation) return;
      try {
        await _audioBackend.playAsset(cue.assetKey);
      } catch (error) {
        debugPrint(
          '[RhythmCuePlayer] failed to play ${cue.assetKey}: $error',
        );
        _onInterruption?.call();
      }
    });
  }

  /// Invalidates queued cues before stopping the shared low-latency player.
  Future<void> stop() {
    if (_disposed) return Future.value();
    _generation += 1;
    return _enqueue(_stopBackendSafely);
  }

  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    _isReady = false;
    _generation += 1;

    await _initializationFuture;
    await _operationTail;
    await _stopBackendSafely();
    try {
      await _audioBackend.dispose();
    } catch (error) {
      debugPrint('[RhythmCuePlayer] dispose failed: $error');
    }
  }

  Future<RhythmCuePreflightReport> _runInitialization() async {
    final available = <RhythmCue>[];
    final missing = <RhythmCue>[];

    for (final cue in RhythmCue.values) {
      var exists = false;
      try {
        exists = await _assetProbe(cue.bundleAssetKey);
      } on Object {
        exists = false;
      }
      (exists ? available : missing).add(cue);
    }

    if (missing.isNotEmpty || _disposed) {
      _isReady = false;
      return _recordPreflight(
        available: available,
        missing: missing,
        initializationError:
            _disposed ? 'RhythmCuePlayer was disposed during preflight.' : null,
      );
    }

    try {
      await _audioBackend.initialize();
      if (_disposed) {
        _isReady = false;
        return _recordPreflight(
          available: available,
          missing: missing,
          initializationError:
              'RhythmCuePlayer was disposed during initialization.',
        );
      }
      _isReady = true;
      return _recordPreflight(available: available, missing: missing);
    } catch (error) {
      _isReady = false;
      return _recordPreflight(
        available: available,
        missing: missing,
        initializationError: error.toString(),
      );
    }
  }

  RhythmCuePreflightReport _recordPreflight({
    required List<RhythmCue> available,
    required List<RhythmCue> missing,
    String? initializationError,
  }) {
    final report = RhythmCuePreflightReport(
      availableCues: List.unmodifiable(available),
      missingCues: List.unmodifiable(missing),
      initializationError: initializationError,
    );
    _lastPreflight = report;
    return report;
  }

  Future<void> _enqueue(Future<void> Function() operation) {
    final result = _operationTail.then((_) => operation());
    _operationTail = result;
    return result;
  }

  Future<void> _stopBackendSafely() async {
    try {
      await _audioBackend.stop();
    } catch (error) {
      debugPrint('[RhythmCuePlayer] stop failed: $error');
    }
  }

  static Future<bool> _probeRootBundleAsset(String bundleAssetKey) async {
    try {
      final data = await rootBundle.load(bundleAssetKey);
      return data.lengthInBytes > 0;
    } on Object {
      return false;
    }
  }
}

class _AudioplayersRhythmCueBackend implements RhythmCueAudioBackend {
  AudioPlayer? _player;

  @override
  Future<void> initialize() async {
    if (_player != null) return;

    final player = AudioPlayer();
    try {
      final context = AudioContextConfig(
        focus: AudioContextConfigFocus.mixWithOthers,
      ).build();
      await player.setAudioContext(context);
      await player.setReleaseMode(ReleaseMode.stop);
      await player.setPlayerMode(PlayerMode.lowLatency);
      _player = player;
    } catch (_) {
      await player.dispose();
      rethrow;
    }
  }

  @override
  Future<void> playAsset(String assetKey) async {
    final player = _player;
    if (player == null) {
      throw StateError('Rhythm cue audio backend is not initialized.');
    }
    await player.stop();
    await player.play(
      AssetSource(assetKey),
      mode: PlayerMode.lowLatency,
    );
  }

  @override
  Future<void> stop() async {
    await _player?.stop();
  }

  @override
  Future<void> dispose() async {
    final player = _player;
    _player = null;
    await player?.dispose();
  }
}
