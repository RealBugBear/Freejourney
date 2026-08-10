import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/training/in_app_music_settings.dart';
import '../../../../l10n/app_localizations.dart';
import '../services/in_app_music_service.dart';

class MusicPickerSheet extends StatefulWidget {
  final void Function(bool active) onMusicActiveChanged;

  const MusicPickerSheet({super.key, required this.onMusicActiveChanged});

  @override
  State<MusicPickerSheet> createState() => _MusicPickerSheetState();
}

class _MusicPickerSheetState extends State<MusicPickerSheet> {
  final _svc = InAppMusicService.instance;
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

  Future<void> _setVolume(double value) async {
    final prefs = await SharedPreferences.getInstance();
    await InAppMusicSettings.setVolume(prefs, value);
    await _svc.setVolume(value);
    if (!mounted) return;
    setState(() => _volume = value);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.trainingMusic,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 16),
          _trackTile(null, l10n.trainingMusicOff),
          const SizedBox(height: 2),
          const Divider(color: Colors.white12),
          const SizedBox(height: 2),
          ...kInAppTracks.map(
            (track) => _trackTile(track, _trackLabel(l10n, track)),
          ),
          if (kInAppTracks.isEmpty) ...[
            const SizedBox(height: 12),
            Text(
              l10n.trainingMusicUnavailable,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
                height: 1.4,
              ),
            ),
          ],
          const SizedBox(height: 12),
          if (_selected != null) ...[
            Text(
              l10n.trainingMusicVolume,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.4),
                fontSize: 11,
                letterSpacing: 0.1,
              ),
            ),
            Slider(
              value: _volume,
              onChanged: _setVolume,
              activeColor: const Color(0xFF6366f1),
              inactiveColor: Colors.white12,
            ),
          ],
          const Divider(color: Colors.white12),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.music_note, color: Colors.white38, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l10n.trainingOwnMusicMixNote,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.35),
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _trackLabel(AppLocalizations l10n, String assetKey) {
    return switch (assetKey) {
      'sounds/music/ambient_flow.mp3' => l10n.trainingMusicAmbientFlow,
      'sounds/music/stille_natur.mp3' => l10n.trainingMusicQuietNature,
      'sounds/music/tiefe_toene.mp3' => l10n.trainingMusicDeepTones,
      _ => assetKey,
    };
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
                  : Colors.white.withValues(alpha: 0.3),
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: isSelected
                      ? Colors.white
                      : Colors.white.withValues(alpha: 0.6),
                  fontSize: 15,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ),
            if (isSelected)
              const Icon(Icons.volume_up, color: Color(0xFF6366f1), size: 16),
          ],
        ),
      ),
    );
  }
}
