import 'dart:async';

import 'package:corejourney/features/training/domain/services/audio_announcement_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AudioAnnouncementService', () {
    test('is a singleton', () {
      expect(
        AudioAnnouncementService.instance,
        same(AudioAnnouncementService.instance),
      );
    });

    test('serializes concurrent requests and exposes queue state', () async {
      final player = _ControlledAudioPlayer();
      final ducking = _RecordingDuckingDelegate();
      final service = AudioAnnouncementService.forTesting(
        audioPlayer: player,
        duckingDelegate: ducking,
      );

      final first = service.play('first.mp3');
      final second = service.play('second.mp3');
      await _flushAsync();

      expect(player.startedAssets, ['first.mp3']);
      expect(service.queueState.isPlaying, isTrue);
      expect(service.queueState.activeAssetKey, 'first.mp3');
      expect(service.queueState.pendingRequestCount, 1);
      expect(service.queueState.pendingAssetCount, 1);
      expect(service.queueState.duckLeaseCount, 1);

      player.completeCurrent();
      await _flushAsync();

      expect(player.startedAssets, ['first.mp3', 'second.mp3']);
      expect(service.queueState.activeAssetKey, 'second.mp3');

      player.completeCurrent();
      await Future.wait([first, second]);

      expect(service.queueState.isPlaying, isFalse);
      expect(service.queueState.pendingRequestCount, 0);
      expect(service.queueState.duckLeaseCount, 0);
      expect(ducking.duckCalls, 2);
      expect(ducking.unduckCalls, 2);

      await service.dispose();
    });

    test('runs higher-priority pending work first', () async {
      final player = _ControlledAudioPlayer();
      final service = AudioAnnouncementService.forTesting(
        audioPlayer: player,
        duckingDelegate: _RecordingDuckingDelegate(),
      );

      final active = service.play('active.mp3');
      final normal = service.play('normal.mp3');
      final high = service.play(
        'high.mp3',
        priority: AnnouncementPriority.high,
      );
      await _flushAsync();

      player.completeCurrent();
      await _flushAsync();
      expect(player.startedAssets, ['active.mp3', 'high.mp3']);

      player.completeCurrent();
      await _flushAsync();
      expect(
        player.startedAssets,
        ['active.mp3', 'high.mp3', 'normal.mp3'],
      );

      player.completeCurrent();
      await Future.wait([active, normal, high]);
      await service.dispose();
    });

    test('new generation cancels active and queued stale work', () async {
      final player = _ControlledAudioPlayer();
      final service = AudioAnnouncementService.forTesting(
        audioPlayer: player,
        duckingDelegate: _RecordingDuckingDelegate(),
      );

      final staleGeneration = service.generation;
      final active = service.play(
        'active.mp3',
        generation: staleGeneration,
      );
      final stalePending = service.play(
        'stale.mp3',
        generation: staleGeneration,
      );
      await _flushAsync();

      final currentGeneration = service.startGeneration();
      final rejectedLateWork = service.play(
        'late-stale.mp3',
        generation: staleGeneration,
      );
      final current = service.play(
        'current.mp3',
        generation: currentGeneration,
      );
      await _flushAsync();

      expect(currentGeneration, staleGeneration + 1);
      expect(player.stopCalls, greaterThanOrEqualTo(1));
      expect(player.startedAssets, ['active.mp3', 'current.mp3']);
      expect(player.startedAssets, isNot(contains('stale.mp3')));
      expect(player.startedAssets, isNot(contains('late-stale.mp3')));

      player.completeCurrent();
      await Future.wait([
        active,
        stalePending,
        rejectedLateWork,
        current,
      ]);
      await service.dispose();
    });

    test('waits for player stop before starting a new generation', () async {
      final player = _ControlledAudioPlayer()..holdStops();
      final service = AudioAnnouncementService.forTesting(
        audioPlayer: player,
        duckingDelegate: _RecordingDuckingDelegate(),
      );

      final active = service.play('active.mp3');
      await _flushAsync();

      final currentGeneration = service.startGeneration();
      final current = service.play(
        'current.mp3',
        generation: currentGeneration,
      );
      await _flushAsync();

      expect(player.startedAssets, ['active.mp3']);

      player.releaseStops();
      await _flushAsync();
      expect(player.startedAssets, ['active.mp3', 'current.mp3']);

      player.completeCurrent();
      await Future.wait([active, current]);
      await service.dispose();
    });

    test('reports player failures as safe session interruptions', () async {
      final player = _ControlledAudioPlayer();
      final ducking = _RecordingDuckingDelegate();
      final service = AudioAnnouncementService.forTesting(
        audioPlayer: player,
        duckingDelegate: ducking,
      );
      var interruptions = 0;
      final subscription = service.interruptions.listen((_) {
        interruptions++;
      });

      final playback = service.play('interrupted.mp3');
      await _flushAsync();
      player.failCurrent(StateError('audio focus lost'));
      await playback;

      expect(interruptions, 1);
      expect(service.queueState.isPlaying, isFalse);
      expect(service.queueState.duckLeaseCount, 0);
      expect(ducking.unduckCalls, 1);

      await subscription.cancel();
      await service.dispose();
    });
  });

  test('ducking controller only restores volume after its final lease',
      () async {
    final delegate = _RecordingDuckingDelegate();
    final controller = ReferenceCountedAnnouncementDuckingController(delegate);

    await controller.acquire();
    await controller.acquire();
    expect(controller.leaseCount, 2);
    expect(delegate.duckCalls, 1);

    await controller.release();
    expect(controller.leaseCount, 1);
    expect(delegate.unduckCalls, 0);

    await controller.release();
    expect(controller.leaseCount, 0);
    expect(delegate.unduckCalls, 1);

    await controller.release();
    expect(delegate.unduckCalls, 1);
  });
}

