import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

import '../../presentation/services/in_app_music_service.dart';

enum AnnouncementPriority {
  low,
  normal,
  high,
  critical,
}

abstract interface class AnnouncementAudioPlayer {
  Future<void> initialize();

  Future<void> playAsset(String assetKey);

  Future<void> stop();

  Future<void> dispose();
}

abstract interface class AnnouncementDuckingDelegate {
  Future<void> duck();

  Future<void> unduck();
}

/// Gives music ducking lease semantics so overlapping owners cannot restore
/// the volume while another owner still needs it lowered.
class ReferenceCountedAnnouncementDuckingController {
  final AnnouncementDuckingDelegate _delegate;
  int _leaseCount = 0;

  ReferenceCountedAnnouncementDuckingController(this._delegate);

  int get leaseCount => _leaseCount;

  Future<void> acquire() async {
    _leaseCount += 1;
    if (_leaseCount != 1) return;
    try {
      await _delegate.duck();
    } catch (_) {
      _leaseCount -= 1;
      rethrow;
    }
  }

  Future<void> release() async {
    if (_leaseCount == 0) return;
    _leaseCount -= 1;
    if (_leaseCount == 0) await _delegate.unduck();
  }

  Future<void> reset() async {
    final hadLease = _leaseCount > 0;
    _leaseCount = 0;
    if (hadLease) await _delegate.unduck();
  }
}

class AnnouncementQueueState {
  final int generation;
  final bool isPlaying;
  final String? activeAssetKey;
  final int pendingRequestCount;
  final int pendingAssetCount;
  final int duckLeaseCount;

  const AnnouncementQueueState({
    required this.generation,
    required this.isPlaying,
    required this.activeAssetKey,
    required this.pendingRequestCount,
    required this.pendingAssetCount,
    required this.duckLeaseCount,
  });
}

class AudioAnnouncementService {
  AudioAnnouncementService._()
      : _audioPlayer = _AudioplayersAnnouncementAudioPlayer(),
        _ducking = ReferenceCountedAnnouncementDuckingController(
          _InAppMusicDuckingDelegate(),
        ),
        _assetTimeout = const Duration(seconds: 45);

  @visibleForTesting
  AudioAnnouncementService.forTesting({
    required AnnouncementAudioPlayer audioPlayer,
    required AnnouncementDuckingDelegate duckingDelegate,
    Duration assetTimeout = const Duration(seconds: 5),
  })  : _audioPlayer = audioPlayer,
        _ducking =
            ReferenceCountedAnnouncementDuckingController(duckingDelegate),
        _assetTimeout = assetTimeout;

  static final AudioAnnouncementService instance = AudioAnnouncementService._();

  final AnnouncementAudioPlayer _audioPlayer;
  final ReferenceCountedAnnouncementDuckingController _ducking;
  final Duration _assetTimeout;
  final List<_AnnouncementRequest> _pending = [];
  final StreamController<void> _interruptions =
      StreamController<void>.broadcast(sync: true);

  _AnnouncementRequest? _activeRequest;
  Completer<void>? _activeCancellation;
  Future<void>? _drainFuture;
  Future<void> _stopBarrier = Future.value();
  String? _activeAssetKey;
  bool _initialized = false;
  int _generation = 0;
  int _nextOrder = 0;

  int get generation => _generation;
  Stream<void> get interruptions => _interruptions.stream;

  AnnouncementQueueState get queueState => AnnouncementQueueState(
        generation: _generation,
        isPlaying: _activeRequest != null,
        activeAssetKey: _activeAssetKey,
        pendingRequestCount: _pending.length,
        pendingAssetCount: _pending.fold(
          0,
          (total, request) => total + request.assetKeys.length,
        ),
        duckLeaseCount: _ducking.leaseCount,
      );

  /// Plays one asset through the same serialized scheduler used by [queue].
  ///
  /// [generation] can bind work to a caller-owned session generation. Work for
  /// an old generation is ignored without playing audio.
  Future<void> play(
    String assetKey, {
    AnnouncementPriority priority = AnnouncementPriority.normal,
    int? generation,
  }) {
    return queue(
      [assetKey],
      priority: priority,
      generation: generation,
    );
  }

  /// Plays one request's assets contiguously and in the supplied order.
  ///
  /// Requests are globally serialized. A higher-priority pending request runs
  /// before lower-priority pending work; active audio is only interrupted by
  /// [startGeneration] or [stop].
  Future<void> queue(
    List<String> assetKeys, {
    AnnouncementPriority priority = AnnouncementPriority.normal,
    int? generation,
  }) {
    if (assetKeys.isEmpty) return Future.value();

    final requestGeneration = generation ?? _generation;
    if (requestGeneration != _generation) return Future.value();

    final request = _AnnouncementRequest(
      assetKeys: List.unmodifiable(assetKeys),
      priority: priority,
      generation: requestGeneration,
      order: _nextOrder++,
    );
    _pending.add(request);
    _pending.sort(_compareRequests);
    _drainFuture ??= _drain();
    return request.done.future;
  }

  /// Cancels active and queued work, then returns the new generation token.
  ///
  /// Callers starting a new session can retain the returned token and pass it
  /// to [play] or [queue], preventing late work from a previous session.
  int startGeneration() {
    _generation += 1;

    for (final request in _pending) {
      request.complete();
    }
    _pending.clear();

    final cancellation = _activeCancellation;
    if (cancellation != null && !cancellation.isCompleted) {
      cancellation.complete();
    }
    _stopBarrier = _stopBarrier.then((_) => _stopPlayerSafely());
    return _generation;
  }

  /// Backwards-compatible all-work cancellation.
  void stop() {
    startGeneration();
  }

