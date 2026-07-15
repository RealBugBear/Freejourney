import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/training/in_app_music_settings.dart';

/// Stable asset keys for the music picker. Display names live in the ARBs.
const List<String> kInAppTracks = [
  'sounds/music/ambient_flow.mp3',
  'sounds/music/stille_natur.mp3',
  'sounds/music/tiefe_toene.mp3',
];

class InAppMusicService {
  InAppMusicService._();

  static final InAppMusicService instance = InAppMusicService._();

  final _player = AudioPlayer();
  bool _initialized = false;
  String? _currentTrack;
  double _normalVolume = 0.7;
  bool _isDucked = false;

  String? get currentTrack => _currentTrack;

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
    } catch (error) {
      debugPrint('[InAppMusicService] init error: $error');
    }
  }

  Future<void> loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final track = InAppMusicSettings.selectedTrack(prefs);
    final volume = InAppMusicSettings.volume(prefs);
    if (track == null) {
      await stop();
      return;
    }
    await play(track, volume: volume);
  }

  Future<void> play(String assetKey, {double volume = 0.7}) async {
    try {
      await init();
      _currentTrack = assetKey;
      _normalVolume = volume.clamp(0.0, 1.0);
      await _player.setVolume(_normalVolume);
      await _player.play(AssetSource(assetKey));
    } catch (error) {
      debugPrint('[InAppMusicService] play error: $error');
    }
  }

  Future<void> stop() async {
    _currentTrack = null;
    await _player.stop();
  }

  Future<void> setVolume(double volume) async {
    await init();
    _normalVolume = volume.clamp(0.0, 1.0);
    if (!_isDucked) await _player.setVolume(_normalVolume);
  }

  /// Temporarily lowers music volume while an announcement plays.
  Future<void> duck() async {
    if (_isDucked || _currentTrack == null) return;
    _isDucked = true;
    await _player.setVolume(0.2);
  }

  /// Restores music volume after an announcement finishes.
  Future<void> unduck() async {
    if (!_isDucked) return;
    _isDucked = false;
    await _player.setVolume(_normalVolume);
  }

  Future<void> dispose() async {
    _initialized = false;
    _currentTrack = null;
    await _player.dispose();
  }
}