class _ControlledAudioPlayer implements AnnouncementAudioPlayer {
  final List<String> startedAssets = [];
  Completer<void>? _current;
  int stopCalls = 0;
  bool disposed = false;
  Completer<void>? _stopGate;

  @override
  Future<void> initialize() async {}

  @override
  Future<void> playAsset(String assetKey) {
    if (_current != null) {
      throw StateError('playAsset was called concurrently');
    }
    startedAssets.add(assetKey);
    final completion = Completer<void>();
    _current = completion;
    return completion.future.whenComplete(() {
      if (identical(_current, completion)) _current = null;
    });
  }

  void completeCurrent() {
    final completion = _current;
    if (completion == null || completion.isCompleted) {
      throw StateError('No active asset to complete');
    }
    completion.complete();
  }

  void failCurrent(Object error) {
    final completion = _current;
    if (completion == null || completion.isCompleted) {
      throw StateError('No active asset to fail');
    }
    completion.completeError(error);
  }

  void holdStops() {
    _stopGate = Completer<void>();
  }

  void releaseStops() {
    final stopGate = _stopGate;
    if (stopGate == null || stopGate.isCompleted) {
      throw StateError('Stops are not currently held');
    }
    stopGate.complete();
    _stopGate = null;
  }

  @override
  Future<void> stop() async {
    stopCalls += 1;
    final completion = _current;
    if (completion != null && !completion.isCompleted) completion.complete();
    await _stopGate?.future;
  }

  @override
  Future<void> dispose() async {
    disposed = true;
    await stop();
  }
}

class _RecordingDuckingDelegate implements AnnouncementDuckingDelegate {
  int duckCalls = 0;
  int unduckCalls = 0;

  @override
  Future<void> duck() async {
    duckCalls += 1;
  }

  @override
  Future<void> unduck() async {
    unduckCalls += 1;
  }
}

Future<void> _flushAsync() async {
  await Future<void>.delayed(Duration.zero);
  await Future<void>.delayed(Duration.zero);
}