  Future<void> dispose() async {
    startGeneration();
    await _drainFuture;
    await _stopBarrier;
    await _ducking.reset();
    _initialized = false;
    await _audioPlayer.dispose();
    await _interruptions.close();
  }

  Future<void> _ensureInitialized() async {
    if (_initialized) return;
    await _audioPlayer.initialize();
    _initialized = true;
  }

  Future<void> _drain() async {
    try {
      while (_pending.isNotEmpty) {
        final request = _pending.removeAt(0);
        if (request.generation != _generation) {
          request.complete();
          continue;
        }
        _activeRequest = request;
        await _playRequest(request);
        request.complete();
        _activeRequest = null;
      }
    } finally {
      _activeRequest?.complete();
      _activeRequest = null;
      _activeAssetKey = null;
      _activeCancellation = null;
      _drainFuture = null;

      // A request can arrive between the final loop check and this cleanup.
      if (_pending.isNotEmpty) _drainFuture = _drain();
    }
  }

  Future<void> _playRequest(_AnnouncementRequest request) async {
    var hasDuckLease = false;
    try {
      await _stopBarrier;
      await _ensureInitialized();
      if (request.generation != _generation) return;

      await _ducking.acquire();
      hasDuckLease = true;

      for (final assetKey in request.assetKeys) {
        if (request.generation != _generation) break;

        final cancellation = Completer<void>();
        _activeCancellation = cancellation;
        _activeAssetKey = assetKey;
        try {
          await Future.any<void>([
            _audioPlayer.playAsset(assetKey).timeout(_assetTimeout),
            cancellation.future,
          ]);
        } on TimeoutException {
          debugPrint(
            '[AudioAnnouncementService] timed out: $assetKey',
          );
          _notifyInterruption();
          await _stopPlayerSafely();
        } catch (error) {
          debugPrint(
            '[AudioAnnouncementService] play error for $assetKey: $error',
          );
          _notifyInterruption();
        } finally {
          if (identical(_activeCancellation, cancellation)) {
            _activeCancellation = null;
          }
          _activeAssetKey = null;
        }
      }
    } catch (error) {
      debugPrint('[AudioAnnouncementService] request error: $error');
      _notifyInterruption();
      _initialized = false;
    } finally {
      if (hasDuckLease) {
        try {
          await _ducking.release();
        } catch (error) {
          debugPrint('[AudioAnnouncementService] unduck error: $error');
        }
      }
    }
  }

  Future<void> _stopPlayerSafely() async {
    try {
      await _audioPlayer.stop();
    } catch (error) {
      debugPrint('[AudioAnnouncementService] stop error: $error');
    }
  }

  void _notifyInterruption() {
    if (!_interruptions.isClosed) _interruptions.add(null);
  }

  static int _compareRequests(
    _AnnouncementRequest first,
    _AnnouncementRequest second,
  ) {
    final byPriority = second.priority.index.compareTo(first.priority.index);
    if (byPriority != 0) return byPriority;
    return first.order.compareTo(second.order);
  }
}

class _AnnouncementRequest {
  final List<String> assetKeys;
  final AnnouncementPriority priority;
  final int generation;
  final int order;
  final Completer<void> done = Completer<void>();

  _AnnouncementRequest({
    required this.assetKeys,
    required this.priority,
    required this.generation,
    required this.order,
  });

  void complete() {
    if (!done.isCompleted) done.complete();
  }
}

class _AudioplayersAnnouncementAudioPlayer implements AnnouncementAudioPlayer {
  AudioPlayer? _player;
  Completer<void>? _playbackCompletion;
  StreamSubscription<void>? _playerCompletionSubscription;
  StreamSubscription<PlayerState>? _playerStateSubscription;

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
      throw StateError('Announcement player is not initialized.');
    }
    if (_playbackCompletion != null) {
      throw StateError('Announcement assets must be played serially.');
    }

    final completion = Completer<void>();
    _playbackCompletion = completion;
    var playbackStarted = false;
    _playerCompletionSubscription = player.onPlayerComplete.listen((_) {
      if (!completion.isCompleted) completion.complete();
    });
    _playerStateSubscription = player.onPlayerStateChanged.listen((state) {
      if (state == PlayerState.playing) {
        playbackStarted = true;
        return;
      }
      if (playbackStarted &&
          (state == PlayerState.paused || state == PlayerState.stopped) &&
          !completion.isCompleted) {
        completion.completeError(
          StateError('Announcement playback was interrupted.'),
        );
      }
    });
    try {
      await player.play(AssetSource(assetKey));
      await completion.future;
    } finally {
      await _playerCompletionSubscription?.cancel();
      _playerCompletionSubscription = null;
      await _playerStateSubscription?.cancel();
      _playerStateSubscription = null;
      if (identical(_playbackCompletion, completion)) {
        _playbackCompletion = null;
      }
    }
  }

  @override
  Future<void> stop() async {
    final completion = _playbackCompletion;
    if (completion != null && !completion.isCompleted) completion.complete();
    await _player?.stop();
  }

  @override
  Future<void> dispose() async {
    final player = _player;
    await stop();
    _player = null;
    await _playerCompletionSubscription?.cancel();
    _playerCompletionSubscription = null;
    await _playerStateSubscription?.cancel();
    _playerStateSubscription = null;
    _playbackCompletion = null;
    await player?.dispose();
  }
}

class _InAppMusicDuckingDelegate implements AnnouncementDuckingDelegate {
  @override
  Future<void> duck() => InAppMusicService.instance.duck();

  @override
  Future<void> unduck() => InAppMusicService.instance.unduck();
}
